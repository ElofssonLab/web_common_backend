FROM debian:trixie-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DJANGO_SETTINGS_MODULE=proj.docker_settings \
    DATA_DIR=/data \
    UV_PYTHON_INSTALL_DIR=/opt/python \
    PATH=/opt/venv/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
        slurm-wlm munge git gcc libxml2-dev libxslt1-dev libffi-dev procps gettext-base ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 webapp

WORKDIR /app
COPY requirements/docker.txt /tmp/requirements.txt
RUN uv venv --python 3.9 /opt/venv \
    && uv pip install --python /opt/venv/bin/python -r /tmp/requirements.txt

COPY src/ /app/
COPY compose/django/slurm.conf.tmpl /etc/slurm/slurm.conf.tmpl
COPY compose/django/cgroup.conf /etc/slurm/cgroup.conf
COPY compose/django/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chown -R webapp:webapp /app

EXPOSE 8000
VOLUME /data
ENTRYPOINT ["/entrypoint.sh"]
CMD ["gunicorn", "proj.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "120"]
