#!/bin/bash

DIRECTORY=${1:-aggregated_reports}

process_json_files() {
  find "$1" -type f -name "*.json" | while read -r file; do
    echo "Processing: $file"
    ruby analyser.rb "$file"
  done
}

process_json_files "$DIRECTORY"