REM Bomberman
REM Original game by Hudson Soft 1987
REM BBC Micro version by picosonic 2023
:
REM Instructions from English NES manual
REM   contributed by Mick Brown
:
REM Check for TUBE
IF INKEY-256 A%=&EA:X%=0:Y%=&FF:IF USR(&FFF4) AND&FF00 THEN VDU26,12:PRINT"Please turn your TUBE off, and restart":END
:
*FX200,3
MODE7:VDU23;8202;0;0;0;
:
PROCPAGE1
PROCPAGE2
PROCPAGE3
PROCPAGE4
PROCPAGE5
:
CLS:*FX200,3
:
REM Disable ESC processing
*FX229,1
:
MODE2
VDU23,1,0;0;0;0;:REM Hide cursor
*L.LOADSCR
*FX15
A=INKEY(500)
:
MODE1
VDU23,1,0;0;0;0;:REM Hide cursor
VDU19,0,0;0;19,1,0;0;19,2,0;0;19,3,0;0;:REM Blank palette
:
REM Sideways RAM loader
DIM code 80
swrpage=&100
swrtest=&2900
swrcopy=&2928
CALL swrtest
IF ?swrpage=255 MODE7:PRINT"No sideways RAM detected":END
*L.BDATA
CALL swrcopy
:
REM Load extra datafile
*L.EXTRA
:
REM Load and run main game file
*/BBM
END
:
DEFPROCPAGE1
PROCBOMB
PRINT'CHR$(129)"GAME STORY:"
PRINT" Bomberman is a robot engaged in the     production of bombs. Like his fellow    robots, he had been put to work in an   underground compound by evil forces."
PRINT" Bomberman found it to be an unbearably  dreary existence. One day, he heard an  encouraging rumor. According to the     rumor, any robot that could escape the  underground compound and make it to the";
PRINT" surface could become human. Bomberman   leaped at the opportunity, but escape   proved to be no small task. Alerted to  Bomberman's betrayal, large numbers of  the enemy set out in pursuit."
PRINT" Bomberman can rely only on bombs of his own production for his defence. Will he ever make it up to the surface? Once    there, will he really become human?"
*FX200,2
PROCSPACE
ENDPROC
:
DEFPROCPAGE2
PROCBOMB
PRINT'CHR$(129)"HOW TO PLAY THE GAME:"
PRINT" Bomberman's goal is to reach the        surface of the earth. However, his      initial point of departure is deep in   the bowel of the earth, so Bomberman    must search for exitways and make his"
PRINT" way upwards, level by level. Of course, enemy forces are lurking throughout the labyrinth, and Bomberman must overcome  each and everyone in order to advance   to the next level. If he should touch"
PRINT" any of the enemy or be caught in the    flames of exploding bombs, he's out for the count, so extreme caution is urged.";
PRINT" The exitways are concealed among the    brick walls and can only be found by    dissolving bricks by the flames of      exploding bombs, also concealed are     "CHR$(162)"power-up"CHR$(162)" panels for increased power."
PROCSPACE
ENDPROC
:
DEFPROCPAGE3
PROCBOMB
PRINT'CHR$(129)"BOMBS:"CHR$(135)"In the earliest stage of the     game, only one bomb can be set at a     time and it has very weak firepower."
PRINTCHR$(129)"BRICKS:"CHR$(135)"These dissolve when hit by the  flames of exploding bombs. Hidden       within the bricks are exitways and      "CHR$(162)"power-up"CHR$(162)" panels, so it wise to bomb   out as many bricks as possible."
PRINTCHR$(129)"CONCRETE:"CHR$(135)"Concrete walls aren't damaged by bomb fires, so Bomberman can take    shelter from exploding bombs."
PRINTCHR$(129)"EXITWAYS:"CHR$(135)"These are to be found among   the bricks. After overcoming all        enemies, Bomberman stands over the      exitways to proceed to the next level."
PRINTCHR$(129)CHR$(162)"POWER-UP"CHR$(162)" PANELS:"CHR$(135)"There are several    different types with different effects. There are levels that cannot be cleared if Bomberman does not collect enough."
PROCSPACE
ENDPROC
:
DEFPROCPAGE4
PROCBOMB
PRINT'CHR$(129)"ENEMY CHARACTERS:"
PRINT" There are 8 types of enemy characters."
PRINT" Each type moves in its own particular   fashion, so it's wise to learn their    moves. If all enemies on a single level can be knocked out by 7 bombs, a        player's scores will increase greatly."
PRINT'CHR$(131)" VALCOM"CHR$(129)"(100pts)"CHR$(131)"     O'NEAL "CHR$(129)"(200pts) "CHR$(131)" DAHL  "CHR$(129)"(400pts)"CHR$(131)"     MINVO  "CHR$(129)"(800pts)   "
PRINTTAB(0,13)CHR$(131)" OVAPE"CHR$(129)"(1000pts)"CHR$(131)"     DORIA "CHR$(129)"(2000pts) "CHR$(131)" PASS "CHR$(129)"(4000pts)"CHR$(131)"     PONTAN"CHR$(129)"(8000pts) "
PRINTCHR$(129)"BONUS LEVELS:"
PRINT" A bonus level is awarded after the      consective five levels are cleared. The objective on bonus level is to take out as many enemies as possible within a    limited time."
PRINT'SPC6CHR$(129)"Press"CHR$(131)"SPACE BAR"CHR$(129)"to continue."
PROCSPACE
ENDPROC
:
DEFPROCPAGE5
PROCBOMB
PRINT'CHR$(129)"CONTROL FUNCTIONS:"
PRINT'CHR$(131)"     *"CHR$(135)"moves Bomberman"CHR$(129)"up"
PRINTCHR$(131)"     ?"CHR$(135)"moves Bomberman"CHR$(129)"down"
PRINTCHR$(131)"     Z"CHR$(135)"moves Bomberman"CHR$(129)"left"
PRINTCHR$(131)"     X"CHR$(135)"moves Bomberman"CHR$(129)"right"
PRINTCHR$(131)" SPACE"CHR$(135)"lays down a"CHR$(129)"bomb."CHR$(135)"This key is     also used when you pick up the remote   controlling explosion panel."
PRINTCHR$(131)"RETURN"CHR$(135)"to"CHR$(129)"pause"CHR$(135)"the game. To"CHR$(129)"start"CHR$(135)"the  game, simply press"CHR$(131)"RETURN"CHR$(135)"again."
PRINTCHR$(131)"ESCAPE"CHR$(135)"quits the game."
PRINT'CHR$(129)"TITLE SCREEN CONTROLS:"
PRINT'" Choose"CHR$(129)"START"CHR$(135)"or"CHR$(129)"CONTINUE"CHR$(135)"using"CHR$(131)"SPACE.  "CHR$(135)"If you press"CHR$(129)"START,"CHR$(135)"the game will start from screen 1. If"CHR$(129)"CONTINUE"CHR$(135)"is selected, use a code to start a previous screen."
PROCSPACE
ENDPROC
:
DEFPROCBOMB
PRINTTAB(14,0)CHR$(141)CHR$(131)"BOMBERMAN"
PRINTTAB(14,1)CHR$(141)CHR$(129)"BOMBERMAN"
ENDPROC
:
DEFPROCSPACE
*FX15,0
PRINTTAB(6,23)CHR$(129)"Press"CHR$(131)"SPACE BAR"CHR$(129)"to continue."
REPEATUNTILGET=32:CLS
ENDPROC
