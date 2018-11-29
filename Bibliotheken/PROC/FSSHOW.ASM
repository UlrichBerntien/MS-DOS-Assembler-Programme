        TITLE *** FS SHOW ***
        PAGE 68,132
        .SALL
;=====================================================================
; MS-Macro-Assmebler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1990
;   letzte Änderung 01.07.1990
;
;=====================================================================

; FPU Insturktion, dann wait für CPU
;---------------------------------------------------------------------
fp      MACRO opcods
          IRP x,<opcods>
            DB 0&&x
          ENDM
          wait
        ENDM

; Register Pushen
;---------------------------------------------------------------------
pushing MACRO regs
        IRP reg,<regs>
          push reg
        ENDM
        ENDM

; Register Popen
;---------------------------------------------------------------------
poping MACRO regs
        IRP reg,<regs>
          pop reg
        ENDM
        ENDM

;=====================================================================
asm_cod1 SEGMENT WORD 'PUBLIC'

ASSUME cs : asm_cod1

PUBLIC  fsshow

fall    STRUC
  controlw DW
  statusw  DW
  tagw     DW
           QW
  s0       TB
  s1       TB
  s2       TB
  s3       TB
  s4       TB
  s5       TB
  s6       TB
  s7       TB
fall    ENDS

fworld EQU [BP]
count  EQU DWORD [BP-90]

ssize = 92

;---------------------------------------------------------------------
fsshow  PROC NEAR
        pushf
        pushing <ax,bx,cx,dx,si,di,bp,ds>
        mov   bx,sp
        sub   sp,ssize
        wait
        fp <DDh,76h,0>     ; fsave [bp]
        mov   ax,sp
        mov   ds,ax                           ;ds := SEG stack
        mov   ax,statusw                      ;ax := FPU status word
        mov   cl,11
        slr   ax,cl                           ;schiebe stacktop bits nach rechts
        or    ax,0111B                        ;blende die andern bits aus
        mov   dx,tagw                         ;tag word in dx
        mov   cx,ax
        mov   si,bp
        add   si,10
bloop:  ror   dx,1                            ;das tag vom stack top nach rechts
        ror   dx,1
        add   si,10
        loop  bloop
        xor   cx,cx                           ;in cx die register zählen
aloop:




        inc   cx                              ;nächstes register
        cmp   cx,7                            ;es gibt die register 0..7
        jle   aloop                           ;bis alle register ausgeben

        fp <DDh,66h,0>     ; frstor [bp]
        add   sp,ssize
        poping <ds,bp,di,si,dx,cx,bx,ax>
        popf
        ret
fsshow  ENDP

asm_cod1 ENDS

        END
