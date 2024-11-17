#!/bin/bash

# Get all tracked files in the repository
repo_files=$(git ls-files)

staged_files=$(git diff --cached --name-only)

# Print each file
echo "[INFO]: All files in the repository:"
for staged_file in $staged_files; do
    # Skip files with ".template." in their name
    if [[ "$staged_file" == *".template."* ]]; then
        continue
    fi

    template_file="${staged_file%.*}.template.${staged_file##*.}"
    # Check if the template file exists in the list
    if echo "$repo_files" | grep -q "$template_file"; then
        echo "[INFO]: Match found: $staged_file has a corresponding $template_file"
        echo [INFO]: Removing $staged_file
        git reset $staged_file
    fi
done
