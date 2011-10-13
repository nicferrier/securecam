# Create your views here.
from django.http import HttpResponse, HttpResponseRedirect
from django.template import RequestContext
from django.shortcuts import render_to_response
from django.contrib.auth.decorators import login_required

from django import forms
from muphan.models import Photo
from muphan.views import handle

import appforms
import models as appmodels

HTTP_CREATED = 201

def index(request):
    return render_to_response('index.html', RequestContext(request))

def login_page(request):
    if request.user.is_authenticated():
        return HttpResponseRedirect('/dashboard/')
    else:
        return render_to_response('login.html')

@login_required
def account_profile(request):
    """display profile information form and user can save if they wish.
       link to dashboard.
    """
    return render_to_response('profile.html', RequestContext(request))

@login_required
def dashboard(request):
    """manage rooms and attached cameras - link to review rooms pictures"""
    return render_to_response('dashboard.html', RequestContext(request))

class Upload(forms.Form):
    title = forms.CharField(max_length=150, required=False)
    photo  = forms.FileField(required=False)

@login_required
def rooms(request):
    if request.method == 'POST':
        form = appforms.RoomForm(request.POST.copy())
        if form.is_valid():
            new_room = appmodels.Room.objects.create(
                owner = request.user,
                name  = form.cleaned_data['name']
            )
            
            return HttpResponseRedirect('/room/%d/setup/' % new_room.id)
        else:
            return HttpResponse(form.errors, status_code=403)
    else:
        return HttpResponseRedirect('/dashboard/')

@login_required
def room_setup(request, roomid):
    try:
        room = request.user.rooms.get(id=roomid)
        context = RequestContext(request, {'room': room})
        return render_to_response('room_setup.html', context)
    except:
        return HttpResponseRedirect('/dashboard/?invalid_room_access')

@login_required
def room_review(request, roomid):
    try:
        room = request.user.rooms.get(id=roomid)
        context = RequestContext(request, {'room': room})
        return render_to_response('room_review.html', context)
    except:
        return HttpResponseRedirect('/dashboard/?invalid_room_access')

@login_required
def room_upload(request, roomid):
    if request.method == "POST":
        form = Upload(request.POST, request.FILES)
        if form.is_valid():
            content_type = form.files["photo"].content_type
            photo = Photo.objects.make_photo(
                request.user, 
                media_type = content_type,
                unique = '%s' % roomid,
                description = form.cleaned_data["title"]
            )
            file_data = request.FILES["photo"]
            handle(photo, content_type, file_data)
            response = HttpResponse(status=HTTP_CREATED)
            response["Location"] = photo.url
            return response
        else:
            return HttpResponse(str(form.errors), status_code=403)

    return HttpResponseRedirect('/dashboard/?invalid_room_access')