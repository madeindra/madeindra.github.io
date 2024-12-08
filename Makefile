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
	@if [ ! -z "$(query)" ] && [ ! -z "$(id)" ]; then \
		echo "Error: Cannot use both query and id parameters"; \
		echo "Usage: make image query='mountain landscape'"; \
		echo "   or: make image id='photo-id'"; \
		exit 1; \
	elif [ -z "$(query)" ] && [ -z "$(id)" ]; then \
		echo "Please provide either a search query or photo ID"; \
		echo "Usage: make image query='mountain landscape'"; \
		echo "   or: make image id='photo-id'"; \
		exit 1; \
	elif [ ! -z "$(query)" ]; then \
		./scripts/get-image.sh "$(query)"; \
	else \
		./scripts/get-image.sh --id "$(id)"; \
	fi

# Compress image to WebP format
.PHONY: compress
compress:
	@if [ -z "$(image)" ]; then \
		echo "Please provide a image path using 'image' parameter"; \
		echo "Usage: make compress image='path/to/image.jpg'"; \
		exit 1; \
	fi
	@./compress-image.sh "$(image)"