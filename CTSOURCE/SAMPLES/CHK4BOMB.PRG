*********** Sample programs for CA-Clipper Tools / 5.2 ************
*
* Program     : CHK4BOMB.PRG
* Copyright   : (c) 1991-93, Computer Associates International.
*               All rights reserved.
* Date        : 08/16/90
* Author      : Lothar Bongartz
* Description : This program is searching for text sequences
*               within .OBJ or .COM files. A sequence is a text,
*               when at least 4 sequential displayable characters
*               are found.
* Compiling   : CLIPPER CHK4BOMB
* Linking     : RTLINK FI CHK4BOMB LIB CT
* Remarks     : The program is 'supposing' by the mean of certain
*               rules, what is text and what is no text.
*
*******************************************************************

PARAMETER cFileName
cFileContens := FILESTR(cFileName)

 cChange := cFileContens              // save original

* change all valid characters to ASCII 255

 CSETREF(.T.)                         // speeds up changing

 RANGEREPL(226,   8, @cChange, 255)   // �ber '�' und unter Tab
 RANGEREPL( 10,  31, @cChange, 255)   // �ber Tab und unter ' '
 RANGEREPL(123, 128, @cChange, 255)   // �ber 'z' und unter '�'
 RANGEREPL(130, 131, @cChange, 255)   // �ber '�' und unter '�'
 RANGEREPL(133, 141, @cChange, 255)   // �ber '�' und unter '�'
 RANGEREPL(143, 147, @cChange, 255)   // �ber '�' und unter '�'
 RANGEREPL(149, 152, @cChange, 255)   // �ber '�' und unter '�'
 RANGEREPL(155, 224, @cChange, 255)   // �ber '�' und unter '�'

 nEndPos  := LEN(cFileContens) +1
 nIgnore  := 0
 n:= 0
 nPos1    := POSEQUAL(cFileContens, cChange, 4, n)

 DO WHILE nPos1 <> 0
   nPos2 := POSDIFF(cFileContens, cChange, nPos1 +3)

   IF nPos2 = 0
     nPos2 := nEndePos
   ENDIF

   ? SUBSTR(cFileContens, nPos1, nPos2 -nPos1)
   nIgnore := nPos2
   nPos1   := POSEQUAL(cFileContens, cChange, 4, nIgnore)
 ENDDO
RETURN
