from django.contrib import admin
from .models import ProductAnalysis


@admin.register(ProductAnalysis)
class ProductAnalysisAdmin(admin.ModelAdmin):
    list_display = [
        'analysis_date',
        'user',
        'overall_rating',
        'overall_score',
        'detected_ingredients',
        'cache_status',
        'speed_category',
    ]
    list_filter = [
        'overall_rating',
        'from_cache',
        'analysis_date',
    ]
    search_fields = [
        'raw_text',
        'recommendation_text',
        'user__username',
    ]
    readonly_fields = [
        'analysis_date',
        'processing_time',
        'cache_status',
        'speed_category',
    ]

    fieldsets = (
        ('Analysis Input', {
            'fields': ('user', 'raw_text')
        }),
        ('Results', {
            'fields': (
                'overall_rating',
                'overall_score',
                'detected_ingredients',
                'recommendation_text',
            )
        }),
        ('Ingredient Breakdown', {
            'fields': (
                'good_ingredients',
                'bad_ingredients',
                'neutral_ingredients',
            ),
            'classes': ('collapse',),
        }),
        ('Warnings', {
            'fields': (
                'allergen_warnings',
                'health_concerns',
            )
        }),
        ('Metadata', {
            'fields': (
                'analysis_date',
                'processing_time',
                'from_cache',
                'cache_status',
                'speed_category',
            )
        }),
    )

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        return qs.select_related('user')
