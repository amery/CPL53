#INCLUDE "BOX.CH"
#include "llibg.ch"
#INCLUDE "INKEY.CH"
#INCLUDE "MEMOEDIT.CH"
#DEFINE CTL_LISTF        1
#DEFINE CTL_LISTS        2
#DEFINE CTL_OKBUTTON     3
#DEFINE CTL_CXLBUTTON    4
#DEFINE LISTBOX_COLOR "W+/B,GR+/B,W+/B,N/B,GR+/B,N/B,B+/B"

Static aControls    // To pass the object of the controls to the MemoUdf

Function BldFilter()
   local GetList := {}
   local nMT := 7, nML := 2, nMB := 27, nMR := 78
   local nET := 17, nEL := 3, nEB := 24, nER := 77
   local cDbf, oErr, cColorSpec := "w/w,w/w,w/w,w/w", bError
   local cFilter, oScrollF, oScrollS, oOk, oListF, oListS, bFilter
   local lRet := .T., oCxl, cScreen := SaveScreen( nMT, nML, nMB+1, nMR+1)
   local aListS := {{"PLUS","+"},{"MINUS","-"},{"EQUAL","="},;
      {"D-EQUAL","=="},{"OR",".OR."},{"AND",".AND."},   ;
      {"( Paren","("},{") Paren",")"}}
   local aListF := {}


   IF !Used()
      MessageBox( "No database available")
      RestScreen( nMT, nML, nMB+1, nMR+1, cScreen)
      Return .F.
   ENDIF
   bError := ErrorBlock( {|o|Break(o) })
   aControls := Array(4)
   cDbf := PadR(Alias(),8)
   AEVAL(DBStruct(), {|a,i|AADD(aListF, a[1]) })
   Set VideoMode To 18
   Set EventMask to 158
   MSetCursor(.T.)
   MHide()
/* Main frame */
   GFRAME((nML*8), (nMT*16), (nMR*8)+8, (nMB*16)+16, 7, 15, 8, 20, 3, 3, 3, LLG_MODE_SET)
/* Edit Frame */
   GFRAME((nEL*8)-3, (nET*16)-3, (nER*8)+8+3, (nEB*16)+16+3, 7, 15, 8, 20, 3, 3, 3, LLG_MODE_SET)

/* List box construct for the fields */
   oScrollF := ScrollBar( 9,14, 54)
   oListF := ListBox(9,36,14,53 )
   oListF:ColdBox := B_SINGLE
   oListF:HotBox := B_DOUBLE
   oListF:VScroll := oScrollF
   oListF:ColorSpec := LISTBOX_COLOR
   aControls[CTL_LISTF] := oListF

/* List box construct for the operators */
   oScrollS := ScrollBar( 9,14, 71)
   oListS := ListBox(9,59,14,71 )
   oListS:ColdBox := B_SINGLE
   oListS:HotBox := B_DOUBLE
   oLists:VScroll := oScrollS
   oListS:ColorSpec := LISTBOX_COLOR
   aControls[CTL_LISTS] := oListS

   AEVAL( aListS, {|a,i| oListS:ADDITEM(a[1],a[2] ) })
   AEVAL(aListF, {|a,i|oListF:ADDITEM(a) })
   oOk := PushButton(26,30,  "  OK  ")
   oOk:ColorSpec := cColorSpec
   aControls[CTL_OKBUTTON] := oOk

   oCxl := PushButton(26,44, "Cancel")
   oCxl:ColorSpec := cColorSpec
   aControls[CTL_CXLBUTTON] := oCXl

   oOk:Display()
   oCxl:Display()
   oListF:DISPLAY()
   oListS:DISPLAY()

   @ 9,6 SAY "Set filter for" Color "B/W"
   @ 9, 21 GET cdbf
   MShow()
   SETCOLOR("+W/B")
/* Memoedit */
   cFilter := MemoEdit(cFilter, nET+1, nEL, nEB, nER,.T., "MemoUdf" )
/* Remove all soft return and hard returns */
   cFilter := StrTran(StrTran(StrTran(cFilter, Chr(141),''),;
      Chr(10),''),Chr(13),'')

/* Build the block and set the filter */
   Begin Sequence
      If !Empty(cFilter)
         cFilter := Alltrim(cFilter)
         bFilter := &("{||"+cFilter+"}")
         DBSetFilter(bFilter, cFilter)
         DBGoTop()
      endif
   Recover using oErr
      lRet := .F.
   End Sequence
   ErrorBlock(bError)                            // Reset the error block
   RestScreen( nMT, nML, nMB+1, nMR+1, cScreen)

RETURN lRet

/* Memoedit from user define function */
FUNCTION MemoUDF( nMode, nLine, nColumn )
   LOCAL nKey := LASTKEY()
   LOCAL nRetVal := ME_DEFAULT                   // Default return action
   LOCAL nRow := MRow()
   local nCol := MCol()
   local nPosition

   do case
   case nMode == ME_IDLE
   case nMode == ME_UNKEY .OR. nMode == ME_UNKEYX
      do case
      case nKey == 1002
         Do Case
         case (nPosition := ;
               aControls[CTL_LISTF]:VSCROLL:Hittest(nRow, nCol)) == -3074
               aControls[CTL_LISTF]:NextItem()
               aControls[CTL_LISTF]:Display()
               Tone(3000,5)

         case (nPosition := ;
               aControls[CTL_LISTF]:VSCROLL:Hittest(nRow, nCol)) == -3075
               aControls[CTL_LISTF]:PrevItem()
               aControls[CTL_LISTF]:Display()
               Tone(3000,5)

         case (nPosition := ;
               aControls[CTL_LISTS]:VSCROLL:Hittest(nRow, nCol)) == -3074
               aControls[CTL_LISTS]:NextItem()
               aControls[CTL_LISTS]:Display()
               Tone(3000,5)

         case (nPosition := ;
               aControls[CTL_LISTS]:VSCROLL:Hittest(nRow, nCol)) == -3075
               aControls[CTL_LISTS]:PrevItem()
               aControls[CTL_LISTS]:Display()
               Tone(3000,5)

         case (nPosition := aControls[CTL_LISTF]:Hittest(nRow, nCol)) > 0
            aControls[CTL_LISTF]:Select(nPosition)
            aControls[CTL_LISTF]:VScroll:Update()
            KeyBoard aControls[CTL_LISTF]:TextValue
         case (nPosition := aControls[CTL_LISTS]:Hittest(nRow, nCol)) > 0
            aControls[CTL_LISTS]:Select(nPosition)
            KeyBoard aControls[CTL_LISTS]:GetItem(nPosition)[2]
         case aControls[CTL_OKBUTTON]:Hittest( nRow, nCol ) < 0
            aControls[CTL_OKBUTTON]:Select()
            nRetVal := K_CTRL_W
         case aControls[CTL_CXLBUTTON]:Hittest( nRow, nCol ) < 0
            aControls[CTL_CXLBUTTON]:Select()
            nRetVal := K_ESC
         endcase

      case nKey == 1002
         Do Case
         case aControls[CTL_LISTF]:Vscroll:Hittest( nRow, nCol ) == -3074 //.OR. ;
            aControls[CTL_LISTF]:NextItem()
            //aControls[CTL_LISTF]:VScroll:Update()
         case aControls[CTL_LISTF]:Vscroll:Hittest( nRow, nCol ) == -3075
            aControls[CTL_LISTF]:PrevItem()
            //         aControls[CTL_LISTF]:VScroll:Update()
         case aControls[CTL_LISTS]:Vscroll:Hittest( nRow, nCol ) == -3074 //.OR. ;
            aControls[CTL_LISTS]:NextItem()
            //aControls[CTL_LISTS]:VScroll:Update()
         case aControls[CTL_LISTS]:Vscroll:Hittest( nRow, nCol ) == -3075
            aControls[CTL_LISTS]:PrevItem()
            //         aControls[CTL_LISTS]:VScroll:Update()
         endcase

      endcase
   endcase

RETURN nRetVal

