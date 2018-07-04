// Enables hotplugging on USB-C port for Dell XPS 15 9550.
// Eliminates the need for USB port limit patch or third-party kext.

DefinitionBlock ("", "SSDT", 2, "hack", "TBOLT", 0x00003000)
{
    External (_SB_.PCI0.RP15.PXSX, DeviceObj)    
    External (_SB_.PCI0.XHC.RHUB, DeviceObj)
    External (_SB_.PCI0.XHC_.RHUB.HS01, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS02, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS03, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS04, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS05, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS06, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS07, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS08, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS09, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS10, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS11, DeviceObj)    
    //External (_SB_.PCI0.XHC_.RHUB.HS12, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS13, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.HS14, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS01, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS02, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS03, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS04, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS05, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS06, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS07, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS08, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS09, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.SS10, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.USR1, DeviceObj)    
    External (_SB_.PCI0.XHC_.RHUB.USR2, DeviceObj)    

    Scope (\_SB.PCI0.XHC.RHUB.HS01)
    {
        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
        {
            0xFF, 
            0x03, 
            0x00, 
            0x00
        })

        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
        {
            Buffer (0x10)  
            {
                0x81, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x31, 
                0x1C, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00
            }
        })
    }

    Scope (\_SB.PCI0.XHC.RHUB.HS02)
    {
        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
        {
            0xFF, 
            0x03, 
            0x00, 
            0x00
        })

        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
        {
            Buffer (0x10)  
            {
                0x81, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x31, 
                0x1C, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00
            }
        })
    }

    Scope (\_SB.PCI0.XHC.RHUB.HS04)
    {
        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
        {
            0xFF, 
            0x03, 
            0x00, 
            0x00
        })

        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
        {
            Buffer (0x10)  
            {
                0x81, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x30, 
                0x1C, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00
            }
        })

    }

    Scope (\_SB.PCI0.XHC.RHUB.HS09)
    {
        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
        {
            0xFF, 
            0x03, 
            0x00, 
            0x00
        })

        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
        {
            Buffer (0x10)  
            {
                0x81, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x30, 
                0x1C, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00
            }
        })
    }

    // Scope for the HS12 defined in DSDT will fail and invalidate the rest of SSDT, so
    // we define the device here, overriding DSDT.
    
    Scope (\_SB.PCI0.XHC.RHUB)
    {
        Device (HS12)
        {
            Name (_ADR, 0x0C)
            
            Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
            {
                0xFF, 
                0x03, 
                0x00, 
                0x00
            })

            // _PLD for Camera port taken from SSDT-6        
            Name (_PLD, Package (0x01)  // _PLD: Physical Location of Device
            {
                Buffer (0x14)
                {
                    0x82, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                    0x24, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x00,
                    0xC8, 0x00, 0xA0, 0x00                         
                }
            }) 
        }
    }

    Scope (\_SB.PCI0.XHC.RHUB.USR1)
    {
        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
        {
            0x00, 
            0x03, 
            0x00, 
            0x00
        })

        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
        {
            Buffer (0x10)  
            {
                0x81, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x30, 
                0x1C, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00
            }
        })
    }

    Scope (\_SB.PCI0.XHC.RHUB.USR2)
    {
        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
        {
            0x00, 
            0x03, 
            0x00, 
            0x00
        })

        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
        {
            Buffer (0x10)  
            {
                0x81, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x30, 
                0x1C, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00
            }
        })
    }

    Scope (\_SB.PCI0.XHC.RHUB.SS01)
    {
        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
        {
            0xFF, 
            0x03, 
            0x00, 
            0x00
        })

        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
        {
            Buffer (0x10)  
            {
                0x81, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x31, 
                0x1C, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00
            }
        })
    }

    Scope (\_SB.PCI0.XHC.RHUB.SS02)
    {
        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
        {
            0xFF, 
            0x03, 
            0x00, 
            0x00
        })

        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
        {
            Buffer (0x10)  
            {
                0x81, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x31, 
                0x1C, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00, 
                0x00
            }
        })
    }

    Scope (\_SB.PCI0.RP15.PXSX)
    {
        Method (_RMV, 0, NotSerialized)  // _RMV: Removal Status
        {
            Return (One)
        }

        Method (_DSM, 4, NotSerialized) 
        {
            Store (Package (0x02)
                {
                    "PCI-Thunderbolt", 
                    One
                }, Local0)
            Return (Local0)
        }

        Device (DSB0)
        {
            Name (_ADR, Zero)  // _ADR: Address
        }

        Device (DSB1)
        {
            Name (_ADR, 0x00010000)  // _ADR: Address
        }

        Device (DSB2)
        {
            Name (_ADR, 0x00020000)  // _ADR: Address

            Device (XHC2)
            {
                Name (_ADR, Zero)  // _ADR: Address
                
                Device (RHUB)
                {
                    Name (_ADR, Zero)  // _ADR: Address

                    Device (HS01)
                    {
                        Name (_ADR, 0x01)
                        
                        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
                        {
                            0x00, 
                            0x09, 
                            0x00, 
                            0x00
                        })

                        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
                        {
                            Buffer (0x10)  
                            {
                                0x81, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x30, 
                                0x1C, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00
                           }
                        })
                    }
                    
                    Device (HS02)
                    {
                        Name (_ADR, 0x02)
                        
                        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
                        {
                            0x00, 
                            0x09, 
                            0x00, 
                            0x00
                        })

                        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
                        {
                            Buffer (0x10)  
                            {
                                0x81, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x30, 
                                0x1C, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00
                           }
                        })
                    }
                    
                    Device (SSP1)
                    {
                        Name (_ADR, 0x03)
                        
                        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
                        {
                            0xFF, 
                            0x09, 
                            0x00, 
                            0x00
                        })

                        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
                        {
                            Buffer (0x10)  
                            {
                                0x81, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x31, 
                                0x1C, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00
                           }
                        })
                    }
                    
                    Device (SSP2)
                    {
                        Name (_ADR, 0x04)
                        
                        Name (_UPC, Package (0x04)  // _UPC: USB Port Capabilities
                        {
                            0x00, 
                            0x09, 
                            0x00, 
                            0x00
                        })

                        Name (_PLD, Package (0x01) // _PLD: Physical Location of Device
                        {
                            Buffer (0x10)  
                            {
                                0x81, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x30, 
                                0x1C, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00, 
                                0x00
                           }
                        })
                    }
                }
            }
        }
    }
}

