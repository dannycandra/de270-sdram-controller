---------------------------------------------------------------------------
-- Funktion : Test Programm fuer extern SDRAM0 Speichers auf dem DE2-70 Board
-- Filename : TestSDRAM0.vhd
-- Beschreibung : Test Programm fuer SDRAM0 Controller 
--                4M x 16bit x 4 Banks SDRAM (IS42S16160B)
--                single burst write or read
--                100 Mhz (1 clktick = 10ns)
-- Standard : VHDL 1993

-- Author : Danny Candra
-- Revision : Version 0.1 
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

--TOP ENTITY NAME : TestSDRAM0
--ARCHITECTURE NAME : verhalten

Entity TestSDRAM0 IS
    GENERIC (                                   -- Die Werte sind der Anzahl von Bits (16 bits bedeutet vector von 0 - 15)
            del 					: integer := 16;  -- fuer skalieren von 200 us counter
            len_auto_ref 		: integer := 10;  -- fuer auto refresh zaehler
            len_small 			: integer := 8;   -- fuer trc,trc, usw nachdem init
            addr_bits_to_dram : integer := 13;  -- Anzahladresse nach dram (A0-A12)
            addr_bits_from_up : integer := 24;  -- Anzahladresse von up (A0-A12)+(A0-A8)+(B0-B1)
            ba_bits 				: integer := 2;   -- Anzahl von bankadress bits
				dqsize				: integer := 16); -- Die Groesse des Datenbus (DQ0-DQ15) 
	Port(
			-- LCD Ports
			oLCD_RS, oLCD_EN, oLCD_RW  : OUT STD_LOGIC;
			oLCD_ON, oLCD_BLON 			: OUT STD_LOGIC;
			LCD_D 							: INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);	
			
			-- SDRAM Ports
			oDRAM0_A		 : OUT STD_LOGIC_VECTOR (addr_bits_to_dram - 1 DOWNTO 0) ; -- SDRAM0 Adresse
			oDRAM0_BA    : OUT STD_LOGIC_VECTOR (ba_bits - 1 DOWNTO 0); -- SDRAM0 Bank
			oDRAM0_CLK   : OUT STD_LOGIC ; -- Clock 
			oDRAM0_CKE   : OUT STD_LOGIC ; -- Clock enable
			oDRAM0_CAS_N : OUT STD_LOGIC ; -- Spaltenadresse Abtastzeit
			oDRAM0_RAS_N : OUT STD_LOGIC ; -- Zeilenadresse Abtastzeit
			oDRAM0_WE_N  : OUT STD_LOGIC ; -- Write enable
			oDRAM0_CS_N  : OUT STD_LOGIC ; -- Chip select
			oDRAM0_LDQM0 : OUT STD_LOGIC ; --	Untere Datenmaske
			oDRAM0_UDQM1 : OUT STD_LOGIC ; --	Obere Datenmaske  		  
			DRAM_DQ      : inout	std_logic_vector(dqsize-1 downto 0);	-- SDRAM DQ 0-15 => SDRAM0, 16-31 => SDRAM1  -- Datenbus
			
			-- Restliche Ports
			temp_data				: OUT STD_LOGIC_VECTOR (15 downto 0);
			test_zustand : OUT STD_LOGIC_VECTOR (3 downto 0);
			oLEDG   : OUT STD_LOGIC_VECTOR(7 downto 0);
			iCLK_50 : IN STD_LOGIC;
			iKEY    : inout std_logic_vector (3 downto 0)); 
END TestSDRAM0;


--##############################################################################
--Architektur begin
--##############################################################################
ARCHITECTURE verhalten OF TestSDRAM0 IS

--Funktion Deklaration 
--#################################################################################
--Diese Funktion inkrementiert ein std_logic_vector typ um '1'
--typische benutzung next_count <= incr_vec(next_count);
--wenn zaehler erreicht den hochsten Wert(alle ein) dann ist der naechste Wert 0
--when count reaches the highest value(all ones), the next count is zero.
--#################################################################################
FUNCTION incr_vec(s1:STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is  
        VARIABLE V  : STD_LOGIC_VECTOR(s1'high DOWNTO s1'low) ; 
        VARIABLE tb : STD_LOGIC_VECTOR(s1'high DOWNTO s1'low); 
        BEGIN 
        tb(s1'low) := '1'; 
        V := s1; 
        for i in (V'low + 1) to V'high loop 
            tb(i) := V(i - 1) and tb(i -1); 
        end loop; 
        for i in V'low to V'high loop    
            if(tb(i) = '1') then 
                V(i) := not(V(i)); 
            end if; 
        end loop; 
        return V; 
        end incr_vec; -- end function 
--######################### ENDE FUNKTION incr_vec #################################

-- Component Deklaration
	-- COMPONENT SDRAM 
	COMPONENT sdram0_ctrl IS
	port(		  
		  -- SDRAM0 pins 
        oDRAM0_A		: OUT STD_LOGIC_VECTOR (addr_bits_to_dram - 1 DOWNTO 0) ; -- SDRAM0 Adresse
        oDRAM0_BA    : OUT STD_LOGIC_VECTOR (ba_bits - 1 DOWNTO 0);            -- SDRAM0 Bank
        oDRAM0_CLK   : OUT STD_LOGIC ; 													 -- Clock 
        oDRAM0_CKE   : OUT STD_LOGIC ; 												    -- Clock enable
        oDRAM0_CAS_N : OUT STD_LOGIC ;														 -- Spaltenadresse Abtastzeit
        oDRAM0_RAS_N : OUT STD_LOGIC ;														 -- Zeilenadresse Abtastzeit
        oDRAM0_WE_N 	: OUT STD_LOGIC ;														 -- Write enable
        oDRAM0_CS_N  : OUT STD_LOGIC ;														 -- Chip select
        oDRAM0_LDQM0	: OUT STD_LOGIC ;														 -- Untere Datenmaske
		  oDRAM0_UDQM1	: OUT STD_LOGIC ;														 -- Obere Datenmaske  		  
		  DRAM_DQ      : inout std_logic_vector(dqsize-1 downto 0);					 -- SDRAM DQ 0-15 => SDRAM0, 16-31 => SDRAM1  -- Datenbus
        ------ SDRAM0 pins Ende
        -- clk and reset signals 
        clk_in  : IN STD_LOGIC;
		  clk_out : OUT STD_LOGIC;
        reset   : IN STD_LOGIC;
        ------ clk and reset signals Ende
		  -- Benutzer Schnittstelle 
        addr_from_up 	: IN STD_LOGIC_VECTOR (addr_bits_from_up -1 DOWNTO 0) ;
        rd_n_from_up 	: IN STD_LOGIC ;
        wr_n_from_up 	: IN STD_LOGIC ;
        dram_init_done  : OUT STD_LOGIC ;
        dram_busy 		: OUT STD_LOGIC ;
		  datain				: IN STD_LOGIC_VECTOR(dqsize-1 downto 0);	   --	 Dateneingang fuer SDRAM Controller von Benutzer
        dataout 			: OUT STD_LOGIC_VECTOR(dqsize-1 downto 0); 	--  Datenausgang fuer Benutzer von SDRAM Controller
		   sdram_zustand	: OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
		  ------ Benutzer Schnittstelle Ende
        );	 	  
	END COMPONENT sdram0_ctrl;
		
	-- COMPONENT LCD_Line
	COMPONENT LCD_Line IS
		PORT(reset, CLOCK_50      : IN STD_LOGIC;
			Lin1, Lin2 				  : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
			LCD_RS, LCD_EN, LCD_RW : OUT STD_LOGIC;
			LCD_ON, LCD_BLON       : OUT STD_LOGIC;
			LCD_DATA               : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0));
	END COMPONENT LCD_Line;	
		
	-- Signal Deklarationen
	signal lcdline1_sig, lcdline2_sig : STD_LOGIC_VECTOR(127 downto 0);
	signal reset_sig 						 : STD_LOGIC := '0';	
	signal addr_sig 				 		 : STD_LOGIC_VECTOR (addr_bits_from_up -1 DOWNTO 0) := (others => '0') ;
	signal read_n_sig 		  			 : STD_LOGIC;
	signal write_n_sig        			 : STD_LOGIC;
	signal dram_init_done_sig 	 		 : STD_LOGIC;
	signal dram_busy_sig  				 : STD_LOGIC;
	signal data_in_sig    		 		 : STD_LOGIC_VECTOR(dqsize-1 downto 0);
	signal data_out_sig   				 : STD_LOGIC_VECTOR(dqsize-1 downto 0);
	signal sig_clk_tb     				 : STD_LOGIC;
	signal write_zaehler_sig			 : STD_LOGIC_VECTOR (3 downto 0);
	signal read_zaehler_sig			 	 : STD_LOGIC_VECTOR (3 downto 0);
	signal sdram_zustand_sig			 : STD_LOGIC_VECTOR (2 downto 0);
		
	-- Zustände
	type TestProg_zustand is (TEST_WAIT_INIT, TEST_IDLE_STATE, TEST_WRITE_STATE, TEST_READ_STATE);
	signal AKTUALZUSTAND : TestProg_zustand := TEST_WAIT_INIT;
	
BEGIN

-- Component Initialisieren
	SDRAM0_CONTROLLER: sdram0_ctrl
	Port map(		  
        oDRAM0_A			=>	oDRAM0_A, 				-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        oDRAM0_BA    	=>	oDRAM0_BA,				-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        oDRAM0_CLK   	=> oDRAM0_CLK,				-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        oDRAM0_CKE   	=> oDRAM0_CKE,				-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        oDRAM0_CAS_N 	=> oDRAM0_CAS_N,			-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        oDRAM0_RAS_N 	=> oDRAM0_RAS_N,			-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        oDRAM0_WE_N 		=> oDRAM0_WE_N,			-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        oDRAM0_CS_N  	=> oDRAM0_CS_N,			-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        oDRAM0_LDQM0		=> oDRAM0_LDQM0,			-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
		  oDRAM0_UDQM1		=> oDRAM0_UDQM1,			-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
		  DRAM_DQ 			=> DRAM_DQ,      		 	-- SDRAM Port von TestProg an Component sdram0_ctrl weiterleiten
        clk_in 			=> iCLK_50,					-- iCLK Port von TestProg an Component sdram0_ctrl weiterleiten
		  clk_out			=> sig_clk_tb,				-- 100 Mhz clk von sdram0_ctrl an TestProg weiterleiten
        reset  			=> reset_sig,				-- Reset signal von TestProg an Component sdram0_ctrl weiterleiten
        addr_from_up 	=> addr_sig,				-- Gewuenschte Adresse von TestProg an Component sdram0_ctrl weiterleiten
        rd_n_from_up 	=> read_n_sig,				-- Read Befehl von TestProg an Component sdram0_ctrl weiterleiten
        wr_n_from_up 	=> write_n_sig,   		-- Write Befehl von TestProg an Component sdram0_ctrl weiterleiten
        dram_init_done  => dram_init_done_sig,  -- Status von Component sdram0_ctrl
        dram_busy 		=> dram_busy_sig, 		-- Status von Component sdram0_ctrl
		  datain				=> data_in_sig,			-- Daten zum schreiben (TestProg -> sdram0ctrl)
		  dataout 			=> data_out_sig,			-- Daten zum lesen (sdram0ctrl -> TestProg)
		  sdram_zustand	=> sdram_zustand_sig
 );

	LCDDE2: LCD_Line
	Port map(
			reset 		=> '1',
			LCD_RS 		=> oLCD_RS, 
			LCD_EN 		=> oLCD_EN, 
			LCD_RW 		=> oLCD_RW,
			LCD_ON 		=> oLCD_ON, 
			LCD_BLON 	=> oLCD_BLON,
			LCD_DATA 	=> LCD_D,
			CLOCK_50 	=> sig_clk_tb,
			Lin1 			=> lcdline1_sig,
			Lin2 			=> lcdline2_sig
	);
	
--################################################################################################################
-- Process: Testen
-- Diese Prozess schreibt fuer jede SDRAM Zelle (16bit) daten
-- Dannach Daten aus SDRAM lesen und vergleichen ob die Daten richtig eingetragen wurden
--################################################################################################################
	testen: PROCESS(sig_clk_tb,iKey)
	BEGIN
	   IF (iKey = "1110")THEN
			reset_sig <= '1';															-- reset senden
			temp_data <= "0000000000000000";
			addr_sig <= "000000000000000000000000";
			data_in_sig <= "0000000000001010";
			write_n_sig <= '1';														-- write signal initialisieren
			read_n_sig <= '1';														-- read signal initialisieren
			AKTUALZUSTAND <= TEST_WAIT_INIT;
		ELSIF(RISING_EDGE(sig_clk_tb)) THEN
			CASE AKTUALZUSTAND IS
				WHEN TEST_WAIT_INIT	 => -- Warten auf SDRAM sich zu initialisieren
												 test_zustand <= "0000";
												 reset_sig <= '0';													-- reset signal ausschalten
												 if(dram_init_done_sig = '1') THEN
													AKTUALZUSTAND <= TEST_IDLE_STATE;
												 END IF;
												 
				WHEN TEST_IDLE_STATE => 
												test_zustand <= "0001";
												addr_sig <= "000000000000000000000000";
												data_in_sig <= "0000000000001010";
												IF (iKey = "1101")THEN
													AKTUALZUSTAND <= TEST_WRITE_STATE;
												ELSIF (iKey = "1011")THEN
													AKTUALZUSTAND <= TEST_READ_STATE;
												END IF;
																						 
				WHEN TEST_WRITE_STATE => -- Daten in SDRAM Schreiben	
												test_zustand <= "0010";
												IF(dram_busy_sig = '0') THEN										-- Sende Schreibtbefehl wenn SDRAM in IDLE zustand ist
													write_n_sig <= '0';						
												END IF;
												
												-- wenn schreibbefehl gesendet wurde dann starte den Timer solange den schreibbefehl noch da und SDRAM zustand auf Schreiben steht
												-- es kann sein dass auto refresh gemacht werden muss während man schreiben will, in diesem fall wird den Schreibvorgang blockiert bis
												-- SDRAM fertig mit auto refresh ist
											   IF((write_n_sig = '0') AND (sdram_zustand_sig = "010"))THEN 
													write_zaehler_sig <= incr_vec(write_zaehler_sig);           
												 END IF;		
												 
												-- wenn schreibbefehl gesendet wurde dann starte den Timer solange den schreibbefehl noch da und SDRAM zustand auf Schreiben steht
												-- es kann sein dass auto refresh gemacht werden muss während man schreiben will, in diesem fall wird den Schreibvorgang blockiert bis
												-- SDRAM fertig mit auto refresh ist
											   IF((write_n_sig = '0') AND (sdram_zustand_sig = "010"))THEN 
													write_zaehler_sig <= "0000";									-- initialisiert schreibzaehler
													write_n_sig	<= '1';												-- Schreibbefehl zurücknehmen
													addr_sig <= incr_vec(addr_sig);								-- inkrementiert die Adresse
													data_in_sig <= incr_vec(data_in_sig);						-- inkrementiert die Daten
													
													IF(addr_sig = "000000000000000000000010")THEN
														addr_sig <= "000000000000000000000000";
														AKTUALZUSTAND <= TEST_IDLE_STATE;						-- naechste Schritt
													END IF;
												END IF;										   
				
				WHEN TEST_READ_STATE => -- Daten in SDRAM Lesen		
												test_zustand <= "0011";
												IF(dram_busy_sig = '0')THEN			
													read_n_sig <='0'; 		--	 |									-- Signalisieren dass das Testprogramm was lesen will
												END IF;
												
												-- wenn Lesebefehl gesendet wurde dann starte den Timer solange den Lesebefehl noch da und SDRAM zustand auf Lesen steht
												-- es kann sein dass auto refresh gemacht werden muss während man schreiben will, in diesem fall wird den Lesevorgang blockiert bis
												-- SDRAM fertig mit auto refresh ist
											   IF(read_n_sig = '0')AND (sdram_zustand_sig = "011") THEN	
													read_zaehler_sig <= incr_vec(read_zaehler_sig);           
												 END IF; 
												 
												IF(read_zaehler_sig = "1000") THEN								-- 8 Takte Warten
													read_n_sig <= '1';												-- Schreibbefehl zurücknehmen
													addr_sig <= incr_vec(addr_sig);								-- inkrementiert die Adresse	
													temp_data <= data_out_sig ;									-- Daten aus SDRAM in einem Lokalen Signal speichern
													read_zaehler_sig <= "0000";									-- initialisiert schreibzaehler
													IF(addr_sig = "000000000000000000000010")THEN
														addr_sig <= "000000000000000000000000";
														AKTUALZUSTAND <= TEST_IDLE_STATE;	-- naechste Schritt
													END IF;
												END IF;
			END CASE;
		END IF;
	END PROCESS testen;
	
--################################################################################################################
-- Process: Ergebnis zeigen
-- Falls kein Fehler gibt dann zeigt "TEST OK"
-- Sonst "FEHLER"
--################################################################################################################
	ergebniszeigen: PROCESS(iCLK_50)	
	BEGIN
		CASE AKTUALZUSTAND IS
			WHEN TEST_WAIT_INIT	 => 	-- Status Warten auf SDRAM
												lcdline1_sig <= "01010100011001010111001101110100010100000111001001101111011001110111001001100001011011010101001101000100010100100100000101001101";
												lcdline2_sig <= "01010011010001000101001001000001010011010010000000101101001000000100100101001110010010010101010000100000001000000010000000100000";
			WHEN TEST_IDLE_STATE  =>	-- Status Warten auf Eingabe
												lcdline1_sig <= "01001011011001010111100100110001001000000011110100100000010101110111001001101001011101000110010100100000001000000010000000100000";
												lcdline2_sig <= "01001011011001010111100100110010001111010010000001010010011001010110000101100100001000000010000000100000001000000010000000100000";
			WHEN TEST_WRITE_STATE => 	-- Status am Schreiben
												lcdline1_sig <= "01010100011001010111001101110100010100000111001001101111011001110111001001100001011011010101001101000100010100100100000101001101";
												lcdline2_sig <= "01010011010001000101001001000001010011010010000000101101001000000101001101100011011010000111001001100101011010010110001001100101";		
			WHEN TEST_READ_STATE  => 	-- Status am Lesen
												lcdline1_sig <= "01010100011001010111001101110100010100000111001001101111011001110111001001100001011011010101001101000100010100100100000101001101";
												lcdline2_sig <= "01010011010001000101001001000001010011010010000000101101001000000100110001100101011100110110010101101110001000000010000000100000";			
		END CASE;		
	END PROCESS ergebniszeigen;
	
END verhalten;	