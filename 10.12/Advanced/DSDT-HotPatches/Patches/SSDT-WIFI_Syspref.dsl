DefinitionBlock ("", "SSDT", 2, "APPLE ", "SSDT-Bro", 0x00001000)
{
    External (_SB_.PCI0.RP01, DeviceObj)    // (from opcode)
    External (_SB_.PCI0.RP01.PXSX, DeviceObj)    // (from opcode)
    External (PXSX, DeviceObj)    // (from opcode)

    Scope (\_SB.PCI0.RP01)
    {
        Scope (PXSX)
        {
            Name (_STA, Zero)  // _STA: Status
        }

        Device (ARPT)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Name (_PRW, Package (0x02)  // _PRW: Power Resources for Wake
            {
                0x09, 
                0x04
            })
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                If (LEqual (Arg2, Zero))
                {
                    Return (Buffer (One)
                    {
                         0x03                                           
                    })
                }

                Return (Package (0x0C)
                {
                    "AAPL,slot-name", 
                    "Built In", 
                    "name", 
                    "AirPort Extreme", 
                    "model", 
                    Buffer (0x3C)
                    {
                        "Broadcom BCM4360 802.11 a/b/g/n/ac Wireless Network Adapter"
                    }, 

                    "device_type", 
                    Buffer (0x08)
                    {
                        "AirPort"
                    }, 

                    "built-in", 
                    Buffer (0x04)
                    {
                         0x01, 0x00, 0x00, 0x00                         
                    }, 

                    "location", 
                    Buffer (0x04)
                    {
                        "1"
                    }
                })
            }
        }
    }
}

