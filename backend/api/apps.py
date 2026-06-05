from django.apps import AppConfig
from django.core.management import call_command
import threading
import time
from datetime import datetime


def automated_reminders_loop():
    """
    Background thread that checks the time every minute and sends automated
    medication reminders to patients at exactly 09:00, 12:00, 15:00, and 18:00.
    """
    last_run_hour = -1
    
    while True:
        now = datetime.now()
        # Check if it's the exact hour for our reminders (9, 12, 15, 18)
        if now.hour in [9, 12, 15, 18] and now.minute == 0:
            if last_run_hour != now.hour:
                try:
                    from api.models import Patient, Notification
                    
                    patients = Patient.objects.filter(status='ACTIVE')
                    count = 0
                    for patient in patients:
                        Notification.objects.create(
                            user_id=patient.patient_id,
                            notification_type='MEDICATION',
                            message=f"Automated Reminder: Please remember to take your {now.hour}:00 medication.",
                            related_patient_id=patient.patient_id
                        )
                        count += 1
                        
                    # Notify dr_hyper that it was sent
                    Notification.objects.create(
                        user_id='dr_hyper',
                        notification_type='GENERAL',
                        message=f"System Automaton: Automated Medication Reminders successfully dispatched to {count} patients at {now.hour}:00."
                    )
                    
                    last_run_hour = now.hour
                except Exception as e:
                    print(f"Automated reminder error: {e}")
                    
        time.sleep(30)


class ApiConfig(AppConfig):
    name = "api"
    
    def ready(self):
        """Run migrations automatically on app startup"""
        try:
            call_command('migrate', verbosity=0)
            print("Database migrations completed")
            
            from django.contrib.auth.models import User
            if not User.objects.filter(username='superadmin').exists():
                User.objects.create_superuser('superadmin', 'superadmin@example.com', 'adminpassword123')
                print("Superuser created successfully.")
                
            call_command('seed_data', verbosity=0)
            print("Test data seeded successfully.")
            
            # Start background thread for reminders
            t = threading.Thread(target=automated_reminders_loop, daemon=True)
            t.start()
            print("Automated reminders background thread started.")
            
        except Exception as e:
            print(f"Startup error: {e}")
