Depending on your memmap, you need to use OsxAptioFixDrv, OsxAptioFix2Drv or OsxAptioFix3Drv.  

Version 3 is the most advanced with nvram support, but can result in strange behaviour when your memmap is too fragmented (like only displaying „does printf work??“).  

Most time OsxAptioFixDrv is working with slide=0 or without any slide parameter at all. If not, you have to calculate the correct slide parameter value by yourself. See https://github.com/wmchris/DellXPS15-9550-OSX/blob/10.13/Additional/slide_calc.md
  
AptioMemoryFix is a fork of v2 which automatically tries to find a suitable slide value. Some people were successful with using it. More details: https://github.com/acidanthera/AptioFixPkg/  
  
Use AllocFix.efi or OsxLowMemFixDrv in combination with OsxAptioFixDrv if you can’t get V1, V2 or V3 to run with correct slide parameters. Use them only asw your last resort!  
  

