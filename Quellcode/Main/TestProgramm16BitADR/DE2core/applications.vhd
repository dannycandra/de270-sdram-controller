-- Bibliothek mit allen Komponenten der UP1core Library sowie eigenen
-- Programmen und Funktionen

LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE applications IS
TYPE string20 IS ARRAY (POSITIVE RANGE 1 To 20) OF CHARACTER;

FUNCTION char2vga (a : IN CHARACTER)
   RETURN STD_LOGIC_VECTOR;

FUNCTION cline2vga(col : IN STD_LOGIC_VECTOR(5 DOWNTO 0); zeile : IN string20)
   RETURN STD_LOGIC_VECTOR;

COMPONENT dec_7seg
		PORT(hex_digit				: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			segment_a, segment_b, segment_c, segment_d,
			segment_e, segment_f, segment_g : OUT STD_LOGIC);
	END COMPONENT;
	COMPONENT debounce
		PORT(pb, clock_100Hz 		: IN	STD_LOGIC;
	         pb_debounced			: OUT	STD_LOGIC);
	END COMPONENT;
	COMPONENT onepulse
		PORT(pb_debounced, clock	: IN	STD_LOGIC;
		 	pb_single_pulse			: OUT	STD_LOGIC);
	END COMPONENT;
	COMPONENT clk_div
		PORT(clock_25Mhz			: IN	STD_LOGIC;
			 clock_1MHz				: OUT	STD_LOGIC;
			 clock_100KHz			: OUT	STD_LOGIC;
			 clock_10KHz			: OUT	STD_LOGIC;
			 clock_1KHz				: OUT	STD_LOGIC;
			 clock_100Hz			: OUT	STD_LOGIC;
			 clock_10Hz				: OUT	STD_LOGIC;
			 clock_1Hz				: OUT	STD_LOGIC);
	END COMPONENT;
	COMPONENT vga_sync
 		PORT(clock_25Mhz, red, green, blue		: IN	STD_LOGIC;
         	 red_out, green_out, blue_out 		: OUT 	STD_LOGIC;
			 horiz_sync_out, vert_sync_out		: OUT 	STD_LOGIC;
			 pixel_row, pixel_column	: OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
	END COMPONENT;
	COMPONENT vga_line is
        PORT(S1       : IN STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
             clock    : IN STD_LOGIC;
             red_out, green_out, blue_out  : OUT STD_LOGIC;
             horiz_sync_out, vert_sync_out : OUT STD_LOGIC);
    END COMPONENT vga_line;
	COMPONENT char_rom
		PORT(character_address			: IN STD_LOGIC_VECTOR(5 DOWNTO 0);
			 font_row, font_col			: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
			 rom_mux_output				: OUT	STD_LOGIC);
	END COMPONENT;
	COMPONENT keyboard
		PORT(keyboard_clk, keyboard_data, clock_25Mhz , 
			 reset, read				: IN STD_LOGIC;
			 scan_code					: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			 scan_ready					: OUT	STD_LOGIC);
	END COMPONENT;
	COMPONENT mouse
		PORT(clock_25Mhz, reset 		: IN std_logic;
        	 mouse_data					: INOUT std_logic;
        	 mouse_clk 					: INOUT std_logic;
        	 left_button, right_button 	: OUT std_logic;
        	 mouse_cursor_row, 
			 mouse_cursor_column 		: OUT std_logic_vector(9 DOWNTO 0));       
		END COMPONENT;

END PACKAGE applications;

PACKAGE BODY applications IS

-- Funktion zur Ausgabe des Character ROM Symbols durch Vergleich mit
-- dem eingegebenen Zeichen a
FUNCTION char2vga (a : IN CHARACTER)
   RETURN STD_LOGIC_VECTOR IS
   VARIABLE char : STD_LOGIC_VECTOR (5 DOWNTO 0);
   BEGIN
      CASE a IS
	             WHEN '@' => char := o"00";
	             WHEN 'A' => char := o"01";
	             WHEN 'B' => char := o"02";
	             WHEN 'C' => char := o"03";
		         WHEN 'D' => char := o"04";
	             WHEN 'E' => char := o"05";
	             WHEN 'F' => char := o"06";
	             WHEN 'G' => char := o"07";
	             WHEN 'H' => char := o"10";
	             WHEN 'I' => char := o"11";
	             WHEN 'J' => char := o"12";
	             WHEN 'K' => char := o"13";
	             WHEN 'L' => char := o"14";
	             WHEN 'M' => char := o"15";
	             WHEN 'N' => char := o"16";
	             WHEN 'O' => char := o"17";
	             WHEN 'P' => char := o"20";
	             WHEN 'Q' => char := o"21";
	             WHEN 'R' => char := o"22";
	             WHEN 'S' => char := o"23";
	             WHEN 'T' => char := o"24";
	             WHEN 'U' => char := o"25";
	             WHEN 'V' => char := o"26";
	             WHEN 'W' => char := o"27";
	             WHEN 'X' => char := o"30";
	             WHEN 'Y' => char := o"31";
	             WHEN 'Z' => char := o"32";
	             WHEN '[' => char := o"33";
	             WHEN ']' => char := o"35";
	             WHEN '<' => char := o"37";
	             WHEN '!' => char := o"41";
	             WHEN '"' => char := o"42";
	             WHEN '#' => char := o"43";
	             WHEN '$' => char := o"44";
	             WHEN '%' => char := o"45";
	             WHEN '&' => char := o"46";
	             WHEN ''' => char := o"47";
	             WHEN '(' => char := o"50";
	             WHEN ')' => char := o"51";
	             WHEN '*' => char := o"52";
	             WHEN '+' => char := o"53";
	             WHEN ',' => char := o"54";
	             WHEN '-' => char := o"55";
	             WHEN '.' => char := o"56";
	             WHEN '/' => char := o"57";
	             WHEN '0' => char := o"60";
	             WHEN '1' => char := o"61";
	             WHEN '2' => char := o"62";
	             WHEN '3' => char := o"63";
	             WHEN '4' => char := o"64";
	             WHEN '5' => char := o"65";
	             WHEN '6' => char := o"66";
	             WHEN '7' => char := o"67";
	             WHEN '8' => char := o"70";
	             WHEN '9' => char := o"71";
	             WHEN OTHERS => char := o"40";
	          END CASE;
	RETURN char;
END char2vga;

-- Funktion zur Ausgabe einer Zeile mit 20 Zeichen auf einem VGA-Monitor.
-- Die Ausgabe wird durch die Spaltenposition COL des Elektronenstrahls gesteuert.
-- Es wird die Funktion CHAR2VGA benutzt.
FUNCTION cline2vga(col : IN STD_LOGIC_VECTOR(5 DOWNTO 0); zeile : IN string20)
   RETURN STD_LOGIC_VECTOR IS
   VARIABLE char : STD_LOGIC_VECTOR(5 DOWNTO 0);
   BEGIN
      CASE col IS
	     WHEN o"00" => char := char2vga(zeile(1));
	     WHEN o"01" => char := char2vga(zeile(2));
	  	 WHEN o"02" => char := char2vga(zeile(3));
	     WHEN o"03" => char := char2vga(zeile(4));
		 WHEN o"04" => char := char2vga(zeile(5));
	     WHEN o"05" => char := char2vga(zeile(6));
		 WHEN o"06" => char := char2vga(zeile(7));
	     WHEN o"07" => char := char2vga(zeile(8));
		 WHEN o"10" => char := char2vga(zeile(9));
	     WHEN o"11" => char := char2vga(zeile(10));
		 WHEN o"12" => char := char2vga(zeile(11));
	     WHEN o"13" => char := char2vga(zeile(12));
		 WHEN o"14" => char := char2vga(zeile(13));
	     WHEN o"15" => char := char2vga(zeile(14));
		 WHEN o"16" => char := char2vga(zeile(15));
	     WHEN o"17" => char := char2vga(zeile(16));
		 WHEN o"20" => char := char2vga(zeile(17));
	     WHEN o"21" => char := char2vga(zeile(18));
		 WHEN o"22" => char := char2vga(zeile(19));
         WHEN o"23" => char := char2vga(zeile(20));
	     WHEN OTHERS => char := o"40";
	 END CASE;
	RETURN char;
END cline2vga;

END applications;