# site

### setup

	$ cd /var/www/site
	$ git clone https://github.com/e-zk/site.git ./htdocs
	$ # add blog posts and such
	$ ./blog.sh add 2020-02-02-somepost.md

### index.html
homepage

### style.css
stylesheet

### blog.sh
script

	usage:  blog.sh [a|add] FILE
        	blog.sh [i|index] [h|help]
	
        	a|add   render a new post from FILE, create necessary dirs,
                	copy plaintext to site root, then regenerate the index
        	i|index regenerate index
        	h|help  show this help message

### posts/
posts

### m4/
m4 templates

