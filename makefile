.POSIX:
.PHONY: update index rss.xml

all: update index rss

update:
	shite ./.env

index:
	sh index.sh ./.env

rss.xml:
	rss.sh ./.env > rss.xml
