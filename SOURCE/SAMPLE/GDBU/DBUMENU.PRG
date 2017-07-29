* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical DBU                                              ³
* ³  Description: Main menu                                                  ³
* ³    File Name: DBUMENU.PRG                                                ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: ş10-29-95              ³
* ³ Time created: 08:27:48pm            Time updated: ş08:27:48pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Computer Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#INCLUDE "llibg.CH"
#include "button.ch"
#include "inkey.ch"
REQUEST DBFCDX
REQUEST DBFNDX
REQUEST DBFMDX
Static oInfo
Static cRdd
Static cWorkArea
Function Main()
   local nId := 0, aFont, aFont1, nColor := 12
   local cString := "Computer Associates International Inc."
   local cBmp
   local cOldDir
   local cOldDrv
   nId := 0
   SET VIDEOMODE TO 18
   MHIDE()
   cOldDrv := DiskName()
   cOldDir := CurDir(cOldDrv+":")
   CLS                                           //3
   GFRAME(0, 0, 640, 480, 15, 9, 8, 30, 3, 3, 3, LLG_MODE_SET)

   // Load a specific font file into memory
   aFont := GFNTLOAD("TNR12.FNT")

   GWRITEAT(200 , 0, cString, nColor, LLG_MODE_SET, aFont)
   GFNTERASE(aFont)

   cBmp := GBmpLoad( "Clip.bmp")
   GBmpDisp(cBmp, 250,150)
   Set score off
   Set status off
   SET EVENTMASK TO 158
   MSETCURSOR(.T.)

   oInfo:=MCreate()
   MSHOW()
   While  nId <> 900
      SetRdd( "DBFNTX" )
      ShowArea()

      nId := MENUMODAL(oInfo,1,29,0,79,"r/w")
   end
   DiskChange(cOldDrv)
   DirChange( cOldDir )
   /* *Important* You must erase the font if it is no longer used. */
RETURN ( NIL )

function MCreate()
   local oTopBar, oPopUp, oSpopup
   oTopBar := TopBar( 2, 1, 78)
   oTopBar:ColorSpec :="GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"

   /* File */
   oPopUp := PopUp()
   oPopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oSpopUp := PopUp()
   oSpopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oSpopUp:AddItem(MenuItem( "&DBFNTX" ,{|o| SETRDD("DBFNTX",o) },,""))
   oSpopUp:AddItem(MenuItem( "DBF&CDX" ,{|o| SETRDD("DBFCDX",o) },,""))
   oSpopUp:AddItem(MenuItem( "DBF&NDX" ,{|o| SETRDD("DBFNDX",o) },,""))
   oSpopUp:AddItem(MenuItem( "DBF&MDX" ,{|o| SETRDD("DBFMDX",o) },,""))

   oPopUp:AddItem(MenuItem( "&RDD Selection" ,oSpopup,,""))
   oPopUp:AddItem(MenuItem( "&New" ,{|| DBUStru(.T.,.F.) },,""))
   oPopUp:AddItem(MenuItem( "&Modify Structure" ,{|| DBUStru(.F., .F.) },,""))
   oPopUp:AddItem(MenuItem( "&Create Index" ,{||DBUStru(.F., .T. ) },,""))
   oPopUp:AddItem(MenuItem( "Open &Database" ,{||OpenDbf() },,""))
   oPopUp:AddItem(MenuItem( "Open &Index" ,{||OpenIdx() },,""))
   oPopUp:AddItem(MenuItem( "&Close" ,{||CloseArea() },,""))
   oPopUp:AddItem(MenuItem( "E&xit" ,{|| .T. },,"",900))
   //   oPopUp:AddItem(MenuItem( "E&xit" ,{|| __Quit() },,"",900))

   oTopBar:AddItem( MenuItem ( "&File",oPopUp) )

   /* Edit */
   oPopUp := PopUp()
   oPopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oPopUp:AddItem(MenuItem( "&Browse" ,{|| DBView(.T.) },,""))
   oPopUp:AddItem(MenuItem( "&Form" ,{|| FormView(.T.) },,""))

   oTopBar:AddItem( MenuItem ( "&Edit",oPopUp) )

   /* Utility */
   oPopUp := PopUp()
   oSpopUp := PopUp()
   oSpopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oSpopUp:AddItem(MenuItem( "&DBF/SDF/DELIM" ,{|| DoCopy(1) },,""))
   oSpopUp:AddItem(MenuItem( "&Structure    " ,{|o| CopyFS(1) },,""))
   oSpopUp:AddItem(MenuItem( "&File         " ,{|o| CopyFS(2) },,""))

   oPopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oPopUp:AddItem(MenuItem( "&Copy" ,oSpopUp,,""))
   oPopUp:AddItem(MenuItem( "&Append" , {||DoCopy(2) },,"" ) )
   oPopUp:AddItem(MenuItem( "&Replace" ,{|| REPLIT() },,""))
   oPopUp:AddItem(MenuItem( "&Pack   " ,{||DoPack( ) },,"" ) )
   oPopUp:AddItem(MenuItem( "&Zap" ,{|| DoZap() },,""))

   oTopBar:AddItem( MenuItem ( "&Utility",oPopUp) )

   /* View */
   oPopUp := PopUp()
   oPopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oPopUp:AddItem(MenuItem( "&Browse" ,{|| DBView(.F. ) },,""))
   oPopUp:AddItem(MenuItem( "&Text" ,{|| OpenText() },,""))

   oTopBar:AddItem( MenuItem ( "&View",oPopUp) )

   /* Search */
   oPopUp := PopUp()
   oPopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oPopUp:AddItem(MenuItem( "&Seek"  ,{|o| Search(o) },,""))
   oPopUp:AddItem(MenuItem( "&Goto"  ,{|o| Search(o) },,""))
   oPopUp:AddItem( MenuItem( MENU_SEPARATOR ) )
   oPopUp:AddItem(MenuItem( "&Filter" ,{||BldFilter()},,""))

   oTopBar:AddItem( MenuItem ( "&Search",oPopUp) )

   /* Work areas */
   oPopUp := PopUp()
   oPopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oPopUp:AddItem(MenuItem( "No workarea" ,{|| .t. },,""))

   oTopBar:AddItem( MenuItem ( "&Work Areas",oPopUp) )

   oPopUp := PopUp()
   oPopUp :ColorSpec:= "GR+/B,GR+/N,BG+/B,GR+/N,N+/B,N+/B"
   oPopUp:AddItem(MenuItem( "No Orders" ,{|| .t. },,""))

   oTopBar:AddItem( MenuItem ( "&Indexes",oPopUp) )
return ( oTopBar)

/* I need to get the object of the menu some time. This function returns
   the object which is declared static.  */
Function TopMenu()
Return oInfo


/* To open the dbf file and place the name in the work areas menu */
Function OpenDbf(cFile)
   local cExt
   local oMenuItem
   local cString := "CURRENT WORKAREA: "
   local oError, cError
   local bError := ErrorBlock( {|o| Break(o) })
   oMenuItem := TopMenu():GetItem(6)
   if Empty(cFile)
      cFile := OpenDialog("*.DBF")
   endif
   IF Select(StripFile(cFile)) > 0
      MessageBox("This file is already open ;Please verify..")
      Return .F.
   ENDIF
   Begin Sequence
      IF !Empty(cFile)
         Use (cFile) New
         cExt := OrdBagExt()
         RemoveItem()
         FillMenu(cFile,oMenuItem)
         UncheckI(oMenuItem:Data)
         CheckItem(oMenuItem:Data:GetItem(oMenuItem:Data:GetLast()))
         IF Right(cExt,3) == 'CDX' .OR. Right(cExt,3) == 'MDX'
            FillIndex(7)
         ENDIF
         ShowArea( )
      ENDIF
   Recover using oError
      cError := oError:Description
      MessageBox("Error:"+cError)
   end sequence
   errorblock( bError )
Return .T.

FUNCTION FillMenu( cFile, oMenuITem )
   local cItem
   local bBlock
   bBlock := {|oPop|ChangeArea(oPop)}
   cItem := StripFile( cFile )
   IF oMenuItem:Data:GetItem(1):Caption == 'No workarea'
      oMenuItem:Data:SetItem(1, MenuItem( cItem, ;
         bBLock,,""))
   Else
      oMenuItem:Data:AddItem(  MenuItem( cItem, ;
         bBlock,,""))
   Endif
   oMenuItem:Data:Display()
Return .T.


Function OpenIdx(cFile)
   local aFile, oMenuItem, cItem
   local nStart, nEnd, cExt, bBlock
   local oError, cError
   local bError := ErrorBlock( {|o| Break(o) })
   bBlock := {|oPop|ChangeOrd(oPop)}

   oMenuItem := TopMenu():GetItem(7)

   if !Used()
      MessageBox("A Database must be open first")
      Return .F.
   endif

   cExt := OrdBagExt()
   if Empty(cFile)
      cFile := OpenDialog("*"+cExt)
   endif
   if !Empty(cFile)
      cItem := StripFile(cFile)
      if OrdNumber(cItem) > 0
         Return .T.
      endif
      Begin Sequence
         OrdListAdd( cFile)
      Recover using oError
         cError := oError:Description
         MessageBox("Error:"+cError)
      end sequence
      errorblock( bError )
      if ( cExt == '.CDX' ) .OR. ( cExt == '.MDX' )
         if !Empty(cFile )
            FillIndex(oMenuItem)
         endif
      else
         if oMenuItem:Data:GetItem(1):Caption == 'No Orders'
            oMenuItem:Data:SetItem(1, MenuItem( "Natural", ;
               bBlock,,""))
            oMenuItem:Data:AddItem(  MenuItem( cItem, ;
               bBlock,,""))
         else
            oMenuItem:Data:AddItem(  MenuItem( cItem, ;
               bBlock,,""))
         endif
      endif
   endif
Return .T.

FUNCTION FillIndex(oMenuI)
   local aFile, cItem, bBlock, oMenuItem, i
   bBlock := {|oPop|ChangeOrd(oPop)}

   if Valtype(oMenuI) != 'O'
      oMenuItem := TopMenu():GetItem(oMenuI)
   else
      oMenuItem := oMenuI
   endif
   aFile := GetOrders()
   FOR i := 1 TO Len(aFile)
      cItem := aFile[i]
      IF oMenuItem:Data:GetItem(1):Caption == 'No Orders'
         oMenuItem:Data:SetItem(1, MenuItem( "Natural", ;
            bBlock,,""))
         oMenuItem:Data:AddItem(  MenuItem( cItem, ;
            bBlock,,""))

      Else
         oMenuItem:Data:AddItem(  MenuItem( cItem, ;
            bBlock,,""))
      Endif
   next
   ChangeOrd(oMenuItem:Data:GetItem(1))
   oMenuItem:Data:Display()
Return .T.

Function ChangeArea(oArea)
   local cArea
   local cString
   IF Valtype(oArea) == 'O' .OR. ValType(oArea) == 'C'
      IF ValType(oArea)== 'C'
         cArea := oArea
      Else
         cArea := oArea:Caption
      Endif
      UncheckI(TopMenu():GetItem(6):Data)
      CheckItem(oArea)
      DbSelectArea(cArea)
      RemoveItem()
      FillIndex(7)
      ShowArea()
   ENDIF
Return .t.

Function ChangeOrd(oArea)
   local nOrder := 0
   local nOldOrder := IndexOrd()
   IF Valtype(oArea) == "O"
      nOrder := OrdNumber( oArea:Caption )
      UncheckI(TopMenu():GetItem(7):Data)
      CheckItem(oArea)
   ElseIf ValType(oArea) == 'C'
      nOrder := OrdNumber( oArea )
   ENDIF
   DBSetOrder(nORder)
Return nOldOrder != nOrder

Function CloseArea()
   loca cString
   local oMenuItem := TopMenu():GetItem(6)
   local nItemCount := oMenuItem:Data:ItemCount
   local cItem := Alias(), i

   IF Used()
      DBCloseArea()
      FOR I := 1 TO nItemCount
         IF oMenuItem:Data:GetItem(i):Caption == cItem
            IF nItemCount < 2
               oMenuItem:Data:SetItem(1, MenuItem( "No workarea", ;
                  {||.t.},,"" ) )
            Else
               oMenuItem:Data:DelItem(i)
            Endif
            oMenuItem:Data:Display()
            exit
         ENDIF
      NEXT
      ShowArea()
      RemoveItem()
   ELSE
      MessageBox("There is nothing to close.")
   ENDIF
Return .T.

Function GetOrders()
   local aOrders, nOrder
   local i := 1
   local cName
   aOrders := {}
   while i > 0
      cName := OrdName(i)
      IF !Empty(cName)
         AADD(aOrders, cName )
      Else
         exit
      endif
      ++I
   EndDo
Return ( aOrders )

Function StripFile(cFile)
   local cItem, nStart, nEnd
   nStart :=  Rat("\",cFile)+1
   nEnd := (At(".",cFile)) - nStart
   cItem := SubStr( cFile, nStart, nEnd )
Return cItem


Function RemoveItem()
   local oMenuITem := TopMenu():GetItem(7)
   local cItem
   local nItemCount := oMenuItem:Data:ItemCount
   While nItemCount > 0
      cItem := oMenuItem:Data:GetItem(nItemCount):Caption
      IF nItemCount == 1
         oMenuItem:Data:SetItem(1, MenuItem( "No Orders", ;
            {||.t.},,"" ) )
      Else
         oMenuItem:Data:DelItem(nItemCount)
      Endif
      oMenuItem:Data:Display()
      nItemCount--
   EndDo
Return .T.

Function SetRdd(cSetRdd, oItem)
   local cString
   local nColor := 12
   RddSetDefault(cSetRdd)
   cRdd := cSetRdd
   cString := "CURRENT RDD: "+cRdd
   ShowRdd(cString)
   UncheckI(TopMenu():GetItem(1):Data:GetItem(1):Data)
   CheckItem(oItem)
Return .T.

Function Rdd()
Return ( cRdd )

FUNCTION SHOWRDD(cString)
   STATIC cOld := ''
   local aFont := GFNTLOAD("TNR08.FNT")
   local x := 14, y := 16
   local nColor := 2
   IF Empty(cOld)
      GWRITEAT( x, y, cString, nColor, LLG_MODE_XOR, aFont)
      cOld := cString
   ELSE
      GWRITEAT( x,y, cOld, nColor, LLG_MODE_XOR, aFont)
      GWRITEAT( x,y, cString, nColor, LLG_MODE_XOR, aFont)
      cOld := cString
   ENDIF
   GFNTERASE(aFont)
RETURN NIL

FUNCTION SHOWAREA()
   STATIC cOld := ''
   local aFont := GFNTLOAD("TNR08.FNT")
   local x := 432, y := 16
   local nColor := 2
   local cString
   cString := "CURRENT WORKAREA: " + ;
      IF(Empty(ALIAS()),"NO AREA ",ALIAS())
   IF Empty(cOld)
      GWRITEAT( x, y, cString, nColor, LLG_MODE_XOR, aFont)
      cOld := cString
   ELSE
      GWRITEAT( x,y, cOld, nColor, LLG_MODE_XOR, aFont)
      GWRITEAT( x,y, cString, nColor, LLG_MODE_XOR, aFont)
      cOld := cString
   ENDIF
   GFNTERASE(aFont)
RETURN NIL


Function UncheckI(oPop)
   local oMenuITem := oPop
   local lChecked
   local nItemCount := oMenuItem:ItemCount
   While nItemCount > 0
      lChecked := oMenuItem:GetItem(nItemCount):Checked
      IF lChecked
         oMenuItem:GetItem(nItemCount):Checked := .F.
         Exit
      Endif
      oMenuItem:Display()
      nItemCount--
   EndDo
Return nil

FUNCTION CHECKITEM(oItem)
   IF (oItem != nil )
      oItem:Checked := .T.
   ENDIF
Return .T.
