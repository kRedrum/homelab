# Homelab Documentation

This repository contains the configuration and setup for my self-hosted homelab. It includes various applications, middleware, and scripts to manage and secure the services.

---

## Services Overview

### Applications

| Application        | Status |
|--------------------|--------|
| **code-server**    |        |
| **atsumenu**       |        |
| **jellyfin**       |    x   |
| **actual**         |        |
| **adguard**        |    x   |
| **audiobookshelf** |        |
| **grafana/loki**   |        |
| **portainer**      |    x   |
| **traefik**        |    x   |
| **gethomepage**    |    x   |
| **fail2ban**       |        |
| **jellyseerr**     |        |
| **rustdesk**       |        |
---

## Backup
- rclone with encryption to wasabi s3

## Directory Structure

### Scripts Directory
- **ddns.sh**: A script for updating dynamic DNS records.
- **./unstage_sensitives.sh**: Place it in the git precommit file
- **gen-yaml.sh**: A script for substituting environment variables in configuration files.

## Root Directory

### /env
- **.env**: Environment variables for the entire homelab setup.
- **apps/.env/**: Environment variables for each app (PORTS, DOMAIN)
- **.gitignore**: Specifies files and directories to ignore (e.g., `.env`, logs, generated yamls).

### Application Folders
Each application (e.g., `jellyfin`, `authentik`) has its own folder containing:
- **.env**: Environment variables specific to the application.
- **docker-compose.template.{yml,yaml}**: A Docker Compose template for the application.
- **configs/**: Configurational folders mounted to the containers.
---

## Scripts

# YAML Template Generator **scripts/gen_yaml.sh**

A bash script for generating YAML files from templates by substituting environment variables. Particularly useful for managing Docker Compose and other YAML configurations across multiple containers and nested directories.

## Usage

Variables in template files should be formatted as `${VARIABLE_NAME}`
```bash
./gen_yaml.sh -f COMPOSE_FOLDERS -n CONTAINER_NAMES -e BASE_ENV_FILE_PATH [-r REMOTE_HOST]
```

### Arguments

- `-f` : Path to the folder containing template files and .env files
- `-n` : Container names separated by semicolons (;)
- `-r` : (Optional) Remote host to copy the generated files to
- `-e` : Base environment file (you can also place them in the folders)

## Directory Structure

```
COMPOSE_FOLDER/
├── .env 
├── container1/
│   ├── .env
│   ├── docker-compose.template.{yml,yaml}
│   └── config/
│       ├── .env (optional)
│       └── config.template.{yml,yaml}
├── container2/
    └── ...
```
