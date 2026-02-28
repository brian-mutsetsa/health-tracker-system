import pickle
import os
import numpy as np
from rest_framework import viewsets, status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Patient, CheckIn
from .serializers import PatientSerializer, CheckInSerializer, CheckInCreateSerializer

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
    took_medication = 1 if answers.get('q7') == 'None' else 0
    
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