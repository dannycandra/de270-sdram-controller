---------------------------------------------------------------------------------------
-- Funktion :     Virtueller Schalter / Taster für das Touch Panel
-- Filename :     TP_SENSOR.VHD
-- Beschreibung : Erzeugung eines N x N Pixel großen, berührungsempfindlichen Bereichs
--				  so dass eine Schalter-/Tasteraktivität ausgegeben wird.
--				  SENSOR_ON ist gleich 1, wenn PIX_X, PIX_Y im Sensorbereich liegen.
--				  Die Farbe des Bereichs kann extern gesteuert werden.
-- Standard : 	VHDL 1993
-- Komponenten:	
-- Author : 	Ulrich Sandkuehler
-- Revision : 	Version 1.4 14.04.2009
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;         -- Bibliotheken fuer numerische Operationen
use ieee.std_logic_unsigned.all;

entity TP_SENSOR is
	generic(N : positive := 32);			-- Größe des Sensorbereich in Pixel
	port (	CLOCK			: in  std_logic;					-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			SENSOR_ON		: out std_logic;					-- Sensorbereich
			SW_AKT, KEY_AKT : out std_logic);					-- Schalterausgaben
end entity TP_SENSOR;

architecture VERHALTEN of TP_SENSOR is

signal SIZE : std_logic_vector(9 downto 0);		-- Sensorgröße
signal SW, KEY : std_logic;						-- Schalter / Taster Zustand
begin

SIZE   <= conv_std_logic_vector(N, 10);	-- Sensorgröße
SW_AKT <= SW;							-- Hilfsgröße für Schalteraktivität

-- Setzen von SENSOR_ON ='1', um den rechteckigen Sensorbereich zu kennzeichnen:
SENSOR_BACKGROUND: process (CLOCK)
begin
   if (PIX_X >  POS_X)  	  and  -- linke Kante
      (PIX_X <= POS_X + SIZE) and  -- reche Kante
      (PIX_Y >  POS_Y)     	  and  -- obere Kante
      (PIX_Y <= POS_Y + SIZE) then -- untere Kante
       SENSOR_ON <= '1';      else  SENSOR_ON <= '0';	-- Sensor Aktivität
	end if;
end process SENSOR_BACKGROUND;

-- VIRTUELLER TASTER:
KEY_PROC: process(CLOCK)
variable PEN_NEW, PEN_OLD : std_logic_vector(19 downto 0);	-- Stiftpositionen
variable CNT : std_logic_vector(19 downto 0); 				-- Delay Counter
variable AKT : std_logic;
begin
-- Wenn der Stift innerhalb des Frames eine neue Position hat, wechselt "AKTIV"
-- von '0' auf '1' und fällt nach 0,1 Sekunden wieder auf '0' ab.	
	if rising_edge(CLOCK) then
		CNT := CNT+1;
		if (CNT = 1000000) then 			-- Zeitverzögerung (Delay Counter)
			CNT := (others => '0');
			PEN_NEW := PEN_X & PEN_Y; 		-- Stiftpositionen
			if (not (PEN_OLD = PEN_NEW)) and 					--neue Position?
			   (PEN_X >= POS_X) and (PEN_X <= POS_X + SIZE) and --im Frame?
			   (PEN_Y >= POS_Y) and (PEN_Y <= POS_Y + SIZE) then				
				AKT := '1';		else				-- Positiver Taster Impuls			
			 	AKT := '0';							-- Rücksetzen				
		    end if;
			PEN_OLD:= PEN_NEW;						-- alte Stiftposition merken
		end if;	
		KEY_AKT <= AKT;								-- Ausgabe Tasterimpuls
		KEY <= AKT;					-- Nutzung des Tastimpulses für Schalter
	end if;
end process KEY_PROC;

-- VIRTUELLER SCHALTER:
SW_PROC: process(KEY)
begin
	if rising_edge(KEY) then SW <= not SW;	-- Toggeln Schalter
	end if;
end process SW_PROC;
end VERHALTEN;		