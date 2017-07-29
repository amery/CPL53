/***
*
*  MenuSys.Prg
*  Standard CA-Clipper 5.3 Menu Item Class subsystem definition
*  Version 5.3b.
*  Copyright (c) 1993 - 1997, Computer Associates International, Inc.
*  All rights reserved.
*
*  NOTE: Compile with /M /N /W
*  Code in C-style comment blocks may be uncommented to test non-CUA 
*  menuing behavior which permits returning to the selected menu item.
*
***/
#include "Button.Ch"
#include "Inkey.Ch"
#include "Llibg.Ch"
#include "Setcurs.Ch"

// Static Menu System array manifest contants:
#define SAMENULIST     1
#define SNMENULEVEL    2
#define SOMENU         3
#define SCOLDMESSAGE   4
#define SCSCRSVMSG     5
#define SLOLDMSGFLAG   6
#define SNOLDROW       7  // Added.
#define SNOLDCOL       8  // Added.
#define SNOLDCURSOR    9  // Added.

#define SNTOTAL        9  // Changed.

// Local message array manifest contants used to store message values:
#define MSGFLAG        1
#define MSGROW         2
#define MSGLEFT        3
#define MSGRIGHT       4
#define MSGCOLOR       5
#define MSGBACK1       6
#define MSGBACK2       7
#define MSGFORE        8
#define MSGFONTCOL     9
#define MSGFONTROW    10

#define GE_SHORTCUT    9  // Added.
#define GE_MOUSEHIT   10  // Added.

#define SNLASTEXIT     6  // Added.
#define SNNEXTGET     12  // Added.

STATIC saStatics := { , , , , , , , , }  // Added 3 elements.
// Array format:     1 2 3 4 5 6 7 8 9

   /* Hold the value of the last TopBarItem position:
   STATIC nTopBar := 1
   Array of PopUp MenuItem positions.
   STATIC aPopUp  := {} */

/***
*
*  MenuModal( <oTopMenu>, <nSelection>, <nMsgRow>, <nMsgLeft>, ;
*             <nMsgRight>, cMsgColor ) --> nReturn
*
*  Standard Menu System Modal handling for Menu Items
*
***/
FUNCTION MenuModal( oTopMenu, nSelection, nMsgRow, nMsgLeft, nMsgRight, ;
		    cMsgColor, GetList )  // Changed: Added 'GetList'.
   // Changed 'lSaveCursor' to 'nSaveCursor':
   LOCAL nKey, nNewItem, lSaveCursor, lLeftDown, oNewMenu, nNewLevel, ;
	 nEvent, oMenuItem, nMenuItem, nReturn, nCol, nRow, aMsg, ;
	 nTemp, bKeyBlock, lSubMenu, aMode, aSavMenuSys

   // Assign menu system entry state settings onto file-wide array:
   aSavMenuSys := ACLONE( saStatics )
   AFILL( saStatics, NIL )

   nReturn     := 0
   // nCol        := COL()  // Commented out.
   // nRow        := ROW()  // Commented out.
   // nSaveCursor := SetCursor( SC_NONE )  // Changed/Commented out.

   saStatics[ SNOLDROW ]    := ROW()  // Changed.
   saStatics[ SNOLDCOL ]    := COL()  // Changed.
   saStatics[ SNOLDCURSOR ] := SetCursor( SC_NONE )  // Changed.

   aMsg := { , nMsgRow, nMsgLeft, nMsgRight, cMsgColor, , , , , }

   IF ( aMsg[ MSGFLAG ] := ( ValType( aMsg[ MSGROW ] ) + ;
			     ValType( aMsg[ MSGLEFT ] ) + ;
			     ValType( aMsg[ MSGRIGHT ] ) == "NNN" ) )

      IF !( ValType( aMsg[ MSGCOLOR ] ) == "C" )
	 aMsg[ MSGCOLOR ] := GetClrPair( SetColor(), 1 )
      ENDIF

      @ aMsg[ MSGROW ], aMsg[ MSGLEFT ] CLEAR TO ;
	aMsg[ MSGROW ], aMsg[ MSGRIGHT ]

      // Graphics mode test to retrieve message colors and font positions:       
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
		 aMsg[ MSGBACK1 ], ;
		 aMsg[ MSGBACK1 ], aMsg[ MSGBACK1 ], ;
		 2, 2, 2, 2, LLG_MODE_SET, LLG_FRAME )

      ENDIF

      saStatics[ SCSCRSVMSG ] := SaveScreen( aMsg[ MSGROW ], ;
	   aMsg[ MSGLEFT ], aMsg[ MSGROW ], aMsg[ MSGRIGHT ] )

   ENDIF

   oTopMenu:Select( nSelection )

   IF ( oTopMenu:ClassName() != "TOPBARMENU" .AND. !oTopMenu:IsOpen )
      oTopMenu:Open()
   ELSE
      oTopMenu:Display()
   ENDIF

   IF nSelection <= 0
      WHILE ( nSelection <= 0 )

	 nEvent := SET( _SET_EVENTMASK, INKEY_KEYBOARD + INKEY_LDOWN )
	 nKey   :=  Inkey( 0 )
	 SET( _SET_EVENTMASK, nEvent )

	 IF ( nKey == K_LBUTTONDOWN .OR. nKey == K_LDBLCLK )
	    nSelection := oTopMenu:HitTest( MRow(), MCol() )

	 ELSEIF ( ( nSelection := oTopMenu:GetAccel( nKey ) ) != 0 )

	 ELSEIF ( IsShortCut( oTopMenu, nKey, @nReturn ) )
	    // Restore system entry state settings from file-wide array:
	    saStatics := ACLONE( aSavMenuSys )
	    RETURN ( nReturn )

	 ELSE
	    nSelection := 1

	 ENDIF

      ENDDO

      oTopMenu:Select( nSelection )
      oTopMenu:Display()

   ENDIF

   IF ( !oTopMenu:GetItem( nSelection ):Enabled )
      // Restore system entry state settings from file-wide array:
      saStatics := ACLONE( aSavMenuSys )
      RETURN ( 0 )
   ENDIF

   saStatics[ SOMENU ]          := oTopMenu
   saStatics[ SAMENULIST ]      := Array( 16 )
   saStatics[ SNMENULEVEL ]     := 1
   saStatics[ SAMENULIST ][ 1 ] := saStatics[ SOMENU ]

   lLeftDown := mLeftDown()

   /* Continue pushing MenuItems until there are no more to push:
   DO WHILE ( PushMenu( .T., oTopMenu ) )
   ENDDO */

   ShowMsg( aMsg, .T. )

   WHILE (.T.)
      /* Save Current TopBar MenuItem:
      nTopBar := oTopBar:Current
      // Save Current PopUp MenuItem:
      aPopUp[ saStatics[ SNMENULEVEL ] ] := saStatics[ SOMENU ]:Current */
      nKey := INKEY( 0 )
      // Check for SET KEY first
      IF !( ( bKeyBlock := SETKEY( nKey ) ) == NIL )
	 EVAL( bKeyBlock, PROCNAME(1), PROCLINE(1), "" )
	 LOOP
      ENDIF

      IF ( nKey == K_MOUSEMOVE )
	 //====== mouse movement.

	 IF ( lLeftDown )
	    // Changed '!HitTest' to '!MHitTest':
	    IF ( !MHitTest( @oNewMenu, @nNewLevel, @nNewItem, oTopMenu ) )
	       //------------ hit nowhere.

	    ELSEIF ( nNewLevel != saStatics[ SNMENULEVEL ] )
	       //------------ menu level change.

	       IF ( nNewItem == oNewMenu:Current )
	       ELSEIF ( oNewMenu:GetItem( nNewItem ):Enabled )
		  saStatics[ SOMENU ] := oNewMenu
		  PopChild( nNewLevel, oTopMenu )
		  saStatics[ SOMENU ]:Select( nNewItem )
		  saStatics[ SOMENU ]:Display()
		  PushMenu( .T., oTopMenu )
		  ShowMsg( aMsg, .T. )
	       ENDIF

	    ELSEIF ( nNewItem != oNewMenu:Current() )
	       //------------ menu item change.

	       PopChild( saStatics[ SNMENULEVEL ], oTopMenu  )

	       IF ( saStatics[ SOMENU ]:GetItem( nNewItem ):Enabled )
		  saStatics[ SOMENU ]:Select( nNewItem )
		  saStatics[ SOMENU ]:Display()
		  PushMenu( .T., oTopMenu )
		  ShowMsg( aMsg, .T. )
	       ENDIF

	    ENDIF

	 ENDIF

      ELSEIF ( nKey == K_DOWN )
	 //====== down arrow key.

	 IF saStatics[ SOMENU ]:ClassName() == "TOPBARMENU"
	    IF ( PushMenu( .T., oTopMenu ) )
	       ShowMsg( aMsg, .T. )
	    ENDIF
	 ELSE  // IF ( saStatics[ SNMENULEVEL ] > 1 )
	    nTemp := saStatics[ SOMENU ]:GetNext()
	    IF ( nTemp == 0 )
	       nTemp := saStatics[ SOMENU ]:GetFirst()
	    ENDIF
	    saStatics[ SOMENU ]:Select( nTemp )
	    saStatics[ SOMENU ]:Display()
	    ShowMsg( aMsg, .T. )

	 ENDIF

      ELSEIF ( nKey == K_UP )
	 //====== up arrow key.

	 IF saStatics[ SOMENU ]:ClassName() != "TOPBARMENU"
	    nTemp := saStatics[ SOMENU ]:GetPrev()
	    IF ( nTemp == 0 )
	       nTemp := saStatics[ SOMENU ]:GetLast()
	    ENDIF
	    saStatics[ SOMENU ]:Select( nTemp )
	    saStatics[ SOMENU ]:Display()
	    ShowMsg( aMsg, .T. )

	 ENDIF

      ELSEIF ( nKey == K_LEFT )
	 //====== left arrow key.
	 /** Reset PopUp MenuItem to 1:
	 aPopUp[ saStatics[ SNMENULEVEL ] ] := 1 **/
	 IF ( lSubMenu := saStatics[ SNMENULEVEL ] > 1 )
	    PopMenu( oTopMenu )
	 ENDIF
	 IF saStatics[ SOMENU ]:ClassName() == "TOPBARMENU"
	    nTemp := saStatics[ SOMENU ]:GetPrev()
	    IF ( nTemp == 0 )
	      nTemp := saStatics[ SOMENU ]:GetLast()
	    ENDIF
	    saStatics[ SOMENU ]:Select( nTemp )
	    saStatics[ SOMENU ]:Display()
	    IF lSubMenu
	       PushMenu( .T., oTopMenu )
	    ENDIF
	 ENDIF
	 ShowMsg( aMsg, .T. )

      ELSEIF ( nKey == K_RIGHT )
	 //====== right arrow key.
	 /* Reset PopUp MenuItem to 1:
	 aPopUp[ saStatics[ SNMENULEVEL ] ] := 1 */
	 IF ( lSubMenu := saStatics[ SNMENULEVEL ] > 1 )
	    /* Test !PopMenu() to determine calling PopAll():
	    IF !( PopMenu( oTopMenu ) )
	       PopAll()
	    ENDIF */
	    PopMenu( oTopMenu )
	 ENDIF

	 IF saStatics[ SOMENU ]:ClassName() == "TOPBARMENU"
	    nTemp := saStatics[ SOMENU ]:GetNext()
	    IF ( nTemp == 0 )
	       nTemp := saStatics[ SOMENU ]:GetFirst()
	    ENDIF
	    saStatics[ SOMENU ]:Select( nTemp )
	    saStatics[ SOMENU ]:Display()
	    IF lSubMenu
	       PushMenu( .T., oTopMenu )
	    ENDIF
	 ENDIF
	 ShowMsg( aMsg, .T. )

      ELSEIF ( nKey == K_ENTER )
	 //====== enter key .

	 IF ( PushMenu( .T., oTopMenu ) )
	    ShowMsg( aMsg, .T. )

	 ELSE
	    ShowMsg( aMsg, .F. )
	    nReturn := Execute( oTopMenu )
	    IF ( nReturn != 0 )
	       EXIT
	    ENDIF

	 ENDIF

      ELSEIF ( nKey == K_ESC )
	 //====== escape key - go to previous menu

	 IF PopMenu( oTopMenu )
	    saStatics[ SOMENU ]:Display()
	    ShowMsg( aMsg, .T. )
	 ELSE

	    IF saStatics[ SOMENU ]:ClassName() == "POPUPMENU"
	       saStatics[ SOMENU ]:Close()
	    ENDIF
	    // Bail out if at the top menu item:
	    nReturn := -1
	    EXIT

	 ENDIF

      ELSEIF ( nKey == K_LBUTTONDOWN )
	 //====== mouse left button press.

	 // Changed '!HitTest' to '!MHitTest':
	 IF ( !MHitTest( @oNewMenu, @nNewLevel, @nNewItem, oTopMenu ) )
	    // Added the following to test Get System HitTest():
	    IF ( !( GetList == NIL ) .AND. ;
	       HitTest( GetList, MROW(), MCOL(), aMsg ) != 0 )
	       GETACTIVE():ExitState := GE_MOUSEHIT
	       // Reset Get System values:
	       ReadStats( SNLASTEXIT, GE_MOUSEHIT )
	       // IF ReadStats( SOMENU ):ClassName() == "POPUPMENU"
	       IF saStatics[ SOMENU ]:ClassName() == "POPUPMENU"
		  PopMenu( oTopMenu )
	       ENDIF
	       // ENDIF
	       nReturn := -1
	       EXIT
	    ENDIF

	    //// Warning: New test for hitting NOWHERE on the Canvas area!!!
	    IF saStatics[ SOMENU ]:ClassName() == "POPUPMENU"
	       PopMenu( oTopMenu )
	    ENDIF

	 ELSEIF ( nNewLevel == saStatics[ SNMENULEVEL ] )
	    saStatics[ SOMENU ]:Select( nNewItem )
	    saStatics[ SOMENU ]:Display()
	    PushMenu(.T., oTopMenu )
	    ShowMsg( aMsg, .T. )

	 ELSE
	    saStatics[ SNMENULEVEL ] := nNewLevel
	    saStatics[ SOMENU ]      := ;
	    saStatics[ SAMENULIST ][ saStatics[ SNMENULEVEL ] ]

	    nMenuItem := saStatics[ SOMENU ]:Current
	    oMenuItem := saStatics[ SOMENU ]:GetItem( nMenuItem )
	    IF ( ( oMenuItem := ;
	       saStatics[ SOMENU ]:GetItem( ;
	       saStatics[ SOMENU ]:Current ) ):IsPopUp() )
	       oMenuItem:Data:Close()
	    ENDIF

	    IF !( nMenuItem == nNewItem )
	       nMenuItem    := nNewItem
	       saStatics[ SOMENU ]:Select( nNewItem )
	       saStatics[ SOMENU ]:Display()
	       PushMenu( .T., oTopMenu )
	    ENDIF

	    ShowMsg( aMsg, .T. )
	 ENDIF

	 lLeftDown := .T.

      ELSEIF ( nKey == K_LBUTTONUP )
	 //====== mouse left button release.

	 lLeftDown := .F.

	 // Changed '!HitTest' to '!MHitTest':
	 IF ( !MHitTest( @oNewMenu, @nNewLevel, @nNewItem, oTopMenu ) )
	 ELSEIF ( nNewLevel == saStatics[ SNMENULEVEL ] )
	    IF ( nNewItem == saStatics[ SOMENU ]:Current )
	       ShowMsg( aMsg, .F.)
	       nReturn := Execute( oTopMenu )
	       IF ( nReturn != 0 )
		  EXIT
	       ENDIF
	    ENDIF

	 ELSE

	    /* This may not be necessary:
	    nNewItem := saStatics[ SOMENU ]:GetFirst()
	    IF ( nNewItem == 0 )
	    ELSE
	       saStatics[ SOMENU ]:Select(  nNewItem )
	       saStatics[ SOMENU ]:Display()
	       ShowMsg( aMsg, .T. )
	    ENDIF */

	 ENDIF

      ELSEIF ( ( nNewItem := saStatics[ SOMENU ]:GetAccel( nKey ) ) != 0 )
	 //=== check for menu item accelerator key.

	 IF saStatics[ SOMENU ]:GetItem( nNewItem ):Enabled
	    saStatics[ SOMENU ]:Select( nNewItem )
	    saStatics[ SOMENU ]:Display()

	    /* Code insert to Debug selected menu item in graphics mode:
	    @ 20, 70 SAY STR( nNewItem, 3 )
	    INKEY(0)
	    @ 20, 70 SAY SPACE( 3 ) */
	 
	    IF ( !PushMenu( .T., oTopMenu ) )
	       ShowMsg( aMsg, .F. )
	       nReturn := Execute( oTopMenu )
	       IF ( nReturn != 0 )
		  EXIT
	       ENDIF
	    ENDIF
	    ShowMsg( aMsg, .T. )

	 ENDIF

      ELSEIF ( IsShortCut( oTopMenu, nKey, @nReturn ) )

	 IF ( nReturn != 0 )
	    EXIT
	 ENDIF

      // Added the following to test Get System HitTest():
      ELSEIF ( !( GetList == NIL ) .AND. ;
	 ( ( nNewItem := Accelerator( GetList, nKey, aMsg ) ) != 0 ) )
	 GETACTIVE():ExitState := GE_SHORTCUT
	 // Reset Get System values:
	 ReadStats( SNNEXTGET, nNewItem )
	 // IF ReadStats( SOMENU ):ClassName() == "POPUPMENU"
	 IF saStatics[ SOMENU ]:ClassName() == "POPUPMENU"
	    PopMenu( oTopMenu )
	 ENDIF
	 // ENDIF
	 nReturn := -1
	 EXIT

      ELSEIF ( ( nNewItem := oTopMenu:GetAccel( nKey ) ) != 0 )
	 //=== check for the top menu item accelerator key

	 IF oTopMenu:GetItem( nNewItem ):Enabled
	    PopAll( oTopMenu )
	    saStatics[ SOMENU ]:Select( nNewItem )
	    saStatics[ SOMENU ]:Display()
	    IF ( oTopMenu:GetItem( nNewItem ):IsPopUp() )
	       PushMenu( .T., oTopMenu )
	    ELSE
	       ShowMsg( aMsg, .F. )
	       nReturn := Execute( oTopMenu )
	       IF ( nReturn != 0 )
		  EXIT
	       ENDIF
	    ENDIF
	    ShowMsg( aMsg, .T. )
	 ENDIF

      ENDIF

   ENDDO

   IF ( aMsg[ MSGFLAG ] )
      RestScreen( aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGROW ], ;
		  aMsg[ MSGRIGHT ], saStatics[ SCSCRSVMSG ] )
   ENDIF

   PopAll( oTopMenu )
   SetPos( nRow, nCol )
   SetCursor( lSaveCursor )
   // Restore system entry state settings from file-wide array:
   saStatics := ACLONE( aSavMenuSys )

   RETURN ( nReturn )


/***
*
*  PushMenu( <lSelect>, <oTopMenu> ) --> .T. | .F.
*
*  Increment saStatics[ SNMENULEVEL ] and optionally select first item.
*  If selected MenuItem IsPopUp, assign saStatics[ SOMENU ].
*
***/
STATIC FUNCTION PushMenu( lSelect, oTopMenu )
   LOCAL oNewMenu

   oNewMenu := saStatics[ SOMENU ]:GetItem( saStatics[ SOMENU ]:Current )

   IF ( !( ValType( oNewMenu ) == "O" ) )
   ELSEIF ( oNewMenu:IsPopUp )

      IF ( !( ValType( lSelect ) == "L" ) )
	 lSelect := .F.
      ENDIF

      saStatics[ SOMENU ] := oNewMenu:Data
      saStatics[ SAMENULIST ][ ++saStatics[ SNMENULEVEL ] ] := ;
				 saStatics[ SOMENU ]

      /* If entering a new level:
      IF LEN( aPopUp ) < saStatics[ SNMENULEVEL ]
	 // Resize the array:
	 ASIZE( aPopUp, saStatics[ SNMENULEVEL ] )
	 // Reset MenuItem to 1:
	 aPopUp[ saStatics[ SNMENULEVEL ] ] := 1
      ENDIF */

      IF ( lSelect )
	 saStatics[ SOMENU ]:Select( saStatics[ SOMENU ]:GetFirst() )
	 /* Select previous item:
	 saStatics[ SOMENU ]:Select( aPopUp[ saStatics[ SNMENULEVEL ] ] ) */
      ELSE
	 saStatics[ SOMENU ]:Select( 0 )

      ENDIF

      IF !( saStatics[ SOMENU ]:IsOpen )
	 saStatics[ SOMENU ]:Open()
      ENDIF

      RETURN ( .T. )

   ENDIF

   RETURN ( .F. )


/***
*
*  PopMenu( <oTopMenu> ) --> .T. | .F.
*
*  Close SubMenuItem and Return to the upper MenuItem level.
*
***/
STATIC FUNCTION PopMenu( oTopMenu )
   IF ( saStatics[ SNMENULEVEL ] > 1 )
      saStatics[ SOMENU ]:Select(0)
      saStatics[ SOMENU ]:Close(.T.)
      // Decrement MenuItem level and assign:
      saStatics[ SOMENU ] := ;
	 saStatics[ SAMENULIST ][ --saStatics[ SNMENULEVEL ] ]
      RETURN ( .T. )

   ENDIF

   RETURN ( .F. )


/***
*
*  PopChild( <nNewLevel>, <oTopMenu> ) --> .T. | .F.
*
*  Close PopUp Child MenuItem and Return to the upper MenuItem level.
*
***/
STATIC FUNCTION PopChild( nNewLevel, oTopMenu )
   LOCAL oOldMenuItem, nCurrent

   IF ( ( nCurrent := saStatics[ SOMENU ]:Current ) != 0 )
      oOldMenuItem := saStatics[ SOMENU ]:GetItem( nCurrent )
      IF ( oOldMenuItem:IsPopUp )
	 oOldMenuItem:Data:Close()
	 saStatics[ SNMENULEVEL ] := nNewLevel
	 RETURN ( .T. )
      ENDIF

   ENDIF

   RETURN ( .F. )


/***
*
*  PopAll( <oTopMenu> ) --> .T.
*
*  Close all Menus below Top Menu and Return to upper MenuItem level.
*
***/
STATIC FUNCTION PopAll( oTopMenu )
   IF saStatics[ SAMENULIST ][2] != NIL
      saStatics[ SAMENULIST ][2]:Close()
   ENDIF
   // Set the menu level and position relative to the top menu item:
   saStatics[ SNMENULEVEL ] := 1
   saStatics[ SOMENU ]      := saStatics[ SAMENULIST ][ 1 ]

   RETURN ( .T. )


/***
*
*  Execute( <oTopMenu> ) --> oNewMenu:Id | 0
*
*  EVAL()uate the Data block if selected MenuItem is !IsPopUp.
*
***/
STATIC FUNCTION Execute( oTopMenu )
   LOCAL oNewMenu, nCurrent := 0, i, lPas := .T.
   LOCAL nOldRow, nOldCol, nOldCursor  // Added.

   oNewMenu := saStatics[ SOMENU ]:GetItem( saStatics[ SOMENU ]:Current )

   IF ( !( ValType( oNewMenu ) == "O" ) )
   // Execute the Data block if selected MenuItem is !IsPopUp:
   ELSEIF ( !oNewMenu:IsPopUp )
      IF ( saStatics[ SOMENU ]:ClassName() == "TOPBARMENU" )
	 nOldRow    := saStatics[ SNOLDROW ]        // Added.
	 nOldCol    := saStatics[ SNOLDCOL ]        // Added.
	 nOldCursor := saStatics[ SNOLDCURSOR ]     // Added.
	 SETPOS( saStatics[ SNOLDROW ], saStatics[ SNOLDCOL ] )  // Added.
	 SETCURSOR( saStatics[ SNOLDCURSOR ] )      // Added.
	 EVAL( oNewMenu:Data, oNewMenu )
	 SETCURSOR( SC_NONE )                       // Added.
	 // saStatics[ SNOLDROW ]    := nOldRow     // Added.
	 // saStatics[ SNOLDCOL ]    := nOldCol     // Added.
	 // saStatics[ SNOLDCURSOR ] := nOldCursor  // Added.
	 lPas := .F.
      ELSEIF ( saStatics[ SOMENU ]:ClassName() == "POPUPMENU" )
	 nOldRow    := saStatics[ SNOLDROW ]        // Added.
	 nOldCol    := saStatics[ SNOLDCOL ]        // Added.
	 nOldCursor := saStatics[ SNOLDCURSOR ]     // Added.
	 SETPOS( saStatics[ SNOLDROW ], saStatics[ SNOLDCOL ] )  // Added.
	 SETCURSOR( saStatics[ SNOLDCURSOR ] )      // Added.
	 EVAL( oNewMenu:Data, oNewMenu )
	 SETCURSOR( SC_NONE )                       // Added.
	 // saStatics[ SNOLDROW ]    := nOldRow     // Added.
	 // saStatics[ SNOLDCOL ]    := nOldCol     // Added.
	 // saStatics[ SNOLDCURSOR ] := nOldCursor  // Added.
	 lPas := .F.
      ENDIF

      // Pop the Menu:
      IF PopMenu( oTopMenu )
	 nCurrent := saStatics[ SOMENU ]:Current
      ENDIF

      saStatics[ SOMENU ]:Select( nCurrent )
      // Display newly selected current menu item:
      IF ( saStatics[ SOMENU ]:ClassName() == "POPUPMENU" .AND. ;
	 saStatics[ SNMENULEVEL ] == 1 .AND. !saStatics[ SOMENU ]:IsOpen )
	 saStatics[ SOMENU ]:Open()
      ENDIF

      IF lPas
	 saStatics[ SOMENU ]:Close()
	 nOldRow    := saStatics[ SNOLDROW ]        // Added.
	 nOldCol    := saStatics[ SNOLDCOL ]        // Added.
	 nOldCursor := saStatics[ SNOLDCURSOR ]     // Added.
	 SETPOS( saStatics[ SNOLDROW ], saStatics[ SNOLDCOL ] )  // Added.
	 SETCURSOR( saStatics[ SNOLDCURSOR ] )      // Added.
	 EVAL( oNewMenu:Data, oNewMenu )
	 SETCURSOR( SC_NONE )                       // Added.
	 // saStatics[ SNOLDROW ]    := nOldRow     // Added.
	 // saStatics[ SNOLDCOL ]    := nOldCol     // Added.
	 // saStatics[ SNOLDCURSOR ] := nOldCursor  // Added.
	 
      ENDIF

      RETURN ( oNewMenu:Id )

   ENDIF

   RETURN ( 0 )


/***
*
*  MHitTest( <oNewMenu>, <nNewLevel>, <nNewItem>, <oTopMenu> ) --> .T. | .F.
*
*  Test to find the Mouse location.
*  Note: Formal parameters received here were passed by reference.
*
***/
STATIC FUNCTION MHitTest( oNewMenu, nNewLevel, nNewItem, oTopMenu )

   FOR nNewLevel := saStatics[ SNMENULEVEL ] TO 1 STEP -1
      oNewMenu   := saStatics[ SAMENULIST ][ nNewLevel ]
      nNewItem   := oNewMenu:HitTest( mRow(), mCol() )
      IF ( nNewItem < 0 )
	 // Test for the mouse on Menu separator or border
	 RETURN ( .F. )

      ELSEIF ( nNewItem > 0 ) .AND. oNewMenu:GetItem( nNewItem ):Enabled
	 // Test for the mouse on an enabled item in the menu
	 RETURN ( .T. )

      ENDIF

   NEXT

   RETURN ( .F. )


/***
*
*  ShowMsg( <aMsg>, <lMode> ) --> .T.
*
*  Erase and Show Messages.
*  Erase Message then ShowMsg() if lMode is .T.
*  Only erases Menu Message if lMode is .F.
*  SaveScreen()/RestScreen() is used for the
*  Message area in both text or graphics mode.
*
***/
FUNCTION ShowMsg( aMsg, lMode )
   LOCAL nCurrent, lColorFlag, cMsg := NIL
   LOCAL cSaveColor := SetColor()
   LOCAL mlOldState := MSetCursor( .F. )

   IF ( ValType( saStatics[ SLOLDMSGFLAG ] ) == "L" .AND. ;
	       saStatics[ SLOLDMSGFLAG ] )

      IF ( _IsGraphics() .AND. !EMPTY( saStatics[ SCOLDMESSAGE ] ) )
	 gFrame( aMsg[ MSGLEFT ]     * aMsg[ MSGFONTCOL ] - 2, ;
		 aMsg[ MSGROW ]      * aMsg[ MSGFONTROW ] - 2, ;
		 aMsg[ MSGRIGHT ]    * aMsg[ MSGFONTCOL ] + 9, ;
	       ( aMsg[ MSGROW ] + 1) * aMsg[ MSGFONTROW ] + 1, ;
		 aMsg[ MSGBACK1 ], ;
		 aMsg[ MSGBACK1 ], aMsg[ MSGBACK1 ], ;
		 2, 2, 2, 2, LLG_MODE_SET, LLG_FRAME )
      ENDIF

      RestScreen( aMsg[ MSGROW ], aMsg[ MSGLEFT ], aMsg[ MSGROW ], ;
		  aMsg[ MSGRIGHT ], saStatics[ SCSCRSVMSG ] )

   ENDIF

   IF lmode
      IF !( lColorFlag    := ( ValType( aMsg[ MSGCOLOR ] ) == "C" ) )
	 aMsg[ MSGCOLOR ] := GetClrPair( SetColor(), 1 )
      ENDIF

      IF ( ( aMsg[ MSGFLAG ] ) .AND. ;
	 ( nCurrent := saStatics[ SOMENU ]:Current ) != 0 )

	 IF !EMPTY( cMsg := saStatics[ SOMENU ]:GetItem( nCurrent ):Message )
	    @ aMsg[ MSGROW ], aMsg[ MSGLEFT ] ;
	    SAY PadC( cMsg, aMsg[ MSGRIGHT ] - aMsg[ MSGLEFT ] + 1 ) ;
	    COLOR aMsg[ MSGCOLOR ]

	    IF _IsGraphics()
	       gFrame( aMsg[ MSGLEFT ]      * aMsg[ MSGFONTCOL ] - 2, ;
		       aMsg[ MSGROW ]       * aMsg[ MSGFONTROW ] - 2, ;
		       aMsg[ MSGRIGHT ]     * aMsg[ MSGFONTCOL ] + 9, ;
		     ( aMsg[ MSGROW ] + 1 ) * aMsg[ MSGFONTROW ] + 1, ;
		       aMsg[ MSGBACK2 ], ;
		       aMsg[ MSGBACK2 ], aMsg[ MSGFORE ], ;
		       2, 2, 2, 2, LLG_MODE_SET, LLG_FRAME )
	    ENDIF

	 ENDIF
      ENDIF

      saStatics[ SCOLDMESSAGE ] := cMsg
      saStatics[ SLOLDMSGFLAG ] := aMsg[ MSGFLAG ]

   ENDIF
   MSetCursor( mlOldState )

   RETURN ( .T. )


/***
*
*  IsShortCut( <oMenu>, <nKey>, <nID> ) -> .T. | .F.
*
*  ShortCut processing for initial Get or Menu Item.
*
***/
FUNCTION IsShortCut( oMenu, nKey, nID )
   LOCAL nItem, nTotal, nShortCut, oItem, i

   // Test for top menu item not a TopBar Menu:
   IF !( oMenu:ClassName() == "TOPBARMENU" )
      RETURN ( IsQuick( oMenu, nKey, @nID ) )

   // Test and assign top menu item shortCut, enabled, and !PopUp:
   // Changed by enclosing assignment before ':Enabled':
   ELSEIF ( ( nShortCut := oMenu:GetShortCt( nKey ) ) > 0 ) .AND. ;
	    ( ( oItem := oMenu:GetItem( nShortcut ) ):Enabled ) .AND. ;
	    ( !( oItem:IsPopUp() ) )
      oMenu:Select( nShortCut )
      EVAL( oItem:Data, oItem )
      nID := oItem:ID
      RETURN ( .T. )

   // Test and assignment for TopBar MenuItem:
   ELSEIF ( nShortCut == 0 )
      nTotal := oMenu:ItemCount()
      nItem  := oMenu:Current
      nItem  := IIF( nItem == 0, nItem := 1, nItem )

      // Loop to wrap around through TopMenu from Current Item:
      FOR i := 1 TO nTotal
	 IF ( !( oItem := oMenu:GetItem( nItem ) ):Enabled )
	 ELSEIF ( !oItem:IsPopUp() )
	 ELSEIF ( IsQuick( oItem:Data, nKey, @nID ) )
	    RETURN ( .T. )
	 ENDIF
	 nItem := IIF( ++nItem > nTotal, nItem := 1, nItem )
      NEXT

   ENDIF

   RETURN ( .F. )


/***
*
*  IsQuick( <oMenu>, <nKey>, <nID> ) --> .T. | .F.
*
*  IsShortCut() for secondary ShortCut processing.
*  Navigates to the next Get or Menu Item from the
*  Current if more than one uses the same ShortCut.
*
***/
FUNCTION IsQuick( oMenu, nKey, nID )
   LOCAL nItem, nTotal, nShortCut, oItem, i

   IF ( ( nShortCut := oMenu:GetShortCt( nKey ) ) == 0 )
      nTotal := oMenu:ItemCount()

      FOR nItem := 1 TO nTotal
	 IF ( !( oItem := oMenu:GetItem( nItem ) ):Enabled )
	 ELSEIF ( !( oItem:IsPopUp() ) )
	 ELSEIF ( IsQuick( oItem:Data, nKey, @nID ) )
	    RETURN ( .T. )
	 ENDIF
      NEXT

   ELSEIF ( !( oItem := oMenu:GetItem( nShortCut ) ):IsPopUp() )
      IF oItem:Enabled
	 oMenu:Select( nShortCut )
	 EVAL( oItem:Data, oItem )
	 nID := oItem:ID
	 RETURN ( .T. )
      ENDIF

   ENDIF

   RETURN ( .F. )
