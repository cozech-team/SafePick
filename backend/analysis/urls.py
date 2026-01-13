from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AnalyzeIngredientsView, QuickHealthCheckView, AnalysisHistoryViewSet

router = DefaultRouter()
router.register(r'history', AnalysisHistoryViewSet,
                basename='analysis-history')

urlpatterns = [
    path('analyze/', AnalyzeIngredientsView.as_view(), name='analyze-ingredients'),
    path('quick-check/', QuickHealthCheckView.as_view(), name='quick-health-check'),
    path('', include(router.urls)),
]
