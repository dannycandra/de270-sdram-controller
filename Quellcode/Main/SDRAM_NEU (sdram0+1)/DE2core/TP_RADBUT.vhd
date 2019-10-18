----------------------------------------------------------------------------
-- Funktion :     Generierung einer Radio Button Leiste
-- Filename :     TP_RADBUT.vhd
-- Beschreibung : Erzeugung und Platzierung von 4 berührungsempfindlichen
--				  Radio Buttons, von denen immer nur ein Element als Schalter
--				  aktiv ist ( vor der ersten Berührung sind alle inaktiv).
-- Komponenten:	  TP_SENSOR.VHD
-- Standard : VHDL 1993
-- Author : Ulrich Sandkuehler
-- Revision : Version 1.2 20.05.2009
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;   -- Bibliotheken fuer numerische Operationen
use ieee.std_logic_unsigned.all;

entity TP_RADBUT is
	generic(N : positive := 4);				-- Anzahl der Radio Buttons
	port(CLOCK		  : in  std_logic;						-- Pixeltakt
		 PIX_X, PIX_Y : in std_logic_vector(9 downto 0);	-- Pixelpositionen
		 PEN_X, PEN_Y : in std_logic_vector(9 downto 0);	-- Stiftpositionen
		 POS_X, POS_Y : in integer;							-- Sensor Position
		 SENSOR_ON	  : out std_logic_vector(N-1 downto 0);	-- Sensorbereich
		 BUTTON 	  : out std_logic_vector(N-1 downto 0));-- Schalterausgaben
end TP_RADBUT;

architecture BEHAVIOR of TP_RADBUT is
constant ABSTAND : integer := 40;					-- Abstand der Radio Buttons
signal KEY : std_logic_vector(N-1 downto 0);

component TP_SENSOR is			-- KOMPONENTE FÜR BERÜHRUNGSEMPFINDLICHE SENSOREN:
	generic(N : positive := 32);			-- Größe des Sensorbereich in Pixel
	port (	CLOCK			: in  std_logic;					-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			SENSOR_ON		: out std_logic;					-- Sensorbereich
			SW_AKT, KEY_AKT : out std_logic);					-- Schalterausgaben
end component TP_SENSOR;

begin
SCHLEIFE:	-- Erzeugung aller Sensoren:
for l in 0 to N-1 generate
	SENSORS: TP_SENSOR
	generic map(N => 32)						-- Sensorgröße
	port map(CLOCK => CLOCK,					-- Pixeltakt
			 PIX_X => PIX_X,					-- Pixelposition X
			 PIX_Y => PIX_Y,					-- Pixelposition Y
			 PEN_X => PEN_X,					-- Stiftposition X
			 PEN_Y => PEN_Y,					-- Stiftposition Y
			 POS_X => POS_X + l * ABSTAND,		-- Sensorposition X
			 POS_Y => POS_Y, 					-- Sensorposition Y
			 SENSOR_ON => SENSOR_ON(l),			-- Sensor aktiv
			 SW_AKT    => open,					-- Schalter
			 KEY_AKT   => KEY(l)); 				-- Taster
end generate;

process(CLOCK)		-- Sicherstellung, dass nur immer ein Schalter aktiv ist:
variable BUT : std_logic_vector(N-1 downto 0);
begin
	for k in 0 to N-1 loop
		if (KEY(k) = '1') then BUT := (k => '1', others => '0');
						  else null;
		end if;
	end loop;
BUTTON <= BUT;
end process;
end BEHAVIOR;