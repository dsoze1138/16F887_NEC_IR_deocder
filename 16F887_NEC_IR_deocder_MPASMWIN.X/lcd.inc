; -------------------------
; LCD functions
; -------------------------
;
#ifndef LCD_INC
#define LCD_INC
#ifdef  LCD_ASM
#define ExtSymbol   global
#else
#define ExtSymbol   extern
#endif
;
; Declare the public symbols
;
    ExtSymbol   pszLCD_RomStr
    ExtSymbol   SetCGRamAddr
    ExtSymbol   SetDDRamAddr
    ExtSymbol   WriteCmdXLCD
    ExtSymbol   WriteDataXLCD
    ExtSymbol   OpenXLCD
    ExtSymbol   PutHexXLCD
    ExtSymbol   PutDecXLCD
    ExtSymbol   putrsXLCD
    ExtSymbol   LCD_BusyBit

; end of public symbols
#undefine ExtSymbol
;
; Define the LCD port pins
#define LCD_POWER_EN  PORTD,7
#define E_PIN         PORTD,6
#define RW_PIN        PORTD,5
#define RS_PIN        PORTD,4
#define LCD_DATA_BITS 0x0F
#define LCD_PORT      PORTD

;#define USE_FAST_CLOCK
;
;
;/* Display ON/OFF Control defines */
#define DON         b'00001111'  ;/* Display on      */
#define DOFF        b'00001011'  ;/* Display off     */
#define CURSOR_ON   b'00001111'  ;/* Cursor on       */
#define CURSOR_OFF  b'00001101'  ;/* Cursor off      */
#define BLINK_ON    b'00001111'  ;/* Cursor Blink    */
#define BLINK_OFF   b'00001110'  ;/* Cursor No Blink */

;/* Cursor or Display Shift defines */
#define SHIFT_CUR_LEFT    b'00010011'  ;/* Cursor shifts to the left   */
#define SHIFT_CUR_RIGHT   b'00010111'  ;/* Cursor shifts to the right  */
#define SHIFT_DISP_LEFT   b'00011011'  ;/* Display shifts to the left  */
#define SHIFT_DISP_RIGHT  b'00011111'  ;/* Display shifts to the right */

;/* Function Set defines */
#define FOUR_BIT   b'00101111'  ;/* 4-bit Interface               */
#define EIGHT_BIT  b'00111111'  ;/* 8-bit Interface               */
#define LINE_5X7   b'00110011'  ;/* 5x7 characters, single line   */
#define LINE_5X10  b'00110111'  ;/* 5x10 characters               */
#define LINES_5X7  b'00111011'  ;/* 5x7 characters, multiple line */

; Start address of each line
#define LINE_ONE    0x00
#define LINE_TWO    0x40
#define LINE_THREE  0x14
#define LINE_FOUR   0x54

#endif