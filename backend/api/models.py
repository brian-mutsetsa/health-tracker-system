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
    patient_id = models.CharField(max_length=100, unique=True)
    condition = models.CharField(max_length=50)
    last_checkin = models.DateTimeField(null=True, blank=True)
    last_risk_level = models.CharField(max_length=20, null=True, blank=True)
    last_risk_color = models.CharField(max_length=20, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.patient_id} - {self.condition}"

    class Meta:
        ordering = ['-updated_at']


class CheckIn(models.Model):
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE, related_name='checkins')
    condition = models.CharField(max_length=50)
    date = models.DateTimeField()
    answers = models.JSONField()
    risk_level = models.CharField(max_length=20)
    risk_color = models.CharField(max_length=20)
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