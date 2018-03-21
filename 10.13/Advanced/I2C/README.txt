VoodooI2C is an alternative to VoodooPS2 (for some touchpads) with a high potential, but considered unstable.

It is compatible with the Dell XPS 15 9550 Touchpad. These files are required to enable compatibility. They’re only added to the repository for future usage. 

Required DSDT Patches:
<dict>
	<key>Comment</key>
	<string>change GPI0 device _STA to XSTA</string>
	<key>Disabled</key>
	<false/>
	<key>Find</key>
	<data>X1NUQQCgCZNTQlJHAA==</data>
	<key>Replace</key>
	<data>WFNUQQCgCZNTQlJHAA==</data>
</dict>
<dict>
	<key>Comment</key>
	<string>change I2C devices _CRS to XCRS</string>
	<key>Disabled</key>
	<false/>
	<key>Find</key>
	<data>X0NSUwCgDg==</data>
	<key>Replace</key>
	<data>WENSUwCgDg==</data>
</dict>

Code:
https://github.com/alexandred/VoodooI2C
