* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical Dbu                                              ³
* ³  Description: To Display and edit in from view                           ³
* ³    File Name: FORMVIEW.PRG                                               ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: ş10-29-95              ³
* ³ Time created: 08:19:54pm            Time updated: ş08:19:54pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Computer Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#INCLUDE "BOX.CH"
#INCLUDE "llibg.CH"
#include "inkey.ch"
#include "setcurs.ch"

STATIC nRow

FUNCTION FormView(lEdit)
   local nT := 7, nL := 12, nB := 24, nR := 68
   local aFieldStru
   local oBrowse
   local oColumn
   local nMaxLen
   local aScreen
   local cColorSpec := "GR+/B,W+/BG,B/W,B/BG,W+/BG,B/BG,R/W,W+/R"
   local nRowPos, nColPos
   local aFont
   local nCursor := SetCursor(1)
   local lReadExit := ReadExit(.T.)
   local i
   IF !Used()
      MessageBox("A database must be open for this operation.")
      Return .F.
   ENDIF
   nRow := 1
   nMaxLen := FCount()
   aFieldStru := Array( nMAXLEN, 3 )
   BuildArray(aFieldStru)
   aScreen := SaveScreen( 4, 11, 28, 69)
   mHide()
   GFRAME((nL*8)-4,(nT*16), ((nR*8)+8)+2, (nB*16)+14, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
   GFRAME(93,84, 554, 111, 7, 15, 8,43, 3, 3, 3, LLG_MODE_SET)
   GFRAME((nL*8)-4,(nB*16)+2, ((nR*8)+8)+2, ((nB+2)*16)+14, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
   aFont := GFNTLOAD("TNR20.FNT")

   GWRITEAT( 250,;
      84,;
      "FORMVIEW",;
      4,;
      LLG_MODE_SET, aFont)
   GFNTERASE(aFont)

   oBrowse := TBrowseDB(nT, nL, nB-1, nR )
   oBrowse:ColorSpec := cColorSpec

   // The go top block sets nRow to 1
   oBrowse:goTopBlock := { || nRow := 1 }

   // The go bottom block sets nRow to the length of the array
   oBrowse:goBottomBlock := { || nRow := nMAXLEN}

   oBrowse:skipBlock :=  ;
      { |nSkip| nSkip := ASkipTest( aFieldStru, nRow, nSkip ), ;
      nRow += nSkip,                             ;
      nSkip                                      ;
      }
   oBrowse:FootSep := ''

   // The go top block sets nRow to 1
   oColumn := TBColumnNew( "", AFormBlock( aFieldStru,    1 ))
   oColumn:Width := 12
   oColumn:ColorBlock := {||{1,2}}
   oColumn:Cargo := {.F.,"@!K"}
   oBrowse:addColumn( oColumn )

   oColumn := TBColumnNew( "", AFormBlock( aFieldStru,    2 ))
   oColumn:Width := 40
   oColumn:ColorBlock := {||{6,5}}
   oColumn:Cargo := {.F.,"@!KS40"}
   oBrowse:addColumn( oColumn )
   MShow()
/* BrowseIndex */
   FormApplyKey(oBrowse,aFieldStru)
   SetCursor(nCursor)
   RestScreen( 4, 11, 28, 69, aScreen )
Return nil

FUNCTION FormApplyKey( oBrowse, aFieldStru )
   local oMenu := TopMenu()
   local nOldCursor                              // Saves current cursor shape
   local nKey := 0                               // Keystroke holder
   local c
   local nRowPos
   local nColPos
   local nRow, nCol
   local cMemo    := ''
   local aPush    := BitMapB(oBrowse, aFieldStru)
   local nPosTop  := 0
   local nPos     := 0
   local nLastTop := 0
   local oPop
   local oPopTemp
   local oTemp


   KeyBoard chr(5)
   // Main key handler loop
   DO WHILE ( nKey <> K_ESC )
      nRowPos := oBrowse:RowPos
      nColPos := oBrowse:ColPos
      oBrowse:ColorRect( {1,1,oBrowse:RowCount,1}, {1,5})
      oBrowse:ColorRect( {2,2,oBrowse:RowCount,2}, {6,6})
      oBrowse:RowPos := nRowPos
      oBrowse:ColPos := nColPos
      oBrowse:ColPos := 2

      // Stabilize the browse and wait for a keystroke
      oBrowse:forceStable()
      nKey := INKEY( 0 )

      // Process the directional keys
      DO CASE

      case nKey == K_LBUTTONDOWN
         nRow := mRow()
         nCol := mCol()
         Do Case
         case ( nPosTop := oMenu:Hittest(nRow, nCol)) > 0
            IF oMenu:GetItem(nPosTop):Enabled
               oPop := oMenu:GetItem(nPosTop):Data
               IF nLastTop > 0
                  If nLastTop != nPosTop
                     oMenu:GetItem(nLastTop):Data:Close(nLastTop)
                     oPop:Open()
                  Elseif nLastTop == nPosTop
                     oMenu:GetItem(nLastTop):Data:Close(nLastTop)
                     nPosTop := 0
                  endif
               ElseIF nLastTop == 0
                  oPop:Open()
               ENDIF
               nLastTop := nPosTop
            EndIf
         case oPop != nil .AND. ValType(oPop) == 'O'
            IF (nPos := oPop:Hittest( nRow, nCol)) > 0
               oPop := oPop:GetItem(nPos)
               IF oPop:Enabled
                  oPopTemp := oPop
                  IF ValType(oPop) == 'O'
                     oPop := oPop:Data
                  ENDIF
                  IF ValType(oPop) == 'O'
                     oPop:Open()
                  else
                     oMenu:GetItem(nLastTop):Data:Close( nLastTop )
                     nLastTop := 0
                     if eval(oPop, oPopTemp)
                        oBrowse:RefreshAll()
                     endif
                  ENDIF
                  nPos := 0
               endif
            Else
               oMenu:Getitem(nLastTop):Data:Close()
            EndIf
         case oBrowse:Hittest( nRow, nCol ) < 0
            IF oMenu:Current > 0 .AND. nLastTop > 0
               oMenu:Getitem(nLastTop):Data:Close()
            ENDIF
         case BUTTONTEST(aPush, nRow, nCol )
            IF oMenu:Current > 0 .AND. nLastTop > 0
               oMenu:Getitem(nLastTop):Data:Close()
            ENDIF
         case nKey == 1
            tone(3000,2)
         EndCase
         nRow := 0
         nCol := 0


      /*---------------------------------------------------------*/
      CASE ( nKey == K_DOWN )
         oBrowse:Down()

      CASE ( nKey == K_UP )
         oBrowse:up()
      CASE ( nKey == K_F10 )
         /* To Save the record. Escape will abort changes */
         SaveIt( aFieldStru )
      CASE ( nKey == K_RIGHT )
         oBrowse:right()
      CASE ( nKey == K_LEFT )
         oBrowse:left()

      CASE ( nKey == K_PGDN )
         oBrowse:PageDown()
      CASE ( nKey == K_PGUP )
         oBrowse:PageUp()

      CASE ( nKey == K_HOME )
         oBrowse:Home()

      CASE ( nKey == K_END )
         oBrowse:End()
      CASE ( nKey == K_RETURN )
         IF CheckMemo(EVAL(oBrowse:GetColumn(oBrowse:ColPos):Block))
            aFieldStru[nRow,3] := DispMemo(aFieldStru[nRow,3])
         endif
      CASE ( ( nKey >= 65 .AND. nKey <= 90 ) .OR. ;
            ( nKey >= 48  .AND. nKey <= 57  ) .OR. ;
            ( nKey >= 97 .AND. nKey <= 122 ) )
         IF CheckMemo(EVAL(oBrowse:GetColumn(oBrowse:ColPos):Block))
         else
            Keyboard Chr(nKey)
            DoGet(oBrowse)
            oBrowse:RefreshCurrent()
            KeyBoard Chr(K_RIGHT)
         endif

      ENDCASE
   ENDDO
RETURN (nil)


FUNCTION AFormBlock( a, x)
   local bBlock
   bBlock := {|p| IF( PCOUNT() == 0, a[nRow, x], a[nRow, x] := p ) }
RETURN (bBlock)

STATIC FUNCTION DoGet( oBrowse )
   LOCAL nCursSave
   LOCAL oColumn, oGet
   local oList
   local bReader := nil
   local oScroll

   // Make sure browse is stable
   oBrowse:ForceStable()

   oColumn := oBrowse:getColumn(oBrowse:colPos)
   // Create a corresponding GET and READ it
   oGet := GETNEW( ROW(), COL(), oColumn:block,;
      oColumn:heading)
   oGet:Picture := oColumn:Cargo[2]

   // READ it!
   READMODAL({oGet})
   IF lastkey() == K_DOWN .OR. ;
         lastkey() == K_UP .OR. ;
         lastkey() == K_ESC .OR. ;
         lastkey() == K_ENTER
      KeyBoard chr(LastKey())
   ENDIF
   // If key was changed
   IF Updated()
      oBrowse:refreshCurrent()
      oBrowse:ForceStable()
   ENDIF

RETURN nil

FUNCTION CheckMemo(cString)
   local lRet := .F.
   IF ValType(cString) == 'C'
      IF cString == "<MEMO>"
         lRet := .T.
      ENDIF
   ENDIF
Return ( lRet )


Function ChangeRec(nWhat, oBrowse, aFieldStru)
   Do Case
   case nWhat == 4                               // previous record
      SaveIt(aFieldStru)
      DBSkip()
      if Eof()
         Tone(3000,5)
      else
         BuildArray( aFieldStru )
         oBrowse:configure()
      endif

   case nWhat == 3                               // Go Bottom
      SaveIt(aFieldStru)
      DBGoBottom()
      if Eof()
         Tone(3000,5)
      else
         BuildArray( aFieldStru )
         oBrowse:configure()
      endif
   case nWhat == 2                               // Go top
      SaveIt(aFieldStru)
      DBGoTop()
      if Bof()
         Tone(3000,5)
      else
         BuildArray( aFieldStru )
         oBrowse:configure()
      endif
   case nWhat == 1                               // next record
      SaveIt(aFieldStru)
      DBSkip(-1)
      if Bof()
         Tone(3000,5)
      else
         BuildArray( aFieldStru )
         oBrowse:configure()
      endif
   endcase
Return .T.



FUNCTION BuildArray(aFieldStru)
   local i
   FOR i := 1 TO Len(aFieldStru)
      aFieldStru[i,1] := Padl(FieldName(i)+":",12)
      IF ValType(FieldGet(i)) == 'M'
         aFieldStru[i,2] := '<MEMO>'
         aFieldStru[i,3] := FieldGet(i)
      ELSE
         aFieldStru[i,2] := FieldGet(i)
      ENDIF
   NEXT

RETURN aFieldStru


Function SaveIt(aFieldStru)
   AEVAL(aFieldStru,    ;
      {|a,i|if(CheckMemo(a[2]),;
      FieldPut(i,a[3]),FieldPut(i,a[2])) })
Return (NIL)

