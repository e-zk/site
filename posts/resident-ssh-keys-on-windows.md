# YubiKey resident SSH keys on Windows+WSL

This is a guide that documents how to use YubiKey resident SSH keys on Windows, with passthrough to WSL2 via `npiperelay` and `socat`.

It's important to understand that with this setup, WSL is using the ssh-agent service running on Windows, not WSL. However, because of the magic of Unix pipes+sockets, you shouldn't notice any functional differences.

## Download OpenSSH

As of writing, OpenSSH 8.1p1 (the default on Windows 10), does not support importing resident SSH keys from YubiKeys via `ssh-add` or `ssh-keygen`. So first we need to update OpenSSH for Windows:

1. Download the latest .zip from the [Win32-OpenSSH GitHub releases page](https://github.com/PowerShell/Win32-OpenSSH/releases). (OpenSSH-Win64.zip in my case).
2. Unzip it, and run the `install-sshd.ps1` script as Administrator.

This script will update the appropriate Windows system services (`sshd` and `ssh-agent`) to use the executables in the current directory instead of the default ones. The script will not, however install the the executables into your PATH (of which `ssh-add` and `ssh-keygen` we'll need later on) so remember where you've unzipped it.

Next restart the `ssh-agent` Windows service:

1. Open `services.msc` from Run (`Win+R`).
2. Find "OpenSSH Authentication Agent", right click and select "Restart".

## Configuring WSL2

1. Install `socat` using your package manager (e.g. `sudo apt install socat`).
2. Download the latest npiperelay from the [GitHub releases page](https://github.com/jstarks/npiperelay/releases). Unzip it, and copy npiperelay.exe to somewhere in your WSL's `$PATH` (`~/bin/npiperelay.exe` in my case).
3. In your `~/.profile`, or `~/.bashrc` shell startup script add the following (adapted from the [`wsl-ssh-agent` README](https://github.com/rupor-github/wsl-ssh-agent)):

		export NPIPE_CMD=$(command -v npiperelay.exe)
		export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
		
		# setup socat
		ss -a | grep -q $SSH_AUTH_SOCK
		if [ "$?" -ne "0" ]; then
			rm -f $SSH_AUTH_SOCK
			( setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"$NPIPE_CMD -ei -s //./pipe/openssh-ssh-agent",nofork & ) >/dev/null 2>&1
		fi
		
		# add your ssh private key paths here ...
		ssh-add ~/.ssh/id_ed25519 ~/.ssh/id_rsa

## Importing resident SSH keys

Importing resident ssh private keys from the YubiKey via `ssh-keygen -K` isn't supported on the default version of OpenSSH installed on Windows 10. However, we can make use of the updated binaries we downloaded previously, which do support importing resident ssh keys:

1. Open a privileged **Administrator** PowerShell window. It must be a privileged PowerShell window, otherwise it will fail with an "invalid format" error.
2. `cd` to the directory the previously downloaded OpenSSH binaries reside (the path I told you to keep a not of).
3. Run `.\ssh-keygen -K`, and follow the prompts:

![screencap of PowerShell window showing the steps to import a resident ssh key](/static/img/import-resident-key.png)

There is another method that requires a second device running anything that isn't Windows (Linux, *BSD, etc). I did this way before realising I could use the updated `ssh-keygen` binary:

1. Import the resident keys to a file; `ssh-keygen -K -f ./id_ed25519_sk`, (make sure to set a password).
2. Either copy the resulting file to a USB drive, or upload it somewhere private (this is, after all, your *private* key).
3. Copy/download the file onto your Windows machine, and add it to the authentication agent via `ssh-add c:\path\to\file`.

## Adding keys to the agent

Adding keys to the agent is fairly simple, whether in WSL or Windows. Just use the `ssh-add` command. 

In WSL2:

	$ ssh-add /path/to/file

In Windows (PowerShell):

	PS C:\Windows\system32> ssh-add C:\path\to\file

### Automating

If like me you have named your SSH keys in a non-standard way, or for some other reason ssh-agent won't load your keys on startup, we can write a simple PowerShell one-liner that runs at login:

```
C:\Users\zzz\Documents\bin\OpenSSH-Win64\ssh-add.exe "$env:USERPROFILE\.ssh\id_yubikey" "$env:USERPROFILE\.ssh\id_something_nonstandard"
```

You will need to replace `C:\Users\zzz\Documents\bin\OpenSSH-Win64\` with the path to where you unzipped Win32-OpenSSH previously (hope you didn't forget!).

Save this script as `ssh-keys.ps1` in: `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp`, and it should run at startup, prompting you for a password in a PowerShell window if your keys are password protected.

Similarly, for adding the private keys in WSL2 you can add a `ssh-add /path/to/key1 /path/to/key1` line to your shell rc.

