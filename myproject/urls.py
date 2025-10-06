"""
URL configuration for myproject project.
"""
from django.contrib import admin
from django.urls import path
from django.http import HttpResponse


def home(request):
    return HttpResponse("Hello from ACR Sample Django App!")


urlpatterns = [
    path('admin/', admin.site.urls),
    path('', home, name='home'),
]
