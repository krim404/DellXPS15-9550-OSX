![Computer Logo](Additional/icon.png "Dell XPS 15")
Before we start:
This installation includes real time DSDT/SSDT patching from within clover. This is pretty easy to install, but it is NOT suited for people with no or only limited knowledge of Hackintosh Systems. If you only know how to copy/paste commands in your shell and you dont know what they're doing, then stop the tutorial and revert to Windows or buy a real Mac. Even if you get it running, this system is not failsafe and will likely be broken multiple times in its usage time, it is likely you will encounter problems in future which will need to be fixed without a step by step tutorial.
English is not my mother-tongue and I'm writing this without proof reading, so please forgive my bad spelling.

If you have questions please read the whole document before reporting an issue to prevent duplicates. Also check [Step 7](Tutorial_11.0_Step7.md) and do a Google search.

As always, bugs may occur and your Dell will most likely be not amused. You have been warned!

## Credits:
The BigSur variant is based on the great work of XXXZC (https://github.com/xxxzc/xps15-9550-macos). There is not much i can do to improve a good working setup.
I try to give credit whenever possible in the corresponding readme.md files.

## What's not working:

- SD-Card reader
- Killer 1535 Wifi (rarely used in the 9550, though if you have it, it must be replaced)
- nVidia Graphics card
- Thunderbolt 3

## Requirements:

- One working MAC OS X Enviroment
- 16GB USB Stick (a larger drive may not bootable and/or require advanced partitioning)
- MacOS BigSur 11.0 installation file from the app store (redownload, just in case)
- Knowledge of editing PLIST files
- USB drive for backup - you'll lose all data on your computer!

## Locations and required Files

- [This repository](https://github.com/wmchris/DellXPS15-9550-OSX/archive/11.0.zip). Unzip this to a folder of your choice, I'll refer to this folder as "./" throughout the rest of the tutorial.
- EFI Partition containing the folder "EFI". This is a hidden partition on your HD/SSD. After mounting it's normally available at /Volumes/EFI/EFI/. I'll refer to it as "EFI/" throughout the rest of the tutorial.

## Step 0: Prepare Installation

### Firmware Update

If your Firmware is below 1.2.25, upgrade your EFI to at least 1.8 using the Firmware Update (See this repository Additional/BIOS). Click [here for a Step by Step Tutorial](Additional/bios_upgrade.md)

### SSD Sector Size (optional)

Optional: check if your SSD can be switched to 4k sector size. See [this Tutorial](4k_sector.md)

### Remove all Hacks from your Installation (Only on Update / Recovery from TimeMachine)

If you upgrade from an old version of OSX and you want to skip Step 2 from this tutorial - make sure to remove ALL old kexts / hacks / tools before you continue. Remnants will most likely break your installation. If you use Time Machine: create the backup after removing everything, otherwise Time Machine can/will restore the old hacks.

### Create Boot Media

Use the existing Mac to download the 11.0 installer from the App Store (make sure you have the full version) and create a bootable USB stick with CLOVER. Open Terminal and enter `diskutil list` and search for the deviceid of the USB stick (ex. disk2). Then reformat it by entering

```
diskutil partitionDisk /dev/disk2 GPT JHFS+ BigSur 0b
```

copy the Catalina installation files to the stick by entering

```
sudo /Applications/Install\ macOS\ Big\ Sur.app/Contents/Resources/createinstallmedia --volume /Volumes/BigSur --nointeraction
```

then install clover onto the USB stick (use google) and select to 'install it in the ESP' by clicking on advanced when possible.
Check twice that you definitely selected the USB stick as the target, installing clover on the internal HDD/SSD can break your system!

Mount the hidden EFI partition of the USB Stick by entering
`diskutil mount EFI`
inside the terminal. Mac OS will automatically mount the EFI partition of the USB stick and not the local machine, but it is worth double checking you havent accidentallly mounted the EFI partition of the host machine to prevent accidental damage to it.

Overwrite everything in the OC folder of the partition EFI with the content of ./11.0/OC.  
  
You have to enter a valid serial number, MLB and other variables (so called SMBIOS) to the config.plist in EFI/OC/.  
  
If your PC has a Core i5 processor, you'll have to modify your config.plist in EFI/OC/: search for the Key AAPL,ig-platform-id: AAAbGQ== and replace it with AAAWGQ==
If your PC is equipped with a HYNIX/Plextor/LiteOn SSD - you have to change the config.plist and enable the IONVMeFamily "Ignore FLBAS bit:4 being set" patch.

## Step 1: Configure your Notebook

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

Also disable the SD-Card Reader to reduce the power consumption drastically. Insert the stick on the Dell XPS 15 and boot it up holding the F12 key to get to the boot-menu and start by selecting your USB stick (if you've done this correctly you will see the name "Install macOS Big Sur", otherwise you will just see the brand name of your USB stick). You should now get to the MacOS Installation, just as it would appear on a real mac. If you're asked to log-in with your apple-id: select not now! Reason: see Step 5.

## Step 2: Partition

WARNING: after this step your computer will loose ALL data! So if you haven't created a backup, yet: QUIT NOW!

Don't install macOS yet. Select the Diskutil and delete the old partitions. Create a new HFS partition and name it "OSX". If you want to multiboot with Windows 10, then you'll have to create a second partition too. Make sure to select HFS, dont use FAT or it will not boot! (You can reformat the second parittion when installing Windows). Make sure to select GUID as partition scheme.
Close the Diskutil.

## Step 3: Install and make it bootable

Install OSX as you would on a real mac. You'll have to reboot multiple times - make sure to always boot using the attached USB stick => don't forget to press F12 if you didn't set the USB stick as your primary boot device. After the first reboot you should see a new boot option inside clover called "Install macOS Big Sur from OSX", which is highlighted by default. Just press enter. If you only see one boot device, then something went wrong and you should retry the installation. After a few reboots you should be inside your new macOS enviroment. You can always boot into it using the USB stick. Remove the USB drive after successful bootup. To make it bootable, enter
`diskutil mount EFI`
in your terminal, which should mount the EFI partition of your local installation.
Now copy everything from ./11.0/OC to EFI/OC like you did before when creating the USB stick. Note: If you had to modify the config.plist in step 1, do it here too. Your system should now be bootable by itself. Reboot to verify.

## Step 4: Post Installation

Because all DSDT/SSDT changes are already in the config.plist, you dont need to recompile your DSDT (though I suggest doing it anyway to make your system more reliable, see gymnaes El-Capitan tutorial for more information). For now we can skip this part. Open a terminal and go to the GIT folder. This step is optional as it only contains NullEthernet.kext. If you are using the stock Broadcom wireless card you can use the Wi-Fi as en0.

```
sudo cp -r ./11.0/Post-Install/LE-Kexts/* /Library/Extensions/
```

I suggest moving some of the kext from EFI/OC/kexts to /Library/Extensions and removing them from the config.plist, but this is optional.

Run 11.0/Post-Install/Additional Steps/Audio/install.sh to install ComboJack

Finalize the kext-copy by recreating the kernel cache:

```
sudo rm -rf /System/Library/Caches/com.apple.kext.caches/Startup/kernelcache
sudo rm -rf /System/Library/PrelinkedKernels/prelinkedkernel
sudo touch /System/Library/Extensions && sudo kextcache -u /
```

Sometimes you'll have to redo the last command if your system shows "Lock acquired".

OSX 10.12.2 removed the posibility to load unsigned code. You can enable this by entering
`sudo spctl --master-disable`

To prevent accidental hibernation (which can and will corrupt your data if you're not using the 4k switch), enter the following
`sudo pmset -a hibernatemode 0` or run the script in `./11.0/Post-Install/Additional\ Steps/Hibernation/disablehibernate.sh`

Take a look in the folder `/11.0/Post-Install/Additional\ Steps/`. There are multiple fixes for various bugs or problems. Use the supplied tools only when needed. These folders always contain a seperate readme file to explain their functionality, requirements and general usage.

## Step 5: iServices (AppStore, iMessages etc.)

WARNING: DONT USE YOUR MAIN APPLE ACCOUNT FOR TESTING! It's pretty common that apple BANS your apple-id from iMessage and other services if you've logged in on poorly configured hackintosh machines!
If you want to use the iServices, you'll have to do some advanced steps, which are not completly explained in this tutorial. If you are using NullEthernet.kext from step 4 or your Wi-Fi card is not en0. Go to your network settings and remove every network interface, then `sudo rm /Library/Preferences/SystemConfiguration/NetworkInterfaces.plist` and reboot. Go back in the network configuration and add the network interfaces (LAN) before Wi-Fi if you are using NullEthernet.kext or add Wi-Fi. If you are using Wi-Fi with no NullEthernet.kext make sure it is en0 before continuing.
You also need to modify your SMBIOS in the config.plist of Clover in your EFI partition with valid information about your "fake" mac. There are [multiple tutorials](http://www.fitzweekly.com/2016/02/hackintosh-imessage-tutorial.html) which explain how to do it.
It's possible you may need to call the apple hotline to get your fake serial whitelisted by telling a good story why apple forgot to add your serial number in their system. (aka: dont do it if you dont own a real mac). I personally suggest using real data from an old (broken) macbook.

## Step 6: Upgrading to macOS 11.0.1 or higher / installing security updates

Each upgrade will possibly break your system!
After each upgrade if you have kexts in your /Library/Extensions folder you will have to recreate the kernel cache by running these:

```
sudo rm -rf /System/Library/Caches/com.apple.kext.caches/Startup/kernelcache
sudo rm -rf /System/Library/PrelinkedKernels/prelinkedkernel
sudo touch /System/Library/Extensions && sudo kextcache -u /
```

Sometimes you'll have to redo the last command if your system shows "Lock acquired".

## Step 7: Fixes / Enhancements / Alternative Solutions / Bugs

If you have any problems, please read this section first. It contains some fixes to known problems and ideas.
I moved this part to its own file. Please click [here](Tutorial_11.0_Step7.md)

## Afterword

As I said before, this is not a tutorial for absolute beginners, though it's much easier than many other tutorials because most is preconfigured in the supplied config.plist. Some Dells have components included, which are not supported by these preconfigured files. In this case I can only suggest using Gymnaes tutorial which explains most of the DSDT patching, config.plist editing and kexts used in detail and use the supplied files here as templates.

- Warning: Some people have reported multiple data losses on this machine. I suggest using Time Machine whenever possible!
- Not a bug: if you REALLY want to use the 4K Display natively and disable the Retina Mode (max 1920x1080), google it or see [this tutorial](http://www.everymac.com/systems/apple/macbook_pro/macbook-pro-retina-display-faq/macbook-pro-retina-display-hack-to-run-native-resolution.html)

## Appendix 1: Accessories

The official [Dell adaptor DA200](http://accessories.euro.dell.com/sna/productdetail.aspx?c=at&l=de&s=dhs&cs=atdhs1&sku=470-abry) seem to work. You can use the Network, USB, HDMI and VGA. 
A cheap 3rd party unbranded USB-C -> VGA adaptor won't work. You can charge the Dell with a generic USB-C Power Adaptor, but USB-C has a maximum power of only 100W, so it's either charging OR usage, not both. Dont forget you need a special USB-C cable (Power Delivery 3.0) for charging. Charging with the Apple USB-C Charger works, but will be limited to ~60W (and therefore throttle the whole system).
  
The WD15 Docking works as well, but cannot be hotplugged and may break the sleep of your device. Ethernet requires [the official realtek drivers](https://www.realtek.com/en/component/zoo/category/network-interface-controllers-10-100-1000m-gigabit-ethernet-usb-3-0-software) to work.
