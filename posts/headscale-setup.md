# Installing headscale on OpenBSD

In this post I'll detail the steps I took to install and configure
[headscale](https://github.com/juanfont/headscale), an open-source self-hostable implementation of the [Tailscale](https://tailscale.com/) control server, on OpenBSD.

Code blocks prefixed with `#` imply that the command should be run as a privileged user/root.

If you get stuck, it'll be probably worthwhile to have a read of headscale's documentation available in their GitHub repo: https://github.com/juanfont/headscale/tree/main/docs .

## Compilation 

Since my server is on OpenBSD-stable, headscale is only available via `pkg_add` on -current, I need to compile the headscale binary by hand and upload it to the server.
I'm doing this on an OpenBSD machine, so compiling and uploading it to the server
should be a breeze.

	$ git clone git@github.com:juanfont/headscale.git
	$ cd headscale
	$ make
	$ sftp user@server <<EOF
	> put ./headscale
	> bye
	EOF

Then login, get root access, and copy the binary to `/usr/local/bin`:

	$ ssh user@server
	$ doas -s
	...
	# cp ./headscale /usr/local/bin
	# chown root:bin /usr/local/bin/headscale

## Configuration

Next we need to setup:

1. a `_headscale` daemon user that headscale will run as.
2. directories for headscale to store its sqlite database, private key, and socket (making sure they have the correct permissions/owner).
3. copy the example config from GitHub, and edit it to our liking

First we setup some directories:

	# mkdir -p /etc/headscale
	# touch /etc/headscale/config.yaml
	# mkdir -p /var/headscale

Then we add our `_headscale` daemon user, and `chown` all the necessary dirs.  
Here we also run `doas` to get us a shell as `_headscale` so I can create the db.sqlite file. Note doing it this way requires some `doas.conf` rules.

	# useradd -L daemon -s /sbin/nologin -d /var/headscale _headscale
	# chown -R _headscale:_headscale /var/headscale 
	# doas -u _headscale /bin/ksh
	$ touch /var/headscale/db.sqlite

Finally we can edit the headscale config. I highly recommend copying the [example config](https://raw.githubusercontent.com/juanfont/headscale/main/config-example.yaml) and using that as a starting point.

	# vi /etc/headscale/config.yaml
	# # copy the example config
	# # change domain, IPs, ports
	# # change sock location to /var/headscale/headscale.sock 

I'm currently using [relayd(8)](https://man.openbsd.org/relayd) as a TLS proxy, so I don't need to
configure any TLS-related stuff.

Run `headscale serve` to see if the config works, and all the directories and permissions are correct:

	# doas -u _headscale headscale serve
	...

If all is well we can move onto setting up an init script for the headscale daemon.

## rc.d

I've made an init script to making stopping/starting and running at boot
a lot easier. Drop this simple script into `/etc/rc.d/headscale`:

	#!/bin/ksh
	#
	# /etc/rc.d/headscale
	
	daemon_user="_headscale"
	daemon="/usr/local/bin/headscale"
	daemon_flags="serve"
	
	. /etc/rc.d/rc.subr
	
	rc_cmd $1

`chmod`, enable and start it as usual:

	# chmod +x /etc/rc.d/headscale
	# rcctl enable headscale
	# rcctl start headscale
	headscale(ok)

## Clients

So here's where you may run into some problems. Depending on the OS your client is going to be running on, it might be a little difficult to get Tailscale to use your custom control server. On Android, this editing the hardcoded Tailscale control server URL, and compiling the client from source.

### OpenBSD client

It's pretty easy to get the Tailscale client on OpenBSD to use your control server. 

	# pkg_add tailscale
	# rcctl enable tailscaled; rcctl start tailscaled
	# tailscale --login-server "https://headscale.example.com:443"
	...

Where `https://headscale.example.com:443` is your control server URL.

### Android client

I didn't bother even attempting to install the android sdk, ndk, and all the other required (garbage) on OpenBSD to compile the Android client. So I booted into Windows, then logged into Ubuntu on WSL, then had to install Go manually (since Ubuntu 20.04 packages are old AF and I can't be bothered to move all the junk I've accumulated in my WSL distro's $HOME). Then i installed the sdkmanager manually, then i installed the ndk through that manually, then I ran `make tailscale-debug.apk` in the android client's repo and viola!

I will edit this post to provide links and more details for this process.  
Quite frankly this was painful, but it isn't supposed to be. Wrangling with old documentation I found online about installing the android sdk set me back a few hours.

In the end it was quite rewarding to install the APK file, open it up and see it all working!

