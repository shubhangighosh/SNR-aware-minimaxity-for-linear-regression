#!/bin/bash

# Input validation
if [ $# -ne 1 ]; then
    echo "Usage: $0 <rotation>"
    exit 1
fi

# Rotation parameter
ROTATION=$1

# Directory containing files (default: current directory)
DIR="./"

# Filename pattern
PATTERN="params"
EXTENSION="txt"

# Get all filenames matching the pattern
FILES=($(ls $DIR/$PATTERN*.$EXTENSION 2>/dev/null))

# Check if files are found
if [ ${#FILES[@]} -eq 0 ]; then
    echo "No files found matching pattern $PATTERN*.$EXTENSION in $DIR"
    exit 1
fi

# Extract numerical indices and sort
INDICES=()
for FILE in "${FILES[@]}"; do
    BASENAME=$(basename "$FILE" .$EXTENSION)
    INDEX=${BASENAME#$PATTERN} # Remove the prefix
    INDICES+=($INDEX)
done
IFS=$'\n' SORTED_INDICES=($(sort -n <<<"${INDICES[*]}"))
unset IFS

# Perform the rotation
TOTAL_FILES=${#SORTED_INDICES[@]}
NEW_FILES=()

for (( i = 0; i < TOTAL_FILES; i++ )); do
    ORIGINAL_INDEX=${SORTED_INDICES[$i]}
    # Compute the new index with rotation
    NEW_INDEX=$(( (i + ROTATION + TOTAL_FILES) % TOTAL_FILES + 1 ))
    NEW_FILENAME="$DIR/$PATTERN$NEW_INDEX.$EXTENSION"
    NEW_FILES+=("$NEW_FILENAME")
    # Rename the file
    mv "$DIR/$PATTERN$ORIGINAL_INDEX.$EXTENSION" "$NEW_FILENAME"
    echo "Renamed $PATTERN$ORIGINAL_INDEX.$EXTENSION to $PATTERN$NEW_INDEX.$EXTENSION"
done

# Create empty files for unassigned filenames
for (( i = 1; i <= TOTAL_FILES; i++ )); do
    TARGET_FILE="$DIR/$PATTERN$i.$EXTENSION"
    if [[ ! " ${NEW_FILES[@]} " =~ " $TARGET_FILE " ]]; then
        touch "$TARGET_FILE"
        echo "Created empty file $TARGET_FILE"
    fi
done

echo "Rotation and renaming complete!"


