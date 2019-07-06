//
// SSDT-ALS0.dsl
//
// Dell XPS 15 9560 
//
// This SSDT contains a fake Ambient Light Sensor.
//
// This is needed to allow brightness to save on reboot
// (MacBookPro13,3 SMBios).
// 

DefinitionBlock ("", "SSDT", 2, "hack", "ALS0", 0x00000000)
{
    External (LHIH, UnknownObj)    // (from opcode)
    External (LLOW, UnknownObj)    // (from opcode)

    Device (ALS0)
    {
        Name (_HID, "ACPI0008")  // _HID: Hardware ID
        Name (_CID, "smc-als")  // _CID: Compatible ID
        Method (_ALI, 0, NotSerialized)  // _ALI: Ambient Light Illuminance
        {
            Return (Or (ShiftLeft (LHIH, 0x08), LLOW))
        }

        Name (_ALR, Package (0x05)  // _ALR: Ambient Light Response
        {
            Package (0x02)
            {
                0x46, 
                Zero
            }, 

            Package (0x02)
            {
                0x49, 
                0x0A
            }, 

            Package (0x02)
            {
                0x55, 
                0x50
            }, 

            Package (0x02)
            {
                0x64, 
                0x012C
            }, 

            Package (0x02)
            {
                0x96, 
                0x03E8
            }
        })
    }
}

