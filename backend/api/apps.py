from django.apps import AppConfig
from django.core.management import call_command


class ApiConfig(AppConfig):
    name = "api"
    
    def ready(self):
        """Run migrations automatically on app startup"""
        try:
            call_command('migrate', verbosity=1)
            print("Database migrations completed")
        except Exception as e:
            print(f"Migration error (may be normal if migrations already ran): {e}")
