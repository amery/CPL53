* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical Dbu                                              ³
* ³  Description: This routine is to create and modify databases and indexes ³
* ³    File Name: DBUSTRU.PRG                                                ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: ş11-09-95              ³
* ³ Time created: 08:18:20pm            Time updated: ş03:10:55pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Computer Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#INCLUDE "BOX.CH"
#INCLUDE "llibg.CH"
#include "inkey.ch"
#include "setcurs.ch"
#include "Common.ch"
#translate NTRIM(<a>) => ALLTRIM(STR(<a>))
#DEFINE MAXLENSTRUCTURE 1024
#DEFINE MAXLENINDEX 99
#DEFINE BROWSESTRUCT 1
#DEFINE BROWSEINDEX  2
#DEFINE BUTTON_OK    1
#DEFINE BUTTON_CXL   2
#DEFINE COMBOBOX     3
#DEFINE CCOLORSPEC   "W+/BG,N/W,W/N,N,GR+/W,N/BG,B+/BG,GR+/BG"
STATIC nRow
STATIC nRow1
Static cRdd

Function DbuStru(lNew, lIndexOnly)
   local aFieldStru, aIndex, aBrowses := ARRAY(2), cfilename := Space(60)
   local oColumn, aScreen, aOldValues


   cRdd := Rdd()

   if !lNew
      IF !Used()
         MessageBox("There is nothing to modify...")
         Return .F.
      ENDIF
   endif
   if lNew
      aFieldStru     := Array(MAXLENSTRUCTURE,4)
      aIndex         := Array(MAXLENINDEX,6)
      aFieldStru[1]  := {Space(10),"Character","00010","000"}
      aIndex[1]      := {Space(8),Space(254),Space(254),Space(254),"No ","Ascending "}
   else
      aOldValues     := OldValues()
      aFieldStru     := aOldValues[BROWSESTRUCT]
      aIndex         := aOldValues[BROWSEINDEX]
      cFileName      := Padr( Alias(), 60)
      cRdd           := DBSetDriver()
   endif
   nRow := 1
   nRow1 := 1
   aScreen := SaveScreen( 0, 0, MaxRow(), MaxCol() )
   mHide()
   //Graphic frames
   GFRAME(10, 55, 639, 390, 9, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
   GFRAME(28, 75, 520, 100, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
   GFRAME(28, 109, 308, 227, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
   GFRAME(28, 235, 620, 370, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)


   Setcolor("R+/W*,B/W*")

   aBrowses[BROWSESTRUCT] := TBrowseDB(7,4,13,37)

   aBrowses[BROWSEINDEX ] := TBrowseDB(15,4,22,76)

   aBrowses[BROWSESTRUCT]:ColorSpec := CCOLORSPEC

   aBrowses[BROWSEINDEX ]:ColorSpec := CCOLORSPEC

/* BrwoseStruct */

   // The go top block sets nRow to 1
   aBrowses[BROWSESTRUCT]:goTopBlock := { || nRow := 1 }

   // The go bottom block sets nRow to the length of the array
   aBrowses[BROWSESTRUCT]:goBottomBlock := { || nRow := MAXLENSTRUCTURE }


   aBrowses[BROWSESTRUCT]:skipBlock :=  ;
      { |nSkip| nSkip := ASkipTest( aFieldStru, nRow, nSkip ), ;
      nRow += nSkip,                             ;
      nSkip                                      ;
      }

   aBrowses[BROWSESTRUCT]:FootSep := ''
   aBrowses[BROWSEINDEX ]:FootSep := ''

   // The go top block sets nRow to 1
   aBrowses[BROWSESTRUCT]:goTopBlock := { || nRow := 1 }

   // The go bottom block sets nRow to the length of the array
   aBrowses[BROWSESTRUCT]:goBottomBlock := { || nRow := LEN( aFieldStru ) }
   oColumn := TBColumnNew( "Field name", ABrowseBlock( aFieldStru,    1 ))
   oColumn:Width := 10
   oColumn:DefColor := {1,2}
   oColumn:Cargo := {.F.,"@!K"}
   aBrowses[BROWSESTRUCT]:addColumn( oColumn )

   oColumn := TBColumnNew( "Type", ABrowseBlock( aFieldStru,    2 ))
   oColumn:Width := 11
   oColumn:Cargo := {.T.,"@!K",{"Character","Numeric","Logic","Memo","Date"}}
   aBrowses[BROWSESTRUCT]:addColumn( oColumn )

   oColumn := TBColumnNew( "Width", ABrowseBlock( aFieldStru,     3 ))
   oColumn:Width := 5
   oColumn:Picture := "99999"
   oColumn:Cargo := {.F.,"99999"}
   aBrowses[BROWSESTRUCT]:addColumn( oColumn )

   oColumn := TBColumnNew( "Dec", ABrowseBlock( aFieldStru,     4 ))
   oColumn:Width := 3
   oColumn:picture := "999"
   oColumn:Cargo := {.F.,"999"}
   aBrowses[BROWSESTRUCT]:addColumn( oColumn )

/* BrowseIndex */
   aBrowses[BROWSEINDEX ]:skipBlock := { |nSkip1| nSkip1 := ASkipTest( aIndex, nRow1, nSkip1 ), ;
      nRow1 += nSkip1,                             ;
      nSkip1                                       ;
      }

   // The go top block sets nRow to 1
   aBrowses[BROWSEINDEX ]:goTopBlock := { || nRow1 := 1 }

   // The go bottom block sets nRow to the length of the array
   aBrowses[BROWSEINDEX ]:goBottomBlock := { || nRow1 := MAXLENINDEX} //LEN( aIndex ) }

   oColumn := TBColumnNew( "Idx name", ABrowseB1lock( aIndex,       1 ))
   oColumn:Width := 8
   oColumn:Cargo := {.F.,"@!K"}
   aBrowses[BROWSEINDEX]:addColumn( oColumn )

   oColumn := TBColumnNew( "Expression", ABrowseB1lock( aIndex,     2 ))
   oColumn:Width := 14
   oColumn:Cargo := {.F.,"@!KS14"}
   aBrowses[BROWSEINDEX]:addColumn( oColumn )

   oColumn := TBColumnNew( "For Clause", ABrowseB1lock( aIndex,     3 ))
   oColumn:Width := 14
   oColumn:Cargo := {.F.,"@!KS14"}
   aBrowses[BROWSEINDEX]:addColumn( oColumn )

   oColumn := TBColumnNew( "While Clause", ABrowseB1lock( aIndex,   4 ))
   oColumn:Width := 14
   oColumn:Cargo := {.F.,"@!KS14"}
   aBrowses[BROWSEINDEX]:addColumn( oColumn )

   oColumn := TBColumnNew( "Uniq", ABrowseB1lock( aIndex,         5 ))
   oColumn:Width := 4
   oColumn:Picture := "@!"
   oColumn:Cargo := {.T.,"@!",{{"Yes",.T.},{"No",.F.}} }
   aBrowses[BROWSEINDEX]:addColumn( oColumn )

   oColumn := TBColumnNew( "A/D", ABrowseB1lock( aIndex,            6 ))
   oColumn:Width := 10
   oColumn:Cargo := {.T.,"@!K",{"Ascend","Descend"}}
   aBrowses[BROWSEINDEX]:addColumn( oColumn )

   mShow()
   Action(aBrowses[BROWSESTRUCT],  ;
      aBrowses[BROWSEINDEX],        ;
      aIndex,                       ;
      aFieldStru,                   ;
      @cFileName,                   ;
      lNew, lIndexOnly )

   RestScreen( 0, 0, MaxRow(), MaxCol(), aScreen )
Return nil

FUNCTION Action( oStruct, oIndex, aIndex, aFieldStru, cFileName, lNew, lIndexOnly )
   Static lStruct := .T.
   LOCAL nOldCursor                              // Saves current cursor shape
   LOCAL nKey := 0                               // Keystroke holder
   local aCtrls
   local nMRow , nMCol
   local nSelect
   local oGet
   local getlist := {}
   local aInfo := Array(4)
   local o
   mHide()
   oGet := GetNew(5,4,{|p|if(Pcount() > 0,cFileName := p, cFileName) },"cFileName")
   oGet:ColorSpec := "W+/B,W+/BG"
   oGet:Display()
   mShow()
   // Preserve cursor setting, turn off cursor
   nOldCursor := SETCURSOR( 0 )
   if !lIndexOnly
      oIndex:ForceStable()
      o := oStruct
   else
      oStruct:ForceStable()
      o := oIndex
      lStruct := .F.
   endif
   aCtrls := CallPushB(lNew)

   // Main key handler loop
   DO WHILE .T.

      // Stabilize the browse and wait for a keystroke
      o:forceStable()
      IF Empty(cFileName)
         ReadExit(.t.)
         SetCursor(1)
         ReadModal({oGet})
         SetCursor(0)
         ReadExit(.f.)
         IF lastkey() == K_ESC
            KeyBoard Chr(27)
         else
            KeyBoard CHR(K_RIGHT)+CHR(K_LEFT)
         endif
      ENDIF

      nKey := INKEY( 0 )

      // Process the directional keys
      DO CASE
      case nKey == K_ESC
         EXIT
      case nKey == K_LBUTTONDOWN
         nMRow := mRow()
         nMCol := mCol()
         Do Case
         case aCtrls[BUTTON_OK]:Hittest( nMRow, nMCol ) < 0
            // Execute code
            aCtrls[BUTTON_OK]:Select()
            aInfo[1] := cFileName
            aInfo[2] :=  aCtrls[3]:TextValue
            aInfo[3] := {}
            aInfo[4] := {}
            AEVAL( aFieldStru, {|a,i| If(!Empty(a[1]),;
               AADD(aInfo[3],{AllTrim(a[1]),   ;
               Left(a[2],1),   ;
               Val(a[3]),      ;
               Val(a[4])}),)})

            AEVAL(aIndex, {|a,i|if(!Empty(a[1]),;
               AADD(aInfo[4], {Alltrim(a[1]),  ;
               AllTrim(a[2]),  ;
               Alltrim(a[3]),  ;
               AllTrim(a[4]),  ;
               if(Left(a[5],1)=='Y',.T.,.F.),;
               if(Left(a[6],1)=='Y',.T.,.F.)}),)})
            if DbuCreate(aInfo, lNew, lIndexOnly)
               Exit
            endif

         case aCtrls[BUTTON_CXL]:Hittest( nMRow, nMCol) < 0
            aCtrls[BUTTON_CXL]:Select()
            Exit

         case aCtrls[COMBOBOX]:Hittest( nMRow, nMCol) < 0
            aCtrls[COMBOBOX]:Open()

         case (nSelect := aCtrls[COMBOBOX]:Hittest( nMRow, nMCol)) > 0
            if aCtrls[COMBOBOX]:IsOpen
               aCtrls[COMBOBOX]:Select(nSelect)
               aCtrls[COMBOBOX]:Close()
            endif
         case oGet:Hittest( nMRow, nMCol ) == -2049
            ReadExit(.T.)
            SetCursor(1)
            ReadModal({oGet})
            ReadExit(.F.)
            SetCursor(0)
         EndCase

      case ( nKey == K_DOWN )
         IF lStruct
            IF Empty(aFieldStru[nRow,1])
            else
               o:Down()
               o:ColPos := 1
               IF Empty(aFieldStru[nRow+1,1])
                  aFieldStru[nRow+1] := {Space(10),"Character","00010","000"}
               Endif
            endif

         else
            IF Empty(aIndex[nRow1,1])
               Tone(1000,2)
            else
               o:Down()
               o:ColPos := 1
               IF Empty(aIndex[nRow1+1,1])
                  aIndex[nRow1+1] := {Space(8),Space(254),Space(254),Space(254),"NO",Space(1)}
               Endif
            endif
         ENDIF
         o:RefreshAll()

      case ( nKey == K_UP )
         IF ((nRow-1) < 1 .AND. lStruct) .OR. ((nRow1-1)<1 .AND. !lStruct)
            Tone(3000,5)
         Else
            IF lStruct
               if Empty(aFieldStruct[nRow,1])
                  aFieldStru[nRow] := {Space(10),"         ","     ","   "}
               endif
            Else
               IF Empty(aIndex[nRow,1])
                  aIndex[nRow1] := {Space(8),Space(254),Space(254),Space(254)," ",Space(1)}
               endif
            ENDIF
            o:RefreshCurrent()
            o:up()
            o:ColPos := 1
         EndIf
      case ( nKey == K_F10 )
         OPENDIALOG()
      case ( nKey == K_RIGHT )
         do case
         case (lStruct .AND. Left(aFieldStru[nRow,2],1) == 'L') .AND. o:ColPos > 1
            aFieldStru[nRow,3] := "00001"
            aFieldStru[nRow,4] := "00000"
            o:RefreshCurrent()
            KeyBoard Chr(K_DOWN)
         case (lStruct .AND. Left(aFieldStru[nRow,2],1) == 'D') .AND. o:ColPos > 1
            aFieldStru[nRow,3] := "00008"
            aFieldStru[nRow,4] := "00000"
            o:RefreshCurrent()
            KeyBoard Chr(K_DOWN)

         case (lStruct .AND. Left(aFieldStru[nRow,2],1) == 'M') .AND. o:ColPos > 1
            aFieldStru[nRow,3] := "00010"
            aFieldStru[nRow,4] := "00000"
            o:RefreshCurrent()
            KeyBoard Chr(K_DOWN)
         case o:ColPos == o:ColCount .OR. (lStruct .AND. Left(aFieldStru[nRow,2],1) == 'M')
            KeyBoard Chr(K_DOWN)
         otherwise
            o:right()
         Endcase

      case ( nKey == K_LEFT )
         o:left()

      case ( nKey == K_PGDN )
         o:right()
         o:down()

      case ( nKey == K_PGUP )
         o:right()
         o:up()

      case ( nKey == K_HOME )
         o:left()
         o:up()

      case ( nKey == K_END )
         o:left()
         o:down()
      case ( nKey == K_RETURN )
         DoGet(o,lStruct)
         o:RefreshCurrent()
         KEYBOARD Chr(K_RIGHT)
      case ( ( nKey >= 65 .AND. nKey <= 90 ) .OR. ;
            ( nKey >= 48  .AND. nKey <= 57  ) .OR. ;
            ( nKey >= 97 .AND. nKey <= 122 ) )
         Keyboard Chr(nKey)
         DoGet(o,lStruct)
         o:RefreshCurrent()
         KeyBoard Chr(K_RIGHT)
      case ( nKey == K_TAB ) .AND. !lIndexOnly
         IF lStruct
            o := oIndex
            lStruct := .F.
            o:Refreshall()
         else
            o := oStruct
            lStruct := .T.
            o:Refreshall()
         ENDIF
      EndCase

   ENDDO

   // Restore the original cursor setting
   SETCURSOR( nOldCursor )

RETURN (nil)



/***
  ABrowseBlock( <aArray>, <nIndex> ) --> bColumnBlock

  Create and return a get/set block for <aArray>[nRow, <nIndex>]
*/
FUNCTION ABrowseBlock( a, x)

RETURN ( {|p| IF( PCOUNT() == 0, a[nRow, x], a[nRow, x] := p ) } )

FUNCTION ABrowseB1lock( a, x)

RETURN ( {|p| IF( PCOUNT() == 0, a[nRow1, x], a[nRow1, x] := p ) } )


/***
  ASkipTest( <aArray>, <nCurrent>, <nSkip> ) --> nSkipsPossible
  Returns the number of skips actually possible
*/
FUNCTION ASkipTest( a, nCurrent, nSkip )

   IF ( nCurrent + nSkip < 1 )

      // Would skip past the top...
      RETURN ( -nCurrent + 1 )

   ELSEIF ( nCurrent + nSkip > LEN( a ) )

      // Would skip past the bottom...
      RETURN ( LEN(a) - nCurrent )

   END

   // No problem
RETURN ( nSkip )





STATIC FUNCTION DoGet( oBrowse, lStruct )
   LOCAL nCursSave
   LOCAL oColumn, oGet
   local oList
   local bReader := nil
   local oScroll
   local nrow, nCol

   // Cursors are for GETs, so:
   nCursSave := SETCURSOR(SC_NORMAL)

   // Make sure browse is stable
   oBrowse:ForceStable()

   oColumn := oBrowse:getColumn(oBrowse:colPos)

   // Create a corresponding GET and READ it
   oGet := GETNEW(ROW(), COL(), oColumn:block,;
      oColumn:heading)
   oGet:Picture := oColumn:Cargo[2]

   IF oColumn:Cargo[1]
      bReader := {|a,b,c,d,e,f| GuiReader(a,b,c,d,e,f) }
      oScroll := ScrollBar( Row()+1,Row()+6,(Col()+oColumn:Width))
      oList := ListBox(Row(),Col(),Row()+6,Col()+oColumn:Width, .T. )
      oList:Vscroll := oScroll
      oGet:Control := oList
      AEVAL(oColumn:Cargo[3], ;
         {|x|oList:ADDITEM(if(ValType(x)=='A',x[1],x))})
   endif
   // Custom reader (if any)
   oGet:reader := bReader

   // READ it!
   READMODAL({oGet})

   // Turn cursor back to its previous state
   SETCURSOR(nCursSave)

   // If key was changed
   IF Updated()
      oBrowse:refreshCurrent()
      oBrowse:ForceStable()
   ENDIF

RETURN nil



Function CallPushB(lNew)
   local aRdd := {"DBFNTX","DBFCDX","DBFMDX","DBFNDX"}
   local aControls := {}
   local oPush
   local oScroll := ScrollBar(8,13,47)
   local nSelection
   local cColorSpec := "w/w,w/w,w/w,w/w"
   local oList

   IF lNew
      nSelection := 1
   Else
      nSelection := ASCAN( aRdd, cRdd )
   ENDIF
   oPush := PushButton(7,60, "  OK  ")
   oPush:ColorSpec := cColorSpec
   oPush:Display()
   AADD(aControls, oPush)

   oPush := PushButton(10,60,"CANCEL")
   oPush:ColorSpec := cColorSpec
   oPush:Display()
   AADD(aControls, oPush)

   oList := ListBox(7,40,13,47,.T.)
   oList:ColdBox := B_SINGLE
   oList:hotBox := B_DOUBLE
   oList:VScroll := oScroll
   oList:ColorsPEC := "R/W,B/W,BG/W,R/B,B/W,N/W+,W/B,W/R"
   AEVAL(aRdd, {|x|oList:ADDITEM(x) })
   oList:Select(oList:FindText(cRdd))
   oList:DisPlay()
   AADD(aControls, oList)

Return aControls

FUNCTION OLDVALUES()
   local aStru := Array(MAXLENSTRUCTURE, 4)
   local aIndex := Array(MAXLENINDEX,6)
   local aRetValue := Array(2)
   local oMenu := TopMenu()
   local nIndCnt := oMenu:GetItem(7):Data:ItemCount
   local cUniq
   local cDescend
   local i
   AEVAL( DBStruct(), {|a,i|aStru[i] := CharConv(a) })
   IF nIndCnt > 1
      FOR i := 2 TO nIndcnt
         //             name    Exp         For      While       uniq  Ascend/descend
         cUniq := if(OrdIsUnique(OrdName(i-1)),"Yes","No " )
         cDescend := if(OrdDescend(OrdName(i-1)),"Ascending ","Descending" )
         aIndex[i-1] :=  {OrdName(i-1),   ;
            Padr(IndexKey(i-1),254),    ;
            Padr(OrdFor(i-1),254),      ;
            Space(254), cUniq, cDescend }
      NEXT
   Else
      aIndex := Array(MAXLENINDEX,6)
      aIndex[1] :=  {Space(8),Space(254),Space(254),Space(254),"No ","Ascending "}
   ENDIF

   aRetValue[1] := aStru
   aRetValue[2] := aIndex
Return aRetValue

Function CharConv( aValue )
   local aRet := Array(4)
   local aChar := {"Character","Numeric","Logic","Memo","Date"}
   aRet[1] := Padr(aValue[1],10)
   aRet[2] := aChar[ASCAN(aChar, {|c| Left(c, 1) = Alltrim(aValue[2]) })]
   aRet[3] := Padl(NTRIM(aValue[3]),5,"0")
   aRet[4] := Padl(NTRIM(aValue[4]),3,"0")
Return aRet


