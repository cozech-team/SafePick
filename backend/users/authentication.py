from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from django.contrib.auth.models import User
from firebase_admin import auth as firebase_auth


class FirebaseAuthentication(BaseAuthentication):
    """Custom authentication class for Firebase tokens"""

    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')

        if not auth_header.startswith('Bearer '):
            return None

        token = auth_header.split('Bearer ')[1]

        try:
            # Verify Firebase token
            decoded_token = firebase_auth.verify_id_token(token)
            uid = decoded_token['uid']
            email = decoded_token.get('email', '')

            # Get or create user
            user, created = User.objects.get_or_create(
                username=uid,
                defaults={
                    'email': email,
                }
            )

            return (user, None)
        except Exception as e:
            print(f"Firebase auth error: {e}")
            raise exceptions.AuthenticationFailed(
                f'Invalid Firebase token: {str(e)}')

    def authenticate_header(self, request):
        return 'Bearer'
