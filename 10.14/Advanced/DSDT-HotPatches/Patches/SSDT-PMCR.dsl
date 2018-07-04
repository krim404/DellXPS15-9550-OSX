// Add PMCR

DefinitionBlock("", "SSDT", 2, "hack", "PMCR", 0)
{
    External(_SB.PCI0, DeviceObj)

    Scope(_SB.PCI0)
    {
		Device (PMCR)
		{
		    Name (_ADR, 0x001F0002)  // macOS expect PMCR for PPMC to load correctly credit syscl
		}
	}
}