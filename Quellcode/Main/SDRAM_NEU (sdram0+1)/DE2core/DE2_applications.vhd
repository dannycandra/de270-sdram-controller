-- Bibliothek mit Komponenten und Funktionen fuer das DE2 Board

LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE DE2_applications IS

TYPE string20 IS ARRAY (POSITIVE RANGE 1 To 20) OF CHARACTER;

FUNCTION char2ascii (a : IN CHARACTER)
RETURN STD_LOGIC_VECTOR;

FUNCTION hex7seg (x : IN STD_LOGIC_VECTOR(3 DOWNTO 0))
RETURN STD_LOGIC_VECTOR;

END PACKAGE DE2_applications;

PACKAGE BODY DE2_applications IS

FUNCTION hex7seg (hex : IN STD_LOGIC_VECTOR(3 DOWNTO 0))
RETURN STD_LOGIC_VECTOR IS
VARIABLE display : STD_LOGIC_VECTOR (6 DOWNTO 0);
-- Umwandlung eines Hexadezimalwertes zur Darstellung mittels
-- 7-Segmentanzeige auf dem DE2 Board
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
BEGIN
      CASE hex IS
         WHEN "0000" => display := "0000001";
         WHEN "0001" => display := "1001111";
         WHEN "0010" => display := "0010010";
         WHEN "0011" => display := "0000110";
         WHEN "0100" => display := "1001100";
         WHEN "0101" => display := "0100100";
         WHEN "0110" => display := "1100000";
         WHEN "0111" => display := "0001111";
         WHEN "1000" => display := "0000000";
         WHEN "1001" => display := "0001100";
         WHEN "1010" => display := "0001000";
         WHEN "1011" => display := "1100000";
         WHEN "1100" => display := "0110001";
         WHEN "1101" => display := "1000010";
         WHEN "1110" => display := "0110000";
         WHEN "1111" => display := "0111000";
         WHEN OTHERS => display := "1111111";
      END CASE;
RETURN display;
END hex7seg;
	

FUNCTION char2ascii (a : IN CHARACTER)
RETURN STD_LOGIC_VECTOR IS
VARIABLE char : STD_LOGIC_VECTOR (7 DOWNTO 0);
-- Funktion zur Umwandlung eines VHDL-Character in den ASCII-Code.
-- Nicht aufgeführte Zeichen werden als Leerzeichen interpretiert.
------------------------------------------------------------------- 
--                        ASCII HEX TABLE
--  Hex						Low Hex Digit
-- Value  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
------\----------------------------------------------------------------
--H  2 |  SP  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
--i  3 |  0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
--g  4 |  @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
--h  5 |  P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
--   6 |  `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
--   7 |  p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~
-----------------------------------------------------------------------
-- Example "A" is row 4 column 1, so hex value is x"41"
   BEGIN
      CASE a IS
	             WHEN ' ' => char := x"20";
	             WHEN '!' => char := x"21";
	             WHEN '"' => char := x"22";
	             WHEN '#' => char := x"23";
	             WHEN '$' => char := x"24";
	             WHEN '%' => char := x"25";
	             WHEN '&' => char := x"26";
	             WHEN ''' => char := x"27";
	             WHEN '(' => char := x"28";
	             WHEN ')' => char := x"29";
	             WHEN '*' => char := x"2A";
	             WHEN '+' => char := x"2B";
	             WHEN ',' => char := x"2C";
	             WHEN '-' => char := x"2D";
	             WHEN '.' => char := x"2E";
	             WHEN '/' => char := x"2F";
	             WHEN '0' => char := x"30";
	             WHEN '1' => char := x"31";
	             WHEN '2' => char := x"32";
	             WHEN '3' => char := x"33";
	             WHEN '4' => char := x"34";
	             WHEN '5' => char := x"35";
	             WHEN '6' => char := x"36";
	             WHEN '7' => char := x"37";
	             WHEN '8' => char := x"38";
	             WHEN '9' => char := x"39";
	             WHEN ':' => char := x"3A";
	             WHEN ';' => char := x"3B";
	             WHEN '<' => char := x"3C";
	             WHEN '=' => char := x"3D";
	             WHEN '>' => char := x"3E";
	             WHEN '?' => char := x"3F";
	             WHEN '@' => char := x"40";
	             WHEN 'A' => char := x"41";
	             WHEN 'B' => char := x"42";
	             WHEN 'C' => char := x"43";
		         WHEN 'D' => char := x"44";
	             WHEN 'E' => char := x"45";
	             WHEN 'F' => char := x"46";
	             WHEN 'G' => char := x"47";
	             WHEN 'H' => char := x"48";
	             WHEN 'I' => char := x"49";
	             WHEN 'J' => char := x"4A";
	             WHEN 'K' => char := x"4B";
	             WHEN 'L' => char := x"4C";
	             WHEN 'M' => char := x"4D";
	             WHEN 'N' => char := x"4E";
	             WHEN 'O' => char := x"4F";
	             WHEN 'P' => char := x"50";
	             WHEN 'Q' => char := x"51";
	             WHEN 'R' => char := x"52";
	             WHEN 'S' => char := x"53";
	             WHEN 'T' => char := x"54";
	             WHEN 'U' => char := x"55";
	             WHEN 'V' => char := x"56";
	             WHEN 'W' => char := x"57";
	             WHEN 'X' => char := x"58";
	             WHEN 'Y' => char := x"59";
	             WHEN 'Z' => char := x"5A";
	             WHEN '[' => char := x"5B";
	             WHEN '\' => char := x"5C";
	             WHEN ']' => char := x"5D";
	             WHEN '^' => char := x"5E";
	             WHEN '_' => char := x"5F";
	             WHEN '´' => char := x"60";
	             WHEN 'a' => char := x"61";
	             WHEN 'b' => char := x"62";
	             WHEN 'c' => char := x"63";
	             WHEN 'd' => char := x"64";
	             WHEN 'e' => char := x"65";
	             WHEN 'f' => char := x"66";
	             WHEN 'g' => char := x"67";
	             WHEN 'h' => char := x"68";
	             WHEN 'i' => char := x"69";
	             WHEN 'j' => char := x"6A";
	             WHEN 'k' => char := x"6B";
	             WHEN 'l' => char := x"6C";
	             WHEN 'm' => char := x"6D";
	             WHEN 'n' => char := x"6E";
	             WHEN 'o' => char := x"6F";
	             WHEN 'p' => char := x"70";
	             WHEN 'q' => char := x"71";
	             WHEN 'r' => char := x"72";
	             WHEN 's' => char := x"73";
	             WHEN 't' => char := x"74";
	             WHEN 'u' => char := x"75";
	             WHEN 'v' => char := x"76";
	             WHEN 'w' => char := x"77";
	             WHEN 'x' => char := x"78";
	             WHEN 'y' => char := x"79";
	             WHEN 'z' => char := x"7A";
	             WHEN '{' => char := x"7B";
	             WHEN '|' => char := x"7C";
	             WHEN '}' => char := x"7D";
	             WHEN '~' => char := x"7E";
	             WHEN OTHERS => char := x"20";
	          END CASE;
	RETURN char;
END char2ascii;


END DE2_applications;