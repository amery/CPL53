* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical DBU                                              ³
* ³  Description: To View dbf files                                          ³
* ³    File Name: DBVIEW.PRG                                                 ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: þ10-29-95              ³
* ³ Time created: 08:23:40pm            Time updated: þ08:23:40pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Computer Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#INCLUDE "llibg.CH"
#INCLUDE "INKEY.CH"
#INCLUDE "BUTTON.CH"
FUNCTION DBView(lEdit)
   local oBrow, oCol, nKey
   local l
   local aScreen
   local aPush
   local oScrollV
   local oScrollH
   local nThumb := 0
   local oMenu := TopMenu()
   local nPosTop := 0
   local nPos := 0
   local nLastTop := 0
   local oPop
   local oPopTemp
   local oTemp
   local i, nRow, nCol
   local nControw := 0, nContCol := 0, RowDiff, ColDiff
   local nThumb_v, nThumb_h


   IF !Used()
      MessageBox("No work area available")
      Return nil
   ENDIF

   For i := 1 to 5
      oMenu:GetItem(1):Data:GetItem(i):Enabled := .F.
   next

   oMenu:GetItem(1):Data:GetItem(7):Enabled := .F.
   oMenu:GetItem(2):Enabled := .F.
   oMenu:GetItem(4):Enabled := .F.
   oMenu:GetItem(6):Enabled := .F.
   oMenu:Display()

   DBGoTop()
   aScreen := SaveScreen( 0, 0, MaxRow(), MaxCol() )

   SETCOLOR("W+/BG,GR+/B")
   mHide()
   GFRAME(24, 87 , 626, 407, 7, 15,9, 8, 8, 8, 8, LLG_MODE_SET)

   GRECT(32,123,617,128,LLG_FILL,15,LLG_MODE_SET)

   oBrow := TBROWSEDB( 8, 4, 23, 74 )
   aPush := BitmapA(oBrow)
   oScrollH := ScrollBar( 5, 76, 24, , 2 )
   oScrollH:Display()

   oScrollV := ScrollBar( 8, 23, 75, , 1 )
   oScrollV:Display()

   oBrow:HeadSep :=  CHR(205) + CHR(209) + CHR(205)
   oBrow:ColSep := Chr(32)+Chr(179)+chr(32)

   FOR i := 1 TO FCount()
      IF Valtype( FieldGet(i) ) == 'M'
         oCol := TBCOLUMNNEW( FieldName(i), ;
            {|| "<MEMO>"} )
         oBrow:addColumn( oCol )
      ELSE
         oCol := TBCOLUMNNEW( FieldName(i), FieldBlock( FieldName(i)) )
         oBrow:addColumn( oCol )
      ENDIF
   Next
   MShow()
   WHILE .T.

      oBrow:Forcestable()
      nKey := INKEY(0)

      if nKey == 1002
         DO CASE
         CASE oScrollV:HitTest(MROW(), MCOL()) == HTSCROLLUNITDEC
            nKey := K_UP
         CASE oScrollV:HitTest(MROW(), MCOL()) == HTSCROLLUNITINC
            nKey := K_DOWN
         CASE oScrollH:HitTest(MROW(), MCOL()) == HTSCROLLUNITDEC
            IF oBrow:colpos == 1
               nKey := K_CTRL_LEFT
            ELSE
               nKey := K_LEFT
            ENDIF
         CASE oScrollH:HitTest(MROW(), MCOL()) == HTSCROLLUNITINC
            nKey := K_RIGHT
         OTHERWISE
            IF oBrow:mRowPos * oBrow:mColPos <> 0
               RowDiff := oBrow:mRowPos - oBrow:RowPos
               oBrow:RowPos := oBrow:mRowPos
               nContRow := nContRow + RowDiff
               oScrollV:current := recno()
               oScrollV:thumbpos := ROUND((nContRow/oScrollV:total)* ;
                  oScrollV:BarLength, 0)
               IF nthumb_v <> oScrollV:thumbpos
                  oScrollV:display()
               ENDIF

               ColDiff := oBrow:mColPos - oBrow:colpos
               oBrow:ColPos := oBrow:mColPos
               nContCol := nContCol + ColDiff
               oScrollH:thumbpos := IIF(nContCol==1, 1, ;
                  ROUND((nContCol/oScrollH:total)*oScrollH:Barlength,0))
               IF nThumb_h <> oScrollH:thumbpos
                  oScrollH:display()
               ENDIF
               oBrow:RefreshAll()
               LOOP
            ENDIF
         ENDCASE
      endif

      nThumb_v := oScrollV:thumbpos
      nThumb_h := oScrollH:thumbpos


      // *****************************************************************
      Do Case
      case ( nKey == K_UP )
         oBrow:Up()
         nContRow--

      case ( nKey == K_DOWN )
         oBrow:Down()
         nContRow++

      case ( nKey == K_LEFT )
         if nContCol > 1
            oBrow:Left()
            nContCol--
         endif

      case ( nKey == K_RIGHT )
         if nContCol < oBrow:ColCount
            oBrow:Right()
            nContCol++
         endif
      case ( nKey == K_ENTER )
         IF EVAL(oBrow:getColumn(oBrow:colPos):Block) == ;
               '<MEMO>'
            DispMemo(FieldGet(oBrow:ColPos), lEdit)
         ElseIF lEdit
            DoGet(oBrow)
         ENDIF
      case ( ( nKey >= 65 .AND. nKey <= 90 ) .OR. ;
            ( nKey >= 48  .AND. nKey <= 57  ) .OR. ;
            ( nKey >= 97 .AND. nKey <= 122 ) )
         Keyboard Chr(nKey)
         DoGet(oBrow)
         oBrow:RefreshCurrent()
      case ( nKey == K_PGDN )
         oBrow:PageDown()
         nContRow := IIf(nContRow+17 > oScrollV:Total,   ;
            oScrollV:Total, nContRow+17)

      case ( nKey == K_PGUP )
         oBrow:PageUp()
         nContRow := IIf(nContRow-17 > oScrollV:Total,   ;
            oScrollV:Total, nContRow-17)


      case ( nKey == K_CTRL_PGUP )
         oBrow:goTop()
         nContRow := 1

      case ( nKey == K_CTRL_PGDN )
         oBrow:goBottom()
         nContRow := oScrollV:Total

      case ( nKey == K_HOME )
         oBrow:home()

      case ( nKey == K_END )
         oBrow:end()

      case ( nKey == K_CTRL_LEFT )
         oBrow:panLeft()

      case ( nKey == K_CTRL_RIGHT )
         oBrow:panRight()

      case ( nKey == K_CTRL_HOME )
         oBrow:panHome()

      case ( nKey == K_CTRL_END )
         oBrow:panEnd()

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
                        oBrow:RefreshAll()
                     endif
                  ENDIF
                  nPos := 0
               endif
            Else
               oMenu:Getitem(nLastTop):Data:Close()
            EndIf
         case oScrollH:Hittest(nRow,nCol) < 0
            oScrollH:Update()
         case oScrollV:Hittest(nRow, nCol) < 0
            oScrollV:Update()
         case ( nKey >= 65 .AND. nKey <= 90 ) .OR. ;
               ( nKey >= 97 .AND. nKey <= 122 )
            Keyboard Chr(nKey)
            DoGet(oBrow)
         case oBrow:Hittest( nRow, nCol ) < 0
            IF oMenu:Current > 0 .AND. nLastTop > 0
               oMenu:Getitem(nLastTop):Data:Close()
            ENDIF
            TbMouse(oBrow, nRow, nCol )
         case BUTTONTEST(aPush, nRow, nCol )
            IF oMenu:Current > 0 .AND. nLastTop > 0
               oMenu:Getitem(nLastTop):Data:Close()
            ENDIF

         EndCase
         nRow := 0
         nCol := 0
      case nKey == K_ESC
         Exit

      ENDCASE
      oScrollV:current := recno()
      oScrollV:thumbpos := ROUND((nContRow/oScrollV:total)*oScrollV:BarLength,0)
      IF nthumb_v <> oScrollV:thumbpos
         oScrollV:display()
      ENDIF

      oScrollH:thumbpos := IIF(nContCol==1, 1, ROUND((nContCol/oScrollH:total)* ;
         oScrollH:BarLength,0) )
      IF nThumb_h <> oScrollH:thumbpos
         oScrollH:display()
      ENDIF

   EndDo
   RestScreen( 0, 0, MaxRow(), MaxCol(), aScreen )
   For i := 1 to 5
      oMenu:GetItem(1):Data:GetItem(i):Enabled := .T.
   next
   oMenu:GetItem(1):Data:GetItem(7):Enabled := .T.
   oMenu:GetItem(2):Enabled := .T.
   oMenu:GetItem(4):Enabled := .T.
   oMenu:GetItem(6):Enabled := .T.
RETURN (NIL)

FUNCTION Search(oMenuItem)

   local cSearch
   local uValue
   local oGet
   local lRet := .F.
   local bBlock := {|p|If(Pcount() > 0, cSearch := p, cSearch)}
   IF !Used()
      MessageBox("No work area open...")
      Return .F.
   ENDIF

   Do Case

   case oMenuItem:Caption == '&Seek'
      if IndexOrd() > 0
         uValue := DBSearch(1)
         IF uValue != nil
            lRet := DBSeek( uValue )
         endif
      else
         MessageBox("Cannot perform this operation ;"+;
            "No index order is set")
      endif
   case oMenuItem:Caption == '&Goto'
      uValue := DBSearch(2)
      IF uValue != nil
         DBGoTo( uValue )
         lRet := .T.
      ENDIF
   endcase
Return lRet


#TRANSLATE Ntrim(<a>) => AllTrim(Str(<a>))
#TRANSLATE Center(<a>,<b>,<c>[, <Clr>]) => DevPos(<a>,Round(((<c>+len(<b>))/2),0));;
   DevOut(<b>[,<Clr>])

Function DBSearch(n)
   local cColor := SetColor("+W/B")
   local cScreen := SaveScreen( 8,19,12,63)
   local GetList := {}
   local cPicture, uSearch, cTitle, nLen
   local nCursor := SetCursor(1)
   GFRAME(152, 128, 504, 200, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
   GFRAME(152, 128, 504, 144, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)

   IF IndexOrd() <= 0 .AND. n == 1
      RestScreen( 8,19,12,63, cScreen)
      Return Nil
   endif
   IF n == 2
      uSearch := 0
   ElseIF ValType(&(IndexKey(0))) == 'N'
      nLen := Ntrim(&(IndexKey(0)))
      cPicture := "9999999999"
      uSearch := 0
   ElseIF ValType( &(IndexKey(0))) == 'L'
      nLen := 1
      cPicture := "Y"
      uSearch := .F.
   ElseIF ValType( &(IndexKey(0))) == 'D'
      nLen := 8
      cPicture := "@D"
      uSearch := CtoD("")
   ElseIF ValType( &(IndexKey(0))) == 'C'
      nLen := Len(&(IndexKey(0)))
      cPicture := If(nLen > 30, "@KS30","@K")
      uSearch := Space(nLen)
   ElseIF ValType( &(IndexKey(0))) == 'M'
      Return nil
   ENDIF
   Do Case
   case n == 1
      cTitle := "Enter the desired string to search ?"
   case n == 2
      cTitle := "Enter the desired record number ?"
   case n == 3
      cTitle := "Enter the desired Query ?"
   endcase
   @ 10,22 Say  cTitle Color "B+/W"
   @ 11,22 Get uSearch Picture cPicture Color "W+/B"
   Read
   IF lastkey() = 27
      uSearch := nil
   ENDIF
   IF Valtype(uSearch) == 'D'
      uSearch := Dtos(uSearch)
   ENDIF
   SetCursor(nCursor)
   RestScreen( 8,19,12,63, cScreen)
return ( uSearch )

STATIC FUNCTION DoGet( oBrowse )
   LOCAL nCursSave
   LOCAL oColumn, oGet
   local oList
   local bReader := nil
   local oScroll
   local lExit := ReadExit(.T.)

   // Make sure browse is stable
   oBrowse:ForceStable()

   oColumn := oBrowse:getColumn(oBrowse:colPos)
   // Create a corresponding GET and READ it
   oGet := GETNEW(ROW(), COL(), oColumn:block,;
      oColumn:heading)

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
   ReadExit(lExit)
RETURN nil
