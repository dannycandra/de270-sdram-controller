-------------------------------------------------------------------------------------
--Dateiname: 	  NEEK_TOUCHPANEL.vhd
--Autor: 		  Christoph Kozicki, Matr.Nr. 10005775
--Beschreibung:   VHDL-Modul zur gleichzeitigen Ansteuerung des LCD-Touch-Panels und
-- 				  und zur Stift-Positionsbestimmung auf dem "NEEK-Board"
--Datum:		  06. Januar 2009
--Abhängigkeiten: adc_spi_controller.v; lcd_spi_cotroller.v; three_wire_controller.v;
--				  Reset_Delay.vhd; pen_korrektur.vhd; lcd_timing_controller.vhd;
-------------------------------------------------------------------------------------
LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.all;
ENTITY NEEK_TOUCHPANEL IS 
port(TPIO_NEEK 		: INOUT STD_LOGIC;						-- I/O HMSC Adapter
	 TPI_NEEK 		: IN 	STD_LOGIC_VECTOR (2 DOWNTO 0);	-- I/O HMSC Adapter
	 TPO_NEEK 		: OUT 	STD_LOGIC_VECTOR(15 DOWNTO 0);	-- I/O HMSC Adapter
	 CLOCK_50 		: IN  	STD_LOGIC;						-- 50 MHz Systemtakt
	 reset 			: IN  	STD_LOGIC;					-- Reset des LCDs (Aktiv Low)
	 r,g,b 			: IN  	STD_LOGIC_VECTOR (7 DOWNTO 0);	-- Eingangsfarben
	 vert_sync		: OUT	STD_LOGIC;					-- vertikale Synchronisation
	 pix_clock		: OUT	STD_LOGIC;					-- Pixeltakt (33,3 MHz)
	 pen_x, pen_y	: OUT  	STD_LOGIC_VECTOR (9 DOWNTO 0);	-- Stiftposition
	 pix_x, pix_y 	: OUT  	STD_LOGIC_VECTOR (9 DOWNTO 0));	-- Pixelposition
END NEEK_TOUCHPANEL;

ARCHITECTURE verhalten OF NEEK_TOUCHPANEL IS
	
component adc_spi_controller is --Verilog Datei von Terasic
port(iCLK,iRST_n 						: in  std_logic;
	oADC_DIN,oADC_DCLK,oADC_CS 			: out std_logic;
	iADC_DOUT, iADC_BUSY, iADC_PENIRQ_n : in  std_logic;
	oTOUCH_IRQ							: out std_logic;
	oX_COORD, oY_COORD					: out std_logic_vector(11 downto 0);
	oNEW_COORD 							: out std_logic);
end component adc_spi_controller;
	
component Reset_Delay is
port(iCLK,iRST				:	in  std_logic;
	oRST_0,oRST_1,oRST_2	:	out std_logic);
end component Reset_Delay;
	
component TP_SYNC_NEEK is
port (pclk				: in  STD_LOGIC;
	  iRST_n			: in  STD_LOGIC;
	  red, green, blue	: in  STD_LOGIC_VECTOR(7 downto 0);
	  oLCD				: out STD_LOGIC_VECTOR(7 downto 0);
	  oHD,oVD,oDEN	 	: out STD_LOGIC;
	  pixel_x, pixel_y 	: OUT STD_LOGIC_VECTOR(9 downto 0));	
end component TP_SYNC_NEEK;

component lcd_spi_cotroller is --Verilog Datei von Terasic
port(iCLK,	iRST_n 				: in  std_logic;
	o3WIRE_SCLK 				: out std_logic;
	io3WIRE_SDAT 				: inout std_logic;
	o3WIRE_SCEN, o3WIRE_BUSY_n  : out std_logic);
end component lcd_spi_cotroller;

component PEN_ADJ is
port (	in_x, in_y	   : in  STD_LOGIC_VECTOR (9 downto 0);
	   out_x, out_y    : out STD_LOGIC_VECTOR (9 downto 0));
end component PEN_ADJ;

component pll50to100 IS --ALTPLL
PORT (inclk0	: IN STD_LOGIC;
	  c0		: OUT STD_LOGIC);
end component pll50to100;

SIGNAL div 	   			 : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL x_coord,y_coord   : STD_LOGIC_VECTOR(11 downto 0);
SIGNAL p_x, p_y 		 : STD_LOGIC_VECTOR (9 downto 0);
SIGNAL ltm_rgb,hex_en 	 : STD_LOGIC_VECTOR (7 downto 0);
SIGNAL new_coord,adc_cs,adc_dclk,ltm_sclk,ltm_3wirebusy_n : STD_LOGIC;
SIGNAL touch_irq,DLY0,DLY1,DLY2 : STD_LOGIC;
SIGNAL ltm_sda,ltm_scen,ltm_grst,ltm_nclk,ltm_den,ltm_hd,ltm_vd : STD_LOGIC;
SIGNAL adc_penirq_n,adc_dout,adc_din,adc_busy,adc_ltm_sclk : STD_LOGIC;

BEGIN

-- Liest die aktuelle Stiftposition aus dem Touchscreen ADC
Stift_koordinaten: adc_spi_controller 
		port map (CLOCK_50,
				  DLY0, --kann auch DLY1 sein
				  adc_din,
				  adc_dclk,
				  adc_cs,
				  adc_dout,
				  adc_busy,
				  adc_penirq_n,
				  touch_irq,--wird nicht verwendet	
				  y_coord, -- y & x sind vertauscht, da Terasic
				  x_coord, -- im Beispiel das Panel hochkant betrieb
				  new_coord);--wird nicht verwendet													

-- Verzögerung, damit nach einem Reset die Übertragungen vom und zum Touchpanel
-- nacheinander und nicht gleichzeitig ablaufen und damit in der Startphase 
-- keine Daten für das LCD anliegen (mind. 11ms laut Datenblatt)	
Verzoegerung: Reset_Delay port map (	CLOCK_50,
										reset, --Global Reset
										DLY0, --High nach 2097151 * 20ns = 42ms
										DLY1, --High nach 3145727 * 20ns = 63ms
										DLY2);--High nach 4194303 * 20ns = 84ms

-- Sendet HSync, VSync, Device Enable und die Subpixel an das LCD und gibt die aktuelle 
-- Pixelposition aus	
LCD_Sync: TP_SYNC_NEEK port map (	ltm_nclk,
									DLY2,
									r,g,b,--(in) Pixel Farbe	
									ltm_rgb,
									ltm_hd,
									ltm_vd,
									ltm_den,
									pix_x, 
									pix_y);--(out) Pixel Koordinaten		

-- Überträgt die	LCD-Konfiguration an das LCD								
LCD_Config: lcd_spi_cotroller 
	port map (CLOCK_50,
			DLY0,
			ltm_sclk,
			ltm_sda,
			ltm_scen,
			ltm_3wirebusy_n);--(out) Taktauswahl für ADC oder LCD	

-- Formatiert die 4096x4096 Stiftauflösung zur LCD-Kompatiblen 800x480 Auflösung
-- Durch weglassen xy_coord(1 downto 0) wird bereits durch 4 geteilt	
Stift: PEN_ADJ 
	port map (	x_coord(11 downto 2),--Stiftkoordinaten vom ADC /4 (also 0..1023)
				y_coord(11 downto 2),--Stiftkoordinaten vom ADC /4 (also 0..1023)
				p_x, --Stiftkoordinaten nach Korrektur (also 0..799)
				p_y);--Stiftkoordinaten nach Korrektur (also 0..479)	
	
-- Wandelt 50MHz zu 100MHz (3x 33,3MHz RGB-Pixeltakt)
PixClk: pll50to100	port map (CLOCK_50,ltm_nclk);

--adc_ltm_sclk beinhaltet bei ltm_3wirebusy_n = '1' "adc_dclk", sonst "ltm_sclk" 
adc_ltm_sclk <= (ltm_sclk AND NOT ltm_3wirebusy_n) OR (adc_dclk AND ltm_3wirebusy_n) ;

-- Zuweisung der Signale zu den Anschlüssen															
TPIO_NEEK <= ltm_sda;
TPO_NEEK(12) <= ltm_scen;
TPO_NEEK(15)  <= NOT ltm_scen;	
adc_busy <= TPI_NEEK(2); 
adc_penirq_n <= TPI_NEEK(0);
TPO_NEEK(8) <= ltm_nclk;
TPO_NEEK(9) <= ltm_den;
TPO_NEEK(10) <= ltm_hd;
TPO_NEEK(11) <= ltm_vd;
TPO_NEEK(7 downto 0) <= ltm_rgb;
adc_dout <= TPI_NEEK(1);
TPO_NEEK(14) <= adc_din;
TPO_NEEK(13) <= adc_ltm_sclk; 
ltm_grst <= reset; --Global Reset
pen_y <= p_y; -- Ausgabe der korrigierten Stift-Koordinaten
pen_x <= p_x; 
vert_sync  	<= ltm_vd;			-- Ausgabe Vertikale Synchronisation
pix_clock	<= ltm_nclk;		-- Ausgabe Pixeltakt
END ARCHITECTURE verhalten;