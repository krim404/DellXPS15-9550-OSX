## SysCL prepatched AppleHDA
This is an experimental patch for AppleHDA supplied by goodwin_c and syscl, which contains a prepatched AppleHDA kext.  
Of course this will break on an update. You’ll have to replace the AppleHDA.kext every time you upgrade your system.  

Just run the install.sh  
then remove EFI/CLOVER/ACPI/patched/SSDT-ALC298.aml manually  
reboot

the install.sh will also try to fix the HDMI audio/video out bug.  

## BE AWARE
if you used VoodooHDA in the past, you’ll have to delete  
/System/Library/Extensions/VoodooHDA.kext  
/System/Library/Extensions/AppleHDADisabler.kext  