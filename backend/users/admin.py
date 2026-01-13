from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from .models import HealthProfile


class HealthProfileInline(admin.StackedInline):
    model = HealthProfile
    can_delete = False
    verbose_name_plural = 'Health Profile'


class UserAdmin(BaseUserAdmin):
    inlines = (HealthProfileInline,)


# Re-register UserAdmin
admin.site.unregister(User)
admin.site.register(User, UserAdmin)


@admin.register(HealthProfile)
class HealthProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'notification_enabled',
                    'scan_reminder', 'created_at']
    list_filter = ['notification_enabled', 'scan_reminder', 'created_at']
    search_fields = ['user__username', 'user__email']
    readonly_fields = ['created_at', 'updated_at']
