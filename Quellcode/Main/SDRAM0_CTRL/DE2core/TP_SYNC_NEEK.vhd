------------------------------------------------------------------------------------
--Dateiname: 	  TP_SYNC_NEEK.vhd												
--Autor: 		  Christoph Kozicki, Matr.Nr. 10005775							
--Beschreibung:   VHDL-Modul zur Ansteuerung des LCD-Panels 					
--				  auf dem "Nios Embedded Evaluation Kit" Coclone III Edtion (NEEK)
--Datum:		  24. November 2008											
--Abhängigkeiten: keine														
------------------------------------------------------------------------------------
LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all; -- Bibliotheken fuer numerische Operationen
USE IEEE.STD_LOGIC_UNSIGNED.all;
entity TP_SYNC_NEEK is
  port (pclk	: in  STD_LOGIC; --Clock 100MHz (3 x 33,3 MHz)
		iRST_n	: in  STD_LOGIC; --Reset
		red, green, blue	: in STD_LOGIC_VECTOR(7 downto 0);--aktuelle Pixelfarbe
		oLCD	: out STD_LOGIC_VECTOR(7 downto 0);--Wert des übertragenen Pixels
		oHD,oVD,oDEN	 : out  STD_LOGIC; --HSync, VSync, Device Enable
		pixel_x, pixel_y : OUT STD_LOGIC_VECTOR(9 downto 0));--Pixelposition
end TP_SYNC_NEEK;

ARCHITECTURE verhalten OF TP_SYNC_NEEK IS
	SIGNAL subpix : STD_LOGIC_VECTOR(7 DOWNTO 0); --Wert des übertragenen Pixels
	SIGNAL x_print, y_print : STD_LOGIC_VECTOR(9 DOWNTO 0); --Pixelposition
	BEGIN
		p0: PROCESS(pclk) IS
			VARIABLE regv : STD_LOGIC; --Variable für VSync
			VARIABLE regh : STD_LOGIC; --Variable für HSync
			VARIABLE y_count : NATURAL:= 0; -- Zählvariable vertikale Pixel
			VARIABLE x_count : NATURAL:= 0; -- Zählvariable horizontale Subpixel
			VARIABLE x_inv : NATURAL:= 0; --Hilfsvariable für horizontale Spiegelung
			VARIABLE pixel_col : NATURAL:= 0; --Auswahl d. aktuellen Pixelfarbe (rgb)
			VARIABLE deven : STD_LOGIC; --Variable für Device Enable
			BEGIN			
				IF FALLING_EDGE(pclk) THEN	
-- Es werden 3 Subpixel pro Pixel übertragen, D.h. x_count zählt alle 3 pclk um einen 
-- Wert hoch. Während der 3 pclk wechselt pixel_col die Werte 2, 1 bis 0 um die 
-- aktuelle Pixelfarbe zu bestimmen 2-blau, 1-grün, 0-rot.
					IF (pixel_col = 0) THEN   		
						pixel_col := 2;	      		     
						x_count := x_count+1; 		
					ELSE				      		
						pixel_col := pixel_col-1;					
					END IF;					  
-- HSync & VSync. Horizontale Linie enthält 1056 Pixel (Nutzbar: 216 bis 1016 also 800)
-- Vertikale Linie enthält 525 Pixel (Nutzbar: 35 bis 515 also 480)       
					IF (x_count = 1056) THEN	
						x_count := 0;						
						regh := '0';    -- hd für einen pclk auf 'low'
						regv := '1';
						IF (y_count = 525) THEN	 
							regv := '0';				
							y_count := 0;	
						END IF;	
						y_count := y_count+1;
					END IF;	
					IF (x_count = 1) THEN -- hd nach einem pclk wieder auf 'high'
						regh := '1';
					END IF;	
-- Device Enable. Der sichtbare Pixelbereich 800x480
					IF (x_count = 216) AND (y_count > 35) AND (y_count < 515) THEN
						deven := '1';
					ELSIF (x_count = 1016)THEN
						deven := '0';
					END IF;
-- Nullpunkt festlegen und Ausgabe der Pixelkoordinaten. Beim NEEK-Board muss
-- die horizontale Linie gespiegelt werden (800 - X_Position).
					x_inv := x_count - 216;
					x_print <= CONV_STD_LOGIC_VECTOR(800 - x_inv,10);
					y_print <= CONV_STD_LOGIC_VECTOR(y_count - 36,10);		
--Multiplexer für Subpixels (r,g,b -> rgb) 
					IF (pixel_col = 0) THEN					
						subpix <= red;		-- der Demultiplexer befindet sich
					END IF;					-- in der MAX II CPLD am Daughterboard
					IF (pixel_col = 1) THEN
						subpix <= green;
					END IF;	
					IF (pixel_col = 2) THEN
						subpix <= blue;
					END IF;
				END IF;	
--Zuweisung der Variablen zu den Ausgängen
				oHD <= regh;
				oVD <= regv;
				oLCD <= subpix; 
				oDEN <= deven;
				pixel_x <= x_print;
				pixel_y <= y_print;				
			END PROCESS p0;
END ARCHITECTURE verhalten;
