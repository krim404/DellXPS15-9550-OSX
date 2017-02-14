#!/bin/bash
sudo mv /System/Library/Extensions/AppleHDA.kext /System/Library/Extensions/AppleHDA.kext.old
sudo cp -R AppleHDA.kext /System/Library/Extensions/ 
sudo cp ALCPlugFix /usr/bin
sudo chmod 755 /usr/bin/ALCPlugFix
sudo chown root:wheel /usr/bin/ALCPlugFix
sudo cp hda-verb /usr/bin
sudo chmod 755 /usr/bin/hda-verb
sudo chown root:wheel /usr/bin/hda-verb
sudo cp good.win.ALCPlugFix.plist /Library/LaunchAgents/
sudo chmod 644 /Library/LaunchAgents/good.win.ALCPlugFix.plist
sudo chown root:wheel /Library/LaunchAgents/good.win.ALCPlugFix.plist
sudo launchctl load /Library/LaunchAgents/good.win.ALCPlugFix.plist
sudo rm -Rf /Library/Extensions/aDummyHDA.kext
sudo rm -rf /System/Library/Caches/com.apple.kext.caches/Startup/kernelcache  
sudo rm -rf /System/Library/PrelinkedKernels/prelinkedkernel  
sudo touch /System/Library/Extensions && sudo kextcache -u /

echo "please remove EFI/CLOVER/ACPI/patched/SSDT-ALC298.aml manually and reboot"
exit 0
