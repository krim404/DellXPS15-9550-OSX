DefinitionBlock ("", "SSDT", 2, "APPLE ", "SSDT-NVM", 0x00001000)
{
    External (_SB_.PCI0, DeviceObj)    // (from opcode)
    External (_SB_.PCI0.RP09.PXSX, DeviceObj)    // (from opcode)

    Scope (\_SB.PCI0)
    {
        Scope (\_SB.PCI0.RP09.PXSX)
        {
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                Store (Package (0x0A)
                    {
                        "AAPL,slot-name", 
                        "Built In", 
                        "name", 
                        "NVME Controller", 
                        "model", 
                        Buffer (0x0F)
                        {
                            "NVME Controller"
                        }, 

                        "device_type", 
                        Buffer (0x10)
                        {
                            "NVME Controller"
                        }, 

                        "device-id", 
                        Buffer (0x04)
                        {
                             0x02, 0x1E, 0x00, 0x00                         
                        }
                    }, Local0)
                DTGP (Arg0, Arg1, Arg2, Arg3, RefOf (Local0))
                Return (Local0)
            }
        }
    }

    Method (DTGP, 5, NotSerialized)
    {
        If (LEqual (Arg0, ToUUID ("a0b5b7c6-1318-441c-b0c9-fe695eaf949b")))
        {
            If (LEqual (Arg1, One))
            {
                If (LEqual (Arg2, Zero))
                {
                    Store (Buffer (One)
                        {
                             0x03                                           
                        }, Arg4)
                    Return (One)
                }

                If (LEqual (Arg2, One))
                {
                    Return (One)
                }
            }
        }

        Store (Buffer (One)
            {
                 0x00                                           
            }, Arg4)
        Return (Zero)
    }
}

