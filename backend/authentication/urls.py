from django.urls import path, include
from .views import GoogleLogin

urlpatterns = [
    # Social Login
    path('google/', GoogleLogin.as_view(), name='google_login'),

    # Generic dj-rest-auth views (login, logout, user, etc.)
    path('', include('dj_rest_auth.urls')),
]
