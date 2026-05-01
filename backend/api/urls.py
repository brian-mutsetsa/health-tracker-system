from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'patients', views.PatientViewSet, basename='patient')
router.register(r'checkins', views.CheckInViewSet, basename='checkin')
router.register(r'messages', views.MessageViewSet, basename='message')

urlpatterns = [
    # Custom endpoints FIRST (before router)
    path('auth/login/', views.provider_login, name='provider-login'),
    path('auth/patient-login/', views.patient_login, name='patient-login'),
    path('auth/verify/', views.verify_session, name='verify-session'),
    path('checkin/submit/', views.create_checkin, name='create-checkin'),
    path('patient/<str:patient_id>/', views.get_patient_by_id, name='get-patient'),
    path('patient/<str:patient_id>/checkins/', views.get_patient_checkins, name='get-patient-checkins'),
    path('patient/<str:patient_id>/baseline/', views.get_patient_baseline, name='get-patient-baseline'),
    path('patient/<str:patient_id>/baseline/update/', views.update_patient_baseline, name='update-patient-baseline'),
    path('patient/<str:patient_id>/change-password/', views.change_patient_password, name='change-patient-password'),
    path('patients/register/', views.register_patient, name='register-patient'),
    path('patients/search/', views.search_patients, name='search-patients'),
    path('patients/', views.list_all_patients, name='list-patients'),
    path('seed/', views.trigger_seed, name='trigger-seed'),
    path('typing/update/', views.update_typing_status, name='update-typing'),
    path('typing/status/', views.get_typing_status, name='typing-status'),
    
    # ==================== PHASE 2: APPOINTMENTS ====================
    path('appointments/', views.list_appointments, name='list-appointments'),
    path('appointments/create/', views.create_appointment, name='create-appointment'),
    path('appointments/<int:appointment_id>/', views.get_appointment, name='get-appointment'),
    path('appointments/<int:appointment_id>/update/', views.update_appointment, name='update-appointment'),
    path('appointments/<int:appointment_id>/complete/', views.complete_appointment, name='complete-appointment'),
    path('appointments/<int:appointment_id>/cancel/', views.cancel_appointment, name='cancel-appointment'),
    
    # ==================== PHASE 2: NOTIFICATIONS ====================
    path('notifications/', views.get_notifications, name='get-notifications'),
    path('notifications/<int:notification_id>/read/', views.mark_notification_read, name='mark-read'),
    path('notifications/<int:notification_id>/delete/', views.delete_notification, name='delete-notification'),
    path('alerts/check-high-risk/', views.check_high_risk_alerts, name='check-alerts'),
    
    # Router LAST
    path('', include(router.urls)),
]