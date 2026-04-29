from django.contrib import admin
from django.contrib.auth.models import User
from django.contrib.auth.admin import UserAdmin
from .models import Patient, CheckIn, Provider, Message, Appointment, Notification

admin.site.unregister(User)

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = UserAdmin.list_display + ('is_active',)


@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    list_display = ['patient_id', 'condition', 'last_risk_level', 'last_checkin', 'updated_at']
    list_filter = ['condition', 'last_risk_level']
    search_fields = ['patient_id']
    readonly_fields = ['created_at', 'updated_at']


@admin.register(CheckIn)
class CheckInAdmin(admin.ModelAdmin):
    list_display = ['patient', 'condition', 'risk_level', 'date', 'uploaded_at']
    list_filter = ['risk_level', 'condition', 'date']
    search_fields = ['patient__patient_id']
    readonly_fields = ['uploaded_at']
    date_hierarchy = 'date'

@admin.register(Provider)
class ProviderAdmin(admin.ModelAdmin):
    list_display = ['provider_id', 'user', 'specialty', 'hospital']
    list_filter = ['specialty', 'hospital']
    search_fields = ['provider_id', 'user__username', 'user__last_name']

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['sender_id', 'receiver_id', 'timestamp', 'is_read']
    list_filter = ['is_read', 'timestamp']
    search_fields = ['sender_id', 'receiver_id']

@admin.register(Appointment)
class AppointmentAdmin(admin.ModelAdmin):
    list_display = ['patient', 'provider_id', 'scheduled_date', 'scheduled_time', 'status']
    list_filter = ['status', 'scheduled_date']
    search_fields = ['patient__patient_id', 'provider_id']

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['notification_type', 'user_id', 'is_read', 'created_at']
    list_filter = ['notification_type', 'is_read', 'created_at']
    search_fields = ['user_id']