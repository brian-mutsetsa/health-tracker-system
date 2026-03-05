from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from api.models import Provider, Patient, CheckIn, Message
from django.utils import timezone
from datetime import timedelta
import random

class Command(BaseCommand):
    help = 'Seed the database with a provider and multiple patients'

    def handle(self, *args, **kwargs):
        self.stdout.write('Clearing old data...')
        # Clear data
        User.objects.all().delete()
        Provider.objects.all().delete()
        Patient.objects.all().delete()
        CheckIn.objects.all().delete()
        Message.objects.all().delete()

        self.stdout.write('Creating admin provider...')
        admin_user = User.objects.create_superuser('admin', 'admin@example.com', 'password')
        admin_user.last_name = "Smith"
        admin_user.save()
        
        provider = Provider.objects.create(
            user=admin_user,
            provider_id='provider',
            specialty='Cardiology',
            hospital='General Hospital'
        )

        conditions = ['Hypertension', 'Diabetes', 'Heart Disease', 'Asthma']
        names = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Heidi', 'Ivan', 'Judy']
        risk_levels = ['GREEN', 'YELLOW', 'ORANGE', 'RED']

        patients = []
        for name in names:
            last_risk = random.choice(risk_levels)
            p = Patient.objects.create(
                patient_id=name,
                condition=random.choice(conditions),
                last_risk_level=last_risk,
                last_risk_color=last_risk.lower(),
                last_checkin=timezone.now()
            )
            patients.append(p)

            # Generate 15 check-ins for the last 15 days
            for i in range(15):
                date = timezone.now() - timedelta(days=i)
                CheckIn.objects.create(
                    patient=p,
                    condition=p.condition,
                    date=date,
                    answers={'q1': 'None', 'q2': 'Mild', 'q3': 'None', 'q7': random.choice(['Yes', 'No'])},
                    risk_level=last_risk,
                    risk_color=last_risk.lower()
                )
            
            # Update the patient's checkin count
            # Actually CheckIn signal would do it, but we can just leave it as is or calculate it via views.
            
            # Generate messages
            Message.objects.create(
                sender_id=p.patient_id,
                receiver_id='provider',
                content=f'Hello Dr. Smith, my {p.condition} seems to be okay today.',
                is_read=False
            )
            Message.objects.create(
                sender_id='provider',
                receiver_id=p.patient_id,
                content=f'That is great to hear, {p.patient_id}. Remember to take your meds.',
                is_read=True
            )

        self.stdout.write(self.style.SUCCESS('Successfully seeded database! Use username: admin, password: password'))
