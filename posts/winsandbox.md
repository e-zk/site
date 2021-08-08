# Windows Sandbox
If you['re forced to] use Windows this might be useful for compartmentalisation.  

Windows Sandbox is a Windows 10 feature that enables the use of temporary Virtual Machines. These can be used as ephemeral sandboxes for applications.

## Enabling

Windows Sandbox isn't enabled by default. To enable it follow these steps:

1. Open "Control Panel" and click the upside down caret next to the back/forward buttons
2. Click "All Control Panel Items"
3. Navigate to "Programs and Features"
4. On the left click "Turn Windows features on or off"
5. Scroll down and tick the box next to "Windows Sandbox" if it isn't already ticked

From the start menu search for "Windows Sandbox". Hit enter and a fresh Sandbox window will appear.

## Configuring

Once the sandbox window is closed all data is erased. Next time you open Windows Sandbox a fresh new VM is created.  
This can make it annoying if you wish to sandbox a single program, but have to install it every time you start a new sandbox.

To make it easier for these cases you can pre-configure sandbox instances via `.wsb` files. With this file you can configure memory, networking, audio/video passthrough, among other things. See the Microsoft official documentation for Windows Sandbox configuration[^wsb]. It also supports running a script at startup, and mapping network devices and local shares.

I highly suggest reading through the documentation for the `.wsb` file format. There are some good examples and interesting features.

### Example: Zoom

Zoom is a very popular group call/video conference software (I won't bore you with the details I'm sure you have _some_ idea what Zoom is by now). However, Zoom has had numerous security and privacy issues. If you're paranoid like me you may feel uneasy just seeing it's icon in the start menu - knowing you have it installed on the same machine along with all your other precious digital data. I digress, here is a configuration file for my Zoom sandbox:

```xml
<Configuration>
    <MappedFolders>
        <MappedFolder>
            <HostFolder>C:\Sandbox\Installers</HostFolder>
            <SandboxFolder>C:\Installers</SandboxFolder>
            <ReadOnly>true</ReadOnly>
        </MappedFolder>
    </MappedFolders>
    <AudioInput>Enable</AudioInput>
    <VideoInput>Enable</VideoInput>
    <VGpu>Enable</VGpu>
    <MemoryInMB>12288</MemoryInMB>
    <LogonCommand>
        <Command>C:\Installers\ZoomInstaller.exe</Command>
    </LogonCommand>
</Configuration>
```

It maps the local `C:\Sandbox\Installers` directory (where I store `ZoomInstaller.exe`) to `C:\Installers` in the VM itself. Enables audio (mic) and video (webcam) passthrough. I allocate 12Gb to the VM - should be more than enough on my laptop with 16Gb of RAM. It then runs the Zoom installer on startup.

The verdict? It works fairly well. Recently however webcam passthrough has stopped working, possibly due to a driver issue. (Installing drivers requires the machine to reboot - but you can't reboot a sandbox without deleting everything).

I make use of a couple of these `.wsb` files for different programs I'd rather install on an ephemeral virtual machine than my main OS.

[^wsb]: https://docs.microsoft.com/en-us/windows/security/threat-protection/windows-sandbox/windows-sandbox-configure-using-wsb-file

