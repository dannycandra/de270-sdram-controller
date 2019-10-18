----------------------------------------------------------------------------------
--Dateiname: 	  PEN_ADJ.vhd
--Autor: 		  Christoph Kozicki, Matr.Nr. 10005775
--Beschreibung:   Wandelt die 1024x1024 Stiftposition zur 800x480 Stiftposition um
--				  und schneidet die nicht genutzten Ränder ab.
--Datum:		  04. Dezember 2008	
--Abhängigkeiten: keine	
-----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PEN_ADJ is
	port (	in_x,in_y	   : in  unsigned (9 downto 0);
			out_x, out_y   : out STD_LOGIC_VECTOR (9 downto 0));
end entity PEN_ADJ;
architecture verhalten of PEN_ADJ is
SIGNAL rdy_x,rdy_y : unsigned (19 downto 0);
SIGNAL cut_x,cut_y,inv_y : unsigned (9 downto 0);
begin
p1: PROCESS(in_x,in_y)
BEGIN	
	IF (in_x < 26 ) THEN 		-- Abschneiden der nicht nutzbaren Ränder (links)
		cut_x <= "0000000000";
	ELSIF (in_x > 990 ) THEN 	-- Abschneiden der nicht nutzbaren Ränder (rechts)
		cut_x <= "1111000100";
	ELSE cut_x <= in_x-26;		-- Abziehen des linken Randes für die nutzbare Fläche
	END IF;
	IF (in_y < 42) THEN			-- Abschneiden der nicht nutzbaren Ränder (unten)
		cut_y <= "0000000000";
	ELSIF (in_y > 978) THEN		-- Abschneiden der nicht nutzbaren Ränder (oben)
		cut_y <= "1110101000";
	ELSE cut_y <= in_y-42;		-- Abziehen des unteren Randes für die nutzbare Fläche
	END IF;
END PROCESS p1;
rdy_x <= "1101010001" * cut_x;	-- mal 849 (dez)
rdy_y <= "1000001101" * cut_y;	-- mal 525 (dez)
out_x <= STD_LOGIC_VECTOR(rdy_x(19 downto 10)); -- Resultat: 0..799 
inv_y <= rdy_y(19 downto 10); 					-- Y-Koordinate muss invertiert werden
out_y <= STD_LOGIC_VECTOR(479-inv_y); 			-- Resultat: 0..479 
end verhalten;
