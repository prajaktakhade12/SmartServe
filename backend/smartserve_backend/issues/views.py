from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Issue, Notification, StatusHistory, IssueComment, CivicPoints, Officer
import json
import math


# ══════════════════════════════════════════════════════════════════════════════
# SMART ROUTING TABLE
# Maps (category, problem_title) → officer username
# "Other (type manually)" always goes to the dept head for manual assignment
# ══════════════════════════════════════════════════════════════════════════════
ISSUE_ROUTING = {
    'ROAD': {
        'Pothole on road':                'deepak.shinde',   # Pothole Repair Supervisor
        'Road damage / crack':            'ravi.kumar',      # Junior Engineer (Roads)
        'Speed breaker needed':           'ravi.kumar',      # Junior Engineer (Roads)
        'Road waterlogging':              'deepak.shinde',   # Pothole Repair Supervisor
        'Encroachment on road':           'nitin.desai',     # Road Survey Officer
        'Damaged footpath / pavement':    'pramod.sawant',   # Bridge & Footpath Inspector
        'Missing road divider':           'pramod.sawant',   # Bridge & Footpath Inspector
        'Missing road signs / signals':   'nitin.desai',     # Road Survey Officer
        'Other (type manually)':          'amit.patil',      # Road Dept Head
    },
    'WATER': {
        'Water supply disruption':        'anil.jadhav',     # Borewell & Pump Officer
        'Water leakage in pipe':          'ganesh.pawar',    # Pipe Repair Engineer
        'Low water pressure':             'anil.jadhav',     # Borewell & Pump Officer
        'Contaminated / dirty water':     'dinesh.lonkar',   # Water Quality Inspector
        'Borewell not working':           'anil.jadhav',     # Borewell & Pump Officer
        'Drainage overflow':              'sagar.kulkarni',  # Drainage & Sewage Engineer
        'Water meter issue':              'dinesh.lonkar',   # Water Quality Inspector
        'Illegal water connection':       'dinesh.lonkar',   # Water Quality Inspector
        'Other (type manually)':          'suresh.deshmukh', # Water Dept Head
    },
    'ELECTRICITY': {
        'Power outage in area':           'santosh.more',    # Line Maintenance Officer
        'Transformer fault':              'kedar.deshpande', # Transformer & Sub-Station Engineer
        'Sparking / hanging wire':        'santosh.more',    # Line Maintenance Officer
        'Fallen electric pole':           'santosh.more',    # Line Maintenance Officer
        'High voltage fluctuation':       'kedar.deshpande', # Transformer & Sub-Station Engineer
        'Electric shock hazard':          'santosh.more',    # Line Maintenance Officer
        'Street light power failure':     'santosh.more',    # Line Maintenance Officer
        'Meter tampering':                'hemant.borde',    # Meter & Connection Inspector
        'Other (type manually)':          'vikram.joshi',    # Electricity Dept Head
    },
    'SANITATION': {
        'Garbage not collected':           'sushma.patil',   # Solid Waste Management Officer
        'Overflowing dustbin / dumpyard':  'sushma.patil',   # Solid Waste Management Officer
        'Open defecation area':            'vijay.gaikwad',  # Sweeping & Cleaning Supervisor
        'Blocked drain / nala':            'ramesh.bhosale', # Drainage & Nala Supervisor
        'Bad odour from drain':            'ramesh.bhosale', # Drainage & Nala Supervisor
        'Sanitation workers absent':       'vijay.gaikwad',  # Sweeping & Cleaning Supervisor
        'Mosquito / pest breeding site':   'sunil.thakur',   # Pest & Mosquito Control Officer
        'Other (type manually)':           'manoj.kulkarni', # Sanitation Dept Head
    },
    'ENVIRONMENT': {
        'Illegal garbage dumping':              'arvind.tiwari',  # Pollution Control Officer
        'Tree fallen on road':                  'neha.gupta',     # Green Belt & Garden Officer
        'Air pollution from factory / vehicle': 'arvind.tiwari',  # Pollution Control Officer
        'Noise pollution':                      'arvind.tiwari',  # Pollution Control Officer
        'Stray animal menace':                  'rahul.bawane',   # River & Lake Conservation Officer
        'Encroachment on green belt / garden':  'neha.gupta',     # Green Belt & Garden Officer
        'River / lake pollution':               'rahul.bawane',   # River & Lake Conservation Officer
        'Other (type manually)':                'priya.nair',     # Environment Dept Head
    },
    'SAFETY': {
        'Suspicious activity / crime':    'kavita.sharma',   # Fire & Accident Prevention Officer
        'Road accident spot':             'sunil.jadhav',    # Field Safety Inspector
        'Fire hazard':                    'kavita.sharma',   # Fire & Accident Prevention Officer
        'Missing person':                 'kavita.sharma',   # Fire & Accident Prevention Officer
        'Illegal construction':           'nilesh.raut',     # Traffic Safety & Encroachment Officer
        'Drug / alcohol nuisance':        'kavita.sharma',   # Fire & Accident Prevention Officer
        'Street harassment':              'kavita.sharma',   # Fire & Accident Prevention Officer
        'Other (type manually)':          'rahul.mehta',     # Safety Dept Head
    },
    'STREET_LIGHT': {
        'Street light not working':              'mohan.gaikwad',  # Electrical Maintenance Officer
        'New street light needed':               'ajay.moon',      # New Installation & Wiring Officer
        'Damaged light pole':                    'nilesh.wagh',    # Light Pole & Fixture Inspector
        'Flickering street light':               'mohan.gaikwad',  # Electrical Maintenance Officer
        'Light on during daytime (wastage)':     'nilesh.wagh',    # Light Pole & Fixture Inspector
        'Wire exposed on light pole':            'mohan.gaikwad',  # Electrical Maintenance Officer
        'Other (type manually)':                 'sanjay.yadav',   # Street Light Dept Head
    },
    'OTHER': {
        'Government property damage':     'prakash.tele',    # General Civic Officer
        'Public toilet issue':            'prakash.tele',    # General Civic Officer
        'Park / garden not maintained':   'ashok.kale',      # Public Property & Parks Officer
        'Bus stop damaged':               'ashok.kale',      # Public Property & Parks Officer
        'Encroachment on public land':    'sneha.moon',      # Building & Encroachment Officer
        'Stray cattle on road':           'prakash.tele',    # General Civic Officer
        'Other (type manually)':          'kavita.reddy',    # Other Dept Head
    },
}


def _auto_assign_officer(category, title):
    """
    Given a category and issue title, return the best matching officer.
    Returns (officer_id, officer_name) or (None, None) if not found.
    """
    category = category.upper()
    routing = ISSUE_ROUTING.get(category, {})

    # Try exact match first
    username = routing.get(title)

    # If no exact match (manually typed title), assign to dept head
    if not username:
        username = routing.get('Other (type manually)')

    if username:
        try:
            officer = Officer.objects.get(username=username)
            return officer.id, officer.name
        except Officer.DoesNotExist:
            pass
    return None, None


def issue_to_dict(issue):
    try:
        history = [{
            'status': h.status,
            'note': h.note,
            'changed_at': h.changed_at.strftime('%d %b %Y, %I:%M %p')
        } for h in issue.history.all()]
    except:
        history = []

    try:
        comments = [{
            'id': c.id,
            'name': c.name,
            'mobile': c.mobile,
            'comment': c.comment,
            'created_at': c.created_at.strftime('%d %b %Y, %I:%M %p')
        } for c in issue.comments.all()]
    except:
        comments = []

    return {
        'id': issue.id,
        'display_id': issue.display_id or 'ID-{}'.format(issue.id),
        'name': issue.name,
        'mobile': issue.mobile,
        'title': issue.title,
        'category': issue.category,
        'description': issue.description,
        'location': issue.location,
        'latitude': issue.latitude,
        'longitude': issue.longitude,
        'status': issue.status,
        'officer_remarks': issue.officer_remarks or '',
        'image': issue.image.url if issue.image else None,
        'extra_images': issue.extra_images or '',
        'rating': issue.rating,
        'rating_comment': issue.rating_comment or '',
        'points_awarded': issue.points_awarded,
        'assigned_officer_id': issue.assigned_officer_id,
        'assigned_officer_name': issue.assigned_officer_name or '',
        'solver_name': issue.solver_name or '',
        'solver_mobile': issue.solver_mobile or '',
        'solver_designation': issue.solver_designation or '',
        'work_done': issue.work_done or '',
        'resolution_date': str(issue.resolution_date) if issue.resolution_date else '',
        'history': history,
        'comments': comments,
        'created_at': issue.created_at.strftime('%d %b %Y, %I:%M %p'),
        'updated_at': issue.updated_at.strftime('%d %b %Y, %I:%M %p'),
    }


# ── Category short prefixes for display IDs ─────────────────────────────────
CATEGORY_PREFIX = {
    'ROAD':        'ROAD',
    'WATER':       'WATR',
    'ELECTRICITY': 'ELEC',
    'SANITATION':  'SANIT',
    'ENVIRONMENT': 'ENV',
    'SAFETY':      'SAFE',
    'STREET_LIGHT':'LITE',
    'OTHER':       'OTHR',
}


def _assign_display_id(issue):
    """
    Assigns a category-wise incremental ID to an issue.
    Example: WATR-001, ROAD-003, ELEC-012
    Counts independently per category — resets when DB is cleared.
    """
    category = issue.category.upper()
    prefix = CATEGORY_PREFIX.get(category, category[:4])
    # Count how many issues exist in this category (including current)
    count = Issue.objects.using('issues_db').filter(
        category=category).count()
    issue.category_issue_no = count
    issue.display_id = '{}-{}'.format(prefix, str(count).zfill(3))
    issue.save(using='issues_db')


def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))


def _clean_display_name(display_name):
    """
    Cleans Nominatim's display_name for Indian addresses.
    Removes country, PIN codes, duplicates.
    Input:  "Station Road, Yavatmal Naka, Yavatmal, Yavatmal, Maharashtra, 445001, India"
    Output: "Station Road, Yavatmal Naka, Yavatmal, Maharashtra"
    """
    import re as _re
    parts   = [p.strip() for p in display_name.split(',') if p.strip()]
    cleaned = []
    seen    = set()
    for part in parts:
        if part == 'India':                       continue  # skip country
        if _re.match(r'^\d{4,6}$', part):         continue  # skip PIN/ZIP
        if part.lower() in seen:                   continue  # skip duplicate
        seen.add(part.lower())
        cleaned.append(part)
        if len(cleaned) >= 6:                      break     # max 6 parts
    return ', '.join(cleaned)


def _reverse_geocode(lat, lng):
    """
    Converts GPS coordinates to a full readable address using OpenStreetMap Nominatim.
    Handles sparse OSM data (common in smaller Indian cities like Yavatmal)
    by falling back to display_name when structured fields are empty.
    Format: "Near <Landmark>, <House No>, <Street>, <Area>, <City>, <State>"
    """
    import urllib.request as _ur
    import time

    headers = {
        'User-Agent':      'SmartServe-CivicApp/1.0',
        'Accept-Language': 'en',
    }

    def _fetch(url, timeout=10):
        req  = _ur.Request(url, headers=headers)
        resp = _ur.urlopen(req, timeout=timeout)
        return json.loads(resp.read())

    try:
        # ── Step 1: Detailed address at building level (zoom=19) ─────────────
        url1 = ("https://nominatim.openstreetmap.org/reverse"
                "?lat={}&lon={}&format=json&addressdetails=1"
                "&zoom=19&namedetails=1&accept-language=en").format(lat, lng)
        geo          = _fetch(url1)
        addr         = geo.get('address', {})
        display_name = geo.get('display_name', '')

        # ── Step 2: Build structured address from individual fields ──────────
        parts = []
        house = addr.get('house_number', '')
        road  = (addr.get('road') or addr.get('pedestrian') or addr.get('path')
                 or addr.get('footway') or addr.get('highway') or
                 addr.get('street') or '')

        if house and road:
            parts.append("{}, {}".format(house, road))
        elif road:
            parts.append(road)

        area = (addr.get('neighbourhood') or addr.get('suburb') or
                addr.get('quarter') or addr.get('residential') or
                addr.get('village') or addr.get('hamlet') or
                addr.get('locality') or addr.get('county') or '')
        if area and area not in ' '.join(parts):
            parts.append(area)

        city = (addr.get('city') or addr.get('town') or
                addr.get('city_district') or addr.get('state_district') or '')
        if city and city not in ' '.join(parts):
            parts.append(city)

        state = addr.get('state', '')
        if state and state not in ' '.join(parts):
            parts.append(state)

        address_str = ', '.join(parts) if parts else ''

        # ── Step 3: If too sparse, use display_name (better for Indian cities) ─
        # "Too sparse" = only city+state (≤2 parts) — OSM lacks street detail
        if len(parts) <= 2 and display_name:
            address_str = _clean_display_name(display_name)

        # ── Step 4: Find nearby landmark ─────────────────────────────────────
        landmark = ''
        time.sleep(0.6)  # Nominatim rate limit: 1 req/sec
        try:
            url2 = ("https://nominatim.openstreetmap.org/reverse"
                    "?lat={}&lon={}&format=json&zoom=17"
                    "&accept-language=en").format(lat, lng)
            lm   = _fetch(url2, timeout=8)
            name = lm.get('name', '')
            if (name and name != road and name != city
                    and name != state and len(name) > 3
                    and name not in address_str):
                landmark = name
        except:
            pass

        # ── Step 5: Combine into final string ────────────────────────────────
        if landmark and address_str:
            final = "Near {}, {}".format(landmark, address_str)
        elif landmark:
            final = "Near {}, {}".format(
                landmark, ', '.join(filter(None, [city, state])))
        elif address_str:
            final = address_str
        else:
            final = "{:.5f}, {:.5f}".format(lat, lng)

        print("Geocoded ({}, {}) -> {}".format(lat, lng, final))
        return final

    except Exception as e:
        print("Geocoding error: {}".format(e))
        return None


@csrf_exempt
def create_issue(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        if request.content_type and 'multipart' in request.content_type:
            data = request.POST
            image = request.FILES.get('image')
        else:
            data = json.loads(request.body)
            image = None

        required = ['name', 'mobile', 'title', 'category', 'description', 'location']
        for field in required:
            if not data.get(field, '').strip():
                return JsonResponse({'error': f'{field} is required'}, status=400)

        if len(data.get('mobile', '')) != 10:
            return JsonResponse({'error': 'Mobile must be 10 digits'}, status=400)

        lat = data.get('latitude')
        lng = data.get('longitude')
        category = data.get('category', '').strip().upper()
        title = data.get('title', '').strip()

        # ── Auto-assign officer based on category + title ─────────────────────
        officer_id, officer_name = _auto_assign_officer(category, title)

        issue = Issue.objects.using('issues_db').create(
            name=data.get('name', '').strip(),
            mobile=data.get('mobile', '').strip(),
            title=title,
            category=category,
            description=data.get('description', '').strip(),
            location=data.get('location', '').strip(),
            latitude=float(lat) if lat else None,
            longitude=float(lng) if lng else None,
            image=image,
            assigned_officer_id=officer_id,
            assigned_officer_name=officer_name or '',
        )

        # Assign category-wise display ID (e.g. WATR-001, ROAD-003)
        try:
            _assign_display_id(issue)
        except Exception as e:
            print(f"display_id error: {e}")

        try:
            StatusHistory.objects.using('issues_db').create(
                issue=issue, status='REPORTED',
                note=f'Issue reported by citizen. Assigned to: {officer_name or "Dept Head"}')
        except:
            pass

        try:
            Notification.objects.using('issues_db').create(
                mobile=issue.mobile, issue=issue,
                message=f"Your issue '{issue.title}' has been submitted successfully.")
        except:
            pass

        try:
            existing = CivicPoints.objects.using('issues_db').filter(mobile=issue.mobile).first()
            if existing:
                existing.total_points += 10
                existing.issues_reported += 1
                existing.save(using='issues_db')
            else:
                CivicPoints.objects.using('issues_db').create(
                    mobile=issue.mobile, name=issue.name,
                    total_points=10, issues_reported=1, issues_resolved=0)
        except Exception as e:
            print(f"Civic points error: {e}")

        # Reverse geocode if GPS provided
        if issue.latitude and issue.longitude:
            geocoded = _reverse_geocode(issue.latitude, issue.longitude)
            if geocoded:
                issue.location = geocoded
                issue.save(using='issues_db')

        return JsonResponse({
            'message': 'Issue submitted successfully',
            'issue': issue_to_dict(issue),
            'assigned_to': officer_name or 'Department Head',
        })

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def my_issues(request):
    mobile = request.GET.get('mobile', '').strip()
    if not mobile:
        return JsonResponse({'error': 'mobile required'}, status=400)
    category = request.GET.get('category', '').strip().upper()
    status = request.GET.get('status', '').strip().upper()
    search = request.GET.get('search', '').strip()

    qs = Issue.objects.using('issues_db').filter(mobile=mobile)
    if category:
        qs = qs.filter(category=category)
    if status:
        qs = qs.filter(status=status)
    if search:
        qs = qs.filter(title__icontains=search)

    return JsonResponse([issue_to_dict(i) for i in qs], safe=False)


@csrf_exempt
def issue_detail(request, issue_id):
    try:
        issue = Issue.objects.using('issues_db').get(id=issue_id)
        return JsonResponse(issue_to_dict(issue))
    except Issue.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)


@csrf_exempt
def update_status(request, issue_id):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        issue = Issue.objects.using('issues_db').get(id=issue_id)
    except Issue.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)

    data = json.loads(request.body)
    new_status = data.get('status', '').upper()
    if new_status not in ['REPORTED', 'IN_PROGRESS', 'COMPLETED']:
        return JsonResponse({'error': 'Invalid status'}, status=400)

    officer_id = data.get('officer_id')
    officer_name = data.get('officer_name', '')
    if officer_id:
        issue.assigned_officer_id = officer_id
        issue.assigned_officer_name = officer_name

    issue.status = new_status
    issue.officer_remarks = data.get('remarks', issue.officer_remarks)

    if new_status == 'COMPLETED':
        issue.solver_name = data.get('solver_name', '')
        issue.solver_mobile = data.get('solver_mobile', '')
        issue.solver_designation = data.get('solver_designation', '')
        issue.work_done = data.get('work_done', '')
        resolution_date = data.get('resolution_date', '')
        if resolution_date:
            from datetime import date
            issue.resolution_date = date.fromisoformat(resolution_date)

    issue.save(using='issues_db')

    try:
        note = data.get('note', '') or data.get('remarks', '')
        StatusHistory.objects.using('issues_db').create(
            issue=issue, status=new_status, note=note)
    except:
        pass

    status_msg = {
        'IN_PROGRESS': f"Your issue '{issue.title}' is now being worked on.",
        'COMPLETED': f"Your issue '{issue.title}' has been resolved!",
    }.get(new_status)

    try:
        if status_msg:
            Notification.objects.using('issues_db').create(
                mobile=issue.mobile, issue=issue, message=status_msg)
    except:
        pass

    if new_status == 'COMPLETED':
        try:
            points = CivicPoints.objects.using('issues_db').get(mobile=issue.mobile)
            points.total_points += 20
            points.issues_resolved += 1
            points.save(using='issues_db')
        except:
            pass

    return JsonResponse({'message': 'Status updated', 'issue': issue_to_dict(issue)})


@csrf_exempt
def rate_issue(request, issue_id):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        issue = Issue.objects.using('issues_db').get(id=issue_id)
        data = json.loads(request.body)
        rating = int(data.get('rating', 0))
        if rating < 1 or rating > 5:
            return JsonResponse({'error': 'Rating must be 1-5'}, status=400)
        issue.rating = rating
        issue.rating_comment = data.get('comment', '')
        issue.save(using='issues_db')

        try:
            points = CivicPoints.objects.using('issues_db').get(mobile=issue.mobile)
            points.total_points += 5
            points.save(using='issues_db')
        except:
            pass

        return JsonResponse({'message': 'Rating submitted'})
    except Issue.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def add_comment(request, issue_id):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        issue = Issue.objects.using('issues_db').get(id=issue_id)
        data = json.loads(request.body)
        comment_text = data.get('comment', '').strip()
        if not comment_text:
            return JsonResponse({'error': 'Comment cannot be empty'}, status=400)

        comment = IssueComment.objects.using('issues_db').create(
            issue=issue,
            mobile=data.get('mobile', ''),
            name=data.get('name', ''),
            comment=comment_text,
        )
        return JsonResponse({
            'message': 'Comment added',
            'comment': {
                'id': comment.id,
                'name': comment.name,
                'comment': comment.comment,
                'created_at': comment.created_at.strftime('%d %b %Y, %I:%M %p'),
            }
        })
    except Issue.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def nearby_issues(request):
    try:
        lat = float(request.GET.get('lat', 0))
        lng = float(request.GET.get('lng', 0))
        radius = float(request.GET.get('radius', 5))
        all_issues = Issue.objects.using('issues_db').exclude(latitude=None).exclude(longitude=None)
        nearby = []
        for issue in all_issues:
            dist = haversine(lat, lng, issue.latitude, issue.longitude)
            if dist <= radius:
                d = issue_to_dict(issue)
                d['distance_km'] = round(dist, 2)
                nearby.append(d)
        nearby.sort(key=lambda x: x['distance_km'])
        return JsonResponse(nearby, safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def civic_points(request):
    mobile = request.GET.get('mobile', '').strip()
    if not mobile:
        return JsonResponse({'error': 'mobile required'}, status=400)
    try:
        pts = CivicPoints.objects.using('issues_db').get(mobile=mobile)
        return JsonResponse({
            'mobile': pts.mobile,
            'name': pts.name,
            'total_points': pts.total_points,
            'issues_reported': pts.issues_reported,
            'issues_resolved': pts.issues_resolved,
            'badge': _get_badge(pts.total_points),
        })
    except:
        return JsonResponse({
            'mobile': mobile, 'name': '', 'total_points': 0,
            'issues_reported': 0, 'issues_resolved': 0, 'badge': 'Newcomer'})


def _get_badge(points):
    if points >= 500: return 'Champion'
    if points >= 200: return 'Hero'
    if points >= 100: return 'Active'
    if points >= 50:  return 'Regular'
    if points >= 10:  return 'Starter'
    return 'Newcomer'


@csrf_exempt
def leaderboard(request):
    try:
        top = CivicPoints.objects.using('issues_db').order_by('-total_points')[:10]
        return JsonResponse([{
            'rank': i + 1,
            'name': p.name,
            'mobile': p.mobile[-4:].zfill(10),
            'total_points': p.total_points,
            'badge': _get_badge(p.total_points),
        } for i, p in enumerate(top)], safe=False)
    except:
        return JsonResponse([], safe=False)


@csrf_exempt
def my_notifications(request):
    mobile = request.GET.get('mobile', '').strip()
    if not mobile:
        return JsonResponse({'error': 'mobile required'}, status=400)
    try:
        notifs = Notification.objects.using('issues_db').filter(mobile=mobile)
        return JsonResponse([{
            'id': n.id, 'message': n.message, 'is_read': n.is_read,
            'issue_id': n.issue_id,
            'created_at': n.created_at.strftime('%d %b %Y, %I:%M %p')
        } for n in notifs], safe=False)
    except:
        return JsonResponse([], safe=False)


@csrf_exempt
def mark_notification_read(request, notif_id):
    try:
        n = Notification.objects.using('issues_db').get(id=notif_id)
        n.is_read = True
        n.save(using='issues_db')
        return JsonResponse({'message': 'Marked as read'})
    except:
        return JsonResponse({'error': 'Not found'}, status=404)


def dashboard(request):
    try:
        mobile = request.GET.get('mobile', '').strip()
        qs = Issue.objects.using('issues_db').filter(mobile=mobile) if mobile else Issue.objects.using('issues_db').all()
        category_counts = {cat: qs.filter(category=cat).count() for cat, _ in Issue.CATEGORY_CHOICES}
        return JsonResponse({
            'total': qs.count(),
            'reported': qs.filter(status='REPORTED').count(),
            'in_progress': qs.filter(status='IN_PROGRESS').count(),
            'completed': qs.filter(status='COMPLETED').count(),
            'categories': category_counts,
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def all_issues(request):
    try:
        category = request.GET.get('category', '').strip().upper()
        status = request.GET.get('status', '').strip().upper()
        qs = Issue.objects.using('issues_db').all()
        if category:
            qs = qs.filter(category=category)
        if status:
            qs = qs.filter(status=status)
        return JsonResponse([issue_to_dict(i) for i in qs], safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def officer_login(request):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        data = json.loads(request.body)
        username = data.get('username', '').strip()
        password = data.get('password', '').strip()
        officer = Officer.objects.get(username=username, password=password)
        return JsonResponse({
            'message': 'Login successful',
            'officer': {
                'id': officer.id,
                'name': officer.name,
                'username': officer.username,
                'category': officer.category,
                'role': officer.role,
                'designation': officer.designation,
            }
        })
    except Officer.DoesNotExist:
        return JsonResponse({'error': 'Invalid username or password'}, status=401)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def officer_dashboard(request):
    category  = request.GET.get('category', '').strip().upper()
    officer_id = request.GET.get('officer_id', '').strip()
    role       = request.GET.get('role', '').strip()
    try:
        if category == 'HEAD':
            qs = Issue.objects.using('issues_db').all()
        elif role == 'officer' and officer_id:
            # Regular officer: their assigned issues + unassigned in their category
            from django.db.models import Q
            qs = Issue.objects.using('issues_db').filter(
                Q(category=category, assigned_officer_id=int(officer_id)) |
                Q(category=category, assigned_officer_id__isnull=True)
            )
        else:
            # Dept head: all issues in their category
            qs = Issue.objects.using('issues_db').filter(category=category)

        category_counts = {}
        if category == 'HEAD':
            for cat, _ in Issue.CATEGORY_CHOICES:
                category_counts[cat] = Issue.objects.using('issues_db').filter(category=cat).count()
        return JsonResponse({
            'total': qs.count(),
            'reported': qs.filter(status='REPORTED').count(),
            'in_progress': qs.filter(status='IN_PROGRESS').count(),
            'completed': qs.filter(status='COMPLETED').count(),
            'categories': category_counts,
        })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def officer_issues(request):
    """
    For a regular officer: shows issues assigned to them OR unassigned issues in their category.
    For dept head: shows ALL issues in their category.
    For overall head: shows all issues.
    """
    category = request.GET.get('category', '').strip().upper()
    officer_id = request.GET.get('officer_id', '').strip()
    role = request.GET.get('role', '').strip()
    status = request.GET.get('status', '').strip().upper()
    search = request.GET.get('search', '').strip()

    try:
        if category == 'HEAD':
            qs = Issue.objects.using('issues_db').all().order_by('-created_at')
        elif role == 'officer' and officer_id:
            # Regular officer: sees issues assigned to them + unassigned in their category
            # This ensures no issue falls through the cracks
            from django.db.models import Q
            qs = Issue.objects.using('issues_db').filter(
                Q(category=category, assigned_officer_id=int(officer_id)) |
                Q(category=category, assigned_officer_id__isnull=True)
            ).order_by('-created_at')
        else:
            # Dept head: sees all issues in category
            qs = Issue.objects.using('issues_db').filter(
                category=category).order_by('-created_at')

        if status:
            qs = qs.filter(status=status)
        if search:
            qs = qs.filter(title__icontains=search) | qs.filter(name__icontains=search)

        return JsonResponse([issue_to_dict(i) for i in qs], safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def officer_notifications(request):
    category = request.GET.get('category', '').strip().upper()
    officer_id = request.GET.get('officer_id', '').strip()
    role = request.GET.get('role', '').strip()
    try:
        if category == 'HEAD':
            qs = Issue.objects.using('issues_db').all().order_by('-created_at')[:20]
        elif role == 'officer' and officer_id:
            from django.db.models import Q
            qs = Issue.objects.using('issues_db').filter(
                Q(category=category, assigned_officer_id=int(officer_id)) |
                Q(category=category, assigned_officer_id__isnull=True)
            ).order_by('-created_at')[:20]
        else:
            qs = Issue.objects.using('issues_db').filter(
                category=category).order_by('-created_at')[:20]

        return JsonResponse([{
            'id': i.id,
            'title': i.title,
            'status': i.status,
            'created_at': i.created_at.strftime('%d %b %Y, %I:%M %p'),
        } for i in qs], safe=False)
    except Exception as e:
        return JsonResponse([], safe=False)


def officer_list(request):
    category = request.GET.get('category', '').strip().upper()
    try:
        if category == 'HEAD':
            officers = Officer.objects.exclude(category='HEAD').order_by('category', 'role')
        else:
            officers = Officer.objects.filter(category=category).order_by('role')
        return JsonResponse([{
            'id': o.id,
            'name': o.name,
            'username': o.username,
            'category': o.category,
            'role': o.role,
            'designation': o.designation,
        } for o in officers], safe=False)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def officer_stats(request):
    category = request.GET.get('category', '').strip().upper()
    try:
        if category == 'HEAD':
            stats = []
            for cat, label in Issue.CATEGORY_CHOICES:
                cat_issues = Issue.objects.using('issues_db').filter(category=cat)
                total = cat_issues.count()
                completed = cat_issues.filter(status='COMPLETED').count()
                in_progress = cat_issues.filter(status='IN_PROGRESS').count()
                reported = cat_issues.filter(status='REPORTED').count()
                rate = round((completed / total * 100), 1) if total > 0 else 0
                try:
                    dept_head = Officer.objects.get(category=cat, role='dept_head')
                    head_name = dept_head.name
                    head_designation = dept_head.designation
                except:
                    head_name = 'N/A'
                    head_designation = ''
                stats.append({
                    'category': cat, 'label': label,
                    'dept_head': head_name, 'dept_head_designation': head_designation,
                    'total': total, 'completed': completed,
                    'in_progress': in_progress, 'reported': reported,
                    'resolution_rate': rate,
                })
            return JsonResponse(stats, safe=False)
        else:
            officers = Officer.objects.filter(category=category)
            stats = []
            cat_issues = Issue.objects.using('issues_db').filter(category=category)
            for o in officers:
                handled = cat_issues.filter(assigned_officer_id=o.id)
                total_handled = handled.count()
                completed = handled.filter(status='COMPLETED').count()
                in_progress = handled.filter(status='IN_PROGRESS').count()
                rate = round((completed / total_handled * 100), 1) if total_handled > 0 else 0
                stats.append({
                    'officer_id': o.id,
                    'name': o.name,
                    'username': o.username,
                    'role': o.role,
                    'designation': o.designation,
                    'total_handled': total_handled,
                    'completed': completed,
                    'in_progress': in_progress,
                    'resolution_rate': rate,
                })
            unassigned = cat_issues.filter(assigned_officer_id=None).count()
            return JsonResponse({
                'category': category,
                'officers': stats,
                'total_issues': cat_issues.count(),
                'unassigned_issues': unassigned,
                'completed_issues': cat_issues.filter(status='COMPLETED').count(),
                'pending_issues': cat_issues.filter(status='REPORTED').count(),
            })
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def officer_profile_stats(request):
    """Individual officer stats for the profile screen."""
    officer_id = request.GET.get('officer_id', '').strip()
    if not officer_id:
        return JsonResponse({'error': 'officer_id required'}, status=400)
    try:
        officer = Officer.objects.get(id=int(officer_id))
        if officer.role == 'head':
            # Overall head: stats across all issues
            all_qs = Issue.objects.using('issues_db').all()
        elif officer.role == 'dept_head':
            # Dept head: stats for their entire category
            all_qs = Issue.objects.using('issues_db').filter(category=officer.category)
        else:
            # Regular officer: only their assigned issues
            all_qs = Issue.objects.using('issues_db').filter(
                assigned_officer_id=officer.id)

        total = all_qs.count()
        completed = all_qs.filter(status='COMPLETED').count()
        in_progress = all_qs.filter(status='IN_PROGRESS').count()
        reported = all_qs.filter(status='REPORTED').count()
        rate = round((completed / total * 100), 1) if total > 0 else 0.0

        return JsonResponse({
            'officer_id': officer.id,
            'name': officer.name,
            'username': officer.username,
            'category': officer.category,
            'role': officer.role,
            'designation': officer.designation,
            'total': total,
            'completed': completed,
            'in_progress': in_progress,
            'reported': reported,
            'resolution_rate': rate,
        })
    except Officer.DoesNotExist:
        return JsonResponse({'error': 'Officer not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def reassign_issue(request, issue_id):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        issue = Issue.objects.using('issues_db').get(id=issue_id)
        data = json.loads(request.body)
        new_officer_id = data.get('officer_id')
        requester_role = data.get('requester_role', '')

        if requester_role not in ['head', 'dept_head']:
            return JsonResponse({'error': 'Permission denied.'}, status=403)

        try:
            new_officer = Officer.objects.get(id=new_officer_id)
        except Officer.DoesNotExist:
            return JsonResponse({'error': 'Officer not found'}, status=404)

        old_name = issue.assigned_officer_name or 'Unassigned'
        issue.assigned_officer_id = new_officer.id
        issue.assigned_officer_name = new_officer.name
        issue.save(using='issues_db')

        try:
            StatusHistory.objects.using('issues_db').create(
                issue=issue, status=issue.status,
                note=f"Reassigned from {old_name} to {new_officer.name}")
        except:
            pass

        return JsonResponse({
            'message': f"Issue reassigned to {new_officer.name}",
            'issue': issue_to_dict(issue)
        })
    except Issue.DoesNotExist:
        return JsonResponse({'error': 'Issue not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def escalate_issue(request, issue_id):
    if request.method != 'POST':
        return JsonResponse({'error': 'POST required'}, status=405)
    try:
        issue = Issue.objects.using('issues_db').get(id=issue_id)
        data = json.loads(request.body)
        requester_role = data.get('requester_role', '')
        escalation_note = data.get('note', 'Issue has been escalated for priority resolution.')

        if requester_role not in ['head', 'dept_head']:
            return JsonResponse({'error': 'Permission denied.'}, status=403)

        try:
            StatusHistory.objects.using('issues_db').create(
                issue=issue, status=issue.status,
                note=f"⚠️ ESCALATED: {escalation_note}")
        except:
            pass

        try:
            Notification.objects.using('issues_db').create(
                mobile=issue.mobile, issue=issue,
                message=f"Your issue '{issue.title}' has been escalated for priority resolution.")
        except:
            pass

        return JsonResponse({'message': 'Issue escalated successfully', 'issue': issue_to_dict(issue)})
    except Issue.DoesNotExist:
        return JsonResponse({'error': 'Issue not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


def geocode(request):
    try:
        lat = float(request.GET.get('lat', 0))
        lng = float(request.GET.get('lng', 0))
        if not lat or not lng:
            return JsonResponse({'error': 'lat and lng required'}, status=400)
        address = _reverse_geocode(lat, lng)
        if address:
            return JsonResponse({'address': address})
        else:
            return JsonResponse({'address': f"{lat:.5f}, {lng:.5f}"})
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)