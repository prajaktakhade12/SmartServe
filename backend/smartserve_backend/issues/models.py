from django.db import models


class Issue(models.Model):
    CATEGORY_CHOICES = [
        ('ROAD', 'Road'),
        ('WATER', 'Water'),
        ('ELECTRICITY', 'Electricity'),
        ('SANITATION', 'Sanitation'),
        ('ENVIRONMENT', 'Environment'),
        ('SAFETY', 'Safety'),
        ('STREET_LIGHT', 'Street Light'),
        ('OTHER', 'Other'),
    ]
    STATUS_CHOICES = [
        ('REPORTED', 'Reported'),
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
    ]

    name = models.CharField(max_length=100, default='')
    mobile = models.CharField(max_length=10, default='')
    title = models.CharField(max_length=200, default='')
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default='OTHER')
    description = models.TextField(default='')
    location = models.CharField(max_length=255, default='')
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    image = models.ImageField(upload_to='issues/', null=True, blank=True)
    extra_images = models.TextField(default='', blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='REPORTED')
    officer_remarks = models.TextField(null=True, blank=True)
    rating = models.IntegerField(null=True, blank=True)
    rating_comment = models.TextField(null=True, blank=True)
    points_awarded = models.IntegerField(default=10)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.mobile})"


class StatusHistory(models.Model):
    issue = models.ForeignKey(Issue, on_delete=models.CASCADE, related_name='history')
    status = models.CharField(max_length=20)
    note = models.TextField(default='', blank=True)
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['changed_at']


class IssueComment(models.Model):
    issue = models.ForeignKey(Issue, on_delete=models.CASCADE, related_name='comments')
    mobile = models.CharField(max_length=10, default='')
    name = models.CharField(max_length=100, default='')
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']


class Notification(models.Model):
    mobile = models.CharField(max_length=10, default='')
    issue = models.ForeignKey(Issue, on_delete=models.CASCADE)
    message = models.CharField(max_length=255, default='')
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']


class CivicPoints(models.Model):
    mobile = models.CharField(max_length=10, unique=True)
    name = models.CharField(max_length=100, default='')
    total_points = models.IntegerField(default=0)
    issues_reported = models.IntegerField(default=0)
    issues_resolved = models.IntegerField(default=0)

    def __str__(self):
        return f"{self.mobile} - {self.total_points} pts"