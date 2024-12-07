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

# Check if a search query is provided
if [ -z "$1" ]; then
    echo "Please provide a search query"
    echo "Usage: ./get-image.sh 'search query'"
    exit 1
fi

# Create assets/images directory if it doesn't exist
mkdir -p assets/images

# Get today's date
DATE=$(date +%Y-%m-%d)

# Format search query (replace spaces with plus)
SEARCH_QUERY=$(echo "$1" | tr ' ' '+')

# Download image metadata from Unsplash
JSON_FILE=$(mktemp)
TEMP_FILE=$(mktemp)

curl -s \
  -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY" \
  -H "Accept-Version: v1" \
  "https://api.unsplash.com/photos/random?query=${SEARCH_QUERY}" -o "$JSON_FILE"

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
mv "$TEMP_FILE" "assets/images/${DATE}-${1// /-}.$EXT"

echo "Image downloaded successfully to assets/images/${DATE}-${1// /-}.$EXT"