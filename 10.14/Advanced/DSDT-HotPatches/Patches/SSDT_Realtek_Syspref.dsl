DefinitionBlock ("", "SSDT", 2, "APPLE ", "SSDT-Realtek_Syspref", 0x00001000)
{
 External (_SB_.PCI0, DeviceObj) 
External (_SB_.PCI0.HDEF, DeviceObj)
    Scope (\_SB.PCI0)
    {
        Scope (\_SB.PCI0.HDEF)
        {
                        Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                Store (Package (0x10)
                    {
                        "AAPL,slot-name", 
                        "Built In", 
                        "name", 
                        "Realtek Audio Controller", 
                        "model", 
                        Buffer (0x20)
                        {
                            "Realtek ALC298 Audio Controller"
                        }, 

                        "device_type", 
                        Buffer (0x11)
                        {
                            "Audio Controller"
                        }, 

                        "layout-id", 
                        Buffer (0x04)
                        {
                             0x1C, 0x00, 0x00, 0x00                         
                        }, 

                        "PinConfigurations", 
                        Buffer (Zero) {}, 
                        "MaximumBootBeepVolume", 
                        Buffer (One)
                        {
                             0x40                                           
                        }, 

                        "hda-gfx", 
                        Buffer (0x0A)
                        {
                            "onboard-1"
                        }
                    }, Local0)
                DTGP (Arg0, Arg1, Arg2, Arg3, RefOf (Local0))
                Return (Local0)
            }}
           
             Method (DTGP, 5, NotSerialized)
            {
                If (LEqual (Arg0, Buffer (0x10)
                {
                    /* 0000 */    0xC6, 0xB7, 0xB5, 0xA0, 0x18, 0x13, 0x1C, 0x44,
                    /* 0008 */    0xB0, 0xC9, 0xFE, 0x69, 0x5E, 0xAF, 0x94, 0x9B
                }))
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
            }}}
