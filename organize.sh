#!/bin/bash

# Root directory containing all folders to process
ROOT_DIR="$1"
if [[ -z "$ROOT_DIR" ]]; then
  echo "Usage: $0 /path/to/root/folder"
  exit 1
fi

# Function to reorganize a folder
reorganize_folder() {
  local folder_path="$1"
  local folder_dir
  local folder_name
  local version_string
  local base_name
  local version_folder
  local new_folder_name
  
  folder_dir=$(dirname "$folder_path")
  folder_name=$(basename "$folder_path")
  
  echo "Processing $folder_path..."
  
  # Check if folder has required subfolders
  local has_required_subfolder=false
  for subfolder in "exefs" "cheats" "romfs"; do
    if [[ -d "$folder_path/$subfolder" ]]; then
      has_required_subfolder=true
      break
    fi
  done
  
  if [[ "$has_required_subfolder" == false ]]; then
    echo "Skipping $folder_name: No exefs, cheats, or romfs subfolder found"
    return 0
  fi
  
  # Extract version string from folder name (pattern: v[digits].[digits].[digits])
  if [[ "$folder_name" =~ \[.*[[:space:]]v([0-9]+\.[0-9]+\.[0-9]+).*\] ]]; then
    version_string="${BASH_REMATCH[1]}"
  else
    echo "Skipping $folder_name: No version pattern found"
    return 0
  fi
  
  # Create base name by removing version from folder name
  base_name=$(echo "$folder_name" | sed "s/ v$version_string//")
  
  # Create version folder path
  version_folder="$folder_dir/$version_string"
  
  # Create version folder if it doesn't exist
  if [[ ! -d "$version_folder" ]]; then
    if ! mkdir -p "$version_folder"; then
      echo "Error: Failed to create version folder $version_folder"
      return 1
    fi
  fi
  
  # Create new folder path
  new_folder_name="$version_folder/$base_name"
  
  # Check if target already exists
  if [[ -d "$new_folder_name" ]]; then
    echo "Warning: Target folder $new_folder_name already exists, skipping"
    return 0
  fi
  
  # Move and rename the folder
  if mv "$folder_path" "$new_folder_name"; then
    echo "Successfully reorganized: $folder_name -> $version_string/$base_name"
  else
    echo "Error: Failed to move $folder_path to $new_folder_name"
    return 1
  fi
}

export -f reorganize_folder

# Find folders matching the pattern and reorganize them
# Use -print0 and read to handle folder names with special characters properly
find "$ROOT_DIR" -type d -name "*\[*\]*" -print0 | \
while IFS= read -r -d '' folder; do
  # Skip the root directory itself
  if [[ "$folder" != "$ROOT_DIR" ]]; then
    reorganize_folder "$folder"
  fi
done

echo "Folder reorganization complete!"