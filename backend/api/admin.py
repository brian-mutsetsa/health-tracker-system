import json
from django.contrib import admin
from django.contrib.auth.models import User
from django.contrib.auth.admin import UserAdmin
from django.shortcuts import render
from django.urls import path
from django.contrib.admin.views.decorators import staff_member_required
from django.utils.decorators import method_decorator
from django.views import View
from .models import Patient, CheckIn, Provider, Message, Appointment, Notification, ClinicalVisit

# ─── District coordinates (approximate centroids) ────────────────────────────
DISTRICT_COORDS = {
    'Harare': (-17.8292, 31.0522),
    'Epworth': (-17.8833, 31.1500),
    'Chitungwiza': (-18.0125, 31.0756),
    'Goromonzi': (-17.8500, 31.3500),
    'Marondera': (-18.1833, 31.5500),
    'Seke': (-17.9500, 31.1800),
    'Makoni': (-18.3500, 32.1000),
    'Mazowe': (-17.5000, 30.9667),
    'Bindura': (-17.3000, 31.3333),
    'Zvimba': (-17.6500, 30.0833),
    'Gweru': (-19.4500, 29.8167),
    'Shurugwi': (-19.6667, 30.0000),
    'Chirumhanzu': (-19.5500, 30.1500),
    'Kwekwe': (-18.9281, 29.8147),
    'Mutare': (-18.9707, 32.6709),
    'Masvingo': (-20.0651, 30.8277),
    'Gutu': (-20.6500, 31.1833),
    'Hwange': (-18.3636, 26.4990),
    'Bulawayo': (-20.1500, 28.5833),
    'Umguza': (-19.9167, 28.7667),
    'Matobo': (-20.3667, 28.5167),
    'Insiza': (-20.5667, 29.0500),
    'Beitbridge': (-22.2167, 29.9833),
}
ZIMBABWE_CENTER = (-19.0154, 29.1549)


def _coords_for(district):
    if not district:
        return ZIMBABWE_CENTER
    # Exact match
    if district in DISTRICT_COORDS:
        return DISTRICT_COORDS[district]
    # Partial match
    lower = district.lower()
    for name, coords in DISTRICT_COORDS.items():
        if name.lower() in lower or lower in name.lower():
            return coords
    return ZIMBABWE_CENTER


# ─── Custom admin view: Patient Map ──────────────────────────────────────────
class PatientMapAdminView(View):
    @method_decorator(staff_member_required)
    def get(self, request):
        patients = Patient.objects.all().order_by('patient_id')
        counts = {'RED': 0, 'ORANGE': 0, 'YELLOW': 0, 'GREEN': 0}

        patients_data = []
        for p in patients:
            level = (p.last_risk_level or 'GREEN').upper()
            if level in counts:
                counts[level] += 1
            lat, lng = _coords_for(p.district)
            checkin_count = p.checkins.count()
            patients_data.append({
                'patient_id': p.patient_id,
                'name': f'{p.name} {p.surname}',
                'condition': p.condition,
                'district': p.district or 'Unknown',
                'risk_level': level,
                'lat': lat,
                'lng': lng,
                'total_checkins': checkin_count,
                'last_checkin': p.last_checkin.isoformat() if p.last_checkin else None,
                'provider': p.primary_provider_id or 'Unassigned',
            })

        context = {**admin.site.each_context(request),
            'title': 'Patient Distribution Map',
            'patients_json': json.dumps(patients_data),
            'total_patients': len(patients_data),
            'counts': counts,
        }
        return render(request, 'admin/patient_map.html', context)


# ─── Custom AdminSite to inject the map URL ──────────────────────────────────
class HealthTrackerAdminSite(admin.AdminSite):
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('patient-map/', self.admin_view(PatientMapAdminView.as_view()), name='patient_map'),
        ]
        return custom_urls + urls

    def index(self, request, extra_context=None):
        extra_context = extra_context or {}
        extra_context['patient_map_url'] = 'patient-map/'
        return super().index(request, extra_context)

admin.site.unregister(User)

# Inject the patient map URL into the default admin site
_original_get_urls = admin.site.__class__.get_urls

def _patched_get_urls(self):
    from django.urls import path as _path
    urls = _original_get_urls(self)
    return [_path('patient-map/', self.admin_view(PatientMapAdminView.as_view()), name='patient_map')] + urls

admin.site.__class__.get_urls = _patched_get_urls

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