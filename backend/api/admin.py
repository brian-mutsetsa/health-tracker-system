from django.contrib import admin
from .models import Patient, CheckIn


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