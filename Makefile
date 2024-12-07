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