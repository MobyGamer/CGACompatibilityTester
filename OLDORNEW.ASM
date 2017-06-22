IDEAL
P8086

include "cgamacro.inc"

SEGMENT DATA word public
ENDS    DATA

SEGMENT CODE byte public
ASSUME  cs:CODE, ds:DATA

PUBLIC  show_oldornew

PROC    show_oldornew  NEAR
mstart:
  ; Mode                                                08
  ;      1 +HRES                                         0
  ;      2 +GRPH                                         0
  ;      4 +BW                                           0
  ;      8 +VIDEO ENABLE                                 8
  ;   0x10 +1BPP                                         0
  ;   0x20 +ENABLE BLINK                                 0
  mov dx,03d8h
  mov al,008h
  out dx,al

  ; Palette                                             00
  ;      1 +OVERSCAN B                                   0
  ;      2 +OVERSCAN G                                   0
  ;      4 +OVERSCAN R                                   0
  ;      8 +OVERSCAN I                                   0
  ;   0x10 +BACKGROUND I                                 0
  ;   0x20 +COLOR SEL                                    0
  mov dx,03d9h
  mov al,0
  out dx,al

  mov dx,03d4h

  ;   0xff Horizontal Total                             38
  mov ax,03800h
  out dx,ax

  ;   0xff Horizontal Displayed                         28
  mov ax,02801h
  out dx,ax

  ;   0xff Horizontal Sync Position                     2d
  mov ax,02d02h
  out dx,ax

  ;   0x0f Horizontal Sync Width                        0a
  mov ax,00a03h
  out dx,ax

  ;   0x7f Vertical Total                               3e
  mov ax,03e04h
  out dx,ax

  ;   0x1f Vertical Total Adjust                        00
  mov ax,00005h
  out dx,ax

  ;   0x7f Vertical Displayed                           02
  mov ax,00206h
  out dx,ax

  ;   0x7f Vertical Sync Position                       19
  mov ax,01a07h
  out dx,ax

  ;   0x03 Interlace Mode                               02
  mov ax,00208h
  out dx,ax

  ;   0x1f Max Scan Line Address                        00
  mov ax,00009h
  out dx,ax

  ; Cursor Start                                        06
  ;   0x1f Cursor Start                                  6
  ;   0x60 Cursor Mode                                   0
  mov ax,0060ah
  out dx,ax

  ;   0x1f Cursor End                                   07
  mov ax,0070bh
  out dx,ax

  ;   0x3f Start Address (H)                            00
  mov ax,0000ch
  out dx,ax

  ;   0xff Start Address (L)                            00
  mov ax,0000dh
  out dx,ax

  ;   0x3f Cursor (H)                                   03
  mov ax,0030eh
  out dx,ax

  ;   0xff Cursor (L)                                   c0
  mov ax,0c00fh
  out dx,ax

  mov dl,0dah

  mov cx,20*60 ;wait 20 seconds
  cli
whichFrameLoop:

  waitForVerticalSync
  waitForNoVerticalSync

  ; During line 0-1 we set up the start address for line 2 and change the vertical total to 0x01
  waitForDisplayEnable
  mov dl,0d4h
  mov ax,00104h ; 4: Vertical total: 2 rows/frame
  out dx,ax
  mov dl,0dah                    ; 2 0 2
  waitForDisplayDisable
  waitForDisplayEnable
  mov dl,0d4h
  mov ax,0000ch
  out dx,ax
  mov ax,0500dh
  out dx,ax
  mov dl,0dah                    ; 2 0 2
  waitForDisplayDisable

  ; During lines 2..197 we set up the start address for the next line
  push cx
  mov cx,98
  mov bx,000a0h
whichRowLoop:
  waitForDisplayEnable
  waitForDisplayDisable
  waitForDisplayEnable
  mov dl,0d4h
  mov ah,bh
  mov al,00ch
  out dx,ax
  mov ah,bl
  inc ax
  out dx,ax
  mov dl,0dah                    ; 2 0 2
  waitForDisplayDisable
  add bx,050h
  loop whichRowLoop
  pop cx

  ; During line 198 we set up the start address for line 0 and change the vertical total to 0x3e
  waitForDisplayEnable
  mov dl,0d4h
  mov ax,03e04h ; 4: Vertical total: 63 rows/frame
  out dx,ax
  mov dl,0dah
  waitForDisplayDisable
  waitForDisplayEnable
  mov dl,0d4h
  mov ax,0000ch
  out dx,ax
  inc ax
  out dx,ax
  mov dl,0dah
  waitForDisplayDisable

  loop whichFrameLoop1
  jmp whichDone
whichFrameLoop1:
  jmp whichFrameLoop
whichDone:
  sti
  mov ax,3
  int 010h
  ret
ENDP

ENDS

END