---------------------------------------------------------------------------------------
-- Funktion : 	  Virtueller Schalter/Taster für das Touch Panel mit Symbolausgabe
-- Filename : 	  TP_SYMBOL.VHD
-- Beschreibung : Erzeugung eines 2**N x 2**N Pixel großen Bereichs zur Ausgabe zweier
--				  Symbole, zwischen denen bei Berührung hin und hergeschaltet wird, so
--				  dass eine Schalter-/Tasteraktivität ausgegeben wird.
--				  Die Farbe von Zeichen und Hintergrund muss extern gesteuert
--				  werden.
-- Standard : 	VHDL 1993
-- Komponenten:	SYMBOL_N.VHD
-- Author : 	Ulrich Sandkuehler
-- Revision : 	Version 1.2 15.04.2009
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;         -- Bibliotheken fuer numerische Operationen
use ieee.std_logic_unsigned.all;

entity TP_SYMBOL is
	generic(N 	  : positive := 6;			 	-- Pixel Adressbreite der Symboldatei
			DATEI : string := "SMILY.mif");  	-- Symboldatei
	port (	CLOCK			: in std_logic;						-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			SW_AKT, KEY_AKT, SIGN_ON, BACK_ON: out std_logic);	-- Text und Schalterausgaben
end entity TP_SYMBOL;

architecture VERHALTEN of TP_SYMBOL is
signal KX, KY : std_logic_vector(9 downto 0);

component SYMB_ROM is
	generic(N 	  : positive := 6;
			DATEI : string := "SMILY.mif");
	port(CLOCK				: in 	std_logic;
		 symb_address		: in	std_logic;
		 font_row, font_col	: in 	std_logic_vector(N-1 downto 0);
		 rom_mux_output	    : out	std_logic);
end component SYMB_ROM;

signal SIZE : std_logic_vector(9 downto 0);
signal SW, KEY : std_logic;
begin

SIZE <= conv_std_logic_vector(2**N, 10);
KX   <= conv_std_logic_vector(POS_X, 10);	--Korrekturwert der X-Position
KY   <= conv_std_logic_vector(POS_Y, 10);	--Korrekturwert der X-Position

SW_AKT <= SW;	-- Hilfsgröße für Schalteraktivität

-- Bei der ASCII Zeichendarstellung muss die Periodizität von 32 Pixeln
-- berücksichtigt werden. Dies erfordert eine Positionskorrektur: 
SYMBOL1: SYMB_ROM
generic map(N 	  => 6,
			DATEI => DATEI)
port map(CLOCK => CLOCK,
		 symb_address	=>  SW,						-- Symbolauswahl
		 font_row => PIX_Y(N-1 downto 0)-KY(N-1 downto 0),	--Korrektur Y
		 font_col => PIX_X(N-1 downto 0)-KX(N-1 downto 0),	--Korrektur X
		 rom_mux_output => SIGN_ON);

-- Setzen von BACK_ON ='1' um Hintergrund darzustellen:
SENSOR_BACKGROUND: process (CLOCK)
begin
if rising_edge(CLOCK) then
   if (PIX_X >  POS_X)  	  and  -- linke Kante
      (PIX_X <= POS_X + SIZE) and  -- reche Kante
      (PIX_Y >  POS_Y)     	  and  -- obere Kante
      (PIX_Y <= POS_Y + SIZE) then -- untere Kante
       BACK_ON <= '1';        else  BACK_ON <= '0';
	end if;
end if;
end process SENSOR_BACKGROUND;

-- Virtueller Taster:
KEY_PROC: process(CLOCK)
variable PEN_NEW, PEN_OLD : std_logic_vector(19 downto 0);
variable CNT : std_logic_vector(19 downto 0); 
variable AKT : std_logic;
begin
-- Wenn der Stift innerhalb des Frames eine neue Position hat, wechselt "AKTIV"
-- von '0' auf '1' und fällt nach 0,1 Sekunden wieder auf '0' ab.	
	if rising_edge(CLOCK) then
		CNT := CNT+1;
		if (CNT = 1000000) then -- Zeitverzögerung
			CNT := (others => '0');
			PEN_NEW := PEN_X & PEN_Y; 
			if (not (PEN_OLD = PEN_NEW)) and 				--neue Position?
			   (PEN_X >= POS_X) and (PEN_X <= POS_X + SIZE) and --im Frame?
			   (PEN_Y >= POS_Y) and (PEN_Y <= POS_Y + SIZE) then				
				AKT := '1';		else							
			 	AKT := '0';							-- Rücksetzen				
		    end if;
			PEN_OLD:= PEN_NEW;
		end if;	
		KEY_AKT <= AKT;
		KEY <= AKT;
	end if;
end process KEY_PROC;

-- Virtueller Schalter
SW_PROC: process(KEY)
begin
	if rising_edge(KEY) then SW <= not SW;	-- Toggeln Schalter
	end if;
end process SW_PROC;
end VERHALTEN;		