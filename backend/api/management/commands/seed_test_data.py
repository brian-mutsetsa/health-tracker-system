from django.core.management.base import BaseCommand
from api.models import Patient, CheckIn
from datetime import datetime, timedelta


class Command(BaseCommand):
    help = 'Seed database with test data - ensures test patients exist with proper credentials'

    def handle(self, *args, **options):
        self.stdout.write("🌱 Seeding test patients with credentials...")
        
        # Test patients - matching the actual dashboard patient names
        patients_data = [
            {
                'patient_id': 'Judy',
                'condition': 'Hypertension',
                'password': 'test123',
                'weight_kg': 85.5,
                'blood_pressure_systolic': 140,
                'blood_pressure_diastolic': 90,
            },
            {
                'patient_id': 'Ivan',
                'condition': 'Hypertension',
                'password': 'test123',
                'weight_kg': 88.0,
                'blood_pressure_systolic': 145,
                'blood_pressure_diastolic': 95,
            },
            {
                'patient_id': 'Heidi',
                'condition': 'Asthma',
                'password': 'test123',
                'weight_kg': 65.0,
                'blood_pressure_systolic': 120,
                'blood_pressure_diastolic': 80,
            },
            {
                'patient_id': 'Grace',
                'condition': 'Heart Disease',
                'password': 'test123',
                'weight_kg': 70.0,
                'blood_pressure_systolic': 130,
                'blood_pressure_diastolic': 85,
            },
            {
                'patient_id': 'Frank',
                'condition': 'Diabetes',
                'password': 'test123',
                'weight_kg': 90.0,
                'blood_pressure_systolic': 135,
                'blood_pressure_diastolic': 87,
                'blood_glucose_baseline': 156,
            },
        ]
        
        now = datetime.now()
        patients_created = []
        
        for patient_data in patients_data:
            patient, created = Patient.objects.get_or_create(
                patient_id=patient_data['patient_id'],
                defaults=patient_data
            )
            
            # If patient already exists, update password and vitals
            if not created:
                patient.password = patient_data['password']
                patient.weight_kg = patient_data['weight_kg']
                patient.blood_pressure_systolic = patient_data['blood_pressure_systolic']
                patient.blood_pressure_diastolic = patient_data['blood_pressure_diastolic']
                if 'blood_glucose_baseline' in patient_data:
                    patient.blood_glucose_baseline = patient_data['blood_glucose_baseline']
                patient.save()
            
            status = "✓ Created" if created else "✓ Updated"
            self.stdout.write(f"{status}: {patient.patient_id} - {patient.condition}")
            patients_created.append(patient)
            
            # Ensure each patient has at least 5 check-ins (for dashboard history)
            existing_checkins = CheckIn.objects.filter(patient=patient).count()
            if existing_checkins == 0:
                self.stdout.write(f"  Creating check-in history for {patient.patient_id}...")
                # Create 5 check-ins with varied risk levels
                risk_levels = ['GREEN', 'YELLOW', 'ORANGE', 'RED', 'GREEN']
                for i, risk in enumerate(risk_levels):
                    CheckIn.objects.create(
                        patient=patient,
                        condition=patient.condition,
                        date=now - timedelta(days=i),
                        answers={
                            'q1': i, 'q2': i, 'q3': i,
                            'q4': i, 'q5': i, 'q6': i,
                            'q7': i, 'q8': i, 'q9': i,
                            'q10': i, 'q11': i, 'q12': None
                        },
                        risk_level=risk,
                        risk_color=risk.lower(),
                    )
        
        self.stdout.write(self.style.SUCCESS(f"\n✅ Successfully seeded {len(patients_created)} test patients!"))
        self.stdout.write("\n📱 Mobile App Login Test Credentials:")
        self.stdout.write("Patient ID: Judy (or Ivan, Heidi, Grace, Frank)")
        self.stdout.write("Password: test123")
