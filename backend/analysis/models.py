from django.db import models
from django.contrib.auth.models import User


class ProductAnalysis(models.Model):
    """Store analysis results for user history"""

    RATING_CHOICES = [
        ('BEST', 'Best'),
        ('GOOD', 'Good'),
        ('AVERAGE', 'Average'),
        ('BAD', 'Bad'),
        ('AVOID', 'Avoid'),
    ]

    # User who performed the analysis
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='analyses', null=True, blank=True)

    # Input
    raw_text = models.TextField(
        help_text="Raw ingredients text that was analyzed")

    # Results from Gemini AI
    detected_ingredients = models.IntegerField(
        help_text="Number of ingredients detected")
    overall_rating = models.CharField(max_length=20, choices=RATING_CHOICES)
    overall_score = models.DecimalField(
        max_digits=3, decimal_places=1, help_text="Score from 0.0 to 10.0")

    # Ingredient breakdown (from AI)
    good_ingredients = models.JSONField(
        default=list, help_text="List of beneficial ingredients")
    bad_ingredients = models.JSONField(
        default=list, help_text="List of harmful ingredients")
    neutral_ingredients = models.JSONField(
        default=list, help_text="List of neutral ingredients")

    # Recommendations
    recommendation_text = models.TextField(
        help_text="AI-generated health recommendation")
    allergen_warnings = models.JSONField(
        default=list, blank=True, help_text="List of detected allergens")
    health_concerns = models.JSONField(
        default=list, blank=True, help_text="List of health concerns")

    # Metadata
    analysis_date = models.DateTimeField(auto_now_add=True)
    processing_time = models.FloatField(
        help_text="Time taken to analyze in seconds")
    from_cache = models.BooleanField(
        default=False, help_text="Whether result came from cache")

    class Meta:
        ordering = ['-analysis_date']
        verbose_name = 'Product Analysis'
        verbose_name_plural = 'Product Analyses'
        indexes = [
            models.Index(fields=['-analysis_date']),
            models.Index(fields=['user', '-analysis_date']),
            models.Index(fields=['overall_rating']),
        ]

    def __str__(self):
        return f"Analysis on {self.analysis_date.strftime('%Y-%m-%d %H:%M')} - {self.overall_rating}"

    @property
    def cache_status(self):
        """Return cache status as emoji"""
        return "✅ Cached" if self.from_cache else "🔄 Fresh"

    @property
    def speed_category(self):
        """Categorize processing speed"""
        if self.processing_time < 0.1:
            return "Instant"
        elif self.processing_time < 1.0:
            return "Fast"
        elif self.processing_time < 3.0:
            return "Normal"
        else:
            return "Slow"
