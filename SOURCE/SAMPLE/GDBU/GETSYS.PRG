/***
*
*  Getsys.prg
*  Modified Standard Clipper 5.3 GET/READ Subsystem for GDBU.EXE
*  Version 5.3b.
*  Copyright (c) 1990 - 1997, Computer Associates International, Inc.
*  All rights reserved.
*
*  This version adds the following public functions:
*
*     ReadKill( [ <lKill> ] )                 --> lKill
*     ReadUpdated( [ <lUpdated> ] )           --> lUpdated
*     ReadFormat( [ <bFormat> ] )             --> bSavFormat | NIL
*     ReadStats( <element> [, <xNewValue> ] ) --> xoldValue
*     EraseGetMsg( <oGet>, <aMsg> )           --> NIL
*     ShowGetMsg( <oGet>, <aMsg> )            --> NIL
*   
*  This version adds the following static functions:
*
*     ClearGetSysVars()                       --> aSavSysVars
*
*  This version makes the following static functions public:
*
*     HitTest()                               --> saStatics[SNNEXTGET] != 0
*     Accelerator()                           --> 0
*
*  This version adds the following static procedure:
*
*     RestoreGetSysVars( <aSavSysVars> )
*
*  NOTE: Compile with /M /N /W
*  NOTE: Summer '87 compatibility: Compile with /M /N /W /DCTRL_END_SPECIAL
*  NOTE: Custom code handling for GDBU.EXE has been inserted
*        in TBApplyKey() in the tests for K_ENTER and tests
*        for K_LBUTTONDOWN and K_LDBLCLK
*
***/
#include "Button.Ch"
#include "GetExit.Ch"
#include "Inkey.Ch"
#include "Llibg.Ch"
#include "Set.Ch"
#include "SetCurs.Ch"
#include "TBrowse.Ch"

/***
*  Nation Message Constants
*  These constants are used with the NationMsg(<msg>) function.
*  The <msg> parameter can range from 1-12 and returns the national
*  version of the system message.
***/
#define _GET_INSERT_ON   7     // "Ins"
#define _GET_INSERT_OFF  8     // "   "
#define _GET_INVD_DATE   9     // "Invalid Date"
#define _GET_RANGE_FROM  10    // "Range: "
#define _GET_RANGE_TO    11    // " - "

#define K_UNDO          K_CTRL_U

// State variables for active READ
STATIC saStatics := { .F., , , , , , , , , , , , , , , ,} // Add 2 elements.
// System array format: 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7

// Static Get System array manifest contants used to preserve states:
#define SLUPDATED         1   // .F.
#define SBFORMAT          2   // .F.
#define SLKILLREAD        3   // .F.
#define SLBUMPTOP         4   // .F.
#define SLBUMPBOT         5   // .F.
#define SNLASTEXIT        6   //  0
#define SNLASTPOS         7   //  0
#define SOACTIVEGET       8   //
#define SXREADVAR         9   //
#define SCREADPROCNAME   10   //  ""
#define SNREADPROCLINE   11   //  0
#define SNNEXTGET        12   //  0
#define SNHITCODE        13   //  0
#define SNPOS            14   //  0
#define SCSCRSVMSG       15   //  0
#define SNMENUID         16   //  0  // Added.
#define SNSVCURSOR       17   //  0  // Added.

#define STATCOUNT        17          // Changed.

// Local message array manifest contants used to store message values:
#define MSGFLAG        1    //
#define MSGROW         2    //
#define MSGLEFT        3    //
#define MSGRIGHT       4    //
#define MSGCOLOR       5    //  0
#define MSGBACK1       6
#define MSGBACK2       7
#define MSGFORE        8
#define MSGFONTCOL     9
#define MSGFONTROW    10

/***
*
*  ReadModal( <GetList>, <nPos>, <oMenu>, <nMsgRow>, <nMsgLeft>, ;
*            <nMsgRight>, <cMsgColor> ) --> saStatics[ SLUPDATED ]
*
*
*  Standard modal READ on an array of GETs
*
***/
FUNCTION ReadModal( GetList, nPos, oMenu, nMsgRow, nMsgLeft, ;
					  nMsgRight, cMsgColor )

   LOCAL oGet, aMode, aMsg
   LOCAL aSavGetSysVars
   LOCAL cMsg := NIL
   LOCAL nSaveCursor

   IF ( VALTYPE( saStatics[ SBFORMAT ] ) == "B" )
      EVAL( saStatics[ SBFORMAT ] )
   ENDIF

   IF ( EMPTY( GetList ) )

      // S'87 compatibility
      SETPOS( MAXROW() - 1, 0 )
      RETURN (.F.)

   ENDIF

   nSaveCursor := SETCURSOR( SC_NONE )

   // Preserve state variables
   aSavGetSysVars := ClearGetSysVars()

   saStatics[ SNSVCURSOR ] := SETCURSOR( SC_NONE )  // Added.

   // Set these for use in SET KEYs
   saStatics[ SCREADPROCNAME ] := PROCNAME( 1 )
   saStatics[ SNREADPROCLINE ] := PROCLINE( 1 )

   aMsg := { , nMsgRow, nMsgLeft, nMsgRight, cMsgColor, , , , , }

   // Set initial GET to be read
   IF ( VALTYPE( nPos ) == "N" )
      saStatics[ SNPOS ] := Settle( GetList, nPos, .T. )
   ELSE
      saStatics[ SNPOS ] := Settle( GetList, 0, .T. )
   ENDIF

   IF ( aMsg[ MSGFLAG ] :=  ( VALTYPE( aMsg[ MSGROW ]   ) + ;
			      VALTYPE( aMsg[ MSGLEFT ]  ) + ;
			      VALTYPE( aMsg[ MSGRIGHT ] ) == "NNN" ) )

      IF !( VALTYPE( aMsg[ MSGCOLOR ] ) == "C" )
	 aMsg[ MSGCOLOR ] := GetClrPair( SetColor(), 1 )
      ENDIF

      @ aMsg[ MSGROW ], aMsg[ MSGLEFT ] CLEAR TO ;
	aMsg[ MSGROW ], aMsg[ MSGRIGHT ]

      // Graphics mode test: retrieve message colors and font positions:       
      IF _IsGraphics()
	 aMode := gMode()
	 aMsg[ MSGBACK1   ] := ;
		_GetNumColor( GetClrBack( GetClrPair( SetColor(), 1 ) ) )
	 aMsg[ MSGFORE    ] := ;
		_GetNumColor( GetClrFore( GetClrPair( aMsg[ MSGCOLOR ], 1 ) ) )
	 aMsg[ MSGBACK2   ] := ;
		_GetNumColor( GetClrBack( GetClrPair( aMsg[ MSGCOLOR ], 1 ) ) )
	 aMsg[ MSGFONTCOL ] := aMode[ LLG_MODE_FONT_COL ]
	 aMsg[ MSGFONTROW ] := aMode[ LLG_MODE_FONT_ROW ]
	 // Reset for next gMode() test:
	 aMode := NIL
	 gFrame( aMsg[ MSGLEFT ]     * aMsg[ MSGFONTCOL ] - 2, ;
		 aMsg[ MSGROW ]      * aMsg[ MSGFONTROW ] - 2, ;
		 aMsg[ MSGRIGHT ]    * aMsg[ MSGFONTCOL ] + 9, ;
	       ( aMsg[ MSGROW ] + 1) * aMsg[ MSGFONTROW ] + 1, ;
		 aMsg[ MSGBACK1 ],;
		 aMsg[ MSGBACK1 ], aMsg[ MSGBACK1 ], ;
		 2, 2, 2, 2, LLG_MODE_SET, LLG_FRAME )

      ENDIF

      saStatics[ SCSCRSVMSG ] := SaveScreen( aMsg[ MSGROW ], ;
	   aMsg[ MSGLEFT ], aMsg[ MSGROW ], aMsg[ MSGRIGHT ] )

   ENDIF

   saStatics[ SNNEXTGET ] := 0
   saStatics[ SNHITCODE ] := 0
   saStatics[ SNMENUID ]  := 0  // Added.

   WHILE !( saStatics[ SNPOS ] == 0 )

      oGet := GetList[ saStatics[ SNPOS ] ]
      // Get next GET from list and post it as the active GET
	 PostActiveGet( oGet )

      // Read the GET
      IF ( VALTYPE( oGet:reader ) == "B" )
	 // Use custom reader block
	 EVAL( oGet:reader, oGet, GetList, oMenu, aMsg )
      ELSE
	 GetReader( oGet, GetList, oMenu, aMsg ) // Use standard reader
      ENDIF

      // Move to next GET based on exit condition
      saStatics[ SNPOS ] := Settle( GetList, saStatics[ SNPOS ], .F. )

   ENDDO

   // Restore state variables
   RestoreGetSysVars( aSavGetSysVars )

   // S'87 compatibility
   SETPOS( MAXROW() - 1, 0 )

   SETCURSOR( saStatics[ SNSVCURSOR ] )  // Changed.

   RETURN ( saStatics[ SLUPDATED ] )


/***
*
*  GetReader( <oGet>, <GetList>, <oMenu>, <aMsg> )
*
*  Standard modal read of a single GET
*
***/
PROCEDURE GetReader( oGet, GetList, oMenu, aMsg )
   LOCAL nKey, nRow, nCol, nCursor

   // Read the GET if the WHEN condition is satisfied
   IF ( saStatics[ SNLASTEXIT ] == GE_SHORTCUT .OR. ;
	saStatics[ SNLASTEXIT ] == GE_MOUSEHIT .OR. ;
	GetPreValidate( oGet, aMsg ) )  // Added 2 previous lines.

      ShowGetMsg( oGet, aMsg )

      // Activate the GET for reading
      saStatics[ SNHITCODE ]  := 0
      saStatics[ SNLASTEXIT ] := 0
      oGet:setFocus()

      WHILE ( oGet:exitState == GE_NOEXIT .AND. !saStatics[ SLKILLREAD ] )

	 // Check for initial typeout (no editable positions)
	 IF ( oGet:typeOut )
	    oGet:exitState := GE_ENTER
	 ENDIF

	 // Apply keystrokes until exit
	 WHILE ( oGet:exitState == GE_NOEXIT .AND. !saStatics[ SLKILLREAD ] )
	    SETCURSOR( IIF( saStatics[ SNSVCURSOR ] == SC_NONE, ;
		 SC_NORMAL, saStatics[ SNSVCURSOR ] ) )  // Added IIF().
	    nKey := INKEY( 0 )
	    SETCURSOR( SC_NONE )
	    GetApplyKey( oGet, nKey, GetList, oMenu, aMsg )
	    nRow := ROW()
	    nCol := COL()
	    ShowGetMsg( oGet, aMsg )
	    DevPos( nRow, nCol )
	 ENDDO

	 // Disallow exit if the VALID condition is not satisfied
	 IF saStatics[ SNLASTEXIT ] == GE_SHORTCUT  // Added.
	 ELSEIF saStatics[ SNLASTEXIT ] == GE_MOUSEHIT  // Added.
	 ELSEIF ( !GetPostValidate( oGet, aMsg ) )
	    oGet:exitState := GE_NOEXIT
	 ENDIF

      ENDDO

      // De-activate the GET
      nRow    := ROW()        // Added.
      nCol    := COL()        // Added.
      nCursor := SETCURSOR()  // Added.
      oGet:killFocus()
      SETCURSOR( nCursor )    // Added.
      SETPOS( nRow, nCol )    // Added.

      EraseGetMsg( oGet, aMsg )

   ENDIF

   RETURN


/***
*
*  GUIReader( <oGet>, <GetList>, <oMenu>, <aMsg> )
*
*  Standard modal read of a single GUI-GET
*
***/
PROCEDURE GUIReader( oGet, GetList, oMenu, aMsg )
   LOCAL oGUI, nKey := 0, nRow, nCol

   // Read the GET if the WHEN condition is satisfied
   IF ( VALTYPE( oGet:Control ) == "O" ) .AND. ;  // Moved up 2 lines.
	saStatics[ SNLASTEXIT ] == GE_SHORTCUT .OR. ;  // Added.
	saStatics[ SNLASTEXIT ] == GE_MOUSEHIT .OR. ;  // Added.
	GetPreValidate( oGet, aMsg )
	// !GUIPreValidate( oGet, oGet:Control, aMsg ) )  // Old test.

      ShowGetMsg( oGet, aMsg )
      saStatics[ SNLASTEXIT ] := 0  // Added.

      // Activate the GET for reading
      oGUI := oGet:Control
      oGUI:Select( oGet:VarGet() )
      oGUI:setFocus()

      IF oGet:exitState == GE_NOEXIT  // Added.

	 IF ( saStatics[ SNHITCODE ] > 0 )
	    oGUI:Select( saStatics[ SNHITCODE ] )

	 ELSEIF ( saStatics[ SNHITCODE ] == HTCAPTION )
	    oGUI:Select()

	 ELSEIF ( saStatics[ SNHITCODE ] == HTCLIENT )
	    oGUI:Select( K_LBUTTONDOWN )

	 ELSEIF ( saStatics[ SNHITCODE ] == HTDROPBUTTON )
	    oGUI:Open()

	 ELSEIF ( ( saStatics[ SNHITCODE ] >= HTSCROLLFIRST ) .AND. ;
		  ( saStatics[ SNHITCODE ] <= HTSCROLLLAST ) )
	    oGUI:Scroll( saStatics[ SNHITCODE ] )
	 ENDIF

      ENDIF  // Added.

      saStatics[ SNHITCODE ] := 0

      WHILE ( oGet:exitState == GE_NOEXIT .AND. !saStatics[ SLKILLREAD ] )

	 // Check for initial typeout (no editable positions)
	 IF ( oGUI:typeOut )
	    oGet:exitState := GE_ENTER
	 ENDIF

	 // Apply keystrokes until exit
	 WHILE ( oGet:exitState == GE_NOEXIT .AND. !saStatics[ SLKILLREAD ] )
	    GUIApplyKey( oGet, oGUI, GetList, INKEY(0), oMenu, aMsg )
	    // nRow := ROW()  // Commented out: Moved.
	    // nCol := COL()  // Commented out: Moved.

	    ShowGetMsg( oGet, aMsg )
	    DevPos( nRow, nCol )
	 ENDDO

	 // Disallow exit if the VALID condition is not satisfied

	 IF     saStatics[ SNLASTEXIT ]  == GE_SHORTCUT  // Added.
	 ELSEIF saStatics[ SNLASTEXIT ] == GE_MOUSEHIT  // Added.
	 ELSEIF ( !GetPostValidate( oGet, aMsg ) )      // Changed.
	 // IF ( !GUIPostValidate( oGet, oGUI, aMsg ) ) // Old test.
	    oGet:exitState := GE_NOEXIT
	 ENDIF

      ENDDO

      // De-activate the GET         
      // NOTE: Need to test both RadioGroup & ListBox:
      IF ( ( oGUI:ClassName() $ "LISTBOX_RADIOGROUP" ) .AND. ;
	 VALTYPE( oGet:VarGet() ) == "N" )
	 // Need to test the Value here:
	 oGet:VarPut( oGUI:Value )
      ELSE
	 oGet:VarPut( oGUI:Buffer )
      ENDIF
      oGUI:killFocus()

      EraseGetMsg( oGet, aMsg )

      IF !( oGUI:ClassName() == "LISTBOX" )
      ELSEIF ( !oGUI:DropDown )
      ELSEIF ( oGUI:IsOpen )
	 oGUI:Close()
      ENDIF

   ENDIF

   RETURN


/***
*
*  TBrowseReader( <oGet>, <GetList>, <oMenu>, <aMsg> )
*
*  Standard modal READ of a single GET TBrowse
*
***/
PROCEDURE TBReader( oGet, GetList, oMenu, aMsg )
   LOCAL oTB, nKey, lAutoLite, nCell, nSaveCursor, nProcessed
   LOCAL nRow, nCol

   // Read the GET if the WHEN condition is satisfied
   IF ( VALTYPE( oGet:Control ) == "O" ) .AND. ;  // Moved up 2 lines.
	saStatics[ SNLASTEXIT ] == GE_SHORTCUT .OR. ;  // Added.
	saStatics[ SNLASTEXIT ] == GE_MOUSEHIT .OR. ;  // Added.
	GetPreValidate( oGet, aMsg )
	// !GUIPreValidate( oGet, oGet:Control, aMsg ) )  // Old test.

      ShowGetMsg( oGet, aMsg )
      saStatics[ SNLASTEXIT ] := 0  // Added.

      nSaveCursor := SetCursor( SC_NONE )

      // Activate the GET for reading
      oTB := oGet:Control

      lAutoLite := oTB:Autolite
      oTB:Autolite := .T.
      oTB:Hilite()

      IF oGet:exitState == GE_NOEXIT  // Added.
	 IF ( saStatics[ SNHITCODE ] == HTCELL )
	    // Replaces call to TBMouse( oTB, mROW(), mCOL() ):
	    oTB:RowPos := oTb:mRowPos
	    oTB:ColPos := oTb:mColPos
	    oTB:Invalidate()
	 ENDIF
      ENDIF  // Added.

      saStatics[ SNHITCODE ] := 0

      WHILE ( oGet:exitState == GE_NOEXIT .AND. !saStatics[ SLKILLREAD ] )

	 // Apply keystrokes until exit
	 WHILE ( oGet:exitState == GE_NOEXIT .AND. !saStatics[ SLKILLREAD ] )
	    nKey := 0

	    WHILE ( !( oTB:Stabilize() ) .AND. ( nKey == 0 ) )
	       nKey := INKEY()
	    ENDDO

	    IF ( nKey == 0 )
	       nKey := INKEY(0)
	    ENDIF

	    nProcessed := oTB:ApplyKey( nKey )
	    IF ( nProcessed == TBR_EXIT )
	       oGet:exitState := GE_ESCAPE
	       EXIT

	    ELSEIF ( nProcessed == TBR_EXCEPTION )
	       TBApplyKey( oGet, oTB, GetList, nKey, oMenu, aMsg )
	       // nRow := ROW()  // Commented out.
	       // nCol := COL()  // Commented out.
	       ShowGetMsg( oGet, aMsg )
	       // DevPos( nRow, nCol )  // Commented out.

	    ENDIF

	 ENDDO

	 // Disallow exit if the VALID condition is not satisfied
	 IF     saStatics[ SNLASTEXIT ]  == GE_SHORTCUT  // Added.
	 ELSEIF saStatics[ SNLASTEXIT ] == GE_MOUSEHIT  // Added.
	 ELSEIF ( !GetPostValidate( oGet, aMsg ) )      // Changed.
	 // IF ( !GUIPostValidate( oGet, oGUI, aMsg ) ) // Old test.
	    oGet:exitState := GE_NOEXIT
	 ENDIF

      ENDDO

      // De-activate the GET
      oTB:Autolite := lAutoLite
      oTB:DeHilite()

      EraseGetMsg( oGet, aMsg )

      SetCursor( nSaveCursor )
   ENDIF

   RETURN


/***
*
*  HitTest( <GetList>, <MouseRow>, <MouseCol>, <aMsg> ) --> ;
*            saStatics[ SNNEXTGET ] != 0
*
*  Test Getlist position and mouse coordinates
*
***/
FUNCTION HitTest( GetList, MouseRow, MouseCol, aMsg ) // Removed STATIC
   LOCAL nCount, nTotal, lGUI

   saStatics[ SNNEXTGET ] := 0
   nTotal  := LEN( GetList )

   FOR nCount := 1 TO nTotal
      IF ( ( saStatics[ SNHITCODE ] := ;
	 GetList[ nCount ]:HitTest( MouseRow, MouseCol ) ) != HTNOWHERE )
	 saStatics[ SNNEXTGET ] := nCount
	 EXIT
      ENDIF
   NEXT

   // DO WHILE !( saStatics[ SNNEXTGET ] == 0 )  // Commented out.
   IF !( saStatics[ SNNEXTGET ] == 0 )  // Changed.
      // Test the current GUI-GET or Get PostValidation:
      lGUI := ( VALTYPE( Getlist[ saStatics[ SNPOS ] ]:Control ) == "O" )
      IF lGUI .AND. !( GUIPostValidate( GetList[ saStatics[ SNPOS ] ], ;
		GetList[ saStatics[ SNPOS ] ]:Control, aMsg  ) )
	 saStatics[ SNNEXTGET ] := 0
	 // EXIT  // Commented out.
	 RETURN 0  // Changed.
      ELSEIF !lGUI .AND. !( GetPostValidate( GetList[ saStatics[ SNPOS ] ], ;
	 aMsg ) )
	 saStatics[ SNNEXTGET ] := 0
	 // EXIT  // Commented out.
	 RETURN 0  // Changed.
      ENDIF
      
      // Test the next GUI-GET or Get PreValidation:
      lGUI := ( VALTYPE( Getlist[ saStatics[ SNNEXTGET ] ]:Control ) == "O" )
      IF lGUI .AND. !( GUIPreValidate( GetList[ saStatics[ SNNEXTGET ] ], ;
		GetList[ saStatics[ SNNEXTGET ] ]:Control, aMsg  ) )
	 saStatics[ SNNEXTGET ] := 0
	 // EXIT  // Commented out.
	 RETURN saStatics[ SNNEXTGET ]  // Changed.
      ELSEIF !lGUI .AND. !( GetPreValidate( GetList[ saStatics[ SNNEXTGET ] ], ;
	 aMsg ) )
	 saStatics[ SNNEXTGET ] := 0
	 // EXIT  // Commented out.
	 RETURN saStatics[ SNNEXTGET ]  // Changed.
      ENDIF
      // EXIT  // Commented out.
      RETURN saStatics[ SNNEXTGET ]  // Changed.
   // ENDDO  // Commented out.
   ENDIF  // Changed.

   // RETURN ( saStatics[ SNNEXTGET ] != 0 )  // Commented out.
   RETURN 0  // Changed.

/***
*
*  Accelerator( <GetList>, <nKey>, <aMsg> ) --> 0
*
*  Identify the Accelerator key 
*
***/
FUNCTION Accelerator( GetList, nKey, aMsg ) // Removed STATIC
   LOCAL nGet, oGet, nHotPos, cKey, cCaption, nStart, nEnd
   LOCAL nIteration, lGUI

      IF ( ( nKey >= K_ALT_Q ) .AND. ( nKey <= K_ALT_P ) )
	 cKey := SUBSTR( "qwertyuiop", nKey - K_ALT_Q + 1, 1 )

      ELSEIF ( ( nKey >= K_ALT_A ) .AND. ( nKey <= K_ALT_L ) )
	 cKey := SUBSTR( "asdfghjkl", nKey - K_ALT_A + 1, 1 )

      ELSEIF ( ( nKey >= K_ALT_Z ) .AND. ( nKey <= K_ALT_M ) )
	 cKey := SUBSTR( "zxcvbnm", nKey - K_ALT_Z + 1, 1 )

      ELSEIF ( ( nKey >= K_ALT_1 ) .AND. ( nKey <= K_ALT_0 ) )
	 cKey := SUBSTR( "1234567890", nKey - K_ALT_1 + 1, 1 )

      ELSE
	 RETURN ( 0 )

      ENDIF

      nStart := saStatics[ SNPOS ] + 1
      nEnd   := LEN( GetList )

      FOR nIteration := 1 TO 2
	 FOR nGet := nStart TO nEnd
	    oGet  := GetList[ nGet ]

	    IF ( VALTYPE( oGet:Control ) == "O" .AND. ;
			  oGet:Control:ClassName() != "TBROWSE" )
	       cCaption := oGet:Control:Caption
	    ELSE
	       cCaption := oGet:Caption
	    ENDIF

	    IF ( ( nHotPos := AT( "&", cCaption ) ) == 0 )
	    ELSEIF ( nHotPos == LEN( cCaption ) )
	    ELSEIF ( LOWER( SUBSTR( cCaption, nHotPos + 1, 1 ) ) == cKey )

      // Test the current GUI-GET or Get PostValidation:
      lGUI := ( VALTYPE( Getlist[ saStatics[ SNPOS ] ]:Control ) == "O" )
      IF lGUI .AND. !( GUIPostValidate( GetList[ saStatics[ SNPOS ] ], ;
		GetList[ saStatics[ SNPOS ] ]:Control, aMsg  ) )
	 RETURN 0
      ELSEIF !lGUI .AND. !( GetPostValidate( GetList[ saStatics[ SNPOS ] ], ;
	 aMsg ) )
	 RETURN 0
      ENDIF
      
      // Test the next GUI-GET or Get PreValidation:
      lGUI := ( VALTYPE( oGet:Control ) == "O" )
      IF lGUI .AND. !( GUIPreValidate( oGet, oGet:Control, aMsg  ) )
	 // RETURN 0  // Commented out.
	 RETURN nGet  // Changed.
      ELSEIF !lGUI .AND. !( GetPreValidate( oGet, aMsg ) )
	 // RETURN 0  // Commented out.
	 RETURN nGet  // Changed.
      ENDIF

	       RETURN ( nGet )
	    ENDIF
	 NEXT

	 nStart := 1
	 nEnd   := saStatics[ SNPOS ] - 1

      NEXT

   RETURN ( 0 )


/***
*
*  GetApplyKey( <oGet>, <nKey>, <GetList>, <oMenu>, <aMsg> )
*
*  Apply a single INKEY() keystroke to a GET
*
*  NOTE: The GET Object must have focus.
*
***/
PROCEDURE GetApplyKey( oGet, nKey, GetList, oMenu, aMsg )

   LOCAL cKey
   LOCAL bKeyBlock
   LOCAL MouseRow, MouseColumn
   LOCAL nButton
   LOCAL nHotItem
   LOCAL lSetKey

   // Check for SET KEY first
   IF !( ( bKeyBlock := SETKEY( nKey ) ) == NIL )
      IF ( lSetKey := GetDoSetKey( bKeyBlock, oGet ) )
	 RETURN
      ENDIF
   ENDIF

   IF ( !( GetList == NIL ) .AND. ;
	( ( nHotItem := Accelerator( GetList, nKey, aMsg ) ) != 0 ) )
      oGet:ExitState := GE_SHORTCUT
      saStatics[ SNNEXTGET ]  := nHotItem
      saStatics[ SNLASTEXIT ] := GE_SHORTCUT  // Added.

   ELSEIF ( !( VALTYPE( oMenu ) == "O" ) )
   ELSEIF ( ( nHotItem := oMenu:GetAccel( nKey ) ) != 0 )
      saStatics[ SNMENUID ] := MenuModal( oMenu, nHotItem, ;  // Changed.
      aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGRIGHT ], aMsg[ MSGCOLOR ] )
      nKey := 0

   ELSEIF ( IsShortCut( oMenu, nKey )  )
      nKey := 0

   ENDIF

   DO CASE
   CASE( nKey == K_UP )
      oGet:exitState := GE_UP

   CASE( nKey == K_SH_TAB )
      oGet:exitState := GE_UP

   CASE( nKey == K_DOWN )
      oGet:exitState := GE_DOWN

   CASE( nKey == K_TAB )
      oGet:exitState := GE_DOWN

   CASE( nKey == K_ENTER )
      oGet:exitState := GE_ENTER

   CASE( nKey == K_ESC )
      IF ( SET( _SET_ESCAPE ) )
	 oGet:Undo()
	 oGet:exitState := GE_ESCAPE
      ENDIF

   CASE( nKey == K_PGUP )
      oGet:exitState := GE_WRITE

   CASE( nKey == K_PGDN )
      oGet:exitState := GE_WRITE

   CASE( nKey == K_CTRL_HOME )
      oGet:exitState := GE_TOP

#ifdef CTRL_END_SPECIAL

   // Both ^W and ^End go to the last GET
   CASE( nKey == K_CTRL_END )
      oGet:exitState := GE_BOTTOM

#else

   // Both ^W and ^End terminate the READ (the default)
   CASE( nKey == K_CTRL_W )
      oGet:exitState := GE_WRITE

#endif
   CASE( ( nKey == K_LBUTTONDOWN ) .OR. ( nKey == K_LDBLCLK ) )
      MouseRow    := mROW()
      MouseColumn := mCOL()

      IF ( !( VALTYPE( oMenu ) == "O" ) )
	 nButton := 0

      ELSEIF ( !( oMenu:ClassName() == "TOPBARMENU" ) )
	 nButton := 0

      ELSEIF ( ( nButton := oMenu:HitTest( MouseRow, MouseColumn ) ) != 0 )
	 saStatics[ SNMENUID ] := MenuModal( oMenu, nHotItem, ;  // Changed.
	 aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGRIGHT ], aMsg[ MSGCOLOR ] )
	 nButton := 1

      ENDIF

      IF ( nButton != 0 )

      ELSEIF ( ( nButton := ;
	 oGet:HitTest( MouseRow, MouseColumn ) ) == HTCLIENT )

	 DO WHILE ( oGet:Col + oGet:Pos - 1 > MouseColumn )
	    oGet:Left()

	    // Handle editing buffer if first character is non-editable:
	    IF oGet:typeOut
	       // reset typeout:
	       oGet:Home()
	       EXIT
	    ENDIF

	 ENDDO

	 DO WHILE ( oGet:Col + oGet:Pos - 1 < MouseColumn )
	    oGet:Right()

	    // Handle editing buffer if last character is non-editable:
	    IF oGet:typeOut
	       // reset typeout:
	       oGet:End()
	       EXIT
	    ENDIF

	 ENDDO

      ELSEIF !( nButton == HTNOWHERE )
      ELSEIF ( !( GetList == NIL ) .AND. ;
	 HitTest( GetList, MouseRow, MouseColumn, aMsg ) != 0 )  // Changed.
	 oGet:exitstate := GE_MOUSEHIT
	 saStatics[ SNLASTEXIT ] := GE_MOUSEHIT  // Added.
      ELSE
	 oGet:exitstate := GE_NOEXIT
      ENDIF

   CASE( nKey == K_UNDO )
      oGet:Undo()

   CASE( nKey == K_HOME )
      oGet:Home()

   CASE( nKey == K_END )
      oGet:End()

   CASE( nKey == K_RIGHT )
      oGet:Right()

   CASE( nKey == K_LEFT )
      oGet:Left()

   CASE( nKey == K_CTRL_RIGHT )
      oGet:wordRight()

   CASE( nKey == K_CTRL_LEFT )
      oGet:wordLeft()

   CASE( nKey == K_BS )
      oGet:BackSpace()

   CASE( nKey == K_DEL )
      oGet:Delete()

   CASE( nKey == K_CTRL_T )
      oGet:delWordRight()

   CASE( nKey == K_CTRL_Y )
      oGet:delEnd()

   CASE( nKey == K_CTRL_BS )
      oGet:delWordLeft()

   CASE( nKey == K_INS )
      SET( _SET_INSERT, !SET( _SET_INSERT ) )
      ShowScoreboard()

   OTHERWISE

      IF ( nKey >= 32 .AND. nKey <= 255 )

	 cKey := CHR( nKey )

	 IF ( oGet:type == "N" .AND. ( cKey == "." .OR. cKey == "," ) )
	    oGet:toDecPos()
	 ELSE

	    IF ( SET( _SET_INSERT ) )
	       oGet:Insert( cKey )
	    ELSE
	       oGet:OverStrike( cKey )
	    ENDIF

	    IF ( oGet:typeOut )
	       IF ( SET( _SET_BELL ) )
		  ?? CHR(7)
	       ENDIF

	       IF ( !SET( _SET_CONFIRM ) )
		  oGet:exitState := GE_ENTER
	       ENDIF
	    ENDIF

	 ENDIF

      ENDIF

   ENDCASE

   RETURN


/***
*
*  GUIApplyKey( <oGet>, <oGUI>, <GetList>, <nKey>, <oMenu>, <aMsg> )
*
*  Apply a single INKEY() keystroke to a GET
*
*  NOTE: GET and GUI must have focus.
*
***/
PROCEDURE GUIApplyKey( oGet, oGUI, GetList, nKey, oMenu, aMsg )

   LOCAL cKey
   LOCAL bKeyBlock
   LOCAL MouseRow, MouseColumn
   LOCAL nButton
   LOCAL TheClass
   LOCAL nHotItem
   LOCAL lClose
   LOCAL lSetKey

   // Check for SET KEY first
   IF ( !( bKeyBlock := SETKEY( nKey ) ) == NIL )
      IF ( lSetKey := GetDoSetKey( bKeyBlock, oGet ) )
	 RETURN
      ENDIF
   ENDIF

   IF ( ( nHotItem := Accelerator( GetList, nKey, aMsg ) ) != 0 )
      oGet:ExitState := GE_SHORTCUT
      saStatics[ SNNEXTGET ] := nHotItem

   ELSEIF ( !( VALTYPE( oMenu ) == "O" ) )
   ELSEIF ( ( nHotItem := oMenu:GetAccel( nKey ) ) != 0 )
      saStatics[ SNMENUID ] := MenuModal( oMenu, nHotItem, ;  // Changed.
      aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGRIGHT ], aMsg[ MSGCOLOR ] )
      nKey := 0

   ELSEIF ( IsShortCut( oMenu, nKey )  )
      nKey := 0

   ENDIF

   IF ( nKey == 0 )
   ELSEIF ( ( TheClass := oGUI:ClassName() ) == "RADIOGROUP" )
      IF ( nKey == K_UP )
	 oGUI:PrevItem()
	 nKey := 0

      ELSEIF ( nKey == K_DOWN )
	 oGUI:NextItem()
	 nKey := 0

      ELSEIF ( ( nHotItem := oGUI:GetAccel( nKey ) ) != 0 )
	 oGUI:Select( nHotItem )

      ENDIF

      IF VALTYPE( oGet:VarGet() ) == "N"
	 oGet:VarPut( oGui:Value )
      ENDIF

   ELSEIF ( TheClass == "CHECKBOX" )
      IF ( nKey == K_SPACE )
	 oGUI:Select()
      ENDIF

   ELSEIF ( TheClass == "PUSHBUTTON" )
      IF ( nKey == K_SPACE )
	 oGUI:Select( K_SPACE )

      ELSEIF ( nKey == K_ENTER )
	 oGUI:Select()
	 nKey := 0
      ENDIF

   ELSEIF ( TheClass == "LISTBOX" )
      IF ( nKey == K_UP )
	 oGUI:PrevItem()
	 nKey := 0

      ELSEIF ( nKey == K_DOWN )
	 oGUI:NextItem()
	 nKey := 0

      ELSEIF ( nKey == K_SPACE )
	 IF ( !oGUI:DropDown )
	 ELSEIF ( !oGUI:IsOpen )
	    oGUI:Open()
	    nKey := 0
	 ENDIF

      ELSEIF ( ( nButton := oGUI:FindText( CHR( nKey ), oGUI:Value + 1, ;
					   .F., .F. ) ) != 0 )
	 oGUI:Select( nButton )

      ENDIF
      // Test for 0 entry scenario:
      IF VALTYPE( oGet:VarGet() ) == "N"
	 oGet:VarPut( oGui:Value )
      ENDIF

   ENDIF

   DO CASE
   CASE( nKey == K_UP )
      oGet:exitState := GE_UP

   CASE( nKey == K_SH_TAB )
      oGet:exitState := GE_UP

   CASE( nKey == K_DOWN )
      oGet:exitState := GE_DOWN

   CASE( nKey == K_TAB )
      oGet:exitState := GE_DOWN

   CASE( nKey == K_ENTER )
      oGet:exitState := GE_ENTER

   CASE( nKey == K_ESC )
      IF ( SET( _SET_ESCAPE ) )
	 oGet:exitState := GE_ESCAPE
      ENDIF

   CASE( nKey == K_PGUP )
      oGet:exitState := GE_WRITE

   CASE( nKey == K_PGDN )
      oGet:exitState := GE_WRITE

   CASE( nKey == K_CTRL_HOME )
      oGet:exitState := GE_TOP

#ifdef CTRL_END_SPECIAL

   // Both ^W and ^End go to the last GET
   CASE( nKey == K_CTRL_END )
      oGet:exitState := GE_BOTTOM

#else

   // Both ^W and ^End terminate the READ (the default)
   CASE( nKey == K_CTRL_W )
      oGet:exitState := GE_WRITE

#endif
   CASE( ( nKey == K_LBUTTONDOWN ) .OR. ( nKey == K_LDBLCLK ) )
      MouseRow    := mROW()
      MouseColumn := mCOL()

      IF ( !( VALTYPE( oMenu ) == "O" ) )
	 nButton := 0

      ELSEIF ( !( oMenu:ClassName() == "TOPBARMENU" ) )
	 nButton := 0

      ELSEIF ( ( nButton := oMenu:HitTest( MouseRow, MouseColumn ) ) != 0 )
	 saStatics[ SNMENUID ] := MenuModal( oMenu, nHotItem, ;  // Changed.
	 aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGRIGHT ], aMsg[ MSGCOLOR ] )
	 nButton := 1

      ENDIF

      lClose := .T.

      IF ( nButton != 0 )
      ELSEIF ( ( nButton := ;
	 oGUI:HitTest( MouseRow, MouseColumn ) ) == HTNOWHERE )
	 // Changed test:
	 IF ( HitTest( GetList, MouseRow, MouseColumn, aMsg ) != 0 )
	    oGet:exitstate := GE_MOUSEHIT
	    saStatics[ SNLASTEXIT ] := GE_MOUSEHIT  // Added.
	 ELSE
	    oGet:exitstate := GE_NOEXIT
	 ENDIF

      ELSEIF ( nButton >= HTCLIENT )
	 oGUI:Select( nButton )

      ELSEIF ( nButton == HTDROPBUTTON )
	 IF ( !oGUI:IsOpen )
	    oGUI:Open()
	    lClose := .F.

	 ENDIF

      ELSEIF ( ( nButton >= HTSCROLLFIRST ) .AND. ;
	       ( nButton <= HTSCROLLLAST ) )
	 oGUI:Scroll( nButton )
	 lClose := .F.

      ENDIF

      IF ( !lClose )
      ELSEIF !( TheClass == "LISTBOX" )
      ELSEIF ( !oGUI:DropDown )
      ELSEIF ( oGUI:IsOpen )
	 oGUI:Close()
	 oGUI:Display()
      ENDIF

   ENDCASE

   RETURN


/***
*
*  TBApplyKey( <oGet>, <oTB>, <GetList>, <nKey>, <oMenu>, <aMsg> )
*
*  Default handler for Applying a single INKEY() keystroke to a TBrowse.
*
*  NOTE: GET and tBrowse ought to have focus.
*
***/
PROCEDURE TBApplyKey( oGet, oTB, GetList, nKey, oMenu, aMsg )

   LOCAL cKey
   LOCAL bKeyBlock
   LOCAL MouseRow, MouseColumn
   LOCAL nButton
   LOCAL nHotItem
   LOCAL lSetKey

   // Check for SET KEY first
   IF !( ( bKeyBlock := SETKEY( nKey ) ) == NIL )
      IF ( lSetKey := GetDoSetKey( bKeyBlock, oGet ) )
	 RETURN
      ENDIF
   ENDIF

   IF ( ( nHotItem := Accelerator( GetList, nKey, aMsg ) ) != 0 )
      oGet:ExitState := GE_SHORTCUT
      saStatics[ SNNEXTGET ] := nHotItem

   ELSEIF ( !( VALTYPE( oMenu ) == "O" ) )
   ELSEIF ( ( nHotItem := oMenu:GetAccel( nKey ) ) != 0 )
      saStatics[ SNMENUID ] := MenuModal( oMenu, nHotItem, ;  // Changed.
      aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGRIGHT ], aMsg[ MSGCOLOR ] )
      nKey := 0

   ELSEIF ( IsShortCut( oMenu, nKey )  )
      nKey := 0

   ENDIF

   DO CASE
   CASE( nKey == K_TAB )
      oGet:exitState := GE_DOWN

   CASE( nKey == K_SH_TAB )
      oGet:exitState := GE_UP

   CASE( nKey == K_ENTER )

      // Special stanza for GDBU.EXE:
      IF UPPER( oGet:Name ) == UPPER( "cFlist" )
         EVAL( { || TBSelect( Getlist, 1 ) } )
      ELSE
         EVAL( { || TBSelect( Getlist, 2 ) } )
      ENDIF
      // Added for GDBU.EXE:
      IF !oTb:Stable()
         oTb:ForceStable()
      ENDIF

      oGet:exitState := GE_ENTER

   CASE( nKey == K_ESC )
      IF ( SET( _SET_ESCAPE ) )
	 oGet:exitState := GE_ESCAPE
      ENDIF

#ifdef CTRL_END_SPECIAL

   // Both ^W and ^End go to the last GET
   CASE( nKey == K_CTRL_END )
      oGet:exitState := GE_BOTTOM

#else

   // Both ^W and ^End terminate the READ (the default)
   CASE( nKey == K_CTRL_W )
      oGet:exitState := GE_WRITE

#endif
   CASE( ( nKey == K_LBUTTONDOWN ) .OR. ( nKey == K_LDBLCLK ) )
      MouseRow    := mROW()
      MouseColumn := mCOL()

      // Special stanza for GDBU.EXE:
      IF UPPER( oGet:Name ) == UPPER( "cFlist" ) .AND. nKey == K_LDBLCLK
         EVAL( {|| TBSelect( Getlist, 1 ) } )
      ELSEIF UPPER( oGet:Name ) == UPPER( "cDirec" )
         EVAL( { || TBSelect( Getlist, 2 ) } )
      ENDIF

      IF ( !( VALTYPE( oMenu ) == "O" ) )
	 nButton := 0

      ELSEIF ( !( oMenu:ClassName() == "TOPBARMENU" ) )
	 nButton := 0

      ELSEIF ( ( nButton := oMenu:HitTest( MouseRow, MouseColumn ) ) != 0 )
	 saStatics[ SNMENUID ] := MenuModal( oMenu, nHotItem, ;  // Changed.
	 aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGRIGHT ], aMsg[ MSGCOLOR ] )
	 nButton := 1

      ENDIF

      IF ( nButton != 0 )
      ELSEIF ( ( nButton := ;
	 oTB:HitTest( MouseRow, MouseColumn ) ) == HTNOWHERE )
	 // Changed test:
	 IF ( HitTest( GetList, MouseRow, MouseColumn, aMsg ) != 0 )
	    oGet:exitstate := GE_MOUSEHIT
	    saStatics[ SNLASTEXIT ] := GE_MOUSEHIT  // Added.
	 ELSE
	    oGet:exitstate := GE_NOEXIT
	 ENDIF
      ENDIF
   ENDCASE

   RETURN


/***
*
*  GetPreValidate( <oGet>, <aMsg> ) --> lWhen
*
*  Test entry condition (WHEN clause) for a GET
*
***/
FUNCTION GetPreValidate( oGet, aMsg )

   LOCAL lSavUpdated
   LOCAL lWhen := .T.

   IF !( oGet:preBlock == NIL )

      lSavUpdated := saStatics[ SLUPDATED ]

      lWhen := EVAL( oGet:preBlock, oGet, aMsg )
      IF !( VALTYPE( oGet:Control ) == "O" ) .AND. !lWhen  // Changed/added.
	 oGet:Display()
      ENDIF

      ShowScoreBoard()
      saStatics[ SLUPDATED ] := lSavUpdated

   ENDIF

   IF ( saStatics[ SLKILLREAD ] )

      lWhen := .F.
      oGet:exitState := GE_ESCAPE       // Provokes ReadModal() exit

   ELSEIF ( !lWhen )

      oGet:exitState := GE_WHEN         // Indicates failure

   ELSE

      oGet:exitState := GE_NOEXIT       // Prepares for editing

   ENDIF

   RETURN ( lWhen )


/***
*
*  GetPostValidate( <oGet>, <aMsg> ) --> lValid
*
*  Test exit condition (VALID clause) for a GET
*
*  NOTE: Bad dates are rejected in such a way as to preserve edit buffer
*
***/
FUNCTION GetPostValidate( oGet, aMsg )

   LOCAL lSavUpdated
   LOCAL lValid := .T.
   LOCAL nCursor  // Added.

   IF ( oGet:exitState == GE_ESCAPE )
      RETURN ( .T. )
   ENDIF

   IF ( oGet:badDate() )
      oGet:Home()
      DateMsg()
      ShowScoreboard()
      RETURN ( .F. )
   ENDIF

   // If editing occurred, assign the new value to the variable
   IF ( oGet:changed )
      oGet:assign()
      saStatics[ SLUPDATED ] := .T.
   ENDIF

   // Reform edit buffer, set cursor to home position, redisplay
   nCursor := SETCURSOR()  // Added.
   oGet:reset()
   SETCURSOR( nCursor )  // Added.

   // Check VALID condition if specified
   IF !( oGet:postBlock == NIL )

      lSavUpdated := saStatics[ SLUPDATED ]

      // S'87 compatibility
      IF VALTYPE( oGet:Buffer ) == "C"
	 SETPOS( oGet:row, oGet:Col + LEN( oGet:Buffer ) )
      ENDIF

      lValid := EVAL( oGet:postBlock, oGet, aMsg )

      // Reset S'87 compatibility cursor position
      SETPOS( oGet:row, oGet:Col )

      ShowScoreBoard()
      oGet:updateBuffer()

      saStatics[ SLUPDATED ] := IIF( oGet:changed, .T., lSavUpdated )

      IF ( saStatics[ SLKILLREAD ] )
	 oGet:exitState := GE_ESCAPE      // Provokes ReadModal() exit
	 lValid := .T.

      ENDIF
   ENDIF

   RETURN ( lValid )


/***
*
*  GUIPreValidate( <oGet>, <oGUI>, <aMsg> ) --> lWhen
*
*  Test entry condition (WHEN clause) for a GET:GUI
*
***/
FUNCTION GUIPreValidate( oGet, oGUI, aMsg )

   LOCAL lSavUpdated
   LOCAL lWhen := .T.

   IF !( oGet:preBlock == NIL )
      lSavUpdated := saStatics[ SLUPDATED ]

      lWhen := EVAL( oGet:preBlock, oGet, aMsg )

      IF ( !( oGUI:ClassName() == "TBROWSE" ) )
	 oGUI:Display()
      ENDIF

      ShowScoreBoard()
      saStatics[ SLUPDATED ] := lSavUpdated
 
   ENDIF

   IF ( saStatics[ SLKILLREAD ] )

      lWhen := .F.
      oGet:exitState := GE_ESCAPE

   ELSEIF ( !lWhen )

      oGet:exitState := GE_WHEN

   ELSE

      oGet:exitState := GE_NOEXIT

   ENDIF

   RETURN ( lWhen )


/***
*
*  GUIPostValidate( <oGet>, <oGUI>, <aMsg> ) --> lValid
*
*  Test exit condition (VALID clause) for a GET:GUI
*
***/
FUNCTION GUIPostValidate( oGet, oGUI, aMsg )

   LOCAL lSavUpdated
   LOCAL lValid := .T.
   LOCAL uOldData, uNewData

   IF ( oGet:exitState == GE_ESCAPE )
      RETURN ( .T. )
   ENDIF

   IF ( !( oGUI:ClassName() == "TBROWSE" ) )
      uOldData := oGet:VarGet()

      IF ( oGUI:ClassName() $ "LISTBOX_RADIOGROUP" .AND. ;
	 VALTYPE( oGet:VarGet() ) == "N" )
	 uNewData := oGUI:Value
      ELSE
	 uNewData := oGUI:Buffer
      ENDIF

   ENDIF

   // If editing occurred, assign the new value to the variable
   IF ( !( uOldData == uNewData ) )
      oGet:VarPut( uNewData )
      saStatics[ SLUPDATED ] := .T.
   ENDIF

   // Check VALID condition if specified
   IF !( oGet:postBlock == NIL )
      lSavUpdated := saStatics[ SLUPDATED ]
      lValid := EVAL( oGet:postBlock, oGet, aMsg )

      // Reset S'87 compatibility cursor position
      SETPOS( oGet:row, oGet:Col )

      ShowScoreBoard()
      IF ( !( oGUI:ClassName() == "TBROWSE" ) )
	 oGUI:Select( oGet:VarGet() )
      ENDIF

      saStatics[ SLUPDATED ] := IIF( oGet:changed, .T., lSavUpdated )

      IF ( saStatics[ SLKILLREAD ] )
	 oGet:exitState := GE_ESCAPE      // Provokes ReadModal() exit
	 lValid := .T.
      ENDIF

   ENDIF

   RETURN ( lValid )


/***
*
*  GetDoSetKey( <keyBlock>, <oGet> ) --> lSetKey
*
*  Process SET KEY during editing
*
***/
FUNCTION GetDoSetKey( keyBlock, oGet )

   LOCAL lSavUpdated, lSetKey

   // If editing has occurred, assign variable
   IF ( oGet:changed )
      oGet:assign()
      saStatics[ SLUPDATED ] := .T.
   ENDIF

   lSavUpdated := saStatics[ SLUPDATED ]

   lSetKey := EVAL( keyBlock, saStatics[ SCREADPROCNAME ], ;
			      saStatics[ SNREADPROCLINE ], ReadVar() )

   IF ( !( VALTYPE( lSetKey ) == "L" ) )
      lSetKey := .T.              // Will cause Return from ApplyKey()
   ENDIF

   ShowScoreboard()
   oGet:updateBuffer()

   saStatics[ SLUPDATED ] := lSavUpdated

   IF ( saStatics[ SLKILLREAD ] )
      oGet:exitState := GE_ESCAPE      // provokes ReadModal() exit
   ENDIF

   RETURN lSetKey


/***
*              READ services
***/

/***
*
*  Settle( <GetList>, <nPos>, <lInit> ) --> nPos
*
*  Returns new position in array of Get objects, based on:
*     - current position
*     - exitState of Get object at current position
*
*  NOTES: return value of 0 indicates termination of READ
*         exitState of old Get is transferred to new Get
*
***/
STATIC FUNCTION Settle( GetList, nPos, lInit )

   LOCAL nExitState

   IF ( nPos == 0 )
      nExitState := GE_DOWN
   ELSEIF ( nPos > 0 .AND. lInit)
      nExitState := GE_NOEXIT
   ELSE
      nExitState := GetList[ nPos ]:exitState
   ENDIF

   IF ( nExitState == GE_ESCAPE .OR. nExitState == GE_WRITE )
      RETURN ( 0 )
   ENDIF

   IF !( nExitState == GE_WHEN )
      // Reset state info
      saStatics[ SNLASTPOS ] := nPos
      saStatics[ SLBUMPTOP ] := .F.
      saStatics[ SLBUMPBOT ] := .F.
   ELSE
      // Re-use last exitState, do not disturb state info:
      // Commented out IIF() test:
      // nExitState := IIF( saStatics[ SNLASTEXIT ] == 0, GE_DOWN, ;
      //                    saStatics[ SNLASTEXIT ] )
      // Added following stanza:
      IF saStatics[ SNLASTEXIT ] != 0
	 nExitState := saStatics[ SNLASTEXIT ]
      ELSEIF saStatics[ SNNEXTGET ] < saStatics[ SNLASTPOS ] 
	 nExitState := GE_UP
      ELSE
	 nExitState := GE_DOWN
      ENDIF

   ENDIF

   // Movement through GETs

   DO CASE
   CASE( nExitState == GE_UP )
      nPos--

   CASE( nExitState == GE_DOWN )
      nPos++

   CASE( nExitState == GE_TOP )
      nPos       := 1
      saStatics[ SLBUMPTOP ]  := .T.
      nExitState := GE_DOWN

   CASE( nExitState == GE_BOTTOM )
      nPos       := LEN( GetList )
      saStatics[ SLBUMPBOT ]  := .T.
      nExitState := GE_UP

   CASE( nExitState == GE_ENTER )
      nPos++

   CASE( nExitState == GE_SHORTCUT )
      RETURN ( saStatics[ SNNEXTGET ] )

   CASE( nExitState == GE_MOUSEHIT )
      RETURN ( saStatics[ SNNEXTGET ] )

   ENDCASE

   // Bounce against first or last GET

   IF ( nPos == 0 )                       // Bumped top
      IF ( !( ReadExit() ) .AND. !saStatics[ SLBUMPBOT ] )
	 saStatics[ SLBUMPTOP ]  := .T.
	 nPos       := saStatics[ SNLASTPOS ]
	 nExitState := GE_DOWN
      ENDIF

   ELSEIF ( nPos == len( GetList ) + 1 )  // Bumped bottom
      IF ( !( ReadExit() ) .AND. !( nExitState == GE_ENTER ) .AND. ;
	   !saStatics[ SLBUMPTOP ] )
	 saStatics[ SLBUMPBOT ]  := .T.
	 nPos       := saStatics[ SNLASTPOS ]
	 nExitState := GE_UP
      ELSE
	 nPos := 0
      ENDIF

   ENDIF

   // Record exit state
   saStatics[ SNLASTEXIT ] := nExitState

   IF !( nPos == 0 )
      GetList[ nPos ]:exitState := nExitState
   ENDIF

   RETURN ( nPos )


/***
*
*  PostActiveGet( <oGet> )
*
*  Post active GET for ReadVar(), GetActive()
*
***/
STATIC PROCEDURE PostActiveGet( oGet )

   GetActive( oGet )
   ReadVar( GetReadVar( oGet ) )

   ShowScoreBoard()

   RETURN


/***
*
*  ClearGetSysVars() --> aSavSysVars
*
*  Save and clear READ state variables. Return array of saved values
*
*  NOTE: 'Updated' status is cleared but not saved (S'87 compatibility)
*
***/
STATIC FUNCTION ClearGetSysVars()

   // Save current sys vars
   LOCAL aSavSysVars          := ACLONE( saStatics )
   aSavSysVars[ SLUPDATED ]   := .F.
   aSavSysVars[ SXREADVAR ]   := READVAR( "" )  // Added.
   aSavSysVars[ SOACTIVEGET ] := GETACTIVE( NIL )  // Added.

   // Re-init old ones
   saStatics[ SLUPDATED ]       := .F.
   saStatics[ SBFORMAT   ]      := NIL
   saStatics[ SLKILLREAD ]      := .F.
   saStatics[ SLBUMPTOP ]       := .F.
   saStatics[ SLBUMPBOT ]       := .F.
   saStatics[ SNLASTEXIT ]      := 0
   saStatics[ SNLASTPOS ]       := 0
   /* saStatics[ SOACTIVEGET ] */
   /* saStatics[ SXREADVAR ]   */
   saStatics[ SCREADPROCNAME ]  := ""
   saStatics[ SNREADPROCLINE ]  := 0
   saStatics[ SNNEXTGET ]       := 0
   saStatics[ SNHITCODE ]       := 0
   saStatics[ SNPOS ]           := 0

   saStatics[ SCSCRSVMSG ]      := NIL

   RETURN ( aSavSysVars )


/***
*
*  RestoreGetSysVars( <aSavSysVars> )
*
*  Restore READ state variables from array of saved values
*
*  NOTE: 'Updated' status is not restored (S'87 compatibility)
*
***/
STATIC PROCEDURE RestoreGetSysVars( aSavSysVars )
   LOCAL lUpdated         := saStatics[ SLUPDATED ]
   saStatics              := ACLONE( aSavSysVars )
   saStatics[ SLUPDATED ] := lUpdated
   READVAR( aSavSysVars[ SXREADVAR ] )  // Added.
   GETACTIVE( aSavSysVars[ SOACTIVEGET ] )  // Added.

   RETURN


/***
*
*  GetReadVar( <oGet> ) --> cName
*
*  Set READVAR() value from a GET
*
***/
STATIC FUNCTION GetReadVar( oGet )

   LOCAL cName := UPPER( oGet:name )
   LOCAL i

   // NOTE: Incompatible with Summer '87
   IF !( oGet:subscript == NIL )
      // Subscripts in Name are returned if Get variable is an
      // array element; retrieved from Subscript instance variable
      FOR i := 1 TO LEN( oGet:subscript )
	 cName += "[" + LTRIM( STR( oGet:subscript[i] ) ) + "]"
      NEXT
   ENDIF

   RETURN ( cName )


/***
*              System Services
***/

/***
*
*  __SetFormat( <b> )
*
*  SET FORMAT service
*
***/
PROCEDURE __SetFormat( b )
   saStatics[ SBFORMAT ] := IIF( VALTYPE( b ) == "B", b, NIL )
   RETURN 


/***
*
*  __KillRead()
*
*  CLEAR GETS service
*
***/
PROCEDURE __KillRead()
   saStatics[ SLKILLREAD ] := .T.
   RETURN


/***
*
*  GetActive( <g> ) --> oldActive
*
*  Retrieves currently active GET object
***/
FUNCTION GetActive( g )

   LOCAL oldActive := saStatics[ SOACTIVEGET ]

   IF ( PCOUNT() > 0 )
      saStatics[ SOACTIVEGET ] := g
   ENDIF

   RETURN ( oldActive )


/***
*
*  Updated() --> saStatics[ SLUPDATED ]
*
***/
FUNCTION Updated()
   RETURN saStatics[ SLUPDATED ]


/***
*
*  ReadExit( <lNew> ) --> ( SET( _SET_EXIT, lNew ) )
*
***/
FUNCTION ReadExit( lNew )
   RETURN ( SET( _SET_EXIT, lNew ) )


/***
*
*  ReadInsert( <lNew> ) --> ( SET( _SET_INSERT, lNew ) )
*
***/
FUNCTION ReadInsert( lNew )
   RETURN ( SET( _SET_INSERT, lNew ) )


/***
*              Wacky Compatibility Services
***/

// Display coordinates for SCOREBOARD
#define SCORE_ROW      0
#define SCORE_COL      60


/***
*
*  ShowScoreboard()
*
***/
STATIC PROCEDURE ShowScoreboard()

   LOCAL nRow
   LOCAL nCol

   IF ( SET( _SET_SCOREBOARD ) )
      nRow := ROW()
      nCol := COL()

      SETPOS( SCORE_ROW, SCORE_COL )
      DISPOUT( IIF( SET( _SET_INSERT ), NationMsg( _GET_INSERT_ON ), ;
					NationMsg( _GET_INSERT_OFF ) ) )

      SETPOS( nRow, nCol )
   ENDIF

   RETURN


/***
*
*  DateMsg()
*
***/
STATIC PROCEDURE DateMsg()

   LOCAL nRow
   LOCAL nCol

   IF ( SET( _SET_SCOREBOARD ) )

      nRow := ROW()
      nCol := COL()

      SETPOS( SCORE_ROW, SCORE_COL )
      DISPOUT( NationMsg( _GET_INVD_DATE ) )
      SETPOS( nRow, nCol )

      WHILE ( NEXTKEY() == 0 )
      ENDDO

      SETPOS( SCORE_ROW, SCORE_COL )
      DISPOUT( SPACE( LEN( NationMsg( _GET_INVD_DATE ) ) ) )
      SETPOS( nRow, nCol )

   ENDIF

   RETURN


/***
*
*  RangeCheck( <oGet>, <junk>, <lo>, <hi> ) --> .T. | .F.
*
*  NOTE: Unused second formal parameter for 5.00 compatibility.
*
***/
FUNCTION RangeCheck( oGet, junk, lo, hi )

   LOCAL cMsg, nRow, nCol
   LOCAL xValue

   IF ( !oGet:changed )
      RETURN ( .T. )
   ENDIF

   xValue := oGet:VarGet()

   IF ( xValue >= lo .AND. xValue <= hi )
      RETURN ( .T. )
   ENDIF

   IF ( SET( _SET_SCOREBOARD ) )

      cMsg := NationMsg(_GET_RANGE_FROM) + LTRIM( TRANSFORM( lo, "" ) ) + ;
	      NationMsg(_GET_RANGE_TO) + LTRIM( TRANSFORM( hi, "" ) )

      IF ( LEN( cMsg ) > MAXCOL() )
	 cMsg := SUBSTR( cMsg, 1, MAXCOL() )
      ENDIF

      nRow := ROW()
      nCol := COL()

      SETPOS( SCORE_ROW, MIN( 60, MAXCOL() - LEN( cMsg ) ) )
      DISPOUT( cMsg )
      SETPOS( nRow, nCol )

      WHILE ( NEXTKEY() == 0 )
      ENDDO

      SETPOS( SCORE_ROW, MIN( 60, MAXCOL() - LEN( cMsg ) ) )
      DISPOUT( SPACE( LEN( cMsg ) ) )
      SETPOS( nRow, nCol )

   ENDIF

   RETURN ( .F. )


/***
*
*  ReadKill( <lKill> ) --> lSavKill
*
***/
FUNCTION ReadKill( lKill )

   LOCAL lSavKill := saStatics[ SLKILLREAD ]

   IF ( PCOUNT() > 0 )
      saStatics[ SLKILLREAD ] := lKill
   ENDIF

   RETURN ( lSavKill )


/***
*
*  ReadUpdated( <lUpdated> ) --> lSavUpdated
*
***/
FUNCTION ReadUpdated( lUpdated )

   LOCAL lSavUpdated := saStatics[ SLUPDATED ]

   IF ( PCOUNT() > 0 )
      saStatics[ SLUPDATED ] := lUpdated
   ENDIF

   RETURN ( lSavUpdated )


/***
*
*  ReadFormat( <bFormat> ) --> bSavFormat
*
***/
FUNCTION ReadFormat( b )

   LOCAL bSavFormat := saStatics[ SBFORMAT ]

   IF ( PCOUNT() > 0 )
      saStatics[ SBFORMAT ] := b
   ENDIF

   RETURN ( bSavFormat )


/***
*
*  ReadStats( <element> [, <xNewValue> ] ) --> xoldValue
*
*  Public Accessor to Get-Set the current Get System STATIC Array element.
*  Optionally changes the value if called with a second parameter.
*  Always RETURNs the old value. Call again to test changed value.
*
***/
FUNCTION ReadStats( nStatic, xValue )

   LOCAL xSavStats := saStatics[ nSTATIC ]

   IF ( PCOUNT() > 1 )
      saStatics[ nSTATIC ] := xValue
   ENDIF

   RETURN ( xSavStats )


/***
*
*  ShowGetMsg() --> NIL
*
***/
FUNCTION ShowGetMsg( oGet, aMsg )    // Use custom reader block
   LOCAL cMsg
   LOCAL lmOldState := MSetCursor( .F. )

   IF ( !( EMPTY( aMsg ) ) .AND. aMsg[ MSGFLAG ] )

      cMsg := IIF( VALTYPE( oGet:Control ) == "O", ;
			    oGet:Control:Message, oGet:Message )

      IF !EMPTY( cMsg )
	 @ aMsg[ MSGROW ], aMsg[ MSGLEFT ] ;
	 SAY PadC( cMsg, aMsg[ MSGRIGHT ] - aMsg[ MSGLEFT ] + 1 ) ;
		   COLOR aMsg[ MSGCOLOR ]

	 IF _IsGraphics()

	    gFrame( aMsg[ MSGLEFT ]     * aMsg[ MSGFONTCOL ] - 2, ;
		    aMsg[ MSGROW ]      * aMsg[ MSGFONTROW ] - 2, ;
		    aMsg[ MSGRIGHT ]    * aMsg[ MSGFONTCOL ] + 9, ;
		   (aMsg[ MSGROW ] + 1) * aMsg[ MSGFONTROW ] + 1, ;
		    aMsg[ MSGBACK2 ],;
		    aMsg[ MSGBACK2 ], aMsg[ MSGFORE ],;
		    2, 2, 2, 2, LLG_MODE_SET, LLG_FRAME )
	 ENDIF

      ENDIF

   ENDIF
   MSetCursor( lmOldState )

   RETURN ( NIL )


/***
*
*  EraseGetMsg( <oGet>, <aMsg> ) --> NIL
*
***/
FUNCTION EraseGetMsg( oGet, aMsg )
   LOCAL cMsg, nRow := ROW(), nCol := COL()  // Added.
   LOCAL lmOldState := MSetCursor( .F. )

   IF ( !( EMPTY( aMsg ) ) .AND. aMsg[ MSGFLAG ] )

      cMsg := IIF( VALTYPE( oGet:Control ) == "O", ;
			    oGet:Control:Message, oGet:Message )

      IF _IsGraphics() .AND. !EMPTY( cMsg )
	 gFrame( aMsg[ MSGLEFT ]     * aMsg[ MSGFONTCOL ] - 2, ;
		 aMsg[ MSGROW ]      * aMsg[ MSGFONTROW ] - 2, ;
		 aMsg[ MSGRIGHT ]    * aMsg[ MSGFONTCOL ] + 9, ;
	       ( aMsg[ MSGROW ] + 1) * aMsg[ MSGFONTROW ] + 1, ;
		 aMsg[ MSGBACK1 ],;
		 aMsg[ MSGBACK1 ], aMsg[ MSGBACK1 ], ;
		 2, 2, 2, 2, LLG_MODE_SET, LLG_FRAME )
      ENDIF

      RestScreen( aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGROW ], ;
		  aMsg[ MSGRIGHT ], saStatics[ SCSCRSVMSG ] )

   ENDIF
   MSetCursor( lmOldState )
   SETPOS( nRow, nCol )  // Added.

   RETURN ( NIL )
