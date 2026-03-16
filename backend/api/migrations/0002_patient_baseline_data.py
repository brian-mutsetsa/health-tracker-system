# Generated migration for Patient baseline data and CheckIn updates

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0001_initial'),
    ]

    operations = [
        # Add baseline data fields to Patient model
        migrations.AddField(
            model_name='patient',
            name='name',
            field=models.CharField(blank=True, max_length=200, default=''),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='patient',
            name='date_of_birth',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='status',
            field=models.CharField(
                choices=[('ACTIVE', 'Active'), ('INACTIVE', 'Inactive'), ('DISCHARGED', 'Discharged')],
                default='ACTIVE',
                max_length=20
            ),
        ),
        migrations.AddField(
            model_name='patient',
            name='weight_kg',
            field=models.FloatField(blank=True, null=True, help_text='Weight in kilograms'),
        ),
        migrations.AddField(
            model_name='patient',
            name='blood_pressure_systolic',
            field=models.IntegerField(blank=True, null=True, help_text='Baseline systolic BP (e.g., 120)'),
        ),
        migrations.AddField(
            model_name='patient',
            name='blood_pressure_diastolic',
            field=models.IntegerField(blank=True, null=True, help_text='Baseline diastolic BP (e.g., 80)'),
        ),
        migrations.AddField(
            model_name='patient',
            name='blood_glucose_baseline',
            field=models.IntegerField(blank=True, null=True, help_text='Baseline blood glucose in mg/dL'),
        ),
        migrations.AddField(
            model_name='patient',
            name='medical_history',
            field=models.TextField(blank=True, help_text='Comma-separated medical conditions'),
        ),
        migrations.AddField(
            model_name='patient',
            name='medications',
            field=models.TextField(blank=True, help_text='Current medications'),
        ),
        migrations.AddField(
            model_name='patient',
            name='allergies',
            field=models.TextField(blank=True, help_text='Known allergies'),
        ),
        migrations.AddField(
            model_name='patient',
            name='primary_provider_id',
            field=models.CharField(blank=True, max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='patient',
            name='registration_date',
            field=models.DateTimeField(auto_now_add=True, null=True),
        ),
        # Add optional numeric reading fields to CheckIn
        migrations.AddField(
            model_name='checkin',
            name='blood_pressure_systolic',
            field=models.IntegerField(blank=True, null=True, help_text="Patient's reading (if provided)"),
        ),
        migrations.AddField(
            model_name='checkin',
            name='blood_pressure_diastolic',
            field=models.IntegerField(blank=True, null=True, help_text="Patient's reading (if provided)"),
        ),
        migrations.AddField(
            model_name='checkin',
            name='blood_glucose_reading',
            field=models.IntegerField(blank=True, null=True, help_text="Patient's reading (if provided)"),
        ),
        # Create new models for Appointment and Notification
        migrations.CreateModel(
            name='Appointment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('provider_id', models.CharField(max_length=100)),
                ('scheduled_date', models.DateField()),
                ('scheduled_time', models.TimeField()),
                ('duration_minutes', models.IntegerField(default=30)),
                ('reason', models.CharField(blank=True, max_length=200)),
                ('notes', models.TextField(blank=True)),
                ('status', models.CharField(
                    choices=[('SCHEDULED', 'Scheduled'), ('COMPLETED', 'Completed'), 
                            ('CANCELLED', 'Cancelled'), ('NO_SHOW', 'No Show')],
                    default='SCHEDULED',
                    max_length=20
                )),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('patient', models.ForeignKey(on_delete=models.deletion.CASCADE, related_name='appointments', to='api.patient')),
            ],
            options={
                'ordering': ['-scheduled_date', '-scheduled_time'],
            },
        ),
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('user_id', models.CharField(max_length=100)),
                ('notification_type', models.CharField(
                    choices=[('HIGH_RISK_ALERT', 'High Risk Alert'), ('DAILY_REMINDER', 'Daily Reminder'),
                            ('APPOINTMENT', 'Appointment'), ('MESSAGE', 'Message'), ('GENERAL', 'General')],
                    max_length=30
                )),
                ('message', models.TextField()),
                ('is_read', models.BooleanField(default=False)),
                ('related_patient_id', models.CharField(blank=True, max_length=100, null=True)),
                ('related_object_id', models.CharField(blank=True, max_length=100, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('read_at', models.DateTimeField(blank=True, null=True)),
            ],
            options={
                'ordering': ['-created_at'],
            },
        ),
    ]
