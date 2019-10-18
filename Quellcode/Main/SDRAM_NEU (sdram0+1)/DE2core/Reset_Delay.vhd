-----------------------------------------------------------------------------
--Dateiname: 	  Reset_Delay.vhd	
--Autor: 		  Christoph Kozicki, Matr.Nr. 10005775	
--Beschreibung:   Zeitverzögerung bei Reset	 
--Datum:		  9. Januar 2009
--Abhängigkeiten: keine 
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY Reset_Delay IS
	PORT (	iCLK, iRST			 : IN  STD_LOGIC;
			oRST_0,oRST_1,oRST_2 : OUT STD_LOGIC);
END ENTITY Reset_Delay;

ARCHITECTURE verhalten OF Reset_Delay IS
BEGIN
	
p1: PROCESS(iCLK, iRST)
VARIABLE Cont : INTEGER RANGE 0 TO 4194303; 
BEGIN
	IF(iRST = '0') THEN --Ausgänge oRST_x bleiben bis zum nächsten Reset bei '1'
		Cont	:=	 0 ;
		oRST_0	<=	'0';
		oRST_1	<=	'0';
		oRST_2	<=	'0';
	ELSIF RISING_EDGE(iCLK) THEN
		IF (NOT(Cont = 4194303)) THEN
			Cont	:=	Cont+1;
		ELSIF(Cont >= 2097151) THEN --42ms
			oRST_0	<=	'1'; 
		ELSIF(Cont >= 3145727) THEN --63ms
			oRST_1	<=	'1';
		ELSIF(Cont >= 4194303) THEN --84ms
			oRST_2	<=	'1';
		END IF;
	END IF;
END PROCESS p1;	
	
END verhalten;		