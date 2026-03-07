#!/bin/bash

FOLDER=".."
DELIMITER=";"
REMOTE_HOST=""
ENV_FILE=".env"
# FOLDER_TO_EXCLUDE=('scripts')

BLUE='\033[0;34m'


usage() {
  echo "Usage: $0 -f FOLDER -e ENV_FILE [-r REMOTE_HOST]"
  echo "  -f: root folder to use substitions (default: ..)"
  echo "  -r: remote host to copy the generated files"
  echo "  -e: base env file to use"
  exit 1
}

# Parse command-line arguments
while getopts "f:r:e:" opt; do
  case $opt in
  f) FOLDER="$OPTARG" ;;
  e) ENV_FILE="$OPTARG" ;;
  *) usage ;;
  esac
done

substitue() {
  local dir="$1"
  local template_files=($@)
  local env_file="${FOLDER}/${ENV_FILE}"

  # xargs for convert output to args for export
  export $(grep -v '^#' $env_file | xargs)

  for template_file in "${template_files[@]}"; do
    echo $template_file

    # Remove the .template from the file name
    local output_file="${template_file//\.template/}"
    
    # TODO: find better templating that preserves ${} at no match
    echo -e "${BLUE}[Log]: 🔄 Substituting $(basename $template_file) in $dir"
    envsubst "$(grep -v '^#' $env_file | awk -F= '{printf "${%s} ", $1}')" < "$template_file" > "$output_file"
  done
}

walk() {
  local dir="$1"
  # prev shell globbing, returned pattern itself on empty
  local template_files=($(find "$dir" -maxdepth 1 -type f -name "*.template.yml"))

  if (( ${#template_files[@]} > 0 )); then
    substitue "$dir" "${template_files[@]}"
  fi

  for subdir in "$dir"/*; do
    if [[ -d "$subdir" ]]; then
      walk "$subdir"
    fi
  done

}

walk "$FOLDER"

echo "[Log]: ✅ Done!"
