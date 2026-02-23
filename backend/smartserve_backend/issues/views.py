from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from .models import Issue, Notification
import json


def issue_to_dict(issue):
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
        'created_at': issue.created_at.strftime('%d %b %Y, %I:%M %p'),
        'updated_at': issue.updated_at.strftime('%d %b %Y, %I:%M %p'),
    }


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

        Notification.objects.using('issues_db').create(
            mobile=issue.mobile,
            issue=issue,
            message=f"Your issue '{issue.title}' has been submitted successfully.",
        )

        return JsonResponse({
            'message': 'Issue submitted successfully',
            'issue': issue_to_dict(issue)
        })

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@csrf_exempt
def my_issues(request):
    mobile = request.GET.get('mobile', '').strip()
    if not mobile:
        return JsonResponse({'error': 'mobile parameter required'}, status=400)
    issues = Issue.objects.using('issues_db').filter(mobile=mobile)
    return JsonResponse([issue_to_dict(i) for i in issues], safe=False)


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

    status_msg = {
        'IN_PROGRESS': f"Your issue '{issue.title}' is now being worked on.",
        'COMPLETED': f"Your issue '{issue.title}' has been resolved!",
    }.get(new_status)

    if status_msg:
        Notification.objects.using('issues_db').create(
            mobile=issue.mobile, issue=issue, message=status_msg)

    return JsonResponse({'message': 'Status updated', 'issue': issue_to_dict(issue)})


@csrf_exempt
def my_notifications(request):
    mobile = request.GET.get('mobile', '').strip()
    if not mobile:
        return JsonResponse({'error': 'mobile required'}, status=400)
    notifs = Notification.objects.using('issues_db').filter(mobile=mobile)
    data = [{
        'id': n.id,
        'message': n.message,
        'is_read': n.is_read,
        'issue_id': n.issue_id,
        'created_at': n.created_at.strftime('%d %b %Y, %I:%M %p')
    } for n in notifs]
    return JsonResponse(data, safe=False)


@csrf_exempt
def mark_notification_read(request, notif_id):
    try:
        n = Notification.objects.using('issues_db').get(id=notif_id)
        n.is_read = True
        n.save(using='issues_db')
        return JsonResponse({'message': 'Marked as read'})
    except Notification.DoesNotExist:
        return JsonResponse({'error': 'Not found'}, status=404)


def dashboard(request):
    mobile = request.GET.get('mobile', '').strip()
    qs = Issue.objects.using('issues_db').filter(mobile=mobile) if mobile else Issue.objects.using('issues_db').all()

    category_counts = {}
    for cat_key, _ in Issue.CATEGORY_CHOICES:
        category_counts[cat_key] = qs.filter(category=cat_key).count()

    return JsonResponse({
        'total': qs.count(),
        'reported': qs.filter(status='REPORTED').count(),
        'in_progress': qs.filter(status='IN_PROGRESS').count(),
        'completed': qs.filter(status='COMPLETED').count(),
        'categories': category_counts,
    })


def all_issues(request):
    category = request.GET.get('category', '').strip().upper()
    status = request.GET.get('status', '').strip().upper()
    qs = Issue.objects.using('issues_db').all()
    if category:
        qs = qs.filter(category=category)
    if status:
        qs = qs.filter(status=status)
    return JsonResponse([issue_to_dict(i) for i in qs], safe=False)