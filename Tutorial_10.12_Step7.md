# Step 7: Fixes / Enhancements / Alternative Solutions / Bugs

## HDMI/VGA Video-Out Fix for iMac7,1 or MBP13,3
Open /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist  
Find the Board-ID which used in your config.plist, default in this tutorial is "Mac-B809C3757DA9BB8D". Differs when using different smbios.  
Replace the attribute Config2 with none  
`sudo kextcache -system-prelinked-kernel && sudo kextcache -system-caches`  
reboot 

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
```
then open the activity monitor and immediately close it to recreate the plist. enter the following command to lock the file to prevent it from saving the last used tab:  
```
chflags uchg ~/Library/Preferences/com.apple.ActivityMonitor.plist
```
the activity monitor will continue to crash on clicking on the Energy Tab, but after closing and manually reopening it will not crash anymore on startup  

## Sleep results in reboot
This is only in case sleep worked in the past. If you have sleep issues from the beginning and you strictly followed this tutorial (check at least twice!), you need additional assistance (easiest way is asking in a forum).  
  
Sometimes (especially on a dual boot environment after booting in the other OS) a normal sleep results in a full (and dirty) reboot. For me the old behaviour can be obtained by issuing this command: `sudo pmset -a hibernatemode 0 && sudo reboot`, albeit already being in hibernatemode 0. The reboot is mandatory, otherwise it doesn't work. Some people reported this fixes their problems, while other still had sleep issues. Just give it a shot.

## Additional Resources / Request help
It's much to read, but this thread include many solutions to the less common problems. Please read every post before asking a question:  
http://www.insanelymac.com/forum/topic/319764-guide-dell-xps-15-9550-sierra-10122-quick-installation/  
also please check if your question is already answered here: https://github.com/wmchris/DellXPS15-9550-OSX/issues?q=is%3Aissue+is%3Aclosed
