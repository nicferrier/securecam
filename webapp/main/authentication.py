from django.shortcuts import render_to_response
from django.contrib.auth import logout as auth_logout
from django.http import HttpResponse, HttpResponseRedirect

import logging

def login_page(request):
    if request.user.is_authenticated():
        return HttpResponseRedirect('/dashboard/')
    else:
        return render_to_response('login.html')

def logout(request):
    """Logs out user"""
    auth_logout(request)
    return HttpResponseRedirect('/')

def fb_authenticate(request):
    logger = logging.getLogger("authenticate.fb_authenticate")
    data = request.GET.copy()
    try:
        auth_code = data['code']
        logger.info(str(data))
    except KeyError:
        logger.warn(str(data))
        render_to_response('fb_declined.html', RequestContext(request))
    return HttpResponseRedirect('/dashboard/')