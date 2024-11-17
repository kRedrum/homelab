#!/bin/bash

COMPOSE_FOLDER="."
CONTAINER_NAMES=""
DELIMITER=";"
REMOTE_HOST=""
BASE_ENV_FILE_PATH=""

COMPOSE_FILES=()

usage() {
  echo "Usage: $0 -f COMPOSE_FOLDER -n CONTAINER_NAMES [-r REMOTE_HOST]"
  echo "  -f: folder containing the docker-compose.template.yml and .env files"
  echo "  -n: container names separated by ;"
  echo "  -r: remote host to copy the generated docker-compose.yml files"
  echo "  -e: base env file to use"
  exit 1
}

# Parse command-line arguments
while getopts "f:n:r:e:" opt; do
  case $opt in
  f) COMPOSE_FOLDER="$OPTARG" ;;
  n) CONTAINER_NAMES="$OPTARG" ;;
  r) REMOTE_HOST="$OPTARG" ;;
  e) BASE_ENV_FILE_PATH="$OPTARG" ;;
  *) usage ;;
  esac
done

if [ -z "$COMPOSE_FOLDER" ] || [ -f "$COMPOSE_FOLDER" ]; then
  echo "[Error]: container folder not specified, please select one with -f"
  exit 1
fi

if [ -z "$CONTAINER_NAMES" ]; then
  echo "[Error]: Please select a container name with -n"
  exit 1
fi

substitue() {
  local dir="$1"
  local env_file="$2"
  local template_file="$3"
  # Remove the .template from the file name parameter expansion
  local output_file="${template_file//\.template/}"

  if [ ! -d "$dir" ]; then
    echo "[Error]: $dir folder does not exist"
    return
  fi
  if [ ! -f "$template_file" ]; then
    echo "[Error]: *.yml file not found in $dir"
    return
  fi
  if [ ! -f "$env_file" ]; then
    env_file=$BASE_ENV_FILE_PATH
    echo "[Error]: .env file not found in $dir"
  fi

  # xargs for convert output to args for export
  export $(grep -v '^#' $env_file | xargs)

  echo "[Log]: Substituting  $output in $dir compose folder"
  envsubst < $template_file > $output_file
}

run() {
  IFS="$DELIMITER" read -ra names <<<"$CONTAINER_NAMES"
  for name in "${names[@]}"; do
    local dir="$COMPOSE_FOLDER/$name"
    local env_file="$COMPOSE_FOLDER/$name/.env"
    local template_file="$COMPOSE_FOLDER/$name/docker-compose.template.yml"


    substitue "$dir" "$env_file" "$template_file"

    # nested directories configuration
    for nested_dir in "$dir"/*; do
      if [ -d "$nested_dir" ]; then
        local env_file="$nested_dir/.env"
        local yaml_files=($nested_dir/*.template.{yml,yaml})
        
        if [ ${#yaml_files[@]} -eq 0 ]; then
          echo "[Warning]: No YAML files found in $nested_dir"
          break
        fi
      
        for yaml_file in "${yaml_files[@]}"; do
          echo $yaml_file
          substitue "$nested_dir" "$env_file" "$yaml_file"
        done
      fi
    done
  done
}

run
