## sh Runner

### Description

Minimal Docker image that runs your shell scripts from `/sh-scripts` on a cron schedule. The image stays generic: it does **not** bake in database clients, or other purpose-specific tools. Mount your own scripts and install whatever each job needs.

### Critical fix (nested cron)

Older images ran `/defaultPoint.sh` from cron, and that script **started another `crond`**. Each night added more cron daemons → overlapping jobs → host OOM.

Current behavior:

- **One** `crond` started by `entrypoint.sh` only
- Cron calls `/run-scripts.sh` (scripts only — never starts cron again)
- Overlapping runs are skipped via a lock
- Scripts named `install-*`, `_*`, or `*.setup.sh` are treated as setup helpers (not daily cron jobs)

### Requirements

* Docker
* Docker Compose (recommended)

### Dev example

```yaml
sh-runner:
  container_name: sh-runner
  build: .
  restart: unless-stopped
  healthcheck:
    test: ["CMD-SHELL", "pgrep cron"]
    interval: 30s
    timeout: 10s
    retries: 3
  environment:
    EXECUTE_ON_START: "false"
    CRON_SCHEDULE: "0 2 * * *"
  volumes:
    - ./logger:/logger
    - ./scripts-example:/sh-scripts
```

### Prod example

```yaml
sh-runner:
  image: muhaimeed/sh-runner:latest
  restart: unless-stopped
  healthcheck:
    test: ["CMD-SHELL", "pgrep cron"]
    interval: 30s
    timeout: 10s
    retries: 3
  environment:
    EXECUTE_ON_START: "false"
    CRON_SCHEDULE: "0 2 * * *"
  volumes:
    - ./logger:/logger
    - ./your-scripts:/sh-scripts
```

### Volumes

* `/sh-scripts` – job scripts (executable `*.sh`)
* `/logger` – logs

Mount any extra paths your jobs need (data, output, etc.) yourself via Docker — the image does not assume a backup folder.

### Environment Variables

1. **EXECUTE_ON_START** — if `true`, run job scripts once at container start (default: `false`). Prefer `false` on small VPS hosts.
2. **CRON_SCHEDULE** — cron expression for daily jobs (default: `0 2 * * *`).

### Bring your own tools

The base image is Alpine + cron only. Install tools from a setup script that runs once at container start:

* `install-*.sh`
* `*.setup.sh`

Example (`install-tools.sh`):

```sh
#!/bin/sh
set -e
apk add --no-cache curl jq
# or: apk add --no-cache aws-cli postgresql-client mariadb-client
```

Daily job scripts under `/sh-scripts` can then use those tools. Setup scripts are **not** re-run by cron.

## License

[MIT](http://opensource.org/licenses/MIT)
