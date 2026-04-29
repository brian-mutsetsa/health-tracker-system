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
    print(" ML model loaded successfully")
except Exception as e:
    print(f" ML model not found: {e}")
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
        print(f" ML prediction error: {e}")
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
    print(f" Received check-in request: {request.data}")
    
    # Try ML prediction first
    ml_risk = None
    ml_confidence = None
    if ml_model is not None:
        try:
            ml_risk, ml_confidence = predict_risk_with_ml(
                request.data.get('answers', {}),
                request.data.get('condition', '')
            )
            print(f" ML Prediction: {ml_risk} (confidence: {ml_confidence:.1f}%)")
        except Exception as e:
            print(f" ML prediction failed: {e}")
    
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
        
        print(f" Check-in created successfully for patient: {checkin.patient.patient_id}")
        return Response(response_data, status=status.HTTP_201_CREATED)
    
    print(f" Validation errors: {serializer.errors}")
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


@api_view(['GET'])
def get_patient_checkins(request, patient_id):
    """
    Get all check-ins for a specific patient (for mobile app history)
    Returns check-ins sorted by date (newest first)
    """
    try:
        patient = Patient.objects.get(patient_id=patient_id)
        checkins = CheckIn.objects.filter(patient=patient).order_by('-date')
        serializer = CheckInSerializer(checkins, many=True)
        return Response(serializer.data)
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
        if not user.is_active:
            return Response({'error': 'Account is disabled'}, status=status.HTTP_403_FORBIDDEN)
            
        response_data = ProviderSerializer(user.provider).data
        response_data['session_token'] = request.session.session_key  # Django session
        response_data['user_id'] = user.id
        return Response(response_data, status=status.HTTP_200_OK)
    else:
        # Check if they failed because they are deactivated
        from django.contrib.auth.models import User
        try:
            u = User.objects.get(username=username)
            if not u.is_active and u.check_password(password):
                return Response({'error': 'Account is disabled'}, status=status.HTTP_403_FORBIDDEN)
        except User.DoesNotExist:
            pass
            
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
        patient = Patient.objects.get(patient_id__iexact=patient_id.strip())
        
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
        from datetime import datetime, timedelta
        from django.db import connection
        
        print(" NUCLEAR RESET: Dropping and recreating ALL tables...")
        
        with connection.cursor() as cursor:
            # Drop all tables in correct order (respecting foreign keys)
            cursor.execute("DROP TABLE IF EXISTS api_typingstatus CASCADE;")
            cursor.execute("DROP TABLE IF EXISTS api_notification CASCADE;")
            cursor.execute("DROP TABLE IF EXISTS api_appointment CASCADE;")
            cursor.execute("DROP TABLE IF EXISTS api_checkin CASCADE;")
            cursor.execute("DROP TABLE IF EXISTS api_message CASCADE;")
            cursor.execute("DROP TABLE IF EXISTS api_provider CASCADE;")
            cursor.execute("DROP TABLE IF EXISTS api_patient CASCADE;")
            print(" Dropped all tables")
            
            # Recreate Patient table
            cursor.execute("""
                CREATE TABLE api_patient (
                    id BIGSERIAL PRIMARY KEY,
                    patient_id VARCHAR(100) UNIQUE NOT NULL,
                    name VARCHAR(200),
                    date_of_birth DATE,
                    condition VARCHAR(50) NOT NULL,
                    status VARCHAR(20) DEFAULT 'ACTIVE',
                    password VARCHAR(255) DEFAULT 'test123',
                    weight_kg DOUBLE PRECISION,
                    blood_pressure_systolic INTEGER,
                    blood_pressure_diastolic INTEGER,
                    blood_glucose_baseline INTEGER,
                    medical_history TEXT,
                    medications TEXT,
                    allergies TEXT,
                    primary_provider_id VARCHAR(100),
                    last_checkin TIMESTAMP,
                    last_risk_level VARCHAR(20),
                    last_risk_color VARCHAR(20),
                    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            print(" Recreated api_patient table")
            
            # Recreate CheckIn table
            cursor.execute("""
                CREATE TABLE api_checkin (
                    id BIGSERIAL PRIMARY KEY,
                    patient_id BIGINT NOT NULL REFERENCES api_patient(id) ON DELETE CASCADE,
                    condition VARCHAR(50) NOT NULL,
                    date TIMESTAMP NOT NULL,
                    answers JSONB NOT NULL,
                    blood_pressure_systolic INTEGER,
                    blood_pressure_diastolic INTEGER,
                    blood_glucose_reading INTEGER,
                    risk_level VARCHAR(20) NOT NULL,
                    risk_color VARCHAR(20) NOT NULL,
                    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            print(" Recreated api_checkin table")
            
            # Recreate Message table
            cursor.execute("""
                CREATE TABLE api_message (
                    id BIGSERIAL PRIMARY KEY,
                    sender_id VARCHAR(100) NOT NULL,
                    receiver_id VARCHAR(100) NOT NULL,
                    content TEXT NOT NULL,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    is_read BOOLEAN DEFAULT FALSE
                );
            """)
            print(" Recreated api_message table")
            
            # Recreate Appointment table
            cursor.execute("""
                CREATE TABLE api_appointment (
                    id BIGSERIAL PRIMARY KEY,
                    patient_id BIGINT NOT NULL REFERENCES api_patient(id) ON DELETE CASCADE,
                    provider_id VARCHAR(100) NOT NULL,
                    scheduled_date DATE NOT NULL,
                    scheduled_time TIME NOT NULL,
                    duration_minutes INTEGER DEFAULT 30,
                    reason VARCHAR(200),
                    notes TEXT,
                    status VARCHAR(20) DEFAULT 'SCHEDULED',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
            print(" Recreated api_appointment table")
            
            # Recreate Notification table
            cursor.execute("""
                CREATE TABLE api_notification (
                    id BIGSERIAL PRIMARY KEY,
                    user_id VARCHAR(100) NOT NULL,
                    notification_type VARCHAR(30) NOT NULL,
                    message TEXT NOT NULL,
                    is_read BOOLEAN DEFAULT FALSE,
                    related_patient_id VARCHAR(100),
                    related_object_id VARCHAR(100),
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    read_at TIMESTAMP
                );
            """)
            print(" Recreated api_notification table")
            
            # Recreate TypingStatus table
            cursor.execute("""
                CREATE TABLE api_typingstatus (
                    id BIGSERIAL PRIMARY KEY,
                    user_id VARCHAR(100) NOT NULL,
                    chat_partner_id VARCHAR(100) NOT NULL,
                    is_typing BOOLEAN DEFAULT FALSE,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, chat_partner_id)
                );
            """)
            print(" Recreated api_typingstatus table")
            
            # Recreate Provider table
            cursor.execute("""
                CREATE TABLE api_provider (
                    id BIGSERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL UNIQUE REFERENCES auth_user(id) ON DELETE CASCADE,
                    provider_id VARCHAR(100) UNIQUE NOT NULL,
                    specialty VARCHAR(100) DEFAULT '',
                    hospital VARCHAR(100) DEFAULT ''
                );
            """)
            print(" Recreated api_provider table")
        
        # Create provider Django user + Provider record
        print(" Creating provider account...")
        from django.contrib.auth.models import User
        
        # Delete existing provider users
        User.objects.filter(username__in=['admin', 'dr_hyper', 'dr_diab', 'dr_asthma', 'dr_cardio']).delete()
        
        providers_data = [
            {'username': 'admin', 'first': 'James', 'last': 'Wilson', 'spec': 'General Practice', 'id': 'DR001'},
            {'username': 'dr_hyper', 'first': 'Sarah', 'last': 'Jones', 'spec': 'Hypertension', 'id': 'DR002'},
            {'username': 'dr_diab', 'first': 'Michael', 'last': 'Chen', 'spec': 'Diabetes', 'id': 'DR003'},
            {'username': 'dr_asthma', 'first': 'Emily', 'last': 'Ndlovu', 'spec': 'Asthma', 'id': 'DR004'},
            {'username': 'dr_cardio', 'first': 'Robert', 'last': 'Smith', 'spec': 'Cardiovascular', 'id': 'DR005'},
        ]

        for p_data in providers_data:
            p_user = User.objects.create_user(
                username=p_data['username'],
                password='password',
                first_name=p_data['first'],
                last_name=p_data['last'],
                email=f"{p_data['username']}@healthtracker.co.zw"
            )
            Provider.objects.create(
                user=p_user,
                provider_id=p_data['id'],
                specialty=p_data['spec'],
                hospital='Harare Central Hospital'
            )
        print(f" Created 5 providers (General Practice + Specialists)")
        
        print(" Now seeding test patients...")
        
        from datetime import date
        
        patients_data = [
            {
                'patient_id': 'PT001',
                'name': 'Judy Moyo',
                'condition': 'Hypertension',
                'password': 'test123',
                'date_of_birth': date(1978, 3, 15),
                'weight_kg': 85.5,
                'blood_pressure_systolic': 140,
                'blood_pressure_diastolic': 90,
                'medical_history': 'Family history of hypertension',
                'medications': 'Amlodipine 5mg daily',
            },
            {
                'patient_id': 'PT002',
                'name': 'Ivan Chikara',
                'condition': 'Hypertension',
                'password': 'test123',
                'date_of_birth': date(1965, 7, 22),
                'weight_kg': 88.0,
                'blood_pressure_systolic': 145,
                'blood_pressure_diastolic': 95,
                'medical_history': 'Diagnosed 2019, mild kidney disease',
                'medications': 'Losartan 50mg daily',
            },
            {
                'patient_id': 'PT003',
                'name': 'Heidi Nkomo',
                'condition': 'Asthma',
                'password': 'test123',
                'date_of_birth': date(1990, 11, 8),
                'weight_kg': 65.0,
                'blood_pressure_systolic': 120,
                'blood_pressure_diastolic': 80,
                'medical_history': 'Childhood-onset asthma, seasonal allergies',
                'medications': 'Salbutamol inhaler PRN',
                'allergies': 'Dust, pollen',
            },
            {
                'patient_id': 'PT004',
                'name': 'Grace Zimuto',
                'condition': 'Heart Disease',
                'password': 'test123',
                'date_of_birth': date(1958, 1, 30),
                'weight_kg': 70.0,
                'blood_pressure_systolic': 130,
                'blood_pressure_diastolic': 85,
                'medical_history': 'MI in 2021, stent placed',
                'medications': 'Aspirin 75mg, Atorvastatin 40mg',
            },
            {
                'patient_id': 'PT005',
                'name': 'Frank Mutasa',
                'condition': 'Diabetes',
                'password': 'test123',
                'date_of_birth': date(1972, 5, 12),
                'weight_kg': 90.0,
                'blood_pressure_systolic': 135,
                'blood_pressure_diastolic': 87,
                'blood_glucose_baseline': 156,
                'medical_history': 'Type 2 diabetes diagnosed 2018',
                'medications': 'Metformin 500mg twice daily',
            },
        ]
        
        # Realistic checkin data per patient (5 checkins each, most recent first)
        # Each entry: (days_ago, risk_level, bp_sys, bp_dia, glucose, answer_pattern)
        checkin_profiles = {
            'PT001': [  # Hypertension - trending worse
                (0, 'ORANGE', 152, 96, None, [2, 2, 1, 3, 2, 1, 2, 2, 1, 2, 1, 0]),
                (3, 'YELLOW', 145, 92, None, [1, 2, 1, 2, 1, 1, 1, 2, 1, 1, 1, 0]),
                (7, 'YELLOW', 142, 90, None, [1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 0]),
                (14, 'GREEN', 135, 86, None, [0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0]),
                (21, 'GREEN', 130, 84, None, [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0]),
            ],
            'PT002': [  # Hypertension - stable high
                (0, 'RED', 165, 102, None, [3, 3, 2, 3, 2, 2, 3, 2, 2, 3, 2, 0]),
                (2, 'RED', 160, 100, None, [3, 2, 2, 3, 2, 2, 2, 3, 2, 2, 2, 0]),
                (5, 'ORANGE', 155, 97, None, [2, 2, 2, 2, 2, 1, 2, 2, 1, 2, 2, 0]),
                (10, 'ORANGE', 150, 95, None, [2, 2, 1, 2, 2, 1, 2, 1, 1, 2, 1, 0]),
                (17, 'YELLOW', 148, 93, None, [1, 2, 1, 2, 1, 1, 1, 2, 1, 1, 1, 0]),
            ],
            'PT003': [  # Asthma - well controlled
                (0, 'GREEN', 118, 78, None, [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0]),
                (4, 'GREEN', 120, 80, None, [0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]),
                (8, 'YELLOW', 122, 80, None, [1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0]),
                (15, 'GREEN', 119, 79, None, [0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0]),
                (22, 'GREEN', 120, 78, None, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
            ],
            'PT004': [  # Heart Disease - concerning trend
                (0, 'RED', 158, 98, None, [3, 2, 3, 3, 2, 2, 3, 2, 3, 2, 2, 0]),
                (1, 'ORANGE', 148, 92, None, [2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 1, 0]),
                (4, 'ORANGE', 145, 90, None, [2, 1, 2, 2, 1, 1, 2, 1, 2, 1, 1, 0]),
                (9, 'YELLOW', 138, 87, None, [1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 0]),
                (16, 'YELLOW', 135, 85, None, [1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 0]),
            ],
            'PT005': [  # Diabetes - fluctuating
                (0, 'YELLOW', 138, 88, 145, [1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 0]),
                (2, 'ORANGE', 142, 90, 210, [2, 2, 2, 2, 1, 2, 2, 2, 1, 2, 1, 0]),
                (6, 'GREEN', 132, 84, 120, [0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0]),
                (12, 'YELLOW', 136, 86, 165, [1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 0]),
                (20, 'RED', 148, 94, 280, [3, 2, 3, 3, 2, 2, 3, 2, 2, 3, 2, 0]),
            ],
        }
        
        now = datetime.now()
        patients_created = []
        
        for patient_data in patients_data:
            patient, created = Patient.objects.get_or_create(
                patient_id=patient_data['patient_id'],
                defaults=patient_data
            )
            
            if not created:
                for key, value in patient_data.items():
                    setattr(patient, key, value)
                patient.save()
            
            patients_created.append(patient)
            print(f" {patient.patient_id} - {patient.name} ({patient.condition}), DOB: {patient.date_of_birth}")
            
            # Create check-in history with realistic vitals
            profile = checkin_profiles[patient.patient_id]
            for i, (days_ago, risk, bp_sys, bp_dia, glucose, answers_list) in enumerate(profile):
                answers = {f'q{j+1}': v for j, v in enumerate(answers_list)}
                checkin = CheckIn.objects.create(
                    patient=patient,
                    condition=patient.condition,
                    date=now - timedelta(days=days_ago),
                    answers=answers,
                    blood_pressure_systolic=bp_sys,
                    blood_pressure_diastolic=bp_dia,
                    blood_glucose_reading=glucose,
                    risk_level=risk,
                    risk_color=risk.lower(),
                )
                print(f"   Check-in {i+1}/5 for {patient.patient_id} ({risk}, BP {bp_sys}/{bp_dia})")
            
            # Update patient tracking fields from most recent checkin (index 0)
            latest = profile[0]
            patient.last_checkin = now - timedelta(days=latest[0])
            patient.last_risk_level = latest[1]
            patient.last_risk_color = latest[1].lower()
            patient.save()
            print(f"   Updated {patient.patient_id}: last_risk={latest[1]}, last_checkin={patient.last_checkin}")
        
        # Create appointments for each patient
        print(" Creating appointments...")
        appointment_reasons = [
            'Blood pressure review', 'Routine follow-up', 'Medication review',
            'Lab results discussion', 'Annual physical exam',
        ]
        for idx, patient in enumerate(patients_created):
            offsets = [(2, '10:00'), (5, '14:30'), (10, '09:00')]
            for j, (days_offset, app_time) in enumerate(offsets):
                app_date = (now + timedelta(days=days_offset)).date()
                Appointment.objects.create(
                    patient=patient,
                    provider_id='DR001',
                    scheduled_date=app_date,
                    scheduled_time=app_time,
                    reason=appointment_reasons[(idx + j) % len(appointment_reasons)],
                    status='SCHEDULED'
                )
                print(f"   Appointment {app_date} {app_time} for {patient.patient_id}")
        
        # Create sample messages between patients and provider
        print(" Creating sample messages...")
        message_pairs = [
            ('PT001', 'DR001', 'Good morning doctor, my BP reading was 152/96 this morning.'),
            ('DR001', 'PT001', 'Thanks Judy. That is a bit high. Are you taking your Amlodipine?'),
            ('PT001', 'DR001', 'Yes, every morning with breakfast.'),
            ('DR001', 'PT001', 'Good. Please monitor for the next 3 days and let me know. Reduce salt intake.'),
            ('PT002', 'DR001', 'Doctor, I have been having headaches and dizziness since yesterday.'),
            ('DR001', 'PT002', 'Ivan, your last BP reading was very high. Please come in for an urgent review.'),
            ('PT004', 'DR001', 'I felt some chest tightness after walking today.'),
            ('DR001', 'PT004', 'Grace, please go to the nearest clinic immediately. Do not exert yourself.'),
            ('PT004', 'DR001', 'I went to the clinic, they said it was mild. I feel better now.'),
            ('DR001', 'PT004', 'Glad to hear. We will discuss this at your next appointment.'),
            ('PT005', 'DR001', 'My glucose was 280 last week but its down to 145 today.'),
            ('DR001', 'PT005', 'Good improvement Frank. Keep up the diet changes and take Metformin consistently.'),
        ]
        for i, (sender, receiver, content) in enumerate(message_pairs):
            Message.objects.create(
                sender_id=sender,
                receiver_id=receiver,
                content=content,
                is_read=(i < len(message_pairs) - 4),  # Last 4 messages unread
            )
        print(f"   Created {len(message_pairs)} messages")
        
        return Response({
            'status': 'success',
            'message': f' Database RESET and seeded with {len(patients_created)} test patients + appointments',
            'patients': [p.patient_id for p in patients_created]
        }, status=status.HTTP_200_OK)
    except Exception as e:
        import traceback
        error_detail = traceback.format_exc()
        print(f" Seeding error: {error_detail}")
        return Response({
            'status': 'error',
            'message': str(e),
            'details': error_detail
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


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
    patient_id is auto-generated (PT + sequential number).
    Expected fields: name, condition, password, date_of_birth, weight_kg, 
                    blood_pressure_systolic, blood_pressure_diastolic, blood_glucose_baseline,
                    medical_history, medications, allergies
    """
    data = request.data.copy()
    # Auto-generate patient_id if not provided
    if not data.get('patient_id'):
        last_patient = Patient.objects.order_by('-id').first()
        next_num = (last_patient.id + 1) if last_patient else 1
        data['patient_id'] = f'PT{next_num:04d}'
        # Ensure uniqueness
        while Patient.objects.filter(patient_id=data['patient_id']).exists():
            next_num += 1
            data['patient_id'] = f'PT{next_num:04d}'
    
    serializer = PatientRegistrationSerializer(data=data)
    if serializer.is_valid():
        patient = serializer.save()
        
        # Auto-assignment logic
        condition = patient.condition
        specialist = Provider.objects.filter(specialty__icontains=condition).first()
        gp = Provider.objects.filter(specialty__icontains='General Practice').first()
        
        if specialist:
            patient.primary_provider_id = specialist.provider_id
        elif gp:
            patient.primary_provider_id = gp.provider_id
            
        patient.save()
        
        print(f" Patient registered: {patient.patient_id} - {patient.name}")
        return Response(PatientSerializer(patient).data, status=status.HTTP_201_CREATED)
    
    print(f" Patient registration failed: {serializer.errors}")
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
    provider_id = request.query_params.get('provider_id', '')
    
    queryset = Patient.objects.all()
    
    # Provider-based routing
    if provider_id:
        try:
            provider = Provider.objects.get(provider_id=provider_id)
            if provider.specialty and 'General Practice' not in provider.specialty:
                # Specialists only see patients with their matching condition
                queryset = queryset.filter(condition__icontains=provider.specialty)
            # GPs see everyone, so no filter needed
        except Provider.DoesNotExist:
            pass
    
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
            print(f" Patient baseline updated: {patient.patient_id}")
            return Response(PatientSerializer(patient).data, status=status.HTTP_200_OK)
        print(f" Baseline update failed: {serializer.errors}")
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
    provider_id = request.query_params.get('provider_id', '')
    
    queryset = Patient.objects.all()
    
    # Provider-based routing
    if provider_id:
        try:
            provider = Provider.objects.get(provider_id=provider_id)
            if provider.specialty and 'General Practice' not in provider.specialty:
                # Specialists only see patients with their matching condition
                queryset = queryset.filter(condition__icontains=provider.specialty)
        except Provider.DoesNotExist:
            pass
    
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
    data = request.data.copy()
    # Allow client to send patient_id (string) instead of patient (FK int)
    if 'patient_id' in data and 'patient' not in data:
        try:
            patient = Patient.objects.get(patient_id=data['patient_id'])
            data['patient'] = patient.id
        except Patient.DoesNotExist:
            return Response({'error': f"Patient {data['patient_id']} not found"}, status=status.HTTP_404_NOT_FOUND)
    serializer = AppointmentSerializer(data=data)
    if serializer.is_valid():
        appointment = serializer.save()
        print(f" Appointment created: {appointment.id}")
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
        # Check if alert already exists for this patient
        existing_alert = Notification.objects.filter(
            user_id=patient.primary_provider_id or 'admin',
            related_patient_id=patient.patient_id,
            notification_type='HIGH_RISK_ALERT'
        ).first()
        
        if not existing_alert:
            alert = Notification.objects.create(
                user_id=patient.primary_provider_id or 'admin',
                notification_type='HIGH_RISK_ALERT',
                message=f' HIGH RISK ALERT: Patient {patient.patient_id} ({patient.name}) has RED risk level',
                related_patient_id=patient.patient_id
            )
            alerts_created.append(alert)
            print(f"🚨 Alert created for {patient.patient_id}")
    
    serializer = NotificationSerializer(alerts_created, many=True)
    return Response({
        'status': 'success',
        'alerts_created': len(alerts_created),
        'alerts': serializer.data
    }, status=status.HTTP_200_OK)
