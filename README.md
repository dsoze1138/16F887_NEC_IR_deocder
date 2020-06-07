PIC16F887 NEC IR Remote decoder app
===================================

MPLABX v5.35 PIC assembly language code that runs on the Microchip PICDEM2 Plus (DM163022-1) 

http://www.microchip.com/Developmenttools/ProductDetails.aspx?PartNO=DM163022-1

The application implements a protocol decoder for an NEC Infrared Remote control transmitter.

This code was posted as an answer to a question posted on StackOverfolw.

See: https://stackoverflow.com/questions/61987319/ir-receiver-with-pic16f887-assembly-language

=========================================

I am using this project as a test for porting an MPASM project to pic-as(v2.20)

Issues found so far:

When MPLABX v5.40 builds non-PIC18F targets with the pis-as(v2.20) tool chain it asserts this message: 

`::: warning: (1428) "-misa=std" is not supported; this feature will be ignored`

The `"-misa=std"` option is supported only for PIC18F controller targets.

The preprocessor macro `#if` and the assembler directive `IF` accept only absolute 
expressions. Relocatable expression that are resolved by the linker such as the 
argument for the MPASM `BANKISEL` directive cannot be used in these expressions.

The MPASM assembler directive `BANKISEL` for the mid-range PIC16F (non-enhanced) 
can be replaced using the preprocessor macro: `#define bankisel(Address) dw 0x1383|((Address&0x100)<<2)`
This requires that the parameter be enclosed in parentheses `()`.

Or this pis-as(v2.20) assembler `MACRO`:

    bankisel MACRO arg1
        dw   0x1383|((arg1 and 0x100) shl 2)
      ENDM

This does not require that the parameter be enclosed in parentheses.