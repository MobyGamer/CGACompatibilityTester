;  zx0_8086.asm - ZX0 time-efficient decompressor implementation for 808x
;
;  Usual DOS assembler SMALL model assumptions apply.  This code:
;  - Assumes it was invoked via FAR call (change RETF to RET for NEAR calls)
;  - Is interrupt-safe
;  - Is not re-entrant (do not decompress while already running decompression)
;  - Trashes all data and segment registers
;
;  Copyright (C) 2023 Jim Leonard, Emmanuel Marty
;
;  This software is provided 'as-is', without any express or implied
;  warranty.  In no event will the authors be held liable for any damages
;  arising from the use of this software.
;
;  Permission is granted to anyone to use this software for any purpose,
;  including commercial applications, and to alter it and redistribute it
;  freely, subject to the following restrictions:
;
;  1. The origin of this software must not be misrepresented; you must not
;     claim that you wrote the original software. If you use this software
;     in a product, an acknowledgment in the product documentation would be
;     appreciated but is not required.
;  2. Altered source versions must be plainly marked as such, and must not be
;     misrepresented as being the original software.
;  3. This notice may not be removed or altered from any source distribution.

        IDEAL
        P8086
        MODEL SMALL

        CODESEG

PUBLIC  zx0_decompress_speed

;  ---------------------------------------------------------------------------
;  Decompress raw zx0 block
;  inputs:
;  * ds:si: raw zx0 block
;  * es:di: output buffer
;  output:
;  * ax:    decompressed size
;  ---------------------------------------------------------------------------

PROC    zx0_decompress_speed  NEAR

MACRO   get_elias_full_ur
LOCAL   eliasloop, gotelias, loadnew
eliasloop:
        shl     al,1            ;shift bit queue, and high bit into carry
        jz      loadnew         ;empty? Load 8 more bits
        jc      gotelias        ;done if control bit is 1
        shl     al,1            ;read data bit
        rcl     cx,1            ;shift into cx
        jmp     eliasloop

loadnew:
        lodsb                   ;read 8 new bits
        rcl     al,1            ;shift bit queue, and high bit into carry
        jc      gotelias        ;done if control bit is 1
        shl     al,1            ;read data bit
        rcl     cx,1            ;shift into cx
        shl     al,1            ;shift bit queue, and high bit into carry
        jc      gotelias        ;done if control bit is 1
        shl     al,1            ;read data bit
        rcl     cx,1            ;shift into cx
        shl     al,1            ;shift bit queue, and high bit into carry
        jc      gotelias        ;done if control bit is 1
        shl     al,1            ;read data bit
        rcl     cx,1            ;shift into cx
        shl     al,1            ;shift bit queue, and high bit into carry
        jc      gotelias        ;done if control bit is 1
        shl     al,1            ;read data bit
        rcl     cx,1            ;shift into cx

;if more than 9 bits of EG code, keep reading
        shl     al,1
        jmp     loadnew
gotelias:
ENDM

; Entry point ===============================================================

        push    di              ;remember decompression offset

        cld                     ;make string operations go forward
        mov     al,080h         ;initialize empty bit queue
                                ;plus bit to roll into carry
        mov     dx,-1           ;initialize rep-offset to 1
        xor     cx,cx           ;need ch=0
        mov     bp,es
        mov     bx,ds           ;cache for faster set/restore in copy routine

@@literals:
        mov     cl,1            ;initialize value to 1 (cx always 0 here)
        get_elias_full_ur          ;read number of literals to copy
        rep     movsb           ;copy literal bytes (cx can be 0 or 1!)

        shl     al,1            ;shift bit queue, and high bit into carry
        jc      @@get_offset    ;if 1: read offset, if 0: rep-match

@@rep_match:
        mov     cl,1            ;initialize value to 1 (cx always 0 here)
        get_elias_full_ur       ;read rep-match length (starts at 1)

@@copy_match:
        mov     ds,bp           ;ds=es
        push    si
        mov     si,di           ;point to destination in es:di + offset in dx
        add     si,dx
        rep     movsb           ;copy matched bytes (cx can be 0 or 1!)
        pop     si              ;restore si
        mov     ds,bx           ;restore ds

        shl     al,1            ;read 'literal or match' bit
        jnc     @@literals      ;if 0: go copy literals

@@get_offset:
        mov     cl,0feh         ;initialize value to FEh
        get_elias_full_ur       ;read high byte of match offset
        inc     cl              ;obtain negative offset high byte
        je      @@done          ;exit if EOD marker

        mov     dh,cl           ;transfer negative high byte into dh
        mov     cx,1            ;initialize match length value to 1
        mov     dl,[si]         ;read low byte of offset + 1 bit of len
        inc     si
        stc                     ;set high bit that is shifted into bit 15
        rcr     dx,1            ;shift len bit into carry/offset in place
        jc      @@got_offs      ;if len bit is set, no need for more

;continue partial decode of elias-gamma
        shl     al,1            ;read data bit
        rcl     cx,1            ;shift into cx
        get_elias_full_ur
@@got_offs:
        inc     cx              ;fix match length
        jmp     @@copy_match    ;go copy match

@@done:
;return # of decompressed bytes in ax
        pop     ax              ;retrieve the original decompression offset
        sub     di,ax           ;adjust for original offset
        xchg    di,ax           ;return adjusted value in ax
        retf                    ;done decompressing, exit to caller

ENDP    zx0_decompress_speed

ENDS

END

;Speed optimization history (decompression times in microseconds @ 4.77 MHz):
;Compression corpus: shuttle alice  robotro wordrun largetx linewar ...... ..
;Start of exercise    197369 158418  943394    4762 1575790 1565898 ******
;Repl. add w/bitops   197369 157392  942383    4762 1576800 1565732 *++*-+
;Repl. adc w/bitops   197380 157392  941343    4762 1577841 1564797 -*+*-+
;1+2 get_elias macro  191798 153153  867348    4710 1547180 1401299 ++++++
;3 get_elias macro    182037 140865  825617    4555 1441313 1337894 ++++++
;elias_bt macro       171307 130954  787532    4445 1342436 1296997 ++++++
;cx=1 -> cl=1         170342 130120  781529    4434 1337799 1273414 ++++++
;push/pop -> regs     163487 122781  738957    4349 1272837 1200430 ++++++
;unroll getelias x3   159560 117950  706226    4310 1210123 1149456 ++++++
;unroll eliasbt x2    157041 116781  700226    4234 1193691 1143040 ++++++
;unroll eliasbt x3    159394 116532  696673    4208 1190055 1140725 -+++++
;cache es/ds in copy  155597 114544  686430    4190 1171284 1123478 ++++++
;eliasbt -> getelias  152552 113669  674602    4122 1143357 1104346 ++++++
;unroll elias w/jumps 159678 120329  715175    4189 1189482 1185627 ------
;tiny unroll getelias 152265 113650  673453    4103 1140111 1104636 +++++-
