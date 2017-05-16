# How to calculate the slide parameter for OsxAptioFix2Drv
If you cannot boot because of an error like "couldn't allocate runtime area" with OSXAptioFIX2 then your memory is too fragmented. 
You need to manually "slide" the pointer of the OSXAptioFix2 to a free map in your memory.  
Because this memory map is unique to each system configuration you have to use a different slide command on most computers.    

## Step 1: Get Memory Map
![MEMMAP](BIOS/pictures/memmap.jpg "Memory Map")  
Boot into the UEFI Shell from Clover and enter the command `memmap`. You'll get an output like from the image above

## Step 2: Use hexadecimal calculator
![Calc](BIOS/pictures/calc.png "Calc")  
use a hexadecimal calculator (like calc from mac in programmers mode on 16)

## Step 3: Add the number of pages till first suitable block
you need a decent amount of pages to boot. Look in your memmap for the first Available block with enough pages. On the image above it would be line 8 with 12D58 free pages.  
Add all blocks from above this. In this example it would be 8+50+1+6+1+3F+1 = A0

## Step 4: Switch to Base 10 
convert the number to Base10 (normal number). You can do this with the mac os calc by pressing the button with the 10 on it. In this example it would result in 160.  
This is your slide parameter. Enter it in your boot command (slide=160) and everything should work. If it doesn't then maybe your block doesn't have enough free pages and you have to select a bigger one.