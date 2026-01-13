from rest_framework import viewsets, status, generics
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth.models import User
from .models import HealthProfile
from .serializers import (
    UserSerializer, UserRegistrationSerializer,
    HealthProfileSerializer
)


class UserRegistrationView(generics.CreateAPIView):
    """API endpoint for user registration"""
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        return Response({
            'user': UserSerializer(user).data,
            'message': 'User created successfully'
        }, status=status.HTTP_201_CREATED)


class UserProfileView(generics.RetrieveUpdateAPIView):
    """API endpoint for viewing and updating user profile"""
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class HealthProfileViewSet(viewsets.ModelViewSet):
    """ViewSet for managing user health profiles"""
    serializer_class = HealthProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return HealthProfile.objects.filter(user=self.request.user)

    def get_object(self):
        return self.request.user.health_profile

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
