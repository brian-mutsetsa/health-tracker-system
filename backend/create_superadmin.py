import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "health_tracker.settings")
django.setup()

from django.contrib.auth.models import User

username = 'superadmin'
password = 'adminpassword123'
email = 'superadmin@example.com'

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username, email, password)
    print(f"Superuser created! Username: {username}, Password: {password}")
else:
    # If it exists, let's just force set the password so we know what it is
    u = User.objects.get(username=username)
    u.set_password(password)
    u.is_superuser = True
    u.is_staff = True
    u.save()
    print(f"Superuser updated! Username: {username}, Password: {password}")
