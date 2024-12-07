.PHONY: post

post:
	@if [ -z "$(date)" ] && [ -z "$(name)" ]; then \
		./scripts/make-post.sh; \
	elif [ -z "$(name)" ]; then \
		./scripts/make-post.sh "$(date)"; \
	else \
		./scripts/make-post.sh "$(date)" "$(name)"; \
	fi