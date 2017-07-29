* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical DBU                                              ³
* ³  Description: To display messages                                        ³
* ³    File Name: MSGBOX.PRG                                                 ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: ş10-29-95              ³
* ³ Time created: 08:22:32pm            Time updated: ş08:22:32pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Computer Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#DEFINE BUTTON1 1
#DEFINE BUTTON2 2
#DEFINE BUTTON3 3
#INCLUDE "llibg.CH"
#INCLUDE "INKEY.CH"
Function MessageBox(cString, aButtons, cDef )
   local nT, nR, nB, nL
   local aString
   local button
   local nSelected
   local nClicked
   local nLines := 0
   local nWidth := 0
   local nXB
   local cCaption := "MESSAGE BOX"
   local cColorSpec := "w/w,w/w,w/w,w/w"
   local cScreen
   local nKey
   local nFocus
   IF aButtons == nil
      button := Array(1)
   else
      button := Array( Len(aButtons))
   ENDIF

   aString := ListAsArray( cString, ";" )
   Set VideoMode to 18
   Set EventMask to 158
   MSetCursor(.T.)
/* Calculate the coordinates */
   nLines := Len(aString)
   AEVAL( aString, {|a| if(nWidth < len(a),nWidth := Len(a), nWidth) })

   nT := ( 30 - (nLines + 3 )) /2
   nB := nT + (nLines + 3 )
   nR := (80-(nWidth+2)) /2
   nL := nR + (nWidth+2)
   cScreen := SaveScreen( nT, nR, nB+1, nL+1 )

   SETCOLOR("+BG/B")

   MHide()
/* Draw the frame */
   GFRAME((nR * 8), (nT * 16), (nL * 8) + 8,      ;
      (nB * 16) + 16, 7, 15, 8, 20, 3, 3, 3, LLG_MODE_SET)
   GdevOut(Padc(cCaption,(nL-nR)), nR, nT,1)

   SETCOLOR("+W/B")
   AEVAL( aString, {|a,i|GDevOut(Padc(a,nWidth+2), nR, nT+i,4) })

   IF aButtons == nil
      nXb := (((nL-nR)-6)/2)+nR

      BUTTON[BUTTON1] := PushButton((nT + nLines) + 2,nXb, Padc("OK",6) )
      BUTTON[BUTTON1]:ColorSpec := cColorSpec
      BUTTON[BUTTON1]:Display()
   ELSE
      nWidth := 0
      AEVAL( aButtons, {|a| if(nWidth < len(a),nWidth := Len(a), nWidth) })
      IF nWidth < 6
         nWidth := 6
      ENDIF
      Do Case
      case Len(aButtons) == 2
         nXb := Round((((nL-nR)-((nWidth*2)+2))/2)+nR, 0 )

         Button[BUTTON1] := PushButton((nT+nLines)+2, nXb, Padc(aButtons[1],nWidth))
         Button[BUTTON1]:ColorSpec := cColorSpec
         Button[BUTTON1]:Display()

         Button[BUTTON2] := PushButton((nT+nLines)+2,nXb+(nWidth+2), Padc(aButtons[2],nWidth))
         Button[BUTTON2]:ColorSpec := cColorSpec
         Button[BUTTON2]:Display()
      case Len(aButtons) == 3
         nXb := Round((((nL-nR)-((nWidth*3)+2))/2)+nR,0)

         Button[BUTTON1] := PushButton((nT+nLines)+2,nXb, Padc(aButtons[1], nWidth))
         Button[BUTTON1]:ColorSpec := cColorSpec
         Button[BUTTON1]:Display()

         Button[BUTTON2] := PushButton((nT+nLines)+2,nXb+(nWidth+2), Padc(aButtons[2], nWidth))
         Button[BUTTON2]:ColorSpec := cColorSpec
         Button[BUTTON2]:Display()

         Button[BUTTON3] := PushButton((nT+nLines)+2,nXb+((nWidth*2)+4), Padc(aButtons[3], nWidth))
         Button[BUTTON3]:ColorSpec := cColorSpec
         Button[BUTTON3]:Display()
      EndCase

   ENDIF
   MShow()
   IF cDef == nil
      button[BUTTON1]:SetFocus()
   else
      button[ascan(abuttons, cdef)]:SetFocus()
   endif
   while .T.
      nKey := Inkey(0)
      nFocus := isFocus(button)
      do case
      case nKey == K_ESC
         nSelected := 0
         exit
      case nKey == K_ENTER
         IF nFocus > 0
            Button[nFocus]:Select()
            nSelected := nFocus
            Exit
         ENDIF
      case nKey == K_LEFT
         IF nFocus > 0
            IF nFocus == 1 .AND. Len(button) > 1
               Button[nFocus]:KillFocus()
               nFocus := Len(button)+1
               Button[nFocus-1]:SetFocus()
            Else
               Button[nFocus]:KillFocus()
               Button[nFocus-1]:SetFocus()
            ENDIF
         ENDIF
      case nKey == K_RIGHT
         IF nFocus > 0
            IF nFocus == Len(button) .AND. Len(button) > 1
               Button[nFocus]:KillFocus()
               nFocus := 0
               Button[nFocus+1]:SetFocus()
            Else
               Button[nFocus]:KillFocus()
               Button[nFocus+1]:SetFocus()
            ENDIF
         ENDIF

      case nKey == K_LBUTTONDOWN
         IF (nClicked := ClickedOn(Button)) > 0
            Button[nFocus]:KillFocus()
            Button[nClicked]:Select()
            nSelected := nClicked
            Exit
         ENDIF
      endcase
   enddo

   RestScreen( nT, nR, nB+1, nL+1, cScreen )

Return nSelected

Function GdevOut(cString, X, Y, C)
   GWRITEAT( (X*8), (Y*16)+4, cString, C, LLG_MODE_SET )
Return .T.


FUNCTION ListAsArray( cList, cDelimiter )

   local nPos                                    // Position of cDelimiter in cList
   local aList := {}                             // Define an empty array
   cDelimiter := if(cDelimiter==nil,",",cDelimiter)

   // Loop while there are more items to extract
   DO WHILE ( nPos := AT( cDelimiter, cList )) != 0

      // Add the item to aList and remove it from cList
      AADD( aList, SUBSTR( cList, 1, nPos - 1 ))
      cList := SUBSTR( cList, nPos + 1 )

   ENDDO
   AADD( aList, cList )                          // Add final element

RETURN ( aList )                                 // Return the array


Function IsFocus(aButton)
   local i
   local nRet := 0
   FOR i := 1 TO len(aButton)
      IF aButton[i]:HasFocus
         nRet := i
         exit
      ENDIF
   NEXT

Return nRet

Function ClickedOn(aButton)
   local i
   local nRet := 0
   FOR i := 1 TO len(aButton)
      IF aButton[i]:Hittest( MRow(), MCol() ) == -2049
         nRet := i
         exit
      ENDIF
   NEXT

Return nRet
