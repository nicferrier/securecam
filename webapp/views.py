# Create your views here.
from django.http import HttpResponse

def index(request):
    return HttpResponse('welcome')
