// An alternate USB-hotplug interrupt method that is non-recursive - dpassmor

DefinitionBlock ("", "SSDT", 1, "hack", "XE42", 0)
{
    External (_GPE.WWAK, MethodObj)
    External (_GPE.WSUB, MethodObj)
    External (_GPE.PGWA, MethodObj)
    External (_GPE.RSMI, MethodObj)
    External (_GPE.DMSI, MethodObj)
    External (_GPE.GNIS, MethodObj)
    External (_GPE.PGWA, MethodObj)
    External (_GPE.TBUF, MethodObj)
    External (_GPE.NTFY, MethodObj)
    External (_GPE.TBFF, MethodObj)
    External (ADBG, MethodObj)
    External (\_SB_.CAGS, MethodObj)
    External (P8XH, MethodObj)
    External (TNAT, FieldUnitObj)
    External (CF2T, FieldUnitObj)
    External (DPTF, FieldUnitObj)
    External (CPGN, FieldUnitObj)
    External (SOHP, FieldUnitObj)
    External (TBSW, FieldUnitObj)
    External (OSUM, MutexObj)
    
    Scope (\_GPE)
    {
        Method (XE42, 0, NotSerialized)  // _Exx: Edge-Triggered GPE
        {
            Return (Zero)
            ADBG ("_E42")
            If (LEqual (CF2T, One))
            {
                ADBG ("Clear")
                ADBG ("GPI_GPE_STS")
                \_SB.CAGS (CPGN)
            }

            WWAK ()
            WSUB ()
            If (LEqual (TNAT, One))
            {
                Store (RSMI (), Local0)
                If (LNot (Local0))
                {
                    Return (Zero)
                }

                If (DMSI ())
                {
                    Return (Zero)
                }
            }

            If (GNIS ())
            {
                Return (Zero)
            }

            OperationRegion (SPRT, SystemIO, 0xB2, 0x02)
            Field (SPRT, ByteAcc, Lock, Preserve)
            {
                SSMP,   8
            }

            ADBG ("TBT-HP-Handler")
            ADBG ("PEG WorkAround")
            PGWA ()
            Acquire (OSUM, 0xFFFF)
            Store (TBFF (), Local1)
            If (LEqual (Local1, One))
            {
                Sleep (0x10)
                Release (OSUM)
                ADBG ("OS_Up_Received")
                If (LEqual (DPTF, One))
                {
                    XE42 ()
                }

                Return (Zero)
            }

            If (LEqual (Local1, 0x02))
            {
                NTFY ()
                Sleep (0x10)
                Release (OSUM)
                P8XH (Zero, 0x7D)
                ADBG ("Disconnect")
                Return (Zero)
            }

            If (LEqual (SOHP, One))
            {
                ADBG ("TBT SW SMI")
                Store (TBSW, SSMP)
            }

            NTFY ()
            Sleep (0x10)
            Release (OSUM)
            ADBG ("End-of-_E42")
        }
    }
}