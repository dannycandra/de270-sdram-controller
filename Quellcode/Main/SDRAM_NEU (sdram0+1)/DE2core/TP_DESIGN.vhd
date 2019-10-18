------------------------------------------------------------------------------
-- Funktion :   Platzierung eines Sensorelements
-- Filename :   TP_DESIGN.vhd
-- Beschreibung : Exemplarisches Programm, um ein Keypad mit hexadezimaler
--				  Eingabe (TP_HEXPAD.VHD), eine hexadezimale (TP_DISP_HEX.VHD)
--				  und eine ASCII (TP_DISP_ASCII.VHD) als Ausgabe Komponenten
--				  auf dem Touch Panel zu platzieren.
-- Komponenten:	  DE2_TOCHPANEL.VHD, TP_HEXPAD, TP_DISP_HEX.VHD, TP_SENSOR
--				  TP_DISP_ASCII.VHD, TP_SYMBOL, POTENTIOMETER, TP_RADBUT,
--				  TP_BAR
-- Standard : VHDL 1993
-- Author : Ulrich Sandkuehler
-- Revision : Version 1.6 7.07.2009
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;   -- Bibliotheken fuer numerische Operationen
use ieee.std_logic_unsigned.all;

entity TP_DESIGN is
port(GPIO_0 	: inout	std_logic_vector(35 downto 0); 	--Anschluss TP
	 CLOCK_50   : in std_logic;							--Systemtakt
	 LEDR		: out std_logic_vector (15 downto 0));	-- LEDs des DE2 Boards					
end TP_DESIGN;

architecture BEHAVIOR of TP_DESIGN is

-- Video Display Signals:
signal VGA_CLK : std_logic;							-- Pixeltakt, Poti Darstellung
signal REIT_ON, POTI_ON, BAR_ON : std_logic;		-- Poti- / Balkenanzeige
signal SW, KEY : std_logic_vector(15 downto 0);		-- Virtuelle Schalter/Taster
signal SENSOR_ON : std_logic_vector(47 downto 0);	-- Aktive TP Bereiche
signal TEXT_ON, TEXT_ON2, TEXT_ON3, TEXT_ON4 : std_logic;	-- Text Pixelausgabe
signal RGB	 : std_logic_vector(0 to 2);			-- Farbsteuerung
signal PENX, PENY : std_logic_vector(9 downto 0);	-- Pen Positionen
signal PIXX, PIXY : std_logic_vector(9 downto 0);	-- Pixelpositionen
signal POTI_WERT : std_logic_vector (7 downto 0);	-- Wert der Poti-Eingabe
signal BUTTON : std_logic_vector(3 downto 0);		-- Radio Buttons

component DE2_TOUCHPANEL is	-- Komponente zur Ansteuerung des Touch Panels
	port(GPIO_0 	: inout std_logic_vector (35 downto 0); --IDE-anschluss (JP1)
		 CLOCK_50	: in std_logic;  						-- Systemtakt
		 R, G, B	: in std_logic_vector(7 downto 0);		-- Farben			 
		 HOR_SYNC	: out std_logic; 						-- Vertikaltakt 
		 VERT_SYNC	: out std_logic; 						-- Vertikaltakt 
		 DEN		: out std_logic; 						-- Vertikaltakt 
		 PIX_CLK	: out std_logic; 						-- Pixeltakt
		 PIX_X,PIX_Y: out std_logic_vector(9 downto 0);  	-- Pixelposition
		 PEN_X,PEN_Y: out std_logic_vector(9 downto 0)); 	-- Stiftposition
end component;

component TP_HEXPAD is
	port (	CLOCK			: in  std_logic;					-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			TEXT_ON			: out std_logic;					-- Zeichenbereich
			SENSOR_ON		: out std_logic_vector(15 downto 0);-- Sensorbereich
			SW, KEY			: out std_logic_vector(15 downto 0));-- Schalterausgaben
end component TP_HEXPAD;

component TP_DISP_HEX is
	generic(N : positive := 4);						-- Anzahl der HEX Zeichen
	port(CLOCK		  : in  std_logic;						-- Pixeltakt
		 PIX_X, PIX_Y : in std_logic_vector(9 downto 0);	-- Pixelpositionen
		 POS_X, POS_Y : in integer;							-- Display Position
		 ZEICHEN	  : in std_logic_vector(4*N-1 downto 0);-- Display Zeichen
		 TEXT_ON	  : out std_logic;						-- Zeichenbereich
		 DISPLAY_ON	  : out std_logic_vector(N-1 downto 0));-- Displaybereich
end component TP_DISP_HEX;

component TP_DISP_ASCII is
	generic(N : positive := 4);						-- Anzahl der ASCII Zeichen
	port(CLOCK		  : in  std_logic;						-- Pixeltakt
		 PIX_X, PIX_Y : in std_logic_vector(9 downto 0);	-- Pixelpositionen
		 POS_X, POS_Y : in integer;							-- Display Position
		 ZEICHEN	  : in std_logic_vector(8*N-1 downto 0);-- Display Zeichen
		 TEXT_ON	  : out std_logic;						-- Zeichenbereich
		 DISPLAY_ON	  : out std_logic_vector(N-1 downto 0));-- Displaybereich
end component TP_DISP_ASCII;

component TP_SYMBOL is
	generic(N 	  : positive := 6;			 	-- Pixel Adressbreite der Symboldatei
			DATEI : string   := "SMILY.mif");  	-- Symboldatei
	port (	CLOCK			: in std_logic;						-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			SW_AKT, KEY_AKT, SIGN_ON, BACK_ON: out std_logic);	-- Text und Schalterausgaben
end component TP_SYMBOL;

component POTENTIOMETER is
	port (	CLOCK			: in  std_logic;					-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Potentiometer Position
			WERT			: out std_logic_vector(7 downto 0);	-- Potentiometer Wert
			POTI_ON, REIT_ON: out std_logic);	-- Potentiometer und Schieberausgaben
end component POTENTIOMETER;

component TP_SENSOR is
	generic(N : positive := 32);				-- Größe des Sensorbereich in Pixel
	port (	CLOCK			: in  std_logic;					-- Pixeltakt
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			PEN_X, PEN_Y	: in std_logic_vector(9 downto 0);	-- Stiftpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			SENSOR_ON		: out std_logic;					-- Sensorbereich
			SW_AKT, KEY_AKT : out std_logic);					-- Schalterausgaben
end component TP_SENSOR;

component TP_RADBUT is
	generic(N : positive := 4);					-- Anzahl der Radio Buttons
	port(CLOCK		  : in  std_logic;							-- Pixeltakt
		 PIX_X, PIX_Y : in std_logic_vector(9 downto 0);		-- Pixelpositionen
		 PEN_X, PEN_Y : in std_logic_vector(9 downto 0);		-- Stiftpositionen
		 POS_X, POS_Y : in integer;								-- Sensor Position
		 SENSOR_ON	  : out std_logic_vector(N-1 downto 0);		-- Sensorbereich
		 BUTTON 	  : out std_logic_vector(N-1 downto 0));	-- Schalterausgaben
end component TP_RADBUT;

component TP_BAR is
	generic(N : positive := 8);					-- Stellenzahl der Signaleingabe
	port (	CLOCK			: in std_logic;						-- Pixeltakt
			SIG				: in std_logic_vector(N-1 downto 0);-- Signalwert
			PIX_X, PIX_Y	: in std_logic_vector(9 downto 0);	-- Pixelpositionen
			POS_X, POS_Y 	: in integer;						-- Sensor Position
			SENSOR_ON, BAR_ON  : out std_logic);				-- Sensorbereich
end component TP_BAR;

begin
VGA_TP: DE2_TOUCHPANEL				-- Touch Panel Ausgabe
port map(GPIO_0 => GPIO_0,			-- Interface DE2 Board
		 CLOCK_50 => CLOCK_50,		-- Systemtakt
		 R	=> (others => RGB(0)),	-- Reduzierung der Farbe Rot auf 1 Bit
		 G	=> (others => RGB(1)),	-- Reduzierung der Farbe Rot auf 1 Bit
		 B	=> (others => RGB(2)),	-- Reduzierung der Farbe Rot auf 1 Bit
		 HOR_SYNC  => open,			-- nicht benötigt
		 VERT_SYNC => open,			-- nicht benötigt
		 DEN       => open,			-- nicht benötigt
		 PIX_CLK   => VGA_CLK,		-- Pixeltakt
		 PIX_X => PIXX,				-- Pixelposition X
		 PIX_Y => PIXY,				-- Pixelposition Y
		 PEN_X => PENX,				-- Stiftposition X
		 PEN_Y => PENY);			-- Stiftposition Y

HEXPAD: TP_HEXPAD						-- HEXADEZIMALES KEYPAD:
port map (	CLOCK		=> VGA_CLK,		-- Pixeltakt
			PIX_X		=> PIXX,		-- Pixelpositionen in X
			PIX_Y		=> PIXY,		-- Pixelpositionen in Y
			PEN_X		=> PENX,		-- Stiftpositionen in X
			PEN_Y		=> PENY,		-- Stiftpositionen in Y
			POS_X		=> 200,			-- Pad Position in Y
			POS_Y 		=> 200,			-- Pad Position in Y
			TEXT_ON		=> TEXT_ON,		-- Tastenbeschriftung
			SENSOR_ON	=> SENSOR_ON(15 downto 0),	-- Sensorbereich
			SW			=> SW, 			-- Tasteraktivitäten
			KEY		 	=> KEY);		-- Schalteraktivitäten
LEDR <= SW;

DISPLAY: TP_DISP_HEX					-- HEX - AUSGABE:
generic map(2)							-- Anzahl der ASCII Zeichen
port map(CLOCK			=> VGA_CLK,		-- Pixeltakt
		 PIX_X			=> PIXX,		-- Pixelpositionen in X
		 PIX_Y			=> PIXY,		-- Pixelpositionen in Y
		 POS_X			=> 550,			-- Display Position in X
		 POS_Y			=> 50,			-- Display Position in Y
		 ZEICHEN	  	=> POTI_WERT,	-- Display Zeichen
		 TEXT_ON	  	=> TEXT_ON2,	-- Zeichentext aktiv
		 DISPLAY_ON	  	=> SENSOR_ON(17 downto 16));-- Displaybereich

DISPLAY_ASCII: TP_DISP_ASCII		-- ASCII - AUSGABE:
generic map(8)						-- Anzahl der ASCII Zeichen
port map(CLOCK		=> VGA_CLK,		-- Pixeltakt
		 PIX_X		=> PIXX,		-- Pixelpositionen in X
		 PIX_Y		=> PIXY,		-- Pixelpositionen in Y
		 POS_X		=> 50,			-- Display Position in X
		 POS_Y		=> 50,			-- Display Position in Y
		 ZEICHEN	=> x"1D1C4506252B373A",	    -- ASCII Zeichen
		 TEXT_ON	=> TEXT_ON3,				-- Zeichen
		 DISPLAY_ON	=> SENSOR_ON(25 downto 18));-- Displaybereich

DISPLAY_SYMBOL: TP_SYMBOL			-- SMILY TASTER:
generic map(6,			 			-- Adressbreite der Symboldatei
			"SMILY.mif")  			-- Symboldatei
port map(	CLOCK	=> VGA_CLK,		-- Pixeltakt
			PIX_X	=> PIXX,		-- Pixelposition in X
			PIX_Y	=> PIXY,		-- Pixelposition in Y
			PEN_X	=> PENX,		-- Stiftposition in X
			PEN_Y	=> PENY,		-- Stiftposition in Y
			POS_X	=> 50,			-- Symbol Position in X
			POS_Y 	=> 200,			-- Symbol Position in Y
			SW_AKT	=> open,		-- Schalteraktivität
			KEY_AKT => open, 		-- Tasteraktivität
			SIGN_ON => TEXT_ON4,	-- Symbol
			BACK_ON => SENSOR_ON(26));	-- Symbol Hintergrund
			
DISPLAY_POTI: POTENTIOMETER			-- POTENTIOMETER:
port map(	CLOCK	=> VGA_CLK,		-- Pixeltakt
			PIX_X	=> PIXX,		-- Pixelposition in X
			PIX_Y	=> PIXY,		-- Pixelposition in Y
			PEN_X	=> PENX,		-- Stiftposition in X
			PEN_Y	=> PENY,		-- Stiftposition in Y
			POS_X	=> 550,			-- Poti Position in X
			POS_Y 	=> 100,			-- Poti Position in Y
			WERT	=> POTI_WERT,	-- Potentiometer Wert
			POTI_ON => POTI_ON,		-- Poti Ausgabe
			REIT_ON => REIT_ON);	-- Schieberausgabe

LEDs: for I in 1 to 16 generate		-- SCHLEIFE FÜR 16 LED
	DISPLAY_LEDS: TP_SENSOR			-- AUSGABEN des HEXPADs:
	generic map(N => 32) 		-- Größe des Sensorbereich in Pixel
	port map(CLOCK  => VGA_CLK,		-- Pixeltakt
			PIX_X	=> PIXX,		-- Pixelposition in X
			PIX_Y	=> PIXY,		-- Pixelposition in Y
			PEN_X	=> PENX,		-- Stiftposition in X
			PEN_Y	=> PENY,		-- Stiftposition in Y
			POS_X	=> 10 + 40*I,	-- Symbol Position in X
			POS_Y 	=> 410,			-- Symbol Position in Y
			SENSOR_ON => SENSOR_ON(26+I),	-- Sensorbereich
			SW_AKT	  => open,		-- Schalterausgaben
			KEY_AKT   => open);		-- Tasterausgaben
end generate;

RADIO_BUTTONS: TP_RADBUT			-- 4 RADIO BUTTONS:
	generic map (N => 4)			-- Anzahl der Radio Buttons
	port map(CLOCK	=> VGA_CLK,		-- Pixeltakt
			 PIX_X	=> PIXX,		-- Pixelposition in X
			 PIX_Y 	=> PIXY,		-- Pixelposition in Y
			 PEN_X	=> PENX,		-- Stiftposition in X
			 PEN_Y	=> PENY,		-- Stiftposition in Y
			 POS_X	=> 50,			-- Buttonleiste Position in X
			 POS_Y 	=> 120,			-- Buttonleiste Position in Y
			 SENSOR_ON	=> SENSOR_ON(46 downto 43),	-- Sensorbereich
			 BUTTON	=> BUTTON);		-- Radio Tasterausgaben

DISPLAY_BAR: TP_BAR					-- AUSSTEUERANZEIGE:
	generic map(N => 8)				-- Stellenzahl
	port map(CLOCK	=> VGA_CLK,		-- Pixeltakt
			 SIG	=> POTI_WERT,	-- Signalwert
			 PIX_X  => PIXX,		-- Pixelposition in X
			 PIX_Y	=> PIXY,		-- Pixelposition in Y
			 POS_X  => 680,			-- Balkenposition in X
			 POS_Y 	=> 350,			-- Balkenposition in Y
			 SENSOR_ON => SENSOR_ON(47), -- Sensorbereich
			 BAR_ON  => BAR_ON);	-- Balkenbereich
			 
-- Definition aller Sensordarstellungen, deren Farben und Symbole.
process(VGA_CLK)
variable RGB1 	: std_logic_vector(2 downto 0);	-- Farben

begin
if rising_edge(VGA_CLK) then
RGB1 := "001";								-- Hintergrundfarbe des TPs (blau)

-- Farbwerte für TP_HEXPAD:
	for k in 0 to 15 loop					-- Scheife für Hex Keypad
	if(SENSOR_ON(k) = '1') then 			-- Aktiver Sensorbereich
       if TEXT_ON = '1' then RGB1:="000";	-- Zeichenfarbe
       elsif SW(k)= '1' then RGB1:="100";	-- Toggeln der Sensorfarbe (Rot)
						else RGB1:="010";	-- (Grün)
	   end if;	   
    end if;
    end loop;

-- Farbwerte für TP_DISP_HEX zur Anzeige des Potiwerts (2-stellig):
	for k in 16 to 17 loop					-- Scheife für 2 Hex Zeichen
	if(SENSOR_ON(k) = '1') then 			-- Aktiver Sensorbereich
       if TEXT_ON2 = '1' then RGB1:="000";	-- Zeichenfarbe (Rot)
						 else RGB1:="100";	-- (Schwarz)
	   end if; 
    end if;
    end loop;

-- Farbwerte für TP_DISP_ASCII zur Anzeige von 8 ASCII Zeichen:
    for k in 18 to 25 loop					-- Scheife für 7 ASCII Zeichen
	if(SENSOR_ON(k) = '1') then 			-- Aktiver Sensorbereich
       if TEXT_ON3 = '1' then RGB1:="110";	-- Zeichenfarbe (Gelb)
						 else RGB1:="000";	-- (Schwarz)
	   end if; 
    end if;
    end loop;

-- Farbwerte für TP_SYMBOL (Virtueller Taster mit Smily):
	if(SENSOR_ON(26) = '1') then 			-- Aktiver Sensorbereich
       if TEXT_ON4 = '1' then RGB1:="100";	-- Zeichenfarbe (Rot)
						 else RGB1:="000";	-- (Schwarz)
	   end if;
	end if;

-- Farbwerte für TP_SENSOR zur Anzeige von 16 virtuellen LEDs:
    for k in 27 to 42 loop					-- Scheife für 16 LEDs
	if(SENSOR_ON(k) = '1') then 			-- Aktiver LED Bereich
       if SW(k-27) = '1' then RGB1:="110";	-- gelbe LED
						 else RGB1:="000";	-- (Schwarz)
	   end if; 
    end if;
    end loop;

-- Farbwerte für TP_RADBUT zur Anzeige von 4 Radio Schaltern:
    for k in 43 to 46 loop						-- Scheife für Radio Buttons
	if(SENSOR_ON(k) = '1') then 				-- Aktiver Radio Button
       if BUTTON(k-43) = '1' then RGB1:="010";	-- grüne LED
						     else RGB1:="100";	-- rote LED
	   end if; 
    end if;
    end loop;

-- Farbwerte zur Anzeige des Potentiometers:       	
	if POTI_ON = '1' then RGB1:="100"; end if;	-- Potifarbe (Rot)
	if REIT_ON = '1' then RGB1:="111"; end if;	-- Schieberfarbe (Weiss)
	
-- Farbwerte zur Anzeige Balkenaussteuerung:
	if BAR_ON = '1'  then RGB1:="110";			-- Austeuerbalken (Gelb)
	elsif SENSOR_ON(47) = '1' then RGB1:="000"; end if;  -- Balkenfläche (Schwarz)

    RGB <= RGB1;		-- Ausgabe der oben definierten Farbwerte
end if;
end process;
end BEHAVIOR;