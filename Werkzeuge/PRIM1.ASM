title PRIM1.ASM
; Primzhalensucher für PC's
; Benchmark aus MC 10/1987 Seite 74ff

z_p     equ 1000
cr      equ 0dH
lf      equ 0aH
ein     equ 0ffH
aus     equ 00H
ASCII_Offset_0 equ '0'

data    segment
prim            dw z_p dup(0), 2
anzahl_Prim     dw 0
rest            dw z_p + 1
z_basis         dw 10
bildschirm_ausgabe dw ein

zeit_h          db ?
zeit_min        db ?
zeit_sec        db ?
zeit_h_sec      db ?
data    ends

stack segment stack
                dw 128 dup (ß)
stack ends

code segment
assume cs:code,ds:data,ss:stack

main proc far
start:
        mov     ax,data
        mov     ds,ax
        xor     cx,cx
        xor     dx,dx
        mov     ah,2dH
        int     21H
        mov     di,2 * z_p
naechste_prim:
        inc     anzahl_prim
        dec     rest
        jz      fertig
        mov     ax,prim[di]
        sub     di,2
        mov     prim[di],ax
naechster_test:
        inc     prim[di]
        mov     si,2* z_p
naechster_divisor:
        mov     ax,prim[di]
        xor     dx,dx
        div     prim[si]
        cmp     dx,0
        je      naechster_test
        dec     si
        dec     si
        cmp     si,di
        jnbe    naechster_divisor
        call    ausgabe
        jmp     naechste_prim
fertig:
        call    system_zeit
        mov     ah,4cH
        int     21H
main    endp

ausgabe proc near
        push    di
        mov     ax,anzahl_prim
        call    dezimal_ausgabe
        mov     al,':'
        call    zeichen_ausgeben
        mov     ax,prim[di]
        call    dezimal_ausgabe
        mov     ax,cr
        call    zeichen_ausgeben
        mov     ax,lf
        call    zeichen_ausgeben
        pop     di
        ret
ausgabe endp

dezimal_ausgabe proc near
        xor     cx,cx
naechste_ziffer:
        inc     cx
        xor     dx,dx
        div     z_basis
        push    dx
        cmp     ax,0
        jne     naechste_ziffer
ziffer_ausgeben:
        pop     ax
        add     ax,ASCII_offset_0
        call    zeichen_ausgeben
        loop    ziffer_ausgeben
        ret
dezimal_ausgabe endp

zeichen_ausgeben proc near
        mov     dl,al
        mov     ah,2
        cmp     bildschirm_ausgabe, aus
        je      keine_ausgabe
        int     21H
keine_ausgabe:
        ret
zeichen_ausgeben endp

system_zeit proc near
        mov     bildschirm_ausgabe,ein
        mov     ah,2cH
        int     21H
        mov     zeit_min,cl
        mov     zeit_sec,dh
        mov     zeit_h_sec,dl
        xor     ah,ah
        mov     al,ch
        call    dezimal_ausgabe
        mov     al,':'
        call    zeichen_ausgeben
        xor     ah,ah
        mov     al,zeit_min
        call    dezimal_ausgabe
        mov     al,':'
        call    zeichen_ausgeben
        xor     ah,ah
        mov     al,zeit_sec
        call    dezimal_ausgabe
        mov     al,'.'
        call    zeichen_ausgeben
        xor     ah,ah
        mov     al,zeit_h_sec
        call    dezimal_ausgabe
        ret
system_zeit endp

code    ends
        end     start
