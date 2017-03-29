#!/bin/bash

# set -x

uid=10

ioreg -n AppleBacklightDisplay -arxw0>/tmp/org.rehabman.display.plist
id=`/usr/libexec/PlistBuddy -c "Print :0:DisplayProductID" /tmp/org.rehabman.display.plist`
id=`printf "F%02dT%04x" $uid $id`
sed "s/F99T1234/$id/g" 4x40s_Backlight.plist >/tmp/org.rehabman.merge.plist

if [ -d patched ]; then rm -R patched; fi
mkdir patched

cp -R vanilla/AppleBacklight.kext patched
plist=patched/AppleBacklight.kext/Contents/Info.plist
/usr/libexec/PlistBuddy -c "Copy ':IOKitPersonalities:AppleIntelPanelA:ApplePanels' ':ApplePanelsBackup'" $plist
/usr/libexec/PlistBuddy -c "Delete ':IOKitPersonalities:AppleIntelPanelA:ApplePanels'" $plist
/usr/libexec/PlistBuddy -c "Merge /tmp/org.rehabman.merge.plist ':IOKitPersonalities:AppleIntelPanelA'" $plist
/usr/libexec/PlistBuddy -c "Copy ':ApplePanelsBackup:Default' ':IOKitPersonalities:AppleIntelPanelA:ApplePanels:Default'" $plist
/usr/libexec/PlistBuddy -c "Delete ':ApplePanelsBackup'" $plist

plist=patched/AppleBacklightInjector.kext/Contents/Info.plist
cp -R vanilla/AppleBacklight.kext/ patched/AppleBacklightInjector.kext
#/usr/libexec/PlistBuddy -c "Copy ':IOKitPersonalities:AppleIntelPanelA:ApplePanels' ':ApplePanelsBackup'" $plist
/usr/libexec/PlistBuddy -c "Delete ':IOKitPersonalities:AppleIntelPanelA:ApplePanels'" $plist
/usr/libexec/PlistBuddy -c "Merge /tmp/org.rehabman.merge.plist ':IOKitPersonalities:AppleIntelPanelA'" $plist
#/usr/libexec/PlistBuddy -c "Copy ':ApplePanelsBackup:Default' ':IOKitPersonalities:AppleIntelPanelA:ApplePanels:Default'" $plist
#/usr/libexec/PlistBuddy -c "Delete ':ApplePanelsBackup'" $plist
/usr/libexec/PlistBuddy -c "Delete ':BuildMachineOSBuild'" $plist
/usr/libexec/PlistBuddy -c "Delete ':DTCompiler'" $plist
/usr/libexec/PlistBuddy -c "Delete ':DTPlatformBuild'" $plist
/usr/libexec/PlistBuddy -c "Delete ':DTPlatformVersion'" $plist
/usr/libexec/PlistBuddy -c "Delete ':DTSDKBuild'" $plist
/usr/libexec/PlistBuddy -c "Delete ':DTSDKName'" $plist
/usr/libexec/PlistBuddy -c "Delete ':DTXcode'" $plist
/usr/libexec/PlistBuddy -c "Delete ':DTXcodeBuild'" $plist
/usr/libexec/PlistBuddy -c "Delete ':OSBundleLibraries'" $plist
/usr/libexec/PlistBuddy -c "Set ':CFBundleGetInfoString' '0.9.0, Copyright 2013 RehabMan Inc. All rights reserved.'" $plist
/usr/libexec/PlistBuddy -c "Set ':CFBundleIdentifier' 'org.rehabman.driver.AppleBacklightInjector'" $plist
/usr/libexec/PlistBuddy -c "Set ':CFBundleName' 'AppleBacklightInjector'" $plist
/usr/libexec/PlistBuddy -c "Set ':CFBundleShortVersionString' '0.9.0'" $plist
/usr/libexec/PlistBuddy -c "Set ':CFBundleVersion' '0.9.0'" $plist
/usr/libexec/PlistBuddy -c "Set ':IOKitPersonalities:AppleIntelPanelA:IOProbeScore' 2500" $plist
rm -R patched/AppleBacklightInjector.kext/Contents/_CodeSignature
rm -R patched/AppleBacklightInjector.kext/Contents/MacOS
rm patched/AppleBacklightInjector.kext/Contents/version.plist

echo "Patched AppleBacklight.kext for DisplayID: " $id