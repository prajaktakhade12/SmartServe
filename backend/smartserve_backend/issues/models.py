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

    # User Details (mobile acts as user identifier)
    name = models.CharField(max_length=100)
    mobile = models.CharField(max_length=10)

    # Issue Details
    title = models.CharField(max_length=200)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    description = models.TextField()
    location = models.CharField(max_length=255)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)

    # Photo
    image = models.ImageField(upload_to='issues/', null=True, blank=True)

    # Status
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='REPORTED'
    )

    # Officer remarks (set by officer desktop app)
    officer_remarks = models.TextField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.mobile})"


class Notification(models.Model):
    mobile = models.CharField(max_length=10)
    issue = models.ForeignKey(Issue, on_delete=models.CASCADE)
    message = models.CharField(max_length=255)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.message