/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160422-64(RM)
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to non-symbolic legacy ASL operators
 *
 * Disassembly of SSDT-17.aml, Wed Aug 24 19:47:04 2016
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000C3 (195)
 *     Revision         0x02
 *     Checksum         0xD5
 *     OEM ID           "SgRef"
 *     OEM Table ID     "SgPeg"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20120913 (538052883)
 */
DefinitionBlock ("", "SSDT", 2, "SgRef", "SgPeg", 0x00001000)
{
    /*
     * External declarations were imported from
     * a reference file -- refs.txt
     */

    External (_GPE.MMTB, MethodObj)    // Imported: 0 Arguments
    External (_GPE.VHOV, MethodObj)    // Imported: 3 Arguments
    External (_SB_.GGIV, MethodObj)    // 1 Arguments
    External (_SB_.PCI0.GFX0.DD02._BCM, MethodObj)    // Imported: 1 Arguments
    External (_SB_.PCI0.LPCB.H_EC.ECRD, MethodObj)    // Imported: 1 Arguments
    External (_SB_.PCI0.LPCB.H_EC.ECWT, MethodObj)    // Imported: 2 Arguments
    External (_SB_.PCI0.PEG0.PEGP, DeviceObj)
    External (_SB_.PCI0.PEG0.PEGP.PVID, FieldUnitObj)
    External (_SB_.PCI0.PEG0.PEGP.SGPO, MethodObj)    // Imported: 2 Arguments
    External (_SB_.PCI0.SAT0.SDSM, MethodObj)    // Imported: 4 Arguments
    External (_SB_.PCI0.SAT1.SDSM, MethodObj)    // Imported: 4 Arguments
    External (_SB_.SGOV, MethodObj)    // 2 Arguments
    External (MDBG, MethodObj)    // Imported: 1 Arguments
    External (SGGP, FieldUnitObj)
    External (SGMD, FieldUnitObj)

    Scope (\_SB.PCI0.PEG0.PEGP)
    {
        Method (SGPO, 2, Serialized)
        {
            If (LEqual (SGGP, One))
            {
                If (CondRefOf (\_SB.SGOV))
                {
                    \_SB.SGOV (Arg0, Arg1)
                }
            }
        }

        Method (SGST, 0, Serialized)
        {
            If (And (SGMD, 0x0F))
            {
                If (LNotEqual (SGGP, One))
                {
                    Return (0x0F)
                }

                Return (Zero)
            }

            If (LNotEqual (PVID, 0xFFFF))
            {
                Return (0x0F)
            }

            Return (Zero)
        }

        Method (SGPI, 1, Serialized)
        {
            Store (Zero, Local0)
            If (LEqual (SGGP, One))
            {
                If (CondRefOf (\_SB.GGIV))
                {
                    Store (\_SB.GGIV (Arg0), Local0)
                }
            }

            Return (Local0)
        }
    }
}

