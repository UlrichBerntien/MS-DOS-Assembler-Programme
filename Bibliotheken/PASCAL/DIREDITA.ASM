; Unterprogramme für DirEdit.Pas
; Version 1.0
; MS-Macro-Assembler V1.0 /Wang PC
; (c) Ulrich Berntien .04.1987

; Function DiskR( DrNr, Sec, Beg : Word, X :ADRMem ): Boolean
;   absulutes Lesen von Disk
; Function DiskW( DrNr, Sec, Beg : Word, X :ADRMem ): Boolean
;   absulutes Schreiben auf Disk
; Parameter:
;   DrNr   [10]   Drive Number ( 0=A, 1=B, .. )
;   Sec    [ 8]   Number of Sector to read/write
;   Beg    [ 6]   Beginning logical record number
;   X	   [ 4]   Transfer address (DS offset)

ASM	Segment Public 'Code'
Assume Cs : ASM
Public DiskR,DiskW

DiskR	Proc Far
	Mov	Cs:Save,Bp		;Sichern des Frame Pointers
	Mov	Bp,Sp			;zur Stack Adressierung
	Mov	Al,10[Bp]		;Al:= DrNr
	Mov	Cx,08[Bp]		;Cx:= Sec
	Mov	Dx,06[Bp]		;Dx:= Beg
	Mov	Bx,04[bp]		;Ds:Bx := ADS X
	Int	25H			;DOS-Call - Read Disk
	Pop	Ax			;Stack säubern
	Mov	Bp,Cs:Save		;Frame Pointer zurück
	Jc	false1			;bei Fehler
	Mov	Ax,01			;True zurück
	Ret
false1: Mov	Ax,00			;False zurück
	Ret
DiskR	EndP

DiskW	Proc Far
	Mov	Cs:Save,Bp		;Sichern des Frame Pointers
	Mov	Bp,Sp			;zur Stack Adressierung
	Mov	Al,10[Bp]		;Al:= DrNr
	Mov	Cx,08[Bp]		;Cx:= Sec
	Mov	Dx,06[Bp]		;Dx:= Beg
	Mov	Bx,04[Bp]		;Ds:Bx := ADS X
	Int	26H			;DOS-Call - Write Disk
	Pop	Ax			;Stack säubern
	Mov	Bp,Cs:Save		;Frame Pointer zurück
	Jc	false2			;bei Fehler
	Mov	Ax,01			;True zurück
	Ret
false2: Mov	Ax,00			;False zurück
	Ret
DiskW	EndP

Save	DW (?)

ASM	EndS
	End
