from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from api.models import Provider

class Command(BaseCommand):
    help = 'Create default provider admin account if it does not exist'

    def handle(self, *args, **kwargs):
        if User.objects.filter(username='admin').exists():
            self.stdout.write(self.style.SUCCESS('✅ Admin user already exists'))
            return
        
        try:
            user = User.objects.create_user(
                username='admin',
                password='password',
                first_name='Olivia',
                last_name='Grant'
            )
            provider = Provider.objects.create(
                user=user,
                provider_id='PRV-7892',
                specialty='Family Medicine',
                hospital='Mercy General'
            )
            self.stdout.write(self.style.SUCCESS('✅ Created admin user and provider account'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'❌ Error: {e}'))
