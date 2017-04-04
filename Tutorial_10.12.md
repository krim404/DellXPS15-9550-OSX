![Computer Logo](Additional/icon.png "Dell XPS 15")
Before we start:
this installation is based on the chinese tutorial of darkhandz. It includes real time DSDT/SSDT patching from within clover. This is pretty easy to install. But it is NOT suited for people with no or only few knowledge in Hackintosh Systems. If you only know how to copy commands in your shell and you dont know what they're doing, then stop the tutorial and revert to windows or buy a real mac. Even if you get it running: this system is not failsafe and will be broken multiple times in its usage time, where you have to fix it without a tutorial.
English is not my mother-tongue and i'm writing this without proof reading, so please forgive my bad spelling 

If you've questions: please read the whole thread (doesn't matter how long it is) before asking to prevent multiple questions. Additionally do a search in google and this forum.



## Credits:
Based on the Tutorial and files of darkhandz: https://github.com/darkhandz/XPS15-9550-Sierra  
Mixed with much knowledge of the tutorial by @Dagor: http://www.insanelymac.com/forum/topic/319766-dell-xps-9550-detailled-1011-guide/  
Using many kexts and solutions from @RehabMan 
## What's not working:
• Hibernation (works somehow, but high chance to destroy your whole data)  
• SD-Card reader  
• Killer 1535 Wifi (rarely used, need replace)  
• nVidia Graphics card (Intel works)  
• FileVault 2 (full HDD encryption)  
## Requirements:
• one working MAC OS X Enviroment 
• 16GB USB Stick (larger is sometimes not bootable and/or requires advanced partitioning)  
• MacOS Sierra 10.12.2 installation file from the app store (redownload, just in case)  
• Knowledge in PLIST editing  
• USB Harddrive for backup - you'll loose all data on your computer!   
## Step 1: Prepare Installation
Use the existing Mac to download the Sierra installer from the App Store and create a bootable USB stick with CLOVER. You can do this with the App "Pandora's Box" of insanelymac (use google for download link), which is pretty easy to use.  
Optional: check if your SSD can be switched to 4k sector size. This prevents NVMe corruption. See [this Tutorial](4k_sector.md)
  
After you've finished you need to download the Dell XPS 15 specific configurations for clover.  
Link: https://github.com/wmchris/DellXPS15-9550-OSX/archive/master.zip / this repo. Unzip this file. You only need the folder 10.12, you can delete the 10.11. I'll refer to this folder by "git/"  
Now mount the hidden EFI partition of the USB Stick by entering
`diskutil mount EFI` 
Inside the terminal. Mac OS will automaticly mount the EFI partition of the USB stick, but just in case: make sure it really is  
  
Overwrite everything in the CLOVER folder of the partition EFI with the content of git/10.12/CLOVER.  
If your PC has a Core i5 processor, you'll have to modify your config.plist in EFI/EFI/CLOVER/: search for the Key ig-platform-id: 0x191b0000 and replace it with 0x19160000.  
If you could use the 4k sector patch, replace the config.plist with the 4kconfig.plist.  
If you use a hynix device and you didnt do the 4k sector switch, you'll have to add the following patch to your config.plist:
```
<key>Comment</key>
<string>IONVMeFamily Pike R. Alpha Hynix SSD patch</string>
<key>Disabled</key>
<false/>
<key>Find</key>
<data>
9sEQD4UcAQAA
</data>
<key>Name</key>
<string>IONVMeFamily</string>
<key>Replace</key>
<data>9sECD4UcAQAA</data>
```
Go into the EFI Configuration (BIOS) of your Dell XPS 15:  
```
gymnae said: 
In order to boot the Clover from the USB, you should visit your BIOS settings:  
- "VT-d" (virtualization for directed i/o) should be disabled if possible (the config.plist includes dart=0 in case you can't do this)  
- "DEP" (data execution prevention) should be enabled for OS X  
- "secure boot " should be disabled  
- "legacy boot" optional  
- "CSM" (compatibility support module) enabled or disabled (varies)  
- "boot from USB" or "boot from external" enabled`  
  
Note: If you get a "garbled" screen when booting the installer in UEFI mode, enable legacy boot and/or CSM in BIOS (but still boot UEFI). Enabling legacy boot/CSM generally tends to clear that problem.  
In my case I left VT-d and Fastboot as they were. Also, update your 9550 to the latest BIOS.  
Don't forget to set mode to "AHCI" in the sub-menu "SATA Operation" of "System Configuration". It's mandatory.
```

Also disable the SD-Card Reader to reduce the power consumption drastically. Insert the stick on the Dell XPS 15 and boot it up holding the F12 key to get in the boot-menu and start by selecting your USB-Stick (if you've done it correctly it's named "Clover: Install macOS Sierra", otherwise it's just the brandname of your USB-Drive). You should get to the MacOS Installation like on a real mac. If you're asked to log-in with your apple-id: select not now! Reason: see Step 5.
## Step 2: Partition and Installation
INFORMATION: after this step your computer will loose ALL data! So if you haven't created a backup, yet: QUIT NOW!  
  
Dont install macOS yet. Select the Diskutil and delete the old partitions. Create a new HFS partition and name it "OSX". If you want to multiboot with Windows 10, then you'll have to create a second partition, too (also HFS! Dont use FAT or it will not boot! You have to reformat it when installing Windows). Make sure to select GUID as partition sheme.
Close the Diskutil and install OSX normally. You'll have to reboot multiple times, make sure to always boot using the attached USB stick. So dont forget to press F12. After the first reboot you should see a new boot option inside clover, which is highlighted by default. Just press enter. If you only see one, then something went wrong.  

## Step 3: Make it bootable
After a few reboots you should be inside your new macOS enviroment. You can always boot into it using the USB stick. Remove the USB drive after successful bootup. Enter 
`diskutil mount EFI`
in your terminal, which should mount the EFI partition of your local installation.  
install git/Additional/Clover_v2.4k_r4003. Make sure to select "Install Clover in ESP". Also select to install the RC-Scripts. This should install the Clover Boot System. Now copy everything from git/10.12/CLOVER to EFI/CLOVER like you did before by creating the usb stick. (if you had to modify the config.plist in step 1, do it here, too). Your system should be bootable by itself. Reboot and check if your system can boot by itself.  

## Step 4: Post Installation
Because all DSDT/SSDT changes are already in the config.plist, you dont need to recompile your DSDT (albeit i suggest doing it anyway to make your system a lil bit more failsafe, see gymnaes El-Capitan tutorial for more informations). So we can skip this part and go directly to the installation of the required kexts. Open a terminal and goto the GIT folder.
```
sudo cp -r ./Post-Install/LE-Kexts/* /Library/Extensions/  
sudo mv /System/Library/Extensions/AppleACPIPS2Nub.kext /System/Library/Extensions/AppleACPIPS2Nub.bak 2> /dev/null  
sudo mv /System/Library/Extensions/ApplePS2Controller.kext /System/Library/Extensions/ApplePS2Controller.bak 2> /dev/null
sudo ./AD-Kexts/VoodooPS2Daemon/_install.command
``` 
Now you'll have to replace the config.plist. Because you'll install modified kexts you'll HAVE TO replace the config.plist in your installation. Otherwise your PC will not boot anymore.
`diskutil mount EFI`
replace `EFI/CLOVER/config.plist` with `git/Post-Install/CLOVER/config.plist`. Again: if your PC has a Core i5 processor, search the config.plist for the Key ig-platform-id: 0x191b0000 and replace it with 0x19160000.  
If you've a NVM SSD Drive which is incompatible with the 4k fix, you need to install NVMe-Hackr with SSDT Spoofing (enables easier system upgrading from appstore). Dont do this if you use the HDD version of the Dell or you use your M.2 port for something different than a SSD (for ex. a UMTS modem). Use the correct KEXT for you. Hynix SSDs require a different KEXT (HackrNVMeFamilySpoof-10_12_2_HYNIX.kext instad of HackrNVMeFamilySpoof-10_12_2.kext
```
sudo cp ./Post-Install/AD-Kexts/HackrNVMe/SSDT-Hackr.aml /EFI/EFI/CLOVER/ACPI/patched/  
sudo cp -r ./Post-Install/AD-Kexts/HackrNVMe/HackrNVMeFamilySpoof-10_12_2.kext /Library/Extensions/
```
i also suggest moving some of the kext from EFI/CLOVER/kexts/10.12 to /Library/Extensions. It's just more stable.  
Finalize the kext-copy by recreating the kernel cache:
```
sudo rm -rf /System/Library/Caches/com.apple.kext.caches/Startup/kernelcache  
sudo rm -rf /System/Library/PrelinkedKernels/prelinkedkernel  
sudo touch /System/Library/Extensions && sudo kextcache -u /
```
sometimes you'll have to redo the last command if your system shows "Lock acquired".  
OSX 10.12.2 removed the posibility to load unsigned code. You can enable this by entering 
`sudo spctl --master-disable `
If you're using the 4K monitor, you'll have to copy the UHD enabling kexts to your clover directory:
```
sudo cp ./Post-Install/AD-Kexts/UHD-Kexts/* /EFI/EFI/CLOVER/kexts/10.12/
```
To prevent getting in hibernation (which can and will corrupt your data).
`sudo pmset -a hibernatemode 0`  
To get HDMI Audio working:  
Search for your Boarrd-ID in the config.plist and open /S/E/AppleGraphicsControl.kext/contents/plugin/AppleGraphicePolicy.kext/contents/info.plist with a texteditor. Search for your board-id in there and change the value of it from "Config2" to "none".  
  

## Step 5: iServices (AppStore, iMessages etc.)
WARNING! DONT USE YOUR MAIN APPLE ACCOUNT FOR TESTING! It's pretty common that apple BANS your apple-id from iMessage and other services if you've logged in on not well configured hackintoshs!  
If you want to use the iServices, you'll have to do some advanced steps, which are not completly explained in this tutorial. First you need to switch the faked network device already created by step 4 to be on en0. Goto your network settings and remove every network interface.
`sudo rm /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist`
Reboot, go back in the network configuration and add the network interfaces (LAN) before Wifi.  
You also need to modify your SMBIOS in the config.plist of Clover in your EFI partition with valid informations about your "fake" mac. There are multiple tutorials which explain how to do it like "http://www.fitzweekly.com/2016/02/hackintosh-imessage-tutorial.html".   
It's possible you have to call the apple hotline to get your fake serial whitelisted by telling a good story why apple forgot to add your serial number in their system. (aka: dont do it if you dont own a real mac). I personally suggest using real data from an old (broken) macbook.
## Step 6: Upgrading to macOS 10.12.3 or higher / installing security updates
Each upgrade will possibly break your system!  
(Update: after the latest updates in the tutorial the system should be relative update-proof)  

## Step 7: Fixes / Enhancements / Alternatives
### Video - Out Fix for iMac7,1 smbios
Open /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist  
Find the Borad-ID which used in your config.plist, default in this tutorial is "Mac-B809C3757DA9BB8D"  
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

### Audio Fox by using patched AppleHDA
alternative to VoodooHDA and with better compatibility, but less stability.  
See [this Tutorial](/10.12/Post-Install/AD-Kexts/AppleHDA_sysCL/readme.md)  
folder: ./10.12/Post-Install/AD-Kexts/AppleHDA_sysCL

## Afterword
as i said before: this is not a tutorial for absolute beginners, albeit it's much easier then most other tutorials, because most is preconfigured in the supplied config.plist. Some Dells have components included, which are not supported by these preconfigured files. Then i can only suggest using Gymnaes tutorial which explains most of the DSDT patching, config.plist editing and kexts used in detail and use the supplied files here as templates.  
•	Warning: Some people have reported multiple data losses on this machine. I suggest using time-machine whenever possible!  
•	4K Touchscreen only: Multitouch can be achieved with the driver from touch-base.com, but it's not open source - costs > 100 $   
•	Not a bug: if you REALLY want to use the 4K Display natively and disable the Retina Mode (max 1920x1080), google it or see: http://www.everymac.com/systems/apple/macbook_pro/macbook-pro-retina-display-faq/macbook-pro-retina-display-hack-to-run-native-resolution.html 
   

## Tutorial Updates
•	27. March 2017: UHD Kexts added, replaces perl command  
•	23. March 2017: 4k sector tutorial against NVMe corruption added  
•   7. March 2017: Suggestion to disable the SD Card Reader for reduced power consumption  
•	4. February 2017: Dell SMBIOS Truncation workaround added  
•	23. January 2017: Hynix SSD fix added  
•	15. January 2017: updated tutorial regarding power management  
•	31. December 2016: USB-C Hotplug Fix and USB InjectAll Removed  
•	28. December 2016: NVMe SSDT Spoof precreated, FakeID already preset in installation config.plist. VoodooHDA added as alternative to SSDT-ALC298 patch as well as color coding in tutorial  
•	22. December 2016: FakeSMBios added  
## Appendix 1: Accessories
The official Dell adaptor DA200 (http://accessories.euro.dell.com/sna/productdetail.aspx?c=at&l=de&s=dhs&cs=atdhs1&sku=470-abry) works completly on Sierra 10.2.2. You can use the Network, USB, HDMI and VGA. Everything is full hot-pluggable  
a cheap 3rd party noname USB-C -> VGA adaptor didnt work  
you can charge the Dell with a generic USB-C Power Adaptor, but USB-C has only a maximum power of 100W, so it's either charging OR usage, not both. Dont forget you need a special USB-C cable (Power Delivery 3.0) for charging  
