LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY keyboard IS
	PORT(	PS2_CLK, PS2_DAT, CLOCK_50 , 
			reset, read		: IN	STD_LOGIC;
			scan_code		: OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
			scan_ready		: OUT	STD_LOGIC;
			key_released    : OUT   STD_LOGIC);   --key release information
			END keyboard;

ARCHITECTURE a OF keyboard IS
	SIGNAL INCNT					: std_logic_vector(3 downto 0);
	SIGNAL SHIFTIN 					: std_logic_vector(8 downto 0);
	SIGNAL READ_CHAR, clock_enable 	: std_logic;
	SIGNAL INFLAG, ready_set		: std_logic;
	SIGNAL keyboard_clk_filtered 	: std_logic;
	SIGNAL filter 					: std_logic_vector(7 downto 0);
BEGIN

PROCESS (read, ready_set)
BEGIN
  IF read = '1' THEN scan_ready <= '0';
  ELSIF ready_set'EVENT and ready_set = '1' THEN
		scan_ready <= '1';
  END IF;
  IF ready_set = '1' AND SHIFTIN(7 DOWNTO 0) = x"F0"   --This outputs 1 if a key is released
     THEN key_released <= '1';
     ELSE key_released <= '0';
  END IF;
END PROCESS;


--This process filters the raw clock signal coming from the keyboard using a shift register and two AND gates
Clock_filter: PROCESS
BEGIN
	WAIT UNTIL CLOCK_50'EVENT AND CLOCK_50= '1';
	clock_enable <= NOT clock_enable;
	IF clock_enable = '1' THEN
		filter (6 DOWNTO 0) <= filter(7 DOWNTO 1) ;
		filter(7) <= PS2_CLK;
		IF filter = "11111111" THEN keyboard_clk_filtered <= '1';
		ELSIF  filter= "00000000" THEN keyboard_clk_filtered <= '0';
		END IF;
  	END IF;
END PROCESS Clock_filter;


--This process reads in serial data coming from the terminal
PROCESS
BEGIN
WAIT UNTIL (KEYBOARD_CLK_filtered'EVENT AND KEYBOARD_CLK_filtered='1');
IF RESET='0' THEN
        INCNT <= "0000";
        READ_CHAR <= '0';
        ready_set<= '0';
ELSE
  IF PS2_DAT='0' AND READ_CHAR='0' THEN
        READ_CHAR<= '1';
		ready_set<= '0';
  ELSE
			-- Shift in next 8 data bits to assemble a scan code
    IF READ_CHAR = '1' THEN
        IF INCNT < "1001" THEN
         	INCNT 				<= INCNT + 1;
         	SHIFTIN(7 DOWNTO 0) <= SHIFTIN(8 DOWNTO 1);
         	SHIFTIN(8) 			<= PS2_DAT;
			-- End of scan code character, so set flags and exit loop
        ELSE
	 	   	scan_code 			<= SHIFTIN(7 DOWNTO 0);
	   		READ_CHAR			<= '0';
	    	ready_set 			<= '1';
	    	INCNT 				<= "0000";
        END IF;
     END IF;
   END IF;
 END IF;
END PROCESS;
END a;


