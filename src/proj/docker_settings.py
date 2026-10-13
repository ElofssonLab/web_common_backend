"""Django settings for the Docker deployment; configured through environment variables."""
import os
from .shared_settings import *

SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', 'insecure-change-me')
DEBUG = os.environ.get('DJANGO_DEBUG', '0') == '1'
ALLOWED_HOSTS = [h.strip() for h in os.environ.get('DJANGO_ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',') if h.strip()]
CSRF_TRUSTED_ORIGINS = [o.strip() for o in os.environ.get('DJANGO_CSRF_TRUSTED_ORIGINS', '').split(',') if o.strip()]

DATA_DIR = os.environ.get('DATA_DIR', '/data')
DATABASES['default']['NAME'] = os.path.join(DATA_DIR, 'db.sqlite3')
