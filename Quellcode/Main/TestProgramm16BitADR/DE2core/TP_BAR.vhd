---------------------------------------------------------------------------------------
-- Funktion :     Analoge Aussteuerungsanzeige
-- Filename :     TP_BAR.VHD
-- Beschreibung : Erzeugung eines 32 Pixel breiten, vertikalen Balkens, dessen Länge
--				  dem EingangswertSIG entspricht. Standardmäßig ist eine Ausgabe im
--				  Bereich von 0 - 255 möglich.
--				  SENSOR_ON ist gleich 1, wenn PIX_X, PIX_Y im Sensorbereich liegen.
--				  BAR_ON signalisiert den ausgesteuerten Bereich.
--				  Die Farbe der Bereiche kann extern gesteuert werden.
-- Standard : 	VHDL 1993
-- Komponenten:	
-- Author : 	Ulrich Sandkuehler
-- Revision : 	Version 1.0 10.06.2009
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;         -- Bibliotheken fuer numerische Operationen
use ieee.std_logic_unsigned.all;

entity TP_BAR is
	generic(N : positive := 8);			-- Stellenzahl
	port (	CLOCK			: in std_logic;						-- Pixeltakt
			SIG				: in std_logic_vector(N-1 downto 0);-- Signalwert
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			SENSOR_ON, BAR_ON  : out std_logic);				-- Sensorbereich
end entity TP_BAR;

architecture VERHALTEN of TP_BAR is
signal SIZE, LENG, SIG1 : std_logic_vector(9 downto 0);		-- Balkenbreite /- Länge

begin
SIZE   <= conv_std_logic_vector(32, 10);	-- Balkenbreite
LENG   <= conv_std_logic_vector(2**N, 10);	-- Balkenlänge
SIG1   <= "00" & SIG;						-- dargestellter Signalwert

-- Setzen von SENSOR_ON ='1', um den rechteckigen Sensorbereich zu kennzeichnen:
SENSOR_BAR: process (CLOCK)
begin
   if (PIX_X >  POS_X)  	  and  -- linke Balkenkante
      (PIX_X <= POS_X + SIZE) and  -- reche Balkenkante
      (PIX_Y >  POS_Y - LENG) and  -- obere Balkenkante
      (PIX_Y <= POS_Y)		  then -- untere Balkenkante
       SENSOR_ON <= '1';      else  SENSOR_ON <= '0';	-- Sensor Aktivität
   end if;
	
   if (PIX_X >  POS_X)  	  and  -- linke Balkenkante
      (PIX_X <= POS_X + SIZE) and  -- reche Balkenkante
      (PIX_Y >  POS_Y - SIG1) and  -- untere Balkenkante
      (PIX_Y <= POS_Y) 		  then -- obere Balkenkante
       BAR_ON <= '1';      	  else  BAR_ON <= '0';	-- Aussteuerung
   end if;
end process SENSOR_BAR;
end VERHALTEN;		