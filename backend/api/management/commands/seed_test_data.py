from django.core.management.base import BaseCommand
from api.models import Patient, CheckIn, Provider, Appointment, Notification
from datetime import datetime, timedelta
import random


class Command(BaseCommand):
    help = 'Seed database with test data for demo and testing'

    def handle(self, *args, **options):
        self.stdout.write("🌱 Starting database seeding...")
        
        # Clear existing data (optional)
        # Patient.objects.all().delete()
        # CheckIn.objects.all().delete()
        # Provider.objects.all().delete()
        
        # Create providers (admin/doctors)
        print("\n📋 Creating providers...")
        providers = [
            {'name': 'Dr. Smith', 'specialty': 'Cardiology', 'user_id': 1},
            {'name': 'Dr. Johnson', 'specialty': 'Endocrinology', 'user_id': 2},
            {'name': 'Dr. Williams', 'specialty': 'Internal Medicine', 'user_id': 3},
        ]
        
        for provider_data in providers:
            try:
                provider = Provider.objects.get(name=provider_data['name'])
                self.stdout.write(f"✓ Provider {provider_data['name']} exists")
            except Provider.DoesNotExist:
                provider = Provider.objects.create(**provider_data)
                self.stdout.write(f"✓ Created provider: {provider_data['name']}")
        
        # Create test patients
        print("\n👥 Creating test patients...")
        patients_data = [
            {
                'patient_id': 'PT001',
                'name': 'John Doe',
                'date_of_birth': '1970-05-15',
                'condition': 'Hypertension',
                'password': 'test123',
                'weight_kg': 85.5,
                'blood_pressure_systolic': 140,
                'blood_pressure_diastolic': 90,
                'blood_glucose_baseline': None,
                'medical_history': 'Hypertension for 10 years',
                'medications': 'Lisinopril 10mg daily',
            },
            {
                'patient_id': 'PT002',
                'name': 'Jane Smith',
                'date_of_birth': '1965-03-22',
                'condition': 'Diabetes',
                'password': 'test123',
                'weight_kg': 72.0,
                'blood_pressure_systolic': 130,
                'blood_pressure_diastolic': 85,
                'blood_glucose_baseline': 156,
                'medical_history': 'Type 2 Diabetes for 5 years',
                'medications': 'Metformin 500mg twice daily',
            },
            {
                'patient_id': 'PT003',
                'name': 'Robert Wilson',
                'date_of_birth': '1955-07-10',
                'condition': 'Cardiovascular',
                'password': 'test123',
                'weight_kg': 92.0,
                'blood_pressure_systolic': 145,
                'blood_pressure_diastolic': 95,
                'blood_glucose_baseline': None,
                'medical_history': 'CAD, heart attack 2020',
                'medications': 'Aspirin 81mg, Atorvastatin 40mg daily',
            },
            {
                'patient_id': 'PT004',
                'name': 'Maria Garcia',
                'date_of_birth': '1975-11-30',
                'condition': 'Hypertension',
                'password': 'test123',
                'weight_kg': 68.5,
                'blood_pressure_systolic': 138,
                'blood_pressure_diastolic': 88,
                'blood_glucose_baseline': None,
                'medical_history': 'Hypertension, mild obesity',
                'medications': 'Amlodipine 5mg daily',
            },
            {
                'patient_id': 'PT005',
                'name': 'James Brown',
                'date_of_birth': '1960-02-14',
                'condition': 'Diabetes',
                'password': 'test123',
                'weight_kg': 95.0,
                'blood_pressure_systolic': 135,
                'blood_pressure_diastolic': 87,
                'blood_glucose_baseline': 172,
                'medical_history': 'Type 2 Diabetes, hypertension',
                'medications': 'Metformin, Gliclazide',
            },
        ]
        
        patients = {}
        for patient_data in patients_data:
            patient, created = Patient.objects.get_or_create(
                patient_id=patient_data['patient_id'],
                defaults=patient_data
            )
            patients[patient_data['patient_id']] = patient
            status = "Created" if created else "Exists"
            self.stdout.write(f"✓ {status}: {patient.name} ({patient.patient_id}) - {patient.condition}")
        
        # Create sample check-ins with varied risk levels
        print("\n📊 Creating sample check-ins...")
        
        now = datetime.now()
        
        # PT001 - GREEN (low risk) check-in from today
        CheckIn.objects.get_or_create(
            patient_id='PT001',
            date=now.date(),
            defaults={
                'condition': 'Hypertension',
                'answers': {
                    'q1': 'None', 'q2': 'None', 'q3': 'Mild',
                    'q4': 'None', 'q5': 'None', 'q6': 'Mild',
                    'q7': 'None', 'q8': 'Mild', 'q9': 'Yes',
                    'q10': 'None', 'q11': 'Low', 'q12': 'None'
                },
                'risk_level': 'GREEN',
                'risk_color': 'green',
                'risk_score': 5,
                'synced': True,
                'created_at': now,
                'updated_at': now,
            }
        )
        self.stdout.write("✓ PT001: GREEN risk checkin (today)")
        
        # PT001 - YELLOW (medium risk) from 3 days ago
        CheckIn.objects.get_or_create(
            patient_id='PT001',
            date=(now - timedelta(days=3)).date(),
            defaults={
                'condition': 'Hypertension',
                'answers': {
                    'q1': 'Mild', 'q2': 'Moderate', 'q3': 'Moderate',
                    'q4': 'Mild', 'q5': 'None', 'q6': 'Moderate',
                    'q7': 'None', 'q8': 'Mild', 'q9': 'Yes',
                    'q10': 'Moderate', 'q11': 'Moderate', 'q12': 'None'
                },
                'risk_level': 'YELLOW',
                'risk_color': 'yellow',
                'risk_score': 11,
                'synced': True,
                'created_at': now - timedelta(days=3),
                'updated_at': now - timedelta(days=3),
            }
        )
        self.stdout.write("✓ PT001: YELLOW risk checkin (3 days ago)")
        
        # PT002 - YELLOW from today
        CheckIn.objects.get_or_create(
            patient_id='PT002',
            date=now.date(),
            defaults={
                'condition': 'Diabetes',
                'answers': {
                    'q1': 'Mild', 'q2': 'Moderate', 'q3': 'Mild',
                    'q4': 'Moderate', 'q5': 'None', 'q6': 'None',
                    'q7': 'None', 'q8': 'Mild', 'q9': 'Missed once',
                    'q10': 'Moderate', 'q11': 'Moderate', 'q12': None
                },
                'risk_level': 'YELLOW',
                'risk_color': 'yellow',
                'risk_score': 10,
                'synced': True,
                'created_at': now,
                'updated_at': now,
            }
        )
        self.stdout.write("✓ PT002: YELLOW risk checkin (today)")
        
        # PT003 - ORANGE (high risk) from today - should trigger alert
        CheckIn.objects.get_or_create(
            patient_id='PT003',
            date=now.date(),
            defaults={
                'condition': 'Cardiovascular',
                'answers': {
                    'q1': 'Severe', 'q2': 'Moderate', 'q3': 'Moderate',
                    'q4': 'Moderate', 'q5': 'Moderate', 'q6': 'Moderate',
                    'q7': 'Mild', 'q8': 'Severe', 'q9': 'Missed more',
                    'q10': 'Moderate', 'q11': 'High', 'q12': None
                },
                'risk_level': 'ORANGE',
                'risk_color': 'orange',
                'risk_score': 18,
                'synced': True,
                'created_at': now,
                'updated_at': now,
            }
        )
        self.stdout.write("✓ PT003: ORANGE risk checkin (today) - HIGH RISK!")
        
        # PT004 - GREEN from today
        CheckIn.objects.get_or_create(
            patient_id='PT004',
            date=now.date(),
            defaults={
                'condition': 'Hypertension',
                'answers': {
                    'q1': 'None', 'q2': 'None', 'q3': 'None',
                    'q4': 'None', 'q5': 'None', 'q6': 'None',
                    'q7': 'None', 'q8': 'None', 'q9': 'Yes',
                    'q10': 'None', 'q11': 'Low', 'q12': 'None'
                },
                'risk_level': 'GREEN',
                'risk_color': 'green',
                'risk_score': 0,
                'synced': True,
                'created_at': now,
                'updated_at': now,
            }
        )
        self.stdout.write("✓ PT004: GREEN risk checkin (today)")
        
        # PT005 - RED (critical risk) - should definitely trigger alert
        CheckIn.objects.get_or_create(
            patient_id='PT005',
            date=now.date(),
            defaults={
                'condition': 'Diabetes',
                'answers': {
                    'q1': 'Severe', 'q2': 'Severe', 'q3': 'Severe',
                    'q4': 'Severe', 'q5': 'Severe', 'q6': 'Severe',
                    'q7': 'Severe', 'q8': 'Severe', 'q9': 'Never',
                    'q10': 'High', 'q11': 'High', 'q12': 'Very High'
                },
                'risk_level': 'RED',
                'risk_color': 'red',
                'risk_score': 27,
                'synced': True,
                'created_at': now,
                'updated_at': now,
            }
        )
        self.stdout.write("✓ PT005: RED risk checkin (today) - CRITICAL!")
        
        # Create appointments
        print("\n📅 Creating sample appointments...")
        
        Appointment.objects.get_or_create(
            patient_id='PT001',
            scheduled_date=now.date() + timedelta(days=7),
            scheduled_time='14:30',
            defaults={
                'provider_id': 1,
                'appointment_type': 'FOLLOW_UP',
                'reason': 'BP monitoring follow-up',
                'status': 'SCHEDULED',
                'notes': 'Check recent readings, adjust medication if needed',
                'created_at': now,
                'updated_at': now,
            }
        )
        self.stdout.write("✓ Appointment created: PT001 on " + str(now.date() + timedelta(days=7)))
        
        Appointment.objects.get_or_create(
            patient_id='PT003',
            scheduled_date=now.date() + timedelta(days=2),
            scheduled_time='10:00',
            defaults={
                'provider_id': 1,
                'appointment_type': 'EMERGENCY',
                'reason': 'High-risk patient review',
                'status': 'SCHEDULED',
                'notes': 'RED risk alert - urgent review needed',
                'created_at': now,
                'updated_at': now,
            }
        )
        self.stdout.write("✓ Appointment created: PT003 on " + str(now.date() + timedelta(days=2)) + " (EMERGENCY)")
        
        # Create some notifications
        print("\n🔔 Creating sample notifications...")
        
        Notification.objects.get_or_create(
            user_id=1,
            notification_type='HIGH_RISK_ALERT',
            defaults={
                'message': 'Patient PT005 (James Brown) has RED risk level (score: 27)',
                'is_read': False,
                'created_at': now,
            }
        )
        self.stdout.write("✓ Notification: HIGH_RISK_ALERT for PT005")
        
        Notification.objects.get_or_create(
            user_id=1,
            notification_type='HIGH_RISK_ALERT',
            defaults={
                'message': 'Patient PT003 (Robert Wilson) has ORANGE risk level (score: 18)',
                'is_read': False,
                'created_at': now,
            }
        )
        self.stdout.write("✓ Notification: HIGH_RISK_ALERT for PT003")
        
        print("\n✅ Database seeding complete!")
        print("\n📋 TEST CREDENTIALS:")
        print("=" * 50)
        print("MOBILE APP - Patient Login:")
        print("  Patient ID: PT001, PT002, PT003, PT004, PT005")
        print("  Password: test123")
        print("\nDASHBOARD - Admin Login:")
        print("  Username: admin")
        print("  Password: admin123")
        print("=" * 50)
