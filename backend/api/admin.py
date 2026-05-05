from django.contrib import admin
from django.contrib.auth.models import User
from django.contrib.auth.admin import UserAdmin
from .models import Patient, CheckIn, Provider, Message, Appointment, Notification, ClinicalVisit

admin.site.unregister(User)

@admin.register(User)
class CustomUserAdmin(UserAdmin):
    list_display = UserAdmin.list_display + ('is_active',)


@admin.register(Patient)
class PatientAdmin(admin.ModelAdmin):
    list_display = ['patient_id', 'name', 'surname', 'condition', 'phone_number',
                    'district', 'last_risk_level', 'last_checkin', 'status', 'updated_at']
    list_filter = ['condition', 'last_risk_level', 'status', 'gender', 'district']
    search_fields = ['patient_id', 'name', 'surname', 'phone_number', 'id_number']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = (
        ('Identity', {
            'fields': ('patient_id', 'name', 'surname', 'date_of_birth', 'gender', 'id_number',
                       'phone_number', 'pin', 'status')
        }),
        ('Location', {
            'fields': ('district', 'home_address')
        }),
        ('Emergency Contact', {
            'fields': ('emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relation')
        }),
        ('Medical', {
            'fields': ('condition', 'weight_kg', 'blood_pressure_systolic', 'blood_pressure_diastolic',
                       'blood_glucose_baseline', 'medical_history', 'medications', 'allergies')
        }),
        ('Provider & Tracking', {
            'fields': ('primary_provider_id', 'last_checkin', 'last_risk_level', 'last_risk_color',
                       'password', 'created_at', 'updated_at')
        }),
    )


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


@admin.register(ClinicalVisit)
class ClinicalVisitAdmin(admin.ModelAdmin):
    list_display = ['patient', 'hcw_id', 'visit_date', 'systolic_bp', 'diastolic_bp',
                    'heart_rate', 'blood_glucose', 'created_at']
    list_filter = ['visit_date', 'hcw_id']
    search_fields = ['patient__patient_id', 'patient__name', 'hcw_id']
    readonly_fields = ['created_at']