; Andrew's lockstep code, converted to TASM

PUSHSTATE
P8086
IDEAL
SMART

; initCGA m
; m = mode register value:
; 0x08 = 40x25 text, colour, bright background
; 0x09 = 80x25 text, colour, bright background
; 0x0a = 320x200 graphics, colour
; 0x0c = 40x25 text, B/W, bright background
; 0x0d = 80x25 text, B/W, bright background
; 0x0e = 320x200 graphics, B/W
; 0x1a = 640x200 graphics, colour
; 0x1e = 640x200 graphics, B/W
; 0x28 = 40x25 text, colour, blinking
; 0x29 = 80x25 text, colour, blinking
; 0x2c = 40x25 text, B/W, blinking
; 0x2d = 80x25 text, B/W, blinking
MACRO initCGAm s1
  IF (s1 AND 10h) NE 0
    initCGAmp s1, 0fh
  ELSE
    initCGAmp s1, 0
  ENDIF
ENDM

; initCGA m. p
; p = palette register value:
; 0x00..0x0f = background/green/red/brown
; 0x10..0x1f = background/light green/light red/yellow
; 0x20..0x2f = background/cyan/magenta/light grey
; 0x30..0x3f = background/light cyan/light magenta/white
MACRO initCGAmp s1,s2
  IF (s1 AND 2) NE 0
    initCGAmpl s1, s2, 2
  ELSE
    initCGAmpl s1, s2, 8
  ENDIF
ENDM

; initCGA m, p, l
; l = scanlines per character
MACRO initCGAmpl s1,s2,s3
  ; Mode
  ;      1 +HRES
  ;      2 +GRPH
  ;      4 +BW
  ;      8 +VIDEO ENABLE
  ;   0x10 +1BPP
  ;   0x20 +ENABLE BLINK
  mov dx,03d8h
  mov al,s1
  out dx,al

  ; Palette
  ;      1 +OVERSCAN B
  ;      2 +OVERSCAN G
  ;      4 +OVERSCAN R
  ;      8 +OVERSCAN I
  ;   0x10 +BACKGROUND I
  ;   0x20 +COLOR SEL
  inc dx
  mov al,s2
  out dx,al

  mov dl,0d4h

  ;   0xff Horizontal Total                             38 71
  IF (s1 AND 1) NE 0
    mov ax,7100h
  ELSE
    mov ax,3800h
  ENDIF
  out dx,ax

  ;   0xff Horizontal Displayed                         28 50
  IF (s1 AND 1) NE 0
    mov ax,5001h
  ELSE
    mov ax,2801h
  ENDIF
  out dx,ax

  ;   0xff Horizontal Sync Position                     2d 5a
  IF (s1 AND 1) NE 0
    mov ax,5a02h
  ELSE
    mov ax,2d02h
  ENDIF
  out dx,ax

  ;   0x0f Horizontal Sync Width                              0a
  mov ax,0a03h
  out dx,ax

  ;   0x7f Vertical Total                                        1f 7f
  IF s3 EQ 2
    mov ax,7f04h
  ELSE
    mov ax,4 OR (((262 / s3) - 1) SHL 8)
  ENDIF
  out dx,ax

  ;   0x1f Vertical Total Adjust                              06
  IF s3 EQ 2
    mov ax,0605h
  ELSE
    mov ax,5 OR ((262 MOD s3) SHL 8)
  ENDIF
  out dx,ax

  ;   0x7f Vertical Displayed                                    19 64
  IF s3 EQ 2
    mov ax,6406h
  ELSE
    mov ax,6 OR ((200 / s3) SHL 8)
  ENDIF
  out dx,ax

  ;   0x7f Vertical Sync Position                                1c 70
  IF s3 EQ 2
    mov ax,7007h
  ELSE
    mov ax,7 OR ((224 / s3) SHL 8)
  ENDIF
  out dx,ax

  ;   0x03 Interlace Mode                                     02
  mov ax,0208h
  out dx,ax

  ;   0x1f Max Scan Line Address                                 07 01
  mov ax,9 OR ((s3 - 1) SHL 8)
  out dx,ax

  ; Cursor Start                                              06
  ;   0x1f Cursor Start                                        6
  ;   0x60 Cursor Mode                                         0
  mov ax,060ah
  out dx,ax

  ;   0x1f Cursor End                                         07
  mov ax,070bh
  out dx,ax

  ;   0x3f Start Address (H)                                  00
  mov ax,000ch
  out dx,ax

  ;   0xff Start Address (L)                                  00
  inc ax
  out dx,ax

  ;   0x3f Cursor (H)                                         03  0x3c0 == 40*24 == start of last line
  mov ax,030eh
  out dx,ax

  ;   0xff Cursor (L)                                         c0
  mov ax,0c00fh
  out dx,ax
ENDM

  ; 8253 PIT Mode control (port 0x43) values

  TIMER0 EQU 00h
  TIMER1 EQU 40h
  TIMER2 EQU 80h

  LATCH  EQU 00h
  LSB    EQU 10h
  MSB    EQU 20h
  BOTH   EQU 30h ; LSB first, then MSB

  MODE0  EQU 00h ; Interrupt on terminal count: low during countdown then high
  MODE1  EQU 02h ; Programmable one shot      : low from gate rising to end of countdown
  MODE2  EQU 04h ; Rate generator             : output low for one cycle out of N
  MODE3  EQU 06h ; Square wave generator      : high for ceil(n/2) and low for floor(n/2)
  MODE4  EQU 08h ; Software triggered strobe  : high during countdown then low for one cycle
  MODE5  EQU 0ah ; Hardware triggered strobe  : wait for gate rising, then high during countdown, then low for one cycle

  BINARY EQU 00h
  BCD    EQU 01h

MACRO refreshOff
  mov al,TIMER1 OR LSB OR MODE0 OR BINARY
  out 43h,al
  mov al,01h  ; Count = 0x0001 so we'll stop almost immediately
  out 41h,al
ENDM

MACRO refreshOn
  mov al,TIMER1 OR LSB OR MODE2 OR BINARY
  out 43h,al
;;mov al,18 ;;18 is standard, we are going to go with 19 which is divisor of 76 which is CGA
  mov al,19
  out 41h,al  ; Timer 1 rate
ENDM


MACRO lockstep
  mov dx,03d8h
  mov al,0
  out dx,al

  ; Set up CRTC for 1 character by 2 scanline "frame". This gives us 2 lchars
  ; per frame.
  mov dx,3d4h
  ;   0xff Horizontal Total
  mov ax,0000h
  out dx,ax
  ;   0xff Horizontal Displayed                         28
  mov ax,0101h
  out dx,ax
  ;   0xff Horizontal Sync Position                     2d
  mov ax,2d02h
  out dx,ax
  ;   0x0f Horizontal Sync Width                        0a
  mov ax,0a03h
  out dx,ax
  ;   0x7f Vertical Total                               7f
  mov ax,0104h
  out dx,ax
  ;   0x1f Vertical Total Adjust                        06
  mov ax,0005h
  out dx,ax
  ;   0x7f Vertical Displayed                           64
  mov ax,0106h
  out dx,ax
  ;   0x7f Vertical Sync Position                       70
  mov ax,0007h
  out dx,ax
  ;   0x03 Interlace Mode                               02
  mov ax,0208h
  out dx,ax
  ;   0x1f Max Scan Line Address                        01
  mov ax,0009h
  out dx,ax

  mov cx,256
  xor ax,ax
  mov ds,ax
  mov si,ax
  cld
  cli

  ; Increase refresh frequency to ensure all DRAM is refreshed before turning
  ; off refresh.
  mov al,TIMER1 OR LSB OR MODE2 OR BINARY
  out 43h,al
  mov al,2
  out 41h,al  ; Timer 1 rate

  ; Delay for enough time to refresh 512 columns
  rep lodsw

  ; We now have about 1.5ms during which refresh can be off
  refreshOff

  ; Set "stosb" destination to be CGA memory
  mov ax,0b800h
  mov es,ax
  mov ds,ax
  mov di,3ffch
  mov si,di
  mov ax,0303h
  stosw
  mov al,0
  stosb

  mov dl,0dah

  ; Set argument for MUL
  mov cl,1

  ; Go into CGA lockstep.
  jmp $+2
  mov al,0  ; exact value doesn't matter here - it's just to ensure the prefetch queue is filled
  mul cl
  lodsb
  mul cl
  nop
  lodsb
  mul cl
  nop
  lodsb
  mul cl

  ; To get the CRTC into lockstep with the CGA and CPU, we need to figure out
  ; which of the two possible CRTC states we're in and switch states if we're
  ; in the wrong one by waiting for an odd number of lchars more in one code
  ; path than in the other. To keep CGA and CPU in lockstep, we also need both
  ; code paths to take the same time mod 3 lchars, so we wait 3 lchars more on
  ; one code path than on the other.
  in al,dx
  and al,1
  dec ax
  mul cl
  mul cl
  jmp $+2

  initCGAm 1

  ; Increase refresh frequency to ensure all DRAM is refreshed before turning
  ; off refresh.
  mov al,TIMER1 OR LSB OR MODE2 OR BINARY
  out 43h,al
  mov al,2
  out 41h,al  ; Timer 1 rate

  xor ax,ax
  mov ds,ax
  mov si,ax

  ; Delay for enough time to refresh 512 columns
  mov cx,256
  rep lodsw
ENDM


MACRO waitForDisplayEnable
  LOCAL x1
  x1:
    in al,dx                       ; 1 1 2
    test al,1                      ; 2 0 2
    jnz x1                         ; 2 0 2
ENDM

MACRO waitForDisplayDisable
  LOCAL x1
  x1:
    in al,dx                       ; 1 1 2
    test al,1                      ; 2 0 2
    jz x1                          ; 2 0 2
ENDM

MACRO waitForVerticalSync
  LOCAL x1
  x1:
    in al,dx
    test al,8
    jz x1
ENDM

MACRO waitForNoVerticalSync
  LOCAL x1
  x1:
    in al,dx
    test al,8
    jnz x1
ENDM


; writePIT16 <timer>, <mode>, <value>
; timer 0 = IRQ0, BIOS time-of-day (default value 0, default mode ?)
; timer 1 = DRAM refresh DMA (default value 18, default mode ?)
; timer 2 = PC speaker/cassette
; mode 0 = interrupt on terminal count
; mode 1 = programmable one-shot
; mode 2 = rate generator
; mode 3 = square wave rate generator
; mode 4 = software triggered strobe
; mode 5 = hardware triggered strobe
; value = 13125000Hz/(11*frequency), or 0 for 18.2Hz
MACRO writePIT16 timer,mode,value
  mov al,(timer << 6) OR BOTH OR (mode << 1)  ; Don't use BCD mode
  out 0x43,al
  mov al,(value) & 0xff
  out 0x40 + s1,al
  mov al,(value) >> 8
  out 0x40 + s1,al
ENDM

; readPIT16 <timer>
; Value returned in AX
; Timer must have been written to with both bytes
MACRO readPIT16 timer
  mov al,(timer << 6) OR LATCH
  out 0x43,al
  in al,0x40 + s1
  mov ah,al
  in al,0x40 + s1
  xchg ah,al
ENDM

POPSTATE
