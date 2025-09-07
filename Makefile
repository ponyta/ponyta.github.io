# Default run in dev mode
.DEFAULT_GOAL=dev

install:
	bundle install
prod:
	JEKYLL_ENV=production bundle exec jekyll build
dev:
	JEKYLL_ENV=development bundle exec jekyll serve --drafts
