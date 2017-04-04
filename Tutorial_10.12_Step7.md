# Step 7: Fixes / Enhancements / Alternative Solutions / Bugs

## HDMI Video-Out Fix for iMac7,1 or MBP13,3
Open /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist  
Find the Board-ID which used in your config.plist, default in this tutorial is "Mac-B809C3757DA9BB8D". Differs when using different smbios.  
Replace the attribute Config2 with none  
`sudo kextcache -system-prelinked-kernel && sudo kextcache -system-caches`  
reboot 

## Model Name Error
if you get "Model Name: Apple device" - then you've not booted with the newest cloverx64.efi. Update your EFI Configuration. See [Additional/Setup-Bootmanager.jpg](Additional/Setup-Bootmanager.jpg) how to configure to boot from it 

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
the supplied AppleBacklightInjector contains an id for the display. It is theoretically possible that this id is different on another machine. In this case just follow [this tutorial](Additional/PatchAppleBacklight_v2/readme.md)

## Display ICC Calibration
ICC profile for 4k screen calibrated with Spyder4Pro colorimeter and DisplayCAL is available in Additional/Profiles.   
Every panel is a lil bit different, so don't expect too much precision, but this profile works great for sRGB and AdobeRGB.

## SSDT / DSDT Modifications
You don't have to decompile the DSDT/SSDT files by yourself. The source dsl files are available in ./10.12/Advanced/DSDT-HotPatches/Patches. Use these for modifications.

## NVRAM Emulation / Saving Sound and Brightness settings after reboot
the native nvram installed in the Dell is not usable right now because of the Aptiofix. Clover can emulate this storage. Just install clover normally, but select "Advanced" when asked for the location of the installation. Now select "Install all RC Scripts on the target partition". You can find the installation files for clover in ./Additional/Clover_v2.4k_r4003.pkg - but i suggest downloading the newest from [Sourceforge](https://sourceforge.net/projects/cloverefiboot/)

## Additional Resources / Request help
It's much to read, but this thread include many solutions to the less common problems. Please read every post before asking a question:  
http://www.insanelymac.com/forum/topic/319764-guide-dell-xps-15-9550-sierra-10122-quick-installation/  
also please check if your question is already answered here: https://github.com/wmchris/DellXPS15-9550-OSX/issues?q=is%3Aissue+is%3Aclosed