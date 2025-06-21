# Soft Uptime

```powershell
PS> Get-Uptime

Days              : 0
Hours             : 20
Minutes           : 27
Seconds           : 48
Milliseconds      : 0
Ticks             : 736680000000
TotalDays         : 0.852638888888889
TotalHours        : 20.4633333333333
TotalMinutes      : 1227.8
TotalSeconds      : 73668
TotalMilliseconds : 73668000
```

Huh? 20 hours? I just powered this thing on a few minutes ago!

Turns out Windows has this "fast startup" thing. As far as I can tell, when
you go Start > Shutdown it closes all running processes, logs out, and then
hibernates the system so that it can startup faster next time. That
basically means to Windows it's not been "really" shutdown so the uptime isn't
 reset.

So how do you tell how long your machine has been "on" (like, since you pressed
the power button)?

Well, there's one pretty ubiquitous process on Windows that's generally one of
the first user-facing applications: Explorer.
So to get a better idea of when I powered on my machine today, I wrote a
function to check the explorer.exe process start time: `Get-SoftUptime`.

```powershell
function Get-SoftUptime {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $Since
    )

    $started = [datetime](Get-Process | Where-Object { $_.Name -eq "explorer" } | Select-Object -ExpandPropety StartTime)

    if ($PSBoundParameters.ContainsKey("Since)) {
        return $started
    } else {
        return (Get-Date) - $started
    }
}
```

The `-Since` option mirrors the behaviour of `Get-Uptime -Since`: it'll just
output the start time of explorer.

This gives me a better idea of when I started up my laptop. The output is the
same format (a `[datetime]`) as `Get-Uptime` too if that is helpful. 

I've used explorer because I reckon it's one of the first processes to start,
it gives me a good enough idea. I don't need it to be very accurate.