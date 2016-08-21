/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160422-64(RM)
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to non-symbolic legacy ASL operators
 *
 * Disassembly of SSDT-8.aml, Sun Aug 21 12:50:52 2016
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000E73 (3699)
 *     Revision         0x02
 *     Checksum         0x0F
 *     OEM ID           "CpuRef"
 *     OEM Table ID     "CpuSsdt"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20120913 (538052883)
 */
DefinitionBlock ("", "SSDT", 2, "CpuRef", "CpuSsdt", 0x00003000)
{
    /*
     * External declarations were imported from
     * a reference file -- refs.txt
     */

    External (_GPE.MMTB, MethodObj)    // Imported: 0 Arguments
    External (_GPE.VHOV, MethodObj)    // Imported: 3 Arguments
    External (_PR_.CPU0, ProcessorObj)
    External (_PR_.CPU1, ProcessorObj)
    External (_PR_.CPU2, ProcessorObj)
    External (_PR_.CPU3, ProcessorObj)
    External (_PR_.CPU4, ProcessorObj)
    External (_PR_.CPU5, ProcessorObj)
    External (_PR_.CPU6, ProcessorObj)
    External (_PR_.CPU7, ProcessorObj)
    External (_SB_.OSCP, IntObj)
    External (_SB_.PCI0.IGPU.DD02._BCM, MethodObj)    // Imported: 1 Arguments
    External (_SB_.PCI0.LPCB.H_EC.ECRD, MethodObj)    // Imported: 1 Arguments
    External (_SB_.PCI0.LPCB.H_EC.ECWT, MethodObj)    // Imported: 2 Arguments
    External (_SB_.PCI0.PEG0.PEGP.SGPO, MethodObj)    // Imported: 2 Arguments
    External (_SB_.PCI0.SAT0.SDSM, MethodObj)    // Imported: 4 Arguments
    External (_SB_.PCI0.SAT1.SDSM, MethodObj)    // Imported: 4 Arguments
    External (MDBG, MethodObj)    // Imported: 1 Arguments
    External (OSYS, FieldUnitObj)

    Scope (\)
    {
        Name (SSDT, Package (0x15)
        {
            "CPU0IST ", 
            0x376BF698, 
            0x000005DC, 
            "APIST   ", 
            0x376BE618, 
            0x000005AA, 
            "CPU0CST ", 
            0x376BEC18, 
            0x0000037F, 
            "APCST   ", 
            0x3770FC18, 
            0x00000119, 
            "CPU0HWP ", 
            0x35A53318, 
            0x0000008E, 
            "APHWP   ", 
            0x35BC0318, 
            0x00000119, 
            "HWPLVT  ", 
            0x35BC0198, 
            0x00000130
        })
        Name (\PDC0, 0x80000000)
        Name (\PDC1, 0x80000000)
        Name (\PDC2, 0x80000000)
        Name (\PDC3, 0x80000000)
        Name (\PDC4, 0x80000000)
        Name (\PDC5, 0x80000000)
        Name (\PDC6, 0x80000000)
        Name (\PDC7, 0x80000000)
        Name (\SDTL, Zero)
    }

    Scope (\_PR)
    {
        Name (CTPC, Zero)
        OperationRegion (PNVS, SystemMemory, 0x29C8D000, 0x006C)
        Field (PNVS, AnyAcc, Lock, Preserve)
        {
            PGRV,   8, 
            CFGD,   32, 
            Offset (0x06), 
            ACRT,   8, 
            APSV,   8, 
            AAC0,   8, 
            CPID,   32, 
            CPPC,   8, 
            CCTP,   8, 
            CLVL,   8, 
            CBMI,   8, 
            PL10,   16, 
            PL20,   16, 
            PLW0,   8, 
            CTC0,   8, 
            TAR0,   8, 
            PPC0,   8, 
            PL11,   16, 
            PL21,   16, 
            PLW1,   8, 
            CTC1,   8, 
            TAR1,   8, 
            PPC1,   8, 
            PL12,   16, 
            PL22,   16, 
            PLW2,   8, 
            CTC2,   8, 
            TAR2,   8, 
            PPC2,   8, 
            C3MW,   8, 
            C6MW,   8, 
            C7MW,   8, 
            CDMW,   8, 
            C3LT,   16, 
            C6LT,   16, 
            C7LT,   16, 
            CDLT,   16, 
            CDLV,   16, 
            CDPW,   16, 
            MPMF,   8, 
            DTSE,   8, 
            DTS1,   8, 
            DTS2,   8, 
            DTSF,   8, 
            PDTS,   8, 
            PKGA,   8, 
            DTS3,   8, 
            DTS4,   8, 
            BGMA,   64, 
            BGMS,   8, 
            BGIA,   16, 
            BGIL,   16, 
            DSIA,   16, 
            DSIL,   8, 
            DSAE,   8, 
            EPCS,   8, 
            EMNA,   64, 
            ELNG,   64, 
            HWPV,   8, 
            HWPA,   16, 
            HWPL,   16, 
            POWS,   8, 
            HDCE,   8, 
            HWPI,   8
        }

        OperationRegion (IO_D, SystemIO, \_PR.DSIA, \_PR.DSIL)
        Field (IO_D, ByteAcc, NoLock, Preserve)
        {
            TRPD,   8
        }

        OperationRegion (IO_P, SystemIO, \_PR.BGIA, \_PR.BGIL)
        Field (IO_P, ByteAcc, NoLock, Preserve)
        {
            TRPF,   8
        }
    }

    Scope (\_PR.CPU0)
    {
        Name (HI0, Zero)
        Name (HC0, Zero)
        Name (HW0, Zero)
        Name (HW2, Zero)
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            Store (CPDC (Arg0), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            Store (COSC (Arg0, Arg1, Arg2, Arg3), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (CPDC, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, REVS)
            CreateDWordField (Arg0, 0x04, SIZE)
            Store (SizeOf (Arg0), Local0)
            Store (Subtract (Local0, 0x08), Local1)
            CreateField (Arg0, 0x40, Multiply (Local1, 0x08), TEMP)
            Name (STS0, Buffer (0x04)
            {
                 0x00, 0x00, 0x00, 0x00                         
            })
            Concatenate (STS0, TEMP, Local2)
            Return (COSC (ToUUID ("4077a616-290c-47be-9ebd-d87058713953"), REVS, SIZE, Local2))
        }

        Method (COSC, 4, NotSerialized)
        {
            CreateDWordField (Arg3, Zero, STS0)
            CreateDWordField (Arg3, 0x04, CAP0)
            CreateDWordField (Arg0, Zero, IID0)
            CreateDWordField (Arg0, 0x04, IID1)
            CreateDWordField (Arg0, 0x08, IID2)
            CreateDWordField (Arg0, 0x0C, IID3)
            Name (UID0, ToUUID ("4077a616-290c-47be-9ebd-d87058713953"))
            CreateDWordField (UID0, Zero, EID0)
            CreateDWordField (UID0, 0x04, EID1)
            CreateDWordField (UID0, 0x08, EID2)
            CreateDWordField (UID0, 0x0C, EID3)
            If (LNot (LAnd (LAnd (LEqual (IID0, EID0), LEqual (IID1, EID1)), LAnd (LEqual (IID2, EID2), LEqual (IID3, EID3)))))
            {
                Store (0x06, STS0)
                Return (Arg3)
            }

            If (LNotEqual (Arg1, One))
            {
                Store (0x0A, STS0)
                Return (Arg3)
            }

            If (Not (And (STS0, One)))
            {
                If (And (CAP0, 0x2000))
                {
                    Store (Zero, \_PR.HDCE)
                }
                Else
                {
                    OperationRegion (SMIP, SystemIO, 0xB2, One)
                    Field (SMIP, ByteAcc, NoLock, Preserve)
                    {
                        IOB2,   8
                    }

                    Store (0x28, IOB2)
                }
            }

            Return (Arg3)
        }

        Method (GCAP, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, STS0)
            CreateDWordField (Arg0, 0x04, CAP0)
            If (LOr (LEqual (STS0, 0x06), LEqual (STS0, 0x0A)))
            {
                Return (Zero)
            }

            If (And (STS0, One))
            {
                And (CAP0, 0x0BFF, CAP0)
                Return (Zero)
            }

            Or (And (PDC0, 0x7FFFFFFF), CAP0, PDC0)
            If (And (CFGD, 0x7A))
            {
                If (LAnd (LAnd (And (CFGD, 0x0200), And (PDC0, 0x18)), LNot (And (SDTL, 0x02))))
                {
                    Or (SDTL, 0x02, SDTL)
                    OperationRegion (CST0, SystemMemory, DerefOf (Index (SSDT, 0x07)), DerefOf (Index (SSDT, 0x08)))
                    Load (CST0, HC0)
                }
            }

            If (LAnd (And (CFGD, One), LNot (And (SDTL, 0x08))))
            {
                Or (SDTL, 0x08, SDTL)
                OperationRegion (IST0, SystemMemory, DerefOf (Index (SSDT, One)), DerefOf (Index (SSDT, 0x02)))
                Load (IST0, HI0)
            }

            If (LEqual (OSYS, 0x07DF))
            {
                If (LAnd (And (CFGD, 0x00400000), LNot (And (SDTL, 0x40))))
                {
                    If (And (\_SB.OSCP, 0x20))
                    {
                        Or (SDTL, 0x40, SDTL)
                        OperationRegion (HWP0, SystemMemory, DerefOf (Index (SSDT, 0x0D)), DerefOf (Index (SSDT, 0x0E)))
                        Load (HWP0, HW0)
                        If (And (CFGD, 0x00800000))
                        {
                            OperationRegion (HWPL, SystemMemory, DerefOf (Index (SSDT, 0x13)), DerefOf (Index (SSDT, 0x14)))
                            Load (HWPL, HW2)
                        }
                    }

                    If (And (\_SB.OSCP, 0x20))
                    {
                        If (LNot (And (\_SB.OSCP, 0x40)))
                        {
                            Store (Zero, HWPV)
                        }
                    }

                    If (And (\_SB.OSCP, 0x40))
                    {
                        Store (0x02, HWPV)
                    }
                }
            }

            If (LNot (And (PDC0, 0x1000)))
            {
                OperationRegion (SMIP, SystemIO, 0xB2, One)
                Field (SMIP, ByteAcc, NoLock, Preserve)
                {
                    IOB2,   8
                }

                Store (0x27, IOB2)
            }

            Return (Zero)
        }
    }

    Scope (\_PR.CPU1)
    {
        Name (HI1, Zero)
        Name (HC1, Zero)
        Name (HW1, Zero)
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            Store (\_PR.CPU0.CPDC (Arg0), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            Store (\_PR.CPU0.COSC (Arg0, Arg1, Arg2, Arg3), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (GCAP, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, STS1)
            CreateDWordField (Arg0, 0x04, CAP1)
            If (LOr (LEqual (STS1, 0x06), LEqual (STS1, 0x0A)))
            {
                Return (Zero)
            }

            If (And (STS1, One))
            {
                And (CAP1, 0x0BFF, CAP1)
                Return (Zero)
            }

            Or (And (PDC1, 0x7FFFFFFF), CAP1, PDC1)
            If (LEqual (And (PDC1, 0x09), 0x09))
            {
                APPT ()
            }

            If (And (\_SB.OSCP, 0x20))
            {
                HWPT ()
            }

            If (And (PDC1, 0x18))
            {
                APCT ()
            }

            Store (PDC1, PDC0)
            Return (Zero)
        }

        Method (APCT, 0, NotSerialized)
        {
            If (LAnd (And (CFGD, 0x7A), LNot (And (SDTL, 0x20))))
            {
                Or (SDTL, 0x20, SDTL)
                OperationRegion (CST1, SystemMemory, DerefOf (Index (SSDT, 0x0A)), DerefOf (Index (SSDT, 0x0B)))
                Load (CST1, HC1)
            }
        }

        Method (APPT, 0, NotSerialized)
        {
            If (LAnd (And (CFGD, One), LNot (And (SDTL, 0x10))))
            {
                Or (SDTL, 0x10, SDTL)
                OperationRegion (IST1, SystemMemory, DerefOf (Index (SSDT, 0x04)), DerefOf (Index (SSDT, 0x05)))
                Load (IST1, HI1)
            }
        }

        Method (HWPT, 0, NotSerialized)
        {
            If (LEqual (OSYS, 0x07DF))
            {
                If (LAnd (And (CFGD, 0x00400000), LNot (And (SDTL, 0x80))))
                {
                    Or (SDTL, 0x80, SDTL)
                    OperationRegion (HWP1, SystemMemory, DerefOf (Index (SSDT, 0x10)), DerefOf (Index (SSDT, 0x11)))
                    Load (HWP1, HW1)
                }
            }
        }
    }

    Scope (\_PR.CPU2)
    {
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            Store (\_PR.CPU0.CPDC (Arg0), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            Store (\_PR.CPU0.COSC (Arg0, Arg1, Arg2, Arg3), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (GCAP, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, STS2)
            CreateDWordField (Arg0, 0x04, CAP2)
            If (LOr (LEqual (STS2, 0x06), LEqual (STS2, 0x0A)))
            {
                Return (Zero)
            }

            If (And (STS2, One))
            {
                And (CAP2, 0x0BFF, CAP2)
                Return (Zero)
            }

            Or (And (PDC2, 0x7FFFFFFF), CAP2, PDC2)
            If (LEqual (And (PDC2, 0x09), 0x09))
            {
                \_PR.CPU1.APPT ()
            }

            If (And (\_SB.OSCP, 0x20))
            {
                \_PR.CPU1.HWPT ()
            }

            If (And (PDC2, 0x18))
            {
                \_PR.CPU1.APCT ()
            }

            Store (PDC2, PDC0)
            Return (Zero)
        }
    }

    Scope (\_PR.CPU3)
    {
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            Store (\_PR.CPU0.CPDC (Arg0), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            Store (\_PR.CPU0.COSC (Arg0, Arg1, Arg2, Arg3), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (GCAP, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, STS3)
            CreateDWordField (Arg0, 0x04, CAP3)
            If (LOr (LEqual (STS3, 0x06), LEqual (STS3, 0x0A)))
            {
                Return (Zero)
            }

            If (And (STS3, One))
            {
                And (CAP3, 0x0BFF, CAP3)
                Return (Zero)
            }

            Or (And (PDC3, 0x7FFFFFFF), CAP3, PDC3)
            If (LEqual (And (PDC3, 0x09), 0x09))
            {
                \_PR.CPU1.APPT ()
            }

            If (And (\_SB.OSCP, 0x20))
            {
                \_PR.CPU1.HWPT ()
            }

            If (And (PDC3, 0x18))
            {
                \_PR.CPU1.APCT ()
            }

            Store (PDC3, PDC0)
            Return (Zero)
        }
    }

    Scope (\_PR.CPU4)
    {
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            Store (\_PR.CPU0.CPDC (Arg0), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            Store (\_PR.CPU0.COSC (Arg0, Arg1, Arg2, Arg3), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (GCAP, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, STS4)
            CreateDWordField (Arg0, 0x04, CAP4)
            If (LOr (LEqual (STS4, 0x06), LEqual (STS4, 0x0A)))
            {
                Return (Zero)
            }

            If (And (STS4, One))
            {
                And (CAP4, 0x0BFF, CAP4)
                Return (Zero)
            }

            Or (And (PDC4, 0x7FFFFFFF), CAP4, PDC4)
            If (LEqual (And (PDC4, 0x09), 0x09))
            {
                \_PR.CPU1.APPT ()
            }

            If (And (\_SB.OSCP, 0x20))
            {
                \_PR.CPU1.HWPT ()
            }

            If (And (PDC4, 0x18))
            {
                \_PR.CPU1.APCT ()
            }

            Store (PDC4, PDC0)
            Return (Zero)
        }
    }

    Scope (\_PR.CPU5)
    {
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            Store (\_PR.CPU0.CPDC (Arg0), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            Store (\_PR.CPU0.COSC (Arg0, Arg1, Arg2, Arg3), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (GCAP, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, STS5)
            CreateDWordField (Arg0, 0x04, CAP5)
            If (LOr (LEqual (STS5, 0x06), LEqual (STS5, 0x0A)))
            {
                Return (Zero)
            }

            If (And (STS5, One))
            {
                And (CAP5, 0x0BFF, CAP5)
                Return (Zero)
            }

            Or (And (PDC5, 0x7FFFFFFF), CAP5, PDC5)
            If (LEqual (And (PDC5, 0x09), 0x09))
            {
                \_PR.CPU1.APPT ()
            }

            If (And (\_SB.OSCP, 0x20))
            {
                \_PR.CPU1.HWPT ()
            }

            If (And (PDC5, 0x18))
            {
                \_PR.CPU1.APCT ()
            }

            Store (PDC5, PDC0)
            Return (Zero)
        }
    }

    Scope (\_PR.CPU6)
    {
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            Store (\_PR.CPU0.CPDC (Arg0), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            Store (\_PR.CPU0.COSC (Arg0, Arg1, Arg2, Arg3), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (GCAP, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, STS6)
            CreateDWordField (Arg0, 0x04, CAP6)
            If (LOr (LEqual (STS6, 0x06), LEqual (STS6, 0x0A)))
            {
                Return (Zero)
            }

            If (And (STS6, One))
            {
                And (CAP6, 0x0BFF, CAP6)
                Return (Zero)
            }

            Or (And (PDC6, 0x7FFFFFFF), CAP6, PDC6)
            If (LEqual (And (PDC6, 0x09), 0x09))
            {
                \_PR.CPU1.APPT ()
            }

            If (And (\_SB.OSCP, 0x20))
            {
                \_PR.CPU1.HWPT ()
            }

            If (And (PDC6, 0x18))
            {
                \_PR.CPU1.APCT ()
            }

            Store (PDC6, PDC0)
            Return (Zero)
        }
    }

    Scope (\_PR.CPU7)
    {
        Method (_PDC, 1, NotSerialized)  // _PDC: Processor Driver Capabilities
        {
            Store (\_PR.CPU0.CPDC (Arg0), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (_OSC, 4, NotSerialized)  // _OSC: Operating System Capabilities
        {
            Store (\_PR.CPU0.COSC (Arg0, Arg1, Arg2, Arg3), Local0)
            GCAP (Local0)
            Return (Local0)
        }

        Method (GCAP, 1, NotSerialized)
        {
            CreateDWordField (Arg0, Zero, STS7)
            CreateDWordField (Arg0, 0x04, CAP7)
            If (LOr (LEqual (STS7, 0x06), LEqual (STS7, 0x0A)))
            {
                Return (Zero)
            }

            If (And (STS7, One))
            {
                And (CAP7, 0x0BFF, CAP7)
                Return (Zero)
            }

            Or (And (PDC7, 0x7FFFFFFF), CAP7, PDC7)
            If (LEqual (And (PDC7, 0x09), 0x09))
            {
                \_PR.CPU1.APPT ()
            }

            If (And (\_SB.OSCP, 0x20))
            {
                \_PR.CPU1.HWPT ()
            }

            If (And (PDC7, 0x18))
            {
                \_PR.CPU1.APCT ()
            }

            Store (PDC7, PDC0)
            Return (Zero)
        }
    }
}

