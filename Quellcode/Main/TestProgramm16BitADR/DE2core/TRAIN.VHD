--
--
-- FPGA Tain VHDL Module - Train Control State Machine for Altera DE2 board
--
-- VGA output displays train and switch state
-- Students supply train_control state machine (tcontrol.vhd) to control train
-- Key0 Pushbutton is run/stop 
-- Key1 Pushbutton is reset 
-- SW0..1 is trainA speed
-- SW2..3 is trainB speed
-- SensorX are track sensors for train, train near=1 (inputs for state machine)
-- SwitchX are track switches, Sw=0 connects to outside track
-- TrackX select power source A=0 or B=1 for track segment
-- DirX selects direction: 00-stop  01-counterclockwise  10-clockwise
-- Note: Screen blinks when trains crash or go through switch in wrong direction
--
--                -----------Sw3--------------
--                | T1         \T4        T1 |
--                |     -------|-------      |
--                |     | T3   |   T3 |      |
--                |     |      | S5   |      |
--             S1 |   S2|             | S3   | S4
--                |     \     T2      /      |
--                ------Sw1---------Sw2-------
--
--                       Track Layout
--
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

LIBRARY lpm;
USE lpm.lpm_components.ALL;

LIBRARY up1core;                   -- Enthaelt Funktionen zur Umcodierung
USE up1core.DE2_applications.all;

ENTITY train IS
GENERIC(ADDR_WIDTH: integer := 12; DATA_WIDTH: integer := 1);
   PORT(SIGNAL CLOCK_50 : IN STD_LOGIC;
        SIGNAL KEY      : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        SIGNAL SW       : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        SIGNAL VGA_R9,VGA_G9,VGA_B9 : OUT STD_LOGIC;
        SIGNAL VGA_HS, VGA_VS, VGA_BLANK, VGA_CLK : OUT STD_LOGIC;
  	 	SIGNAL LCD_RS, LCD_EN	: OUT	STD_LOGIC;
	 	SIGNAL LCD_RW, LCD_ON	: OUT   STD_LOGIC;
	 	SIGNAL LCD_DATA			: INOUT	STD_LOGIC_VECTOR(7 DOWNTO 0);
	    SIGNAL HEX0, HEX3       : OUT   STD_LOGIC_VECTOR(0 TO 6));	
END train;

ARCHITECTURE behavior OF train IS
TYPE character_string IS ARRAY ( 0 TO 31 ) OF STD_LOGIC_VECTOR( 7 DOWNTO 0 );
TYPE character_string6 IS ARRAY ( 0 TO 5 ) OF STD_LOGIC_VECTOR( 7 DOWNTO 0 );
TYPE STATE_TYPE IS (HOLD, FUNC_SET, DISPLAY_ON, MODE_SET, Print_String,
LINE2, RETURN_HOME, DROP_LCD_E, RESET1, RESET2, 
RESET3, DISPLAY_OFF, DISPLAY_CLEAR);

-- Users state machine to control trains
COMPONENT Tcontrol
PORT(reset, clock, sensor1, sensor2, sensor3, sensor4, sensor5: in std_logic;
     switch1, switch2, switch3: out std_logic;
     track1, track2, track3, track4: out std_logic;
     DirA, DirB : out std_logic_vector(1 DOWNTO 0);
     Acount, Bcount : OUT std_logic_vector(3 DOWNTO 0);
     status : out string(1 TO 6));      -- Zustand der FSM
END COMPONENT;

-- PLL to generate Video clock
COMPONENT video_PLL
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0			: OUT STD_LOGIC 
	);
end component;

-- 7-Seg-Display Signals
SIGNAL Acount, Bcount : std_logic_vector(3 DOWNTO 0);
-- LCD Display Signals
SIGNAL state, next_command: STATE_TYPE;
SIGNAL status : std_logic_vector(2 DOWNTO 0);
SIGNAL LCD_display_string	: character_string;
SIGNAL LCD_status : string(1 TO 6);    -- Zustandsangabe

-- Enter new ASCII hex data above for LCD Display
SIGNAL DATA_BUS_VALUE, Next_Char: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL CLK_COUNT_400HZ: STD_LOGIC_VECTOR(19 DOWNTO 0);
SIGNAL CHAR_COUNT: STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL CLK_400HZ,LCD_RW_INT : STD_LOGIC;
SIGNAL Line1_chars, Line2_chars: STD_LOGIC_VECTOR(127 DOWNTO 0);
-- Video Train Simulation Signals
SIGNAL speed_A, speed_B: std_logic_vector(3 DOWNTO 0);
SIGNAL switch, switch_sync, cycle_count: std_logic_vector(7 DOWNTO 0);
SIGNAL speed_signal_A, speed_signal_B, train_run, train_stop, reset: std_logic;


-- Train Signals for virtual train display
SIGNAL trainArow, trainAcol: std_logic_vector(6 DOWNTO 0);
SIGNAL next_trainArow, next_trainAcol: std_logic_vector(6 DOWNTO 0);
SIGNAL next_trainBrow, next_trainBcol: std_logic_vector(6 DOWNTO 0);
SIGNAL old_trainArow, old_trainAcol: std_logic_vector(6 DOWNTO 0);
SIGNAL old2_trainArow, old2_trainAcol: std_logic_vector(6 DOWNTO 0);
SIGNAL trainBrow, trainBcol: std_logic_vector(6 DOWNTO 0);
SIGNAL old_trainBrow, old_trainBcol: std_logic_vector(6 DOWNTO 0);
SIGNAL old2_trainBrow, old2_trainBcol: std_logic_vector(6 DOWNTO 0);
SIGNAL col_adjustA, row_adjustA: std_logic_vector(6 DOWNTO 0);
SIGNAL col_adjustB, row_adjustB: std_logic_vector(6 DOWNTO 0);
SIGNAL C10A,C30A,C40A,C50A,C70A,R10A,R30A,R70A,R4xA,R5xA,T1,T2,T3,T4: boolean;
SIGNAL C10B,C30B,C40B,C50B,C70B,R10B,R30B,R70B,R4xB,R5xB: boolean;
SIGNAL crash, crashA, crashB, second: std_logic;
SIGNAL sensor, old_sensor: std_logic_vector(4 DOWNTO 0);

-- Train Signals for state machine control
SIGNAL sensor1, sensor2, sensor3, sensor4, sensor5 : std_logic;
SIGNAL switch1, switch2, switch3 :  std_logic;
SIGNAL DirA, DirB:  std_logic_vector(1 DOWNTO 0);
SIGNAL track1, track2, track3, track4 : std_logic;
-- Make these pins outputs to monitor status on Logic Analyzer
SIGNAL o_sensor1, o_sensor2, o_sensor3, o_sensor4, o_sensor5 :  std_logic;
SIGNAL o_switch1, o_switch2, o_switch3 :   std_logic;
SIGNAL o_dirA1, o_dirA0, o_dirB1, o_dirB0:   std_logic;
SIGNAL o_track1, o_track2, o_track3, o_track4 :  std_logic;
SIGNAL o_clock, o_reset : std_logic;

-- Video Display Signals   
SIGNAL rom_address: std_logic_vector(11 DOWNTO 0);
SIGNAL H_count,V_count: std_logic_vector(9 DOWNTO 0);
SIGNAL F_count: std_logic_vector(4 DOWNTO 0);
SIGNAL Color_count: std_logic_vector(3 DOWNTO 0);
SIGNAL data: std_logic_vector(0 DOWNTO 0);
SIGNAL clock, Red_Data, Green_Data, Blue_Data, we, slow_clock: std_logic;
SIGNAL Red_Mux_Data, Green_Mux_Data, Blue_Mux_Data: std_logic;
SIGNAL Red_Display_Data, Green_Display_Data, Blue_Display_Data, display_item: std_logic;

-- Signals for Video Memory for Pixel Data
SIGNAL address: std_logic_vector(13 DOWNTO 0);
SIGNAL col_address, row_address: std_logic_vector(6 DOWNTO 0);
SIGNAL pixel_col_count, pixel_row_count: std_logic_vector(5 DOWNTO 0);
SIGNAL rom_output: std_logic_vector(0 DOWNTO 0);


-- Signals for Push buttons
SIGNAL KEY0_sync, KEY0_Single_Pulse: std_logic; 
SIGNAL KEY0_debounced, KEY0_debounced_Sync: std_logic; 
SIGNAL OLD_KEY0_debounced_Sync: std_logic;
SIGNAL KEY0_debounced_delay, Debounce_clock: std_logic;
SIGNAL SHIFT_KEY0 : std_logic_vector(3 DOWNTO 0);

constant H_max : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(799,10); 
-- 799 is max horiz count
constant V_max : std_logic_vector(9 DOWNTO 0) := CONV_STD_LOGIC_VECTOR(524,10); 
-- 524 is max vert count
SIGNAL video_on, video_on_H, video_on_V: std_logic;

BEGIN           
------------------------------------------------------------------------------
-- PLL below is used to generate the 25.175Mhz pixel clock frequency
-- Uses DE2's 50Mhz USB clock for PLL's input clock
video_PLL_inst : video_PLL PORT MAP (
		inclk0	 => CLOCK_50,
		c0	 => clock
	);-- 64 by 64 by 1 video rom for pixel background data
--
back_rom: lpm_rom

      GENERIC MAP (lpm_widthad => ADDR_WIDTH,
        lpm_outdata => "UNREGISTERED",
        lpm_address_control => "REGISTERED",
        lpm_file => "train.mif",
         lpm_width => DATA_WIDTH)
-- Reads in mif file for initial data - train track background
     
PORT MAP (inclock => clock, address => rom_address(11 DOWNTO 0), q => rom_output);

CONTROL: Tcontrol
-- Use Student supplied module for Train control
 port map( reset => reset, clock => slow_clock,
           sensor1 => sensor1, sensor2 => sensor2,
           sensor3 => sensor3, sensor4 => sensor4,
           sensor5 => sensor5,
           switch1 => switch1, switch2 => switch2,
           switch3 => switch3,
           track1 => track1, track2 => track2,
           track3 => track3, track4 => track4,
           DirA => DirA, DirB => DirB,
           Acount => Acount, Bcount => Bcount,
           status => LCD_status);


-- Copy state machine I/Os to Cyclone chip output pins for use by logic analyzer
o_sensor1 <= sensor1;     
o_sensor2 <= sensor2;     
o_sensor3 <= sensor3;     
o_sensor4 <= sensor4;     
o_sensor5 <= sensor5;     
o_switch1 <= switch1;
o_switch2 <= switch2;
o_switch3 <= switch3;
o_track1 <= track1;		
o_track2 <= track2;		
o_track3 <= track3;		
o_track4 <= track4;
o_dirA1 <= DirA(1);
o_dirA0 <= DirA(0);
o_dirB1 <= DirB(1);
o_dirB0 <= DirB(0);
o_clock <= slow_clock;
o_reset <= reset;

		
-- Colors for pixel data on video SIGNAL
-- address video_ram for pixel background color data
-- IF display_item='1' use display data instead of background
Red_Mux_Data <= rom_output(0) When display_item='0' else red_display_data;
Green_Mux_Data <= rom_output(0) When display_item='0' else green_display_data;
Blue_Mux_Data <= '1' When display_item='0' else blue_display_data;

Red_Data <=  (Red_Mux_Data xor (Crash and Second));
Green_Data <= (Green_Mux_Data xor (Crash and Second));
Blue_Data <= Blue_Mux_Data;

rom_address(11 DOWNTO 6) <= row_address(6 DOWNTO 1);
rom_address(5 DOWNTO 0) <= col_address(6 DOWNTO 1);

slow_clock <= Debounce_Clock;


VGA_R9 <=  Red_Data   AND video_on;
VGA_G9 <=  Green_Data AND video_on;
VGA_B9 <=  Blue_Data  AND video_on;

-- video_on turns off pixel data when not in the view area
video_on <= video_on_H and video_on_V;

-- Combine Dip Switch Inputs into Switch vector
Switch <= SW(0) & SW(1) & "00" &
          SW(2) & SW(3) & "00";

-- Controls Speed of TrainA with input from Flex Switches 7..4
SPEED_TRAINA: PROCESS 
BEGIN
  WAIT UNTIL (slow_clock'Event) and (slow_clock='1');
if Speed_A = Switch_Sync(7 DOWNTO 4) THEN
 Speed_A <="0000"; 
 Speed_Signal_A <='1';
ELSE
 Speed_A <= Speed_A + 1;
 Speed_Signal_A <='0';
END IF;
END PROCESS SPEED_TRAINA;

SPEED_TRAINB: PROCESS 
BEGIN
  WAIT UNTIL (slow_clock'Event) and (slow_clock='1');
if Speed_B = Switch_Sync(3 DOWNTO 0) THEN
 Speed_B <="0000"; 
 Speed_Signal_B <='1';
ELSE
 Speed_B <= Speed_B + 1;
 Speed_Signal_B <= '0';
END IF;
END PROCESS SPEED_TRAINB;

-- Makes KEY0 the Train Run/Step Button
PAUSE_TRAIN: PROCESS
BEGIN
  WAIT UNTIL (slow_clock'Event) and (slow_clock='1');
    IF KEY0_DEBOUNCED_SYNC /= OLD_KEY0_DEBOUNCED_SYNC THEN
		OLD_KEY0_DEBOUNCED_SYNC <= KEY0_DEBOUNCED_SYNC;
		IF KEY0_DEBOUNCED_SYNC = '1' THEN
			Train_Run <= Not Train_Run;
    		Old_sensor <= Sensor;
		End IF;
    End IF;
End PROCESS PAUSE_TRAIN;

Sensor <= Sensor5 & Sensor4 & Sensor3 & Sensor2 & Sensor1;

-- Stops Train only at Sensor Change for Single Step
STEP_TRAIN: PROCESS
BEGIN
  WAIT UNTIL (slow_clock'event) and (slow_clock = '1');
   IF Train_run = '1' THEN Train_stop <= '1'; ELSE
   IF (Sensor /= Old_Sensor) THEN 
    Train_stop <= '0';
   END IF;
   END IF;
End PROCESS STEP_TRAIN;

-- Move Train

-- Generate boolean signals for each track segment
-- to determine train's current location

C10A <= (trainAcol(6 DOWNTO 1) = "001000");
C30A <= (trainAcol(6 DOWNTO 1) = "011000");
C40A <= (trainAcol(6 DOWNTO 1)= "100000");
C50A <= (trainAcol(6 DOWNTO 1) = "101000");
C70A <= (trainAcol(6 DOWNTO 1) = "111000");
R10A <= (trainArow(6 DOWNTO 1) = "001000");
R30A <= (trainArow(6 DOWNTO 1) = "011000");
R4xA <= (trainArow(6 DOWNTO 4) = "100");
R5xA <= (trainArow(6 DOWNTO 4) = "101");
R70A <= (trainArow(6 DOWNTO 1) = "111000");

C10B <= (trainBcol(6 DOWNTO 1) = "001000");
C30B <= (trainBcol(6 DOWNTO 1) = "011000");
C40B <= (trainBcol(6 DOWNTO 1)= "100000");
C50B <= (trainBcol(6 DOWNTO 1) = "101000");
C70B <= (trainBcol(6 DOWNTO 1) = "111000");
R10B <= (trainBrow(6 DOWNTO 1) = "001000");
R30B <= (trainBrow(6 DOWNTO 1) = "011000");
R4xB <= (trainBrow(6 DOWNTO 4) = "100");
R5xB <= (trainBrow(6 DOWNTO 4) = "101");
R70B <= (trainBrow(6 DOWNTO 1) = "111000");

T1 <= (track1 = '1');
T2 <= (track2 = '1');
T3 <= (track3 = '1');
T4 <= (track4 = '1');

Next_TrainAcol <= TrainAcol + col_adjustA;
Next_TrainArow <= TrainArow + row_adjustA;
Next_TrainBcol <= TrainBcol + col_adjustB;
Next_TrainBrow <= TrainBrow + row_adjustB;
Crash <= CrashA or CrashB;

MOVE_TRAINA: PROCESS (reset, trainArow, slow_clock)
BEGIN 
  
IF reset='1' or trainArow = "0000000" THEN
 trainArow <= "0010000";
 trainAcol <= "0100000";
 old_trainArow <= "0010000";
 old_trainAcol <= "0100010";
 col_adjustA <= "0000000";
 row_adjustA <= "0000000";
 crashA <='0';
ELSIF (slow_clock'Event) and (slow_clock = '1') THEN

IF (trainArow=trainBrow) and (trainAcol=trainBcol) THEN 
 crashA <='1';
END IF;

IF (Speed_Signal_A = '1') and (crash='0')  and (Train_stop = '1') THEN

Old2_TrainAcol <= Old_TrainAcol;
Old2_TrainArow <= Old_TrainArow;
Old_TrainAcol <= TrainAcol;
Old_TrainArow <= TrainArow;
TrainAcol <= Next_TrainAcol;
TrainArow <= Next_TrainArow;
-----------------------------------------------------------
-- Track 1
IF R10A and not(C10A) and not(C70A) and not(C40A) THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
-- train is moving clockwise
  IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
   col_adjustA <= "0000001";
   row_adjustA <= "0000000";
  ELSE
   col_adjustA <= "0000000";
   row_adjustA <= "0000000";
  END IF;
 END IF;
ELSE

IF R10A and C10A THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

-- Switch 3 Location
IF R10A and C40A THEN
 IF Switch3 = '0' THEN
-- Switch connected to outside track
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
-- crash if going wrong way into switch
  IF old_trainArow > "0010000" THEN crashA <= '1'; END IF;
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE
-- Switch connected to inside track
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
-- crash if going wrong way into switch
  IF old_trainAcol > "1000001" THEN crashA <= '1'; END IF;
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
 END IF;
ELSE

IF R10A and C70A THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

IF C10A and not(R10A) and not(R70A) THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

IF C10A and R70A THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

IF C70A and not(R70A) and not(R10A) THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

-- Track 2 When col>=30 and <=50 else Track 1
IF R70A and not(C10A) and not(C70A) and not(C30A) and not(C50A) THEN
 IF trainAcol >= "0110000" and trainAcol <= "1010001" THEN
-- Track 2 region
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

-- Track 1 region
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
END IF;
ELSE

IF R70A and C70A THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

-- Switch 1 Location
IF R70A and C30A THEN
 IF Switch1 = '0' THEN
-- Switch connected to outside track
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
-- crash if going wrong way into switch
  IF old_trainArow < "1110000" THEN crashA <= '1'; END IF;
 ELSE
-- train is moving clockwise
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE
-- Switch connected to inside track
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 -- crash if going wrong way into switch
  IF old_trainAcol < "0110000" THEN crashA <= '1'; END IF;
ELSE
-- is train moving counterclockwise?
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
-- crash if going wrong way into switch
  IF old2_trainAcol(6 DOWNTO 1) < "011000" THEN crashA <= '1'; END IF;
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
 END IF;
ELSE

-- Switch 2 Location
IF R70A and C50A THEN
 IF Switch2 = '0' THEN
-- Switch connected to outside track
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
-- crash if going wrong way into switch
  IF old_trainArow < "1110000" THEN crashA <= '1'; END IF;
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE
-- Switch connected to inside track
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
-- crash if going wrong way into switch
  IF old_trainAcol > "1010001" THEN crashA <= '1'; END IF;
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
 END IF;
ELSE

------------------------------------------------------------
-- Track 3
IF C30A and not(R70A) and not(R30A) THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
-- train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

IF C30A and R30A THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
--  train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

IF R30A and not(C50A) and not(C30A) and not(C40A) THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
--  train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE
 
IF R30A and C40A THEN
-- Tracks cross which way was train moving?
IF Old_TrainArow /= "0110000" or TrainArow(0)='1' THEN
-- N/S Track
-- is train moving counterclockwise?
 IF (not(T4) and DirA(0)='1') or (T4 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T4) and DirA(1)='1') or (T4 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE
-- E/W Track
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
--  train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustA <= "0000001";
  row_adjustA <= "0000000";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
END IF;
ELSE


IF C50A and not(R70A) and not(R30A) THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

IF C50A and R30A THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustA <= "1111111";
  row_adjustA <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE

--------------------------------------------------------------------------
-- Track 4
IF C40A and not(R10A) THEN
-- is train moving counterclockwise?
 IF (not(T4) and DirA(0)='1') or (T4 and DirB(0)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T4) and DirA(1)='1') or (T4 and DirB(1)='1') THEN
  col_adjustA <= "0000000";
  row_adjustA <= "0000001";
  IF trainArow > "1010000" THEN CrashA <= '1'; END IF;
 ELSE
  col_adjustA <= "0000000";
  row_adjustA <= "0000000";
 END IF;
 END IF;
ELSE
 col_adjustA <= "0000000";
 row_adjustA <= "0000000";
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;

End PROCESS MOVE_TRAINA;


-----------------------------------------------------------
-- Move Train B
MOVE_TRAINB: PROCESS (reset, trainBrow, slow_clock)
BEGIN  
IF reset='1' or trainBrow = "0000000" THEN
 trainbrow <= "1000000";
 trainbcol <= "0110000";
 old_trainbrow <= "1000010";
 old_trainbcol <= "0110000";
 col_adjustB <= "0000000";
 row_adjustB <= "0000000";
 crashB <= '0';
ELSIF (slow_clock'Event) and (slow_clock = '1') THEN

IF (trainArow=trainBrow) and (trainAcol=trainBcol) THEN 
 crashB <='1';
END IF;

IF (Speed_Signal_B = '1') and (crash='0') and (Train_stop ='1') THEN

Old2_TrainBcol <= Old_TrainBcol;
Old2_TrainBrow <= Old_TrainBrow;
Old_TrainBcol <= TrainBcol;
Old_TrainBrow <= TrainBrow;
TrainBcol <= Next_TrainBcol;
TrainBrow <= Next_TrainBrow;
-----------------------------------------------------------
-- Track 1
IF R10B and not(C10B) and not(C70B) and not(C40B) THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
-- train is moving clockwise
  IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
   col_adjustB <= "0000001";
   row_adjustB <= "0000000";
  ELSE
   col_adjustB <= "0000000";
   row_adjustB <= "0000000";
  END IF;
 END IF;
ELSE

IF R10B and C10B THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

-- Switch 3 Location
IF R10B and C40B THEN
 IF Switch3 = '0' THEN
-- Switch connected to outside track
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
-- crash if going wrong way into switch
  IF old_trainBrow > "0010000" THEN crashB <= '1'; END IF;
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE
-- Switch connected to inside track
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
-- crash if going wrong way into switch
  IF old_trainBcol > "1000000" THEN crashB <= '1'; END IF;
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
 END IF;
ELSE

IF R10B and C70B THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

IF C10B and not(R10B) and not(R70B) THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

IF C10B and R70B THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

IF C70B and not(R70B) and not(R10B) THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

-- Track 2 When col>=30 and <=50 else Track 1
IF R70B and not(C10B) and not(C70B) and not(C30B) and not(C50B) THEN
 IF trainBcol >= "0110000" and trainBcol <= "1010001" THEN
-- Track 2 region
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

-- Track 1 region
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
END IF;
ELSE

IF R70B and C70B THEN
-- is train moving counterclockwise?
 IF (not(T1) and DirA(0)='1') or (T1 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T1) and DirA(1)='1') or (T1 and DirB(1)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

-- Switch 1 Location
IF R70B and C30B THEN
 IF Switch1 = '0' THEN
-- Switch connected to outside track
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
-- crash if going wrong way into switch
  IF old_trainBrow < "1110000" THEN crashB <= '1'; END IF;
 ELSE
-- train is moving clockwise
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE
-- Switch connected to inside track
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
-- is train moving counterclockwise?
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
-- crash if going wrong way into switch
  IF old_trainBcol < "0110000" THEN crashB <= '1'; END IF;
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
 END IF;
ELSE

-- Switch 2 Location
IF R70B and C50B THEN
 IF Switch2 = '0' THEN
-- Switch connected to outside track
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 -- crash if going wrong way into switch
  IF old_trainBrow < "1110000" THEN crashB <= '1'; END IF;
ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE
-- Switch connected to inside track=1
-- is train moving counterclockwise?
 IF (not(T2) and DirA(0)='1') or (T2 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T2) and DirA(1)='1') or (T2 and DirB(1)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
-- crash if going wrong way into switch
  IF old_trainBcol > "1010001" THEN crashB <= '1';  END IF;
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
 END IF;
ELSE

------------------------------------------------------------
-- Track 3
IF C30B and not(R70B) and not(R30B) THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
-- train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

IF C30B and R30B THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
--  train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

IF R30B and not(C50B) and not(C30B) and not(C40B) THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
--  train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE
 
IF R30B and C40B THEN
-- Tracks cross which way was train moving?
IF Old_TrainBrow /= "0110000" or TrainBrow(0)='1'  THEN
-- N/S Track
-- is train moving counterclockwise?
 IF (not(T4) and DirA(0)='1') or (T4 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T4) and DirA(1)='1') or (T4 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE
-- E/W Track
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
--  train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustB <= "0000001";
  row_adjustB <= "0000000";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
END IF;
ELSE


IF C50B and not(R70B) and not(R30B) THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

IF C50B and R30B THEN
-- is train moving counterclockwise?
 IF (not(T3) and DirA(0)='1') or (T3 and DirB(0)='1') THEN
  col_adjustB <= "1111111";
  row_adjustB <= "0000000";
 ELSE
-- train is moving clockwise
 IF (not(T3) and DirA(1)='1') or (T3 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE

--------------------------------------------------------------------------
-- Track 4
IF C40B and not(R10B) THEN
-- is train moving counterclockwise?
 IF (not(T4) and DirA(0)='1') or (T4 and DirB(0)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "1111111";
 ELSE
-- train is moving clockwise
 IF (not(T4) and DirA(1)='1') or (T4 and DirB(1)='1') THEN
  col_adjustB <= "0000000";
  row_adjustB <= "0000001";
-- Check for end of Track 4
  IF trainBrow > "1010000" THEN CrashB <= '1'; END IF;
 ELSE
  col_adjustB <= "0000000";
  row_adjustB <= "0000000";
 END IF;
 END IF;
ELSE
 col_adjustB <= "0000000";
 row_adjustB <= "0000000";
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;

End PROCESS MOVE_TRAINB;

-- Compute Track Sensor Values
COMPUTE_SENSOR: PROCESS (trainarow, trainacol, trainbrow, trainbcol, 
C10A,C30A,C40A,C50A,C70A,R10A,R30A,R70A,R4xA,R5xA,T1,T2,
T3,T4,C10B,C30B,C40B,C50B,C70B,R10B,R30B,R70B,R4xB,R5xB)
BEGIN

 IF (C10A and R5xA) OR  (C10B and R5xB) THEN
  sensor1 <= '1';
 ELSE
  sensor1 <= '0';
 END IF;
 
 IF (C30A and R5xA) OR (C30B and R5xB) THEN
  sensor2 <= '1';
 ELSE
  sensor2 <= '0';
 END IF;

 IF (C50A and R5xA) OR (C50B and R5xB) THEN
  sensor3 <= '1';
 ELSE
  sensor3 <= '0';
 END IF;

 IF (C70A and R5xA) OR (C70B and R5xB) THEN
  sensor4 <= '1';
 ELSE
  sensor4 <= '0';
 END IF;

 IF (R4xA and C40A) OR (R4xB and C40B) THEN
  sensor5 <= '1';
 ELSE
  sensor5 <= '0';
 END IF;

End PROCESS COMPUTE_SENSOR;

-- Display Sensor, Switch, and Train
TRAIN_DISPLAY: PROCESS
BEGIN
Wait UNTIL(Clock'Event) and (Clock='1');

-- Display Train
-- Train A
IF ((trainAcol(6 DOWNTO 1) = col_address(6 DOWNTO 1)) and 
   (trainArow(6 DOWNTO 1) = row_address(6 DOWNTO 1))) THEN
     display_item <= '1';
     red_display_data <= '0';
     green_display_data <='0';
     blue_display_data <= '0';
else


IF ((old_trainAcol(6 DOWNTO 1) = col_address(6 DOWNTO 1)) and 
   (old_trainArow(6 DOWNTO 1) = row_address(6 DOWNTO 1))) THEN
     display_item <= '1';
     red_display_data <= '0';
     green_display_data <='0';
     blue_display_data <= '0';
else

IF ((old2_trainAcol(6 DOWNTO 1) = col_address(6 DOWNTO 1)) and 
   (old2_trainArow(6 DOWNTO 1) = row_address(6 DOWNTO 1))) THEN
     display_item <= '1';
     red_display_data <= '0';
     green_display_data <='0';
     blue_display_data <= '0';
else

-- Train B
IF ((trainBcol(6 DOWNTO 1) = col_address(6 DOWNTO 1)) and 
   (trainBrow(6 DOWNTO 1) = row_address(6 DOWNTO 1))) THEN
     display_item <= '1';
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
else

IF ((old_trainBcol(6 DOWNTO 1) = col_address(6 DOWNTO 1)) and 
   (old_trainBrow(6 DOWNTO 1) = row_address(6 DOWNTO 1))) THEN
     display_item <= '1';
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
else

IF ((old2_trainBcol(6 DOWNTO 1) = col_address(6 DOWNTO 1)) and 
   (old2_trainBrow(6 DOWNTO 1) = row_address(6 DOWNTO 1))) THEN
     display_item <= '1';
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
else



-- Display Switch
-- switch 3 display
IF row_address(6 DOWNTO 1) = "000110" and
   col_address(6 DOWNTO 1) = "100000" THEN
      display_item <= '1';
  IF switch3 = '0' THEN
     red_display_data <= '0';
     green_display_data <='1';
     blue_display_data <= '0';
    else
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
    END IF;
else

-- switch 2 display
IF row_address(6 DOWNTO 1) = "111010" and
   col_address(6 DOWNTO 1) = "101000" THEN
     display_item <= '1';
    IF switch2 = '0' THEN
     red_display_data <= '0';
     green_display_data <='1';
     blue_display_data <= '0';
    else
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
    END IF;
else

-- switch 1 display
IF row_address(6 DOWNTO 1) = "111010" and
   col_address(6 DOWNTO 1) = "011000" THEN
     display_item <= '1';
    IF switch1 = '0' THEN
     red_display_data <= '0';
     green_display_data <='1';
     blue_display_data <= '0';
    else
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
    END IF;
else

-- sensor display
-- sensor 5
IF row_address(6 DOWNTO 1) = "011100" and
   col_address(6 DOWNTO 1) = "100100" THEN
      display_item <= '1';
   IF sensor5 = '0' THEN
     red_display_data <= '0';
     green_display_data <='1';
     blue_display_data <= '0';
    else
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
    END IF;
else

-- sensor 1
IF row_address(6 DOWNTO 1) = "110000" and
  col_address(6 DOWNTO 1) = "000100" THEN
    display_item <= '1';
    IF sensor1 = '0' THEN
     red_display_data <= '0';
     green_display_data <='1';
     blue_display_data <= '0';
    else
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
    END IF;
   else

-- sensor 2
IF row_address(6 DOWNTO 1) = "110000" and
   col_address(6 DOWNTO 1) = "010100" THEN
    display_item <= '1';
    IF sensor2 = '0' THEN
     red_display_data <= '0';
     green_display_data <='1';
     blue_display_data <= '0';
    else
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
    END IF;
   else

-- sensor 3
IF row_address(6 DOWNTO 1) = "110000" and
   col_address(6 DOWNTO 1) = "101100" THEN
    display_item <= '1';
    IF sensor3 = '0' THEN
     red_display_data <= '0';
     green_display_data <='1';
     blue_display_data <= '0';
    else
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
    END IF;
  else

-- sensor 4
IF row_address(6 DOWNTO 1) = "110000" and
   col_address(6 DOWNTO 1) = "111011" THEN
    display_item <= '1';
    IF sensor4 = '0' THEN
     red_display_data <= '0';
     green_display_data <='1';
     blue_display_data <= '0';
    else
     red_display_data <= '1';
     green_display_data <='0';
     blue_display_data <= '0';
    END IF;
-- no items to display use memory for backgound colors
  else
   display_item <='0';
  END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
END IF;
End PROCESS TRAIN_DISPLAY;

			-- Outputs for Video DAC
VGA_BLANK <= video_on;
VGA_CLK   <= clock;
--Generate Horizontal and Vertical Timing Signals for Video Signal
VIDEO_DISPLAY: PROCESS
BEGIN

Wait UNTIL(Clock'Event) and (Clock='1');
IF Reset = '1' THEN
 H_count <= CONV_STD_LOGIC_VECTOR(0,10);
 V_count <= CONV_STD_LOGIC_VECTOR(0,10);
 Video_on_H <= '0';
 Video_on_V <= '0';
ELSE
-- H_count counts pixels (640 + extra time for sync signals)
--
--   <-Clock out RGB Pixel Row Data ->   <-H Sync->
--   ------------------------------------__________--------
--   0                           640   659       755    799
--
IF (H_count >= H_max) THEN
   H_count <= "0000000000";
ELSE
   H_count <= H_count + "0000000001";
END IF;

--Generate Horizontal Sync Signal
IF (H_count <= CONV_STD_LOGIC_VECTOR(755,10)) and (H_count >= CONV_STD_LOGIC_VECTOR(659,10)) THEN
   VGA_HS <= '0';
ELSE
   VGA_HS <= '1';
END IF;

--V_count counts rows of pixels (480 + extra time for sync signals)
--
--  <---- 480 Horizontal Syncs (pixel rows) -->  ->V Sync<-
--  -----------------------------------------------_______------------
--  0                                       480    493-494          524
--
IF (V_count >= V_max) and (H_count >= CONV_STD_LOGIC_VECTOR(699,10)) THEN
   V_count <= "0000000000";
ELSE IF (H_count = CONV_STD_LOGIC_VECTOR(699,10)) THEN
   V_count <= V_count + "0000000001";
END IF;
END IF;

-- Generate Vertical Sync Signal
IF (V_count <= CONV_STD_LOGIC_VECTOR(494,10)) and (V_count >= CONV_STD_LOGIC_VECTOR(493,10)) THEN
   VGA_VS <= '0';
   Debounce_Clock <= '0';
ELSE
   VGA_VS <= '1';
   Debounce_Clock <= '1';
END IF;



-- Generate Video on Screen Signals for Pixel Data
-- Generate row and col address for 5 by 4 superpixel to map into 64 by 64 video memory
--
IF (H_count <= CONV_STD_LOGIC_VECTOR(639,10)) THEN
   video_on_H <= '1';
IF pixel_col_count < CONV_STD_LOGIC_VECTOR(4,6) THEN
   pixel_col_count <= pixel_col_count + '1';
ELSE
   pixel_col_count <= "000000";
   col_address <= col_address + '1';
END IF;
ELSE
   video_on_H <= '0';
   pixel_col_count <= "000000";
   col_address <= "0000000";
END IF;

IF(H_COUNT = CONV_STD_LOGIC_VECTOR(641,10)) THEN
    pixel_row_count <= pixel_row_count + '1';
IF (pixel_row_count = CONV_STD_LOGIC_VECTOR(3,6)) THEN
   pixel_row_count <= "000000";
   row_address <= row_address + '1';
END IF;
END IF;

IF (V_count <= CONV_STD_LOGIC_VECTOR(479,10)) THEN
   video_on_V <= '1';
ELSE
   video_on_V <= '0';
   pixel_row_count <= "000000";
   row_address <= "0000000";
END IF;


IF (V_count = CONV_STD_LOGIC_VECTOR(0,10)) and (H_count = CONV_STD_LOGIC_VECTOR(0,10)) THEN
IF (F_count = CONV_STD_LOGIC_VECTOR(30,5)) THEN
   F_count <= "00000";
   second <= not second;
ELSE 
   F_count <= F_count + "00001";
END IF;
END IF;
END IF;

END PROCESS VIDEO_DISPLAY;
-- Generate reset signal
PROCESS
BEGIN 
   WAIT UNTIL (clock'Event) and (clock = '1');
   reset <= NOT KEY(1);
END PROCESS ;
-- Sync external pushbutton and reset input to chip clock
PUSH_BUTTON: PROCESS
BEGIN
  WAIT UNTIL (debounce_clock'event) and (debounce_clock='1');
KEY0_Sync <= NOT KEY(0);
Switch_Sync <= Switch;
KEY0_DEBOUNCED_SYNC <= KEY0_DEBOUNCED;
END PROCESS PUSH_BUTTON;

-- Debounce Button: Filters out mechanical bounce for around 80Ms.
-- Debounce clock uses VGA_VSync timing signal (16Ms) to save hardware
-- for clock prescaler
DEBOUNCE_BUTTON1: PROCESS
BEGIN
  WAIT UNTIL (debounce_clock'event) and (debounce_clock='1');
  SHIFT_KEY0(2 DOWNTO 0) <= SHIFT_KEY0(3 DOWNTO 1);
  SHIFT_KEY0(3) <= KEY0_Sync;
  IF SHIFT_KEY0(3 DOWNTO 0)="1111" THEN
    KEY0_DEBOUNCED <= '1';
  ELSE 
    KEY0_DEBOUNCED <= '0';
  END IF;
END PROCESS DEBOUNCE_BUTTON1;


SINGLE_PULSE_KEY0: PROCESS
BEGIN
  WAIT UNTIL (CLOCK'event) and (CLOCK='1');
  IF RESET='1' THEN
  KEY0_SINGLE_PULSE <='0';
  KEY0_DEBOUNCED_DELAY <= '1';
  ELSE
-- Generates Single Clock Cycle Pulse When Switch Hit
-- No matter how long switch is held down
  IF KEY0_DEBOUNCED_SYNC = '1' AND KEY0_DEBOUNCED_DELAY = '0' THEN
   KEY0_SINGLE_PULSE <= '1';
  ELSE
   KEY0_SINGLE_PULSE <= '0';
  END IF;
  KEY0_DEBOUNCED_DELAY <= KEY0_DEBOUNCED_SYNC;
 END IF;
END PROCESS SINGLE_PULSE_KEY0;

-- LCD Display Code for Train Status
-- ASCII hex values for LCD Display
-- Enter Live Hex Data Values from hardware here
-- LCD DISPLAYS THE FOLLOWING:
-------------------------
--| sXXXXXtXXXXswXXX   |
--| Zustand daXX dbXX  |
-------------------------
LCD_display_string <= (

-- Line 1
X"73", X"0" & "000" & Sensor5, X"0" & "000" & Sensor4,
X"0" & "000" & Sensor3, X"0" & "000" & Sensor2, X"0" & "000" & Sensor1,
X"74", X"0" & "000" & Track4, X"0" & "000" & Track3,
X"0" & "000" & Track2, X"0" & "000" & Track1,
X"73",X"77", X"0" & "000" & Switch3, X"0" & "000" & Switch2,
X"0" & "000" & Switch1, 

-- Line 2
char2ascii(LCD_status(1)),
char2ascii(LCD_status(2)),
char2ascii(LCD_status(3)),
char2ascii(LCD_status(4)),
char2ascii(LCD_status(5)),
char2ascii(LCD_status(6)),
X"20",X"64",X"61", X"0" & "000" & DIRA(1), X"0" & "000" & DIRA(0),
X"20",X"64",X"62", X"0" & "000" & DIRB(1), X"0" & "000" & DIRB(0));

-- 7-Segment Display to show number of turns for Train A and B
HEX0 <= hex7seg(Bcount);
HEX3 <= hex7seg(Acount);

-- BIDIRECTIONAL TRI STATE LCD DATA BUS
	LCD_DATA <= DATA_BUS_VALUE WHEN LCD_RW_INT = '0' ELSE "ZZZZZZZZ";
-- get next character in display string
	Next_Char <= LCD_display_string(CONV_INTEGER(CHAR_COUNT));
	LCD_RW <= LCD_RW_INT;
LCD_CLOCK: PROCESS
	BEGIN
	 WAIT UNTIL CLOCK'EVENT AND CLOCK = '1';
		IF RESET = '1' THEN
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
	END PROCESS LCD_CLOCK;
	LCD_ON <= '1';
LCD_DISPLAY:	PROCESS (CLK_400HZ, reset)
	BEGIN
		IF reset = '1' THEN
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
-- Write ASCII hex character in first LCD character location
				WHEN Print_String =>
						LCD_EN <= '1';
						LCD_RS <= '1';
						LCD_RW_INT <= '0';
-- ASCII character to output
						IF Next_Char(7 DOWNTO  4) /= X"0" THEN
						DATA_BUS_VALUE <= Next_Char;
						ELSE
-- Convert 4-bit value to an ASCII hex digit
							IF Next_Char(3 DOWNTO 0) >9 THEN
-- ASCII A...F
							 DATA_BUS_VALUE <= X"4" & (Next_Char(3 DOWNTO 0)-9);
							ELSE
-- ASCII 0...9
							 DATA_BUS_VALUE <= X"3" & Next_Char(3 DOWNTO 0);
							END IF;
						END IF;
						state <= DROP_LCD_E;
-- Loop to send out 32 characters to LCD Display  (16 by 2 lines)
						IF (CHAR_COUNT < 31) AND (Next_Char /= X"FE") THEN 
						 CHAR_COUNT <= CHAR_COUNT +1;
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
-- The next three states occur at the end of each command or data transfer to the LCD
-- Drop LCD E line - falling edge loads inst/data to LCD controller
				WHEN DROP_LCD_E =>
						LCD_EN <= '0';
						state <= HOLD;
-- Hold LCD inst/data valid after falling edge of E line				
				WHEN HOLD =>
						state <= next_command;
			END CASE;
		END IF;
	END PROCESS LCD_DISPLAY;
END behavior;

