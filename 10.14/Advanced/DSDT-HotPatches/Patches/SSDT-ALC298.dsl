// This SSDT demonstrates a custom configuration for ALC283.
// It is the same data that is currently in the Info.plist

// If you had a codec that needed the same configuration, you could
// load this SSDT in order to implement it without modifying the kext.
// It will override the defaults specfied by the CodecCommander Info.plist

// Customize to suit your needs.

DefinitionBlock ("", "SSDT", 1, "hack", "ALC298", 0)
{
    External(_SB.PCI0.HDEF, DeviceObj)
    
    Name(_SB.PCI0.HDEF.RMCF, Package()
    {
        "CodecCommander", Package()
        {
            "Custom Commands", Package()
            {
                Package(){}, // signifies Array instead of Dictionary
                Package()
                {
                    // 0x18 SET_PIN_WIDGET_CONTROL 0x22
                    "Command", Buffer() { 0x01, 0x87, 0x07, 0x22 },
                    "On Init", ">y",
                    "On Sleep", ">n",
                    "On Wake", ">y",
                },
                Package()
                {
                    // 0x1a SET_PIN_WIDGET_CONTROL 0x23
                    "Command", Buffer() { 0x01, 0xa7, 0x07, 0x23 },
                    "On Init", ">y",
                    "On Sleep", ">n",
                    "On Wake", ">y",
                },
                Package()
                {
                    // 0x21 SET_UNSOLICITED_ENABLE 0x83
                    "Command", Buffer() { 0x02, 0x17, 0x08, 0x83 },
                    "On Init", ">y",
                    "On Sleep", ">n",
                    "On Wake", ">y",
                },
            },
            "Perform Reset", ">n",
            "Send Delay", 10,
            "Sleep Nodes", ">n",
        },
    })
}
//EOF
