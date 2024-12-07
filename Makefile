# Run local development
.PHONE: run
run:
	bundle exec jekyll serve --config _config.yml,_config-dev.yml --livereload

# Create new post template
.PHONY: post
post:
	@if [ -z "$(title)" ] && [ -z "$(date)" ]; then \
		./scripts/make-post.sh; \
	elif [ -z "$(date)" ]; then \
		./scripts/make-post.sh "$(title)"; \
	elif [ -z "$(title)" ]; then \
		./scripts/make-post.sh "" "$(date)"; \
	else \
		./scripts/make-post.sh "$(title)" "$(date)"; \
	fi

# Get image from Unsplash
.PHONY: image
image:
	@if [ -z "$(query)" ]; then \
		echo "Please provide a search query using 'query' parameter"; \
		echo "Usage: make image query='mountain landscape'"; \
		exit 1; \
	fi
	@./scripts/get-image.sh "$(query)"

# Compress image to WebP format
.PHONY: compress
compress:
	@if [ -z "$(image)" ]; then \
		echo "Please provide a image path using 'image' parameter"; \
		echo "Usage: make compress image='path/to/image.jpg'"; \
		exit 1; \
	fi
	@./compress-image.sh "$(image)"