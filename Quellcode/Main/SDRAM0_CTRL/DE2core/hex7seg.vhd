-- Filename : 	 hex7seg.vhd
-- Beschreibung: Ausgabe der Hexadezimalzeichen 0 bis f auf einer 
--				 7-Segment LED-Anzeige. 

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY hex7seg IS
	PORT (	B	: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
			H	: OUT	STD_LOGIC_VECTOR(0 TO 6));
END hex7seg;

ARCHITECTURE Behavior OF hex7seg IS
BEGIN

	--       0  
	--      ---  
	--     |   |
	--    5|   |1
	--     | 6 |
	--      ---  
	--     |   |
	--    4|   |2
	--     |   |
	--      ---  
	--       3  
	
WITH B SELECT
	H	<=	 "0000001"  WHEN "0000",
			 "1001111"  WHEN "0001",
			 "0010010"  WHEN "0010",
			 "0000110"  WHEN "0011",
			 "1001100"  WHEN "0100",
			 "0100100"  WHEN "0101",
			 "0100000"  WHEN "0110",
			 "0001111"  WHEN "0111",
			 "0000000"  WHEN "1000",
			 "0000100"  WHEN "1001",
			 "0001000"  WHEN "1010",
			 "1100000"  WHEN "1011",
			 "0110001"  WHEN "1100",
			 "1000010"  WHEN "1101",
			 "0110000"  WHEN "1110",
			 "0111000"  WHEN "1111",
			 "1111111"  WHEN OTHERS;
END Behavior;
