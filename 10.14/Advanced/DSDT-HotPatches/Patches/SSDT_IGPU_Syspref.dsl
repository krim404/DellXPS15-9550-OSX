DefinitionBlock ("", "SSDT", 2, "APPLE ", "SSDT-IGPU_Syspref", 0x00001000)
{
    External (_SB_.PCI0, DeviceObj)    // (from opcode)
    External (_SB_.PCI0.IGPU, DeviceObj)    // (from opcode)

    Scope (\_SB.PCI0)
    {
        Scope (\_SB.PCI0.IGPU)
        {
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                Store (Package (0x0E)
                    {
                        "AAPL,slot-name", 
                        "Built In", 
                        "name", 
                        "Intel Display Controller", 
                        "model", 
                        Buffer (0x16)
                        {
                            "Intel HD Graphics 530"
                        }, 

                        "device_type", 
                        Buffer (0x13)
                        {
                            "Display Controller"
                        }, 

                        "AAPL,ig-platform-id", 
                        Buffer (0x04)
                        {
                             0x04, 0x00, 0x26, 0x19                         
                        }, 

                        "AAPL,GfxYTile", 
                        Buffer (0x04)
                        {
                             0x01, 0x00, 0x00, 0x00                         
                        }, 

                        "hda-gfx", 
                        Buffer (0x0A)
                        {
                            "onboard-1"
                        }
                    }, Local0)
                DTGP (Arg0, Arg1, Arg2, Arg3, RefOf (Local0))
                Return (Local0)
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
}

