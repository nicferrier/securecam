from django import forms

class RoomForm(forms.Form):
    name = forms.CharField()

