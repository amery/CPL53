* 旼 Program 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
* �  Application: Graphical DBU                                              �
* �  Description: To display and edit memo and text files                    �
* �    File Name: DBUMEMO.PRG                                                �
* �       Author: Herntz P. Graham      Tester:                              �
* � Date created: 10-29-95              Date updated: �11-09-95              �
* � Time created: 08:21:06pm            Time updated: �12:29:28pm            �
* �    Make File:                                                            �
* �      Docs By: Herntz P. Graham                                           �
* �    Copyright: (c) 1995 by Computer Associates International Inc.         �
* 읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸
#INCLUDE "llibg.CH"
Function DispMemo( cString, lEdit)
local aFont
local aFont1
local x,y
local cStr1 := "Memo Viewer"
local cStr2 := " Press ESC to Abort or CTRL+W to Exit and Save "
local cColor := SetColor( "+W/B")
local cScreen := SaveScreen( 6,6,25,73)
x := 250
y := 115
MHide()
GFRAME(61, 117, 587, 390, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
GFRAME(61, 117, 587,143, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
GFRAME(61, 352, 587,390, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)
aFont := GFNTLOAD("TNR20.FNT")
GWRITEAT( X,Y,cStr1,4, LLG_MODE_SET, aFont)

aFont1 := GFNTLOAD("TNR08.FNT")
GWRITEAT( 66,355,cStr2,4, LLG_MODE_SET, aFont1)
MShow()
cString := Memoedit(cString,9,8,21,72, lEdit)
GFNTERASE(aFont)
SetColor(cColor)
RestScreen( 6,6,25,73, cScreen)
return cString
