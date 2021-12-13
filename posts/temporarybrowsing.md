# Temporary web browsing

Here's a few ways of scripting an ephemeral browser environment.

The idea is that the entire state of the browser is ephemeral - on exit
everything should be removed from storage including cookies, history
bookmarks, etc. This is more aggressive than your standard incognito mode
as it directly removes all files associated with the browser instance.

I use this all the time because for some things I don't find it necessary
for history, bookmarks, etc to be saved (a quick web search, logging into 
personal, sensitive services like online banking). Some might find it 
over-the-top but I think its a useful scripting exercise if anything.

## 1. Temporary profile

Browsers typically have a user "profile", where all bookmarks, history, and
other required state is stored.   
Most browsers that matter (Firefox, Chromium) allow the directory this profile
information is stored in to be configured via a CLI flag. For firefox this is 
`---profile <path>`, which defaults to somewhere in `~/.local` if my memory 
serves correct. Similarly, Chromium (and I assume other Chromium-based browsers
by proxy) support this via the `--user-data-dir=<path>`, which defaults to 
`~/.config/chromium`.

This feature can be used to create a fresh, new profile in a custom directory.
On exit this directory can be aggressively removed by a simple `rm -rf <path>`
command. Here's a short script to facilitate all this for Firefox:

	#!/bin/sh
	
	# make temporary profile directory
	PROFILE_DIR="$(mktemp -d -p /tmp 'firefox.XXXXXX')"
	
	cleanup() {
		rm -rvf "$PROFILE_DIR"
	}
	
	firefox-esr --new-instance --no-remote --profile "$PROFILE_DIR" "$@"
	
	cleanup

First the script creates a temporary directory via `mktemp`, where the profile
will be. Next we define a cleanup function to be run after Firefox, so that on
exit the profile is simply `rm -rf`'d. Then `firefox-esr` is run (replace this
with `firefox` if you don't use the ESR variant), and the profile directory is 
specified with `--profile`.

I also included the `--new-instance` flag to make sure Firefox didn't just
open a tab in an already running instance, and `--no-remote` to dissallow 
remote commands. 

Additional arguments can be passed to the script - these will be directly added to
`firefox-esr`'s arguments.

I also like to add a `trap` to the script, so if it ever exits unexpectedly,
the clean-up process will still take place. This is what that looks like:

	#!/bin/sh
	# trap everything; clean up on exit
	trap cleanup 1 2 3 6 15

	# make temporary profile directory
	PROFILE_DIR="$(mktemp -d -p /tmp 'firefox.XXXXXX')"
	
	cleanup() {
		rm -rvf "$PROFILE_DIR"
	}
	
	firefox-esr --new-instance --no-remote --profile "$PROFILE_DIR" "$@"
	
	cleanup

The equivalent final script for Chromium/Chrome:

	#!/bin/sh
	# trap everything; clean up on exit
	trap cleanup 1 2 3 6 15

	# make temporary profile directory
	PROFILE_DIR="$(mktemp -d -p /tmp 'chrome.XXXXXX')"
	
	cleanup() {
		rm -rvf "$PROFILE_DIR"
	}
	
	chromium --user-data-dir="$PROFILE_DIR" "$@"
	
	cleanup

## 2. Temporary home directory

Instead of specifying a custom profile, then removing it, why not create an
entire ephemeral home directory, then remove *that*?

This trick is fairly simple and works on *any program*, not just browsers.
Just re-define the `$HOME` environment variable to `$FAKEHOME`, and any program that runs 
after that will "think" that's the real home directory:

	$ FAKEHOME=/tmp/firefox
	$ HOME=$FAKEHOME firefox [...] https://zakaria.org/

Note this method means removing `$FAKEHOME/Downloads` and *any* directory the 
program creates in its dedicated home directory on exit. If you've downloaded
something you'd like to keep you'll need to copy it out of `$FAKEHOME/Downloads` 
*BEFORE* closing the browser.  
Since the program runs in a new home directory, if you use X11 it won't have 
access to `~/.Xauthority`, so it won't be able to actually be graphically useful. 
To fix this simply symlink `~/.Xauthority` to `$FAKEHOME/.Xauthority` before running.

A script that does all this, plus some more:

	#!/bin/sh
	# trap everything; clean up on exit
	trap cleanup 1 2 3 6 15
	
	# setup fake home dir
	FAKEHOME="$(mktemp -d -p /tmp 'firefox.XXXXXX')"
	
	# clean up after exit
	cleanup() {
		rm -rvf "$FAKEHOME"
	}
	
	# link Xauthority
	ln -s "${HOME}/.Xauthority" "${FAKEHOME}/.Xauthority"
	
	# unset XDG dirs as these can intefere with the fake $HOME if they're set
	# to something non-default
	unset XDG_CONFIG_HOME
	unset XDG_CACHE_HOME
	
	# set the fake home dir
	export HOME=${FAKEHOME}
	
	# run firefox w/ given args
	firefox-esr --new-instance --no-remote "$@"

	# uncomment for chrome
	# chromium "$@"
	
	cleanup

## Extra stuff

To add to these scripts, one could also:

- Force a specific user-agent string
- Configure `user.js` used by Firefox by writing to `$PROFILE_DIR/user.js`
  before actually running the Firefox command

My personal scripts do just that, for [Chromium](https://git.zakaria.org/bin-obsd/file/tmpchrome.html) and [Firefox](https://git.zakaria.org/bin-obsd/file/tmpfox.html "maybe uses outdated user.js flags"). 

## Other methods

Some other methods to look into include:
 
- Mounting a new **in-memory filesystem** dedicated to a fake home dir or browser 
  profile
  - OpenBSD does not support mounting filesystems as non-root
    users, so this isn't ideal for my setup.
- Ephemeral **containers**
  - While the security aspects of Linux containers are overrated IMO, using
    one as the basis for an ephemeral browser instance doesn't sound like an awful
    idea.
- Dedicated **virtual machine**
  - I've actually accomplished this in the past on an Alpine Linux VM running on OpenBSD's 
    [vmd(8)](https://man.openbsd.org/vmd) and X11 forwarding. But I never fleshed out
    any scripts for making it truly ephemeral - that might be the focus of a future blog post. 
    [Here's](/static/img/linuxwebvm.png) an old screenshot of that running on OpenBSD 6.7. 

