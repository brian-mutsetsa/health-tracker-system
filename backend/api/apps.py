from django.apps import AppConfig
from django.core.management import call_command


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
        except Exception as e:
            print(f"Startup error: {e}")
