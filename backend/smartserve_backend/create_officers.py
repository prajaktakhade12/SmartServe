import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'smartserve_backend.settings')
django.setup()

from issues.models import Officer

officers = [
    {'username': 'rajesh.sharma',       'password': 'Head@123',  'name': 'Rajesh Sharma',      'category': 'HEAD',         'role': 'head'},
    {'username': 'amit.patil',          'password': 'Road@123',  'name': 'Amit Patil',          'category': 'ROAD',         'role': 'officer'},
    {'username': 'suresh.deshmukh',     'password': 'Water@123', 'name': 'Suresh Deshmukh',     'category': 'WATER',        'role': 'officer'},
    {'username': 'vikram.joshi',        'password': 'Elec@123',  'name': 'Vikram Joshi',        'category': 'ELECTRICITY',  'role': 'officer'},
    {'username': 'manoj.kulkarni',      'password': 'San@123',   'name': 'Manoj Kulkarni',      'category': 'SANITATION',   'role': 'officer'},
    {'username': 'priya.nair',          'password': 'Env@123',   'name': 'Priya Nair',          'category': 'ENVIRONMENT',  'role': 'officer'},
    {'username': 'rahul.mehta',         'password': 'Safe@123',  'name': 'Rahul Mehta',         'category': 'SAFETY',       'role': 'officer'},
    {'username': 'sanjay.yadav',        'password': 'Light@123', 'name': 'Sanjay Yadav',        'category': 'STREET_LIGHT', 'role': 'officer'},
    {'username': 'kavita.reddy',        'password': 'Other@123', 'name': 'Kavita Reddy',        'category': 'OTHER',        'role': 'officer'},
]

created = 0
for o in officers:
    obj, created_new = Officer.objects.get_or_create(
        username=o['username'],
        defaults=o
    )
    if created_new:
        print(f"✅ Created: {o['name']} ({o['category']})")
        created += 1
    else:
        print(f"⚠️  Already exists: {o['name']}")

print(f"\n✅ Done! {created} officers created.")
