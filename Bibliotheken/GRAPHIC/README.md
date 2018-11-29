# Dokumentation der Unterprogramme

Programmierspachen:

-      Microsoft MACRO Assembler Version 1.1
-      Microsoft Pascal Compiler Version 3.04

Computersystem:

-         Wang PC
-         Drucker Epson FX-80

Programmierer:

-         Ulrich Berntien .06.1985 - .07.1988

## Unterprogramme zur Nutzung der Wang Grafikkarte

-   Alle X-Werte müssen im Bereich von 0..799 liegen
-   Alle Y-Werte müssen im Bereich von 0..299 liegen
-   Sind diese Bedingung nicht erfüllt, so wird das Unterprogramm ohne
-   Fehlermeldung verlassen. Ausgenommen sind die Boolean-Funktionen.
-   Es werden die globalen Variablen GGSeg,GGSta,GGOut benutzt!

#### Procedure Graphic

   Holt die nötigen Daten für die Grafikroutinen
   Die Prozedure muß einmal vor benutzung der Grafik aufgerufen werden
   Sie wird bei dem Interface 'Graphic.PIn' automatisch aufgerufen

#### Procedure Dot( X,Y :Integer )

   Setzt den Punkt (X/Y) auf dem Grafikbildschirm

#### Procedure CDot( X,Y :Integer )

   Löscht den Punkt (X/Y) auf dem Grafikbildschirm

#### Procedure LineV( Y1,Y2,X :Integer )

   Zieht eine Linie vertikal von (X,Y1) nach (X,Y2)

#### Procedure CLineV( Y1,Y2,X :Integer )

   Löscht eine Linie vertikal von (X,Y1) nach (X,Y2)

#### Procedure LineH( X1,X2,Y :Integer )

   Zieht ein Linie horizontal von (X1/Y) bis (X2/Y)

#### Procedure CLineH( X1,X2,Y :Integer )

   Löscht ein Linie horizontal von (X1/Y) bis (X2/Y)

#### Procedure LineP( X1,Y1,X2,Y2 :Integer )

   Zieht eine Linie von Punkt( X1,Y1 ) nach Punkt( X2,Y2 )

#### Procedure CLineP( X1,Y1,X2,Y2 :Integer )

   Löscht eine Linie von Punkt( X1,Y1 ) nach Punkt( X2,Y2 )

#### Procedure PutBild( Var  GDaten : Bild; X,Y : Integer )

  Die Funktion gibt ein Punktmuster auf den Grafikbildschirm mit Hilfe einer
  XOR-Operation aus, d.h. dort wo im Bild ein Punkt gesetzt ist wird der
  Punkt auf dem Grafikbildschirm invertiert. Die Koordinate X,Y bezieht
  sich auf den linken oberen Punkt des Bildes. Im GDaten-Array bedeutet:

   GDaten[1] = Breite des Bildes in 16er !! Punkten

   GDaten[2] = Höhe des Bildes ,max. 256 Zeilen

   GDaten[.] = Bildpunkte ,Zeilenweise

#### Procedure Invert

   Der Grafikbildschirm wird invertiert.

#### Procedure Roll( R : Integer )

   Der Grafikbildschirm wird gerollt

   1 - up , 2 - right , 3 - down , 4 - left

#### Procedure Print

   Ausdruck des Grafikbildschirm auf dem FX-80, der Bildschirminhalt wird

   dazu um 90° gedreht, um auf ca. eine A4-Seite zu passsen

#### Function Load( Const Name :String ): Boolean

   Der Grafikbildschirm wird aus dem File mit der Bezeichnung NAME geladen.
   Tritt ein Fehler bei der Abarbeitung des Unterprogrammes auf, wird
   der Wert FALSE zurückgegeben.

#### Function Save( Const Name :String ): Boolean

   Der Grafikbildschirm wird unter der Bezeichnung NAME abgespeichert.
   Tritt ein Fehler bei der Abarbeitung des Unterprogrammes auf, wird
   der Wert FALSE zurückgegeben.

