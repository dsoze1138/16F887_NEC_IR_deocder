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

For the PIC16F the pic-as assembler directive "MACRO" fails when parameters are present.

For the PIC16F the pic-as assembler directive "IF" does not work.

The MPASM assembler directive "BANKISEL" for the mid-range PIC16F (non-enhanced) 
can be replaced using the preprocessor macro:

`#define bankisel(x) dw 0x1383|((x&0x100)<<2)`

This requires that the parameter be enclosed in parentheses '()'