        list    n=0, c=250  ; No page breaks, support long lines in list file
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