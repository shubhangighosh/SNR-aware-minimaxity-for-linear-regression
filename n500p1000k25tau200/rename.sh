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

# Perform the rotation using a temporary directory
TOTAL_FILES=${#SORTED_INDICES[@]}
TEMP_DIR=$(mktemp -d) # Temporary directory to avoid overwriting

# Step 1: Move files to temporary directory with new names
for (( i = 0; i < TOTAL_FILES; i++ )); do
    ORIGINAL_INDEX=${SORTED_INDICES[$i]}
    # Compute the new index with rotation
    NEW_INDEX=$(( (i + ROTATION + TOTAL_FILES) % TOTAL_FILES + 1 ))
    mv "$DIR/$PATTERN$ORIGINAL_INDEX.$EXTENSION" "$TEMP_DIR/$PATTERN$NEW_INDEX.$EXTENSION"
    echo "Temporarily renamed $PATTERN$ORIGINAL_INDEX.$EXTENSION to $PATTERN$NEW_INDEX.$EXTENSION"
done

# Step 2: Move files back from the temporary directory
for FILE in "$TEMP_DIR"/*; do
    BASENAME=$(basename "$FILE")
    mv "$FILE" "$DIR/$BASENAME"
    echo "Moved $BASENAME back to $DIR"
done

# Clean up
rmdir "$TEMP_DIR"

echo "Rotation and renaming complete!"
