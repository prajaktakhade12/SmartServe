from django.urls import path
from . import views

urlpatterns = [
    # Citizen URLs
    path('issue/create/', views.create_issue),
    path('issue/my/', views.my_issues),
    path('issue/<int:issue_id>/', views.issue_detail),
    path('issue/<int:issue_id>/status/', views.update_status),
    path('issue/<int:issue_id>/rate/', views.rate_issue),
    path('issue/<int:issue_id>/comment/', views.add_comment),
    path('issue/nearby/', views.nearby_issues),
    path('dashboard/', views.dashboard),
    path('notifications/', views.my_notifications),
    path('notifications/<int:notif_id>/read/', views.mark_notification_read),
    path('issues/all/', views.all_issues),
    path('civic/points/', views.civic_points),
    path('civic/leaderboard/', views.leaderboard),
    # Officer URLs
    path('officer/login/', views.officer_login),
    path('officer/dashboard/', views.officer_dashboard),
    path('officer/issues/', views.officer_issues),
    path('officer/notifications/', views.officer_notifications),
]
