// For solving instant wake by hooking GPRW or UPRW

DefinitionBlock ("", "SSDT", 2, "hack", "UPRW", 0x00000000)
{
    External (YPRW, MethodObj)    // 2 Arguments (from opcode)

    Scope (\)
    {
        Method (GPRW, 2, NotSerialized)
        {
            If (LEqual (0x6D, Arg0))
            {
                Return (Package (0x02)
                {
                    0x6D, 
                    Zero
                })
            }

            Return (\YPRW (Arg0, Arg1))
        }

        Method (UPRW, 0, NotSerialized)
        {
            Return (Zero)
        }
    }
}

