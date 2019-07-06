// Power fix - cause AppleACPIACAdapter to be loaded
// reference https://github.com/syscl/XPS9350-macOS/blob/master/DSDT/patches/system/system_ADP1.txt

DefinitionBlock ("", "SSDT", 2, "hack", "ADP1", 0)
{
    External(\_SB.ADP1, DeviceObj)
    Scope (\_SB.ADP1)
    {
        Name (_PRW, Package() { 0x18, 0x03 })
    }
}