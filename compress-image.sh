#!/bin/bash

# Check if cwebp is installed
if ! command -v cwebp &> /dev/null; then
    echo "Error: cwebp is not installed"
    echo "Please install webp package:"
    echo "  - macOS: brew install webp"
    echo "  - Ubuntu/Debian: sudo apt-get install webp"
    echo "  - CentOS/RHEL: sudo yum install libwebp-tools"
    exit 1
fi

# Check if image path is provided
if [ -z "$1" ]; then
    echo "Usage: ./compress-image.sh <image_path>"
    exit 1
fi

# Check if file exists
if [ ! -f "$1" ]; then
    echo "Error: File not found!"
    exit 1
fi

# Get directory and filename
source_dir=$(dirname "$1")
filename=$(basename -- "$1")
filename_noext="${filename%.*}"

# Convert to WebP with quality adjustment if needed
echo "Converting to WebP..."
quality=100
min_qulity=25
max_size=$((100 * 1024))  # 100KB in bytes

while true; do
    cwebp -quiet -q $quality -resize 1080 0 "$1" -o "${source_dir}/${filename_noext}.webp"
    
    current_size=$(stat -f%z "${source_dir}/${filename_noext}.webp")
    
    if [ $current_size -le $max_size ] || [ $quality -le $min_qulity ]; then
        break
    fi
    
    quality=$((quality - 5))
    echo "File too large, retrying with quality: $quality"
done

# Calculate and show size comparison
original_size=$(stat -f%z "$1")
final_size=$(stat -f%z "${source_dir}/${filename_noext}.webp")
reduction=$((100 - (final_size * 100 / original_size)))

# Convert sizes to KB/MB for display
format_size() {
    local size=$1
    if [ $size -ge 1048576 ]; then
        echo "$(echo "scale=2; $size/1048576" | bc)MB"
    else
        echo "$(echo "scale=2; $size/1024" | bc)KB"
    fi
}

echo "Successfully converted and compressed to: ${source_dir}/${filename_noext}.webp"
echo "Original size: $(format_size $original_size)"
echo "Final size: $(format_size $final_size)"
echo "Size reduction: ${reduction}%"
echo "Final WebP quality: $quality"