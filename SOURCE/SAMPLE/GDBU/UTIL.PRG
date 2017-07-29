* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical DBU                                              ³
* ³  Description: display pushbuttons for dbview                             ³
* ³    File Name: UTIL.PRG                                                   ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: ş11-09-95              ³
* ³ Time created: 08:28:29pm            Time updated: ş12:49:46pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Computer Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#INCLUDE "INKEY.CH"
Function BitmapA(oBrowse)
   local aIco := {}
   local oPush1, oPush2, oPush3, oPush4, oPush5

   oPush1 := PushButton(6, 5)
   oPush1:BitMap := "ArrowL.bmp"
   oPush1:Sizex := 29
   oPush1:Sizey := 25
   oPush1:SBlock := {||oBrowse:Up() }
   oPush1:Display()
   AADD(aIco, oPush1)

   oPush2 := PushButton(6, 9)
   oPush2:BitMap := "ArrowDL.bmp"
   oPush2:Sizex := 29
   oPush2:Sizey := 25
   oPush2:SBlock := {||oBrowse:PageUp() }
   oPush2:Display()
   AADD(aIco, oPush2)

   oPush3 := PushButton(6, 13)
   oPush3:BitMap := "ArrowDR.bmp"
   oPush3:Sizex := 29
   oPush3:Sizey := 25
   oPush3:SBlock := {||oBrowse:PageDown() }
   oPush3:Display()
   AADD(aIco, oPush3)

   oPush4 := PushButton(6, 17)
   oPush4:BitMap := "ArrowR.bmp"
   oPush4:Sizex := 29
   oPush4:Sizey := 25
   oPush4:SBlock := {||oBrowse:Down() }
   oPush4:Display()
   AADD(aIco, oPush4)

   oPush5 := PushButton(6, 21)
   oPush5:BitMap := "Quitu.bmp"
   oPush5:Sizex := 29
   oPush5:Sizey := 25
   oPush5:SBlock := {|| __KeyBoard(Chr(K_ESC)) }
   oPush5:Display()
   AADD(aIco, oPush5)


Return ( aIco)

Function BitmapB(oBrowse, aF)
   local aIco := {}
   local oPush1, oPush2, oPush3, oPush4, oPush5

   oPush1 := PushButton(25, 13)
   oPush1:BitMap := "ArrowL.bmp"
   oPush1:Sizex := 29
   oPush1:Sizey := 25
   oPush1:SBlock := {|| ChangeRec(1, oBrowse, aF) } //oBrowse:Up() }
   oPush1:Display()
   AADD(aIco, oPush1)

   oPush2 := PushButton(25, 17)
   oPush2:BitMap := "ArrowDL.bmp"
   oPush2:Sizex := 29
   oPush2:Sizey := 25
   oPush2:SBlock := {||ChangeRec(2, oBrowse, aF)}//oBrowse:PageUp() }
   oPush2:Display()
   AADD(aIco, oPush2)

   oPush3 := PushButton(25, 21)
   oPush3:BitMap := "ArrowDR.bmp"
   oPush3:Sizex := 29
   oPush3:Sizey := 25
   oPush3:SBlock := {|| ChangeRec(3, oBrowse,aF)  } //oBrowse:PageDown() }
   oPush3:Display()
   AADD(aIco, oPush3)

   oPush4 := PushButton(25, 25)
   oPush4:BitMap := "ArrowR.bmp"
   oPush4:Sizex := 29
   oPush4:Sizey := 25
   oPush4:SBlock := {||ChangeRec(4, oBrowse, aF) } //oBrowse:Down() }
   oPush4:Display()
   AADD(aIco, oPush4)

   oPush5 := PushButton(25, 29)
   oPush5:BitMap := "Quitu.bmp"
   oPush5:Sizex := 29
   oPush5:Sizey := 25
   oPush5:SBlock := {|| __KeyBoard(Chr(K_ESC)) }
   oPush5:Display()
   AADD(aIco, oPush5)


Return ( aIco)



Function ButtonTest(aPush, nRow, nCol)
   local lRet := .F.
   local i
   FOR i := 1 TO Len(aPush)
      IF aPush[i]:Hittest( nRow, nCol ) < 0
         aPush[i]:SetFocus()
         aPush[i]:Select()
         aPush[i]:KillFocus()
         lRet := .T.
         Exit
      ENDIF
   NEXT
Return lRet


Function Opentext()
   local cText
   local oErr
   local oError := ErrorBlock( {|o|Break(o)})
   local lRet
   cText := OpenDialog("*.txt")
   Begin Sequence
      if !(lRet := Empty(cText))
         DISPMEMO(MemoRead(cText), .F. )
      endif
   Recover using oErr
      MessageBox( Str(oErr:OsCode)+" Error has occured")
      Tone(3000,4)
   end Sequence
   ErrorBlock(oError)
Return .T.


Function DoZap()
   local cFile, nAns, lRet

   IF !Used()
      MessageBox("No work area open....")
      lRet := .F.
   else
      cFile := Alias()
      nAns := MessageBox(Upper(cFile)+".DBF is about to be emptied;"+;
         "Are sure ?",{"Zap","Abort"},"Abort")
      IF nAns == 1
         Zap
         lRet := .T.
      Else
         lRet := .F.
      ENDIF
   Endif
Return lRet

Function DoPack()
   local cFile, nAns, lRet

   IF !Used()
      MessageBox("No work area open....")
      lRet := .F.
   else
      cFile := Alias()
      nAns := MessageBox(Upper(cFile)+".DBF is about to be packed;"+;
         "Are sure ?",{"Pack","Abort"},"Abort")
      IF nAns == 1
         Pack
         lRet := .T.
      Else
         lRet := .F.
      ENDIF
   Endif
Return lRet

