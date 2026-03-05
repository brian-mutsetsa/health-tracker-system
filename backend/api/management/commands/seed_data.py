import random
from datetime import timedelta
from django.utils import timezone
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from api.models import Patient, CheckIn, Message, Provider

class Command(BaseCommand):
    help = 'Wipes the database and populates it with realistic dummy data for testing the dashboard'

    def handle(self, *args, **kwargs):
        self.stdout.write('Wiping existing data...')
        
        # Wipe all records
        CheckIn.objects.all().delete()
        Message.objects.all().delete()
        Patient.objects.all().delete()
        Provider.objects.all().delete()
        User.objects.filter(is_superuser=False).delete() # Keep superusers

        self.stdout.write('Creating Provider Account...')
        
        # Create or get Provider Admin
        user, created = User.objects.get_or_create(
            username='admin',
            defaults={
                'password': 'password',
                'first_name': 'Olivia',
                'last_name': 'Grant'
            }
        )
        if created:
            user.set_password('password')
            user.save()
            self.stdout.write('Created new admin user')
        else:
            self.stdout.write('Admin user already exists')
        
        # Create or get provider
        provider, created = Provider.objects.get_or_create(
            user=user,
            defaults={
                'provider_id': 'PRV-7892',
                'specialty': 'Family Medicine',
                'hospital': 'Mercy General'
            }
        )
        
        provider_id = 'provider' # the ID used historically in the frontend messages logic
        
        self.stdout.write('Creating Patients...')

        PATIENTS_DATA = [
            {'id': 'P-10041', 'name': 'Sarah Jenkins', 'condition': 'Diabetes', 'risk': 'ORANGE'},
            {'id': 'P-10042', 'name': 'Michael Chang', 'condition': 'Hypertension', 'risk': 'YELLOW'},
            {'id': 'P-10043', 'name': 'Emma Watson', 'condition': 'Heart Disease', 'risk': 'RED'},
            {'id': 'P-10044', 'name': 'James Miller', 'condition': 'Diabetes', 'risk': 'GREEN'},
            {'id': 'P-10045', 'name': 'Anita Desai', 'condition': 'Hypertension', 'risk': 'GREEN'},
            {'id': 'P-10046', 'name': 'Robert Taylor', 'condition': 'Heart Disease', 'risk': 'ORANGE'},
            {'id': 'P-10047', 'name': 'Linda Martinez', 'condition': 'Diabetes', 'risk': 'YELLOW'},
            {'id': 'P-10048', 'name': 'William Brown', 'condition': 'Hypertension', 'risk': 'RED'}
        ]

        now = timezone.now()
        
        for p_data in PATIENTS_DATA:
            patient = Patient.objects.create(
                patient_id=p_data['id'],
                condition=p_data['condition'],
                last_risk_level=p_data['risk'],
                last_risk_color=p_data['risk'].lower(),
                last_checkin=now - timedelta(hours=random.randint(1, 48))
            )
            
            # Create Check-ins timeline (last 7 days)
            for i in range(7):
                date = now - timedelta(days=i, hours=random.randint(0, 5))
                is_recent = i == 0
                
                # Match the latest checkin risk level to the patient's current risk level to reflect the UI
                risk_level = p_data['risk'] if is_recent else random.choice(['GREEN', 'YELLOW', 'ORANGE', 'RED'])
                
                answers = {
                    'q1': random.choice(['None', 'Mild', 'Severe']),
                    'q2': random.choice(['None', 'Mild', 'Severe']),
                    'q3': random.choice(['Yes', 'No'])
                }
                
                CheckIn.objects.create(
                    patient=patient,
                    condition=p_data['condition'],
                    date=date,
                    answers=answers,
                    risk_level=risk_level,
                    risk_color=risk_level.lower()
                )

            # Create Messages
            Message.objects.create(
                sender_id=provider_id,
                receiver_id=patient.patient_id,
                content=f"Hello {p_data['name'].split()[0]}, please remember to log your check-in today.",
                timestamp=now - timedelta(days=2)
            )
            
            Message.objects.create(
                sender_id=patient.patient_id,
                receiver_id=provider_id,
                content="I just submitted my check-in. I'm feeling a bit dizzy today.",
                timestamp=now - timedelta(days=1, hours=2)
            )
            
            if p_data['risk'] in ['ORANGE', 'RED']:
                Message.objects.create(
                    sender_id=provider_id,
                    receiver_id=patient.patient_id,
                    content="I saw your check-in risk was high today. Did you take your medication?",
                    timestamp=now - timedelta(hours=5)
                )
                Message.objects.create(
                    sender_id=patient.patient_id,
                    receiver_id=provider_id,
                    content="Yes I did, just 10 minutes ago.",
                    timestamp=now - timedelta(hours=4)
                )

        self.stdout.write(self.style.SUCCESS('Successfully seeded database! Login with username: admin | password: password'))
