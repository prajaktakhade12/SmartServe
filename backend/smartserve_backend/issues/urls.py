from django.urls import path
from . import views

urlpatterns = [
    # Citizen endpoints
    path('issue/create/', views.create_issue),
    path('issue/my/', views.my_issues),
    path('issue/<int:issue_id>/', views.issue_detail),
    path('dashboard/', views.dashboard),
    path('notifications/', views.my_notifications),
    path('notifications/<int:notif_id>/read/', views.mark_notification_read),

    # Officer endpoints
    path('issue/<int:issue_id>/status/', views.update_status),
    path('issues/all/', views.all_issues),
]