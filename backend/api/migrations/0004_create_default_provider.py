from django.db import migrations
from django.contrib.auth.models import User

def create_default_provider(apps, schema_editor):
    Provider = apps.get_model('api', 'Provider')
    
    # Only create if it doesn't exist
    if not User.objects.filter(username='admin').exists():
        user = User.objects.create_user(
            username='admin',
            password='password',
            first_name='Olivia',
            last_name='Grant'
        )
        Provider.objects.create(
            user=user,
            provider_id='PRV-7892',
            specialty='Family Medicine',
            hospital='Mercy General'
        )

def reverse_function(apps, schema_editor):
    User = apps.get_model('auth', 'User')
    User.objects.filter(username='admin').delete()

class Migration(migrations.Migration):

    dependencies = [
        ('api', '0003_provider'),
    ]

    operations = [
        migrations.RunPython(create_default_provider, reverse_function),
    ]
