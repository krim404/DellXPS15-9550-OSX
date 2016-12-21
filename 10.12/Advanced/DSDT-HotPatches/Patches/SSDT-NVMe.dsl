// Inject bogus class code for NVMe SSD so that native IONVMeFamily.kext does not load
DefinitionBlock("", "SSDT", 2, "hack", "NVMe-Pcc", 0)
{
    External(_SB.PCI0.RP09.PXSX, DeviceObj)
    Method(_SB.PCI0.RP09.PXSX._DSM, 4)
    {
        If (!Arg2) { Return (Buffer() { 0x03 } ) }
        Return(Package()
        {
            "class-code", Buffer() { 0xff, 0x08, 0x01, 0x00 },
        })
    }
}
//EOF