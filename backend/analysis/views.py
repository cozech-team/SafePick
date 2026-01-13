from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from .gemini_service import gemini_analyzer
from .models import ProductAnalysis
from .serializers import ProductAnalysisSerializer, AnalysisHistorySerializer
import time


class AnalyzeIngredientsView(APIView):
    """
    API endpoint to analyze ingredients using Gemini AI
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """
        Analyze ingredients text

        Request body:
        {
            "ingredients_text": "Water, Sugar, Sodium Benzoate, Vitamin C..."
        }
        """
        ingredients_text = request.data.get('ingredients_text')

        if not ingredients_text:
            return Response(
                {'error': 'ingredients_text is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Track processing time
            start_time = time.time()

            # Call Gemini AI for analysis
            analysis_result = gemini_analyzer.analyze_ingredients(
                ingredients_text)

            # Calculate processing time
            processing_time = time.time() - start_time

            # Save to database for history
            ProductAnalysis.objects.create(
                user=request.user,
                raw_text=ingredients_text,
                detected_ingredients=analysis_result.get(
                    'total_ingredients', 0),
                overall_rating=analysis_result.get(
                    'overall_rating', 'AVERAGE'),
                overall_score=analysis_result.get('overall_score', 5.0),
                good_ingredients=analysis_result.get('good_ingredients', []),
                bad_ingredients=analysis_result.get('bad_ingredients', []),
                neutral_ingredients=analysis_result.get(
                    'neutral_ingredients', []),
                recommendation_text=analysis_result.get('recommendation', ''),
                allergen_warnings=analysis_result.get('allergen_warnings', []),
                health_concerns=analysis_result.get('health_concerns', []),
                processing_time=processing_time,
                from_cache=processing_time < 0.1,  # If very fast, likely from cache
            )

            return Response(analysis_result, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class QuickHealthCheckView(APIView):
    """
    Quick health check for a single ingredient
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        """
        Check single ingredient

        Request body:
        {
            "ingredient_name": "Sodium Benzoate"
        }
        """
        ingredient_name = request.data.get('ingredient_name')

        if not ingredient_name:
            return Response(
                {'error': 'ingredient_name is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # Analyze single ingredient
            analysis_result = gemini_analyzer.analyze_ingredients(
                ingredient_name)

            return Response(analysis_result, status=status.HTTP_200_OK)

        except Exception as e:
            return Response(
                {'error': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class AnalysisHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for viewing analysis history
    """
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'list':
            return AnalysisHistorySerializer
        return ProductAnalysisSerializer

    def get_queryset(self):
        return ProductAnalysis.objects.filter(user=self.request.user)
