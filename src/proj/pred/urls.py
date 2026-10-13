from django.conf.urls import url
from spyne.server.django import DjangoView

from proj.pred import views

urlpatterns = [
    url(r'^api_submitseq/', DjangoView.as_view(application=views.app_submitseq)),
]
