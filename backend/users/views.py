from rest_framework import viewsets, status, generics
from rest_framework.decorators import api_view, action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth.models import User
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials, initialize_app
from django.conf import settings
import os
from .models import HealthProfile
from .serializers import (
    UserSerializer,
    HealthProfileSerializer
)

# Initialize Firebase Admin SDK
try:
    cred_path = os.path.join(settings.BASE_DIR, 'firebase-credentials.json')
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        initialize_app(cred)
        print("Firebase Admin SDK initialized successfully")
    else:
        print("Warning: firebase-credentials.json not found. Firebase auth will not work.")
except Exception as e:
    print(f"Firebase initialization error: {e}")


@api_view(['POST'])
def sync_user(request):
    """
    Sync Firebase user with Django backend

    POST /api/users/sync/
    Headers: Authorization: Bearer <firebase_token>
    {
        "uid": "firebase_uid",
        "email": "user@example.com",
        "display_name": "John Doe"
    }
    """
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')

    if not auth_header.startswith('Bearer '):
        return Response(
            {'error': 'Authorization header required'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    token = auth_header.split('Bearer ')[1]

    try:
        # Verify Firebase token
        decoded_token = firebase_auth.verify_id_token(token)
        uid = decoded_token['uid']
        email = decoded_token.get('email', '')

        # Get data from request
        display_name = request.data.get('display_name', '')
        first_name = display_name.split(' ')[0] if display_name else ''
        last_name = ' '.join(display_name.split(' ')[1:]) if len(
            display_name.split(' ')) > 1 else ''

        # Get or create user
        user, created = User.objects.get_or_create(
            username=uid,
            defaults={
                'email': email,
                'first_name': first_name,
                'last_name': last_name,
            }
        )

        # Update user if exists
        if not created:
            user.email = email
            user.first_name = first_name
            user.last_name = last_name
            user.save()

        # Create health profile if doesn't exist
        if not hasattr(user, 'health_profile'):
            HealthProfile.objects.create(user=user)

        return Response({
            'message': 'User synced successfully',
            'user': UserSerializer(user).data,
            'created': created
        }, status=status.HTTP_200_OK)

    except Exception as e:
        return Response(
            {'error': 'Invalid Firebase token', 'details': str(e)},
            status=status.HTTP_401_UNAUTHORIZED
        )


class UserProfileView(generics.RetrieveUpdateAPIView):
    """API endpoint for viewing and updating user profile"""
    serializer_class = UserSerializer
    permission_classes = [AllowAny]  # We'll validate Firebase token manually

    def get_object(self):
        # Validate Firebase token
        auth_header = self.request.META.get('HTTP_AUTHORIZATION', '')

        if not auth_header.startswith('Bearer '):
            return None

        token = auth_header.split('Bearer ')[1]

        try:
            decoded_token = firebase_auth.verify_id_token(token)
            uid = decoded_token['uid']

            user = User.objects.get(username=uid)
            return user
        except Exception as e:
            print(f"Error getting user: {e}")
            return None


class HealthProfileViewSet(viewsets.ModelViewSet):
    """ViewSet for managing user health profiles"""
    serializer_class = HealthProfileSerializer
    permission_classes = [AllowAny]  # We'll validate Firebase token manually

    def get_queryset(self):
        # Validate Firebase token
        auth_header = self.request.META.get('HTTP_AUTHORIZATION', '')

        if not auth_header.startswith('Bearer '):
            return HealthProfile.objects.none()

        token = auth_header.split('Bearer ')[1]

        try:
            decoded_token = firebase_auth.verify_id_token(token)
            uid = decoded_token['uid']

            user = User.objects.get(username=uid)
            return HealthProfile.objects.filter(user=user)
        except Exception as e:
            print(f"Error getting health profile: {e}")
            return HealthProfile.objects.none()

    def get_object(self):
        # Validate Firebase token
        auth_header = self.request.META.get('HTTP_AUTHORIZATION', '')

        if not auth_header.startswith('Bearer '):
            return None

        token = auth_header.split('Bearer ')[1]

        try:
            decoded_token = firebase_auth.verify_id_token(token)
            uid = decoded_token['uid']

            user = User.objects.get(username=uid)
            return user.health_profile
        except Exception as e:
            print(f"Error getting health profile: {e}")
            return None

    @action(detail=False, methods=['post'])
    def check_product(self, request):
        """Check if a product is safe for the user"""
        from products.models import Product

        product_id = request.data.get('product_id')
        if not product_id:
            return Response(
                {'error': 'product_id is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            product = Product.objects.get(id=product_id)
            health_profile = request.user.health_profile
            safety_check = health_profile.check_product_safety(product)

            return Response(safety_check)
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found'},
                status=status.HTTP_404_NOT_FOUND
            )
