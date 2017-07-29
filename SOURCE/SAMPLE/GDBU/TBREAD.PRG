#include "button.ch"
#include "Inkey.ch"
#include "Getexit.ch"
#include "Set.ch"
#include "SetCurs.ch"
#include "tbrowse.ch"
#include "llibg.ch"

PROCEDURE ReplReader( oGet, GetList, aRepl )
   local oTB, nKey, lAutoLite, nCell, nSaveCursor, nProcessed
   local snHitCode

   // Read the GET if the WHEN condition is satisfied
   IF ( ! GUIPreValidate( oGet, oGet:Control ) )
   elseif ( ValType( oGet:Control ) == "O" )

      nSaveCursor := SetCursor( SC_NONE )

      // Activate the GET for reading

      oTB := oGet:Control
      snHitCode := oTB:Hittest( MRow(), MCol() )

      lAutoLite := oTB:Autolite
      oTB:Autolite := .T.
      oTB:Hilite()

      if ( snHitCode == HTCELL )
         tbMouse( oTB, mRow(), mCol() )
      endif

      snHitCode := 0

      WHILE ( oGet:exitState == GE_NOEXIT )

         // Apply keystrokes until exit
         WHILE ( oGet:exitState == GE_NOEXIT )
            nKey := 0

            WHILE ( ( ! oTB:Stabilize() ) .AND. ( nKey == 0 ) )
               nKey := Inkey()
            ENDDO

            IF ( nKey == 0 )
               nKey := Inkey(0)
            ENDIF

            ReplApplyKey( oGet, oTB, GetList, nKey, aRepl)


         ENDDO

         // Disallow exit if the VALID condition is not satisfied

         IF ( !GUIPostValidate( oGet, oTB ) )
            oGet:exitState := GE_NOEXIT
         ENDIF
      ENDDO

      // De-activate the GET
      oTB:Autolite := lAutoLite
      oTB:DeHilite()
      SetCursor( nSaveCursor )
   ENDIF

RETURN

PROCEDURE ReplApplyKey( oGet, oTB, GetList, nKey, aRepl )

   LOCAL cKey
   LOCAL bKeyBlock
   local MouseRow, MouseColumn
   local nButton
   local nHotItem
   local snNextGet

   // Check for SET KEY first
   IF !( ( bKeyBlock := setkey( nKey ) ) == NIL )
      GetDoSetKey( bKeyBlock, oGet )
      RETURN                                     // NOTE
   ENDIF

   DO CASE
   CASE ( nKey == K_TAB )
      oGet:exitState := GE_DOWN

   CASE ( nKey == K_SH_TAB )
      oGet:exitState := GE_UP

   CASE ( nKey == K_ENTER )
      oGet:exitState := GE_ENTER

   CASE ( nKey == K_ESC )
      IF ( SET( _SET_ESCAPE ) )
         oGet:exitState := GE_ESCAPE
      ENDIF
   CASE nKey == K_LEFT
      oTb:Left()
   CASE nKey == K_RIGHT
      oTb:Right()
   CASE nKey == K_UP
      oTb:Up()
   CASE nKey == K_DOWN
      IF !Empty(aRepl[oTb:RowPos,1] )
         IF oTb:RowPos < Len(aRepl)
            oTb:Down()
         ELSE
            Tone(3000,5)
            AADD(aRepl,{Space(8), Space(255)})
            oTb:Down()
            oTb:RowPos := 1
            oTb:refreshall()
         ENDIF
      ENDIF

   CASE ( nKey >= 65 .AND. nKey <= 90 ) .OR. ;
         ( nKey >= 97 .AND. nKey <= 122 )
      KeyBoard CHR(nKey)
      DoGet(oTb)


   CASE ( ( nKey == K_LBUTTONDOWN ) .or. ( nKey == K_LDBLCLK ) )
      MouseRow := mrow()
      MouseColumn := mcol()

      if ( nButton != 0 )
      elseif ( ( nButton := oTB:HitTest( MouseRow, MouseColumn ) ) == HTNOWHERE )
         if ( HitTest( GetList, MouseRow, MouseColumn ) )
            oGet:exitstate := GE_MOUSEHIT
         else
            oGet:exitstate := GE_NOEXIT
         endif
      endif

   ENDCASE

RETURN

static function HitTest( GetList, MouseRow, MouseCol )
   local nCount, nTotal, snNextGet, snHitCode

   snNextGet := 0
   nTotal  := Len( GetList )

   for nCount := 1 to nTotal
      if ( ( snHitCode := GetList[ nCount ]:HitTest( MouseRow, MouseCol ) ) != HTNOWHERE )
         snNextGet := nCount
         exit
      endif
   next

   if ( snNextGet == 0 )
   elseif ( ValType( GetList[ snNextGet ]:Control ) <> "O" )
   elseif ( ! GUIPreValidate( GetList[ snNextGet ], GetList[ snNextGet ]:Control ) )
      snNextGet := 0
   endif

   if ( snNextGet == 0 )
   elseif ( ! GetPrevalidate( GetList[ snNextGet ] ) )
      snNextGet := 0
   endif

return ( snNextGet != 0 )

