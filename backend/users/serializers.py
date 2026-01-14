from rest_framework import serializers
from django.contrib.auth.models import User
from .models import HealthProfile


class HealthProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = HealthProfile
        fields = [
            'id', 'allergies', 'dietary_restrictions', 'health_conditions',
            'avoid_ingredients', 'preferred_categories',
            'notification_enabled', 'scan_reminder',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']


class UserSerializer(serializers.ModelSerializer):
    health_profile = HealthProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'email',
                  'first_name', 'last_name', 'health_profile']
        read_only_fields = ['id']
