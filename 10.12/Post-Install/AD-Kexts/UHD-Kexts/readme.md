## UHD Kexts
This kexts have been published on insanelymac and replaces the old perl command for patching the coredisplay to enable UHD resolution with the Intel GPU. You only require these kexts if your Dell 9550 has the 4K touch display installed.  
Uses @vit9696 lilu patching framework  
Patcher created by @PMHeart  

# WARNING - this can be buggy and result in a kernel panic after some time. We dont know why. The manual patching using the old command (see below) is much more reliable.

## Old Command
Old command (can be used to replace these kexts):  
```
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay  
sudo codesign -f -s - /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay  
```

obviously has to be redone after each system upgrade
