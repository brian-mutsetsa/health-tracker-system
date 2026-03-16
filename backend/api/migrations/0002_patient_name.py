# Generated migration to add missing 'name' column to Patient model

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='patient',
            name='name',
            field=models.CharField(blank=True, max_length=200, default='Unknown'),
            preserve_default=False,
        ),
    ]
