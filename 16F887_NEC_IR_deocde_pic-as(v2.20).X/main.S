; -------------------------
; NEC IR Remote decoder app
; -------------------------
;
#include "main.inc"
#include "lcd.inc"
;
; PIC16F887 Configuration Bit Settings
; Assembly source line config statements
;
 config FOSC = INTRC_NOCLKOUT, WDTE = OFF, PWRTE = OFF, MCLRE = ON, CP = OFF, CPD = OFF, BOREN = OFF, IESO = ON, FCMEN = OFF, LVP = OFF
 config BOR4V = BOR21V, WRT = OFF
;
; File:     main.asm
; Date:     2020-05-23
; Target:   PIC16F887
; Author:   dan1138
;
; Description:
;   Decoder for NEC Infrared Remote control protocol.
;
;   Physical transport:
;       Long flash  (> 8ms)
;       Pause       (COMMAND event when pause is more than 4ms), 
;                   (REPEAT event when pause is less than 4ms but greater than 2ms)
;       Short flash (0.5 to 0.6ms)
;
;     When a COMMAND is sent this repeats 32 times:
;       Pause       DATA is one when pause is more than 1ms, else DATA is zero.
;       Short flash (0.5 to 0.6ms)
;
;   The repeat period is 100ms. This is the first period where 50Hz and 60Hz
;   power line frequencies have a common zero crossing node.
;
;
; See: https://stackoverflow.com/questions/61987319/ir-receiver-with-pic16f887-assembly-language
;
;                         PIC16F887
;                 +----------:_:----------+
;       VPP ->  1 : RE3/MCLR/VPP  PGD/RB7 : 40 <> PGD
;           <>  2 : RA0/AN0       PGC/RB6 : 39 <> PGC
;           <>  3 : RA1/AN1      AN13/RB5 : 38 <>
;           <>  4 : RA2/AN2      AN11/RB4 : 37 <>
;           <>  5 : RA3/AN3   PGM/AN9/RB3 : 36 <> 
;           <>  6 : RA4/T0CKI     AN8/RB2 : 35 <> 
;           <>  7 : RA5/AN4      AN10/RB1 : 34 <> 
;           <>  8 : RE0/AN5  INT/AN12/RB0 : 33 <- IR_RECEIVERn
;           <>  9 : RE1/AN6           VDD : 32 <- 5v0
;           <> 10 : RE2/AN7           VSS : 31 <- GND
;       5v0 -> 11 : VDD               RD7 : 30 -> LCD_ON
;       GND -> 12 : VSS               RD6 : 29 -> LCD_E
;           -> 13 : RA7/OSC1          RD5 : 28 -> LCD_RW
;           <- 14 : RA6/OSC2          RD4 : 27 -> LCD_RS
;           <> 15 : RC0/SOSCO   RX/DT/RC7 : 26 <>    
;           <> 16 : RC1/SOSCI   TX/CK/RC6 : 25 <>    
;           <> 17 : RC2/CCP1          RC5 : 24 <>
;           <> 18 : RC3/SCL       SDA/RC4 : 23 <>    
;    LCD_D4 <> 19 : RD0               RD3 : 22 <> LCD_D7
;    LCD_D5 <> 20 : RD1               RD2 : 21 <> LCD_D6
;                 +-----------------------:
;                          DIP-40
;
; Power on reset vector
;
    psect   ResetVector,abs,local,class=CODE,delta=2
    org     0x0000
POReset:
    pagesel START
    GOTO    START               ; go to beginning of program
;
; Interrupt context save area
;
    psect   udata_shr
WREG_SAVE:   ds     1
STATUS_SAVE: ds     1
PCLATH_SAVE: ds     1
NEC_IR_State:       ds  1
NEC_IR_StartFlash:  ds  1
NEC_IR_CdPause:     ds  1
;
; Data area for protocol decoder
;
    psect   udata
NEC_IR_RawData:     ds  4
NEC_IR_Address:     ds  1
NEC_IR_Command:     ds  1
NEC_IR_Flags:       ds  1
#define BIT_NEC_IR_Flags_COMMAND NEC_IR_Flags,0
#define BIT_NEC_IR_Flags_REPEAT  NEC_IR_Flags,1
;
; Interrupt Service Routine
;
    psect   ISRVector,abs,local,class=CODE,delta=2
    org     0x0004

ISR:
    movwf   WREG_SAVE           ; 
    movf    STATUS,W            ; These register: WREG, STATUS, PCLATH
    movwf   STATUS_SAVE         ; are what, at the minimum, must be saved 
    movf    PCLATH,W            ; and restored on an interrupt.
    movwf   PCLATH_SAVE         ;
    clrf    STATUS              ; Force to memory bank 0
    clrf    PCLATH              ; Force to code page 0
;
; Handle external INT interrupt request
;
    btfsc   INTCON,INTCON_INTE_POSITION
    btfss   INTCON,INTCON_INTF_POSITION
    goto    INT_End
    bcf     INTCON,INTCON_INTF_POSITION
;
; Block flash detection until application loop is done
;
    btfss   BIT_NEC_IR_Flags_COMMAND
    btfsc   BIT_NEC_IR_Flags_REPEAT
    goto    INT_End

    movf    NEC_IR_State,F
    btfss   STATUS,STATUS_Z_POSITION    ;skpz    
    goto    NEC_IR_NextState
;
; Look for initial long flash
;
    clrf    NEC_IR_StartFlash
    clrf    TMR0
    bcf     INTCON,INTCON_T0IF_POSITION
MeasureStartFlash:
    btfsc   PORTB,0             ; Skip if flash still on
    goto    EndOfFlash
    btfss   INTCON,INTCON_T0IF_POSITION
    goto    MeasureStartFlash
    bcf     INTCON,INTCON_T0IF_POSITION
    incfsz  NEC_IR_StartFlash,W
    movwf   NEC_IR_StartFlash
    goto    MeasureStartFlash
EndOfFlash:
    clrf    TMR0
    bcf     INTCON,INTCON_T0IF_POSITION
    clrf    NEC_IR_CdPause
    movlw   8
    subwf   NEC_IR_StartFlash,W
    btfss   STATUS,STATUS_C_POSITION ; Skip if count equal or greater than 8 T0IF ticks
    goto    INT_End
;
; Measure pause after flash
;
MeasurePause:
    btfss   PORTB,0             ; Skip if flash still off
    goto    EndOfPause
    btfss   INTCON,INTCON_T0IF_POSITION
    goto    MeasurePause
    bcf     INTCON,INTCON_T0IF_POSITION
    incfsz  NEC_IR_CdPause,W
    movwf   NEC_IR_CdPause
    goto    MeasurePause
EndOfPause:
    btfss   PORTB,0             ; Skip when flash goes off
    goto    EndOfPause
    clrf    TMR0
    bcf     INTCON,INTCON_T0IF_POSITION
    bcf     INTCON,INTCON_INTF_POSITION
    movlw   4
    subwf   NEC_IR_CdPause,W
    btfsc   STATUS,STATUS_C_POSITION ; Skip if count less than 4 T0IF ticks
    goto    ReceiveCommandState
    banksel NEC_IR_Flags
    bsf     BIT_NEC_IR_Flags_REPEAT ; Assert this is a REPEAT event
    goto    INT_End
ReceiveCommandState:
    movlw   32
    movwf   NEC_IR_State      ; Advnace to state 32 when we expect ADDRESS/COMMAND data
INT_End:
;
    movf    PCLATH_SAVE,W       ;
    movwf   PCLATH              ; Restore the saved context of the
    movf    STATUS_SAVE,W       ; interrupted execution.
    movwf   STATUS              ;
    swapf   WREG_SAVE,F         ;
    swapf   WREG_SAVE,W         ;
    retfie                      ; Exit ISR and enable the interrupts.
;
; Receive COMMAND or REPEAT event
;
NEC_IR_NextState:
    banksel PORTB
    bcf     STATUS,STATUS_C_POSITION
    btfsc   INTCON,INTCON_T0IF_POSITION
    bsf     STATUS,STATUS_C_POSITION
    banksel NEC_IR_RawData
    rlf     NEC_IR_RawData,F
    rlf     NEC_IR_RawData+1,F
    rlf     NEC_IR_RawData+2,F
    rlf     NEC_IR_RawData+3,F
EndOfBit:
    banksel PORTB
    btfss   PORTB,0             ; Skip when flash goes off
    goto    EndOfBit
    clrf    TMR0
    bcf     INTCON,INTCON_T0IF_POSITION
    decf    NEC_IR_State,F
    btfss   STATUS,STATUS_Z_POSITION
    goto    INT_End
;
; Validate ADDRESS and COMMAND
;
    banksel NEC_IR_RawData
    comf    NEC_IR_RawData,W
    xorwf   NEC_IR_RawData+1,W
    btfss   STATUS,STATUS_Z_POSITION
    goto    INT_End
    comf    NEC_IR_RawData+2,W
    xorwf   NEC_IR_RawData+3,W
    btfss   STATUS,STATUS_Z_POSITION
    goto    INT_End

    movf    NEC_IR_RawData+1,W
    movwf   NEC_IR_Command
    movf    NEC_IR_RawData+3,W
    movwf   NEC_IR_Address
    bsf     BIT_NEC_IR_Flags_COMMAND
    goto    INT_End
;
; Initialize the PIC hardware
;
START:
    clrf    INTCON              ; Disable all interrupt sources
    banksel BANK1
    clrf    PIE1
    clrf    PIE2

    movlw   0b01100000
    movwf   OSCCON              ; Set internal oscillator at 4MHz

    movlw   0b10000001         ; Pull-ups off, INT edge high to low, WDT prescale 1:1
    movwf   OPTION_REG          ; TMR0 clock edge low to high, TMR0 clock = FCY, TMR0 prescale 1:4
                                ; TIMER0 will assert the overflow flag every 256*4 (1024)
                                ; instruction cycles, with a 4MHz oscilator this ia 1.024 milliseconds.

    movlw   0b11111111         ;
    movwf   TRISA

    movlw   0b11111111         ;
    movwf   TRISB

    movlw   0b11111111         ;
    movwf   TRISC

    movlw   0b11111111         ;
    movwf   TRISD

    ; Set all ADC inputs for digital I/O
    banksel BANK3
    movlw   0b00000000
    movwf   ANSEL
    movlw   0b00000000
    movwf   ANSELH
    banksel BANK2
    clrf    CM1CON0             ; turn off comparator
    clrf    CM2CON0             ; turn off comparator
    banksel BANK1
    movlw   0b00000000
    movwf   ADCON1
    clrf    VRCON               ; turn off voltage reference
    banksel BANK0
    movlw   0b10000000
    movwf   ADCON0

    pagesel main
    goto    main
;
; Main data
;
    psect   udata
RepeatCount: ds     1
;
; Main application code
;
    psect   MainFunc,local,class=CODE,delta=2
; 
; Main application initialization
;
main:
    pagesel OpenXLCD
    call    OpenXLCD
 
    movlw   LINE_ONE
    pagesel SetDDRamAddr
    call    SetDDRamAddr

    movlw   LOW(LCD_message1)
    movwf   pszLCD_RomStr
    movlw   HIGH(LCD_message1)
    movwf   pszLCD_RomStr+1
    pagesel putrsXLCD
    call    putrsXLCD

    banksel NEC_IR_Flags
    clrf    NEC_IR_Flags
    clrf    NEC_IR_State
    bcf     BIT_NEC_IR_Flags_COMMAND
    bcf     BIT_NEC_IR_Flags_REPEAT
    bcf     INTCON,INTCON_INTF_POSITION
    bsf     INTCON,INTCON_INTE_POSITION
    bsf     INTCON,INTCON_GIE_POSITION
;
; Application process loop
;
AppLoop:
    movf    NEC_IR_Flags,F      ; Check for event
    btfsc   STATUS,STATUS_Z_POSITION ; Skip if any event bit set
    GOTO    AppLoop             ;

    banksel NEC_IR_Flags
    btfsc   BIT_NEC_IR_Flags_REPEAT ; skip of not a REPEAT event
    goto    IncrementCount
    banksel RepeatCount
    clrf    RepeatCount
;
; Increment repeat count
;
IncrementCount:
    banksel RepeatCount
    incfsz  RepeatCount,W
    movwf   RepeatCount

;
; Show measurement for Start Of Transmission (SOT) flash
;
    movlw   LINE_TWO
    pagesel SetDDRamAddr
    call    SetDDRamAddr
    movf    NEC_IR_StartFlash,W
    pagesel PutDecXLCD
    call    PutDecXLCD
;
; Show measurement for pause after SOT flash
;
    movlw   ' '
    pagesel WriteDataXLCD
    call    WriteDataXLCD
    movf    NEC_IR_CdPause,W
    pagesel PutDecXLCD
    call    PutDecXLCD
;
; Show decoded ADDRESS and COMMAND
;
    movlw   ' '
    pagesel WriteDataXLCD
    call    WriteDataXLCD
    banksel NEC_IR_Address
    movf    NEC_IR_Address,W
    pagesel PutHexXLCD
    call    PutHexXLCD
    banksel NEC_IR_Command
    movf    NEC_IR_Command,W
    pagesel PutHexXLCD
    call    PutHexXLCD
;
; Show REPEAT count
;
    movlw   ' '
    pagesel WriteDataXLCD
    call    WriteDataXLCD
    banksel RepeatCount
    movf    RepeatCount,W
    pagesel PutHexXLCD
    call    PutHexXLCD
;
; Clear event flags to enable capture of next event
;
    banksel NEC_IR_Flags
    clrf    NEC_IR_Flags

    pagesel AppLoop
    GOTO    AppLoop
;
; LCD messages
;
    psect   MainConst,local,class=CODE,delta=2
LCD_message1:
;    dt  "NEC IR Decode v1",0
  IRP char,'N','E','C',' ','I','R',' ','D','e','c','o','d','e',' ','v','1',0
    retlw char
  ENDM
;
; Tell linker where to start
;
    END     POReset
