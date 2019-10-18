------------------------------------------------------------------------------------------
--Dateiname: 	  DE2_TOUCHPANEL.vhd
--Autor: 		  Christoph Kozicki, Matr.Nr. 10005775									
--Beschreibung:   VHDL-Modul zur gleichzeitigen Ansteuerung des LCD-Touch-Panels
-- 				  und zur Stift-Positionsbestimmung auf dem "DE2-Board" mit "TRDB-LTM"
--Datum:		  13. Januar 2009													
--Abhängigkeiten: adc_spi_controller.v; lcd_spi_cotroller.v; three_wire_controller.v; 	
--				  Reset_Delay.v; pen_korrektur.vhd; lcd_timing_controller.vhd; TP_SYNC.vhd	
------------------------------------------------------------------------------------------
library ieee;
use IEEE.STD_LOGIC_1164.all;

entity DE2_TOUCHPANEL is
	port(GPIO_0 	: inout	std_logic_vector (35 downto 0);  --IDE-anschluss (JP1)
		 CLOCK_50	: in  std_logic;					     -- Systemtakt
		 R,G,B		: in  std_logic_vector(7 downto 0);	     -- Eingangäne Farbwerte			 
		 HOR_SYNC	: out std_logic;					     -- horizontale Synchronisation
		 VERT_SYNC	: out std_logic;					     -- vertikale Synchronisation
		 DEN		: out std_logic;					     -- VGA (Device) Enable
		 PIX_CLK	: out std_logic;					     -- Pixeltakt (25 MHz ?)
		 PIX_X, PIX_Y : out std_logic_vector(9 downto 0);    --Pixelposition
		 PEN_X, PEN_Y : out std_logic_vector(9 downto 0));   --Stiftposition
end entity DE2_TOUCHPANEL;

architecture verhalten of DE2_TOUCHPANEL is

component adc_spi_controller is --Verilog Datei von Terasic
	port(iCLK,iRST_n 						: in  std_logic;
		oADC_DIN,oADC_DCLK,oADC_CS 			: out std_logic;
		iADC_DOUT, iADC_BUSY, iADC_PENIRQ_n : in  std_logic;
		oTOUCH_IRQ							: out std_logic;
		oX_COORD, oY_COORD					: out std_logic_vector(11 downto 0);
		oNEW_COORD 							: out std_logic);
end component adc_spi_controller;

component Reset_Delay is --Verilog Datei von Terasic
	port(iCLK,iRST				:	in  std_logic;
		oRST_0,oRST_1,oRST_2	:	out std_logic);
end component Reset_Delay;

component TP_SYNC is
	port(iCLK, iRST_n 			: IN  STD_LOGIC;
		r,g,b					: IN  STD_LOGIC_VECTOR(7 downto 0);			
		oLCD_R,oLCD_G,oLCD_B 	: OUT STD_LOGIC_VECTOR(7 downto 0);
		oHD,oVD,oDEN			: OUT STD_LOGIC;
		pixel_x, pixel_y 		: OUT STD_LOGIC_VECTOR(9 downto 0));
end component TP_SYNC;

component lcd_spi_cotroller is --Verilog Datei von Terasic
	port(iCLK,	iRST_n 				: in  std_logic;
		o3WIRE_SCLK 				: out std_logic;
		io3WIRE_SDAT 				: inout std_logic;
		o3WIRE_SCEN, o3WIRE_BUSY_n : out std_logic);
end component lcd_spi_cotroller;

component PEN_ADJ is
port (	in_x, in_y	   : in  STD_LOGIC_VECTOR (9 downto 0);
		out_x, out_y   : out STD_LOGIC_VECTOR (9 downto 0));
end component PEN_ADJ;

SIGNAL div 	   			 : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL x_coord,y_coord   : STD_LOGIC_VECTOR(11 downto 0);
SIGNAL ltm_r,ltm_g,ltm_b,hex_en : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL touch_irq,DLY0,DLY1,DLY2,new_coord : STD_LOGIC;
SIGNAL adc_cs,adc_dclk,ltm_sclk,ltm_3wirebusy_n : STD_LOGIC;
SIGNAL ltm_sda,ltm_scen,ltm_grst,ltm_nclk,ltm_den,ltm_hd,ltm_vd : STD_LOGIC;
SIGNAL adc_penirq_n,adc_dout,adc_din,adc_busy,adc_ltm_sclk : STD_LOGIC;
SIGNAL p_x, p_y   : STD_LOGIC_VECTOR (9 downto 0);

BEGIN

-- Liest die aktuelle Stiftposition aus dem Touchscreen ADC
Stift_koordinaten: adc_spi_controller 
	port map (  CLOCK_50,
			    DLY0, 
				adc_din,
				adc_dclk,
				adc_cs,
				adc_dout,
				adc_busy,
				adc_penirq_n,
				touch_irq,    --wird nicht verwendet
				y_coord,      -- y & x sind vertauscht, da Terasic
				x_coord,      -- im Beispiel das Panel hochkant betrieb
				new_coord);	  --wird nicht verwendet	

-- Verzögerung, damit in der Startphase des LCD keine Daten für das LCD anliegen
-- siehe "Power ON sequence" im Datenblatt "TD043MTEA1_20.pdf" Seite 11																									
Verzoegerung: Reset_Delay port map (CLOCK_50,
									'1',  --Global Reset
									DLY0, --High nach 1fffff * 20ns = 42ms
									DLY1, --High nach 2fffff * 20ns = 63ms
									DLY2);--High nach 3fffff * 20ns = 84ms
									
-- Sendet HSync, VSync, Device Enable und die Subpixel an das LCD und gibt die aktuelle 
-- Pixelposition aus										
LCD_Sync: TP_SYNC port map (	ltm_nclk,
								DLY2,
								R,G,B,--(in) Pixel Farbe	
								ltm_r,
								ltm_g,
								ltm_b,
								ltm_hd,
								ltm_vd,
								ltm_den,
								PIX_X, PIX_Y);--(out) Pixel Koordinaten		

-- Überträgt die LCD-Konfiguration an das LCD								
LCD_Config: lcd_spi_cotroller port map (CLOCK_50,
										DLY0,
										ltm_sclk,
										ltm_sda,
										ltm_scen,
										ltm_3wirebusy_n);

-- Formatiert die 4096x4096 Stiftauflösung zur LCD-Kompatiblen 800x480 Auflösung
-- Durch weglassen xy_coord(1 downto 0) wird bereits durch 4 geteilt										
Stift: PEN_ADJ 
	port map (	x_coord(11 downto 2),--Stiftkoordinaten vom ADC /4 (also 0..1023)
				y_coord(11 downto 2),--Stiftkoordinaten vom ADC /4 (also 0..1023)
				p_x, --Stiftkoordinaten nach Korrektur (also 0..799)
				p_y);--Stiftkoordinaten nach Korrektur (also 0..479)

--adc_ltm_sclk beinhaltet bei ltm_3wirebusy_n = '1' "adc_dclk", sonst "ltm_sclk" 
adc_ltm_sclk <= (ltm_sclk AND NOT ltm_3wirebusy_n) OR (adc_dclk AND ltm_3wirebusy_n);

-- Wandelt 50MHz zu 25MHz (RGB-Pixeltakt)
clockdiv: PROCESS(CLOCK_50) IS
	VARIABLE nck : std_logic; 
	BEGIN			
		IF FALLING_EDGE(CLOCK_50) THEN	
			IF (nck = '1') THEN	
				nck := '0';
			ELSE 
				nck := '1';	
			END IF;		
		END IF;	
		ltm_nclk <= nck; --LCD-Bittakt/Pixeltakt
		PIX_CLK  <= nck;
END PROCESS clockdiv;


-- Zuweisung der Signale zu den Anschlüssen																		
GPIO_0(32 downto 25) <= ltm_r;
GPIO_0(24 downto 17) <= ltm_g;
GPIO_0(8) <= ltm_b(0);
GPIO_0(7) <= ltm_b(1);
GPIO_0(6) <= ltm_b(2);
GPIO_0(5) <= ltm_b(3);
GPIO_0(16 downto 13) <= ltm_b(7 downto 4);
GPIO_0(35) <= ltm_sda;
GPIO_0(34) <= ltm_scen; --zugleich: "NOT adc_cs"
GPIO_0(33) <= ltm_grst; --Global Reset
GPIO_0(9) <= ltm_nclk;
GPIO_0(10) <= ltm_den;
GPIO_0(11) <= ltm_hd;
GPIO_0(12) <= ltm_vd;
adc_penirq_n <= GPIO_0(0);
adc_dout <= GPIO_0(1);
GPIO_0(3) <= adc_din;
adc_busy <= GPIO_0(2); 
GPIO_0(4) <= adc_ltm_sclk; 
ltm_grst <= '1';     --Global Reset
HOR_SYNC  <= ltm_hd; -- Ausgabe der horizontalen Synchronisation
VERT_SYNC <= ltm_vd; -- Ausgabe der vertikalen Synchronisation
DEN		  <= ltm_den;-- Ausgabe des VGA (Device) Enable
PEN_Y 	  <= p_y; 	 -- Ausgabe der korrigierten Stift-Koordinaten
PEN_X	  <= p_x; 

END ARCHITECTURE verhalten;