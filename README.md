# Homelab Documentation

This repository contains the configuration and setup for my homelab cluster. It includes various applications, middleware, and scripts to manage services.

---

## Services Overview


## Directory Structure

### Scripts Directory
- **ddns.sh**: A script for updating dynamic DNS records.
- **unstage_sensitives.sh**: for unstaging sensitives files.
- **gen.sh**: A script for substituting environment variables in configuration files.
- **do-backup.sh**: Encrypted offsite backup script using `rclone crypt`.
- **report_zpool.sh**: Report to Ntfy topic if the zfs pool is errors out

## Root Directory

- **.env**: Environment variables for the entire homelab setup.
- **.env.template**: Environment declarations only  
- **apps**: Custom regular apps that are deployed in cluster
- **cluster**: Cluster resources (crds, namespaces, storage, configs, secrets) and infrastructure apps

## Backups (`scripts/do-backup.sh`)

Syncs local directories to a remote using `rclone crypt`:
- **Encrypted & Obfuscated**: File contents, file names, and directory structures are client-side encrypted before uploading.
- **Ignore Marker**: Any directory containing a `.backup-ignore` file is skipped automatically.
- **Dry Run**: Pass `-D` (or set `DRY_RUN=true`) to test without transferring files.

## Why I use the Intel Device Operator

Normally Jellyfin needs privileged: true to access /dev/dri for Intel iGPU transcoding. Running privileged pods is a big security risk.
The Intel Device Plugin Operator exposes the GPU to Kubernetes safely, so the pod can use hardware acceleration without needing privileged mode.
