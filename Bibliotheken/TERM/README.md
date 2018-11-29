# Dokumentation der Unterprogramme

Programmierspachen:

-      Microsoft MACRO Assembler Version 1.1
-      Microsoft Pascal Compiler Version 3.04

Computersystem:

-         Wang PC
-         Drucker Epson FX-80

Programmierer:

-         Ulrich Berntien .06.1985 - .07.1988


##      Unterprogramme zur Nutzung des Wang PC Terminals

Es wird die globale Variable TTSIB benutzt!

#### Procedure Term

   Die Prozedure wird durch das Interface 'Term.PIn' aufgerufen.
   Sie stellt für folgende Prozeduren die Adresse TTSIB zur Verfügung,
   löscht den Bilschirm, löscht alle Attribut, lehrt den Tastaturbuffer
   und schaltet den Cursor ein.

#### Procedure CRRS( Nr :Integer );

   0 - Cursor einschalten  / 1 - ausschalten

   2 - Blinken einschalten / 3 - ausschalten

   4 - Underline           / 5 - Block


#### Type Attribute = Set of (Top,Down,Under,Over,Bold,Blank,Reverse,Blink);

#### Procedure ATTR (Para :Attribute);

   die Schriftart wird nach dem Parameter geändert, es bedeuten:
   Top   - Superscript          Down  - Subscript
   Under - Underline            Over  - Overline
   Bold  -                      Blank -
   Reverse                      Blink

#### Procedure ClLine( Y :Integer )

   Die Zeile Y ( 1..25 ) wird gelöscht, der Cursor steht am Anfang
   dieser Zeile.

#### Procedure GotoXY( X,Y :Integer )

   Die nächste Schreibposition ist (X/Y), der Cursor bleibt aber bis zu
   dieser Ausgabe an der alten Position. ( X =1..80 / Y =1..25 )

#### Procedure WhereXY(Var X,Y :Integer );

   Den Variablen X,Y wird die aktuelle Cursorposition zugewiesen.

#### Procedure PutChar( x,y :Integer, c :Char, a :Attribute );

   Setzt das Zeichen c mit den Attributen a an die Stelle
   (x,y) des Bildschirmspeichers

#### Procedure PutATTR( x,y :Integer, a :Attribute );

   Gibt dem Zeichen auf der Position (x,y) im Bildschirm-
   speicher die Attribute a

#### Function GetChar( x,y :Integer ): Char;

   Liest das Zeichen an der Position (x,y) in dem Bild-
   schirmspeicher

#### Procedure SCRDump;

   Die Procedure druckt den Inhalt des Bildscirms aus. Dabei wird die letzte
   Spalte nicht gedruckt, ebenso werden Attribute nicht berücksichtigt.

#### Type GenM = Array [1..12] of Byte;

#### Procedure GetGen( n :Integer; Var z :GenM );

  Liest von Zeichen# n das Font aus den Zeichengenerator

#### Procedure PutGen( n :Integer; Var z :GenM );

  Schreibt bei Zeichen# n das Font z in den Zeichengenerator

#### Procedure CTrap ( On :Boolean )

   Ein/Ausschalten der Verarbeitung der KTRL-C Taste bei DOS Aufrufen
   über Funktion 33H.

#### Procedure LED( Nr :Integer On :Boolean )

   Das Unterprogramm schaltet die LED der Tastatur (Nr.0 bis Nr.5) an(=true)
   oder aus(=false). Ist die Nummer -1 werden alle LEDs an-/ausgeschaltet.

#### Function InKey :Byte

   Die Funktion übergibt den WISCII-Wert der gedrükten Taste, ist keine
   Taste gedrückt wird der Wert 00 ausgegeben.

#### Function WaitKey :Byte

   Die Funktion übergibt den WISCII-Wert der gedrükten Taste, ist keine
   Taste gedrückt wartet die Prozedure auf eine Taste

#### Function ReadInt :Integer

   Die Funktion liest einen Integerwert ( -32749 bis 32749 ) von der Tastaur
   und gibt ihn auf dem Bildschirm aus. Die Tasten 0,1..,9,BS,CR werden be-
   rücksichtigt. Ist die Zahl größer als +-32749 wird +-MaxInt zurückgegeben.

#### Procedure PortOut( Nr : Word; x : Byte );

   Die Procedure gibt das Byte X auf den Port Nr aus


##    Unterprogramme zur Druckeransteuerung


Procedure SetTrans
   Die Prozedure schaltet den Transparentmodus ein,
   d.h. alle Zeichen zum Drucker werden ohne Code-
   wandlung übertragen

Procedure DelTrans
   Die Prozedure hebt den Transparentmodus auf

Procedure WriteP( Was : Char );
   Direkte Ausgabe des Charakters Was auf dem Parallelausgang. Vor der Ausgabe
   wird auf das READY-signal des Druckers gewartet.

Procedure ReadP : Byte;
   Liest das Statusbyte der Parallelschnittstelle ein. Es bedeuten:
   Bit 4 (10h) = Busy
   Bit 5 (20h) = Ready
   Bit 6 (40h) = End of Paper [meist zusammen mit Busy]


