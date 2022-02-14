stagit setup on OpenBSD
=======================

[stagit](https://codemadness.org/stagit.html) is a static page generator for git repos. It's very minimal - which I like.

In this post I'll detail how I set up [git.zakaria.org](https://git.zakaria.org/) on my OpenBSD server.

The majority of my setup is based upon a post by `poptart`. Be sure to check out the original post here: https://hosakacorp.net/p/stagit-server.html. It's pretty well done, and easy to follow (unlike my post here - which is really more for my sake when I inevitably bork my server again and have to re-do it all). `poptart` has some other great OpenBSD-related posts on there as well.

Setup
-----

On the server install `git`, create the `_git` user, and make some directories:

	server# pkg_add git libgit2
	server# groupadd _git
	server# mkdir -p -m 744 /var/git/repos /var/git/template
	server# useradd -g _git -L daemon -c "git backend user" -d /var/git/repos -s /usr/local/bin/git-shell _git
	server# chown _git:_git /var/git/repos

The directories we created:

 - `/var/www/repos` contains the bare git files (also the `$HOME` of user `_git`)
 - `/var/git/template` will contain the template for new repositories.

The next steps are only if like me you've made source changes to stagit and you'd like to use your custom version. If you want to use plain stagit, install it on the server with `pkg_add stagit`.  
On another machine, compile stagit and `sftp` it over to the server:

	laptop$ make
	laptop$ md5 stagit stagit-index
	laptop$ # remember these checksums for verifying it's been copied over correctly
	laptop$ sftp enderman <<EOF
	> put stagit
	> put stagit-index
	> bye
	EOF

Back on the server, verify the binaries were copied over correctly:

	server# md5 stagit stagit-index
	server# # verify the checksums

Copy these binaries to `/usr/local/bin` and set permissions appropriately:

	server# cp stagit{,-index} /usr/local/bin
	server# chown root:bin /usr/local/bin/stagit{,-index} 
	server# chmod 755 /usr/local/bin/stagit{,-index}

The following is a message from the future:

> I wrote this post a while ago. But I recall abandoning the modified stagit binary setup
> purely because the libraries on my laptop were newer than my server, and I 
> could not get static compilation to work... 
> So I gave up and installed stagit via `pkg_add stagit` on the server :P

Scripts
-------
Next we'll configure a few scripts:

 - `/var/git/repos/template/post-receive`  
   Will be executed every time we push to a repo.
 - `/usr/local/bin/stagit-gen-index`  
   A helper script to generate the index page.
 - `/usr/local/bin/stagit-newrepo`  
   Script to run to create a new repository.
 - `/usr/local/bin/stagit-chdesc`  
   Script to change the description of an existing repository.

Some internal variables will be shared between these scripts, for instance the
git user, htdocs path, etc. Instead of writing these out into each script we
can create a config file that each script will source before running anything.  
In `/var/git/config.rc`:

	# shared variables
	GIT_HOME="/var/git"
	GIT_REPOS="${GIT_HOME}/repos"
	WWW_HOME="/var/www/htdocs/git.zakaria.org
	CLONE_URI="_git@git.zakaria.org"
	DEFAULT_OWNER="zakaria"
	DEFAULT_DESC=""
	GIT_USER="_git"

We restrict access to this file to `root:wheel`:

	server# chown root:wheel /var/git/config.rc

After a `git push` we want the server to (re)generate the static html pages. To do this, we write a script in `/var/git/template/post-receive`:

	#!/bin/sh
	# Author: Cale "poptart" Black
	# Modified by: zakaria @ zakaria.org
	# License: MIT
	
	set -euf
	
	. /var/git/config.rc
	
	export LC_TYPE="en_US.UTF-8"
	src="$(pwd)"
	name="$(basename "$src")"
	dest="${WWW_HOME}/$(basename "$name" '.git')"
	mkdir -p "$dest"
	cd "$dest" || exit 1

	echo "[stagit] building $dest"
	/usr/local/bin/stagit "$src"

	echo "[stagit] linking $dest"
	# if a README.html exists use that as the index.html
	# if not use log.html
	if [ -f "README.html" ]; then
		ln -sf README.html index.html
	else
		ln -sf log.html index.html
	fi
	ln -sf ../style.css style.css
	ln -sf ../logo.png logo.png

Next, we need a script to generate the stagit `/index.html`. In `/usr/local/bin/stagit-gen-index`:

	#!/bin/sh 
	# Author: Cale "poptart" Black
	# License: MIT
	
	set -eu
	
	. /var/git/config.rc
	stagit-index "${GIT_REPOS}/*.git" > "${WWW_HOME}/index.html"

The next script will be used to setup a new repository. In `/usr/local/bin/stagit-newrepo`:

	#!/bin/sh
	# Author: Cale "poptart" Black
	# Modified by: zakaria @ zakaria.org
	# License: MIT
	# Usage: stagit-newrepo <name> [desc] [author]
	
	set -eu
	
	. /var/git/config.rc
	
	log() {
		printf '%s\n' "$*" >&2
	}
	die() {
		log "error: $*"
		printf 'exiting...\n'
		exit 1
	}
	
	REPO="$1"
	DESC="${2:-$DEFAULT_DESC}"
	OWNER="${3:-$DEFAULT_OWNER}"
	
	if [ -z "$REPO" ]; then
		die "no repo name given"
	fi
	
	REPO_PATH="${GIT_REPOS}/${REPO}.git"
	
	git init --bare "$REPO_PATH"
	cp "${GIT_HOME}/template/post-receive" "${REPO_PATH}/hooks/post-receive"
	echo "${CLONE_URI}/${REPO}.git" > "${REPO_PATH}/url"
	echo "$OWNER" > "${REPO_PATH}/owner"
	echo "$DESC" > "${REPO_PATH}/description"
	
	chmod u+x "${REPO_PATH}/hooks/post-receive"
	mkdir "${WWW_HOME}/${REPO}"
	/usr/local/bin/stagit-gen-index

At the end of this script we call our `stagit-gen-index` helper script to regenerate
the `index.html`.

The last script is a simple wrapper that will allow us to change a repo's description:

	#!/bin/sh
	# Author: zakaria / zakaria.org
	# License: MIT
	# Usage: stagit-chdesc <repo> <new_description>
	
	set -eu
	
	. /var/git/config.rc
	
	log() {
		printf '%s\n' "$*" >&2
	}
	die() {
		log "error: $*"
		printf 'exiting...\n'
		exit 1
	}
	
	REPO="$1"
	DESC="$2"

	if [ -z "$REPO" ]; then
		die "no repo name provided"
	fi
	if [ -z "$DESC" ]; then
		die "no new description provided"
	fi
	
	REPO_PATH="${GIT_REPOS}/${REPO}.git"
	
	echo "$DESC" > ${REPO_PATH}/description

Then set the appropriate permissions and restrictions for these scripts:

	$ chmod +x /usr/local/bin/stagit-{gen-index,newrepo,chdesc}
	$ chown -R _git:_git /var/git/template
	$ chmod +x $GIT_HOME/template
	$ chown -R _git:_git $WWW_HOME

Replacing `GIT_HOME` and `WWW_HOME` with the variables we configured previously in `config.rc`.

Finally we configure our [doas.conf(5)](https://man.openbsd.org/doas.conf) to allow our main user to run these commands:

	permit nopass mite as _git cmd /usr/local/bin/stagit-newrepo
	permit nopass mite as _git cmd /usr/local/bin/stagit-gen-index
	permit nopass mite as _git cmd /usr/local/bin/stagit-chdesc

I've made a git repository for these scripts (and maybe a few more) available on [GitHub](https://github.com/e-zk/stagit-scripts) which is mirrored on [git.zakaria.org](https://git.zakaria.org/stagit-scripts/log.html)

httpd config
------------
To actually serve the generated static files we need to configure [httpd(8)](https://man.openbsd.org/httpd). In [`/etc/httpd.conf`](https://man.openbsd.org/httpd.conf):

	...snip...
	
	server "git.zakaria.org" {
		listen on 127.0.0.1 on 8080
	
		# for letsencrypt
		location "/.well-known/acme-challenge/*" {
			root "/acme"
			request strip 2
		}
	
		root "/htdocs/git.zakaria.org"
	}
	
	...snip...

I use [relayd(8)](https://man.openbsd.org/relayd) as a TLS proxy, so I don't need to configure TLS certs in httpd.conf.

