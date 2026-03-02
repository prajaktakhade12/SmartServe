from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Issue, Notification, StatusHistory, IssueComment, CivicPoints
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

        # Create status history - wrapped in try so it doesn't block submission
        try:
            StatusHistory.objects.using('issues_db').create(
                issue=issue, status='REPORTED', note='Issue reported by citizen')
        except:
            pass

        # Create notification - wrapped in try so it doesn't block submission
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