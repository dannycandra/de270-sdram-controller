--------------------------------------------------------------------------
-- Funktion :     Generierung eines hexadezimalen Keypads
-- Filename :     TP_HEX.vhd
-- Beschreibung : Erzeugung und Platzierung eines Keypads aus 4 x 4
--				  berührungsempfindlichen Elementen (TP_SENSOR.VHD).
--				  Jedes Element arbeitet gleichzeitig als Schalter und als
--				  Taster. Der betätigte Schalter ändert dabei seine Farbe.
--				  Zusätzlich werden die Schalterfunktionen durch rote LEDs
--				  angezeigt.
-- Komponenten:	  TP_SENSOR.VHD, HEX_ROM16.VHD
-- Standard : VHDL 1993
-- Author : Ulrich Sandkuehler
-- Revision : Version 1.2 14.04.2009
--------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;   -- Bibliotheken fuer numerische Operationen
use ieee.std_logic_unsigned.all;

entity TP_HEXPAD is
	port(CLOCK		  : in  std_logic;						-- Pixeltakt
		 PIX_X, PIX_Y : in std_logic_vector(9 downto 0);	-- Pixelpositionen
		 PEN_X, PEN_Y : in std_logic_vector(9 downto 0);	-- Stiftpositionen
		 POS_X, POS_Y : in integer;							-- Sensor Position
		 TEXT_ON	  : out std_logic;
		 SENSOR_ON	  : out std_logic_vector(15 downto 0);	-- Sensorbereich
		 SW, KEY 	  : out std_logic_vector(15 downto 0));	-- Schalterausgaben
end TP_HEXPAD;

architecture BEHAVIOR of TP_HEXPAD is

-- Video Display Signals:
signal SEN_ON	 : std_logic_vector(15 downto 0);
signal ROW, COL  : std_logic_vector(3 downto 0); 	-- Zeile/Spalte für CHAR_ROM
signal TXT 		 : std_logic_vector(3 downto 0);	-- dargestelltes Zeichen
constant ABSTAND : integer := 40;

component TP_SENSOR is			-- KOMPONENTE FÜR BERÜHRUNGSEMPFINDLICHE SENSOREN:
	generic(N : positive := 32);			-- Größe des Sensorbereich in Pixel
	port (	CLOCK			: in  std_logic;					-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			SENSOR_ON		: out std_logic;					-- Sensorbereich
			SW_AKT, KEY_AKT : out std_logic);					-- Schalterausgaben
end component TP_SENSOR;

component HEX_ROM16 is			-- KOMPONENTE ZUR GENERIERUNG DER HEX ZEICHEN:
	port(clock				: in std_logic;						-- Pixeltakt
		 character_address	: in std_logic_vector(3 downto 0);	-- HEX Zeichen
		 font_row, font_col	: in std_logic_vector(3 downto 0);	-- Pixeladresse
		 rom_mux_output	    : out std_logic);					-- Pixelwert (0/1)
end component HEX_ROM16;

begin
HEX_AUSGABE: HEX_ROM16					-- CHAR_ROM Aufruf
port map(clock				=> CLOCK,	-- Pixeltakt
		 character_address 	=> TXT,		-- HEX Zeichen Auswahl
		 font_row 			=> ROW,		-- Pixeladresse Zeile
		 font_col 			=> COL,		-- Pixeladresse Spalte
		 rom_mux_output 	=> TEXT_ON);-- Pixelwert (0/1)

-- Definition aller Sensordarstellungen, deren Farben und Symbole.
-- Die Symbole werden in doppelter Größe dargestellt:
process(CLOCK)
variable KX, KY : std_logic_vector(9 downto 0);	-- Pos.Korrektur der ASCII Zeichen
variable POS_SENX, POS_SENY : integer;
begin
if rising_edge(CLOCK) then
  for k in 0 to 3 loop						    -- Scheifen für 4 x 4 Sensoren
    for l in 0 to 3 loop
	   if(SEN_ON(4*k+l) = '1') then 			  -- Aktiver Sensorbereich
       POS_SENX := POS_X + l * ABSTAND;			  -- Tasterposition in X
       POS_SENY := POS_Y + k * ABSTAND;			  -- Tasterposition in Y
	   KX  := conv_std_logic_vector(POS_SENX, 10);-- Korrekturwert der X-Position
       KY  := conv_std_logic_vector(POS_SENY, 10);-- Korrekturwert der Y-Position
       COL <= PIX_X(4 downto 1)-KX(4 downto 1);	  -- Korrektur X & doppelte Größe
       ROW <= PIX_Y(4 downto 1)-KY(4 downto 1);	  -- Korrektur Y & doppelte Größe
       TXT <= conv_std_logic_vector(4*k+l, 4);	  -- Sensor HEX-Symbol
       end if;
    end loop;
  end loop;
end if;
end process;

SCHLEIFE:	-- Erzeugung aller Sensoren:
for k in 0 to 3 generate
	SCHLEIFE2:
	for l in 0 to 3 generate
		SENSORS: TP_SENSOR
		generic map(N => 32)						-- Sensorgröße
		port map(CLOCK => CLOCK,					-- Pixeltakt
				 PIX_X => PIX_X,					-- Pixelposition X
				 PIX_Y => PIX_Y,					-- Pixelposition Y
				 PEN_X => PEN_X,					-- Stiftposition X
				 PEN_Y => PEN_Y,					-- Stiftposition Y
				 POS_X => POS_X + l * ABSTAND,		-- Sensorposition X
				 POS_Y => POS_Y + k * ABSTAND, 		-- Sensorposition Y
				 SENSOR_ON => SEN_ON(4*k+l),		-- Sensor aktiv
				 SW_AKT    => SW(4*k+l),			-- Schalter
				 KEY_AKT   => KEY(4*k+l)); 			-- Taster
	end generate;
end generate;
SENSOR_ON <= SEN_ON;
end BEHAVIOR;