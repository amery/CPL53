* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical DBU                                              ³
* ³  Description: To display and select files to be loaded                   ³
* ³    File Name: DIALOG.PRG                                                 ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: ş10-29-95              ³
* ³ Time created: 08:24:29pm            Time updated: ş08:24:29pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Computer Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#include "llibg.ch"
Static nSubs
Static nSubs1
Static cSpec
#DEFINE COLOR_SPEC "W+/B,GR+/B,W/N,N,GR+/W,N/BG,B+/BG,GR+/BG"
#DEFINE LISTBOX_COLOR "W+/B,GR+/B,W+/B,Gr+/B,GR+/B,N/B,B+/B,GR+/B"


Function OpenDialog(cSp)
   local cFilename := Space(12)
   local cDrives := DiskName(), aDirec := Directory("*.","D")
   local cDirec := Space(12), aDirList := {}
   local cFlist := Space(12), aFlist := {}
   local aDrives := AllDrives(), aFileList, cSpecs, GetList := {}
   local oKButton := .F. , cXlButton := .F.
   local aSpecs := {{"All Files ","*.*"}  ,;
      {"Databases","*.DBF"}  ,;
      {"Indexes NTX","*.NTX"},;
      {"Indexes CDX","*.CDX"},;
      {"Indexes MDX","*.MDX"},;
      {"Indexes NDX","*.NDX"},;
      {"Text file  ","*.TXT"}}
   LOCAL oBrow, oBrow1, aScreen, oCol

   cSpec  := If(cSp == nil,"*.*",cSp)
   cSpecs := If(cSp == nil,"*.*",cSp)
   aFileList := Directory(cSpec)
   nSubs := 1
   nSubs1 := 1

   AEVAL(aFileList, {|x,y|AADD(aFlist, x[1]) })
   AEVAL(aDirec, {|x,y|if(x[5]=='D',AADD(aDirList, x[1]),"") })
   aFlist := ASORT(aFList,,, { |x, y| x < y })
   aDirList := ASORT(aDirList,,, { |x, y| x < y })

   aScreen := SaveScreen(0, 0, MaxRow(), MaxCol())

   mHide()
   // Frame for dialog box
   GFRAME(20, 80, 449, 282, 9, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)

   GFRAME(20, 77, 449, 100, 1, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)

   GFRAME(47,143, 170, 243, 9, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)

   GFRAME(222,143, 347, 243, 9, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)

   @ 5,25 SAY "Open File" Color "W+/b+"

   oBrow := TBROWSENEW( 9, 6,14,20 )
   oBrow:ColorSpec := COLOR_SPEC
   oBrow:Border := LLG_BOX_GRAY_STD
   oBrow:FootSep := ''
   oBrow:Cargo := if(Len(aFlist) < 1,aFlist := {Padc("<NONE>",12)},aFList)
   oBrow:skipBlock     := {|nReq| ArraySkip(nReq, oBrow:Cargo, @nSubs)}
   oBrow:goTopBlock    := {|| nSubs := 1}
   oBrow:goBottomBlock := {|| nSubs := Len(oBrow1:Cargo)}
   oCol := TBCOLUMNNEW( , {|| oBrow:Cargo[nSubs]})
   oCol:Width := 12
   oBrow:addColumn(oCol)
   oBrow:ForceStable()


   oBrow1 := TBROWSENEW( 9,28,14,42 )
   oBrow1:ColorSpec := COLOR_SPEC
   oBrow1:Cargo := aDirlist
   oBrow1:skipBlock     := {|nReq| ArraySkip(nReq, oBrow1:Cargo, @nSubs1)}
   oBrow1:goTopBlock    := {|| nSubs1 := 1 }
   oBrow1:goBottomBlock := {|| nSubs1 := Len(oBrow1:Cargo)}
   oCol := TBCOLUMNNEW( , {|| oBrow1:Cargo[nSubs1]})
   oCol:Width := 12
   oBrow1:addColumn(oCol)
   oBrow1:ForceStable()

   @ 7, 6 GET cFileName
   @ 9, 6, 14, 20 Get cFlist Tbrowse oBrow
   @ 9,28, 14, 42 Get cDirec Tbrowse oBrow1
   @ 7, 46 GET OKBUTTON  PUSHBUTTON CAPTION "OK" SIZE X 50 Y 20 State {||ITISOK(@cFileName, GetList) }COLOR "W/N,W/N,W/N,W/N"
   @ 9, 46 GET CXLBUTTON PUSHBUTTON CAPTION "Cancel" SIZE X 50 Y 20 State {||ITISCXL(@cFileName,GetList) }COLOR "W/N,W/N,W/N,W/N"
   @ 16, 6, 22, 20 GET cSpecs LISTBOX aSpecs DROPDOWN Color LISTBOX_COLOR STATE {||IdxSpec(GetList)} SCROLLBAR
   @ 16, 28, 22, 42 GET cDrives LISTBOX aDrives DROPDOWN Color LISTBOX_COLOR STATE {||DRIVECD(GetList)} SCROLLBAR
   MShow()
   READ
   RestScreen(0,0,MaxRow(), MaxCol(), aScreen)

RETURN (cFileName)


STATIC FUNCTION ArraySkip( nRequest, aArray, nSub)
   LOCAL nActually := 0

   nActually := IF(ABS(nRequest) >= IF(nRequest >= 0,;
      LEN(aArray) - nSub, nSub - 1),;
      IF(nRequest >= 0, LEN(aArray) - nSub,;
      1 - nSub), nRequest)

   nSub += nActually
RETURN (nActually)


Function TbSelect(Getlist,nWhich, lDrive, cSpecs)
   local oTb2 := GetList[3]:Control
   local oTb1 := GetList[2]:Control
   local oCol1 := oTb1:GetColumn(1)
   local oCol2 := oTb2:GetColumn(1)
   local cDir := Alltrim(Eval(oCol2:Block))
   local aNewDir, aNewDir2
   IF ValType(lDrive) != 'L'
      lDrive := .F.
   ENDIF

   If nWhich == 1
      GetList[1]:VarPut( Eval(oCol1:Block) )
      GetList[1]:Display()
   Else

      IF !lDrive
         DirChange(cDir)
      endif

      oTb2:Cargo := {}
      oTb1:Cargo := {}

      aNewDir := ASORT(Directory("*.*","D"),,, { |x, y| x[1] < y[1] })
      AEVAL(aNewDir, {|x,y|if(x[5]=='D',AADD(oTb2:Cargo,x[1]),"") })
      oTb2:Cargo := IF( Len(oTb2:Cargo) < 1, {"."},oTb2:Cargo )

      aNewDir := Directory(cSpec)
      aNewDir := if(Len(aNewDir) < 1, {{Padc("<NONE>",12)}},ASORT(aNewDir,;
         ,,, {|X,Y| X[1] < Y[1] }) )
      AEVAL(aNewDir, {|x,y|AADD(oTb1:Cargo,x[1] ) })

      nSubs := Len(oTb1:Cargo)
      nSubs1 := len(oTb2:Cargo)

      oTb1:GoTop()
      oTb2:GoTop()

      oTb1:Configure()
      oTb1:ForceStable()

      oTb2:Configure()
      oTb2:ForceStable()

   EndIf
Return .T.

Function ITISOK(cFileName, GetList)
   local oGet := Getlist[4]
   IF Empty(cFileName)
      cFileName := ''
   Else
      cFileName := DiskName()+":\"+CurDir()+"\"+Alltrim(cFileName)

   EndIf
   IF oGet != nil
      oGet:ExitState := 6
   endif
Return .T.

Function ITISCXL(cFileName, GetList)
   local oGet := GetList[5]
   cFileName := ''
   IF oGet != nil
      oGet:ExitState := 7
   endif
Return .T.


FUNCTION AllDrives()
   LOCAL wI
   local cDrive := ""
   local aDrives := {}
   local cCurDrive := DiskName()                 // Save Current Drive
   FOR wI := 1 TO 26
      cDrive := Chr( wI + 64 )
      IF DISKCHANGE( cDrive )
         AADD( aDrives, cDrive )
      ENDIF
   NEXT
   DISKCHANGE( cCurDrive )                       // Restore Current drive
RETURN aDrives

Function DriveCD(GetList)
   local oGet := GetList[7]
   local cCurDrive := DiskName()
   local oControl
   oControl := oGet:Control
   IF oControl != nil
      DiskChange(Alltrim(Upper(oControl:Buffer)))
      TbSelect(GetList, 2, .T. )
   EndIf
Return .T.

Function IdxSpec(GetList,x)
   local oGet := GetList[6]
   local oControl
   oControl := oGet:Control
   IF oControl != nil
      cSpec := oControl:GetData( oControl:Value )
      TbSelect(GetList, 2, .T. )
   EndIf
Return .T.


