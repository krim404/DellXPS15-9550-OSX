## UHD Kexts
This kexts have been published on insanelymac and replaces the old perl command for patching the coredisplay to enable UHD resolution. Only use these kexts if you've the 4K touch display.  
Uses @vit9696 lilu patching framework  
Patcher created by @PMHeart  

# WARNING - this is bugged in 10.12.5 and will result in a kernel panic! Use the old command instead!

## Old Command
Old command (can be used to replace these kexts):  
```
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay  
sudo codesign -f -s - /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay  
```

obviously has to be redone after each system upgrade
