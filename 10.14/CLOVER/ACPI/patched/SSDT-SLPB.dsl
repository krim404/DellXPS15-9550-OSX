// reference https://github.com/syscl/XPS9350-macOS/blob/master/DSDT/patches/syscl_SLPB.txt

DefinitionBlock ("", "SSDT", 2, "hack", "SLPB", 0)
{
    External(\_SB.SLPB, DeviceObj)
    Scope (\_SB.SLPB)
    {
        Name (_STA, 0x0B)  // correct status by syscl
    }
}