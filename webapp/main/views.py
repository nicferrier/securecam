# Create your views here.
from django.http import HttpResponse
from django.template import RequestContext
from django.shortcuts import render_to_response

from django import forms
from muphan.models import Photo
from muphan.views import handle

HTTP_CREATED = 201

def index(request):
    return render_to_response('index.html', RequestContext(request))

class Upload(forms.Form):
    title = forms.CharField(max_length=150, required=False)
    photo  = forms.FileField(required=False)

def upload(request, username, room_id):
    if request.method == "POST":
        form = Upload(request.POST, request.FILES)
        if form.is_valid():
            # import pdb; pdb.set_trace()
            content_type = form.files["photo"].content_type
            photo = Photo.objects.make_photo(
                request.user, 
                media_type = content_type,
                unique = '%s' % room_id,
                description = form["title"]
            )
            file_data = request.FILES["photo"]
            handle(photo, content_type, file_data)
            response = HttpResponse(status=HTTP_CREATED)
            response["Location"] = photo.url
            return response
        else:
            return HttpResponse(str(form.errors), status_code=403)

    form = Upload()
    return HttpResponse()

