"""
Idempotent seed command — safe to run on every deploy.
Uses get_or_create / update_or_create so it never destroys existing data.
"""
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta, date, time
import random

from api.models import Provider, Patient, CheckIn, Message, Appointment, Notification


# ── Canonical patient definitions ────────────────────────────────────────────
PATIENTS = [
    dict(
        patient_id='PT001', name='Judy Moyo',    condition='Hypertension',
        weight_kg=72.0, blood_pressure_systolic=145, blood_pressure_diastolic=92,
        primary_provider_id='DR001', last_risk_level='YELLOW', last_risk_color='yellow',
    ),
    dict(
        patient_id='PT002', name='Ivan Choto',   condition='Hypertension',
        weight_kg=85.0, blood_pressure_systolic=160, blood_pressure_diastolic=100,
        primary_provider_id='DR001', last_risk_level='ORANGE', last_risk_color='orange',
    ),
    dict(
        patient_id='PT003', name='Heidi Chiware', condition='Diabetes',
        weight_kg=68.0, blood_glucose_baseline=210,
        primary_provider_id='DR001', last_risk_level='YELLOW', last_risk_color='yellow',
    ),
    dict(
        patient_id='PT004', name='Grace Mutombwa', condition='Heart Disease',
        weight_kg=78.0, blood_pressure_systolic=155, blood_pressure_diastolic=95,
        primary_provider_id='DR001', last_risk_level='RED', last_risk_color='red',
    ),
    dict(
        patient_id='PT005', name='Frank Mutasa',  condition='Diabetes',
        weight_kg=91.0, blood_glucose_baseline=240,
        primary_provider_id='DR001', last_risk_level='GREEN', last_risk_color='green',
    ),
]

# ── Appointment schedule (relative to today) ──────────────────────────────────
# Format: (patient_id, days_from_today, HH:MM, reason, status, initiated_by)
APPOINTMENTS = [
    # ── Upcoming SCHEDULED (provider-initiated) ─────────────────────────────
    ('PT001', +2,  '09:00', 'Blood pressure review',        'SCHEDULED', 'PROVIDER'),
    ('PT002', +2,  '10:00', 'Hypertension follow-up',       'SCHEDULED', 'PROVIDER'),
    ('PT004', +2,  '14:30', 'Cardiac monitoring check',     'SCHEDULED', 'PROVIDER'),
    ('PT003', +3,  '11:00', 'Diabetes management review',   'SCHEDULED', 'PROVIDER'),
    ('PT005', +3,  '15:00', 'Glucose level assessment',     'SCHEDULED', 'PROVIDER'),
    ('PT001', +5,  '14:00', 'Medication adjustment',        'SCHEDULED', 'PROVIDER'),
    ('PT002', +7,  '09:00', 'Monthly check-up',             'SCHEDULED', 'PROVIDER'),
    ('PT003', +7,  '10:30', 'HbA1c results review',         'SCHEDULED', 'PROVIDER'),
    ('PT004', +10, '09:00', 'ECG follow-up',                'SCHEDULED', 'PROVIDER'),
    ('PT005', +14, '14:30', 'Dietary consultation',         'SCHEDULED', 'PROVIDER'),
    # ── Pending approval (patient-initiated) ────────────────────────────────
    ('PT002', +4,  '10:00', 'Urgent: headache and dizziness','PENDING',  'PATIENT'),
    ('PT003', +6,  '15:30', 'Insulin dose query',            'PENDING',  'PATIENT'),
    # ── Past COMPLETED ───────────────────────────────────────────────────────
    ('PT001', -1,  '09:00', 'Routine blood pressure check',  'COMPLETED', 'PROVIDER'),
    ('PT003', -3,  '14:00', 'Diabetes quarterly review',     'COMPLETED', 'PROVIDER'),
    ('PT002', -7,  '10:00', 'Hypertension medication review','COMPLETED', 'PROVIDER'),
    ('PT004', -7,  '11:30', 'Heart function assessment',     'COMPLETED', 'PROVIDER'),
    ('PT005', -14, '09:00', 'Diabetes initial consultation', 'COMPLETED', 'PROVIDER'),
]

CHECKIN_ANSWERS_BY_CONDITION = {
    'Hypertension': {'q1': 2, 'q2': 1, 'q3': 0, 'q4': 1, 'q5': 0, 'q6': 2, 'q7': 1, 'q8': 0, 'q9': 0, 'q10': 1, 'q11': 0, 'q12': 0},
    'Diabetes':     {'q1': 1, 'q2': 2, 'q3': 1, 'q4': 0, 'q5': 2, 'q6': 1, 'q7': 0, 'q8': 1, 'q9': 1, 'q10': 0, 'q11': 1, 'q12': 0},
    'Heart Disease':{'q1': 3, 'q2': 1, 'q3': 2, 'q4': 1, 'q5': 0, 'q6': 2, 'q7': 1, 'q8': 2, 'q9': 0, 'q10': 1, 'q11': 0, 'q12': 1},
    'Asthma':       {'q1': 0, 'q2': 2, 'q3': 1, 'q4': 0, 'q5': 1, 'q6': 0, 'q7': 2, 'q8': 1, 'q9': 0, 'q10': 0, 'q11': 1, 'q12': 0},
}
RISK_BY_CONDITION = {
    'Hypertension': ('YELLOW', 'yellow'),
    'Diabetes':     ('YELLOW', 'yellow'),
    'Heart Disease':('RED',    'red'),
    'Asthma':       ('GREEN',  'green'),
}


class Command(BaseCommand):
    help = 'Idempotent seed — creates demo data without destroying existing records'

    def handle(self, *args, **kwargs):
        self.stdout.write('Starting idempotent seed...')

        # ── Provider: DR001 ───────────────────────────────────────────────────
        dr_user, created = User.objects.get_or_create(
            username='DR001',
            defaults={'email': 'sarah.johnson@hararehospital.co.zw', 'first_name': 'Sarah', 'last_name': 'Johnson'},
        )
        if created:
            dr_user.set_password('provider123')
            dr_user.save()
            self.stdout.write('  Created User DR001')

        Provider.objects.update_or_create(
            provider_id='DR001',
            defaults={
                'user': dr_user,
                'specialty': 'Cardiology & Hypertension',
                'hospital': 'Harare Central Hospital',
            },
        )

        # Legacy 'provider' account (for backward compat with old seed / tests)
        legacy_user, lc = User.objects.get_or_create(
            username='provider',
            defaults={'email': 'provider@hararehospital.co.zw', 'first_name': 'Sarah', 'last_name': 'Johnson'},
        )
        if lc:
            legacy_user.set_password('provider123')
            legacy_user.save()
        Provider.objects.update_or_create(
            provider_id='provider',
            defaults={'user': legacy_user, 'specialty': 'General Practice', 'hospital': 'Harare Central Hospital'},
        )

        # ── Superadmin ────────────────────────────────────────────────────────
        if not User.objects.filter(username='admin').exists():
            su = User.objects.create_superuser('admin', 'admin@hararehospital.co.zw', 'password')
            su.first_name = 'System'
            su.last_name = 'Admin'
            su.save()
            self.stdout.write('  Created superuser admin')

        # ── Patients ─────────────────────────────────────────────────────────
        patient_objects = {}
        for pdata in PATIENTS:
            pid = pdata['patient_id']
            patient, created = Patient.objects.update_or_create(
                patient_id=pid,
                defaults={
                    'name': pdata['name'],
                    'condition': pdata['condition'],
                    'weight_kg': pdata.get('weight_kg'),
                    'blood_pressure_systolic': pdata.get('blood_pressure_systolic'),
                    'blood_pressure_diastolic': pdata.get('blood_pressure_diastolic'),
                    'blood_glucose_baseline': pdata.get('blood_glucose_baseline'),
                    'primary_provider_id': pdata.get('primary_provider_id'),
                    'last_risk_level': pdata.get('last_risk_level'),
                    'last_risk_color': pdata.get('last_risk_color'),
                    'password': 'test123',
                    'status': 'ACTIVE',
                },
            )
            patient_objects[pid] = patient
            action = 'Created' if created else 'Updated'
            self.stdout.write(f'  {action}: {pid} - {patient.name} ({patient.condition})')

            # Check-ins: only add if this patient has none yet
            if not CheckIn.objects.filter(patient=patient).exists():
                risk_level, risk_color = RISK_BY_CONDITION.get(patient.condition, ('GREEN', 'green'))
                base_answers = CHECKIN_ANSWERS_BY_CONDITION.get(
                    patient.condition, {f'q{i}': 1 for i in range(1, 13)}
                )
                for i in range(30):
                    checkin_dt = timezone.now() - timedelta(days=i)
                    answers = {k: max(0, min(3, v + random.randint(-1, 1))) for k, v in base_answers.items()}
                    CheckIn.objects.create(
                        patient=patient,
                        condition=patient.condition,
                        date=checkin_dt,
                        answers=answers,
                        risk_level=risk_level,
                        risk_color=risk_color,
                    )
                patient.last_checkin = timezone.now()
                patient.save(update_fields=['last_checkin'])
                self.stdout.write(f'    → Created 30 check-ins for {pid}')

            # Messages: add if none exist for this patient
            if not Message.objects.filter(sender_id=pid).exists():
                Message.objects.create(
                    sender_id=pid,
                    receiver_id='DR001',
                    content=f'Hello Doctor, how am I doing with my {patient.condition}?',
                    is_read=False,
                )
                Message.objects.create(
                    sender_id='DR001',
                    receiver_id=pid,
                    content=f'Hi {patient.name.split()[0]}, keep monitoring your vitals daily.',
                    is_read=True,
                )

        # ── Appointments ─────────────────────────────────────────────────────
        today = date.today()
        created_count = 0
        skipped_count = 0
        for (pid, day_offset, time_str, reason, appt_status, initiated_by) in APPOINTMENTS:
            patient = patient_objects.get(pid)
            if not patient:
                continue
            appt_date = today + timedelta(days=day_offset)
            h, m = map(int, time_str.split(':'))
            appt_time = time(h, m)

            _, created = Appointment.objects.get_or_create(
                patient=patient,
                provider_id='DR001',
                scheduled_date=appt_date,
                scheduled_time=appt_time,
                defaults={
                    'reason': reason,
                    'status': appt_status,
                    'initiated_by': initiated_by,
                    'duration_minutes': 30,
                },
            )
            if created:
                created_count += 1
            else:
                skipped_count += 1

        self.stdout.write(f'  Appointments: {created_count} created, {skipped_count} already existed')

        self.stdout.write(self.style.SUCCESS(
            '\nSeed complete!\n'
            '  Provider login : DR001 / provider123\n'
            '  Patient login  : PT001 (or PT002-PT005) / test123\n'
            '  Admin login    : admin / password\n'
        ))
