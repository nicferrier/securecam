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
    url(r'^(?P<username>[a-zA-Z0-9]+)/(?P<room_id>[a-zA-Z0-9]+)/image/', 'main.views.upload'),
    url(r'^/index$',   'main.views.index'),
)

