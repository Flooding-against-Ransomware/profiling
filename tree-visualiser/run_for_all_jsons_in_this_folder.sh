#!/bin/bash

FOLDER="${1:-.}"

if [ ! -d "$FOLDER" ]; then
    echo "Error: '$FOLDER' is not a valid directory."
    exit 1
fi

JSON_FILES=("$FOLDER"/*.json)

if [ ! -e "${JSON_FILES[0]}" ]; then
    echo "No JSON files found in '$FOLDER'."
    exit 0
fi

for json_file in "${JSON_FILES[@]}"; do
    echo "Processing: $json_file"
    uv run python tree_visualiser.py "$json_file"
    if [ $? -ne 0 ]; then
        echo "Warning: failed on '$json_file', continuing..."
    fi
done

echo "Done."