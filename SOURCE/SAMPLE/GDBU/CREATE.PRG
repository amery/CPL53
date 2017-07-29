* ÚÄ Program ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
* ³  Application: Graphical DBU                                              ³
* ³  Description: To create the dbf and index files                          ³
* ³    File Name: CREATE.PRG                                                 ³
* ³       Author: Herntz P. Graham      Tester:                              ³
* ³ Date created: 10-29-95              Date updated: þ11-09-95              ³
* ³ Time created: 08:25:23pm            Time updated: þ12:43:33pm            ³
* ³    Make File:                                                            ³
* ³      Docs By: Herntz P. Graham                                           ³
* ³    Copyright: (c) 1995 by Compyter Associates International Inc.         ³
* ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
#INCLUDE "DBINFO.CH"
#DEFINE FILENAME        1
#DEFINE RDDSET          2
#DEFINE STRUCTURE       3
#DEFINE INDEXINFO       4

Function DbuCreate(aInfo, lNew, lIndexOnly)
   local i,cFor, bFor, bWhile, cTag, cExp, bExp, bEval
   local cFileName, cBagName
   local bError, bErrorBlock := ErrorBlock({|o|Break(o)})
   local lTag := .F., nAns := 0

   cFileName := Alltrim(aInfo[FILENAME])
   IF File(cFileName+".dbf") .AND. !lINdexOnly
      nAns := MessageBox( "The file specified already exist"+;
         ";Do you want to override it ?",{"Yes","No"},"No" )
      if nAns == 2
         Return .F.
      endif
   ENDIF

   /* Block to be use with the eval for progress bar. */
   bEval := {||.T. }                             //hpg Return .T.  for now

   /* Lets trap the error that may occur here. */
   Begin Sequence

   /* Create the dbf file */
      if !lIndexOnly
         if !lNew
            FRename(cFileName+".DBF", "GGDDBBUU.DBF")
            IF File(cFileName+DBInfo(DBI_MEMOEXT))
               FRename(cFileName+DBInfo(DBI_MEMOEXT),;
                  "GGDDBBUU"+DBInfo(DBI_MEMOEXT))
               DBCloseArea()
            endif
         endif
         DBCREATE(cFileName ,aInfo[STRUCTURE], aInfo[RDDSET])
      endif

   /* Check if to process indexes */
      IF Len(aInfo[INDEXINFO]) > 0

      /* Open Dbf file if we are to process indexes */
         IF !lIndexOnly
            IF !lNew
               Append From GGDDBBUU
            ENDIF
            //DBUseArea( .T., aInfo[RDDSET], cFileName, , .F.)
            OpenDBF( cFileName )
         endif

         FOR I := 1 TO Len( aInfo[INDEXINFO])

         /* Check for rdd type */
            if SubStr(aInfo[RDDSET],4,2) $ "NT ND"
               cBagName := aInfo[INDEXINFO][I][1]
            else
               cBagName := NIL
               lTag := .T.
            endif

            cTag := aInfo[INDEXINFO][I][1]
            cExp := aInfo[INDEXINFO][I][2]
            bExp := &("{||"+cExp+"}")

         /* check for For condition */
            IF Empty( aInfo[INDEXINFO][I][3] )
               cFor := nil
               bFor := nil
            else
               cFor := AllTrim(aInfo[INDEXINFO][I][3])
               bFor := &("{||"+AllTrim(aInfo[INDEXINFO][I][3])+"}")
            ENDIF

         /* Check for while condition */
            IF Empty( aInfo[INDEXINFO][I][4] )
               bWhile := nil
            else
               bWhile := &("{||"+AllTrim(aInfo[INDEXINFO][I][4])+"}")
            ENDIF

         /* Set the order condition */
            OrdCondSet( cFor, ;
               bFor,, ;
               bWhile,;
               bEval,, ;
               RECNO(),,,, ;
               aInfo[INDEXINFO][I][6] )

         /* Create the index and the tags if any */
            OrdCreate(cBagName ,cTag,;
               cExp , ;
               bExp, ;
               aInfo[INDEXINFO][I][5] )
         NEXT

      /* If we open the file we close it before we leave
         if lNew
            (cFileName)->( DBCloseArea() )
         endif
         */
      ENDIF

   /* Lets recover from the error */
   Recover Using bError
      Tone(3000,6)                               //hpg tone for now
   End Sequence

   /* We set the error back to its orginal form */
   ErrorBlock( bErrorBlock )
   IF !lIndexOnly .AND. MessageBox("The File has been created ;"+;
         "Would you like to enter new data?",;
         {"Yes","No"}, "Yes" ) == 1
      /*
      if lNew
         DBUseArea( .T., aInfo[RDDSET], cFileName, , .F.)
      endif
      */
      IF !lTag
         FOR i := 1 TO Len(aInfo[INDEXINFO])
            //    OrdListAdd(aInfo[INDEXINFO][I][1])
            OpenIdx( aInfo[INDEXINFO][I][1])
         NEXT
      ENDIF
      FormView(.T.)
      /*
      if lNew
         (cFileName)->( DBCloseArea() )
      endif
      */
   ENDIF
RETURN .T.
