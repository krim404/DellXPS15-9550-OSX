## Step 7: Fixes / Enhancements / Alternative Solutions / Bugs

### HDMI Video-Out Fix for iMac7,1 or MBP13,3
Open /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist  
Find the Board-ID which used in your config.plist, default in this tutorial is "Mac-B809C3757DA9BB8D". Differs when using different smbios.  
Replace the attribute Config2 with none  
`sudo kextcache -system-prelinked-kernel && sudo kextcache -system-caches`  
reboot 

### Model Name Error
if you get "Model Name: Apple device" - then you've not booted with the newest cloverx64.efi. Update your EFI Configuration. See `Additional/Setup-Bootmanager.jpg` how to configure to boot from it 

### Alternative Power Management
The whole power management is done by intels speed step technology (HWP), which is enabled in the clover config. If you want to let OSX manage the power management, you'll have to do these steps:  
```
sudo cp ./Post-Install/CLOVER/ACPI/optional/SSDT.aml /EFI/EFI/CLOVER/ACPI/patched/
```
then open the config.plist (/EFI/EFI/CLOVER/config.plist) and change `<key>HWPEnable</key><true/>` to `<key>HWPEnable</key><false/>`.  
This is not compatible with Skylake SMBIOS like MB9,1 or MBP13,1.

### Audio Fix by using VoodooHDA
in case you've audio problems: 
AppleHDA has some problems after Wake-Up. You'll have to plug in a headphone to get your speakers working again. You can use VoodooHDA instead, which breaks the headphone jack most of the time, but makes the rest much more stable.
```
sudo rm -r /Library/Extensions/CodecCommander.kext  
sudo rm /EFI/EFI/CLOVER/ACPI/patched/SSDT-ALC298.aml
```
then remove from your config.plist from the key "KextsToPatch" the elements "AppleHDA#1" to "AppleHDA#7". Install the package: git/Post-Install/AD-Kexts/VoodooHDA-2.8.8.pkg  

### Audio Fix by using patched AppleHDA
alternative to VoodooHDA and with better compatibility, but less stability.  
See [this Tutorial](/10.12/Post-Install/AD-Kexts/AppleHDA_sysCL/readme.md)  
folder: ./10.12/Post-Install/AD-Kexts/AppleHDA_sysCL


### Additional Resources / Request help
It's much to read, but this thread include many solutions to the less common problems. Please read every post before asking a question:  
http://www.insanelymac.com/forum/topic/319764-guide-dell-xps-15-9550-sierra-10122-quick-installation/  
also please check if your question is already answered here: https://github.com/wmchris/DellXPS15-9550-OSX/issues?q=is%3Aissue+is%3Aclosed