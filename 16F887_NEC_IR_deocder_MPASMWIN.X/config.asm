;
; Include Special Function Register definitions
;
#include "p16f887.inc"
;
; PIC16F887 Configuration Bit Settings
; Assembly source line config statements
;
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_ON & _FCMEN_OFF & _LVP_OFF
 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
    end
