* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical DBU                                              ³
* ³  Description: To Copy dbf files using copy to and to append using append ³
* ³               From                                                       ³
* ³    File Name: COPYBOX.PRG                                                ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: þ10-29-95              ³
* ³ Time created: 08:26:14pm            Time updated: þ08:26:14pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Computer Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#INCLUDE "llibg.CH"
#INCLUDE "INKEY.CH"
#DEFINE LISTBOX_COLOR "W+/B,GR+/B,W+/B,N/B,GR+/B,N/B,B+/B,GR+/B"

STATIC lAll
STATIC lText
Function DoCopy(n)
   local nT := 6, nL := 9, nB := 25, nR := 68
   local GetList := {}
   local aTitle := {"COPY","APPEND"}
   local cCopyFrom, cCopyTo := space(128)
   local lOk := .T., lCxl := .T., lAns := .F., nWhich := 0, oRb
   local cClrSpc := "R/W,B/W,G/W,GR/W,B/W,R/W,G/W"
   local aButtons := {}
   local cFor := Space(255), cWhile := Space(255), cFields := Space(255)
   local cScope := "ALL", cText := " "
   local bFor, bWhile, cFile, aFields, nNext,nRec, lRest := .T.
   local cRdd := "DBFNTX", aList := {"DBFNTX","DBFCDX","DBFNDX","DBFMDX"}
   local cScreen := SaveScreen( nT, nL, nB+1, nR+1)
   local lCopy := .F.
   cCopyFrom := Padr(Upper(Alias()),8)

   IF !Used()
      MessageBox("No database open....")
      Return .F.
   ENDIF
   lAll := 1
   lText := 1
   oRb := RadioButton(20,13, "&Dbf")
   oRb:ColorSpec := cClrSpc
   oRb:Bitmaps := {"RADIO_F.BMU","RADIO_E.BMU"}
   AADD( aButtons, oRb )

   oRb := RadioButton(20,35, "&Delimited")
   oRb:ColorSpec := cClrSpc
   AADD( aButtons, oRb )

   oRb := RadioButton(20,56, "&Sdf")
   oRb:ColorSpec := cClrSpc
   AADD( aButtons, oRb )

   MHide()
   GFRAME((nL*8), (nT*16), (nR*8)+8, (nB*16)+16, 7, 15, 8,20, 3, 3, 3, LLG_MODE_SET)
   GWRITEAT( (nL*8)+180,;
      (nT*16)+4,;
      aTitle[n],;
      4,;
      LLG_MODE_SET)
   @ 09, 18 GET cCopyFrom When {|| .F. } Color "B/BG"
   if n == 1
      @ 8, 18 SAY "Copy from" Color "B/w"
      @ 8, 53 say "Copy to" Color "B/w"
      @ 09, 45 GET cCopyTo picture "@!S21" VALID {||!Empty(cCopyTo) } Color "B/BG,W+/N"
   else
      @ 8, 18 SAY "Append to" Color "B/w"
      @ 8, 53 say "Append from" Color "B/w"
      @ 09, 45 GET cCopyTo picture "@!S21" ;
         When {||CallDial() } color "B/BG,W+/N"
   endif
   @ 8, 30 SAY "    Rdd    " Color "B/W"
   @ 09, 30,15,40 Get cRdd LISTBOX aList DROPDOWN SCROLLBAR ;
      Color LISTBOX_COLOR

   @ 11, 12 Say "FIELDS......: " Color "B/W"
   @ 11, Col() GET cFields Picture "@KS40" color "B/BG"

   @ 13, 12 Say "FOR CLAUSE  : " Color "B/W"
   @ 13, Col() GET cFor   Picture "@KS40" color "B/BG"
   @ 15, 12 Say "WHILE CLAUSE: " Color "B/W"
   @ 15, Col() GET cWhile Picture "@KS40" WHEN {||Empty(cFor) }color "B/BG"
   @ 17, 12 Say "SCOPE.......: "  Color "B/W"
   @ 17, Col() GET cScope When {||SetSpace(.T.)} color "B/BG"
   @ 19, 10, 21, 67 Get nWhich RadioGroup aButtons VALID {|o|SetText(o) }Color "R/W,W/W,B/W"
   @ 22, 12 Say "DELIMITED WITH..: "  Color "W/W"
   @ 22, Col() GET cText When {||SetSpace(.F.,nWhich)} color "W/W"
   @ 24, 29 GET lOk   PUSHBUTTON CAPTION "  OK  " ;
      STATE {||CkButton(@lAns),Readkill(.T.) } COLOR "W/W,W/W,W/W,W/W"
   @ 24, 42 GET lCxl  PUSHBUTTON CAPTION "Cancel" ;
      STATE {||CkButton(@lAns),READKILL(.T.) } COLOR "W/W,W/W,W/W,W/W"
   MShow()
   read
   IF Lastkey() != 27 .OR. lAns
      cCopyTo := Alltrim(cCopyTo)
      IF !Empty(cFor)
         bFor := &("{||"+cFor+"}")
      ENDIF
      IF !Empty(cWhile)
         bWhile := &("{||"+cWhile+"}")
      ENDIF
      IF lAll == 1
         lRest := .T.
      ElseIF lAll == 2
         lRest := .F.
         nNext := Val(cScope)
      ElseIF lAll == 3
         lRest := .F.
         nRec := Val(cScope)
      ENDIF
      IF ValType(bFor) = 'B' .OR. ValType(bWhile) = 'B'
         lRest := .F.
      ENDIF
      IF Empty(cText)
         cText := ","
      ENDIF
      IF !Empty(cFields)
         aFields := ListAsArray(cFields, "|")
      else
         aFields := {}
      ENDIF
      IF n == 1
         lCopy := .T.
      ENDIF
      DO CASE
      CASE nWhich == 1
         // DBF
         if n == 1
            __DBCopy(cCopyTo,       ;
               aFields,        ;
               bFor,           ;
               bWhile,         ;
               nNext,          ;
               nRec,           ;
               lRest,          ;
               cRdd )
         else
            __DBApp(cCopyTo,       ;
               aFields,        ;
               bFor,           ;
               bWhile,         ;
               nNext,          ;
               nRec,           ;
               lRest,          ;
               cRdd )
         endif

      case nWhich == 2
         // Delimited
         __DBDelim(lCopy,cCopyTo,  ;
            cText,          ;
            aFields,        ;
            bFor,           ;
            bWhile,         ;
            nNext,          ;
            nRec,           ;
            lRest )

      case nWhich == 3
         // Sdf
         __DBSdf(lCopy,cCopyTo,    ;
            aFields,        ;
            bFor,           ;
            bWhile,         ;
            nNext,          ;
            nRec,           ;
            lRest )
      endcase
   Else

   endif
   RestScreen( nT, nL, nB+1, nR+1, cScreen)
   SetKey(K_SPACE)
Return .T.

Function CkButton(lok)
   local o := GetActive():Control

   IF Alltrim(Upper(o:Caption)) == Alltrim(Upper("Ok"))
      lOk := .T.
   Else
      lOk := .F.
   ENDIF
Return .T.

Function ValueSet(lScope)
   local oGet := GetActive()
   local lRet := .T.
   IF lAll == 1

      @ 17,26 Say "NEXT" Color "B/W"
      oGet:Row := 17
      oGet:Col := 33
      oGet:VarPut("     ")
      oGet:Picture := "99999"
      oGet:ColorDisp("B/BG")
      oGet:Reset()
      oGet:Display()
      lAll := 2

   ElseiF lAll == 2

      @ 17,26 Say "RECORD" Color "B/W"
      oGet:Row := 17
      oGet:Col := 33
      oGet:VarPut("     ")
      oGet:Picture := "99999"
      oGet:ColorDisp("B/BG")
      oGet:Reset()
      oGet:Display()
      lAll := 3

   ElseIf lAll == 3

      @ 17, 29 SAY "         " Color "W/W"
      oGet:Row := 17
      oGet:Col := 26
      oGet:VarPut("ALL")
      oGet:Picture := "XXX"
      oGet:ColorDisp("B/BG")
      oGet:Reset()
      oGet:Display()
      lAll := 1

   ENDIF
Return lRet

Function SetSpace(lSet, n)
   local lRet := .F.
   local oGet := GetActive()
   IF (Upper(oGet:Name) != 'CTEXT')
      SetKey(K_SPACE, {||ValueSet(lSet) })
      lRet := .T.
   ElseIF ( n > 1 )
      SetKey(K_SPACE, {||ValueSet(lSet) })
      oGet:ColorDisp("BG/B")
      oGet:Reset()
      oGet:Display()
      lRet := .T.
   ENDIF
Return lRet

Function SetText(o)
   local n := o:Varget()
   IF n == 2
      @ 22, 12 Say "DELIMITED WITH..: "  Color "B/W"
   ENDIF
Return .T.

Function CallDial()
   local oGet := GetActive()
   local cFile
   local lRet := .T.
   cFile := OpenDialog("*.*")
   IF !Empty(cFile)
      oGet:VarPut(cFile)
      oGet:Display()
      lRet := .F.
   ENDIF
Return lRet
