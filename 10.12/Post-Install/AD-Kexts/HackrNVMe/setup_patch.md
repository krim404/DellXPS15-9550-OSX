If you use a hynix device and you didnt do the 4k sector switch, you'll have to add the following patch to your config.plist before starting the installation:
```
<key>Comment</key>
<string>IONVMeFamily Pike R. Alpha Hynix SSD patch</string>
<key>Disabled</key>
<false/>
<key>Find</key>
<data>
9sEQD4UcAQAA
</data>
<key>Name</key>
<string>IONVMeFamily</string>
<key>Replace</key>
<data>9sECD4UcAQAA</data>
```