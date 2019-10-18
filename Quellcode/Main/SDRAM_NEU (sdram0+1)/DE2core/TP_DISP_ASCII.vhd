----------------------------------------------------------------------------
-- Funktion :     Platzierung einer N-stelligen ASCII Zeichenausgabe
-- Filename :     TP_DISP_ASCII.vhd
-- Beschreibung : Positionierte Ausgabe von N ASCII Zeichen auf dem TP.
--				  Die Zeichen werden im 8 Bit Format entsprechend der 7 Bit
--				  ASCII Tabelle eingegeben, wobei das MSB nicht genutzt wird.
--				  Dementsprechend können 128 verschiedene Zeichen dargestellt
--				  werden. Die Darstellung erfolgt in doppelter Größe (32 x 32)
--				  Pixel, indem jeweils 2 x 2 Pixel zusammengefasst werden.
-- Komponenten:	  ASCII_ROM16.VHD
-- Standard : VHDL 1993
-- Author : Ulrich Sandkuehler
-- Revision : Version 1.2 7.07.2009
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;   -- Bibliotheken fuer numerische Operationen
use ieee.std_logic_unsigned.all;

entity TP_DISP_ASCII is
	generic(N : positive := 4);						-- Anzahl der ASCII Zeichen
	port(CLOCK		  : in  std_logic;						-- Pixeltakt
		 PIX_X, PIX_Y : in std_logic_vector(9 downto 0);	-- Pixelpositionen
		 POS_X, POS_Y : in integer;							-- Display Position
		 ZEICHEN	  : in std_logic_vector(0 to 8*N-1);    -- ASCII Zeichen
		 TEXT_ON	  : out std_logic;						-- Text Darstellung
		 DISPLAY_ON	  : out std_logic_vector(N-1 downto 0));-- Displaybereich
end TP_DISP_ASCII;

architecture BEHAVIOR of TP_DISP_ASCII is

-- Video Display Signals:
signal SIZE : std_logic_vector(9 downto 0);			-- Zeichengröße
signal ROW, COL  : std_logic_vector(3 downto 0); 	-- Zeile/Spalte für CHAR_ROM
signal TXT 		 : std_logic_vector(6 downto 0);	-- dargestelltes Zeichen
constant ABSTAND : integer := 32;					-- Zeichenabstand

component ASCII_ROM16 is		-- KOMPONENTE ZUR GENERIERUNG DER ASCII ZEICHEN:
	port(clock				: in std_logic;						-- Pixeltakt
		 character_address	: in std_logic_vector(6 downto 0);	-- ASCII Zeichen
		 font_row, font_col	: in std_logic_vector(3 downto 0);	-- Pixeladresse
		 rom_mux_output	    : out std_logic);					-- Pixelwert (0/1)
end component ASCII_ROM16;

begin
HEX_AUSGABE: ASCII_ROM16				-- CHAR_ROM Aufruf
port map(clock				=> CLOCK,	-- Pixeltakt
		 character_address 	=> TXT,		-- HEX Zeichen Auswahl
		 font_row 			=> ROW,		-- Pixeladresse Zeile
		 font_col 			=> COL,		-- Pixeladresse Spalte
		 rom_mux_output 	=> TEXT_ON);-- Pixelwert (0/1)

SIZE   <= conv_std_logic_vector(ABSTAND, 10);-- Zeichengröße

-- Definition aller Darstellungen, deren Farben und Zeichen.
-- Die Zeichen werden in doppelter Größe dargestellt:
process(CLOCK)
variable KX, KY : std_logic_vector(9 downto 0);	-- Pos.Korrektur der Zeichen
variable POS_XX : integer;						-- X-Position des Zeichens
variable DISP_ON: std_logic_vector (N-1 downto 0); -- Displaybereich
begin
if rising_edge(CLOCK) then
  for k in 0 to N-1 loop				    -- Scheife für N Zeichen
      POS_XX := POS_X + (N-1-k) * ABSTAND;	-- X-Position des ASCII Zeichens
      if (PIX_X >  POS_XX)  	   and      -- linke Kante
		 (PIX_X <= POS_XX + SIZE)  and      -- reche Kante
		 (PIX_Y >  POS_Y)     	   and      -- obere Kante
		 (PIX_Y <= POS_Y + SIZE)   then     -- untere Kante
		  DISP_ON(k) := '1';       else  DISP_ON(k) := '0';
	  end if;
	  
      if(DISP_ON(k) = '1') then 					--Aktiver Sensorbereich
	   KX  := conv_std_logic_vector(POS_XX, 10);	--Korrekturwert der X-Position
       KY  := conv_std_logic_vector(POS_Y, 10);		--Korrekturwert der Y-Position
       COL <= PIX_X(4 downto 1)-KX(4 downto 1);	    --Korrektur X & doppelte Größe
       ROW <= PIX_Y(4 downto 1)-KY(4 downto 1);		--Korrektur Y & doppelte Größe
       TXT <= ZEICHEN(8*N-7-8*k to 8*N-1-8*k);	    --Display ASCII Zeichen
       end if;
   end loop;
end if;
DISPLAY_ON <= DISP_ON;						-- Ausgabe des Displaybereichs
end process;
end BEHAVIOR;