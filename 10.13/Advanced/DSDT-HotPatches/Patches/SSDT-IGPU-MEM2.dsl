// Add MEM2

DefinitionBlock("", "SSDT", 2, "hack", "MEM2", 0)
{
    External(_SB.PCI0, DeviceObj)

    Scope(_SB.PCI0)
    {
		Device (MEM2) // iGPU use MEM2 instead of TPMX, and RW memory. syscl
		{
		    Name (_HID, EisaId ("PNP0C01"))
		    Name (_UID, 0x02)
		    Name (_STA, 0x0F)
		    Name (_CRS, ResourceTemplate ()
		    {
		        Memory32Fixed (ReadWrite, 0x20000000, 0x00200000, )
		        Memory32Fixed (ReadWrite, 0x40000000, 0x00200000, )
		    })
		}
	}
}