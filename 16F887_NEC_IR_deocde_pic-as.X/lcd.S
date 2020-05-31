; -------------------------
; LCD functions
; -------------------------
;
#include "main.inc"
#include "lcd.inc"
;
; This code assumes a oscillator of 4MHz
;
; The the fastest oscillator a PIC16F887 can use is 20MHz.
;
; When USE_FAST_CLOCK is defined the delays are adjusted
; for a 20MHz oscillator.
;
;#define USE_FAST_CLOCK
#ifdef USE_FAST_CLOCK
#define DELAY_FOR_FAST_CLOCK  call DelayFor18TCY
#else
#define DELAY_FOR_FAST_CLOCK
#endif
;
; This RAM is used by the LCD interface routines.
;
    psect   udata_shr
LCD_byte:   ds      1       ; byte sent to or read from LCD
LCD_BusyBit: ds     1       ; Mask of where the BUSY bit is located
pszLCD_RomStr: ds   2       ; pointer to ASCIIZ string in ROM

    psect   LcdFunc,local,class=CODE,delta=2

; DelayFor18TCY() provides a 18 Tcy delay
DelayFor18TCY:
    goto    DelayFor16TCY

; DelayXLCD() provides at least 5ms delay
DelayXLCD:
;
; If we are using a fast clock make
; the delays work for a 20MHz clock.
;
#ifdef USE_FAST_CLOCK
    call    DXLCD0
    call    DXLCD0
    call    DXLCD0
    call    DXLCD0
#endif

DXLCD0:
    goto    $+1
    goto    $+1
    movlw   249
DXLCD1:
    call    DelayFor16TCY
    addlw   -1
    btfss   STATUS,STATUS_Z_POSITION ;skpz
    goto    DXLCD1
DelayFor16TCY:
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    goto    $+1
    return

; DelayPORXLCD() provides at least 15ms delay
DelayPORXLCD:
    call    DelayXLCD
    call    DelayXLCD
    goto    DelayXLCD
;
; Function Name:  BusyXLCD
; Return Value:   W = Not zero when status of LCD controller is busy
; Parameters:     void
; Description:    This routine reads the busy status of the
;                 Hitachi HD44780 LCD controller.
; Notes:
;  The busy bit is not reported in the same nibble
;  on all HD44780 "compatible" controllers.
;  If you have a Novatek 7605 type controller some
;  versions report these nibbles in reverse order.
;
;  This code has been tested with a Novatek 7605
;  and the real Hitachi HD44780.
;
BusyXLCD:
    movf    LCD_BusyBit,F   ; Check if busy bit avaliable.
    btfsc   STATUS,STATUS_Z_POSITION ;skpnz
    goto    DelayPORXLCD    ; Use a 15ms delay when busy not available.

    bcf     RS_PIN
    bsf     RW_PIN

    bcf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK

    btfsc   LCD_BusyBit,7
    movf    LCD_PORT,W      ; The standard LCD returns the BUSY flag first

    bcf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK

    btfsc   LCD_BusyBit,3
    movf    LCD_PORT,W      ; A Non standard LCD returns the BUSY flag second

    bcf     E_PIN
    andlw   (LCD_DATA_BITS&(~LCD_DATA_BITS>>1))
    btfss   STATUS,STATUS_Z_POSITION ;skpz
    goto    BusyXLCD
    return
;
; Send a byte to LCD using 4-bit mode
BytePutLCD:
    banksel BANK1
    movlw   ~LCD_DATA_BITS
    andwf   LCD_PORT,F      ; Make LCD port bits outputs
    banksel BANK0
    andwf   LCD_PORT,F      ; Make LCD port bits zero

    bcf     RW_PIN
;
; send first 4-bits
    swapf   LCD_byte,W
    andlw   LCD_DATA_BITS
    iorwf   LCD_PORT,F
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
;
; send second 4-bits
    xorwf   LCD_byte,W
    andlw   LCD_DATA_BITS
    xorwf   LCD_PORT,F
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN

; set data bits for input
    banksel BANK1
    movlw   LCD_DATA_BITS
    iorwf   LCD_PORT,F
    banksel BANK0
    movf    LCD_byte,W
    return
;
; Read a byte to LCD using 4-bit mode
ByteGetLCD:
    bsf     RW_PIN
;
; read first 4-bits
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    movf    LCD_PORT,W
    bcf     E_PIN
    andlw   LCD_DATA_BITS
    movwf   LCD_byte
;
; read second 4-bits
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    movf    LCD_PORT,W
    bcf     E_PIN
    andlw   LCD_DATA_BITS
    swapf   LCD_byte,F
    iorwf   LCD_byte,F
    movf    LCD_byte,W
    return
;
; Function Name:  SetCGRamAddr
; Return Value:   void
; Parameters:     W = character generator ram address
; Description:    This routine sets the character generator
;                 address of the Hitachi HD44780 LCD
;                 controller.
;
SetCGRamAddr:
    iorlw   0x40            ; Write cmd and address to port
    movwf   LCD_byte        ; save byte going to LCD

    call    BusyXLCD

    bcf     RS_PIN
    goto    BytePutLCD

;
; Function Name:  SetDDRamAddr
; Return Value:   void
; Parameters:     W = display data address
; Description:    This routine sets the display data address
;                 of the Hitachi HD44780 LCD controller.
;
SetDDRamAddr:
    iorlw   0x80            ; Write cmd and address to port
    movwf   LCD_byte        ; save byte going to LCD

    call    BusyXLCD

    bcf     RS_PIN
    goto    BytePutLCD
;
; Function Name:  WriteCmdXLCD
; Return Value:   void
; Parameters:     W = command to send to LCD
; Description:    This routine writes a command to the Hitachi
;                 HD44780 LCD controller.
;
WriteCmdXLCD:
    movwf   LCD_byte        ; save byte going to LCD

    call    BusyXLCD

    bcf     RS_PIN
    goto    BytePutLCD
;
; Function Name:  WriteDataXLCD
; Return Value:   void
; Parameters:     W = data byte to be written to LCD
; Description:    This routine writes a data byte to the
;                 Hitachi HD44780 LCD controller. The data
;                 is written to the character generator RAM or
;                 the display data RAM depending on what the
;                 previous SetxxRamAddr routine was called.
;
WriteDataXLCD:
    movwf   LCD_byte        ; save byte going to LCD

    call    BusyXLCD

    bsf     RS_PIN
    call    BytePutLCD
    bcf     RS_PIN
    return
;
; Function Name:  OpenXLCD
; Return Value:   void
; Parameters:     none
; Description:    This routine configures the LCD. Based on
;                 the Hitachi HD44780 LCD controller. The
;                 routine will configure the I/O pins of the
;                 microcontroller, setup the LCD for 4-bit
;                 mode and clear the display.
;
OpenXLCD:
    clrf    LCD_BusyBit
    banksel BANK1
    movlw   ~LCD_DATA_BITS
    andwf   LCD_PORT,F      ; Make LCD data bus an output
    bcf     E_PIN           ; Make LCD data enable strobe an output
    bcf     RW_PIN          ; Make LCD Read/Write select an output
    bcf     RS_PIN          ; Make LCD Register select an output
    bcf     LCD_POWER_EN    ; Make LCD power enable an output
    banksel BANK0
    andwf   LCD_PORT,F      ; Drive all LCD pins low
    bcf     E_PIN
    bcf     RW_PIN
    bcf     RS_PIN
    bsf     LCD_POWER_EN    ; Turn on LCD power

    call    DelayPORXLCD    ; Wait for LCD to complete power on reset

    movlw   0b00000011     ; force LCD into 8-bit mode
    iorwf   LCD_PORT,F
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
    call    DelayXLCD       ; Required 5ms delay

    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
    call    DelayXLCD       ; minimum 100us delay but use 5ms

    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
    call    DelayXLCD       ; minimum 100us delay but use 5ms

    movlw   0b00000010     ; set LCD into 4-bit mode
    xorwf   LCD_PORT,W
    andlw   LCD_DATA_BITS
    xorwf   LCD_PORT,F
    bsf     E_PIN
    DELAY_FOR_FAST_CLOCK
    bcf     E_PIN
    call    DelayXLCD

    banksel BANK1
    movlw   LCD_DATA_BITS   ; Make LCD data pins inputs
    iorwf   LCD_PORT,F
    banksel BANK0

    movlw   FOUR_BIT & LINES_5X7 ; Setup for 2-line display
    call    WriteCmdXLCD

    movlw   DOFF & CURSOR_OFF & BLINK_OFF
    call    WriteCmdXLCD

    movlw   DON & CURSOR_OFF & BLINK_OFF
    call    WriteCmdXLCD

    movlw   (0x01)          ; Clear display
    call    WriteCmdXLCD

    movlw   SHIFT_CUR_LEFT
    call    WriteCmdXLCD
;
; Find position of busy bit
; Required when using 4-bit mode.
;
    movlw   LINE_ONE+1
    call    SetDDRamAddr

    call    BusyXLCD

    call    ByteGetLCD
    xorlw   0x01
    btfsc   STATUS,STATUS_Z_POSITION ;skpnz
    bsf     LCD_BusyBit,7
    xorlw   0x11
    btfsc   STATUS,STATUS_Z_POSITION ;skpnz
    bsf     LCD_BusyBit,3
;
; Initialize CGRAM
;
    clrw
    call    SetCGRamAddr
    movlw   LOW(CGRAM_Table)
    movwf   pszLCD_RomStr
    movlw   HIGH(CGRAM_Table)
    movwf   pszLCD_RomStr+1
    call    putrsXLCD
;
; Put cursor on line one, left most position
;
    movlw   LINE_ONE
    call    SetDDRamAddr

    return
;
; Function Name:  PutHexXLCD
; Return Value:   void
; Parameters:     W = 8-bit value to send to LCD
; Description:    Writes two ASCII character of the
;                 hexadecimal value in thw W register.
;
PutHexXLCD:
        movwf   pszLCD_RomStr
        swapf   pszLCD_RomStr,W
        call    PutHexNibbleXLCD
        movf    pszLCD_RomStr,W
PutHexNibbleXLCD:
        andlw   0x0F
        addlw   0x06
        btfsc   STATUS,STATUS_DC_POSITION
        addlw   'A'-'0'-10
        addlw   '0'-6
        call    WriteDataXLCD
        movf    pszLCD_RomStr,W
        return
;
; Function Name:  PutDecXLCD
; Return Value:   void
; Parameters:     W = 8-bit value to send to LCD
; Description:    Writes three ASCII character of the
;                 decimal value in thw W register.
;
PutDecXLCD:
        clrf    pszLCD_RomStr+1

        addlw   256-200
        btfsc   STATUS,STATUS_C_POSITION ;skpnc
        bsf     pszLCD_RomStr+1,1
        btfss   STATUS,STATUS_C_POSITION ;skpc
        addlw   200

        addlw   256-100
        btfsc   STATUS,STATUS_C_POSITION ;skpnc
        bsf     pszLCD_RomStr+1,0
        btfss   STATUS,STATUS_C_POSITION ;skpc
        addlw   100

        movwf   pszLCD_RomStr       ; save output value less than 100

        movlw   0x1F
        andwf   pszLCD_RomStr+1,W
        bsf     pszLCD_RomStr+1,5
        btfss   STATUS,STATUS_Z_POSITION ;skpz
        bsf     pszLCD_RomStr+1,4
        movf    pszLCD_RomStr+1,W
        btfsc   pszLCD_RomStr+1,4
        call    WriteDataXLCD       ; output 100's digit
        movlw   0x10
        andwf   pszLCD_RomStr+1,F

        movf    pszLCD_RomStr,W
        addlw   256-80
        btfsc   STATUS,STATUS_C_POSITION ;skpnc
        bsf     pszLCD_RomStr+1,3
        btfss   STATUS,STATUS_C_POSITION ;skpc 
        addlw   80

        addlw   256-40
        btfsc   STATUS,STATUS_C_POSITION ;skpnc
        bsf     pszLCD_RomStr+1,2
        btfss   STATUS,STATUS_C_POSITION ;skpc
        addlw   40

        addlw   256-20
        btfsc   STATUS,STATUS_C_POSITION ;skpnc
        bsf     pszLCD_RomStr+1,1
        btfss   STATUS,STATUS_C_POSITION ;skpc
        addlw   20

        addlw   256-10
        btfsc   STATUS,STATUS_C_POSITION ;skpnc
        bsf     pszLCD_RomStr+1,0
        btfss   STATUS,STATUS_C_POSITION ;skpc
        addlw   10
        movwf   pszLCD_RomStr

        movlw   0x1F
        andwf   pszLCD_RomStr+1,W
        bsf     pszLCD_RomStr+1,5
        btfss   STATUS,STATUS_Z_POSITION ;skpz
        bsf     pszLCD_RomStr+1,4
        movf    pszLCD_RomStr+1,W
        btfsc   pszLCD_RomStr+1,4
        call    WriteDataXLCD       ; output 10's digit
        movlw   '0'
        addwf   pszLCD_RomStr,W
        call    WriteDataXLCD       ; output 1's digit
        return
;
; Function Name:  putrsXLCD
; Return Value:   void
; Parameters:     pszLCD_RomStr: pointer to string
; Description:    This routine writes a string of bytes to the
;                 Hitachi HD44780 LCD controller. The data
;                 is written to the character generator RAM or
;                 the display data RAM depending on what the
;                 previous SetxxRamAddr routine was called.
;
putrsXLCD:
    call    TableLookUp             ; This call affects the PCLATH
    pagesel putrsXLCD               ; Point the PCLATH resgister to this page
    iorlw   0                       ; Check for the end of string
    btfsc   STATUS,STATUS_Z_POSITION ; Skip of more to send
    return
    call    WriteDataXLCD           ; Send data to the LCD
    incf    pszLCD_RomStr,F         ; Update the string pointer
    btfsc   STATUS,STATUS_Z_POSITION
    incf    pszLCD_RomStr+1,F
    goto    putrsXLCD               ; Loop until the end of string found

TableLookUp:
    movf    pszLCD_RomStr+1,W
    movwf   PCLATH
    movf    pszLCD_RomStr,W
    movwf   PCL
;
; This table is used to write
; default characters to the
; Character Generator RAM of
; the LCD module.
;
    psect   LcdConst,local,class=CODE,delta=2
CGRAM_Table:
    retlw   0b10000000  ; CGRAM character 1
    retlw   0b10001110 
    retlw   0b10001010 
    retlw   0b10001010 
    retlw   0b10001110 
    retlw   0b10000000 
    retlw   0b10000000 
    retlw   0b10011111 

    retlw   0b10001110  ; CGRAM character 2
    retlw   0b10010001 
    retlw   0b10010000 
    retlw   0b10010000 
    retlw   0b10010001 
    retlw   0b10001110 
    retlw   0b10000000 
    retlw   0b10011111 

    retlw   0b10001110  ; CGRAM character 3
    retlw   0b10010001 
    retlw   0b10010000 
    retlw   0b10010011 
    retlw   0b10010001 
    retlw   0b10001110 
    retlw   0b10000000 
    retlw   0b10011111 

    retlw   0b10000000  ; CGRAM character 4
    retlw   0b10001110 
    retlw   0b10001010 
    retlw   0b10001010 
    retlw   0b10001110 
    retlw   0b10000000 
    retlw   0b10000000 
    retlw   0b10011111 

    retlw   0b10011110  ; CGRAM character 5
    retlw   0b10010001 
    retlw   0b10010001 
    retlw   0b10011110 
    retlw   0b10010010 
    retlw   0b10010001 
    retlw   0b10000000 
    retlw   0b10011111 

    retlw   0b10001110  ; CGRAM character 6
    retlw   0b10010001 
    retlw   0b10010001 
    retlw   0b10011111 
    retlw   0b10010001 
    retlw   0b10010001 
    retlw   0b10000000 
    retlw   0b10011111 

    retlw   0b10010001  ; CGRAM character 7
    retlw   0b10011011 
    retlw   0b10010101 
    retlw   0b10010101 
    retlw   0b10010001 
    retlw   0b10010001 
    retlw   0b10000000 
    retlw   0b10011111 

    retlw   0b10000000  ; CGRAM character 8
    retlw   0b10001110 
    retlw   0b10001010 
    retlw   0b10001010 
    retlw   0b10001110 
    retlw   0b10000000 
    retlw   0b10000000 
    retlw   0b10011111 

    retlw   0b00000000  ; End of table marker

    end
