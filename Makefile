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