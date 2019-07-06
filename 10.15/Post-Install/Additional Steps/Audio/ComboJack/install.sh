#!/bin/bash
echo "This installer requires admin rights. Also make sure you don’t have Time Machine running or any usb stick inserted!"
echo "Do you want to continue?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) break;;
        No ) exit;;
    esac
done
 
diskutil mount EFI 
echo "Step 1: removing old content. 'Not found' errors are normal in this step" 
sudo rm /usr/bin/ALCPlugFix
sudo rm /Library/LaunchAgents/good.win.ALCPlugFix.plist
sudo rm -r /Library/Extensions/CodecCommander.kext

echo "Step 2: Adding files to your Library and EFI"
sudo cp -R VerbStub.kext /Library/Extensions/

echo "Step 3: Updating Kext Caches"
sudo rm -rf /System/Library/Caches/com.apple.kext.caches/Startup/kernelcache  
sudo rm -rf /System/Library/PrelinkedKernels/prelinkedkernel  
sudo touch /System/Library/Extensions && sudo kextcache -u /

echo "Step 4: Installing local configuration"
sudo cp ComboJack /usr/bin
sudo chmod 755 /usr/bin/ComboJack
sudo chown root:wheel /usr/bin/ComboJack
sudo cp hda-verb /usr/bin
sudo chmod 755 /usr/bin/hda-verb
sudo chown root:wheel /usr/bin/hda-verb
sudo cp com.XPS.ComboJack.plist /Library/LaunchAgents/
sudo chmod 644 /Library/LaunchAgents/com.XPS.ComboJack.plist
sudo chown root:wheel /Library/LaunchAgents/com.XPS.ComboJack.plist
sudo launchctl load /Library/LaunchAgents/com.XPS.ComboJack.plist
sudo cp Headphone.icns /usr/local/share/ComboJack/
sudo chmod 644 /usr/local/share/ComboJack/Headphone.icns
sudo cp l10n.json /usr/local/share/ComboJack/
sudo chmod 644 /usr/local/share/ComboJack/l10n.json
echo
echo "Please reboot! Also, it may be a good idea to turn off \"Use"
echo "ambient noise reduction\" when using an input method other than"
echo "the internal mic (meaning line-in, headset mic). As always: YMMV."
echo
echo "You can check to see if the watcher is working in the IORegistry:"
echo "there should be a device named \"VerbStubUserClient\" attached to"
echo "\"com_XPS_SetVerb\" somewhere within the \"HDEF\" entry's hierarchy."
echo
echo "Enjoy!"
echo
exit 
