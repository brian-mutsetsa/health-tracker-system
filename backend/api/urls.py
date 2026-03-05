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
    path('checkin/submit/', views.create_checkin, name='create-checkin'),
    path('patient/<str:patient_id>/', views.get_patient_by_id, name='get-patient'),
    # Router LAST
    path('', include(router.urls)),
]