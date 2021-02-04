# OpenBSD notes

Random notes on running [OpenBSD](https://openbsd.org/) (some notes may only be useful for a laptop install). Updated frequently.

## Table of Contents
* [Power/Battery](#Power%2fBattery)
  * [Hibernate on low battery](#Hibernate%20on%20low%20battery)
  * [User power commands](#User%20power%20commands)
* [Multimedia](#Multimedia)
  * [Microphone Setup](#Microphone%20Setup)
* [X](#X)
* [PF](#PF)
  * [Standard preamble](#Standard%20preamble)
  * [Allow NTP](#Allow%20NTP)
  * [VMs](#VMs)
* [Misc](#Misc)
* [Manual pages as beautifully typeset PDFs](#Manual%20pages%20as%20beautifully%20typeset%20PDFs)

## Power/Battery

### Hibernate on low battery

To hibernate at 5% remaining battery add in `/etc/rc.conf.local`:

```bash
apmd_flags=-A -Z 5
```

### User power commands

In `/etc/doas.conf`:

```
permit nopass :staff as root cmd zzz
permit nopass :staff as root cmd ZZZ
permit nopass :staff as root cmd reboot args
permit nopass :staff as root cmd shutdown args -p now
```

## Multimedia

### Microphone setup

I have a fancy microphone that has a headphone passthrough. So it is both USB "speaker" and a USB microphone. Good news, that makes using it with sndio a _bit_ easier.

Change primary sndiod device to the microphone (check dmesg for `audio[0-9]` device id):

```
# rcctl set sndiod flags -f rsnd/1
# rcctl restart sndiod
```

Switch mixer sources:

```
# mixerctl outputs.hp_source=dac-2:3
outputs.hp_source: dac-0:1 -> dac-2:3
```

To switch back, remove the sndiod flag, and change the source back to it's original value (`dac-0:1`).

## X

See [full post](/posts/2021-01-04-xenodm.html) for xenodm themeing.

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
block all 

# antispoofing
antispoof for egress
antispoof for $vm_int
```

### Allow NTP

In rare cases ntp can use tcp apparently...

```
pass quick inet proto { tcp, udp } to port ntp
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

## Misc

### Manual pages as beautifully typeset PDFs

```console
$ MANPAGER=zathura man -T pdf style
```
