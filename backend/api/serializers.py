from rest_framework import serializers
from .models import Patient, CheckIn, Message, Provider


class ProviderSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Provider
        fields = ['id', 'provider_id', 'specialty', 'hospital', 'username', 'first_name', 'last_name']
        read_only_fields = ['id']


class CheckInSerializer(serializers.ModelSerializer):
    class Meta:
        model = CheckIn
        fields = ['id', 'patient', 'condition', 'date', 'answers', 'risk_level', 'risk_color', 'uploaded_at']
        read_only_fields = ['id', 'uploaded_at']


class PatientSerializer(serializers.ModelSerializer):
    checkins = CheckInSerializer(many=True, read_only=True)
    total_checkins = serializers.SerializerMethodField()

    class Meta:
        model = Patient
        fields = ['id', 'patient_id', 'condition', 'last_checkin', 'last_risk_level', 
                  'last_risk_color', 'created_at', 'updated_at', 'checkins', 'total_checkins']
        read_only_fields = ['id', 'created_at', 'updated_at']

    def get_total_checkins(self, obj):
        return obj.checkins.count()


class CheckInCreateSerializer(serializers.Serializer):
    patient_id = serializers.CharField(max_length=100)
    condition = serializers.CharField(max_length=50)
    date = serializers.DateTimeField()
    answers = serializers.JSONField()
    risk_level = serializers.CharField(max_length=20)
    risk_color = serializers.CharField(max_length=20)

    def create(self, validated_data):
        patient_id = validated_data.pop('patient_id')
        
        # Get or create patient
        patient, created = Patient.objects.get_or_create(
            patient_id=patient_id,
            defaults={'condition': validated_data['condition']}
        )
        
        # Update patient's last check-in info
        patient.last_checkin = validated_data['date']
        patient.last_risk_level = validated_data['risk_level']
        patient.last_risk_color = validated_data['risk_color']
        patient.save()
        
        # Create check-in
        checkin = CheckIn.objects.create(patient=patient, **validated_data)
        return checkin


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['id', 'sender_id', 'receiver_id', 'content', 'timestamp', 'is_read']
        read_only_fields = ['id', 'timestamp']