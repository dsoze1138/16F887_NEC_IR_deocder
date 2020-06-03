        list    c=250   ; support long lines in list file
        radix   dec
;
; Include Special Function Register definitions
;
#include <xc.inc>
; -------------------------
; Main application
; -------------------------
#ifndef MAIN_INC
#define MAIN_INC
;
; Declare the public symbols
;
    global   main
;
;
; Define macros to help with
; bank selection
;
#define BANK0  (0x000)
#define BANK1  (0x080)
#define BANK2  (0x100)
#define BANK3  (0x180)

#endif