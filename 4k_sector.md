##FIX for the NVMe Corruption  
This fix is making it possible to use the native NVMe driver from apple on many machines. There is no drawback, because all modern OS (like Windows 7 and newer) support 4k sector sizes. After this step your SSD will be unreadable and must be reformatted. You'll loose all your data.   

  
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
You can switch the settings by reformating it:  
`nvme format -l 1 /dev/nvme0`
  
Now remove SSDT-Hackr.aml from EFI/ACPI/patched, the hackrnvmefamily kext or the clover storage hotpatches from your EFI bootloader and reinstall OSX
