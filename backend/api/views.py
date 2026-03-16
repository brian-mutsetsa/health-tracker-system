import pickle
import os
import numpy as np
from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.contrib.auth import authenticate
from django.core.management import call_command
from .models import Patient, CheckIn, Message, Provider, TypingStatus, Appointment, Notification
from .serializers import (PatientSerializer, CheckInSerializer, CheckInCreateSerializer, 
                         MessageSerializer, ProviderSerializer, TypingStatusSerializer,
                         PatientRegistrationSerializer, PatientUpdateSerializer, PatientListSerializer,
                         AppointmentSerializer, NotificationSerializer)
from django.db import models
from django.utils import timezone
from django.db.models import Q

# Load ML model
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'ml_models', 'risk_model.pkl')
try:
    with open(MODEL_PATH, 'rb') as f:
        ml_model = pickle.load(f)
    print("✅ ML model loaded successfully")
except Exception as e:
    print(f"⚠️ ML model not found: {e}")
    ml_model = None


def predict_risk_with_ml(answers, condition, patient=None):
    """
    Use ML model to predict risk using 12-question format with baseline integration.
    
    answers: dict with q1-q12 keys, values 0-3 (int)
    condition: string (Hypertension, Diabetes, Cardiovascular)
    patient: Patient object (optional, for baseline data)
    """
    if ml_model is None:
        # Fallback to score-based calculation
        total_score = sum(answers.values()) if isinstance(next(iter(answers.values()), 0), int) else 0
        if total_score >= 24:
            return 'RED', 100
        elif total_score >= 16:
            return 'ORANGE', 80
        elif total_score >= 8:
            return 'YELLOW', 60
        else:
            return 'GREEN', 40
    
    try:
        # Convert string answers to integers if needed
        int_answers = {}
        for k, v in answers.items():
            if isinstance(v, str):
                scale = {'None': 0, 'Mild': 1, 'Moderate': 2, 'Severe': 3}
                int_answers[k] = scale.get(v, 0)
            else:
                int_answers[k] = v
        
        # Get 12 question scores
        question_scores = [int_answers.get(f'q{i}', 0) for i in range(1, 13)]
        
        # Calculate baseline deviations if patient data available
        systolic_dev = 0
        diastolic_dev = 0
        glucose_dev = 0
        
        if patient and patient.blood_pressure_systolic:
            # Current BP from optional fields in request
            current_systolic = answers.get('blood_pressure_systolic', patient.blood_pressure_systolic)
            systolic_dev = int(current_systolic) - int(patient.blood_pressure_systolic)
        
        if patient and patient.blood_pressure_diastolic:
            current_diastolic = answers.get('blood_pressure_diastolic', patient.blood_pressure_diastolic)
            diastolic_dev = int(current_diastolic) - int(patient.blood_pressure_diastolic)
        
        if patient and patient.blood_glucose_baseline:
            current_glucose = answers.get('blood_glucose_reading', patient.blood_glucose_baseline)
            glucose_dev = int(current_glucose) - int(patient.blood_glucose_baseline)
        
        # Medication adherence (q11 usually)
        medication = int_answers.get('q11', 0) / 3  # Normalize to 0-1
        
        # Condition encoding
        condition_map = {'Hypertension': 0, 'Diabetes': 1, 'Cardiovascular': 2, 'Heart Disease': 2}
        condition_code = condition_map.get(condition, 0)
        
        # Age normalization
        age = patient.get_age() if patient else 50
        age_normalized = (age - 25) / 60 if age else 0.5
        
        # Build feature vector (19 features)
        features = np.array([[
            *question_scores,  # q1-q12: 12 features
            systolic_dev, diastolic_dev, glucose_dev,  # 3 features
            medication, condition_code, age_normalized  # 3 features
        ]])
        
        # Predict
        prediction = ml_model.predict(features)[0]
        confidence = ml_model.predict_proba(features)[0]
        
        # Map prediction to risk level
        risk_map = {0: 'GREEN', 1: 'YELLOW', 2: 'ORANGE', 3: 'RED'}
        risk_level = risk_map[int(prediction)]
        risk_confidence = float(confidence[int(prediction)] * 100)
        
        return risk_level, risk_confidence
    except Exception as e:
        print(f"⚠️ ML prediction error: {e}")
        # Fallback to score calculation
        total_score = sum(question_scores) if 'question_scores' in locals() else 12
        if total_score >= 24:
            return 'RED', 90
        elif total_score >= 16:
            return 'ORANGE', 70
        elif total_score >= 8:
            return 'YELLOW', 50
        else:
            return 'GREEN', 30

class PatientViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Patient.objects.all()
    serializer_class = PatientSerializer


class CheckInViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = CheckIn.objects.all()
    serializer_class = CheckInSerializer


class MessageViewSet(viewsets.ModelViewSet):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer

    def get_queryset(self):
        queryset = Message.objects.all()
        user_id = self.request.query_params.get('user_id', None)
        other_id = self.request.query_params.get('other_id', None)
        
        if user_id and other_id:
            # Get messages between two specific users
            return queryset.filter(
                (models.Q(sender_id=user_id) & models.Q(receiver_id=other_id)) |
                (models.Q(sender_id=other_id) & models.Q(receiver_id=user_id))
            )
        elif user_id:
            # Get all messages for a specific user
            return queryset.filter(
                models.Q(sender_id=user_id) | models.Q(receiver_id=user_id)
            )
        return queryset


@api_view(['POST'])
def create_checkin(request):
    """
    Create a new check-in and update patient info
    Uses ML model for risk prediction if available
    """
    print(f"📥 Received check-in request: {request.data}")
    
    # Try ML prediction first
    ml_risk = None
    ml_confidence = None
    if ml_model is not None:
        try:
            ml_risk, ml_confidence = predict_risk_with_ml(
                request.data.get('answers', {}),
                request.data.get('condition', '')
            )
            print(f"🤖 ML Prediction: {ml_risk} (confidence: {ml_confidence:.1f}%)")
        except Exception as e:
            print(f"⚠️ ML prediction failed: {e}")
    
    # Add ML prediction to request data if available
    data = request.data.copy()
    if ml_risk:
        data['risk_level'] = ml_risk
        data['risk_color'] = ml_risk.lower()
    
    serializer = CheckInCreateSerializer(data=data)
    if serializer.is_valid():
        checkin = serializer.save()
        
        # Add ML confidence to response
        response_data = CheckInSerializer(checkin).data
        if ml_confidence:
            response_data['ml_confidence'] = round(ml_confidence, 2)
            response_data['ml_predicted'] = True
        
        print(f"✅ Check-in created successfully for patient: {checkin.patient.patient_id}")
        return Response(response_data, status=status.HTTP_201_CREATED)
    
    print(f"❌ Validation errors: {serializer.errors}")
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def get_patient_by_id(request, patient_id):
    """
    Get patient info by patient_id
    """
    try:
        patient = Patient.objects.get(patient_id=patient_id)
        return Response(PatientSerializer(patient).data)
    except Patient.DoesNotExist:
        return Response(
            {'error': 'Patient not found'},
            status=status.HTTP_404_NOT_FOUND
        )

@api_view(['POST'])
def provider_login(request):
    """
    Authenticate a provider with username and password.
    Response includes session token and provider info.
    """
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'error': 'Username and password required'}, status=status.HTTP_400_BAD_REQUEST)

    user = authenticate(username=username, password=password)

    if user and hasattr(user, 'provider'):
        # Valid provider
        response_data = ProviderSerializer(user.provider).data
        response_data['session_token'] = request.session.session_key  # Django session
        response_data['user_id'] = user.id
        return Response(response_data, status=status.HTTP_200_OK)
    else:
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['POST'])
def patient_login(request):
    """
    Authenticate a patient with patient_id and password.
    Response includes patient info and session token.
    """
    patient_id = request.data.get('patient_id')
    password = request.data.get('password')

    if not patient_id or not password:
        return Response({'error': 'Patient ID and password required'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        patient = Patient.objects.get(patient_id=patient_id)
        
        # Simple password check (in production, use hashed passwords)
        if patient.password == password:
            response_data = PatientSerializer(patient).data
            response_data['session_token'] = request.session.session_key
            response_data['patient_id'] = patient.patient_id
            return Response(response_data, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)
    except Patient.DoesNotExist:
        return Response({'error': 'Patient not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
def trigger_seed(request):
    """
    Temporary endpoint to trigger database seeding.
    Needed because Render free tier does not provide SSH/terminal access.
    """
    try:
        call_command('seed_test_data')
        return Response({'status': 'success', 'message': 'Database seeded successfully'}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'status': 'error', 'message': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
def update_typing_status(request):
    """
    Update typing status for a user chatting with another user.
    """
    user_id = request.data.get('user_id')
    chat_partner_id = request.data.get('chat_partner_id')
    is_typing = request.data.get('is_typing', False)

    if not user_id or not chat_partner_id:
        return Response({'error': 'user_id and chat_partner_id required'}, status=status.HTTP_400_BAD_REQUEST)

    # Convert to boolean if string provided
    if isinstance(is_typing, str):
        is_typing = is_typing.lower() == 'true'

    status_obj, created = TypingStatus.objects.update_or_create(
        user_id=user_id,
        chat_partner_id=chat_partner_id,
        defaults={'is_typing': is_typing}
    )
    
    return Response(TypingStatusSerializer(status_obj).data, status=status.HTTP_200_OK)


@api_view(['GET'])
def get_typing_status(request):
    """
    Check if a partner is currently typing to the requesting user.
    """
    user_id = request.query_params.get('user_id')
    partner_id = request.query_params.get('partner_id')

    if not user_id or not partner_id:
        return Response({'error': 'user_id and partner_id required'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Check if partner is typing to user
        status_obj = TypingStatus.objects.get(
            user_id=partner_id,
            chat_partner_id=user_id
        )
        
        # If the status is older than 10 seconds, assume they stopped typing
        time_diff = timezone.now() - status_obj.updated_at
        is_typing = status_obj.is_typing and time_diff.total_seconds() < 10

        return Response({
            'is_typing': is_typing,
            'last_updated': status_obj.updated_at
        }, status=status.HTTP_200_OK)
    except TypingStatus.DoesNotExist:
        return Response({'is_typing': False}, status=status.HTTP_200_OK)


# ==================== PATIENT REGISTRATION ENDPOINTS ====================

@api_view(['POST'])
def register_patient(request):
    """
    Register a new patient with baseline clinical data.
    Expected fields: patient_id, name, condition, date_of_birth, weight_kg, 
                    blood_pressure_systolic, blood_pressure_diastolic, blood_glucose_baseline,
                    medical_history, medications, allergies, primary_provider_id
    """
    serializer = PatientRegistrationSerializer(data=request.data)
    if serializer.is_valid():
        patient = serializer.save()
        print(f"✅ Patient registered: {patient.patient_id} - {patient.name}")
        return Response(PatientSerializer(patient).data, status=status.HTTP_201_CREATED)
    
    print(f"❌ Patient registration failed: {serializer.errors}")
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def search_patients(request):
    """
    Search patients by name, patient_id, condition, or status.
    Query parameters:
        - q: Search query (name or patient_id)
        - condition: Filter by condition
        - status: Filter by status
        - risk_level: Filter by last risk level (GREEN, YELLOW, ORANGE, RED)
    """
    query = request.query_params.get('q', '')
    condition_filter = request.query_params.get('condition', '')
    status_filter = request.query_params.get('status', '')
    risk_filter = request.query_params.get('risk_level', '')
    
    queryset = Patient.objects.all()
    
    # Text search
    if query:
        queryset = queryset.filter(
            Q(name__icontains=query) | Q(patient_id__icontains=query)
        )
    
    # Condition filter
    if condition_filter:
        queryset = queryset.filter(condition=condition_filter)
    
    # Status filter
    if status_filter:
        queryset = queryset.filter(status=status_filter)
    
    # Risk level filter
    if risk_filter:
        queryset = queryset.filter(last_risk_level=risk_filter)
    
    # Sort by most recently updated
    queryset = queryset.order_by('-updated_at')
    
    serializer = PatientListSerializer(queryset, many=True)
    return Response({
        'count': queryset.count(),
        'results': serializer.data
    })


@api_view(['GET'])
def get_patient_baseline(request, patient_id):
    """
    Get patient baseline clinical data.
    """
    try:
        patient = Patient.objects.get(patient_id=patient_id)
        data = {
            'patient_id': patient.patient_id,
            'name': patient.name,
            'date_of_birth': patient.date_of_birth,
            'weight_kg': patient.weight_kg,
            'blood_pressure_systolic': patient.blood_pressure_systolic,
            'blood_pressure_diastolic': patient.blood_pressure_diastolic,
            'blood_glucose_baseline': patient.blood_glucose_baseline,
            'medical_history': patient.medical_history,
            'medications': patient.medications,
            'allergies': patient.allergies,
        }
        return Response(data, status=status.HTTP_200_OK)
    except Patient.DoesNotExist:
        return Response(
            {'error': 'Patient not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['PUT'])
def update_patient_baseline(request, patient_id):
    """
    Update patient baseline clinical data.
    """
    try:
        patient = Patient.objects.get(patient_id=patient_id)
        serializer = PatientUpdateSerializer(patient, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            print(f"✅ Patient baseline updated: {patient.patient_id}")
            return Response(PatientSerializer(patient).data, status=status.HTTP_200_OK)
        print(f"❌ Baseline update failed: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Patient.DoesNotExist:
        return Response(
            {'error': 'Patient not found'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
def list_all_patients(request):
    """
    List all patients with pagination and filters.
    Query parameters:
        - page: Page number (default 1)
        - page_size: Results per page (default 20)
        - status: Filter by status (ACTIVE, INACTIVE, DISCHARGED)
        - condition: Filter by condition
    """
    page = int(request.query_params.get('page', 1))
    page_size = int(request.query_params.get('page_size', 20))
    status_filter = request.query_params.get('status', '')
    condition_filter = request.query_params.get('condition', '')
    
    queryset = Patient.objects.all()
    
    if status_filter:
        queryset = queryset.filter(status=status_filter)
    
    if condition_filter:
        queryset = queryset.filter(condition=condition_filter)
    
    # Sort by risk level (RED first), then by most recent check-in
    queryset = queryset.order_by('-last_risk_level', '-last_checkin')
    
    # Pagination
    start = (page - 1) * page_size
    end = start + page_size
    total_count = queryset.count()
    
    patients = queryset[start:end]
    serializer = PatientListSerializer(patients, many=True)
    
    return Response({
        'count': total_count,
        'page': page,
        'page_size': page_size,
        'total_pages': (total_count + page_size - 1) // page_size,
        'results': serializer.data
    })


# ==================== PHASE 2: APPOINTMENT MANAGEMENT ====================

@api_view(['POST'])
def create_appointment(request):
    """Create a new appointment"""
    serializer = AppointmentSerializer(data=request.data)
    if serializer.is_valid():
        appointment = serializer.save()
        print(f"✅ Appointment created: {appointment.id}")
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET'])
def list_appointments(request):
    """
    List appointments with optional filters.
    Query parameters:
        - patient_id: Filter by patient
        - provider_id: Filter by provider
        - status: Filter by status (SCHEDULED, COMPLETED, CANCELLED, NO_SHOW)
        - date_from: Start date (YYYY-MM-DD)
        - date_to: End date (YYYY-MM-DD)
    """
    queryset = Appointment.objects.all()
    
    patient_id = request.query_params.get('patient_id')
    provider_id = request.query_params.get('provider_id')
    appt_status = request.query_params.get('status')
    date_from = request.query_params.get('date_from')
    date_to = request.query_params.get('date_to')
    
    if patient_id:
        queryset = queryset.filter(patient__patient_id=patient_id)
    if provider_id:
        queryset = queryset.filter(provider_id=provider_id)
    if appt_status:
        queryset = queryset.filter(status=appt_status)
    if date_from:
        queryset = queryset.filter(scheduled_date__gte=date_from)
    if date_to:
        queryset = queryset.filter(scheduled_date__lte=date_to)
    
    queryset = queryset.order_by('-scheduled_date', '-scheduled_time')
    serializer = AppointmentSerializer(queryset, many=True)
    return Response({'count': queryset.count(), 'results': serializer.data})


@api_view(['GET'])
def get_appointment(request, appointment_id):
    """Get appointment details"""
    try:
        appointment = Appointment.objects.get(id=appointment_id)
        serializer = AppointmentSerializer(appointment)
        return Response(serializer.data)
    except Appointment.DoesNotExist:
        return Response({'error': 'Appointment not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['PUT'])
def update_appointment(request, appointment_id):
    """Update appointment (reschedule or add notes)"""
    try:
        appointment = Appointment.objects.get(id=appointment_id)
        serializer = AppointmentSerializer(appointment, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Appointment.DoesNotExist:
        return Response({'error': 'Appointment not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
def complete_appointment(request, appointment_id):
    """Mark appointment as completed"""
    try:
        appointment = Appointment.objects.get(id=appointment_id)
        appointment.status = 'COMPLETED'
        appointment.save()
        serializer = AppointmentSerializer(appointment)
        return Response(serializer.data)
    except Appointment.DoesNotExist:
        return Response({'error': 'Appointment not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
def cancel_appointment(request, appointment_id):
    """Cancel appointment"""
    try:
        appointment = Appointment.objects.get(id=appointment_id)
        appointment.status = 'CANCELLED'
        appointment.save()
        return Response({'status': 'cancelled', 'appointment_id': appointment_id})
    except Appointment.DoesNotExist:
        return Response({'error': 'Appointment not found'}, status=status.HTTP_404_NOT_FOUND)


# ==================== PHASE 2: NOTIFICATIONS & ALERTS ====================

@api_view(['GET'])
def get_notifications(request):
    """
    Get user's notifications.  
    Query parameters:
        - user_id: Required, the provider_id or patient_id
        - unread_only: If true, only return unread notifications
    """
    user_id = request.query_params.get('user_id')
    unread_only = request.query_params.get('unread_only', 'false').lower() == 'true'
    
    if not user_id:
        return Response({'error': 'user_id required'}, status=status.HTTP_400_BAD_REQUEST)
    
    queryset = Notification.objects.filter(user_id=user_id)
    if unread_only:
        queryset = queryset.filter(is_read=False)
    
    queryset = queryset.order_by('-created_at')
    serializer = NotificationSerializer(queryset, many=True)
    return Response({'count': queryset.count(), 'results': serializer.data})


@api_view(['PUT'])
def mark_notification_read(request, notification_id):
    """Mark a notification as read"""
    try:
        notification = Notification.objects.get(id=notification_id)
        notification.is_read = True
        notification.read_at = timezone.now()
        notification.save()
        serializer = NotificationSerializer(notification)
        return Response(serializer.data)
    except Notification.DoesNotExist:
        return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['DELETE'])
def delete_notification(request, notification_id):
    """Delete a notification"""
    try:
        notification = Notification.objects.get(id=notification_id)
        notification.delete()
        return Response({'status': 'deleted'})
    except Notification.DoesNotExist:
        return Response({'error': 'Notification not found'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['POST'])
def check_high_risk_alerts(request):
    """
    Check for high-risk patients and create alerts.
    This would typically be called by a scheduled task.
    Returns list of newly created alerts.
    """
    alerts_created = []
    
    # Find all RED risk patients from last 24 hours
    from datetime import timedelta
    cutoff_time = timezone.now() - timedelta(hours=24)
    
    high_risk_patients = Patient.objects.filter(
        last_risk_level='RED',
        last_checkin__gte=cutoff_time
    )
    
    for patient in high_risk_patients:
        if patient.primary_provider_id:
            # Check if alert already exists
            existing = Notification.objects.filter(
                user_id=patient.primary_provider_id,
                notification_type='HIGH_RISK_ALERT',
                related_patient_id=patient.patient_id,
                created_at__gte=cutoff_time
            ).exists()
            
            if not existing:
                alert = Notification.objects.create(
                    user_id=patient.primary_provider_id,
                    notification_type='HIGH_RISK_ALERT',
                    message=f'{patient.name or patient.patient_id} is at HIGH RISK - Immediate attention needed',
                    related_patient_id=patient.patient_id
                )
                alerts_created.append(NotificationSerializer(alert).data)
    
    return Response({
        'alerts_created': len(alerts_created),
        'results': alerts_created
    })
def list_all_patients(request):
    """
    List all patients with pagination and filters.
    Query parameters:
        - page: Page number (default 1)
        - page_size: Results per page (default 20)
        - status: Filter by status (ACTIVE, INACTIVE, DISCHARGED)
        - condition: Filter by condition
    """
    page = int(request.query_params.get('page', 1))
    page_size = int(request.query_params.get('page_size', 20))
    status_filter = request.query_params.get('status', '')
    condition_filter = request.query_params.get('condition', '')
    
    queryset = Patient.objects.all()
    
    if status_filter:
        queryset = queryset.filter(status=status_filter)
    
    if condition_filter:
        queryset = queryset.filter(condition=condition_filter)
    
    # Sort by risk level (RED first), then by most recent check-in
    queryset = queryset.order_by('-last_risk_level', '-last_checkin')
    
    # Pagination
    start = (page - 1) * page_size
    end = start + page_size
    total_count = queryset.count()
    
    patients = queryset[start:end]
    serializer = PatientListSerializer(patients, many=True)
    
    return Response({
        'count': total_count,
        'page': page,
        'page_size': page_size,
        'total_pages': (total_count + page_size - 1) // page_size,
        'results': serializer.data
    })
