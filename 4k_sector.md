## FIX for the NVMe Corruption  
This fix is making it possible to use the native NVMe driver from apple on many machines. There is no drawback, because all modern OS (like Windows 8, 8.1 and newer) support 4k sector sizes. After this step your SSD will be unreadable and must be reformatted. You'll loose all your data(keep a backup).   

## Do first
First check your firmware upgrades for your SSD. Especially if you use Toshiba drives, these have a critical "drive disappearing" bug which can happen at any time. [Link](http://www.dell.com/support/home/en/en/debsdt1/Drivers/DriversDetails?driverId=2N42W)  
Some people reported problems with identification of a 4K formatted drive in its Dell Notebooks (looks like the disappearing bug). Recovery is possible by restarting multiple times until the disk is visible again and switching back to the 512b mode. This change will not brick your drive, but you will loose all your data after the format, even if the 4k switch was unsuccessful and reverted.  

## Incompatible Drives
* any Samsung drive
* LiteOn CX2 series


## Begin
Boot from Ubuntu 16.10 Live USB  
Enable Universe repository and reload repo database  
check the device for your ssd (can be /dev/nvme0, /dev/sda0 or something completly different.  
open the terminal  
```
sudo apt-get install smartmontools  
sudo apt-get install nvme-cli  
sudo smartctl -a /dev/nvme0  
```  
Check the output. If you have an entry with 4096, then your SSD is 4k compatible and you can use the native SSD configuration  
```
Supported LBA Sizes (NSID 0x1)  
Id Fmt  Data  Metadt  Rel_Perf  
 0 +     512       0         2  
 1 -    4096       0         1  
```

the setting with the + in front is the active one  
You can switch the settings:  
`nvme format -l 1 /dev/nvme0`
this will do a low level format. You need to create a new partition table afterwards from the OSX installation disk utility.  

## Before you boot
you have to remove any trace from the HackrNVMe patch from your installation drive (and obviously also from the productive used one)! With the patch enabled it will not recognize your drive anymore!
Delete if exist:
* SSDT-Hackr.aml from EFI/ACPI/patched
* hackrnvmefamily kext
* hotpatches inside your config.plist (IONVMeFamily Patch#N)
