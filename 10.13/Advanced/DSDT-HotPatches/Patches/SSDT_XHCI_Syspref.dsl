DefinitionBlock ("", "SSDT", 2, "APPLE ", "SSDT_XHC_Syspref", 0x00001000)
{
    External (_SB_.PCI0, DeviceObj)    // (from opcode)
    External (_SB_.PCI0.XHC, DeviceObj)    // (from opcode)
    
        Scope (\_SB.PCI0)
    {
        Scope (\_SB.PCI0.XHC)
        {
                        Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                Store (Package (0x17)
                    {
                        "AAPL,clock-id", 
                        Buffer (One)
                        {
                             0x02                                           
                        }, 

                        "AAPL,slot-name", 
                        "Built In", 
                        "name", 
                        "Intel XHCI Controller", 
                        "model", 
                        Buffer (0x38)
                        {
                            "Intel 10 Series Chipset Family USB xHCI Host Controller"
                        }, 

                        "device_type", 
                        Buffer (0x0F)
                        {
                            "USB Controller"
                        }, 

                        "AAPL,current-available", 
                        0x0834, 
                        "AAPL,current-extra", 
                        0x0A8C, 
                        "AAPL,current-in-sleep", 
                        0x03E8, 
                        "AAPL,current-extra-in-sleep", 
                        0x0834, 
                        "AAPL,max-port-current-in-sleep", 
                        0x0A8C, 
                        "AAPL,device-internal", 
                        0x02, 
                        Buffer (One)
                        {
                             0x00                                           
                        }
                    }, Local0)
                DTGP (Arg0, Arg1, Arg2, Arg3, RefOf (Local0))
                Return (Local0)
            }
        }
    }
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
    }}

    