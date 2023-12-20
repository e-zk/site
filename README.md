site
====

source files + code for static website


	main.go  ==> main
	posts.go ==> post list + meta parsing
	index.go ==> index generation
	gen.go   ==> article generation / tempate functions
	rss.go   ==> rss generation



	usage: zorg [command] [args]
	commands:
		gen	(re)generate all posts
		index	generate index file (to stdout)
		rss	generate rss feed (to stdout)
	
	args:
		-n	do nothing - just list steps that would be taken

