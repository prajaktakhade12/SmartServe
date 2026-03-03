from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Issue, Notification, StatusHistory, IssueComment, CivicPoints, Officer
import json
import math


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


def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))


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

        issue = Issue.objects.using('issues_db').create(
            name=data.get('name', '').strip(),
            mobile=data.get('mobile', '').strip(),
            title=data.get('title', '').strip(),
            category=data.get('category', '').strip().upper(),
            description=data.get('description', '').strip(),
            location=data.get('location', '').strip(),
            latitude=float(lat) if lat else None,
            longitude=float(lng) if lng else None,
            image=image,
        )

        # Create status history
        try:
            StatusHistory.objects.using('issues_db').create(
                issue=issue, status='REPORTED', note='Issue reported by citizen')
        except:
            pass

        # Create notification
        try:
            Notification.objects.using('issues_db').create(
                mobile=issue.mobile, issue=issue,
                message=f"Your issue '{issue.title}' has been submitted successfully.")
        except:
            pass

        # Award civic points
        try:
            existing = CivicPoints.objects.using('issues_db').filter(mobile=issue.mobile).first()
            if existing:
                existing.total_points = existing.total_points + 10
                existing.issues_reported = existing.issues_reported + 1
                existing.save(using='issues_db')
            else:
                CivicPoints.objects.using('issues_db').create(
                    mobile=issue.mobile,
                    name=issue.name,
                    total_points=10,
                    issues_reported=1,
                    issues_resolved=0,
                )
        except Exception as e:
            print(f"Civic points error: {e}")

        # Reverse Geocoding - house no, street, area, nearby place, city, state
        if issue.latitude and issue.longitude:
            try:
                import urllib.request as _ur

                # Step 1: Detailed address from coordinates
                _url = "https://nominatim.openstreetmap.org/reverse?lat={}&lon={}&format=json&addressdetails=1".format(
                    issue.latitude, issue.longitude)
                _req = _ur.Request(_url, headers={'User-Agent': 'SmartServe/1.0'})
                _resp = _ur.urlopen(_req, timeout=4)
                _geo = json.loads(_resp.read())
                _addr = _geo.get('address', {})
                _parts = []

                # House number + road/street
                house = _addr.get('house_number', '')
                road = (_addr.get('road') or _addr.get('pedestrian') or
                        _addr.get('path') or _addr.get('footway') or
                        _addr.get('street') or '')
                if house and road:
                    _parts.append("{} {}".format(house, road))
                elif road:
                    _parts.append(road)

                # Neighbourhood / locality / suburb
                area = (_addr.get('neighbourhood') or _addr.get('suburb') or
                        _addr.get('quarter') or _addr.get('residential') or
                        _addr.get('village') or _addr.get('hamlet') or '')
                if area and area not in _parts:
                    _parts.append(area)

                # City / town / district
                city = (_addr.get('city') or _addr.get('town') or
                        _addr.get('city_district') or _addr.get('state_district') or '')
                if city and city not in _parts:
                    _parts.append(city)

                # State
                state = _addr.get('state', '')
                if state and state not in _parts:
                    _parts.append(state)

                location_str = ", ".join(_parts) if _parts else issue.location

                # Step 2: Nearby famous place within ~20 metres (zoom=17)
                try:
                    _n_url = "https://nominatim.openstreetmap.org/reverse?lat={}&lon={}&format=json&zoom=17".format(
                        issue.latitude, issue.longitude)
                    _nreq = _ur.Request(_n_url, headers={'User-Agent': 'SmartServe/1.0'})
                    _nresp = _ur.urlopen(_nreq, timeout=3)
                    _ndata = json.loads(_nresp.read())
                    nearby_name = _ndata.get('name', '')
                    # Only add if it's a real named place (not a road or house number)
                    if nearby_name and nearby_name != road and nearby_name not in location_str:
                        location_str = "Near {}, {}".format(nearby_name, location_str)
                except:
                    pass

                if location_str:
                    issue.location = location_str
                issue.save(using='issues_db')
            except Exception as e:
                print("Geocoding error: {}".format(e))

        return JsonResponse({'message': 'Issue submitted successfully', 'issue': issue_to_dict(issue)})

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
        note = data.get('note', '')
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
    if points >= 50: return 'Regular'
    if points >= 10: return 'Starter'
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
            }
        })
    except Officer.DoesNotExist:
        return JsonResponse({'error': 'Invalid username or password'}, status=401)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def officer_dashboard(request):
    category = request.GET.get('category', '').strip().upper()
    try:
        if category == 'HEAD':
            qs = Issue.objects.using('issues_db').all()
        else:
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
    category = request.GET.get('category', '').strip().upper()
    status = request.GET.get('status', '').strip().upper()
    search = request.GET.get('search', '').strip()
    try:
        if category == 'HEAD':
            qs = Issue.objects.using('issues_db').all().order_by('-created_at')
        else:
            qs = Issue.objects.using('issues_db').filter(category=category).order_by('-created_at')
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
    try:
        if category == 'HEAD':
            qs = Issue.objects.using('issues_db').all().order_by('-created_at')[:20]
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
