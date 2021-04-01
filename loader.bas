REM BBM Loader
:
REM Check for TUBE
IF INKEY-256 A%=&EA:X%=0:Y%=&FF:IF USR(&FFF4) AND&FF00 THEN VDU26,12:PRINT"Please turn your TUBE off, and restart":END
:
REM Load loading screen
*FX229,1
MODE2
VDU23,1,0;0;0;0;:REM Hide cursor
*L.LOADSCR
*FX15
REPEATUNTILGET<>&FF
:
MODE1
VDU23,1,0;0;0;0;:REM Hide cursor
VDU19,1,0;0;19,2,0;0;19,3,0;0;19,4,0;0;:REM Blank palette
:
REM Load extra datafile
*L.EXTRA
:
REM Load and run main game file
*/BBM
