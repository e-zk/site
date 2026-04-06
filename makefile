.POSIX:
.PHONY: update index bookshelf serve

all: update index bookshelf

update:
	~/var/go/src/site-gen/site-gen compile

index:
	~/var/go/src/site-gen/site-gen index

bookshelf:
	~/var/go/src/site-gen/site-gen bookshelf

# serve (for testing only)
serve:
	ip a
	-pgrep sghs || sghs && echo "error: already serving"
