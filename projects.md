# Projects

Select list of personal projects in alphabetical order.   
Click any of the project names to jump to their sections.   

  * [after](#after)       - Echo string after process death \(C) (OpenBSD).
  * [hidlock](#hidlock)   - Lock screen on HID attach (Shell) (OpenBSD).
  * [nlcc](#nlcc)         - Compile NIST LWC entries into executable \(C).
  * [page](#page)         - Secret storage using age encryption (Go).
  * [sghs](#sghs)         - Shitty Go HTTP Server (Go).
  * [shite](#shite)       - Static site generation scripts in `/bin/sh` (Shell).
  * [stsd](#stsd)         - Secure Time Sync Daemon (Go).
  * [subc](#subc)         - Subcommands package (Go).
  * [wslcheck](#wslcheck) - Package that can test whether it is running on WSL (Go).

:box
## after

[**after**](https://github.com/e-zk/after) is an 
[OpenBSD](https://openbsd.org/)-specific program that echoes a string after a 
process has died.  
In traditional interactve Unix-like shell usage if you wanted to echo 
something after a program is finished running you'd do: 

	$ program; echo "finished!".

But what if you've already started `program` and 
don't want to stop it, but still want to run some other code _after_ it 
finishes? That's what `after` is for: 

	$ after -n program -e "finished!"

You can use `after`'s output to run shell commands. For instance, if you 
wanted to shutdown your machine after your `program` is finished:

	$ after -n program -e "shutdown -p now" | sh

The only reason `after` is OpenBSD-specific is because at the time I mainly
used OpenBSD. 
::

:box
## hidlock

[**hidlock**](https://github.com/e-zk/hidlock) is an OpenBSD-specific 
hotplugd(8) script that locks all X displays when a new Human Interface 
Device is detected by hotplugd(8).

Essentially it aims to protect against HID attacks in which malicious HIDs
are used to inject keystrokes into users machines - with hidlock the display 
is locked as soon as the HID is attached - this way any injected keystrokes
get sent straight to the lockscreen and nowhere near the user's environment.  
See the project's [README](https://github.com/e-zk/hidlock/blob/master/README.md)
for screenshots and a more in-depth explanation.

[**yubilock**](https://github.com/e-zk/yubilock) is another hotplugd(8) script similar to 
hidlock, except it locks the display when a YubiKey device is removed.
::

:box
## nlcc

[**nlcc**](https://github.com/e-zk/nlcc) was written while on semester break 
for University as part of a cryptography research project. For this project 
a small team of us students were tasked with researching an analysing one of 
the contenders for NIST's 
[Lightweight Cryptography Competition](https://csrc.nist.gov/Projects/Lightweight-Cryptography). 

We had to narrow down candidates in order to choose a single algorithm to 
analyse.  
The competition entires' C implementation code had to adhere to a specific 
API/spec. I figured I could use this to create a plug-and-play program
that would allow any one of the entires to be compiled into a CLI executable -
that's what `nlcc` is. It allows the user to specify inputs for the cipher's 
AEAD paramaters through the command-line; it performs both encryption and 
decryption and shows a summary of the algorithm inputs:

	$ ./nlcc -k ./file -m "testing message" -a "adadadadad"
	Key   = ffffffffffffffffffffffffffffffff (128)
	Nonce = 000000000000000000000000 (96)
	AD    = 61646164616461646164 (80)
	PT    = 74657374696e67206d657373616765 ("testing message") (120)
	CT    = 87e649bf2c3e6c83cbb1ee7120c419a1f58b03b0386258
::

:box
## page

A command-line password manager written in Go that uses the 
[age](https://age-encryption.org/) encryption algorithm for storing secrets 
It uses `$EDITOR` to edit entries, supports decrypting+copying secrets to the
clipboard, random string password generation.

I used this as my main password manager for a long time 
(utilising Termux on Android to use it on my phone). Its inspired by many other
CLI password managers including its predecessor, [cpass](https://github.com/e-zk/cpass).

I've switched to Bitwarden for password management these days, but I spent
a lot of time building and "perfecting" [**page**](https://github.com/e-zk/page) 
for my own use.
::

:box
## sghs

[**Shitty Go HTTP Server**](https://github.com/e-zk/sghs) - a super simple Go HTTP fileserver for just serving 
files. Supports TLS too, if you've got the cert files for it.
::

:box
## shite

A collection of [**shell scripts**](https://github.com/e-zk/shite) used to generate this static site.
It uses standard Unix stuff like `find`, `sed`, and uses [lowdown](https://kristaps.bsd.lv/lowdown/) to convert
Markdown into HTML.

Very opinionated, you probably don't want to use it `:P`.
::

:box
## stsd

[**Secure Time Sync Daemon**](https://github.com/e-zk/stsd). A system daemon 
that uses HTTP date headers over TLS (HTTPS) to set system date as opposed to NTP.
Why not NTP? See the [README](https://raw.githubusercontent.com/e-zk/stsd/trunk/README).
::

:box
## subc

A super small, super simple [**subc**](https://github.com/e-zk/subc)ommand package for Go. It wraps the standard 
`flag` package and uses FlagSets to create arbitrary "subcommands" for CLI 
projects. It's used by [`page`](#page).
::

:box
## wlscheck

[**Go package**](https://github.com/e-zk/wslcheck) that tests whether you're running on WSL based on the kernel 
version string. It's used in [`page`](#page) to know whether to use 
Windows' `clip.exe`.
::
