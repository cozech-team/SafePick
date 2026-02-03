import os
from allauth.socialaccount.providers.google.views import GoogleOAuth2Adapter
from allauth.socialaccount.providers.oauth2.client import OAuth2Client
from dj_rest_auth.registration.views import SocialLoginView


class GoogleLogin(SocialLoginView):
    adapter_class = GoogleOAuth2Adapter
    # Use environment variable for production, fallback to localhost for development
    callback_url = os.environ.get(
        "GOOGLE_CALLBACK_URL", "http://localhost:8000/api/auth/google/callback/")
    client_class = OAuth2Client
