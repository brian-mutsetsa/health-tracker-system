from django.db import models
from django.utils import timezone
from django.contrib.auth.models import User

class Provider(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    provider_id = models.CharField(max_length=100, unique=True)
    specialty = models.CharField(max_length=100, blank=True)
    hospital = models.CharField(max_length=100, blank=True)

    def __str__(self):
        return f"Dr. {self.user.last_name} ({self.provider_id})"


class Patient(models.Model):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('INACTIVE', 'Inactive'),
        ('DISCHARGED', 'Discharged'),
    ]
    
    patient_id = models.CharField(max_length=100, unique=True)
    name = models.CharField(max_length=200, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    condition = models.CharField(max_length=50)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    password = models.CharField(max_length=255, default='test123', help_text="Patient login password (hashed in production)")
    
    # Baseline clinical data
    weight_kg = models.FloatField(null=True, blank=True, help_text="Weight in kilograms")
    blood_pressure_systolic = models.IntegerField(null=True, blank=True, help_text="Baseline systolic BP (e.g., 120)")
    blood_pressure_diastolic = models.IntegerField(null=True, blank=True, help_text="Baseline diastolic BP (e.g., 80)")
    blood_glucose_baseline = models.IntegerField(null=True, blank=True, help_text="Baseline blood glucose in mg/dL")
    
    # Medical information
    medical_history = models.TextField(blank=True, help_text="Comma-separated medical conditions")
    medications = models.TextField(blank=True, help_text="Current medications")
    allergies = models.TextField(blank=True, help_text="Known allergies")
    
    # Provider assignment
    primary_provider_id = models.CharField(max_length=100, null=True, blank=True)
    
    # Check-in tracking
    last_checkin = models.DateTimeField(null=True, blank=True)
    last_risk_level = models.CharField(max_length=20, null=True, blank=True)
    last_risk_color = models.CharField(max_length=20, null=True, blank=True)
    
    # Timestamps
    registration_date = models.DateTimeField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.patient_id} - {self.name or 'Unknown'} ({self.condition})"
    
    def get_age(self):
        """Calculate age from date of birth"""
        if self.date_of_birth:
            from datetime import date
            today = date.today()
            return today.year - self.date_of_birth.year - ((today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day))
        return None

    class Meta:
        ordering = ['-updated_at']


class CheckIn(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='checkins')
    condition = models.CharField(max_length=50)
    date = models.DateTimeField()
    
    # 12 answers in JSON format - each answer 0-3 scale
    # Format: {"q1": 0, "q2": 1, ..., "q12": 3}
    answers = models.JSONField(help_text="12 answers, each 0-3 scale")
    
    # Optional numeric readings
    blood_pressure_systolic = models.IntegerField(null=True, blank=True, help_text="Patient's reading (if provided)")
    blood_pressure_diastolic = models.IntegerField(null=True, blank=True, help_text="Patient's reading (if provided)")
    blood_glucose_reading = models.IntegerField(null=True, blank=True, help_text="Patient's reading (if provided)")
    
    # Risk assessment
    risk_level = models.CharField(max_length=20)
    risk_color = models.CharField(max_length=20)
    
    # Timestamps
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.patient.patient_id} - {self.date.strftime('%Y-%m-%d')} - {self.risk_level}"

    class Meta:
        ordering = ['-date']

class Message(models.Model):
    sender_id = models.CharField(max_length=100)
    receiver_id = models.CharField(max_length=100)
    content = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return f"From {self.sender_id} to {self.receiver_id} at {self.timestamp}"

    class Meta:
        ordering = ['timestamp']

class TypingStatus(models.Model):
    user_id = models.CharField(max_length=100)
    chat_partner_id = models.CharField(max_length=100)
    is_typing = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user_id} typing to {self.chat_partner_id}: {self.is_typing}"

    class Meta:
        unique_together = ('user_id', 'chat_partner_id')
        indexes = [
            models.Index(fields=['user_id', 'chat_partner_id']),
        ]


class Appointment(models.Model):
    STATUS_CHOICES = [
        ('SCHEDULED', 'Scheduled'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
        ('NO_SHOW', 'No Show'),
    ]
    
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='appointments')
    provider_id = models.CharField(max_length=100)
    scheduled_date = models.DateField()
    scheduled_time = models.TimeField()
    duration_minutes = models.IntegerField(default=30)
    reason = models.CharField(max_length=200, blank=True)
    notes = models.TextField(blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='SCHEDULED')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Appointment: {self.patient.patient_id} - {self.scheduled_date} {self.scheduled_time}"

    class Meta:
        ordering = ['-scheduled_date', '-scheduled_time']


class Notification(models.Model):
    TYPE_CHOICES = [
        ('HIGH_RISK_ALERT', 'High Risk Alert'),
        ('DAILY_REMINDER', 'Daily Reminder'),
        ('APPOINTMENT', 'Appointment'),
        ('MESSAGE', 'Message'),
        ('GENERAL', 'General'),
    ]
    
    user_id = models.CharField(max_length=100)  # provider_id or patient_id
    notification_type = models.CharField(max_length=30, choices=TYPE_CHOICES)
    message = models.TextField()
    is_read = models.BooleanField(default=False)
    related_patient_id = models.CharField(max_length=100, null=True, blank=True)
    related_object_id = models.CharField(max_length=100, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.notification_type} - {self.user_id}"

    class Meta:
        ordering = ['-created_at']