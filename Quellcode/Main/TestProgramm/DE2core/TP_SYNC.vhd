----------------------------------------------------------------------------
--Dateiname: 	  TP_SYNC.vhd
--Autor: 		  Christoph Kozicki, Matr.Nr. 10005775
--Beschreibung:   Sendet Synchronisationssignale an das Touchpanel TRDB-LTM
--Datum:		  27. November 2008	
--Abh‰ngigkeiten: keine 
----------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

entity TP_SYNC is
  port (iCLK	: in  STD_LOGIC;
		iRST_n	: in  STD_LOGIC;
		r,g,b	: in  STD_LOGIC_VECTOR(7 downto 0);		
		oLCD_R,oLCD_G,oLCD_B	: out STD_LOGIC_VECTOR(7 downto 0);
		oHD,oVD,oDEN	 : out  STD_LOGIC;
		pixel_x, pixel_y : OUT STD_LOGIC_VECTOR(9 downto 0));
end TP_SYNC;

architecture verhalten of TP_SYNC is
SIGNAL tmp_x, x_cnt : integer range 0 to 2047;
SIGNAL tmp_y, y_cnt : integer range 0 to 1023;
SIGNAL mhd, mvd, mden, display_area : STD_LOGIC;
SIGNAL r_pixel, g_pixel, b_pixel : STD_LOGIC_VECTOR(7 downto 0);
SIGNAL out_x, out_y : STD_LOGIC_VECTOR(9 downto 0);
begin

-- Device Enable. Horizontale Linie enth‰lt 1056 Pixel (Nutzbar: 216 bis 1016 also 800) 
-- Vertikale Linie enth‰lt 525 Pixel (Nutzbar: 35 bis 515 also 480)  
p0: Process (iCLK, x_cnt, y_cnt)
  BEGIN 
	IF	( x_cnt > 215 AND x_cnt < 1016 AND y_cnt > 34 AND y_cnt < 515 ) THEN
		 display_area <= '1';
	ELSE display_area <= '0';
	END IF;	
END process p0;	

--HSync, VSync und Device Enable.
p1: Process (iCLK,iRST_n)
  BEGIN
  IF RISING_EDGE(iCLK) THEN
    IF iRST_n = '0' THEN
		x_cnt <= 0;	
		mhd  <= '0';  
		y_cnt <= 0;	
		mvd  <= '1';
		mden <= '0';
	ELSIF x_cnt = 1055 THEN
		x_cnt <= 0;
		mhd  <= '0';
		IF y_cnt = 524 THEN
			 y_cnt <= 0;
		ELSE y_cnt <= y_cnt + 1;	
		END IF;
	ELSE
		x_cnt <= x_cnt + 1;
		mhd  <= '1';
	END IF;
	
	IF (y_cnt = 0) THEN
			mvd  <= '0';
	ELSE	mvd  <= '1';
	END IF;
	
	IF display_area = '1' THEN
		 mden  <= '1';
	ELSE mden  <= '0';	
	END IF;
  END IF;
END process p1;

p4: Process (iCLK,iRST_n)--,r,g,b
  BEGIN
  IF RISING_EDGE(iCLK) THEN
	IF (display_area = '0') THEN
		out_x <= "1111111111"; --1023 dez auﬂerhalb des sichtbaren Bereichs
		out_y <= "1111111111"; 
	ELSE	
		tmp_x <= 1014-x_cnt; --Invertieren der X-Koordinate, FEHLER: vorher 1016-x_cnt;
		tmp_y <= y_cnt-35;   --Invertieren der Y-Koordinate, FEHLER: vorher y_cnt-35;
		IF (tmp_x >= 800) THEN --Sicherheitsmaﬂnahme gegen negative Zahlen
			tmp_x <= 799;
		ELSIF (tmp_x < 0) THEN
	        tmp_x <= 0;   ELSE
	        NULL;
	    END IF;	
		IF (tmp_y >= 480) THEN
			tmp_y <= 479;
		ELSIF (tmp_y < 0) THEN
		    tmp_y <= 0;   ELSE
		    NULL;
		END IF;
		out_x <= CONV_STD_LOGIC_VECTOR(tmp_x,10); --Koordinatenausgabe 0..799
		out_y <= CONV_STD_LOGIC_VECTOR(tmp_y,10); --Koordinatenausgabe 0..479
	END IF;	
  END IF;	
END process p4;

--Zuweisung der Variablen zu den Ausg‰ngen		
p5: Process (iCLK,iRST_n)
  BEGIN
  IF RISING_EDGE(iCLK) THEN	
	IF(iRST_n = '0') THEN	-- Sende nichts und Warte solange, bis Reset abf‰llt
		oHD	<= '0';			-- damit die LCD-Startphase gelingt
		oVD	<= '0';
		oDEN <= '0';
		oLCD_R <= "00000000";
		oLCD_G <= "00000000";
		oLCD_B <= "00000000";
	ELSE
		oHD	<= mhd;
		oVD	<= mvd;
		oDEN <= mden;
		oLCD_R <= r;
		oLCD_G <= g;
		oLCD_B <= b;
		pixel_x <= out_x;
		pixel_y <= out_y;
	END IF;
  END IF;	
END process p5;

end verhalten;
