from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver


class HealthProfile(models.Model):
    """Model for storing user health information and preferences"""

    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name='health_profile')

    # Health conditions
    allergies = models.JSONField(
        default=list, blank=True, help_text="List of allergies")
    dietary_restrictions = models.JSONField(
        default=list, blank=True, help_text="Dietary restrictions (vegan, halal, etc.)")
    health_conditions = models.JSONField(
        default=list, blank=True, help_text="Health conditions (diabetes, hypertension, etc.)")

    # Preferences
    avoid_ingredients = models.JSONField(
        default=list, blank=True, help_text="Ingredients to avoid")
    preferred_categories = models.JSONField(
        default=list, blank=True, help_text="Preferred product categories")

    # Profile settings
    notification_enabled = models.BooleanField(default=True)
    scan_reminder = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Health Profile - {self.user.username}"

    def check_product_safety(self, product):
        """Check if a product is safe for this user"""
        warnings = []

        for ingredient in product.ingredients.all():
            # Check allergies
            if ingredient.name.lower() in [a.lower() for a in self.allergies]:
                warnings.append({
                    'type': 'ALLERGY',
                    'ingredient': ingredient.name,
                    'severity': 'HIGH'
                })

            # Check ingredients to avoid
            if ingredient.name.lower() in [a.lower() for a in self.avoid_ingredients]:
                warnings.append({
                    'type': 'AVOID',
                    'ingredient': ingredient.name,
                    'severity': 'MEDIUM'
                })

            # Check health condition impacts
            for impact in ingredient.health_impacts.all():
                if impact.condition.lower() in [c.lower() for c in self.health_conditions]:
                    warnings.append({
                        'type': 'HEALTH_CONDITION',
                        'ingredient': ingredient.name,
                        'condition': impact.condition,
                        'severity': impact.impact_level
                    })

        return {
            'is_safe': len(warnings) == 0,
            'warnings': warnings
        }


@receiver(post_save, sender=User)
def create_health_profile(sender, instance, created, **kwargs):
    """Automatically create health profile when user is created"""
    if created:
        HealthProfile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_health_profile(sender, instance, **kwargs):
    """Save health profile when user is saved"""
    if hasattr(instance, 'health_profile'):
        instance.health_profile.save()
