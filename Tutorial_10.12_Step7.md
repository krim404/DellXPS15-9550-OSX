# Step 7: Fixes / Enhancements / Alternative Solutions / Bugs

## HDMI/VGA Video-Out Fix for iMac7,1 or MBP13,3
Open /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist  
Find the Board-ID which used in your config.plist, default in this tutorial is "Mac-B809C3757DA9BB8D". Differs when using different smbios.  
Replace the attribute Config2 with none  
`sudo kextcache -system-prelinked-kernel && sudo kextcache -system-caches`  
reboot 

## OSX doesn't boot anymore after Firmware upgrade to 1.2.25 or higher
If you have an old installation and recently upgraded your firmware: 1.2.25 and newer firmwares (BIOS) don't work with OSXAPTIO Version 1. This needs to be replaced with OSXAPTIOv2. Replace the EFI/CLOVER/drivers64UEFI with the content from this repository and add slide=168 to the boot arguments

## Error: couldn't allocate runtime area / unable to start installer / unable to boot at all
Since OSXAptioV2 is a lil bit picky with memory maps, you'll have to change your slide= command (see question above) to a suitable number. See [this Tutorial](/Additional/slide_calc.md) for more informations. It is still possible you cant get it to boot because no memory section is big enough. This is happening on some machines especially on installation. Try to DOWNGRADE your BIOS (See [this Tutorial](/Additional/bios_upgrade.md)) with the files from the branch
```
git clone https://github.com/wmchris/DellXPS15-9550-OSX -b 10.12-BIOS1.2.21
```
(the 1.2.21 BIOS version is inside this branch in Additional/BIOS). Then install OSX normally, upgrade BIOS and recalculate your slide.

## Error: same as above, but additionally mentiones "unable to load kernel cache"
this normally only occurs on installation with firmware 1.2.25. If you have this message as well as the couldn't allocate runtime area, then there is a high posibility you can boot the installation with `OsxAptioFix2Drv-free2000.efi` instead of `OsxAptioFix2Drv-64.efi`. You can find the free2000 version in ./10.12/CLOVER/drivers64UEFI/Other. Replace them and install normally. Free2000 is not very stable and sometimes crash on start, so switch back to the normal version after installation. Sometimes you still need the slide parameter from above, sometimes you dont.

## clover doesnt boot OR Model Name Error 
if you get "Model Name: Apple device" in "About this mac" or your mac cant boot without the USB stick - then you're not loading the cloverx64.efi from your EFI. Simply update your EFI configuration by adding it to the boot order by hand. See [Additional/Setup-Bootmanager.jpg](Additional/Setup-Bootmanager.jpg) how to configure to boot from it 

## Alternative Power Management
The whole power management is done by intels speed step technology (HWP), which is enabled in the clover config. If you want to let OSX manage the power management, you'll have to do these steps:  
```
sudo cp ./10.12/Post-Install/CLOVER/ACPI/optional/SSDT.aml /Volumes/EFI/EFI/CLOVER/ACPI/patched/
```
then open your installed config.plist from your EFI partition (EFI/CLOVER/config.plist) and change `<key>HWPEnable</key><true/>` to `<key>HWPEnable</key><false/>`.  
This is not compatible with Skylake SMBIOS like MB9,1 or MBP13,1.

## Audio Fix by using VoodooHDA
in case you've audio problems: 
AppleHDA has some problems after Wake-Up. You'll have to plug in a headphone to get your speakers working again. You can use VoodooHDA instead, which breaks the headphone jack most of the time, but makes the rest much more stable.
```
sudo rm -r /Library/Extensions/CodecCommander.kext  
sudo rm /EFI/EFI/CLOVER/ACPI/patched/SSDT-ALC298.aml
```
then remove in your config.plist (EFI/CLOVER/config.plist) from the key "KextsToPatch" the elements "AppleHDA#1" to "AppleHDA#7". Then install the package: ./10.12/Post-Install/AD-Kexts/VoodooHDA-2.8.8.pkg  

## Audio Fix by using patched AppleHDA
alternative to VoodooHDA and with better compatibility, but less stability.  
See [this Tutorial](/10.12/Post-Install/AD-Kexts/AppleHDA_sysCL/readme.md)  
folder: ./10.12/Post-Install/AD-Kexts/AppleHDA_sysCL

## Display Backlight Control not working
the supplied AppleBacklightInjector contains an id for the display. It is possible that this id is different on your machine (especially if you use the non touch display). In this case just follow [this tutorial](Additional/PatchAppleBacklight_v2/readme.md)

## Display ICC Calibration
ICC profile for 4k screen calibrated with Spyder4Pro colorimeter and DisplayCAL is available in Additional/Profiles.   
Every panel is a lil bit different, so don't expect too much precision, but this profile works great for sRGB and AdobeRGB.

## SSDT / DSDT Modifications
You don't have to decompile the DSDT/SSDT files by yourself. The source dsl files are available in ./10.12/Advanced/DSDT-HotPatches/Patches. Use these for modifications.

## NVRAM Emulation / Saving Sound and Brightness settings after reboot
the native nvram installed in the Dell is not usable right now because of the Aptiofix. Clover can emulate this storage. Just install clover normally, but select "Advanced" when asked for the location of the installation. Now select "Install all RC Scripts on the target partition". You can find the installation files for clover in ./Additional/Clover_v2.4k_r4003.pkg - but i suggest downloading the newest from [Sourceforge](https://sourceforge.net/projects/cloverefiboot/)

## Some Multitouch Gestures don't work
Most multitouch gestures are hardcoded in the VoodooPS2 driver and result in keyboard commands. The options in the Control Panel->Touchpad are mostly useless.  
The currently enabled multitouch commands are:  
* swipe 3 fingers left/right => Mapped to CMD + LEFT ARROW / RIGHT ARROW (defaults previous and next page)
* swipe 2 fingers from right side in => Mapped to CTRL+CMD+0
* swipe 2 fingers from left side in => Mapped to CTRL+CMD+9
* swipe 3 fingers up => CTRL + UP ARROW (defaults mission control)
* swipe 3 fingers down => CTRL + CMD + DOWN ARROW 
* swipe 4 fingers up => F11 (defaults show desktop)
* swipe 4 fingers down => CMD + M (defaults minimize)
* swipe 4 fingers left/right => CTRL+RIGHT ARROW / LEFT ARROW (inverse)
    
you can modify which commands should be triggered by each gesture from controlpanel -> Keyboard -> Shortcuts. For example set "Notification Bar" to CTRL+CMD+0 to show the bar on swiping left in

## Activity Monitor App crashes on opening
This is a known issue, which is triggered from the ACPI Battery Driver after clicking on the Energy tab once.  
There is no real fix, only a workaround. If the Activity Monitor crashes, enter 
```
rm ~/Library/Preferences/com.apple.ActivityMonitor.plist
open /Applications/Utilities/Activity\ Monitor.app && sleep 1 && osascript -e 'quit app "Activity Monitor"' && chflags uchg ~/Library/Preferences/com.apple.ActivityMonitor.plist
```
make sure there is no blank after ".plist", otherwise chflags will give a file not found error.  
the activity monitor will continue to crash on clicking on the Energy Tab, but after closing and manually reopening it will not crash anymore on startup  

## Sleep results in reboot
This is only in case sleep worked in the past. If you have sleep issues from the beginning and you strictly followed this tutorial (check at least twice!), you need additional assistance (easiest way is asking in a forum).  
  
Sometimes (especially on a dual boot environment after booting in the other OS) a normal sleep results in a full (and dirty) reboot. For me the old behaviour can be obtained by issuing this command: `sudo pmset -a hibernatemode 0 && sudo reboot`, albeit already being in hibernatemode 0. The reboot is mandatory, otherwise it doesn't work. Some people reported this fixes their problems, while other still had sleep issues. Just give it a shot.

## Additional Resources / Request help
It's much to read, but this thread include many solutions to the less common problems. Please read every post before asking a question:  
http://www.insanelymac.com/forum/topic/319764-guide-dell-xps-15-9550-sierra-10122-quick-installation/  
also please check if your question is already answered here: https://github.com/wmchris/DellXPS15-9550-OSX/issues?q=is%3Aissue+is%3Aclosed
