#!/bin/bash
set -e

# New root structure
mkdir -p compose/django compose/nginx compose/postgres
mkdir -p requirements scripts
mkdir -p src/apps src/static src/templates

# Move Docker-related items
if [ -f docker-compose-apps.yml ]; then
  mv docker-compose-apps.yml docker-compose-apps.yml
fi

# Move Django project code
if [ -d proj ]; then
  mv proj src/myproject
fi

# Move main Django entrypoint
if [ -f manage.py ]; then
  mv manage.py src/
fi

# Requirements
if [ -f requirements.txt ]; then
  mv requirements.txt requirements/base.txt
fi

# Common scripts
for f in getuid.sh init.sh setup_virtualenv.sh; do
  if [ -f "$f" ]; then
    mv "$f" scripts/
  fi
done

# Documentation
mkdir -p docs
for f in README.md how_to_start_docker.md LICENSE; do
  if [ -f "$f" ]; then
    mv "$f" docs/
  fi
done

# Deployment & Ansible (infra)
mkdir -p infra/ansible infra/deployment
if [ -d ansible ]; then
  mv ansible infra/
fi
if [ -d deployment ]; then
  mv deployment infra/
fi

# Miscellaneous assets
if [ -d misc ]; then
  mv misc infra/
fi

# Add example environment file
cat > .env.example <<'EOF'
# Django settings
DJANGO_SETTINGS_MODULE=myproject.settings.dev
DEBUG=True
SECRET_KEY=changeme
ALLOWED_HOSTS=*

# Database
POSTGRES_DB=mydb
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
POSTGRES_HOST=db
POSTGRES_PORT=5432
EOF

# Create placeholder structure for settings split
mkdir -p src/myproject/settings
cat > src/myproject/settings/__init__.py <<'EOF'
# Settings package
EOF

cat > src/myproject/settings/base.py <<'EOF'
"""
Base Django settings shared across environments.
"""
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv("SECRET_KEY", "changeme")
DEBUG = os.getenv("DEBUG", "True") == "True"
ALLOWED_HOSTS = os.getenv("ALLOWED_HOSTS", "*").split(",")

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Add your apps here
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'myproject.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'myproject.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('POSTGRES_DB', 'postgres'),
        'USER': os.getenv('POSTGRES_USER', 'postgres'),
        'PASSWORD': os.getenv('POSTGRES_PASSWORD', ''),
        'HOST': os.getenv('POSTGRES_HOST', 'db'),
        'PORT': os.getenv('POSTGRES_PORT', '5432'),
    }
}

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']
EOF

cat > src/myproject/settings/dev.py <<'EOF'
from .base import *
DEBUG = True
EOF

cat > src/myproject/settings/prod.py <<'EOF'
from .base import *
DEBUG = False
EOF

# Create Docker placeholders
cat > compose/django/Dockerfile <<'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements/base.txt .
RUN pip install --no-cache-dir -r base.txt
COPY ./src /app
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EOF

cat > compose/django/start.sh <<'EOF'
#!/bin/sh
set -e
python manage.py migrate --noinput
python manage.py runserver 0.0.0.0:8000
EOF
chmod +x compose/django/start.sh

# Clean up old README files under src if present
find src -name "README.txt" -delete || true

echo "✅ Project restructured successfully!"
echo "Next steps:"
echo "1. Update imports and settings paths to match 'myproject.settings.dev'."
echo "2. Review infra/ and misc/ folders manually."
echo "3. Run 'docker-compose build && docker-compose up'."
