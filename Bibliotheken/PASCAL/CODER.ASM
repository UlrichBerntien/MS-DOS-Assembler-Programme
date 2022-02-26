; MS-Macro Assembler V3.04 / Wang PC
; (c) Ulrich Berntien .12.1987
; Version 1.0
; Format:  CODER <nicht codiert> <codiert>
; codieren einer Datei, der Codiertext wird über ein Pascalprogramm zur
; Verfügung gestellt.

Code	Segment
 Assume Cs: Code, DS : Code

top	EQU 2048		;Speicherbeginn für Buffer
vol	EQU 60 * 1024		;60 KBytes Buffergröße
Long	EQU Byte PTR Ds:80H
	ORG	100H

;** Namen decodieren
	MOV	Bx,0081H	;erstes Zeichen des Parameters
	MOV	Dx,Bx		;auch in Dx
	ADD	Dl,Long 	;Dx auf letztes Zeichen +1
	JNB	Lop0		;testen ob Übertrag
	INC	DH
Lop0:	INC	BX		;nächstes Zeichen
	CMP	BX,DX
	JG	ERR
	CMP	BYTE PTR [BX],32
	JZ	Lop0		;solange bis nicht Blank ist
	MOV	ADR1,BX 	;Adresse alten Namens
Lop2:	INC	BX		;nächstes Zeichen
	CMP	BX,DX
	JG	ERR
	CMP	BYTE PTR [BX],32
	JNZ	Lop2		;solange bis Blank
	MOV	BYTE PTR [BX],00 ;Name in ASCIZ Format
Lop3:	INC	BX		;nächstes Zeichen
	CMP	BX,DX
	JG	ERR
	CMP	BYTE PTR [BX],32
	JZ	Lop3		;solange bis kein Blank
	MOV	ADR2,BX 	;Adresse des alten Namns
	MOV	SI,DX
	MOV	BYTE PTR [SI],00 ;Name in ASCIZ Format
;** Files öffnen
	Mov	Dx,ADR1 	;altes File
	Mov	Ax,3D00H	;open for reading
	Int	21H		;DOS-Call
	Jc	ERRD		;bei Fehler
	Mov	Hand1,Ax	;file handle sichern
	Mov	Dx,ADR2 	;neues file
	Mov	Ax,3D01H	;open for writing
	Int	21H		;DOS-Call
	Jnc	W02		;kein Fehler
	Xor	Cx,Cx		;CX:= 0 keinen Zugriffsschutz
	Mov	Ah,3CH		;create file
	Int	21H		;DOS-Call
	Jc	ERRD		;bei Fehler
W02:	Mov	Hand2,Ax	;file handle sichern
	Mov	Si,Offset Codi	;Start des Coder Textes
	Mov	Di,Len
	Add	Di,Si		;Ende des Coder Textes
	Mov	Dx,top		;Start des Buffers
	Jmp	Lop4
;** Fehlermeldung ausgeben (hier abgespeichert weil Out OF Range Jumps)
ERRD:	MOV	CL,AL		;FehlerCode sichern
	SHR	AL,1
	SHR	AL,1		;Highnibel
	SHR	AL,1		;nach LoNibel schieben
	SHR	AL,1
	ADD	AL,'0'		;in ASCII Wert
	MOV	ET,AL		;Ausgabestring
	MOV	AL,CL
	AND	AL,0FH		;LoNibel
	ADD	AL,'0'		;in ASCII Wert
	MOV	ET+1,AL 	;in Ausgaestring
	Mov	CX,Text2-Text1	;Länge
	Mov	DX,offset Text1 ;Adresse
	JMP	OUT		;Ausgabe
ERR:	Mov	CX,ED-Text2	;Länge
	Mov	DX,offset Text2 ;Adresse
Out:	MOV	AL,0DH		;Ausgabe auf Monitor
	INT	88H		;BIOS-Call
	INT	20H		;DOS-Exit
;** Daten schaufeln
Lop4:	Mov	Bx,Hand1	;aus dem File lesen
	Mov	Cx,Vol		;Sollzahl der Bytes
	Mov	Ah,3FH		;read a File
	Int	21H		;DOS-Call
	Jc	ERRD		;bei Fehler
	Cmp	Ax,0		;alles gelesen ?
	Je	OK		; ja,fertig
	Mov	Cx,Ax		;Bytes
	Xor	Bx,Bx		;Bx:= 0
Lop5:	Mov	Ax,[Si] 	;fürs Codieren
	XOr	[top+Bx],Ax	;codiert
	Inc	Si		;nächtes Word
	Inc	Si
	Cmp	Si,Di		;am Ende ?
	Jl	W01
	Mov	Si,Offset Codi
	Dec	Di		;verkürzen
	Cmp	Di,Si		;geht nicht mehr ?
	Jg	W01
	Mov	Di,Len
	Add	Di,Si		;wieder den ganzen Text
W01:	Inc	Bx
	Inc	Bx		;nächstes Word
	Cmp	Bx,Cx		;alles durch ?
	JBE	Lop5
	Mov	Bx,Hand2	;in das File schreiben
	Mov	Ah,40H		;write a File
	Int	21H		;DOS-Call
	Jc	ERRD		;bei Fehler
	Jmp	Lop4
;** Programmablauf ordnungsgemäß beendet
OK:	Mov	Bx,Hand1	;handle laden
	Mov	Ah,3EH		;close a file
	Int	21H		;DOS-Call
	Mov	Bx,Hand2	;handle laden
	Mov	Ah,3EH		;close a file
	Int	21H		;DOS-Call
	Mov	Cx,EF-Text3	;Länge
	Mov	Dx,offset Text3 ;Adresse
	MOV	AL,0DH		;Ausgabe auf Monitor
	INT	88H		;BIOS-Call
	Int	20H		;Programm fertig

	EVEN
ADR1	DW ?			;Adresse alte Name
ADR2	DW ?			;Adresse neuer Name
Hand1	DW ?			;file handle
Hand2	DW ?
Text1	DB 'MS-DOS #'		;Text für Fehlerausgabe
ET	DB '00'
	DB ' ERROR during work'
Text2	DB 'wrong Parameter'
ED	DB ?
Text3	DB 'File codiert',13,10
EF	DB ?
	EVEN
Len	DW ?			;Länge des Codetextes
Codi	Label Byte		;Datentext zum Codieren

Code	EndS
	End
