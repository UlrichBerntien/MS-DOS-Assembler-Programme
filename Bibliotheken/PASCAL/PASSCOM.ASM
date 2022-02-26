; MS-Macro Assembler V1.1
; (c) Ulrich Berntien .12.1987


Ver1	Segment
 Assume Ds:Ver1, Cs:Ver1
	ORG 0
	Mov	Dx,Offset T1
	Mov	Cx,Word PTR E1	;Länge
	Mov	Al,0DH		;Zeichenkette ausgeben
	Int	88H		;BIOS-Call
L2:	Xor	Bx,Bx		;Bx:= 0
L1:	Mov	Ah,07H		;direct consol input
	Int	21H		;DOS-Call
	Xor	Al,[StartC+Bx]	;codieren
	Cmp	Al,[StartP+Bx]
	Jne	L4		; wenn falsch
	Inc	Bx
	Cmp	Bx,Len
	Jle	L1
	Mov	Bx,000DH	;CR-LF ausgben
	Mov	Al,06H
	Int	88H
	Mov	Bx,000AH
	Mov	Al,06H
	Int	88H
	Jmp	StartC
L4:	Cmp	Al,03		;KTRL - C ?
	Je	L2		; ja, wieder neu
	Mov	Ah,07H		;direct consol input
	Int	21H		;DOS-Call
	Jmp	L4		;Schleife
T1:	DB 'PASSWORD:'
E1 = $ - Offset T1
	ORG 1000H
StartC:
StartP:
Len = 10
Ver1	EndS

Ver2	Segment
 Assume Ds:Ver2, Cs:Ver2
	ORG 0
	Mov	Dx,Offset T01
	Mov	Cx,Word PTR E01 ;Länge
	Mov	Al,0DH		;Zeichenkette ausgeben
	Int	88H		;BIOS-Call
L02:	Xor	Bx,Bx		;Bx:= 0
L01:	Mov	Ah,07H		;direct consol input
	Int	21H		;DOS-Call
	Xor	Al,[StartC0+Bx] ;codieren
	Cmp	Al,[StartP0+Bx]
	Jne	L04		; wenn falsch
	Inc	Bx
	Cmp	Bx,Len
	Jle	L01
	Mov	Bx,000DH	;CR-LF ausgben
	Mov	Al,06H
	Int	88H
	Mov	Bx,000AH
	Mov	Al,06H
	Int	88H
	Mov	Cx,02		;Tastaturclicker ausschalten
	Mov	Dx,Offset T02
	Mov	Al,07H
	Int	88H
	Jmp	StartC0
L04:	Cmp	Al,03		;KTRL - C ?
	Je	L02		; ja, wieder neu
	Mov	Ah,07H		;direct consol input
	Int	21H		;DOS-Call
	Jmp	L04		;Schleife
T01:	DB 'PASSWORD:'
E01 = $ - Offset T01
T02:	DB 20H,01H
	ORG 1000H
StartC0:
StartP0:
Len0 = 10
Ver2	EndS

	End
