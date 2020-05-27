        list    p=16F887	; Select PIC16F887 as target device
        list    n=0, c=250	; No page breaks, support long lines in list file
        list    r=dec
        errorlevel -302         ; Suppress not in bank zero warning
;
; Include Special Function Register definitions
;
#include "p16f887.inc"
; -------------------------
; Main application
; -------------------------
#ifndef MAIN_INC
#define MAIN_INC
#ifdef  MAIN_ASM
#define ExtSymbol   global
;
; PIC16F887 Configuration Bit Settings
; Assembly source line config statements
;
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_ON & _FCMEN_OFF & _LVP_OFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   main
;
; end of public symbols
#undefine ExtSymbol

;
; Define macros to help with
; bank selection
;
#define BANK0  (h'000')
#define BANK1  (h'080')
#define BANK2  (h'100')
#define BANK3  (h'180')

#endif