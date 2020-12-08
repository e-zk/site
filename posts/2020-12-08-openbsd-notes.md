# OpenBSD notes

Miscellaneous notes on running [OpenBSD](https://openbsd.org/) (some notes may only be useful for a laptop install). Updated frequently.

## Hibernate on low battery

To hibernate at 5% remaining battery add in `/etc/rc.conf.local`:

```bash
apmd_flags=-A -Z 5
```

## Non-root power control

`/etc/doas.conf`:

```
permit nopass :staff as root cmd zzz
permit nopass :staff as root cmd ZZZ
permit nopass :staff as root cmd reboot args
permit nopass :staff as root cmd shutdown args -p now
```

## Manual pages as beautifully typeset PDFs

```console
$ MANPAGER=zathura man -T pdf style
```

## X

Xorg settings, xenodm theming. 

### Run programs on xenodm login screen

`/etc/X11/xenodm/Xsetup_0`:

```bash
# comment out xconsole

xsetroot -solid \#202a2b
```

### Main xenodm login theme

`/etc/X11/xenodm/Xresources`:

```
xlogin*login.translations: #override \
        Ctrl<Key>R: abort-display()\n\
        <Key>F1: set-session-argument(failsafe) finish-field()\n\
        <Key>Left: move-backward-character()\n\
        <Key>Right: move-forward-character()\n\
        <Key>Home: move-to-begining()\n\
        <Key>End: move-to-end()\n\
        Ctrl<Key>KP_Enter: set-session-argument(failsafe) finish-field()\n\
        <Key>KP_Enter: set-session-argument() finish-field()\n\
        Ctrl<Key>Return: set-session-argument(failsafe) finish-field()\n\
        <Key>Return: set-session-argument() finish-field()


xlogin.Login.echoPasswd:       true
xlogin.Login.fail:             Access Denied
xlogin.Login.greeting:
xlogin.Login.namePrompt:       \040\040login\040
xlogin.Login.passwdPrompt:     \040passwd\040

xlogin.Login.height:           200
xlogin.Login.width:            400
xlogin.Login.y:                320
xlogin.Login.frameWidth:       10
xlogin.Login.innerFramesWidth: 0

xlogin.Login.background:        #000000
xlogin.Login.foreground:        #afafaf
xlogin.Login.failColor:         red
xlogin.Login.inpColor:          #1a1f1f
xlogin.Login.promptColor:       #afafaf
xlogin.Login.hiColor:           #000000
xlogin.Login.shdColor:          #000000

! font face
xlogin.Login.face:             Dina-11
xlogin.Login.failFace:         Dina-11
xlogin.Login.promptFace:       Dina-11
```

### Changing location of ~/.xsession (xenodm)

Change the location through these vars in `/etc/X11/xenodm/Xsession`:

```bash
startup=$HOME/.xsession
resources=$HOME/.Xresources
```

May also be wise to load Xresources before `ssh-agent` if `ssh-askpass` is themed:

```bash
# load xresources
xrdb -load $HOME/x/xresources

# where ssh-agent is called below...
```

## PF

Packet Filter (firewall). General stuff to remember:

* last rule 'wins'\*
* `egress` = interface(s) that hold the default route(s)

### Standard preamble

```
# options 
set block-policy drop
set skip on lo

# default deny
block return
block all 

# antispoofing
antispoof for egress
antispoof for $vm_int
```

### VMs

Don't forget to `sysctl net.inet.ip.forwarding=1`!

```
# where:
# vm_int        = vm interface (vether[0-9])
# vm_dns_server = dns server to be used by vms

# allow ssh traffic to vm
pass out on $vm_int proto tcp to $vm_int:network port 22

# vm nat
match out on egress from $vm_int:network to any nat-to (egress)
pass in proto { tcp udp } from $vm_int:network to any port domain \
        rdr-to $vm_dns_server port domain

# allow icmp + web from vms
pass in on $vm_int proto icmp
pass in on $vm_int proto tcp to port { www, https }

# only allow X11 forwarding on the vm interface
pass in on $vm_int proto tcp to port 6000:6010
```


