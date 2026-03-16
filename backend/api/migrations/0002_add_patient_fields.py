# Comprehensive migration to add all missing columns to Patient model
# This fixes the schema mismatch that was preventing the app from running

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0001_initial'),
    ]

    operations = [
        # Add all missing Patient fields
        migrations.AddField(
            model_name='patient',
            name='name',
            field=models.CharField(blank=True, max_length=200, default='Unknown'),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='patient',
            name='date_of_birth',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='weight_kg',
            field=models.FloatField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='blood_pressure_systolic',
            field=models.IntegerField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='blood_pressure_diastolic',
            field=models.IntegerField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='blood_glucose_baseline',
            field=models.IntegerField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='medical_history',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='medications',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='allergies',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='primary_provider_id',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='last_checkin',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='last_risk_level',
            field=models.CharField(blank=True, max_length=20, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='last_risk_color',
            field=models.CharField(blank=True, max_length=20, null=True),
        ),
    ]
