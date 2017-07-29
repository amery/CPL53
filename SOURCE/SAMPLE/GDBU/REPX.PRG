#include "llibg.ch"
#INCLUDE "INKEY.CH"
STATIC lAll
Function ReplIt()
   local nMT := 3, nML := 1, nMB := 23, nMR := 78
   local nBT := 7, nBL := 4, nBB := 13, nBR := 54
   local CFILENAME, cForCond := Space(55), cWhileCond := Space(55)
   local cScope := "ALL", cBrowse := Space(8)
   local aRepl := {{Space(8), Space(255)}}, GetList := {}
   local oBrowse, i, oCol, lAns := .F., lOk := .T., lCxl := .F.
   local nRow := 1, aFont, cList, cString,  bAction
   local bFor := NIL, bWhile := NIL, nNext := NIL, nRecord := NIL
   local lRet := .T., cScreen := SaveScreen( nMT, nML, nMB+1, nMR+1)

   lAll := 1

   IF !Used()
      MessageBox("No databases open")
      Return .F.
   ENDIF
   cFileName := Padr(Alias(),8)
   MHide()
   //Main box
   GFRAME( (nML*8), (nMT*16), (nMR*8)+8, (nMB*16)+16, 7, 15, 8, 12, 12, 12, 12, LLG_MODE_SET)

   // Browse Box
   GFRAME((nBL*8)-4, (nBT*16)-8, ((nBR*8)+8)+3, ((nBB*16)+16)+3, 7, 15, 8, 9, 3, 3, 3, LLG_MODE_SET)
   aFont := GFntLoad("TNR36.fnt")
   GWriteAt( (nML*8)+300, (nMT*16)+4,"Replace", 4, LLG_MODE_SET,aFont)

   SETCOLOR("+W/B")

   oBrowse := TBrowseDB(nBT, nBL, nBB, nBR)
   oBrowse:GoTopBlock := {|| nRow := 1 }
   oBrowse:skipBlock:= {|nReq| ArraySkip(nReq, aRepl, @nRow)}
   oBrowse:GoBottomBlock := {|| nRow := Len(aRepl) }

   oCol:= TBColumnNew("Fields",{|p|If(PCount() > 0, ;
      aRepl[nRow,1] := p, aRepl[nRow,1]) })
   oCol:Width := 8
   oBrowse:AddColumn(oCol)

   oCol:= TBColumnNew("With Expresion", {|p|If(PCount() > 0, ;
      aRepl[nRow,2] := p, aRepl[nRow,2]) })
   oCol:Picture := "@S40"
   oBrowse:AddColumn(oCol)


   @ 15,4 SAY "For Clause..:"
   @ 17,4 SAY "While Clause:"
   @ 19,4 SAY "Scope.......:"
   @ 5, 4 GET cFileName When {|| .F.  } COLOR "W/B, W+/BG"
   @ nBT, nBL, nBB, nBR Get cBrowse TBROWSE oBrowse SEND Reader := {|o|ReplReader(o,GetList, aRepl)}
   @ 15, 18 GET cForCond COLOR "W/B,W+/BG"
   @ 17, 18 GET cWhileCond COLOR "W/B,W+/BG"
   @ 19, 18 GET cScope When {||VSpace() } COLOR "W/B,W+/BG"
   @ 21, 31 GET lOk   PUSHBUTTON CAPTION "  OK  " ;
      STATE {||CkButton(@lAns),Readkill(.T.) } COLOR "W/W,W/W,W/W,W/W"
   @ 21, 42 GET lCxl  PUSHBUTTON CAPTION "Cancel" ;
      STATE {||CkButton(@lAns),READKILL(.T.) } COLOR "W/W,W/W,W/W,W/W"
   MShow()

   read

   if lAns
      FOR i := 1 to Len(aRepl)
         IF !EMPTY(aRepl[I,1]) .AND. !EMPTY(aRepl[i,2])
            cString := "_Field->"+Alltrim(aRepl[i,1])+   ;
               " := "+CHR(34)+Alltrim(aRepl[i,2])+CHR(34)+;
               IF( i != Len(aRepl), ",","")
         ENDIF
      NEXT
      if !Empty(cString)
         bAction := &("{||"+ALLTRIM(cString)+"}")
         IF !Empty(cForCond)
            bFor := &("{||"+ALLTRIM(cForCond)+"}")
         ENDIF
         IF !Empty(cWhileCond)
            bWhile := &("{||"+ALLTRIM(cWhileCond)+"}")
         ENDIF
         IF lAll == 2
            nNext := cScope
         ElseIf lAll == 3
            nRecord := cScope
         ENDIF
         DBEVAL( bAction      , ;
            bFor              , ;
            bWhile            , ;
            nNext             , ;
            nRecord           , ;
            .F. )
      endif
   Else
      lRet := .F.
   endif
   RestScreen( nMT, nML, nMB+1, nMR+1, cScreen)

RETURN lRet



FUNCTION ArraySkip( nRequest, aArray, nSubscript )
   LOCAL nActually := 0
   nActually := IF(ABS(nRequest) >= IF(nRequest >= 0,;
      LEN(aArray) - nSubscript, nSubscript - 1),;
      IF(nRequest >= 0, LEN(aArray) - nSubscript,;
      1 - nSubscript), nRequest)

   nSubscript += nActually
RETURN (nActually)


FUNCTION DoGet( oBrowse )
   LOCAL nCursSave, GetList := {}
   LOCAL oColumn, oGet, nKey
   local oList, bReader, oScroll
   local aList := {}
   local aTemp := DbStruct()
   local nT, nL, nB, nR
   local lExit := ReadExit(.t.)

   // Cursors are for GETs, so:
   nCursSave := SETCURSOR(0)

   // Make sure browse is stable
   oBrowse:ForceStable()

   oColumn := oBrowse:getColumn(oBrowse:colPos)

   // Create a corresponding GET and READ it
   oGet := GETNEW(ROW(), COL(), oColumn:block,;
      oColumn:heading, oColumn:Picture )
   IF oBrowse:ColPos == 1
      bReader := {|a,b,c,d,e,f| GuiReader(a,b,c,d,e,f) }
      oScroll := ScrollBar( Row()+1,Row()+6,(Col()+oColumn:Width))
      oList := ListBox(Row(),Col(),Row()+6,Col()+oColumn:Width, .T. )
      oList:Vscroll := oScroll
      oGet:Control := oList
      AEVAL(aTemp, ;
         {|x|oList:ADDITEM(x[1])})

   ENDIF

   oGet:Reader := bReader

   // READ it!
   READMODAL({oGet})

   ReadExit(lExit)
   // Turn cursor back to its previous state
   SETCURSOR(nCursSave)

   IF Updated()
      oBrowse:refreshCurrent()
      oBrowse:ForceStable()

   ENDIF

   IF oBrowse:ColPos == 1
      KeyBoard Chr(K_RIGHT)
   ENDIF

RETURN (UPDATED())

Function VSet()
   local oGet := GetActive()
   local lRet := .T.
   IF lAll == 1

      @ 19,18 Say "NEXT" Color "B/W"
      oGet:Row := 19
      oGet:Col := 23
      oGet:VarPut("     ")
      oGet:Picture := "99999"
      oGet:ColorDisp("B/BG")
      oGet:Reset()
      oGet:Display()
      lAll := 2

   ElseiF lAll == 2

      @ 19,18 Say "RECORD " Color "B/W"
      oGet:Row := 19
      oGet:Col := 25
      oGet:VarPut("     ")
      oGet:Picture := "99999"
      oGet:ColorDisp("B/BG")
      oGet:Reset()
      oGet:Display()
      lAll := 3

   ElseIf lAll == 3

      @ 19, 18 SAY "             " Color "W/W"
      oGet:Row := 19
      oGet:Col := 18
      oGet:VarPut("ALL")
      oGet:Picture := "XXX"
      oGet:ColorDisp("B/BG")
      oGet:Reset()
      oGet:Display()
      lAll := 1

   ENDIF
Return lRet

Function VSpace(lSet)
   local lRet := .F.
   local oGet := GetActive()
   IF (Upper(oGet:Name) = 'CSCOPE')
      SetKey(K_SPACE, {||VSet() })
      lRet := .T.
      Tone(3000,5)
   ENDIF
Return lRet

