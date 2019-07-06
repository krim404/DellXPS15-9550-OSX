// Custom ADB codes to change Dell brightness keys to F14/F15
// some SSDTs use a different path than _SB.PCI0.LPCB.PS2K, so adjust accordingly
DefinitionBlock ("", "SSDT", 2, "hack", "ps2k", 0)
{
    External(\_SB.PCI0.LPCB.PS2K, DeviceObj)
    Scope (\_SB.PCI0.LPCB.PS2K)
    {
        Name(RMCF, Package()
        {
            "Keyboard", Package()
            {
                "Custom ADB Map", Package()
                {
                    Package(){},
                    "e005=6b",
                    "e006=71",
                },
            },
        })
    }
}