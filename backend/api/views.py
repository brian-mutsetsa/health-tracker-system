import pickle
import os
import numpy as np
from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.contrib.auth import authenticate
from django.core.management import call_command
from .models import Patient, CheckIn, Message, Provider, TypingStatus
from .serializers import PatientSerializer, CheckInSerializer, CheckInCreateSerializer, MessageSerializer, ProviderSerializer, TypingStatusSerializer
from django.db import models
from django.utils import timezone

# Load ML model
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'ml_models', 'risk_model.pkl')
try:
    with open(MODEL_PATH, 'rb') as f:
        ml_model = pickle.load(f)
    print("✅ ML model loaded successfully")
except Exception as e:
    print(f"⚠️ ML model not found: {e}")
    ml_model = None


def predict_risk_with_ml(answers, condition):
    """Use ML model to predict risk"""
    if ml_model is None:
        return None, None
    
    # Count symptoms
    severe_count = sum(1 for v in answers.values() if v == 'Severe')
    mild_count = sum(1 for v in answers.values() if v == 'Mild')
    none_count = sum(1 for v in answers.values() if v == 'None')
    
    # Check medication (q7 is typically medication question)
    took_medication = 1 if answers.get('q7') == 'Yes' else 0
    
    # Encode condition
    condition_map = {'Hypertension': 0, 'Diabetes': 1, 'Heart Disease': 2}
    condition_code = condition_map.get(condition, 0)
    
    # Prepare features
    features = np.array([[severe_count, mild_count, none_count, took_medication, condition_code]])
    
    # Predict
    prediction = ml_model.predict(features)[0]
    confidence = ml_model.predict_proba(features)[0]
    
    # Map prediction to risk level
    risk_map = {0: 'GREEN', 1: 'YELLOW', 2: 'ORANGE', 3: 'RED'}
    risk_level = risk_map[prediction]
    
    # Get confidence for predicted class
    risk_confidence = confidence[prediction] * 100
    
    return risk_level, risk_confidence

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
    Authenticate a provider and return provider info.
    Expects username and password.
    """
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'error': 'Please provide both username and password'}, status=status.HTTP_400_BAD_REQUEST)

    user = authenticate(username=username, password=password)

    if user and hasattr(user, 'provider'):
        # Valid provider credentials
        return Response(ProviderSerializer(user.provider).data, status=status.HTTP_200_OK)
    else:
        return Response({'error': 'Invalid credentials or not a provider'}, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['GET'])
def trigger_seed(request):
    """
    Temporary endpoint to trigger database seeding.
    Needed because Render free tier does not provide SSH/terminal access.
    """
    try:
        call_command('seed_data')
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
