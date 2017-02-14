This is an experimental patch for AppleHDA supplied by goodwin_c and syscl, which contains a prepatched AppleHDA kext. Of course this will break on an update. You’ll have to replace the AppleHDA.kext every time you upgrade your system.

Be aware:  if you used VoodooHDA in the past, you’ll have to delete 
/System/Library/Extensions/VoodooHDA.kext
/System/Library/Extensions/AppleHDADisabler.kext