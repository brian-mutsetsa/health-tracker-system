from django.core.management.base import BaseCommand
from django.db.models import Q
from api.models import Patient


class Command(BaseCommand):
    help = 'Set full names for test patients where name is currently blank'

    PATIENT_NAMES = {
        'PT001': 'Judy Moyo',
        'PT002': 'Ivan Choto',
        'PT003': 'Heidi Chiware',
        'PT004': 'Grace Mutombwa',
        'PT005': 'Frank Mutasa',
    }

    def handle(self, *args, **options):
        updated = 0
        for patient_id, name in self.PATIENT_NAMES.items():
            count = Patient.objects.filter(
                patient_id=patient_id
            ).filter(
                Q(name='') | Q(name__isnull=True)
            ).update(name=name)
            if count:
                self.stdout.write(f'  Updated: {patient_id} → {name}')
                updated += count

        if updated:
            self.stdout.write(self.style.SUCCESS(f'Done. Updated {updated} patient name(s).'))
        else:
            self.stdout.write('No blank names found — all test patients already have names.')
