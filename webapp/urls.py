from django.conf import settings
from django.conf.urls.defaults import patterns, include, url
from django.contrib.staticfiles.urls import staticfiles_urlpatterns
from django.contrib import admin

# admin urls
admin.autodiscover()
urlpatterns = patterns('',
    url(r'^admin/', include(admin.site.urls)),
)

# static files
urlpatterns += staticfiles_urlpatterns()

if settings.DEBUG:
    urlpatterns += patterns('',
        url(r'^uploads/(?P<path>.*)$', 'django.views.static.serve', {
                'document_root': settings.MEDIA_ROOT,
                'show_indexes': True,
        }),
    )


# social auth urls
urlpatterns = patterns('',
    url(r'', include('social_auth.urls')),
)

# our urls.
urlpatterns += patterns('',
    url(r'accounts/profile/$',  'main.views.account_profile'),
    url(r'accounts/login/$',    'main.authentication.login_page'),
    url(r'login$',              'main.authentication.login_page'),
    url(r'logout$',             'main.authentication.logout'),
    url(r'fbauth$',             'main.authentication.fb_authenticate'),

    url(r'room/$',              'main.views.rooms'),
    url(r'room/(?P<roomid>[0-9]+)/setup/$',   'main.views.room_setup'),
    url(r'room/(?P<roomid>[0-9]+)/review/$',  'main.views.room_review'),
    url(r'room/(?P<roomid>[0-9]+)/image/$',   'main.views.room_upload'),

    url(r'dashboard/$',         'main.views.dashboard'),    
    
    url(r'^raw/(?P<template>[a-zA-Z]+).html$',     'main.views.raw'),
    url(r'^index$',   'main.views.index'),
)
