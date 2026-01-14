from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import UserProfileView, HealthProfileViewSet, sync_user

router = DefaultRouter()
router.register(r'health-profile', HealthProfileViewSet,
                basename='health-profile')

urlpatterns = [
    # Firebase Authentication
    path('sync/', sync_user, name='sync-user'),

    # User profile
    path('profile/', UserProfileView.as_view(), name='user-profile'),

    # Health profile
    path('', include(router.urls)),
]
