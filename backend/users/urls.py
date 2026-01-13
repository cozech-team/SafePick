from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from .views import UserRegistrationView, UserProfileView, HealthProfileViewSet

router = DefaultRouter()
router.register(r'health-profile', HealthProfileViewSet,
                basename='health-profile')

urlpatterns = [
    # Authentication
    path('register/', UserRegistrationView.as_view(), name='user-register'),
    path('login/', TokenObtainPairView.as_view(), name='token-obtain'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),

    # User profile
    path('profile/', UserProfileView.as_view(), name='user-profile'),

    # Health profile
    path('', include(router.urls)),
]
