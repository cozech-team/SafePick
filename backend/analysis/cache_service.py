import hashlib
import json
from django.core.cache import cache
from typing import Optional, Dict


class AnalysisCache:
    """
    Cache analysis results to reduce API calls and costs
    Same product scanned multiple times = instant results from cache
    """

    CACHE_TTL = 60 * 60 * 24 * 30  # 30 days

    @staticmethod
    def _generate_cache_key(ingredients_text: str) -> str:
        """Generate unique cache key from ingredients"""
        # Normalize text (lowercase, remove extra spaces)
        normalized = ' '.join(ingredients_text.lower().split())
        # Create hash
        return f"analysis_{hashlib.md5(normalized.encode()).hexdigest()}"

    @staticmethod
    def get(ingredients_text: str) -> Optional[Dict]:
        """Get cached analysis result"""
        cache_key = AnalysisCache._generate_cache_key(ingredients_text)
        cached_result = cache.get(cache_key)

        if cached_result:
            print(f"✅ Cache HIT - Instant result!")
            return json.loads(cached_result)

        print(f"❌ Cache MISS - Calling AI...")
        return None

    @staticmethod
    def set(ingredients_text: str, result: Dict):
        """Cache analysis result for 30 days"""
        cache_key = AnalysisCache._generate_cache_key(ingredients_text)
        cache.set(cache_key, json.dumps(result), AnalysisCache.CACHE_TTL)
        print(f"💾 Cached result for future use")
