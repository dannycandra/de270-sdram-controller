---------------------------------------------------------------------------
-- Funktion     : Nachbildung eines virtuellen Potentiometers auf dem TP
-- Filename     : POTENTIOMETER.VHD
-- Beschreibung : Über ein virtuelles Schiebepotentiometer, welches auf
--                dem Touch Panel beliebig positioniert werden kann,
--				  wird durch verschieben eines Reiters ein 8 Bit Wert
--                generiert und ausgegeben.
-- Standard     : VHDL 1993
-- Revision     : Version 1.1 6.04.2009
---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;         -- Bibliotheken fuer numerische Operationen
use ieee.std_logic_unsigned.all;

entity POTENTIOMETER is
	port (	CLOCK			: in  std_logic;					-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Potentiometer Position
			WERT			: out std_logic_vector(7 downto 0);	-- Potentiometer Wert
			POTI_ON, REIT_ON: out std_logic);	-- Potentiometer und Schieberausgaben
end entity POTENTIOMETER;

architecture VERHALTEN of POTENTIOMETER is
signal SIZE, WERT1   : std_logic_vector(9 downto 0);

-- Alle darstellungsrelevanten Positionen auf dem TP:
type POSITION is array (1 to 6, 1 to 2) of integer;
constant POSI : POSITION := 
		 (( 0,   0),-- (1) obere  linke  Ecke oberer Balken      1-----
		 (31,   7), -- (2) untere rechte Ecke oberer Balken      -----2
		 (12,   7), -- (3) obere  linke  Ecke mittlerer Balken     3|
					--											   ||
					-- Länge des mittleren Balkens = 256 Pixel	   ||
					--											   ||
		 (19, 262), -- (4) untere rechte Ecke mittlerer Balken     |4
		 ( 0, 262), -- (5) linke  oberer Ecke unterer Balken     5-----
		 (31, 269));-- (6) rechte untere Ecke unterer Balken     -----6
begin
SIZE  <= conv_std_logic_vector(4,10);   -- Schieberhoehe

-- Setzen von POTI_ON = '1', um das Potentiometer darzustellen:
POTI_DISPLAY: process (CLOCK)
begin
if rising_edge(CLOCK) then
  if ((PIX_X >= POSI(1,1) + POS_X)	and -- oberer Querbalken
      (PIX_X <= POSI(2,1) + POS_X)	and
      (PIX_Y >= POSI(1,2) + POS_Y)	and
      (PIX_Y <= POSI(2,2) + POS_Y))	or

     ((PIX_X >= POSI(3,1) + POS_X)	and -- mittlerer Längsbalken
      (PIX_X <= POSI(4,1) + POS_X)	and
      (PIX_Y >= POSI(3,2) + POS_Y)	and
      (PIX_Y <= POSI(4,2) + POS_Y))	or

     ((PIX_X >= POSI(5,1) + POS_X)	and -- unterer Querbalken
      (PIX_X <= POSI(6,1) + POS_X)	and
      (PIX_Y >= POSI(5,2) + POS_Y)	and
      (PIX_Y <= POSI(6,2) + POS_Y))	then

       POTI_ON <= '1';				else
       POTI_ON <= '0';
  end if;
end if;
end process POTI_DISPLAY;

SCHIEBER_EINSTELLUNG: process (CLOCK)
variable PY : std_logic_vector(9 downto 0);
begin
if rising_edge(CLOCK) then
-- Stift innerhalb des Schieberbereichs des Potentiometerbereich
-- Begrenzung des Eingabebereichs und des Eingabewertes:
   if ((PEN_X >= POSI(1,1) + POS_X)	and
       (PEN_X <= POSI(2,1) + POS_X)	and
       (PEN_Y >= POSI(3,2) + POS_Y)	and
       (PEN_Y <= POSI(4,2) + POS_Y))	 then
	   if (PEN_Y > POSI(4,2) + POS_Y)    then -- obere Begrenzung
	       PY := conv_std_logic_vector(POSI(4,2)+POS_Y, 10);
	   elsif (PEN_Y < POSI(1,2) + POS_Y) then -- untere Begrenzung
	          PY := conv_std_logic_vector(POSI(3,2)+POS_Y, 10);
	   else   PY := PEN_Y;
	   end if;  
-- Umwandlung der Schieber/Stift-Position in einen 8 Bit Wert:
	 WERT1 <= conv_std_logic_vector(POS_Y+POSI(3,2)-1, 10) - PY;
     WERT  <= WERT1(7 downto 0);
   end if;

-- Setzen von REIT_ON = '1', um den Schiebereiter darzustellen:
   if ((PIX_X >= POSI(1,1) + POS_X)	and
	   (PIX_X <= POSI(2,1) + POS_X)	and
	   (PIX_Y >= PY - SIZE)			and
	   (PIX_Y <= PY + SIZE))		then
	    REIT_ON <= '1';				else
	    REIT_ON <= '0';
   end if;
end if;
end process SCHIEBER_EINSTELLUNG;
end VERHALTEN;