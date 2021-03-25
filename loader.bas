REM BBM Loader
:
REM Initialise "MODE 8" 256x224
MODE1
VDU23,1,0,0,0,0,0,0,0,0:REM Hide cursor
?&FE00=1:?&FE01=64:REM Set 256 pixels wide
?&FE00=2:?&FE01=89:REM Centre horizontally
?&FE00=6:?&FE01=28:REM Set 224 pixels high
?&FE00=7:?&FE01=33:REM Centre vertically
?&FE00=13:?&FE01=0:?&FE00=12:?&FE01=9:REM Change screen start address to &4800
:
REM Load datafiles
*L.TITLE
*L.TILES
*L.SPRITES
*L.TUNES
*L.EXTRA
:
REM Define envelope
ENVELOPE 1,2,0,0,0,0,0,0,60,-4,-4,-4,60,30:REM "Marimba"
:
REM Load and run main game file
*/BBM
