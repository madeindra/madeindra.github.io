#!/bin/bash

# Get date parameter or use today's date
date=${1:-$(date +%Y-%m-%d)}
datetime=$(date +"%Y-%m-%d %H:%M:%S")

# Get post name parameter or use placeholder
post_name=${2:-"New Blog Post"}

# Convert post name to filename format (lowercase, replace spaces with hyphens)
filename=$(echo "$post_name" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

# Create post file
post_file="_posts/${date}-${filename}.md"

# Generate post content
cat > "$post_file" << EOF
---
layout: post
title: "${post_name}"
date: "${datetime}"
category: ""
image: "/assets/images/"
feature_image: true
description: ""
keywords:
  - 
  - 
comments: true
archived: false
---

Write your content here.
EOF

echo "Created new post: $post_file"