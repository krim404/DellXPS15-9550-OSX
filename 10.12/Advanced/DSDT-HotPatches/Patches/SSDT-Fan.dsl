/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20160422-64(RM)
 * Copyright (c) 2000 - 2016 Intel Corporation
 * 
 * Disassembling to non-symbolic legacy ASL operators
 *
 * Disassembly of iASLyAMAcy.aml, Sun Apr  9 10:02:12 2017
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000B9 (185)
 *     Revision         0x01
 *     Checksum         0xD7
 *     OEM ID           "APPLE "
 *     OEM Table ID     "DefMon"
 *     OEM Revision     0x00003000 (12288)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20160422 (538313762)
 */
DefinitionBlock ("", "SSDT", 1, "APPLE ", "DefMon", 0x00003000)
{
    External (_SB_.PCI0.LPCB.ECDV.KDRT, MethodObj)    // 1 Arguments (from opcode)

    Device (_SB.PCI0.LPCB.MON0)
    {
        Name (_HID, EisaId ("PNP0C02"))  // _HID: Hardware ID
        Name (_CID, "MON00000")  // _CID: Compatible ID
        Name (TACH, Package (0x02)
        {
            "System Fan 0", 
            "FAN0"
        })
        Method (FAN0, 0, NotSerialized)
        {
            Store (\_SB.PCI0.LPCB.ECDV.KDRT (0x02), Local0)
            Return (Add (0x07D0, Multiply (Local0, 0x0A)))
        }
    }
}

