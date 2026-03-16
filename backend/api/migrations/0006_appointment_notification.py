# Generated migration for Phase 2 models (Appointment and Notification)

from django.db import migrations, models
import django.db.models.deletion
import django.utils.timezone


class Migration(migrations.Migration):

    dependencies = [
        ('api', '0005_typingstatus'),
    ]

    operations = [
        # Create Appointment model
        migrations.CreateModel(
            name='Appointment',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('provider_id', models.IntegerField()),
                ('scheduled_date', models.DateField()),
                ('scheduled_time', models.TimeField()),
                ('appointment_type', models.CharField(
                    default='FOLLOW_UP',
                    max_length=20,
                    choices=[
                        ('INITIAL', 'Initial Consultation'),
                        ('FOLLOW_UP', 'Follow-up'),
                        ('CHECKUP', 'Checkup'),
                        ('EMERGENCY', 'Emergency'),
                        ('ROUTINE', 'Routine'),
                    ]
                )),
                ('reason', models.TextField()),
                ('status', models.CharField(
                    default='SCHEDULED',
                    max_length=20,
                    choices=[
                        ('SCHEDULED', 'Scheduled'),
                        ('COMPLETED', 'Completed'),
                        ('CANCELLED', 'Cancelled'),
                        ('NO_SHOW', 'No Show'),
                    ]
                )),
                ('notes', models.TextField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('patient', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='api.patient')),
            ],
            options={
                'verbose_name': 'Appointment',
                'verbose_name_plural': 'Appointments',
                'ordering': ['-scheduled_date', '-scheduled_time'],
            },
        ),
        
        # Create Notification model
        migrations.CreateModel(
            name='Notification',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('user_id', models.IntegerField(help_text='provider_id or patient_id')),
                ('notification_type', models.CharField(
                    max_length=50,
                    choices=[
                        ('HIGH_RISK_ALERT', 'High Risk Alert'),
                        ('APPOINTMENT_REMINDER', 'Appointment Reminder'),
                        ('MEDICATION_REMINDER', 'Medication Reminder'),
                        ('CHECKIN_SCHEDULED', 'Check-in Scheduled'),
                        ('RESULT_AVAILABLE', 'Result Available'),
                        ('GENERAL_NOTIFICATION', 'General Notification'),
                    ]
                )),
                ('message', models.TextField()),
                ('related_patient_id', models.CharField(blank=True, max_length=20, null=True)),
                ('is_read', models.BooleanField(default=False)),
                ('read_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'verbose_name': 'Notification',
                'verbose_name_plural': 'Notifications',
                'ordering': ['-created_at'],
            },
        ),
        
        # Add indexes for better query performance
        migrations.AddIndex(
            model_name='appointment',
            index=models.Index(fields=['provider_id', 'scheduled_date'], name='appt_provider_date_idx'),
        ),
        migrations.AddIndex(
            model_name='appointment',
            index=models.Index(fields=['patient', 'status'], name='appt_patient_status_idx'),
        ),
        migrations.AddIndex(
            model_name='notification',
            index=models.Index(fields=['user_id', 'is_read'], name='notif_user_read_idx'),
        ),
        migrations.AddIndex(
            model_name='notification',
            index=models.Index(fields=['notification_type', 'created_at'], name='notif_type_created_idx'),
        ),
    ]
