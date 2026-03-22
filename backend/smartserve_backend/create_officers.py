"""
Run this script ONCE to populate all officers in the database.
Command: python create_officers.py
(Run from inside: backend/smartserve_backend/)
"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'smartserve_backend.settings')
django.setup()

from issues.models import Officer

officers_data = [

    # ══════════════════════════════════════════════════════════════════════════
    # OVERALL HEAD  (1)
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'rajesh.sharma',
        'password': 'Head@123',
        'name': 'Rajesh Sharma',
        'category': 'HEAD',
        'role': 'head',
        'designation': 'Municipal Commissioner',
    },

    # ══════════════════════════════════════════════════════════════════════════
    # ROAD  (1 dept head + 4 officers = 5)
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'amit.patil',
        'password': 'Road@123',
        'name': 'Amit Patil',
        'category': 'ROAD',
        'role': 'dept_head',
        'designation': 'Road Department Head',
    },
    {
        'username': 'ravi.kumar',
        'password': 'Road@456',
        'name': 'Ravi Kumar',
        'category': 'ROAD',
        'role': 'officer',
        'designation': 'Junior Engineer (Roads)',
    },
    {
        'username': 'deepak.shinde',
        'password': 'Road@789',
        'name': 'Deepak Shinde',
        'category': 'ROAD',
        'role': 'officer',
        'designation': 'Pothole Repair Supervisor',
    },
    {
        'username': 'nitin.desai',
        'password': 'Road@321',
        'name': 'Nitin Desai',
        'category': 'ROAD',
        'role': 'officer',
        'designation': 'Road Survey Officer',
    },
    {
        'username': 'pramod.sawant',
        'password': 'Road@654',
        'name': 'Pramod Sawant',
        'category': 'ROAD',
        'role': 'officer',
        'designation': 'Bridge & Footpath Inspector',
    },

    # ══════════════════════════════════════════════════════════════════════════
    # WATER  (1 dept head + 4 officers = 5)
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'suresh.deshmukh',
        'password': 'Water@123',
        'name': 'Suresh Deshmukh',
        'category': 'WATER',
        'role': 'dept_head',
        'designation': 'Water Department Head',
    },
    {
        'username': 'ganesh.pawar',
        'password': 'Water@456',
        'name': 'Ganesh Pawar',
        'category': 'WATER',
        'role': 'officer',
        'designation': 'Pipe Repair Engineer',
    },
    {
        'username': 'anil.jadhav',
        'password': 'Water@789',
        'name': 'Anil Jadhav',
        'category': 'WATER',
        'role': 'officer',
        'designation': 'Borewell & Pump Officer',
    },
    {
        'username': 'sagar.kulkarni',
        'password': 'Water@321',
        'name': 'Sagar Kulkarni',
        'category': 'WATER',
        'role': 'officer',
        'designation': 'Drainage & Sewage Engineer',
    },
    {
        'username': 'dinesh.lonkar',
        'password': 'Water@654',
        'name': 'Dinesh Lonkar',
        'category': 'WATER',
        'role': 'officer',
        'designation': 'Water Quality Inspector',
    },

    # ══════════════════════════════════════════════════════════════════════════
    # ELECTRICITY  (1 dept head + 3 officers = 4)
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'vikram.joshi',
        'password': 'Elec@123',
        'name': 'Vikram Joshi',
        'category': 'ELECTRICITY',
        'role': 'dept_head',
        'designation': 'Electricity Department Head',
    },
    {
        'username': 'santosh.more',
        'password': 'Elec@456',
        'name': 'Santosh More',
        'category': 'ELECTRICITY',
        'role': 'officer',
        'designation': 'Line Maintenance Officer',
    },
    {
        'username': 'kedar.deshpande',
        'password': 'Elec@789',
        'name': 'Kedar Deshpande',
        'category': 'ELECTRICITY',
        'role': 'officer',
        'designation': 'Transformer & Sub-Station Engineer',
    },
    {
        'username': 'hemant.borde',
        'password': 'Elec@321',
        'name': 'Hemant Borde',
        'category': 'ELECTRICITY',
        'role': 'officer',
        'designation': 'Meter & Connection Inspector',
    },

    # ══════════════════════════════════════════════════════════════════════════
    # SANITATION  (1 dept head + 5 officers = 6)  ← largest dept
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'manoj.kulkarni',
        'password': 'San@123',
        'name': 'Manoj Kulkarni',
        'category': 'SANITATION',
        'role': 'dept_head',
        'designation': 'Sanitation Department Head',
    },
    {
        'username': 'sushma.patil',
        'password': 'San@456',
        'name': 'Sushma Patil',
        'category': 'SANITATION',
        'role': 'officer',
        'designation': 'Solid Waste Management Officer',
    },
    {
        'username': 'ramesh.bhosale',
        'password': 'San@789',
        'name': 'Ramesh Bhosale',
        'category': 'SANITATION',
        'role': 'officer',
        'designation': 'Drainage & Nala Supervisor',
    },
    {
        'username': 'vijay.gaikwad',
        'password': 'San@321',
        'name': 'Vijay Gaikwad',
        'category': 'SANITATION',
        'role': 'officer',
        'designation': 'Sweeping & Cleaning Supervisor',
    },
    {
        'username': 'anita.kamble',
        'password': 'San@654',
        'name': 'Anita Kamble',
        'category': 'SANITATION',
        'role': 'officer',
        'designation': 'Public Toilet Maintenance Officer',
    },
    {
        'username': 'sunil.thakur',
        'password': 'San@987',
        'name': 'Sunil Thakur',
        'category': 'SANITATION',
        'role': 'officer',
        'designation': 'Pest & Mosquito Control Officer',
    },

    # ══════════════════════════════════════════════════════════════════════════
    # ENVIRONMENT  (1 dept head + 3 officers = 4)
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'priya.nair',
        'password': 'Env@123',
        'name': 'Priya Nair',
        'category': 'ENVIRONMENT',
        'role': 'dept_head',
        'designation': 'Environment Department Head',
    },
    {
        'username': 'arvind.tiwari',
        'password': 'Env@456',
        'name': 'Arvind Tiwari',
        'category': 'ENVIRONMENT',
        'role': 'officer',
        'designation': 'Pollution Control Officer',
    },
    {
        'username': 'neha.gupta',
        'password': 'Env@789',
        'name': 'Neha Gupta',
        'category': 'ENVIRONMENT',
        'role': 'officer',
        'designation': 'Green Belt & Garden Officer',
    },
    {
        'username': 'rahul.bawane',
        'password': 'Env@321',
        'name': 'Rahul Bawane',
        'category': 'ENVIRONMENT',
        'role': 'officer',
        'designation': 'River & Lake Conservation Officer',
    },

    # ══════════════════════════════════════════════════════════════════════════
    # SAFETY  (1 dept head + 3 officers = 4)
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'rahul.mehta',
        'password': 'Safe@123',
        'name': 'Rahul Mehta',
        'category': 'SAFETY',
        'role': 'dept_head',
        'designation': 'Safety Department Head',
    },
    {
        'username': 'sunil.jadhav',
        'password': 'Safe@456',
        'name': 'Sunil Jadhav',
        'category': 'SAFETY',
        'role': 'officer',
        'designation': 'Field Safety Inspector',
    },
    {
        'username': 'kavita.sharma',
        'password': 'Safe@789',
        'name': 'Kavita Sharma',
        'category': 'SAFETY',
        'role': 'officer',
        'designation': 'Fire & Accident Prevention Officer',
    },
    {
        'username': 'nilesh.raut',
        'password': 'Safe@321',
        'name': 'Nilesh Raut',
        'category': 'SAFETY',
        'role': 'officer',
        'designation': 'Traffic Safety & Encroachment Officer',
    },

    # ══════════════════════════════════════════════════════════════════════════
    # STREET LIGHT  (1 dept head + 3 officers = 4)
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'sanjay.yadav',
        'password': 'Light@123',
        'name': 'Sanjay Yadav',
        'category': 'STREET_LIGHT',
        'role': 'dept_head',
        'designation': 'Street Light Department Head',
    },
    {
        'username': 'mohan.gaikwad',
        'password': 'Light@456',
        'name': 'Mohan Gaikwad',
        'category': 'STREET_LIGHT',
        'role': 'officer',
        'designation': 'Electrical Maintenance Officer',
    },
    {
        'username': 'nilesh.wagh',
        'password': 'Light@789',
        'name': 'Nilesh Wagh',
        'category': 'STREET_LIGHT',
        'role': 'officer',
        'designation': 'Light Pole & Fixture Inspector',
    },
    {
        'username': 'ajay.moon',
        'password': 'Light@321',
        'name': 'Ajay Moon',
        'category': 'STREET_LIGHT',
        'role': 'officer',
        'designation': 'New Installation & Wiring Officer',
    },

    # ══════════════════════════════════════════════════════════════════════════
    # OTHER  (1 dept head + 3 officers = 4)
    # ══════════════════════════════════════════════════════════════════════════
    {
        'username': 'kavita.reddy',
        'password': 'Other@123',
        'name': 'Kavita Reddy',
        'category': 'OTHER',
        'role': 'dept_head',
        'designation': 'General Department Head',
    },
    {
        'username': 'prakash.tele',
        'password': 'Other@456',
        'name': 'Prakash Tele',
        'category': 'OTHER',
        'role': 'officer',
        'designation': 'General Civic Officer',
    },
    {
        'username': 'sneha.moon',
        'password': 'Other@789',
        'name': 'Sneha Moon',
        'category': 'OTHER',
        'role': 'officer',
        'designation': 'Building & Encroachment Officer',
    },
    {
        'username': 'ashok.kale',
        'password': 'Other@321',
        'name': 'Ashok Kale',
        'category': 'OTHER',
        'role': 'officer',
        'designation': 'Public Property & Parks Officer',
    },
]


def create_all_officers():
    created = 0
    updated = 0
    for o in officers_data:
        obj, was_created = Officer.objects.update_or_create(
            username=o['username'],
            defaults={
                'password':    o['password'],
                'name':        o['name'],
                'category':    o['category'],
                'role':        o['role'],
                'designation': o['designation'],
            }
        )
        if was_created:
            created += 1
            print(f"  ✅  Created : {obj.name:<25}  {obj.category:<14}  {obj.role:<10}  {obj.designation}")
        else:
            updated += 1
            print(f"  🔄  Updated : {obj.name:<25}  {obj.category:<14}  {obj.role:<10}  {obj.designation}")

    total = Officer.objects.count()
    print(f"\n  {'─'*60}")
    print(f"  Done!  {created} created,  {updated} updated.")
    print(f"  Total officers in database: {total}")
    print(f"  {'─'*60}")
    print(f"\n  Summary by department:")
    for cat in ['HEAD', 'ROAD', 'WATER', 'ELECTRICITY', 'SANITATION',
                'ENVIRONMENT', 'SAFETY', 'STREET_LIGHT', 'OTHER']:
        count = Officer.objects.filter(category=cat).count()
        label = f"{cat:<14}"
        print(f"    {label}: {count} officer(s)")
    print()


if __name__ == '__main__':
    print("\n  Creating SmartServe officers...\n")
    create_all_officers()