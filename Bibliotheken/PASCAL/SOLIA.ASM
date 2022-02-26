Name Solitaer
; Version 1.0
; MS-Macro-Assembler V1.1 /Wang PC
; (c) Ulrich Berntien .06.1985

Prog Segment 'Code'
Assume CS:Prog
Public	GibZug,MacheZug,Fertig

; Procedure GibZug(Var F :Feld; Var Platz,Richt :Word); Extern;
; Sucht im Feld ab platz nach möglichen Zügen
; Ausgabe von richt=9, wenn keine weitere gefunden

GibZug	Proc Far
	Push	BP			;Frame Pointer retten
	Mov	BP,SP
	Mov	DI,10[BP]		;Zeiger auf das Feld
	Mov	BX,8[BP]		;Zeiger auf Platz
	Add	DI,[BX] 		;DI auf aktuelle Position
	Mov	BX,6[BP]		;Zeiger auf Richt
	Mov	CX,[BX] 		;Richtung in CX
	Mov	BX,0303h		;Werte für bestzt
	Mov	DX,0402h		;Werte für Ende & frei
Loop1:	Mov	AL,[DI] 		;Wert der Position in AL
	Cmp	AL,DL			;freier Platz ? (DL=2)
	Jz	Loop2			; ja
	Cmp	AL,DH			;letzte Position ? (DH=4)
	Jz	Ende1			; ja
	Inc	DI			;nächster Platz
	Jmp	Loop1
Loop2:	Inc	CX			;nächste Richtung
	Cmp	CL,DL			;Richtung 2 ? (DL=2)
	Jl	Way1			; kleiner -> Richt.1
	Jz	Way2			; ja
	Cmp	CL,DH			;Richtung 4 ?  (DH=4)
	Jl	Way3			; kleiner -> Richt.3
	Jz	Way4			; ja
LoopE:	Sub	CX,CX			;keine Richtung ;mit 0+1 starten
	Inc	DI
	Jmp	Loop1			;nächter Platz
Way1:	Cmp	-9[DI],BL		;obererPlatz besetzt ?
	Jnz	Way1E			; nein, nächste richtung
	Cmp	-18[DI],BL		;oberer Platz besetzt ?
	Jz	Ende2			; ja,neue Möglichkeit gefunden
Way1E:	Inc	CX			; nein,nächste Richtung
Way2:	Cmp	-2[DI],BX		;linke Plätze besetzt ?
	Jz	Ende2			; ja, neue Möglichkeit gefunden
	Inc	CX			; nein,nächste Richtung
Way3:	Cmp	9[DI],BL		;unterer Platz besetzt ?
	Jnz	Way3E			; nein, nächste Richtung
	Cmp	18[DI],BL		;unterer Platz besetzt ?
	Jz	Ende2			; ja,neue Möglichkeit gefunden
Way3E:	Inc	CX			; nein,nächste Richtung
Way4:	Cmp	1[DI],BX		;rechte Plätze besetzt ?
	Jnz	LoopE			; nein, nächste Richtung
					;neue Möglichkeit gefunden
Ende2:	Mov	BX,6[BP]		;Zeiger auf Richtung
	Mov	[BX],CX 		;Richtung abspeicher
	Sub	DI,10[BP]		;Feldnummer errechnen
	Mov	BX,8[BP]		;Zeiger auf Platz
	Mov	[BX],DI 		;Nummer abspeichern
	Pop	BP			;Frame Pointer
	Ret	6			;zurück und Parameter entfernen
Ende1:	Mov	BX,6[BP]		;Zeiger auf Richtung
	Mov	Word PTR [BX],9 	;keine weitere Möglichkeit
	Pop	BP			;Frame Pointer
	Ret	6			;zurück und Parameter entfernen
GibZug	EndP

; Procedure MacheZug(Var F :Feld; Var Platz,Richt :Word); Extern;
; Ausführen des Zuges

MacheZug Proc Far
	Push	BP			;Frame Pointer retten
	Mov	BP,SP
	Mov	DI,10[BP]		;Zeiger auf Feldbegin
	Mov	BX,8[BP]		;Zeiger auf Positonsnum.
	Add	DI,[BX] 		;DI auf Platz
	Mov	BX,6[BP]		;Zeiger auf Richtung
	Mov	CX,[BX] 		;Richtung in CX
	Mov	Byte PTR[DI],3		;Platz besetzt
	Cmp	CX,2			;Richtung 2 ?
	Jl	Zug1			; kleiner ->Zug1
	Jz	Zug2			; ja
	Cmp	CX,3			;Richtung 3 ?
	Jz	Zug3			; ja
Zug4:	Mov	Word PTR 1[DI],0202h	;freie Plätze
	Pop	BP			;Frame Pointer
	Ret	6
Zug1:	Mov	Byte PTR -9[DI],2	;frei
	Mov	Byte PTR -18[DI],2	;frei
	Pop	BP			;Frame Pointer
	Ret	6
Zug2:	Mov	Word PTR -2[DI],0202h	;freie Plätze
	Pop	BP			;Frame Pointer
	Ret	6
Zug3:	Mov	Byte PTR 9[DI],2	;frei
	Mov	Byte PTR 18[DI],2	;frei
	Pop	BP			;Frame Pointer
	Ret	6
MacheZug EndP

; Function Fertig(Var F :Feld):Byte;
; gibt die Anzahl der bestzten Plätze, wenn die Mitte besetzt ist,
; sonst wird 0 ausgegeben

Fertig	Proc Far
	Push	BP			;Frame Pointer retten
	Mov	BP,SP
	Mov	DI,6[BP]		;Zeiger auf Feld
	Mov	SI,DI			;Zeiger in SI
	Add	SI,40			;SI auf Mitte
	Cmp	Byte PTR[SI],3		;Mitte besettzt ?
	Jz	LoopB			; ja
	Mov	AL,0			;Mitte nicht bestzt
	Pop	BP			;Frame Pointer
	Ret	2
LoopB:	CLD				;Richtungsflag abwärts
	Sub	AH,AH			;AH Null setzen
	Add	DI,12			;DI auf ersten Platz
	Mov	AL,3			;Vergleichen mit 3
LoopF:	ScasB				;Wert des Platzes
					;Zeiger auf nächstes
	Jl	EndeT			; letzer Platz
	Jg	LoopF			; frei oder außen
	Inc	AH			;bestzter Paltz
	Jmp	LoopF			;wieder in Schleife
EndeT:	Mov	AL,AH			;letztes Feld
	Pop	BP			;Frame Pointer
	Ret	2
Fertig	EndP

Prog	EndS
	End
