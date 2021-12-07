# Breaking promises with LD_PRELOAD

In this post I show how to simply [noop](https://wikipedia.org/wiki/NOP_(code)) calls to OpenBSD's [pledge(1)](https://man.openbsd.org/pledge) using LD_PRELOAD.

I only focus on pledge(2), only because that's what I first tried this out on.
But this will also work for [unveil(2)](https://man.openbsd.org/unveil), and any syscall you want for that matter.

Before we get into it, this doesn't actually make pledge(2) completely useless, nor is it an oversight by the developers of OpenBSD - LD_PRELOAD can be used to break any and every system call. I just thought it was a neat trick that might be useful for CTFs or something. In regard to the title, I just couldn't pass on the fantastic opportunity for some word play+clickbait.

## Crafting a shared object

LD_PRELOAD works by loading a shared object file that can essentially re-define whatever C function or syscall you like before running the actual program.

To craft our shared object to use with LD_PRELOAD first we have to look up the function signature of pledge(2) in the [man page](https://man.openbsd.org/pledge) and plop it into a .c file:

```c
#include <unistd.h>

int
pledge(const char *promises, const char *execpromises)

```

Next, we want to make sure when called pledge(2) does absolutely nothing and returns success every time it's called. Alternatively, you could add additional [promises](https://man.openbsd.org/pledge), or remove specific promises, but I think its more jarring to make it do absolutely nothing.

```c
// pledge_override.c
#include <unistd.h> 

int 
pledge(const char *promises, const char *execpromises) {
	// noop
	return 0;
}
```

Compile it into a shared object `override.so`:

```console
$ cc -shared -fPIC -o override.so pledge_override.c
```

Now, with this shared object file, you can run anything you want ignoring it's pledge(2) promises:

```console
$ LD_PRELOAD=$PWD/override.so <program>
```

## Testing it out

Here we have an example use of pledge(2) (yes, I should be checking return values).

```c
// test.c
#include <stdio.h>
#include <unistd.h>

int
main(void) {
	// promise to only use stdio
	pledge("stdio", NULL);
	printf("Hello! I will abort now :3\n");

	// revoke all promises
	pledge("", NULL);

	// should abort here
	printf("You should not be seeing this :O\n");
	return 0;
}
```

When run normally the program should abort at the second call to printf(3) since after the
first one we've revoked the privilege to call `stdio` functions.

```console
$ ./a.out
Hello! I will abort now :3
Abort trap (core dumped)
```

Then, when we add our specially crafted `override.so` to the equation:

```console
$ LD_PRELOAD=$PWD/override.so ./a.out
Hello! I will abort now :3
You should not be seeing this :O
```

## When this won't work

Using LD_PRELOAD like this to get around pledge doesn't work when:

1. You statically link your binary
   - If you statically link your binary, LD_PRELOAD does not have any effect.
   - To test this out, compile the above example program with `-static`, then try and do the LD_PRELOAD trick again. It'll always abort at the correct printf(3) call.
2. SUID / SGID
   - SUID or SGID binaries aren't affected by LD_PRELOAD according to the OpenBSD [man page](https://man.openbsd.org/ld.so#LD_PRELOAD).  
   The Linux [man page](https://linux.die.net/man/8/ld.so) is less clear about this, but I assume its the same.
   - Simply put, your doas(1) and sudo(1) are safe.

