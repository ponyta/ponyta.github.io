# Makefile for my blog
.DEFAULT_GOAL=dev

prod:
	JEKYLL_ENV=production bundle exec jekyll build
dev:
	JEKYLL_ENV=development bundle exec jekyll serve --drafts
all:
	bundle exec jekyll build
