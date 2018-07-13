# Makefile for my blog
.DEFAULT_GOAL=all

prod:
	JEKYLL_ENV=production bundle exec jekyll build
dev:
	JEKYLL_ENV=development bundle exec jekyll serve
all:
	bundle exec jekyll build
