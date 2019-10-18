LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;
ENTITY LCD_Line IS
-- Displays two Lines (lin1, lin2) of 16 hex data values each
-- (See ASCII to hex table below)
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
--   7 |  p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~ DEL
-----------------------------------------------------------------------
-- Example "A" is row 4 column 1, so hex value is X"41"
--
	PORT(reset, CLOCK_50			: IN	STD_LOGIC;
		 Lin1, Lin2 			    : IN    STD_LOGIC_VECTOR(127 DOWNTO 0);
		 LCD_RS, LCD_EN, LCD_RW		: OUT	STD_LOGIC;
		 LCD_ON, LCD_BLON			: OUT   STD_LOGIC;
		 LCD_DATA					: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0));
		
END ENTITY LCD_Line;

ARCHITECTURE a OF LCD_LINE IS
TYPE character_string IS ARRAY ( 0 TO 31 ) OF STD_LOGIC_VECTOR( 7 DOWNTO 0 );

TYPE STATE_TYPE IS (HOLD, FUNC_SET, DISPLAY_ON, MODE_SET, Print_String,
LINE2, RETURN_HOME, DROP_LCD_E, RESET1, RESET2, 
RESET3, DISPLAY_OFF, DISPLAY_CLEAR);
SIGNAL state, next_command: STATE_TYPE;
SIGNAL LCD_display_string	: character_string;
SIGNAL DATA_BUS_VALUE, Next_Char: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL CLK_COUNT_400HZ: STD_LOGIC_VECTOR(19 DOWNTO 0);
SIGNAL CHAR_COUNT: STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL CLK_400HZ,LCD_RW_INT : STD_LOGIC;
SIGNAL Line1_chars, Line2_chars: STD_LOGIC_VECTOR(127 DOWNTO 0);
BEGIN

LCD_ON   <= '1';
LCD_BLON <= '1';
LCD_display_string <= (
Lin1(127 DOWNTO 120),Lin1(119 DOWNTO 112),Lin1(111 DOWNTO 104), Lin1(103 DOWNTO 96),
Lin1(95 DOWNTO 88),Lin1(87 DOWNTO 80),Lin1(79 DOWNTO 72), Lin1(71 DOWNTO 64),
Lin1(63 DOWNTO 56),Lin1(55 DOWNTO 48),Lin1(47 DOWNTO 40), Lin1(39 DOWNTO 32),
Lin1(31 DOWNTO 24),Lin1(23 DOWNTO 16),Lin1(15 DOWNTO 8), Lin1(7 DOWNTO 0),
Lin2(127 DOWNTO 120),Lin2(119 DOWNTO 112),Lin2(111 DOWNTO 104), Lin2(103 DOWNTO 96),
Lin2(95 DOWNTO 88),Lin2(87 DOWNTO 80),Lin2(79 DOWNTO 72), Lin2(71 DOWNTO 64),
Lin2(63 DOWNTO 56),Lin2(55 DOWNTO 48),Lin2(47 DOWNTO 40), Lin2(39 DOWNTO 32),
Lin2(31 DOWNTO 24),Lin2(23 DOWNTO 16),Lin2(15 DOWNTO 8), Lin2(7 DOWNTO 0));

-- BIDIRECTIONAL TRI STATE LCD DATA BUS
	LCD_DATA <= DATA_BUS_VALUE WHEN LCD_RW_INT = '0' ELSE "ZZZZZZZZ";
-- get next character in display string
	Next_Char <= LCD_display_string(CONV_INTEGER(CHAR_COUNT));
	LCD_RW <= LCD_RW_INT;
PROCESS
	BEGIN
	 WAIT UNTIL CLOCK_50'EVENT AND CLOCK_50 = '1';
		IF RESET = '0' THEN
		 CLK_COUNT_400HZ <= X"00000";
		 CLK_400HZ <= '0';
		ELSE
				IF CLK_COUNT_400HZ < X"0EA60" THEN 
				 CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1;
				ELSE
		    	 CLK_COUNT_400HZ <= X"00000";
				 CLK_400HZ <= NOT CLK_400HZ;
				END IF;
		END IF;
	END PROCESS;
	PROCESS (CLK_400HZ, reset)
	BEGIN
		IF reset = '0' THEN
			state <= RESET1;
			DATA_BUS_VALUE <= X"38";
			next_command <= RESET2;
			LCD_EN <= '1';
			LCD_RS <= '0';
			LCD_RW_INT <= '1';

		ELSIF CLK_400HZ'EVENT AND CLK_400HZ = '1' THEN
-- State Machine to send commands and data to LCD DISPLAY			
			CASE state IS
-- Set Function to 8-bit transfer and 2 line display with 5x8 Font size
-- see Hitachi HD44780 family data sheet for LCD command and timing details
				WHEN RESET1 =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= RESET2;
						CHAR_COUNT <= "00000";
				WHEN RESET2 =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= RESET3;
				WHEN RESET3 =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= FUNC_SET;
-- EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD
				WHEN FUNC_SET =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"38";
						state <= DROP_LCD_E;
						next_command <= DISPLAY_OFF;
-- Turn off Display and Turn off cursor
				WHEN DISPLAY_OFF =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"08";
						state <= DROP_LCD_E;
						next_command <= DISPLAY_CLEAR;
-- Clear Display and Turn off cursor
				WHEN DISPLAY_CLEAR =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"01";
						state <= DROP_LCD_E;
						next_command <= DISPLAY_ON;
-- Turn on Display and Turn off cursor
				WHEN DISPLAY_ON =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"0C";
						state <= DROP_LCD_E;
						next_command <= MODE_SET;
-- Set write mode to auto increment address and move cursor to the right
				WHEN MODE_SET =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"06";
						state <= DROP_LCD_E;
						next_command <= Print_String;
-- Write ASCII hex character in next LCD character location
				WHEN Print_String =>
						LCD_EN <= '1';
						LCD_RS <= '1';
						LCD_RW_INT <= '0';
						state <= DROP_LCD_E;
-- ASCII character to output
						IF Next_Char(7 DOWNTO  4) /= X"0" THEN
						 DATA_BUS_VALUE <= Next_Char;
						ELSE
-- Convert 4-bit live hex value to an ASCII hex digit
							IF Next_Char(3 DOWNTO 0) >9 THEN
-- ASCII A...F
							 DATA_BUS_VALUE <= X"4" & (Next_Char(3 DOWNTO 0)-9);
							ELSE
-- ASCII 0...9
							 DATA_BUS_VALUE <= X"3" & Next_Char(3 DOWNTO 0);
							END IF;
						END IF;
-- Loop to send out 32 characters to LCD Display  (16 by 2 lines)
						IF (CHAR_COUNT < 31) AND (Next_Char /= X"FE") THEN 
						 CHAR_COUNT <= CHAR_COUNT + 1;
						ELSE 
						 CHAR_COUNT <= "00000"; 
						END IF;
-- Jump to second line?
						IF CHAR_COUNT = 15 THEN next_command <= line2;
-- Return to first line?
						ELSIF (CHAR_COUNT = 31) OR (Next_Char = X"FE") THEN 
						 next_command <= return_home; 
						ELSE next_command <= Print_String; END IF;
-- Set write address to line 2 character 1
				WHEN LINE2 =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"C0";
						state <= DROP_LCD_E;
						next_command <= Print_String;
-- Return write address to first character postion on line 1
				WHEN RETURN_HOME =>
						LCD_EN <= '1';
						LCD_RS <= '0';
						LCD_RW_INT <= '0';
						DATA_BUS_VALUE <= X"80";
						state <= DROP_LCD_E;
						next_command <= Print_String;
-- The next two states occur at the end of each command or data transfer to the LCD
-- Drop LCD E line - falling edge loads inst/data to LCD controller
				WHEN DROP_LCD_E =>
						LCD_EN <= '0';
						state <= HOLD;
-- Hold LCD inst/data valid after falling edge of E line				
				WHEN HOLD =>
						state <= next_command;
			END CASE;
		END IF;
	END PROCESS;
END a;
