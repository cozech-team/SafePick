from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from django.contrib.auth.models import User
import json
import base64


class FirebaseAuthentication(BaseAuthentication):
    """Simplified authentication - extracts email from Firebase token"""

    def authenticate(self, request):
        auth_header = request.META.get('HTTP_AUTHORIZATION', '')

        if not auth_header.startswith('Bearer '):
            return None

        token = auth_header.split('Bearer ')[1]

        try:
            # Decode Firebase token (no verification, just extract payload)
            # Firebase tokens are JWT: header.payload.signature
            parts = token.split('.')
            if len(parts) != 3:
                raise ValueError("Invalid token format")

            # Decode payload (base64url)
            payload = parts[1]
            # Add padding if needed
            padding = 4 - len(payload) % 4
            if padding != 4:
                payload += '=' * padding

            decoded_bytes = base64.urlsafe_b64decode(payload)
            decoded_token = json.loads(decoded_bytes)

            email = decoded_token.get('email', '')
            uid = decoded_token.get('user_id') or decoded_token.get('sub', '')

            if not email:
                raise ValueError("No email in token")

            # Get or create user by email
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': email.split('@')[0] + '_' + uid[:8],
                }
            )

            return (user, None)
        except Exception as e:
            print(f"Auth error: {e}")
            raise exceptions.AuthenticationFailed(
                f'Invalid token: {str(e)}')

    def authenticate_header(self, request):
        return 'Bearer'
