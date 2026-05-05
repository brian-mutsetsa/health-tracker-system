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
        patient_id='PT001', name='Judy',    surname='Moyo',    condition='Hypertension',
        gender='F', phone_number='+263771000001', pin='1234',
        district='Goromonzi', home_address='14 Arcturus Rd, Ruwa',
        emergency_contact_name='Tom Moyo',  emergency_contact_phone='+263771000010', emergency_contact_relation='Husband',
        weight_kg=72.0, blood_pressure_systolic=145, blood_pressure_diastolic=92,
        primary_provider_id='DR001', last_risk_level='YELLOW', last_risk_color='yellow',
    ),
    dict(
        patient_id='PT002', name='Ivan',    surname='Choto',   condition='Hypertension',
        gender='M', phone_number='+263771000002', pin='2345',
        district='Mazowe', home_address='8 Mazowe Citrus Rd, Mazowe',
        emergency_contact_name='Mary Choto', emergency_contact_phone='+263771000011', emergency_contact_relation='Wife',
        weight_kg=85.0, blood_pressure_systolic=160, blood_pressure_diastolic=100,
        primary_provider_id='DR001', last_risk_level='ORANGE', last_risk_color='orange',
    ),
    dict(
        patient_id='PT003', name='Heidi',   surname='Chiware', condition='Diabetes',
        gender='F', phone_number='+263771000003', pin='3456',
        district='Seke', home_address='22 Unit L, Seke',
        emergency_contact_name='Brian Chiware', emergency_contact_phone='+263771000012', emergency_contact_relation='Brother',
        weight_kg=68.0, blood_glucose_baseline=210,
        primary_provider_id='DR001', last_risk_level='YELLOW', last_risk_color='yellow',
    ),
    dict(
        patient_id='PT004', name='Grace',   surname='Mutombwa', condition='Heart Disease',
        gender='F', phone_number='+263771000004', pin='4567',
        district='Umguza', home_address='5 Old Khami Rd, Umguza',
        emergency_contact_name='Simon Mutombwa', emergency_contact_phone='+263771000013', emergency_contact_relation='Son',
        weight_kg=78.0, blood_pressure_systolic=155, blood_pressure_diastolic=95,
        primary_provider_id='DR001', last_risk_level='RED', last_risk_color='red',
    ),
    dict(
        patient_id='PT005', name='Frank',   surname='Mutasa',  condition='Diabetes',
        gender='M', phone_number='+263771000005', pin='5678',
        district='Shurugwi', home_address='11 Mine Ave, Shurugwi',
        emergency_contact_name='Alice Mutasa', emergency_contact_phone='+263771000014', emergency_contact_relation='Wife',
        weight_kg=91.0, blood_glucose_baseline=240,
        primary_provider_id='DR001', last_risk_level='GREEN', last_risk_color='green',
    ),
    # ── Additional patients (PT006–PT015) ─────────────────────────────────────
    dict(
        patient_id='PT006', name='Tendai',  surname='Chirombe', condition='Hypertension',
        gender='M', phone_number='+263771000006', pin='6789',
        district='Zvimba', home_address='33 Murombedzi Rd, Zvimba',
        emergency_contact_name='Rudo Chirombe', emergency_contact_phone='+263771000015', emergency_contact_relation='Wife',
        weight_kg=88.0, blood_pressure_systolic=158, blood_pressure_diastolic=98,
        primary_provider_id='DR001', last_risk_level='ORANGE', last_risk_color='orange',
    ),
    dict(
        patient_id='PT007', name='Simbai',  surname='Ncube',   condition='Asthma',
        gender='M', phone_number='+263771000007', pin='7890',
        district='Insiza', home_address='7 Filabusi Rd, Insiza',
        emergency_contact_name='Nomsa Ncube', emergency_contact_phone='+263771000016', emergency_contact_relation='Mother',
        weight_kg=62.0,
        primary_provider_id='DR001', last_risk_level='GREEN', last_risk_color='green',
    ),
    dict(
        patient_id='PT008', name='Rudo',    surname='Makoni',  condition='Diabetes',
        gender='F', phone_number='+263771000008', pin='8901',
        district='Makoni', home_address='2 Broadway Ave, Rusape',
        emergency_contact_name='Patrick Makoni', emergency_contact_phone='+263771000017', emergency_contact_relation='Husband',
        weight_kg=74.0, blood_glucose_baseline=195,
        primary_provider_id='DR001', last_risk_level='YELLOW', last_risk_color='yellow',
    ),
    dict(
        patient_id='PT009', name='Blessing', surname='Dube',   condition='Heart Disease',
        gender='F', phone_number='+263771000009', pin='9012',
        district='Gutu', home_address='18 Gutu Mission Rd, Gutu',
        emergency_contact_name='Joseph Dube', emergency_contact_phone='+263771000018', emergency_contact_relation='Father',
        weight_kg=81.0, blood_pressure_systolic=170, blood_pressure_diastolic=105,
        primary_provider_id='DR001', last_risk_level='RED', last_risk_color='red',
    ),
    dict(
        patient_id='PT010', name='Tatenda', surname='Mhiripiri', condition='Hypertension',
        gender='M', phone_number='+263771000010', pin='0123',
        district='Chirumhanzu', home_address='45 Mine Rd, Mvuma',
        emergency_contact_name='Hope Mhiripiri', emergency_contact_phone='+263771000019', emergency_contact_relation='Sister',
        weight_kg=79.0, blood_pressure_systolic=142, blood_pressure_diastolic=89,
        primary_provider_id='DR001', last_risk_level='YELLOW', last_risk_color='yellow',
    ),
    dict(
        patient_id='PT011', name='Chenai',  surname='Zulu',    condition='Diabetes',
        gender='F', phone_number='+263771000011', pin='1122',
        district='Bindura', home_address='91 Trojan Rd, Bindura',
        emergency_contact_name='Victor Zulu', emergency_contact_phone='+263771000020', emergency_contact_relation='Husband',
        weight_kg=69.0, blood_glucose_baseline=230,
        primary_provider_id='DR001', last_risk_level='ORANGE', last_risk_color='orange',
    ),
    dict(
        patient_id='PT012', name='Kudzai',  surname='Banda',   condition='Asthma',
        gender='F', phone_number='+263771000012', pin='2233',
        district='Epworth', home_address='5 Unit B, Epworth',
        emergency_contact_name='Farirai Banda', emergency_contact_phone='+263771000021', emergency_contact_relation='Daughter',
        weight_kg=57.0,
        primary_provider_id='DR001', last_risk_level='GREEN', last_risk_color='green',
    ),
    dict(
        patient_id='PT013', name='Takudzwa', surname='Phiri',  condition='Heart Disease',
        gender='M', phone_number='+263771000013', pin='3344',
        district='Marondera', home_address='3 Diggleford Rd, Marondera',
        emergency_contact_name='Taurai Phiri', emergency_contact_phone='+263771000022', emergency_contact_relation='Brother',
        weight_kg=83.0, blood_pressure_systolic=165, blood_pressure_diastolic=102,
        primary_provider_id='DR001', last_risk_level='RED', last_risk_color='red',
    ),
    dict(
        patient_id='PT014', name='Mavis',   surname='Chikwanda', condition='Hypertension',
        gender='F', phone_number='+263771000014', pin='4455',
        district='Matobo', home_address='22 Figtree Rd, Matobo',
        emergency_contact_name='Arnold Chikwanda', emergency_contact_phone='+263771000023', emergency_contact_relation='Son',
        weight_kg=76.5, blood_pressure_systolic=150, blood_pressure_diastolic=94,
        primary_provider_id='DR001', last_risk_level='ORANGE', last_risk_color='orange',
    ),
    dict(
        patient_id='PT015', name='Simba',   surname='Musiiwa',  condition='Diabetes',
        gender='M', phone_number='+263771000015', pin='5566',
        district='Hwange', home_address='60 Colliery Rd, Hwange',
        emergency_contact_name='Chipo Musiiwa', emergency_contact_phone='+263771000024', emergency_contact_relation='Wife',
        weight_kg=95.0, blood_glucose_baseline=260,
        primary_provider_id='DR001', last_risk_level='RED', last_risk_color='red',
    ),
]

# ── Appointment schedule (relative to today) ────────────────────────────────
# Format: (patient_id, days_from_today, HH:MM, reason, status, initiated_by)
#
# CONFLICT RESOLUTION DEMO — the following slots are intentionally filled
# so that the booking dialog shows them as unavailable:
#   Day+2 : 09:00 PT001, 10:00 PT002, 14:30 PT004  → only 08:xx / 11:xx / 15:xx free
#   Day+3 : 09:00 PT006, 10:30 PT008, 11:00 PT003, 14:00 PT009, 15:00 PT005
#             → 08:00 / 08:30 / 12:00 / 14:30 / 15:30 / 16:xx free
#   Day+4 : 10:00 already booked (PT002 pending) → patient can't re-book same slot
APPOINTMENTS = [
    # ── Upcoming SCHEDULED ───────────────────────────────────────────────────
    ('PT001', +2,  '09:00', 'Blood pressure review',           'SCHEDULED', 'PROVIDER'),
    ('PT002', +2,  '10:00', 'Hypertension follow-up',          'SCHEDULED', 'PROVIDER'),
    ('PT004', +2,  '14:30', 'Cardiac monitoring check',        'SCHEDULED', 'PROVIDER'),
    ('PT006', +2,  '11:00', 'BP monitoring — new patient',     'SCHEDULED', 'PROVIDER'),
    ('PT010', +2,  '15:00', 'Initial hypertension consult',    'SCHEDULED', 'PROVIDER'),
    ('PT013', +2,  '16:00', 'Heart disease assessment',        'SCHEDULED', 'PROVIDER'),
    ('PT003', +3,  '11:00', 'Diabetes management review',      'SCHEDULED', 'PROVIDER'),
    ('PT005', +3,  '15:00', 'Glucose level assessment',        'SCHEDULED', 'PROVIDER'),
    ('PT006', +3,  '09:00', 'Hypertension follow-up',          'SCHEDULED', 'PROVIDER'),
    ('PT008', +3,  '10:30', 'HbA1c review',                    'SCHEDULED', 'PROVIDER'),
    ('PT009', +3,  '14:00', 'Cardiac monitoring',              'SCHEDULED', 'PROVIDER'),
    ('PT011', +3,  '16:30', 'Diabetes insulin review',         'SCHEDULED', 'PROVIDER'),
    ('PT001', +5,  '14:00', 'Medication adjustment',           'SCHEDULED', 'PROVIDER'),
    ('PT007', +5,  '09:00', 'Asthma inhaler technique check',  'SCHEDULED', 'PROVIDER'),
    ('PT012', +5,  '10:00', 'Asthma spirometry review',        'SCHEDULED', 'PROVIDER'),
    ('PT014', +5,  '11:00', 'BP medication titration',         'SCHEDULED', 'PROVIDER'),
    ('PT015', +5,  '15:30', 'Diabetes weight management',      'SCHEDULED', 'PROVIDER'),
    ('PT002', +7,  '09:00', 'Monthly check-up',                'SCHEDULED', 'PROVIDER'),
    ('PT003', +7,  '10:30', 'HbA1c results review',            'SCHEDULED', 'PROVIDER'),
    ('PT004', +10, '09:00', 'ECG follow-up',                   'SCHEDULED', 'PROVIDER'),
    ('PT005', +14, '14:30', 'Dietary consultation',            'SCHEDULED', 'PROVIDER'),
    ('PT008', +7,  '14:00', 'Diabetes quarterly review',       'SCHEDULED', 'PROVIDER'),
    ('PT009', +10, '10:00', 'Heart function assessment',       'SCHEDULED', 'PROVIDER'),
    ('PT013', +14, '09:00', 'ECG and stress test review',      'SCHEDULED', 'PROVIDER'),
    # ── Pending approval (patient-initiated) ─────────────────────────────────
    # PT002 tries 10:00 on day+4 — this slot is free that day so it shows as bookable
    ('PT002', +4,  '10:00', 'Urgent: headache and dizziness',  'PENDING',  'PATIENT'),
    ('PT003', +6,  '15:30', 'Insulin dose query',              'PENDING',  'PATIENT'),
    # PT006 tries 09:00 on day+3 — that slot is ALREADY taken (SCHEDULED above),
    # so this pending request demonstrates a conflict that admin must resolve
    ('PT006', +3,  '09:00', 'Urgent chest tightness',          'PENDING',  'PATIENT'),
    ('PT011', +5,  '10:00', 'High glucose reading concern',    'PENDING',  'PATIENT'),
    ('PT015', +7,  '09:00', 'Weight spike and fatigue',        'PENDING',  'PATIENT'),
    # ── Past COMPLETED ────────────────────────────────────────────────────────
    ('PT001', -1,  '09:00', 'Routine blood pressure check',    'COMPLETED', 'PROVIDER'),
    ('PT003', -3,  '14:00', 'Diabetes quarterly review',       'COMPLETED', 'PROVIDER'),
    ('PT002', -7,  '10:00', 'Hypertension medication review',  'COMPLETED', 'PROVIDER'),
    ('PT004', -7,  '11:30', 'Heart function assessment',       'COMPLETED', 'PROVIDER'),
    ('PT005', -14, '09:00', 'Diabetes initial consultation',   'COMPLETED', 'PROVIDER'),
    ('PT006', -2,  '09:00', 'BP baseline measurement',         'COMPLETED', 'PROVIDER'),
    ('PT007', -5,  '10:00', 'Asthma action plan review',       'COMPLETED', 'PROVIDER'),
    ('PT008', -4,  '14:00', 'Diabetes education session',      'COMPLETED', 'PROVIDER'),
    ('PT009', -6,  '11:00', 'Echocardiogram follow-up',        'COMPLETED', 'PROVIDER'),
    ('PT010', -3,  '15:00', 'Blood pressure log review',       'COMPLETED', 'PROVIDER'),
    ('PT011', -8,  '09:30', 'Insulin initiation consult',      'COMPLETED', 'PROVIDER'),
    ('PT013', -10, '14:30', 'Cardiology referral discussion',  'COMPLETED', 'PROVIDER'),
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
                    'surname': pdata.get('surname', ''),
                    'gender': pdata.get('gender', 'M'),
                    'phone_number': pdata.get('phone_number', ''),
                    'pin': pdata.get('pin', ''),
                    'district': pdata.get('district', ''),
                    'home_address': pdata.get('home_address', ''),
                    'emergency_contact_name': pdata.get('emergency_contact_name', ''),
                    'emergency_contact_phone': pdata.get('emergency_contact_phone', ''),
                    'emergency_contact_relation': pdata.get('emergency_contact_relation', ''),
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
                    content=f'Hi {patient.name}, keep monitoring your vitals daily.',
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
