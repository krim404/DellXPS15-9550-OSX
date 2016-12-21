// Adding PNLF device for IntelBacklight.kext

//REVIEW: come up with table driven effort here...
#define SANDYIVY_PWMMAX 0x710
#define HASWELL_PWMMAX 0xad9

DefinitionBlock("", "SSDT", 2, "hack", "PNLF", 0)
{
    External(RMCF.BKLT, IntObj)
    External(RMCF.LMAX, IntObj)
    External(_SB.PCI0.IGPU.GDID, FieldUnitObj)
    External(_SB.PCI0.IGPU.BAR1, FieldUnitObj)
    External(_SB.PCI0.IGPU._DOS, MethodObj)

    // For backlight control
    Device(_SB.PNLF)
    {
        Name(_ADR, Zero)
        Name(_HID, EisaId ("APP0002"))
        Name(_CID, "backlight")
        Name(_UID, 15)
        Name(_STA, 0x0B)

                        //define hardware register access for brightness
                        // lower nibble of BAR1 is status bits and not part of the address
                        OperationRegion (BRIT, SystemMemory, And(\_SB.PCI0.IGPU.BAR1, Not(0xF)), 0xe1184)
                        Field (BRIT, AnyAcc, Lock, Preserve)
                        {
                            Offset(0x48250),
                            LEV2, 32,
                            LEVL, 32,
                            Offset(0x70040),
                            P0BL, 32,
                            Offset(0xc8250),
                            LEVW, 32,
                            LEVX, 32,
                            Offset(0xe1180),
                            PCHL, 32,
                        }
                        // LMAX: use 0xad9/0x56c/0x5db to force OS X value
                        //       or use any arbitrary value
                        //       or use 0 to capture BIOS setting
                        Name (LMAX, 0xad9)
                        // KMAX: defines the unscaled range in the _BCL table below
                        Name (KMAX, 0xad9)
                        // _INI deals with differences between native setting and desired
                        Method (_INI, 0, NotSerialized)
                        {
                            // This 0xC value comes from looking what OS X initializes this
                            // register to after display sleep (using ACPIDebug/ACPIPoller)
                            Store(0xC0000000, LEVW)
                            // determine LMAX to use
                            If (LNot(LMAX)) { Store(ShiftRight(LEVX,16), LMAX) }
                            If (LNot(LMAX)) { Store(KMAX, LMAX) }
                            If (LNotEqual(LMAX, KMAX))
                            {
                                // Scale all the values in _BCL to the PWM max in use
                                Store(0, Local0)
                                While (LLess(Local0, SizeOf(_BCL)))
                                {
                                    Store(DerefOf(Index(_BCL,Local0)), Local1)
                                    Divide(Multiply(Local1,LMAX), KMAX,, Local1)
                                    Store(Local1, Index(_BCL,Local0))
                                    Increment(Local0)
                                }
                                // Also scale XRGL and XRGH values
                                Divide(Multiply(XRGL,LMAX), KMAX,, XRGL)
                                Divide(Multiply(XRGH,LMAX), KMAX,, XRGH)
                            }
                            // adjust values to desired LMAX
                            Store(ShiftRight(LEVX,16), Local1)
                            If (LNotEqual(Local1, LMAX))
                            {
                                Store(And(LEVX,0xFFFF), Local0)
                                If (LOr(LNot(Local0),LNot(Local1))) { Store(LMAX, Local0) Store(LMAX, Local1) }
                                Divide(Multiply(Local0,LMAX), Local1,, Local0)
                                //REVIEW: wait for vblank before setting new PWM config
                                //Store(P0BL, Local7)
                                //While (LEqual (P0BL, Local7)) {}
                                Store(Or(Local0,ShiftLeft(LMAX,16)), LEVX)
                            }
                        }
                        // _BCM/_BQC: set/get for brightness level
                        Method (_BCM, 1, NotSerialized)
                        {
                            // store new backlight level
                            Store(Match(_BCL, MGE, Arg0, MTR, 0, 2), Local0)
                            If (LEqual(Local0, Ones)) { Subtract(SizeOf(_BCL), 1, Local0) }
                            Store(Or(DerefOf(Index(_BCL,Local0)),ShiftLeft(LMAX,16)), LEVX)
                        }
                        Method (_BQC, 0, NotSerialized)
                        {
                            Store(Match(_BCL, MGE, And(LEVX, 0xFFFF), MTR, 0, 2), Local0)
                            If (LEqual(Local0, Ones)) { Subtract(SizeOf(_BCL), 1, Local0) }
                            Return(DerefOf(Index(_BCL, Local0)))
                        }
                        Method (_DOS, 1, NotSerialized)
                        {
                            // Note: Some systems have this defined in DSDT, so uncomment
                            // the next line if that is the case.
                            //External(^^_DOS, MethodObj)
                            \_SB.PCI0.IGPU._DOS(Arg0)
                        }
                        // extended _BCM/_BQC for setting "in between" levels
                        Method (XBCM, 1, NotSerialized)
                        {
                            // store new backlight level
                            If (LGreater(Arg0, XRGH)) { Store(XRGH, Arg0) }
                            If (LAnd(Arg0, LLess(Arg0, XRGL))) { Store(XRGL, Arg0) }
                            Store(Or(Arg0,ShiftLeft(LMAX,16)), LEVX)
                        }
                        Method (XBQC, 0, NotSerialized)
                        {
                            Store(And(LEVX,0xFFFF), Local0)
                            If (LGreater(Local0, XRGH)) { Store(XRGH, Local0) }
                            If (LAnd(Local0, LLess(Local0, XRGL))) { Store(XRGL, Local0) }
                            Return(Local0)
                        }
                        // Set XOPT bit 0 to disable smooth transitions
                        // Set XOPT bit 1 to wait for native BacklightHandler
                        // Set XOPT bit 2 to force use of native BacklightHandler
                        Name (XOPT, 0x02)
                        // XRGL/XRGH: defines the valid range
                        Name (XRGL, 25)
                        Name (XRGH, 2777)
                        // _BCL: returns list of valid brightness levels
                        // first two entries describe ac/battery power levels
                        Name (_BCL, Package()
                        {
                            2777,
                            748,
                            0,
                            35, 39, 44, 50,
                            58, 67, 77, 88,
                            101, 115, 130, 147,
                            165, 184, 204, 226,
                            249, 273, 299, 326,
                            354, 383, 414, 446,
                            479, 514, 549, 587,
                            625, 665, 706, 748,
                            791, 836, 882, 930,
                            978, 1028, 1079, 1132,
                            1186, 1241, 1297, 1355,
                            1414, 1474, 1535, 1598,
                            1662, 1728, 1794, 1862,
                            1931, 2002, 2074, 2147,
                            2221, 2296, 2373, 2452,
                            2531, 2612, 2694, 2777,
                        })



    }
}
//EOF
