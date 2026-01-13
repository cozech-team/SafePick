from google import genai
from google.genai import types
import json
from django.conf import settings
from typing import Dict
from .cache_service import AnalysisCache


class GeminiAnalyzer:
    """
    FREE ingredient analysis using Google Gemini AI
    No database needed - AI knows millions of ingredients!
    """

    def __init__(self):
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)

    def analyze_ingredients(self, ingredients_text: str) -> Dict:
        """
        Analyze ingredients using FREE Gemini API

        Args:
            ingredients_text: Raw ingredient list from OCR

        Returns:
            Dictionary with analysis results
        """
        # Check cache first using AnalysisCache
        cached_result = AnalysisCache.get(ingredients_text)
        if cached_result:
            return cached_result

        prompt = self._create_prompt(ingredients_text)

        try:
            # Call FREE Gemini API using new client
            response = self.client.models.generate_content(
                model='gemini-2.0-flash-exp',
                contents=prompt
            )
            result_text = response.text

            # Extract JSON from markdown code blocks if present
            if "```json" in result_text:
                result_text = result_text.split("```json")[1].split("```")[0]
            elif "```" in result_text:
                result_text = result_text.split("```")[1].split("```")[0]

            result = json.loads(result_text.strip())

            # Cache the result using AnalysisCache
            AnalysisCache.set(ingredients_text, result)

            return result

        except Exception as e:
            raise Exception(f"Gemini API error: {str(e)}")

    def _create_prompt(self, ingredients_text: str) -> str:
        """Create analysis prompt for Gemini"""
        return f"""You are a professional nutritionist and food safety expert.
Analyze the following product ingredients and provide a health rating.

INGREDIENTS:
{ingredients_text}

Respond with ONLY valid JSON in this exact format:
{{
  "overall_score": 7.5,
  "overall_rating": "GOOD",
  "total_ingredients": 8,
  "good_ingredients": [
    {{
      "name": "Vitamin C",
      "score": 8,
      "category": "Nutrient",
      "impact": "Boosts immunity and supports skin health"
    }}
  ],
  "bad_ingredients": [
    {{
      "name": "Sodium Benzoate",
      "score": -4,
      "category": "Preservative",
      "impact": "May form benzene in acidic conditions"
    }}
  ],
  "neutral_ingredients": [
    {{
      "name": "Water",
      "score": 0,
      "category": "Base",
      "impact": "Essential for hydration"
    }}
  ],
  "recommendation": "Brief health recommendation",
  "allergen_warnings": ["List any allergens"],
  "health_concerns": ["List any health concerns"]
}}

Rating scale:
- BEST: 8.5-10.0 (Excellent, highly recommended)
- GOOD: 7.0-8.4 (Safe, good choice)
- AVERAGE: 5.0-6.9 (Acceptable)
- BAD: 3.0-4.9 (Not recommended)
- AVOID: 0.0-2.9 (Harmful)

Scoring guidelines:
- Start with base score of 10.0
- Beneficial ingredients (vitamins, minerals, natural): +0.1 to +0.5
- Harmful ingredients (artificial, toxic): -0.5 to -3.0
- Consider ingredient combinations"""


# Singleton instance
gemini_analyzer = GeminiAnalyzer()
