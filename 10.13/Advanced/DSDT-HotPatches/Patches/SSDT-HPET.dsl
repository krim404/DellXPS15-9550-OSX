// Fix HPET devices

DefinitionBlock("", "SSDT", 2, "hack", "HPET", 0)
{
    External(_SB.PCI0.LPCB, DeviceObj)

    Scope(_SB.PCI0.LPCB)
    {
        Device (HPET)
        {
            Name (_HID, EisaId ("PNP0103"))  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (BUF0, ResourceTemplate()
            {
                IRQNoFlags() { 0, 8, 11, 15 }
                Memory32Fixed (ReadWrite,
                               0xFED00000,         // Address Base
                               0x00000400,         // Address Length
                               _Y30)
            })

            Name (_STA, 0x0F)
            Method (_CRS, 0, NotSerialized)
            {
                Return (BUF0)
            }
        }
    }
}