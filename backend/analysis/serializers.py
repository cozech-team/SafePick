from rest_framework import serializers
from .models import ProductAnalysis


class ProductAnalysisSerializer(serializers.ModelSerializer):
    """Serializer for ProductAnalysis model"""

    cache_status = serializers.ReadOnlyField()
    speed_category = serializers.ReadOnlyField()
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = ProductAnalysis
        fields = [
            'id',
            'username',
            'raw_text',
            'detected_ingredients',
            'overall_rating',
            'overall_score',
            'good_ingredients',
            'bad_ingredients',
            'neutral_ingredients',
            'recommendation_text',
            'allergen_warnings',
            'health_concerns',
            'analysis_date',
            'processing_time',
            'from_cache',
            'cache_status',
            'speed_category',
        ]
        read_only_fields = [
            'id',
            'analysis_date',
            'processing_time',
            'from_cache',
        ]


class AnalysisHistorySerializer(serializers.ModelSerializer):
    """Lightweight serializer for analysis history list"""

    cache_status = serializers.ReadOnlyField()

    class Meta:
        model = ProductAnalysis
        fields = [
            'id',
            'overall_rating',
            'overall_score',
            'detected_ingredients',
            'analysis_date',
            'from_cache',
            'cache_status',
        ]
