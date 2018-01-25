Depending on your memmap, you need to use OsxAptioFixDrv, OsxAptioFix2Drv or OsxAptioFix3Drv.  
Version 3 is the most advanced with nvram support, but can result in strange behaviour when your memmap is too fragmented (like only displaying „does printf work??“.  
  
Use AllocFix.efi in combination with OsxAptioFixDrv if you can’t get V2 or V3 to run with correct slide parameters. Use AllocFix only as your last resort!w