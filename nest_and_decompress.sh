#!/bin/bash

# Script to organize zip archives by creating nested directories based on archive names
# Usage: ./script.sh /path/to/root/directory

# Check if root directory is provided
ROOT_DIR="$1"
if [[ -z "$ROOT_DIR" ]]; then
  echo "Usage: $0 /path/to/root/directory"
  echo "This script will organize zip archives into nested directories and extract them."
  exit 1
fi

# Check if root directory exists
if [[ ! -d "$ROOT_DIR" ]]; then
  echo "Error: Directory '$ROOT_DIR' does not exist."
  exit 1
fi

# Function to extract archive name components
extract_name_components() {
  local filename="$1"
  local base_name="${filename%.zip}"
  
  # Extract the main game name (everything before the first bracket)
  local game_name=$(echo "$base_name" | sed 's/\s*\[.*$//')
  
  # Extract the ID (first bracketed content)
  local game_id=$(echo "$base_name" | grep -o '\[[^]]*\]' | head -n1)
  
  echo "$game_name|$game_id"
}

# Find all zip files in the root directory
find "$ROOT_DIR" -maxdepth 1 -type f -name "*.zip" -print0 | while IFS= read -r -d '' zip_file; do
  # Get just the filename without path
  filename=$(basename "$zip_file")
  
  echo "Processing: $filename"
  
  # Extract name components
  components=$(extract_name_components "$filename")
  game_name=$(echo "$components" | cut -d'|' -f1)
  game_id=$(echo "$components" | cut -d'|' -f2)
  
  # Clean up game name (trim whitespace)
  game_name=$(echo "$game_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  # Skip if we couldn't extract proper components
  if [[ -z "$game_name" || -z "$game_id" ]]; then
    echo "✗ Error: Could not parse archive name format for $filename"
    echo "Expected format: 'Game Name [ID][optional].zip'"
    echo "----------------------------------------"
    continue
  fi
  
  echo "Game Name: $game_name"
  echo "Game ID: $game_id"
  
  # Create nested directory structure
  nested_dir="$ROOT_DIR/$game_name/$game_id"
  
  echo "Creating directory structure: $nested_dir"
  if ! mkdir -p "$nested_dir"; then
    echo "✗ Error: Failed to create directory structure: $nested_dir"
    echo "----------------------------------------"
    continue
  fi
  
  # Move the zip file to the nested directory
  target_zip="$nested_dir/$filename"
  echo "Moving archive: $filename -> $target_zip"
  
  if ! mv "$zip_file" "$target_zip"; then
    echo "✗ Error: Failed to move $filename to $target_zip"
    echo "----------------------------------------"
    continue
  fi
  
  echo "✓ Successfully moved archive to: $target_zip"
  
  # Extract the zip file in the same directory
  echo "Extracting archive..."
  if (cd "$nested_dir" && unzip -q "$filename"); then
    echo "✓ Successfully extracted: $filename"
    
    # Remove the zip file after successful extraction
    if rm "$target_zip"; then
      echo "✓ Removed original archive: $filename"
    else
      echo "✗ Warning: Failed to remove original archive: $target_zip"
    fi
  else
    echo "✗ Error: Failed to extract $filename"
  fi
  
  echo "----------------------------------------"
done

echo "Organization and extraction complete!"