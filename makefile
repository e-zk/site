.POSIX:
.PHONY: update index rss serve

all: update index rss

update:
	shite ./.env

index:
	sh index.sh ./.env

rss:
	rss.sh ./.env > rss.xml

# serve (for testing only)
serve:
	-pgrep sghs || sghs && echo "error: already serving" &
