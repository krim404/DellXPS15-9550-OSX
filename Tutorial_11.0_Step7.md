# Step 7: Fixes / Enhancements / Alternative Solutions / Bugs

## HDMI/VGA Video-Out Fix for MBP13,3
Open /System/Library/Extensions/AppleGraphicsControl.kext/Contents/PlugIns/AppleGraphicsDevicePolicy.kext/Contents/Info.plist  
Find the Board-ID which used in your config.plist.  
Replace the attribute Config2 with none  
`sudo kextcache -system-prelinked-kernel && sudo kextcache -system-caches`  
reboot 

## Error: couldn't allocate runtime area / unable to start installer / unable to boot at all
Since OSXAptio is a lil bit picky with memory maps, you have to swap to OSXAptioV2 and choose a different slide= command (see question above) to a suitable number. Change the slide param in the config.plist. See [this Tutorial](/Additional/slide_calc.md) for more informations. It is still possible you cant get it to boot because no memory section is big enough. There are multiple different options available, but each of them has to be considered experimental or buggy. 

## Display Backlight Control not working
the supplied AppleBacklightInjector contains an id for the display. It is possible that this id is different on your machine (especially if you use the non touch display). In this case just follow [this tutorial](Additional/PatchAppleBacklight_v2/readme.md)

## Display Flickers randomly
See tutorial in [Additional/EDID-Injector](Additional/Tools/EDID-Injector) for possible fix.  

## Display ICC Calibration
ICC profile for 4k screen calibrated with Spyder4Pro colorimeter and DisplayCAL is available in Additional/Profiles.   
Every panel is a lil bit different, so don't expect too much precision, but this profile works great for sRGB and AdobeRGB.

## Sleep results in reboot
This is only in case sleep worked in the past. If you have sleep issues from the beginning and you strictly followed this tutorial (check at least twice!), you need additional assistance (easiest way is asking in a forum).  
  
Sometimes (especially on a dual boot environment after booting in the other OS) a normal sleep results in a full (and dirty) reboot. For me the old behaviour can be obtained by issuing this command: `sudo pmset -a hibernatemode 0 && sudo reboot`, albeit already being in hibernatemode 0. The reboot is mandatory, otherwise it doesn't work. Some people reported this fixes their problems, while other still had sleep issues. Just give it a shot.

## Additional Resources / Request help
It's much to read, but this thread include many solutions to the less common problems. Please read every post before asking a question:  
http://www.insanelymac.com/forum/topic/319764-guide-dell-xps-15-9550-sierra-10122-quick-installation/  
also please check if your question is already answered here: https://github.com/wmchris/DellXPS15-9550-OSX/issues?q=is%3Aissue+is%3Aclosed
