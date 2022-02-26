; Unterprogramme zu Look.Pas
; Varsion 1.0
; MS-Macro-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .10.1986

; Function Readdisk( s,d,b : Word; x : Adrmem ): Boolean; Extern;
;  s - logical record number (12)
;  d - Drive number 0 = A  (10)
;  b - number of Bytes to Transfer (8)

Data	Segment Public 'Data'
 DGroup Group Data
 Assume DS : DGroup

Extrn	BpSector : Word
Mem	DB 1024 Dup (?)
Save	DW

Data	EndS

Look	Segment Public 'Code'
 Assume CS : Look
 Public ReadDisk

ReadDisk Proc Far
	Push	Bp		;Frame-Pointer retten
	Mov	Bp,Sp
	Mov	Save,Bp
read:	Mov	Al,10[Bp]	;Drive#
	Mov	Cx,01		;one sector read
	Mov	Dx,12[Bp]	;logical record#
	Mov	Bx,Offset DGroup:Mem ;in Mem
	Int	25H		;absolute disk read
	Mov	Bp,Save
	Jc	false		;Fehler
	Pop	Dx		;Stack säubern von Int 25H
	Inc	Word PTR 12[Bp] ;next record
	Mov	Bx,6[Bp]	;Adresse in Bi
	Mov	Ax,8[Bp]	;#of bytes
	Mov	Cx,BpSector	;Zahl der gelesenen Bytes
	Xor	Si,Si		;Si:= 0
Loop:	Mov	Dl,Mem[Si]
	Mov	[Si+Bx],Dl	;one Byte transfer
	Inc	Si
	Dec	Ax
	Jng	true		;fertig
	Dec	Cx
	Jg	Loop		;next Byte
	Add	Bx,Si		;Neue Adresse
	Mov	6[Bp],Bx	;Adresse für den Rest
	Mov	8[Bp],Ax	;noch zu lesende Bytes
	Jmp	read
true:	Mov	Al,01		;Alles klar
	Jmp	Ende
false:	Mov	Al,00		;Fehler bei Diskzugriff
	Pop	Dx		;Stack säubern von Int 25H
Ende:	Pop	Bp		;Frame-Pointer holen
	Ret	8		;zurück und Stack säubern
ReadDisk EndP

Look	EndS
	End
