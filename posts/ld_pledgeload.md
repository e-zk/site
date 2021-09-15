# LD_PRELOAD and pledge

After reading about how to implement/call OpenBSD's [pledge(2)](https://man.openbsd.org/pledge) and [unveil(2)](https://man.openbsd.org/unveil) system calls from Python [^py], I had a couple of epiphanies:

1. It shouldn't be too hard to write a wrapper program that calls pledge(2) with user-specified promises, then launches a child process (which is then bound by those promises).  
  I've had this idea for a good while and even attempted writing it before with no success - but after a super long break I've come up with a really simple ~20 line program that does just that, [pledgeme](https://github.com/e-zk/pledgeme).  
2. pledge(2) and unveil(2) system calls can just be noop'd with LD_PRELOAD.

The second epiphany is what this post is about. I should mention this doesn't "defeat" or "break" pledge/unveil - well it does, but you can break literally anything with LD_PRELOAD. And if you're on a machine where you're able to change evironment variables, and run arbitrary programs you've already pwned the machine.   
I suppose this might be useful for CTFs or something like that, or if pledge/unveil is annoying you and you just want it to go away when running some program.

## Crafting a shared object

LD_PRELOAD works by loading a shared object file that can essentially re-define whatever C function or syscall you like before running the actual program.

For this example I'll focus on pledge(2), only because that's what I first tried this out on.  
To craft our LD_PRELOAD shared object first we have to look up the functions signature of pledge(2) in the [man page](https://man.openbsd.org/pledge) and plop it into a .c file:

```c
#include <unistd.h>

int
pledge(const char *promises, const char *execpromises)

```

Next, all we want to do is make sure it does absolutely nothing and returns success every time it's called:

```c
#include <unistd.h> 

int 
pledge(const char *promises, const char *execpromises) {
	// noop
	return 0;
}

```

Compile it into a `.so`:

```console
$ cc -shared -fPIC -o override.so pledge_override.c
```

Now, with this shared object file, you can run anything you want, ignoring it's pledge(2) promises:

```console
$ LD_PRELOAD=./override.so <program>
```

