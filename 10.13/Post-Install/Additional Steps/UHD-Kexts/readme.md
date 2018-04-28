## UHD Kexts
This kexts have been published on insanelymac and replaces the old perl command for patching the coredisplay to enable UHD resolution with the Intel GPU. You only require these kexts if your Dell 9550 has the 4K touch display installed.  
Uses @vit9696 lilu patching framework  
Patcher created by @PMHeart  

# WARNING - this can be buggy and result in a kernel panic after some time. We dont know why. The manual patching using the old command (see below) is much more reliable.

## Manual Command (10.13.4+)
```
CoreDisplayLocation="/System/Library/Frameworks/CoreDisplay.framework/Versions/A/CoreDisplay"
sudo perl -i.bak -pe '$oldtest1 = qr"\xE8\x37\x02\x00\x00\xBB\xE6\x02\x00\xE0\x85\xC0\x0F\x85\x9C\x00\x00\x00"s;$newtest1 = "\xE8\x37\x02\x00\x00\xBB\xE6\x02\x00\xE0\x31\xC0\x0F\x85\x9C\x00\x00\x00"; $oldtest2 = qr"\xE8\x65\x00\x00\x00\x85\xC0\xBB\xE6\x02\x00\xE0\x0F\x85\xCA\xFE\xFF\xFF"s;$newtest2 = "\xE8\x65\x00\x00\x00\x31\xC0\xBB\xE6\x02\x00\xE0\x0F\x85\xCA\xFE\xFF\xFF";s/$oldtest1/$newtest1/g;s/$oldtest2/$newtest2/g' $CoreDisplayLocation
sudo touch /System/Library/Extensions
sudo codesign -f -s - $CoreDisplayLocation
sudo update_dyld_shared_cache
```

## Old Command
Old command (can be used to replace these kexts on 10.13.3 or lower):  
```
sudo perl -i.bak -pe 's|\xB8\x01\x00\x00\x00\xF6\xC1\x01\x0F\x85|\x33\xC0\x90\x90\x90\x90\x90\x90\x90\xE9|sg' /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay  
sudo codesign -f -s - /System/Library/Frameworks/CoreDisplay.framework/Versions/Current/CoreDisplay  
```

obviously has to be redone after each system upgrade
