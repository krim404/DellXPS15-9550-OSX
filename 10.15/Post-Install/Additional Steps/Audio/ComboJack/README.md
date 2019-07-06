## VerbStub by KNNSpeed
this is a copy of the 9560 thread. Just install using the install.sh. It’s already modified to do all required steps for a normal installation with AppleHDA patch by sysCL.  
  
If you installed VoodooHDA - uninstall it before you continue


### Description
Allows complete configuration of unsupported codecs (this version enables full functionality of the Dell XPS 15 9560’s ALC3266 3.5mm combination jack).  
  
Based on the idea of https://github.com/goodwin/ALCPlugFix  
Implemented by way of porting hda-verb from alsa-tools:  
https://www.alsa-project.org/main/index.php/Main_Page  
  
Portions of code adapted from CodecCommander (https://github.com/RehabMan/  EAPD-Codec-Commander) and the Linux kernel (https://github.com/torvalds/  linux). All copyrights belong to their respective owners.  
  
Uses layout-id 72. VerbStub.kext goes into EFI/Clover/kexts/Other.  