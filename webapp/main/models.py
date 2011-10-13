from django.db import models
from django.contrib.auth.models import User
from datetime import datetime
# Create your models here.


class Room(models.Model):
    owner = models.ForeignKey(User, related_name='rooms')
    created = models.DateTimeField(default=datetime.now)
    lastmodified = models.DateTimeField(default=datetime.now)
    is_active = models.BooleanField(default=True)
    name = models.CharField(max_length=15)

