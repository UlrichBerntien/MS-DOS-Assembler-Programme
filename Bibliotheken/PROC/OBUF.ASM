        TITLE *** MODUL obuf ***
        PAGE 70,132
;=====================================================================
; MS-Macro-Assembler V1.10 /Wang PC
; (c) Ulrich Berntien .07.1989
;   letzte Änderung 11.12.1989
;
; Schreiben von Buffer in File.
;
; OBUF_CREATE : NEAR
;       -> ES:DX - pointer to asciz filename
;       <- CARRY
;       File neu erstellen.
;
; OBUF_APPEND : NEAR
;       -> ES:DX - pointer to asciz filename
;       <- CARRY
;       An ein bestehendes File anhängen.
;
; OBUF_PTR : NEAR
;       -> ES:DX - pointer to buffer
;       Gibt die Adresse des Buffers an.
;
; OBUF_PUT : NEAR
;       -> CX - Anzahl der Bytes
;       <- CARRY
;       Schreiben aus Buffer in das File
;
; OBUF_CLOSE : NEAR
;       <- CARRY
;       File schließen.
;
; Das CARRY wird von der entsprechenden DOS-function übernommen.
; Bei gestzetn CARRY wird wird der Fehlercode in ERR_STATUS abgelegt.
;
;=====================================================================
; Die Register (ohne Flags) werden bei allen Procs erhalten.
; DS immer auf das DATA segment
; CS immer auf das CODE segment
; alle Procs sind vom Typ NEAR
; trift eine Proc auf einen DOS-Fehler, so wird er i.a. über Carry
; weitergmeldet und der error-code aus AX in err_status abgelegt.
;=====================================================================

dos = 21H                  ;dos interface interrupt vector

;=====================================================================
data    SEGMENT WORD PUBLIC 'data'

EXTRN err_status : WORD

        EVEN
handle  DW 0FFFFH          ;file handle
buf_adr DD ?               ;ads of buffer
data    ENDS

; --------------------------------------------------------------------
push_reg MACRO regs
        IRP reg,<regs>
          push reg
        ENDM
        ENDM

; --------------------------------------------------------------------
pop_reg MACRO regs
        IRP reg,<regs>
          pop reg
        ENDM
        ENDM

;=====================================================================
code    SEGMENT WORD PUBLIC 'code'
ASSUME  cs : code, ds : data, es : nothing

PUBLIC  obuf_create, obuf_append, obuf_ptr, obuf_put, obuf_close

; l0100 --------------------------------------------------------------
obuf_create PROC NEAR
        push_reg <ax,cx,ds>
        mov   ax,es                           ;ds:dx to filename
        mov   ds,ax
        xor   cx,cx                           ;cx := no file protection
        mov   ah,3CH                          ;create a file
        clc
        int   dos
        pop   ds
        jnc   l0100
        mov   err_status,ax                   ;falls fehler bei dos
        jmp   l0101
l0100:  mov   handle,ax                       ;filehandle merken
l0101:  pop_reg <cx,ax>
        ret
obuf_create ENDP

; l0200 --------------------------------------------------------------
obuf_append PROC NEAR
        push_reg <ax,bx,cx,dx,ds>
        mov   ax,es                           ;ds:dx to filename
        mov   ds,ax
        mov   ax,3D01H                        ;open file for writing
        clc
        int   dos
        pop   ds
        jnc   l0200
        mov   err_status,ax                   ;falls fehler bei dos
        jmp   l0202
l0200:  mov   handle,ax                       ;filehandle merken
        mov   bx,ax                           ;bx := filehandle
        xor   cx,cx
        mov   dx,cx                           ;dx:cx := 0
        mov   ax,4202H                        ;move write ptr to eof +dx:cx
        int   dos
        jnc   l0202
        mov   err_status,ax                   ;falls fehler bei dos
l0202:  pop_reg <dx,cx,bx,ax>
        ret
obuf_append ENDP

; l0300 --------------------------------------------------------------
obuf_ptr PROC NEAR
        mov   WORD PTR buf_adr,dx
        mov   WORD PTR buf_adr+2,es
        ret
obuf_ptr ENDP

; l0400 --------------------------------------------------------------
obuf_put PROC NEAR
        push_reg <ax,bx,dx,ds>
        mov   bx,handle                       ;bx := filehandle
        lds   dx,buf_adr                      ;ds:dx auf buffer
        mov   ah,40H                          ;write a file
        int   dos
        clc
        pop   ds
        jnc   l0400
        mov   err_status,ax                   ;falls fehler bei dos
l0400:  pop_reg <dx,bx,ax>
        ret
obuf_put ENDP

; l0500 --------------------------------------------------------------
obuf_close PROC NEAR
        push_reg <ax,bx>
        push  bx
        mov   bx,handle                       ;bx := filehandle
        mov   handle,0FFFFH                   ;der wird wohl immer falsch sein
        mov   ah,3EH                          ;close a file
        clc
        int   dos
        jnc   l0500
        mov   err_status,ax                   ;falls fehler bei dos
l0500:  pop_reg <bx,ax>
        ret
obuf_close ENDP

code    ENDS

;=====================================================================
        END
