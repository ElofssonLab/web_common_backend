#!/bin/bash
set -euo pipefail

DATA_DIR=${DATA_DIR:-/data}
STATIC=/app/proj/pred/static
NODE_NAME=$(hostname -s)
NODE_CPUS=${SLURM_CPUS:-$(nproc)}
NODE_MEM=${SLURM_MEMORY_MB:-$(awk '/MemTotal/ {print int($2/1024*0.9)}' /proc/meminfo)}
export NODE_NAME NODE_CPUS NODE_MEM

start_slurm() {
    mkdir -p /run/slurm /var/spool/slurmd /var/spool/slurmctld /var/log/slurm /run/munge /var/log/munge /var/lib/munge
    chown slurm:slurm /run/slurm /var/spool/slurmctld /var/log/slurm
    chown -R munge:munge /run/munge /var/log/munge /var/lib/munge /etc/munge
    chmod 0700 /etc/munge /var/lib/munge
    chmod 0755 /run/munge

    [ -f /etc/munge/munge.key ] || /usr/sbin/mungekey --create
    chown munge:munge /etc/munge/munge.key && chmod 0400 /etc/munge/munge.key
    runuser -u munge -- /usr/sbin/munged

    envsubst < /etc/slurm/slurm.conf.tmpl > /etc/slurm/slurm.conf
    slurmctld
    slurmd

    for _ in $(seq 1 30); do
        sinfo -h 2>/dev/null | grep -qE 'idle|mix|alloc' && return 0
        sleep 1
    done
    echo "WARNING: slurm node did not become ready" >&2
    sinfo || true
}

mkdir -p "$DATA_DIR"
for d in result tmp md5 log; do
    mkdir -p "$DATA_DIR/$d"
    rm -rf "$STATIC/$d"
    ln -s "$DATA_DIR/$d" "$STATIC/$d"
done
chown webapp:webapp "$DATA_DIR" "$DATA_DIR"/{result,tmp,md5,log}
chmod 1777 "$DATA_DIR/tmp"

start_slurm

if [ "${1:-}" = "gunicorn" ] || [ "${1:-}" = "python" ]; then
    runuser -u webapp -- python manage.py migrate --noinput
fi

export QUEUE_METHOD=${QUEUE_METHOD:-slurm}
exec runuser -u webapp -p -- "$@"
