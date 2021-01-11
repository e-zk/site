# `usbkill` the OpenBSD way

[`usbkill`](https://github.com/hephaest0s/usbkill) is a kill-switch that shuts down your computer on any USB change. It does this by watching the output of `lsusb` and when there is a change it runs `shutdown -h now`.

Simple, right? One thing to note is that `lsusb` is not included in OpenBSD's base packages, but [`hotplugd(8)`](https://man.openbsd.org/hotplugd) is.

## hotplugd

So what is `hotplugd`, and how can it be useful? The [man page](https://man.openbsd.org/hotplugd) does a good job of explaining it. Simply put: when any device is attached to or detached from your machine `hotplugd` will execute a script.

To see how simple it is to write a hotplug script we can start by simply logging device attach events. First, start by enabling and starting `hotplugd` (as root):

	# rcctl enable hotplugd
	# rcctl start hotplugd
	hotplugd(ok)

Next we will write the script that is executed on a device attach event:

	# mkdir -p /etc/hotplug
	# $EDITOR /etc/hotplug/attach

In this file we will log the device class and name:

	#!/bin/sh
	
	DEVCLASS=$1
	DEVNAME=$2
	
	# log attach event
	logger -t hotplug "$DEVCLASS:$DEVNAME attached"

To see this in action in another terminal type

	$ tail -f /var/log/messages

Then connect a USB device to your machine and you should see messages tagged 'hotplug'. This is what I get when I plug in my Logitech USB adapter for my wireless mouse (which I usually don't use):

	Jan 11 11:48:32 x1 hotplug: 0:uhid3 attached
	Jan 11 11:48:32 x1 hotplug: 5:wsmouse2 attached
	Jan 11 11:48:32 x1 hotplug: 0:ums0 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhid1 attached
	Jan 11 11:48:32 x1 hotplug: 5:wskbd1 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhid0 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhid4 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhid2 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhidev1 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhidev2 attached
	Jan 11 11:48:32 x1 hotplug: 0:ukbd0 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhidev0 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhid5 attached
	Jan 11 11:48:32 x1 hotplug: 0:uhid6 attached

Site note: What is happening here? Why have so many events popped up after inserting one USB device? My theory is that because it's a [Unifying Receiver](https://www.logitech.com/product/unifying-receiver-usb), it allows more than one Logitech HID to be connected to a single receiver, so it must register a bunch of HIDs to the kernel.

## The 'kill' part

Now that we've seen how `hotplugd` works, we can work on the _kill_ part of `usbkill`.  
We want to shutdown the machine on a device attach or detach event, but we also want to be able to arm and disarm the _kill_ part, since I might need to plug something in once in a while. Make the `/etc/hotplug/attach` script as so:

	#!/bin/sh
	
	arm_file=/tmp/arm_usbkill
	 
	DEVCLASS="$1"
	DEVNAME="$2"
	
	logger -t "${0##*/}" "${DEVCLASS}:${DEVNAME} attached"
	
	if [ -f "$arm_file" ]; then
	        shutdown -p now
	else
	        logger -t "${0##*/}" "unarmed - aborted shutdown"
	fi

If the `/tmp/arm_usbkill` file exists then the machine will shutdown, if it doesn't exist it will just add a log entry to syslog.

`hotplug` also supports running a different script, `/etc/hotplug/detach` on detach events. Since both scripts are exactly the same I've symlinked the attach script to the location of the detach script.

	# ln -s /etc/hotplug/attach /etc/hotplug/detach

The `${0##*/}` logger tag gets substituted to the filename of the script being executed (in this case it is either `attach` or `detach`).

One thing to note is that this setup will execute the shutdown command on _any_ device change event. This includes USBs but also includes network devices, disk drives, and serial line interfaces[^1]. If that is a problem, you can implement a device class-based whitelist by checking `$DEVCLASS`:

	#!/bin/sh
	
	# class whitelist (space-separated)
	class_whitelist="0 2 3 5"
	
	# arm file
	arm_file=/tmp/arm_usbkill
	
	DEVCLASS="$1"
	DEVNAME="$2"
	
	whitelisted() {
		for class in $class_whitelist; do
			if [ "$class" = "$1" ]; then
				return 0
			fi
		done
		return 1
	}
	
	logger -t "${0##*/}" "${DEVCLASS}:${DEVNAME} attached"
	
	if [ -f "$arm_file" ]; then
		if whitelisted "$DEVCLASS"; then
			logger -t "${0##*/}" "whitelisted - aborted shutdown"
			exit 0
		fi
		shutdown -p now
	else
		logger -t "${0##*/}" "unarmed - aborted shutdown"
	fi


But this is not really useful to me since I use a laptop and I'm not attaching and detaching network devices or disk drives.

One disadvantage of this setup is the inability to whitelist devices based on their USB IDs like you can with `usbkill`. This could be acheived through a much more complicated script using `usbdevs` to get USB IDs, but as of yet I have no need for that.

## Arming and disarming

To arm and disarm this script all you have to do is create or remove the `$arm_file` respectively. Here are some shell functions to add to your shell rc to make it easier:

	# arm/disarm usbkill
	arm() {
	        touch /tmp/arm_usbkill && printf 'armed\\n' || printf 'error arming\\n'
	}
	disarm() {
	        rm -f /tmp/arm_usbkill && printf 'disarmed\\n' || printf 'error disarming\\n'
	}

The script can be armed or disarmed by any regular user which may or may not be preferable to you (and isn't the case for `usbkill`, which requires root to run).  
Originally I had added the `uchg` flag to the file to lock it. But this proved to be counterproductive since it wasn't cleared from `/tmp` on reboot and when `hotplugd` would first start up, it would immediately shutdown the machine again. That was fun to fix (not).

## Why?

So why do all this? Why not just `pkg_add usbutils`, download + run `usbkill` and be done?  
Well for starters that isn't as fun. The main reason is that all this works in a default OpenBSD install - no additional packages needed. Why install a program to solve a problem when the default tools and services can solve the problem just as (if not more) elegantly?

## SEE ALSO

* OpenBSD `hotplug(4)` pseudo-device man page: https://man.openbsd.org/hotplug .
* OpenBSD includes the `usbdevs(8)` tool in base that lists connected USB devices and their IDs: https://man.openbsd.org/usbdevs [^2].
* OpenWRT has it's own similarly named hotplug.d service: https://openwrt.org/docs/guide-user/base-system/hotplug. But it's slightly different to OpenBSD's.
* A couple of years ago I wrote [a hotplug script](https://github.com/e-zk/hidlock) that instead runs [`xlock(1)`](https://man.openbsd.org/xlock) on all running X displays after a HID is attached. In theory this would to thwart HID/badusb attacks, while not being as aggressive as shutting down your machine. Might be worth looking into if you like the sound of that.

[^1]: As per the [`hotplugd(8)` man page](https://man.openbsd.org/hotplugd)
[^2]: In the future I might write a script to act more similarly to `usbkill`, using `usbdevs` to poll for device changes instead of `lsusb`.
