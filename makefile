.POSIX:
.PHONY: update rss serve

all: update rss serve

update:
	../site-gen/site-gen .

rss:
	echo stub

# serve (for testing only)
serve:
	-pgrep sghs || sghs && echo "error: already serving"
