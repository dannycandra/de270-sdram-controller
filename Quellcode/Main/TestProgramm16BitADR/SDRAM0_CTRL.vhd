---------------------------------------------------------------------------
-- Funktion : Ansteuerung des extern SDRAM0 Speichers auf dem DE2-70 Board
-- Filename : sdram0_ctrl.vhd
-- Beschreibung : 4M x 16bit x 4 Banks SDRAM (IS42S16160B)
--                single burst write or read
--                100 Mhz (1 clktick = 10ns)
-- Standard : VHDL 1993

-- Author : Danny Candra
-- Revision : Version 0.1 
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

--TOP ENTITY NAME : sdram0_ctrl
--ARCHITECTURE NAME : verhalten

ENTITY sdram0_ctrl IS
    GENERIC (                                   -- Die Werte sind der Anzahl von Bits (16 bits bedeutet vector von 0 - 15)
            del 					: integer := 16;  -- fuer skalieren von 200 us counter
            len_auto_ref 		: integer := 10;  -- fuer auto refresh zaehler
            len_small 			: integer := 8;   -- fuer trc,trc, usw nachdem init
            addr_bits_to_dram : integer := 13;  -- Anzahladresse nach dram (A0-A12)
            addr_bits_from_up : integer := 24;  -- Anzahladresse von up (A0-A12)+(A0-A8)+(B0-B1)
            ba_bits 				: integer := 2;   -- Anzahl von bankadress bits
				dqsize				: integer := 16); -- Die Groesse des Datenbus (DQ0-DQ15)  
    PORT (
		  -- SDRAM Schnittstelle
		  -- SDRAM0 pins 
        oDRAM0_A		: OUT STD_LOGIC_VECTOR (addr_bits_to_dram - 1 DOWNTO 0) ; -- SDRAM0 Adresse
        oDRAM0_BA    : OUT STD_LOGIC_VECTOR (ba_bits - 1 DOWNTO 0); -- SDRAM0 Bank
        oDRAM0_CLK   : OUT STD_LOGIC ; -- Clock enable
        oDRAM0_CKE   : OUT STD_LOGIC ; -- Clock
        oDRAM0_CAS_N : OUT STD_LOGIC ; -- Spaltenadresse Abtastzeit
        oDRAM0_RAS_N : OUT STD_LOGIC ; -- Zeilenadresse Abtastzeit
        oDRAM0_WE_N 	: OUT STD_LOGIC ; -- Write enable
        oDRAM0_CS_N  : OUT STD_LOGIC ; -- Chip select
        oDRAM0_LDQM0	: OUT STD_LOGIC ; --	Untere Datenmaske
		  oDRAM0_UDQM1	: OUT STD_LOGIC ; --	Obere Datenmaske
        -- SDRAM0 pins Ende

        -- clk and reset signals 
        clk_in : IN STD_LOGIC;
        reset  : IN STD_LOGIC;
		  clk_out : OUT STD_LOGIC;
        -- clk and reset signals Ende
	
		  -- Benutzer Schnittstelle 
        addr_from_up 				: IN STD_LOGIC_VECTOR (addr_bits_from_up -1 DOWNTO 0) ;  -- (0 -> 23) Adress
        rd_n_from_up 				: IN STD_LOGIC ;
        wr_n_from_up 				: IN STD_LOGIC ;
        dram_init_done  			: OUT STD_LOGIC ;
        dram_busy 					: OUT STD_LOGIC ;
		  datain							: IN STD_LOGIC_VECTOR(dqsize-1 downto 0);	 -- Dateneingang fuer SDRAM Controller von Benutzer
        dataout 						: OUT STD_LOGIC_VECTOR(dqsize-1 downto 0); -- Datenausgang fuer Benutzer von SDRAM Controller
		  sdram_zustand				: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		  -- Benutzer Schnittstelle Ende

		  -- Datenbus
		  DRAM_DQ : inout	std_logic_vector(dqsize-1 downto 0)	-- SDRAM DQ 0-15 => SDRAM0, 16-31 => SDRAM1      
        );

END sdram0_ctrl;

--##############################################################################
--Architektur begin
--##############################################################################
ARCHITECTURE verhalten OF sdram0_ctrl IS

--Funktion Deklaration 
--#################################################################################
--Diese Funktion inkrementiert ein std_logic_vector typ um '1'
--typische benutzung next_count <= incr_vec(next_count);
--wenn zaehler erreicht den hochsten Wert(alle ein) dann ist der naechste Wert 0
--when count reaches the highest value(all ones), the next count is zero.
--#################################################################################
FUNCTION incr_vec(s1:STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is  
        VARIABLE V : STD_LOGIC_VECTOR(s1'high DOWNTO s1'low) ; 
        VARIABLE tb : STD_LOGIC_VECTOR(s1'high DOWNTO s1'low); 
        BEGIN 
        tb(s1'low) := '1'; 
        V := s1; 
        for i in (V'low + 1) to V'high loop 
            tb(i) := V(i - 1) and tb(i -1); 
        end loop; 
        for i in V'low to V'high loop      --   0..0  next count
            if(tb(i) = '1') then 
                V(i) := not(V(i)); 
            end if; 
        end loop; 
        return V; 
        end incr_vec; -- end function 
--######################### ENDE FUNKTION incr_vec #################################

--##################################################################################
--Diese Funktion dekrementiert ein std_logic_vector typ um '1'
--typische benutzung next_count <= dcr_vec(next_count);
--wenn zaehler erreicht den niedrigsten Wert(alle 0) dann ist der naechste Wert alle ein
--##################################################################################
        FUNCTION  dcr_vec(s1:std_logic_vector) return std_logic_vector is
        VARIABLE V : std_logic_vector(s1'high downto s1'low) ;
        VARIABLE tb : std_logic_vector(s1'high downto s1'low);
        BEGIN
        tb(s1'low) := '0';
        V := s1;
        for i in (V'low + 1) to V'high loop
            tb(i) := V(i - 1) or tb(i -1);
        end loop;
        for i in V'low to V'high loop     -- 1..1 next count 
            if(tb(i) = '0') then
                V(i) := not(V(i));
            end if;
        end loop;
        return V;
        end dcr_vec; -- end function
--Funktion Deklaration Ende


--Signal Deklaration
  SIGNAL sig_clk	 					: STD_LOGIC ;
  SIGNAL sig_clk_shifted			: STD_LOGIC ;
  SIGNAL sig_clk_lsa					: STD_LOGIC ;
  SIGNAL delay_reg 					: STD_LOGIC_VECTOR(del-1 downto 0); -- Wertebereich 0 - 32768   --wenn der dram ist schon initialisiert. Der zaehler funktioniert als auto refreshs zaehler (7.81 us)
  SIGNAL addr_sig  					: STD_LOGIC_VECTOR(addr_bits_to_dram - 1 DOWNTO 0) ;
  SIGNAL ba_sig    					: STD_LOGIC_VECTOR(ba_bits - 1 DOWNTO 0) ;
  SIGNAL dram_init_done_s   		: STD_LOGIC ;
  SIGNAL dram_init_done_s_del   	: STD_LOGIC ;
  SIGNAL reset_del_count   		: STD_LOGIC ; -- reset delay zaehler
  SIGNAL command_bus   				: STD_LOGIC_VECTOR (5 DOWNTO 0) ; -- bit 5 = cs, bit 4 = ras, bit 3 = cas, bit 2 = we, bit 1 = dqm(1), bit 0 = dqm(0)
  SIGNAL no_of_refs_needed			: STD_LOGIC_VECTOR(len_auto_ref - 1 downto 0) ;
  SIGNAL one_auto_ref_time_done	: STD_LOGIC ;
  SIGNAL one_auto_ref_complete	: STD_LOGIC ;
  SIGNAL auto_ref_pending			: STD_LOGIC ;
  SIGNAL operation_timer		   : STD_LOGIC_VECTOR(len_small - 1 downto 0) ;
  SIGNAL dram_busy_sig 				: STD_LOGIC; --dram macht auto_ref zyklus
--Signal Deklaration Ende

	-- Zustände
	type SDRAM_ZUSTAENDE is (INIT_STATE, IDLE_STATE, WRITE_STATE, READ_STATE, REF_STATE);
	signal AKTUALZUSTAND : SDRAM_ZUSTAENDE := INIT_STATE;

--Konstanten Deklaration
  CONSTANT mod_reg_val     			: std_logic_vector(11 downto 0) := "000000100000";
  -- ll,10 = reserved, 
  -- 9 = '0' programmed burst length,
  -- 8,7 = Op mode = 00
  -- 6,5,4 = CAS latency = 010 = cas latency of 2 
  -- 3 = Burst Type = '0' = Sequential
  -- 2,1,0 = Brust Length = 000 = Single Burst
  CONSTANT sd_init     : integer := 20000; -- = 20000 * f in MHz  = 200 micro sec (initialization Wartezeit)
  CONSTANT trp         : integer := 2;     -- = 20 ns (pre->act)
  CONSTANT trc         : integer := 7;     -- = 70 ns (pre->pre|act->act)
  CONSTANT tmrd        : integer := 2;     -- = 15 ns ~ 20 ns (Wartezeit nachdem mode register set)
  CONSTANT trcd        : integer := 2;     -- = 20 ns (trcd ist die Zeit, die gewartet werden muss nachdem ACTIVE geschickt wurde)
  CONSTANT cas_latenz  : integer := 2;     -- = 20 ns (Zeit von trcd auf lesen)
  CONSTANT auto_ref_co : integer := 780;   -- = auto_ref_co > 7.81 * F in MHz

  -- Konstanten fuer command_bus damit wir zeilen sparen koennen
  CONSTANT inhibit         : std_logic_vector(5 downto 0) := "111111"; -- 63
  CONSTANT nop             : std_logic_vector(5 downto 0) := "011111"; -- 31
  CONSTANT activea         : std_logic_vector(5 downto 0) := "001111"; -- 15
  CONSTANT reada           : std_logic_vector(5 downto 0) := "010100"; -- 20
  CONSTANT writea          : std_logic_vector(5 downto 0) := "010000"; -- 16
  CONSTANT precharge       : std_logic_vector(5 downto 0) := "001011"; -- 11
  CONSTANT auto_ref        : std_logic_vector(5 downto 0) := "000111"; -- 7
  CONSTANT load_mode_reg   : std_logic_vector(5 downto 0) := "000011"; -- 3
  CONSTANT rd_wr_in_prog   : std_logic_vector(5 downto 0) := "011100"; -- 28(NOP)
--Konstants Deklaration Ende

-- Component Deklarationen
	-- Phase locked
	component pll1 is
   port (
		inclk0        : in      std_logic; -- 50 mhz board clock
		c0   		     : out     std_logic; -- 100 mhz system clock
		c1				  : out     std_logic; -- 100 mhz shifted -5 ns
		c2				  : out     std_logic -- 200 mhz lsa
	);
	end component;
-- Component Deklarationen Ende
	
BEGIN
-- ############ Instanziierung altpll (inclk0 in 50Mhz, c0 out 100Mhz) ########
-- bei 100Mhz, 1 clktick = 10 ns
	pll : pll1
	port map 
	(
			inclk0 	=> clk_in,
			c0  	   => sig_clk,
			c1			=> sig_clk_shifted,
			c2			=> sig_clk_lsa
	);

-- ######### Process init_sig_delay ############################################
-- # Inkrementiert zaehler um 200 microsekunde fuer SDRAM Init
-- # Wenn das schon fertig ist dann wird fuer auto refreshs zaehler benutzt
-- #############################################################################
	init_delay_reg: PROCESS(sig_clk)
	BEGIN
            IF(reset = '1') THEN
              delay_reg <= (others => '0');
              one_auto_ref_time_done <= '0';				  
            ELSIF(RISING_EDGE(sig_clk)) THEN
              IF(reset_del_count = '1') THEN 
                delay_reg <= (others => '0');
              ELSIF(dram_init_done_s_del = '1') THEN
                IF(to_integer(unsigned(delay_reg)) = auto_ref_co) THEN
						--d.h sig_delay hat schon 780 clockticks gezaehlt
						--und wir mussen den Timer zuruckstellen und refresh signalisiert
                  delay_reg <= (others => '0');
                  one_auto_ref_time_done <= '1';
                ELSE -- solange 780 clockticks noch nicht errreicht, weiter inkrementieren
                  delay_reg <= incr_vec(delay_reg);
                  one_auto_ref_time_done <= '0';
                END IF;
              ELSE -- Initialisierungszeit (200 ms)
                  delay_reg <= incr_vec(delay_reg);
                  one_auto_ref_time_done <= '0';
              END IF; --(reset_del_count = '1')
            END IF; --(reset = '1')
	END PROCESS init_delay_reg;

-- #################### Prozess init_auto_ref_count_reg ########################
-- # Berechnet wieviel auto refresh gemacht werden mussen 
-- #############################################################################
	init_auto_ref_count_reg: PROCESS(sig_clk)
	BEGIN
            IF(reset = '1') THEN
					no_of_refs_needed <= (others => '0');
            ELSIF(RISING_EDGE(sig_clk)) THEN
				  IF(reset_del_count = '1') THEN 
                no_of_refs_needed <= (others => '0');
              ELSIF(dram_init_done_s = '1') THEN
                IF(no_of_refs_needed = "1111111111") THEN
                  no_of_refs_needed <= no_of_refs_needed;
                ELSE
					   --auto_ref_time_done wird '1' fuer 1 clock cycle
					   --nach 780 clocks
                  IF(one_auto_ref_time_done = '1') THEN
                    no_of_refs_needed <= incr_vec(no_of_refs_needed); 
                  ELSIF(one_auto_ref_complete = '1') THEN
					     --es muss geprueft werden dass der zaehler nicht unter 0 geht
					     --sollte eigentlich nicht passieren
                    IF(no_of_refs_needed = "0000000000") THEN
                      no_of_refs_needed <= no_of_refs_needed; 
                    ELSE
                      no_of_refs_needed <= dcr_vec(no_of_refs_needed); 
                    END IF; -- IF(no_of_refs_needed = "0000000000") THEN
                  END IF; -- (one_auto_ref_time_done = '1') THEN
                END IF; -- (no_of_refs_needed = "1111111111") THEN
              END IF; -- IF(reset_del_count = '1') THEN
            END IF; --(reset = '1')
	END PROCESS init_auto_ref_count_reg;

-- ######### Hauptprozess ################# ####################################
-- #  Hier werden alle operationen ausgefuehrt, spricht
-- #  init, write, read, precharge, auto refresh 
-- #############################################################################
	init_reg: PROCESS(sig_clk,reset)
	BEGIN     
	
	-- RESET_STATE, INIT_STATE, IDLE_STATE, WRITE_STATE, READ_STATE, REF_STATE
	IF(reset = '1') THEN
		dram_init_done_s 			<= '0';
		command_bus 				<= inhibit;
		one_auto_ref_complete 	<= '0';
		dataout						<= (others => '0');
		addr_sig 					<= (others => '0');
		ba_sig 						<= (others => '0');
		operation_timer 			<= (others => '0');	
		AKTUALZUSTAND 				<= INIT_STATE;
	ELSIF(RISING_EDGE(sig_clk)) THEN 
		CASE AKTUALZUSTAND is
		WHEN INIT_STATE =>  -- SDRAM init
								  sdram_zustand <= "000";
								  DRAM_DQ <= (others => 'Z');
								  IF(dram_init_done_s = '0') THEN
									 IF(to_integer(unsigned(delay_reg)) = sd_init) THEN -- 200 micro secs (delay_reg = 20000) trc = 2 trp = 7 trmd = 2
										dram_init_done_s <= dram_init_done_s;
										command_bus <= precharge;
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										addr_sig(10) <=  '1';
										ba_sig <= (others => '0');
									 ELSIF(to_integer(unsigned(delay_reg)) = sd_init + trp) THEN -- autoref 1. (delay_reg = 20002)
										dram_init_done_s <= dram_init_done_s;
										command_bus <= auto_ref; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;
									 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 2. (delay_reg = 20009)
									 = sd_init + trp + trc ) THEN
										dram_init_done_s <= dram_init_done_s;
										command_bus <= auto_ref;  
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;
									 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 3. (delay_reg = 20016)
									 = sd_init + trp + 2*trc ) THEN
										dram_init_done_s <= dram_init_done_s;
										command_bus <= auto_ref; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;
									 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 4. (delay_reg = 20023)
									 = sd_init + trp + 3*trc ) THEN
										dram_init_done_s <= dram_init_done_s;
										command_bus <= auto_ref; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;
									 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 5. (delay_reg = 20030)
									 = sd_init + trp + 4*trc ) THEN
										dram_init_done_s <= dram_init_done_s;
										command_bus <= auto_ref; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;
									 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 6. (delay_reg = 20037)
									 = sd_init + trp + 5*trc ) THEN
										dram_init_done_s <= dram_init_done_s;
										command_bus <= auto_ref; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;	
									 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 7. (delay_reg = 20044)
									 = sd_init + trp + 6*trc ) THEN
										dram_init_done_s <= dram_init_done_s;
										command_bus <= auto_ref; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;	
									 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 8. (delay_reg = 20051)
									 = sd_init + trp + 7*trc ) THEN
										dram_init_done_s <= dram_init_done_s;
										command_bus <= auto_ref; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;				
									 ELSIF(to_integer(unsigned(delay_reg)) = -- MRS (delay_reg = 20058)
									 sd_init + trp + 8*trc ) THEN 
										dram_init_done_s <= dram_init_done_s;
										command_bus <= load_mode_reg;
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										addr_sig(11 downto 0) <= mod_reg_val;
										ba_sig <= ba_sig;
									 ELSIF(to_integer(unsigned(delay_reg)) = -- 1.NOP (delay_reg = 20060)
									 sd_init + trp + 8*trc + tmrd) THEN 
										dram_init_done_s <= '1';
										command_bus <= nop; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										ba_sig <= ba_sig;
										AKTUALZUSTAND <= IDLE_STATE;			  -- initialisierung fertig
									 ELSE -- ELSE NOP
										dram_init_done_s <= dram_init_done_s;
										command_bus <= nop; 
										one_auto_ref_complete <= one_auto_ref_complete;
										addr_sig <= (others => '0');
										addr_sig(10) <=  addr_sig(10);
										ba_sig <= ba_sig;
									 END IF;
								  END IF;
		
		WHEN IDLE_STATE => 	-- SDRAM in IDLE zustand
								   sdram_zustand <= "001";
									DRAM_DQ <= (others => 'Z');
									operation_timer <= (others => '0');
									addr_sig <= (others => '0');
									ba_sig <= (others => '0');
									
									IF ((auto_ref_pending = '1') AND (wr_n_from_up /= '0') AND (rd_n_from_up /= '0')) THEN
										AKTUALZUSTAND <= REF_STATE;
									ELSIF (rd_n_from_up = '0')THEN
										AKTUALZUSTAND <= READ_STATE;
									ELSIF (wr_n_from_up = '0') THEN
										AKTUALZUSTAND <= WRITE_STATE;
									END IF;
		
		WHEN WRITE_STATE =>	-- SDRAM write + precharge
									sdram_zustand <= "010";
									operation_timer <= incr_vec(operation_timer);
									IF(to_integer(unsigned(operation_timer)) < trcd) THEN
										ba_sig <= addr_from_up(23 downto 22) ;
										addr_sig <= addr_from_up(21 downto 9) ; 
										command_bus <= activea; 
										--addresse allokierung
										--23 downto 22 sind bank selectors, total banks = 4
										--21 downto 9  sind row  selectors, total rows  = 8192
										--8  downto 0  sind col  selectors, total cols  = 512
										--total space available 4 x 8192 x 512 = 16 Meg											
									ELSIF(to_integer(unsigned(operation_timer)) = trcd) THEN
										ba_sig <= addr_from_up(23 downto 22) ;
										addr_sig(12 downto 9) <= (others => '0');
										addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ;
										command_bus <= writea;	
										DRAM_DQ <= datain;		
									ELSIF(to_integer(unsigned(operation_timer)) = trcd +1) THEN
										ba_sig <= addr_from_up(23 downto 22) ;
										addr_sig(12 downto 9) <= (others => '0');
										addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ;
										command_bus <= nop;			
									ELSIF(to_integer(unsigned(operation_timer)) = trcd +2) THEN				   
										ba_sig <= addr_from_up(23 downto 22) ;
										addr_sig(12 downto 9) <= (others => '0');
										addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ;
										command_bus <= nop;	
									ELSIF(to_integer(unsigned(operation_timer)) = trcd +3) THEN		
										ba_sig <= (others => '0');
										addr_sig(12 downto 9) <= (others => '0');
										addr_sig(10) <= '1';
										addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ;	
										command_bus <= precharge;	
									ELSIF(to_integer(unsigned(operation_timer)) = trcd +4) THEN				  
										ba_sig <= addr_from_up(23 downto 22) ;
										addr_sig(12 downto 9) <= (others => '0');
										addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ;
										command_bus <= nop;	
									ELSIF(to_integer(unsigned(operation_timer)) = trcd +5) THEN				  
										ba_sig <= addr_from_up(23 downto 22) ;
										addr_sig(12 downto 9) <= (others => '0');
										addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ;
										command_bus <= nop;	
									ELSIF(to_integer(unsigned(operation_timer)) = trcd +6) THEN				  
										ba_sig <= addr_from_up(23 downto 22) ;
										addr_sig(12 downto 9) <= (others => '0');
										addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ;
										command_bus <= nop;	 
									ELSIF(to_integer(unsigned(operation_timer)) = trcd +7) THEN				  
										ba_sig <= addr_from_up(23 downto 22) ;
										addr_sig(12 downto 9) <= (others => '0');
										addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ;
										command_bus <= nop;	
										AKTUALZUSTAND <= IDLE_STATE;   									
									ELSE
										ba_sig <= ba_sig;	
										addr_sig <= addr_sig;	
                              command_bus <= nop; 							--dqm ist 00 sonst ein NOP										
									 END IF;		
		
		WHEN READ_STATE => -- SDRAM read + precharge
								 sdram_zustand <= "011";
								 DRAM_DQ <= (others => 'Z');
								 operation_timer <= incr_vec(operation_timer);
								 IF(to_integer(unsigned(operation_timer)) < trcd - 1) THEN	
									ba_sig <= addr_from_up(23 downto 22);
									addr_sig <= addr_from_up(21 downto 9);
									command_bus <= activea;
								 ELSIF(to_integer(unsigned(operation_timer)) = trcd) THEN
									ba_sig <= addr_from_up(23 downto 22);	
									addr_sig(12 downto 9) <= (others => '0');
									addr_sig(8 downto 0) <= addr_from_up(8 downto 0); 
									command_bus <= reada;
								 ELSIF(to_integer(unsigned(operation_timer)) = trcd + cas_latenz) THEN
									ba_sig <= ba_sig;
									command_bus <= nop; 
									addr_sig <= addr_sig; 							
								 ELSIF(to_integer(unsigned(operation_timer)) = trcd + cas_latenz + 1) THEN
									ba_sig <= ba_sig;
									command_bus <= precharge; 
									addr_sig <= addr_sig; 							
								 ELSIF(to_integer(unsigned(operation_timer)) = trcd + cas_latenz + 2) THEN
									ba_sig <= ba_sig;
									addr_sig <= addr_sig; 
									command_bus <= nop;
									dataout <= DRAM_DQ;	
								 ELSIF(to_integer(unsigned(operation_timer)) = trcd + cas_latenz + 3) THEN
									ba_sig <= ba_sig;
									addr_sig <= addr_sig; 
									command_bus <= nop;
								ELSIF(to_integer(unsigned(operation_timer)) = trcd + cas_latenz + 4) THEN
									ba_sig <= ba_sig;
									addr_sig <= addr_sig; 
									command_bus <= nop;
								ELSIF(to_integer(unsigned(operation_timer)) = trcd + cas_latenz + 5) THEN
									ba_sig <= ba_sig;
									addr_sig <= addr_sig; 
									command_bus <= nop;
									AKTUALZUSTAND <= IDLE_STATE;
								 ELSE
									ba_sig <= ba_sig;	
									addr_sig <= addr_sig; 
									command_bus <= nop; --dqm ist 00 sonst ein NOP	
								 END IF;	
		
		WHEN REF_STATE => -- SDRAM autorefresh zustand
	                     sdram_zustand <= "100";
								DRAM_DQ <= (others => 'Z');
		   					operation_timer <= incr_vec(operation_timer);		    
								IF (to_integer(unsigned(operation_timer)) = trp)THEN
									command_bus <= auto_ref; 
									one_auto_ref_complete <= '1'; 
								ELSIF ((to_integer(unsigned(operation_timer)) = trc)) THEN
									command_bus <= nop; 
									one_auto_ref_complete <= '0'; 
									AKTUALZUSTAND <= IDLE_STATE;					
								ELSE
									command_bus <= nop; 
									one_auto_ref_complete <= '0';			   
								END IF;
		
		END CASE;
    END IF; --IF(reset = '1')
	END PROCESS init_reg;
	
--##############################################################################
--  Prozess:  
--##############################################################################
	reset_del_count_gen_reg: PROCESS(sig_clk)	
	BEGIN
        IF(RISING_EDGE(sig_clk)) THEN
          dram_init_done_s_del <= dram_init_done_s;
        END IF;
	END PROCESS reset_del_count_gen_reg;

--generiert ein pulse auf reset_del_count wenn dram_init_done_s auf high geht
reset_del_count <= dram_init_done_s AND not(dram_init_done_s_del);

--##############################################################################
--  Prozess:  Signalisiert dass ein Refresh gemacht werden muss
--##############################################################################
	gen_auto_ref_pending_cmb: PROCESS (no_of_refs_needed)
	BEGIN
        IF(to_integer(unsigned(no_of_refs_needed)) = 0) THEN 
          auto_ref_pending <= '0';
        ELSE
          auto_ref_pending <= '1';
        END IF;
	END PROCESS gen_auto_ref_pending_cmb;

--##############################################################################
--  Prozess:  Generiert busy signal
--##############################################################################
	dram_busy_gen: PROCESS(sig_clk)
        BEGIN
        IF(RISING_EDGE(sig_clk)) THEN
          IF(reset = '1') THEN
            dram_busy_sig <= '0';
          ELSE
            IF(AKTUALZUSTAND = IDLE_STATE) THEN
				  dram_busy_sig <= '0';
            ELSE
              dram_busy_sig <= '1';
            END IF;
          END IF;
        END IF;
	END PROCESS dram_busy_gen;

-- ########## Prozess CKE generierung  ##########################################
-- # Generiert cke anhand reset 
-- ##############################################################################
	cke_gen_reg: PROCESS(sig_clk)
        BEGIN
          IF(RISING_EDGE(sig_clk)) THEN
            IF(reset = '1') THEN
              oDRAM0_CKE <= '0';
            ELSE
              oDRAM0_CKE <= '1';
            END IF;
          END IF;
	END PROCESS cke_gen_reg;

dram_init_done <= dram_init_done_s_del;
dram_busy <= dram_busy_sig ;
	
-- ########## intern signal => extern signal zuweisung (DRAM Schnittstelle) ##################
oDRAM0_A		   <= addr_sig; 	
oDRAM0_BA      <=	ba_sig;	
oDRAM0_CS_N		<=	command_bus(5);
oDRAM0_RAS_N   <=	command_bus(4);
oDRAM0_CAS_N   <=	command_bus(3);
oDRAM0_WE_N	   <=	command_bus(2);
oDRAM0_UDQM1	<=	command_bus(1); 
oDRAM0_LDQM0   <=	command_bus(0);
oDRAM0_CLK		<= sig_clk;	
clk_out 			<= sig_clk;

END verhalten;