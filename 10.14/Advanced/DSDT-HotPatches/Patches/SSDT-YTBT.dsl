//
// SSDT-YTBT.dsl
//
// Dell XPS 15 9560
//
// This SSDT fixes an ACPI recursion that breaks Type-C hot plug.
//
// Credit to dpassmor:
// https://www.tonymacx86.com/threads/usb-c-hotplug-questions.211313/
//
DefinitionBlock ("", "SSDT", 2, "hack", "YTBT", 0x00000000)
{
    Scope (\_GPE)
    {
        Method (YTBT, 2, NotSerialized)
        {
            If (LEqual (Arg0, Arg1))
            {
                Return (Zero)
            }
            Else
            {
                Return (Zero)
            }
        }
    }
}

