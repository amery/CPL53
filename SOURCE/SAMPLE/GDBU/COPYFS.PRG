#include "llibg.ch"
Function CopyFS(nFile)
   local GetList := {}
   local nT := 8, nL := 8, nB := 14, nR := 72
   local cFromS := Space(8), cFromF := Space(128),cToS   := Space(128)
   local cToF   := Space(128), cFields := Space(255), lOk := .T.
   local lCancel := .T., lAns := .T., lRet := .T.
   local cScreen := SaveScreen( nT, nL, nB+6, nR+1 )
   local cButtonClr := "w/w,w/w,w/w,R/w"

   IF nFile == 1
      nB := 18
   ENDIF

   MHide()
   GFRAME((nL*8), (nT*16), (nR*8)+8, (nB*16)+16, 7, 15, 8, 3, 3, 3, 3, LLG_MODE_SET)

   SETCOLOR( "+W/B" )
   @ nT+2, 12 Say "From"

   IF nFile == 1
      cFromS := Alias()
      @ nT+2, 27 Say "To"
      @ nT+5, 12 Say "Fields"
      @ nT+2, 17 GET cFromS When {|| .F. }
      @ nT+3, 27 GET cToS Picture "@KS40"    Color "W+/B,W+/BG"
      @ nT+6, 12 Get cFields Picture "@KS55" Color "W+/B,W+/BG"
   Else
      @ nT+2, 42 Say "To"
      @ nT+3, 12 GET cFromF Picture "@KS25" When {||GetFile(GetList,1)} Color "W+/B,W+/BG"
      @ nT+3, 42 GET cToF Picture "@KS25"  When {||GetFile(GetList,2)} Color "W+/B,W+/BG"

   Endif

   @ nB-1, 32 GET lOK PUSHBUTTON ;
      CAPTION Padc("&OK",6)          ;
      STATE { || IsOk(@lAns, 1), ReadKill(.T.) } COLOR cButtonClr

   @ nB-1, 43 GET lCancel PUSHBUTTON ;
      CAPTION "&Cancel"         ;
      STATE { || IsOk(@lAns, 2), ReadKill(.T.) } COLOR cButtonClr

   MShow()
   READ



   IF lAns
      IF nFile == 1
         lRet := CopyStr(cFromS, cToS)
      Else
         lRet := CopyFi(cFromF, cToF )
      ENDIF
      IF !lRet
         Tone(3000,5)
         //MessageBox("The from or the to is empty copy not possible")
      ENDIF
   ENDIF
   RestScreen(nT, nL, nB+6, nR+1, cScreen)

Return .T.
Function IsOk(lAns, n)
   IF n == 1
      lAns := .T.
   Else
      lAns := .F.
   ENDIF
Return .T.

Function CopyStr(cFrom, cTo)
   local lRet := .T.
   IF  !Empty(cTo)
      __dbCopyStruct( cTo )                      // , { <(fields)> } )
   else
      lRet := .F.
   ENDIF

Return lRet

Function CopyFi(cFrom, cTo )
   local lRet := .T.
   cFrom := Alltrim(cFrom)
   cTo := Alltrim(cTo)
   IF !Empty(cFrom) .AND. !Empty(cTo)
      __CopyFile( cFrom, cTo )
   Else
      lRet := .F.
   endif

Return lRet

Function GetFile(Getlist,n)
   local cFilename
   cFileName := OpenDialog("*.*")
   IF !Empty(cFileName)
      GetList[n]:VarPut(cFileName)
   Else
      GetList[n]:VarPut(Space(128))
   ENDIF
Return .T.





