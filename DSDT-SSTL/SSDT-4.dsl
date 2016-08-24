/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160422-64(RM)
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to non-symbolic legacy ASL operators
 *
 * Disassembly of SSDT-4.aml, Wed Aug 24 19:47:04 2016
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000BE3 (3043)
 *     Revision         0x02
 *     Checksum         0xCE
 *     OEM ID           "INTEL "
 *     OEM Table ID     "Ther_Rvp"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20120913 (538052883)
 */
DefinitionBlock ("", "SSDT", 2, "INTEL ", "Ther_Rvp", 0x00001000)
{
    /*
     * iASL Warning: There were 10 external control methods found during
     * disassembly, but only 9 were resolved (1 unresolved). Additional
     * ACPI tables may be required to properly disassemble the code. This
     * resulting disassembler output file may not compile because the
     * disassembler did not know how many arguments to assign to the
     * unresolved methods. Note: SSDTs can be dynamically loaded at
     * runtime and may or may not be available via the host OS.
     *
     * In addition, the -fe option can be used to specify a file containing
     * control method external declarations with the associated method
     * argument counts. Each line of the file must be of the form:
     *     External (<method pathname>, MethodObj, <argument count>)
     * Invocation:
     *     iasl -fe refs.txt -d dsdt.aml
     *
     * The following methods were unresolved and many not compile properly
     * because the disassembler had to guess at the number of arguments
     * required for each:
     */
    /*
     * External declarations were imported from
     * a reference file -- refs.txt
     */

    External (_GPE.MMTB, MethodObj)    // Imported: 0 Arguments
    External (_GPE.VHOV, MethodObj)    // Imported: 3 Arguments
    External (_PR_.AAC0, FieldUnitObj)
    External (_PR_.ACRT, FieldUnitObj)
    External (_PR_.APSV, FieldUnitObj)
    External (_PR_.CPU0, ProcessorObj)
    External (_PR_.CPU1, ProcessorObj)
    External (_PR_.CPU2, ProcessorObj)
    External (_PR_.CPU3, ProcessorObj)
    External (_PR_.CPU4, ProcessorObj)
    External (_PR_.CPU5, ProcessorObj)
    External (_PR_.CPU6, ProcessorObj)
    External (_PR_.CPU7, ProcessorObj)
    External (_PR_.DTS1, FieldUnitObj)
    External (_PR_.DTS2, FieldUnitObj)
    External (_PR_.DTS3, FieldUnitObj)
    External (_PR_.DTS4, FieldUnitObj)
    External (_PR_.DTSE, FieldUnitObj)
    External (_PR_.PDTS, FieldUnitObj)
    External (_PR_.PKGA, FieldUnitObj)
    External (_SB_.PCI0.GFX0.DD02._BCM, MethodObj)    // Imported: 1 Arguments
    External (_SB_.PCI0.LPCB.H_EC.ECAV, IntObj)    // Warning: Unknown object
    External (_SB_.PCI0.LPCB.H_EC.ECMD, MethodObj)    // Warning: Unknown method, guessing 1 arguments
    External (_SB_.PCI0.LPCB.H_EC.ECMT, UnknownObj)    // Warning: Unknown object
    External (_SB_.PCI0.LPCB.H_EC.ECRD, MethodObj)    // Imported: 1 Arguments
    External (_SB_.PCI0.LPCB.H_EC.ECWT, MethodObj)    // Imported: 2 Arguments
    External (_SB_.PCI0.LPCB.H_EC.PECH, UnknownObj)    // Warning: Unknown object
    External (_SB_.PCI0.LPCB.H_EC.PECL, UnknownObj)    // Warning: Unknown object
    External (_SB_.PCI0.LPCB.H_EC.PENV, UnknownObj)    // Warning: Unknown object
    External (_SB_.PCI0.LPCB.H_EC.PLMX, UnknownObj)    // Warning: Unknown object
    External (_SB_.PCI0.PEG0.PEGP.SGPO, MethodObj)    // Imported: 2 Arguments
    External (_SB_.PCI0.SAT0.SDSM, MethodObj)    // Imported: 4 Arguments
    External (_SB_.PCI0.SAT1.SDSM, MethodObj)    // Imported: 4 Arguments
    External (AC0F, FieldUnitObj)
    External (AC1F, FieldUnitObj)
    External (ACT1, FieldUnitObj)
    External (ACTT, FieldUnitObj)
    External (CRTT, FieldUnitObj)
    External (CTYP, FieldUnitObj)
    External (MDBG, MethodObj)    // Imported: 1 Arguments
    External (PSVT, FieldUnitObj)
    External (TC1V, FieldUnitObj)
    External (TC2V, FieldUnitObj)
    External (TCNT, FieldUnitObj)
    External (TSPV, FieldUnitObj)
    External (VFN0, FieldUnitObj)
    External (VFN1, FieldUnitObj)
    External (VFN2, FieldUnitObj)
    External (VFN3, FieldUnitObj)
    External (VFN4, FieldUnitObj)

    Scope (\_TZ)
    {
        Name (ETMD, One)
        Event (FCET)
        Name (FCRN, Zero)
        Mutex (FCMT, 0x00)
        Name (CVF0, Zero)
        Name (CVF1, Zero)
        Name (CVF2, Zero)
        Name (CVF3, Zero)
        Name (CVF4, Zero)
        Mutex (FMT0, 0x00)
        Mutex (FMT1, 0x00)
        Mutex (FMT2, 0x00)
        Mutex (FMT3, 0x00)
        Mutex (FMT4, 0x00)
        PowerResource (FN00, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Store (Zero, Local1)
                Store (Acquire (FMT0, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (CVF0, Local1)
                    Release (FMT0)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Store (Acquire (FMT0, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (One, CVF0)
                    Release (FMT0)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Store (Acquire (FMT0, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (Zero, CVF0)
                    Release (FMT0)
                }

                FNCL ()
            }
        }

        Device (FAN0)
        {
            Name (_HID, EisaId ("PNP0C0B"))  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN00
            })
        }

        PowerResource (FN01, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Store (Zero, Local1)
                Store (Acquire (FMT1, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (CVF1, Local1)
                    Release (FMT1)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Store (Acquire (FMT1, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (One, CVF1)
                    Release (FMT1)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Store (Acquire (FMT1, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (Zero, CVF1)
                    Release (FMT1)
                }

                FNCL ()
            }
        }

        Device (FAN1)
        {
            Name (_HID, EisaId ("PNP0C0B"))  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN01
            })
        }

        PowerResource (FN02, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Store (Zero, Local1)
                Store (Acquire (FMT2, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (CVF2, Local1)
                    Release (FMT2)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Store (Acquire (FMT2, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (One, CVF2)
                    Release (FMT2)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Store (Acquire (FMT2, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (Zero, CVF2)
                    Release (FMT2)
                }

                FNCL ()
            }
        }

        Device (FAN2)
        {
            Name (_HID, EisaId ("PNP0C0B"))  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN02
            })
        }

        PowerResource (FN03, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Store (Zero, Local1)
                Store (Acquire (FMT3, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (CVF3, Local1)
                    Release (FMT3)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Store (Acquire (FMT3, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (One, CVF3)
                    Release (FMT3)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Store (Acquire (FMT3, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (Zero, CVF3)
                    Release (FMT3)
                }

                FNCL ()
            }
        }

        Device (FAN3)
        {
            Name (_HID, EisaId ("PNP0C0B"))  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN03
            })
        }

        PowerResource (FN04, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Store (Zero, Local1)
                Store (Acquire (FMT4, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (CVF4, Local1)
                    Release (FMT4)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Store (Acquire (FMT4, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (One, CVF4)
                    Release (FMT4)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Store (Acquire (FMT4, 0x03E8), Local0)
                If (LEqual (Local0, Zero))
                {
                    Store (Zero, CVF4)
                    Release (FMT4)
                }

                FNCL ()
            }
        }

        Device (FAN4)
        {
            Name (_HID, EisaId ("PNP0C0B"))  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN04
            })
        }

        Method (FNCL, 0, NotSerialized)
        {
            Store (Acquire (FCMT, 0x03E8), Local5)
            If (LEqual (Local5, Zero))
            {
                Store (FCRN, Local6)
                Release (FCMT)
            }

            If (LNotEqual (Local6, Zero))
            {
                Signal (FCET)
                Return (Zero)
            }
            Else
            {
                Store (Acquire (FCMT, 0x03E8), Local5)
                If (LEqual (Local5, Zero))
                {
                    Store (One, FCRN)
                    Release (FCMT)
                }

                Store (Zero, Local5)
                While (LLess (Local5, 0x04))
                {
                    If (LNotEqual (Wait (FCET, 0x05), Zero))
                    {
                        Store (0x04, Local5)
                    }
                    Else
                    {
                        Increment (Local5)
                    }
                }

                Store (Acquire (FCMT, 0x03E8), Local5)
                If (LEqual (Local5, Zero))
                {
                    Store (Zero, FCRN)
                    Release (FCMT)
                }
            }

            Store (Zero, Local0)
            Store (Zero, Local1)
            Store (Zero, Local2)
            Store (Zero, Local3)
            Store (Zero, Local4)
            Store (Acquire (FMT0, 0x03E8), Local5)
            If (LEqual (Local5, Zero))
            {
                Store (CVF0, Local0)
                Release (FMT0)
            }

            Store (Acquire (FMT1, 0x03E8), Local5)
            If (LEqual (Local5, Zero))
            {
                Store (CVF1, Local1)
                Release (FMT1)
            }

            Store (Acquire (FMT2, 0x03E8), Local5)
            If (LEqual (Local5, Zero))
            {
                Store (CVF2, Local2)
                Release (FMT2)
            }

            Store (Acquire (FMT3, 0x03E8), Local5)
            If (LEqual (Local5, Zero))
            {
                Store (CVF3, Local3)
                Release (FMT3)
            }

            Store (Acquire (FMT4, 0x03E8), Local5)
            If (LEqual (Local5, Zero))
            {
                Store (CVF4, Local4)
                Release (FMT4)
            }

            Store (Local0, \VFN0)
            Store (Local1, \VFN1)
            Store (Local2, \VFN2)
            Store (Local3, \VFN3)
            Store (Local4, \VFN4)
            If (LAnd (\_SB.PCI0.LPCB.H_EC.ECAV, ETMD))
            {
                Store (Acquire (\_SB.PCI0.LPCB.H_EC.ECMT, 0x03E8), Local5)
                If (LEqual (Local5, Zero))
                {
                    If (LAnd (LNotEqual (Local0, Zero), LNotEqual (Local1, Zero)))
                    {
                        \_SB.PCI0.LPCB.H_EC.ECWT (AC0F, RefOf (\_SB.PCI0.LPCB.H_EC.PENV))
                    }
                    ElseIf (LAnd (LEqual (Local0, Zero), LNotEqual (Local1, Zero)))
                    {
                        \_SB.PCI0.LPCB.H_EC.ECWT (AC1F, RefOf (\_SB.PCI0.LPCB.H_EC.PENV))
                    }
                    Else
                    {
                        \_SB.PCI0.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PCI0.LPCB.H_EC.PENV))
                    }

                    \_SB.PCI0.LPCB.H_EC.ECMD (0x1A)
                    Release (\_SB.PCI0.LPCB.H_EC.ECMT)
                }
            }
        }

        ThermalZone (TZ00)
        {
            Name (PTMP, 0x0BB8)
            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
                Store (Arg0, \CTYP)
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                If (CondRefOf (\_PR.ACRT))
                {
                    If (LNotEqual (\_PR.ACRT, Zero))
                    {
                        Return (Add (0x0AAC, Multiply (\_PR.ACRT, 0x0A)))
                    }
                }

                Return (Add (0x0AAC, Multiply (\CRTT, 0x0A)))
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling
            {
                If (CondRefOf (\_PR.AAC0))
                {
                    If (LNotEqual (\_PR.AAC0, Zero))
                    {
                        Return (Add (0x0AAC, Multiply (\_PR.AAC0, 0x0A)))
                    }
                }

                Return (Add (0x0AAC, Multiply (\ACTT, 0x0A)))
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling
            {
                Return (Add (0x0AAC, Multiply (\ACT1, 0x0A)))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling
            {
                Return (Subtract (Add (0x0AAC, Multiply (\ACT1, 0x0A)), 0x32))
            }

            Method (_AC3, 0, Serialized)  // _ACx: Active Cooling
            {
                Return (Subtract (Add (0x0AAC, Multiply (\ACT1, 0x0A)), 0x64))
            }

            Method (_AC4, 0, Serialized)  // _ACx: Active Cooling
            {
                Return (Subtract (Add (0x0AAC, Multiply (\ACT1, 0x0A)), 0x96))
            }

            Name (_AL0, Package (0x01)  // _ALx: Active List
            {
                FAN0
            })
            Name (_AL1, Package (0x01)  // _ALx: Active List
            {
                FAN1
            })
            Name (_AL2, Package (0x01)  // _ALx: Active List
            {
                FAN2
            })
            Name (_AL3, Package (0x01)  // _ALx: Active List
            {
                FAN3
            })
            Name (_AL4, Package (0x01)  // _ALx: Active List
            {
                FAN4
            })
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (LNot (ETMD))
                {
                    Return (0x0BB8)
                }

                If (CondRefOf (\_PR.DTSE))
                {
                    If (LEqual (\_PR.DTSE, 0x03))
                    {
                        Return (Add (0x0B10, Multiply (\CRTT, 0x0A)))
                    }
                }

                If (CondRefOf (\_PR.DTSE))
                {
                    If (LEqual (\_PR.DTSE, One))
                    {
                        If (LEqual (\_PR.PKGA, One))
                        {
                            Store (\_PR.PDTS, Local0)
                            Return (Add (0x0AAC, Multiply (Local0, 0x0A)))
                        }

                        Store (\_PR.DTS1, Local0)
                        If (LGreater (\_PR.DTS2, Local0))
                        {
                            Store (\_PR.DTS2, Local0)
                        }

                        If (LGreater (\_PR.DTS3, Local0))
                        {
                            Store (\_PR.DTS3, Local0)
                        }

                        If (LGreater (\_PR.DTS4, Local0))
                        {
                            Store (\_PR.DTS4, Local0)
                        }

                        Return (Add (0x0AAC, Multiply (Local0, 0x0A)))
                    }
                }

                If (\_SB.PCI0.LPCB.H_EC.ECAV)
                {
                    Store (\_SB.PCI0.LPCB.H_EC.ECRD (RefOf (\_SB.PCI0.LPCB.H_EC.PLMX)), Local0)
                    Add (0x0AAC, Multiply (Local0, 0x0A), Local0)
                    Store (Local0, PTMP)
                    Return (Local0)
                }

                Return (0x0BC2)
            }
        }

        ThermalZone (TZ01)
        {
            Name (PTMP, 0x0BB8)
            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
                Store (Arg0, \CTYP)
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                If (CondRefOf (\_PR.ACRT))
                {
                    If (LNotEqual (\_PR.ACRT, Zero))
                    {
                        Return (Add (0x0AAC, Multiply (\_PR.ACRT, 0x0A)))
                    }
                }

                Return (Add (0x0AAC, Multiply (\CRTT, 0x0A)))
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (LNot (ETMD))
                {
                    Return (0x0BCC)
                }

                If (CondRefOf (\_PR.DTSE))
                {
                    If (LEqual (\_PR.DTSE, 0x03))
                    {
                        Return (Add (0x0B10, Multiply (\CRTT, 0x0A)))
                    }
                }

                If (CondRefOf (\_PR.DTSE))
                {
                    If (LEqual (\_PR.DTSE, One))
                    {
                        If (LEqual (\_PR.PKGA, One))
                        {
                            Store (\_PR.PDTS, Local0)
                            Return (Add (0x0AAC, Multiply (Local0, 0x0A)))
                        }

                        Store (\_PR.DTS1, Local0)
                        If (LGreater (\_PR.DTS2, Local0))
                        {
                            Store (\_PR.DTS2, Local0)
                        }

                        If (LGreater (\_PR.DTS3, Local0))
                        {
                            Store (\_PR.DTS3, Local0)
                        }

                        If (LGreater (\_PR.DTS4, Local0))
                        {
                            Store (\_PR.DTS4, Local0)
                        }

                        Return (Add (0x0AAC, Multiply (Local0, 0x0A)))
                    }
                }

                If (\_SB.PCI0.LPCB.H_EC.ECAV)
                {
                    Store (\_SB.PCI0.LPCB.H_EC.ECRD (RefOf (\_SB.PCI0.LPCB.H_EC.PECH)), Local0)
                    Multiply (Local0, 0x0A, Local0)
                    Store (\_SB.PCI0.LPCB.H_EC.ECRD (RefOf (\_SB.PCI0.LPCB.H_EC.PECL)), Local1)
                    ShiftRight (Local1, 0x02, Local1)
                    Store (Divide (Multiply (Local1, 0x0A), 0x40, ), Local1)
                    Add (Local0, Local1, Local0)
                    Add (0x0AAC, Local0, Local0)
                    Store (Local0, PTMP)
                    Return (Local0)
                }

                Return (0x0BD6)
            }

            Method (XPSL, 0, Serialized)
            {
                If (LEqual (\TCNT, 0x08))
                {
                    Return (Package (0x08)
                    {
                        \_PR.CPU0, 
                        \_PR.CPU1, 
                        \_PR.CPU2, 
                        \_PR.CPU3, 
                        \_PR.CPU4, 
                        \_PR.CPU5, 
                        \_PR.CPU6, 
                        \_PR.CPU7
                    })
                }

                If (LEqual (\TCNT, 0x04))
                {
                    Return (Package (0x04)
                    {
                        \_PR.CPU0, 
                        \_PR.CPU1, 
                        \_PR.CPU2, 
                        \_PR.CPU3
                    })
                }

                If (LEqual (\TCNT, 0x02))
                {
                    Return (Package (0x02)
                    {
                        \_PR.CPU0, 
                        \_PR.CPU1
                    })
                }

                Return (Package (0x01)
                {
                    \_PR.CPU0
                })
            }

            Method (XPSV, 0, Serialized)
            {
                If (CondRefOf (\_PR.APSV))
                {
                    If (LNotEqual (\_PR.APSV, Zero))
                    {
                        Return (Add (0x0AAC, Multiply (\_PR.APSV, 0x0A)))
                    }
                }

                Return (Add (0x0AAC, Multiply (\PSVT, 0x0A)))
            }

            Method (XTC1, 0, Serialized)
            {
                Return (\TC1V)
            }

            Method (XTC2, 0, Serialized)
            {
                Return (\TC2V)
            }

            Method (XTSP, 0, Serialized)
            {
                Return (\TSPV)
            }
        }
    }
}

