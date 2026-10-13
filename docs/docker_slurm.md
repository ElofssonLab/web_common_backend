# Web server container with built-in Slurm

The `web` service runs Django (gunicorn) and a single-node Slurm cluster
(`munged`, `slurmctld`, `slurmd`) in one container. Jobs submitted by the web
app go to the local Slurm queue (`QUEUE_METHOD=slurm`).

## Start

    docker compose up -d --build
    curl -i 'http://localhost:8000/pred/api_submitseq/?wsdl'

The backend exposes only the SOAP/WSDL API (`submitjob_remote`, `checkjob`,
`deletejob`) at `/pred/api_submitseq/`. A submission creates a job directory
under `/data/result` and submits `run_job.py` to Slurm with `sbatch`; check it
with `docker compose exec web squeue`.

## Configuration (environment variables)

| Variable | Default | Meaning |
|---|---|---|
| `WEB_PORT` | `8000` | host port |
| `DJANGO_SECRET_KEY` | `insecure-change-me` | set this in production |
| `DJANGO_DEBUG` | `0` | enable Django debug |
| `DJANGO_ALLOWED_HOSTS` | `localhost,127.0.0.1` | comma-separated host list |
| `QUEUE_METHOD` | `slurm` | `slurm` or `suq` |
| `SLURM_CPUS` / `SLURM_MEMORY_MB` | detected | resources advertised to Slurm |
| `DJANGO_CSRF_TRUSTED_ORIGINS` | empty | comma-separated origins |

All state (sqlite DB, `result`, `tmp`, `md5`, `log`) lives in the `webdata`
volume mounted at `/data`.

## Check Slurm

    docker compose exec web sinfo
    docker compose exec -u webapp web sbatch --wrap="hostname"
    docker compose exec web squeue

## Notes

- Slurm cgroup support is disabled (`CgroupPlugin=disabled`) because the
  container cannot manage cgroups; this requires Slurm >= 24.x, hence the
  Debian trixie base image.
- Settings module: `proj.docker_settings`.
