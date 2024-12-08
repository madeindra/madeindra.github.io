#!/bin/bash

# Check for required environment variables
if [ -z "$UNSPLASH_ACCESS_KEY" ]; then
    echo "Error: UNSPLASH_ACCESS_KEY environment variables are required"
    echo "Please set them before running this script"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    echo "Please install jq first:"
    echo "  macOS: brew install jq"
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  CentOS/RHEL: sudo yum install jq"
    exit 1
fi

# Check parameters
if [ $# -eq 0 ]; then
    echo "Please provide either a search query or photo ID"
    echo "Usage: ./get-image.sh 'search query'"
    echo "   or: ./get-image.sh --id 'photo-id'"
    exit 1
fi

if [ $# -gt 2 ]; then
    echo "Error: Too many parameters"
    echo "Usage: ./get-image.sh 'search query'"
    echo "   or: ./get-image.sh --id 'photo-id'"
    exit 1
fi

# Create assets/images directory if it doesn't exist
mkdir -p assets/images

# Get today's date
DATE=$(date +%Y-%m-%d)

# Handle parameters and set API URL
if [ "$1" = "--id" ]; then
    if [ -z "$2" ]; then
        echo "Error: Photo ID is required when using --id"
        exit 1
    fi
    API_URL="https://api.unsplash.com/photos/$2"
    FILENAME_SUFFIX="$2"
else
    if [ "$2" ]; then
        echo "Error: Invalid parameter combination"
        echo "Usage: ./get-image.sh 'search query'"
        echo "   or: ./get-image.sh --id 'photo-id'"
        exit 1
    fi
    SEARCH_QUERY=$(echo "$1" | tr ' ' '+')
    API_URL="https://api.unsplash.com/photos/random?query=${SEARCH_QUERY}"
    FILENAME_SUFFIX="$1"
fi

# Download image metadata from Unsplash
JSON_FILE=$(mktemp)
TEMP_FILE=$(mktemp)

curl -s \
  -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY" \
  -H "Accept-Version: v1" \
  "$API_URL" -o "$JSON_FILE"

# Extract image URL and download the actual image
IMAGE_URL=$(jq -r '.urls.full' "$JSON_FILE")
curl -s "$IMAGE_URL" -o "$TEMP_FILE"
rm "$JSON_FILE"

# Get file extension based on content type
CONTENT_TYPE=$(file --mime-type -b "$TEMP_FILE")
case "$CONTENT_TYPE" in
    "image/jpeg") EXT="jpg" ;;
    "image/png") EXT="png" ;;
    "image/gif") EXT="gif" ;;
    *) EXT="jpg" ;; # Default to jpg
esac

# Move file to assets/images with proper naming
mv "$TEMP_FILE" "assets/images/${DATE}-${FILENAME_SUFFIX// /-}.$EXT"

echo "Image downloaded successfully to assets/images/${DATE}-${FILENAME_SUFFIX// /-}.$EXT"