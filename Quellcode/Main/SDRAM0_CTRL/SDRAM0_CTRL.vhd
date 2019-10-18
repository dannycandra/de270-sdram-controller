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
    GENERIC (
            del 					: integer := 16;  -- fuer skalieren von 200 us counter
            len_auto_ref 		: integer := 10;  -- fuer auto refresh zaehler
            len_small 			: integer := 8;   -- fuer trc,trc, usw nachdem init
            addr_bits_to_dram : integer := 13;  -- Anzahladresse nach dram
            addr_bits_from_up : integer := 24;  -- Anzaladresse von up
            ba_bits 				: integer := 2;   -- Anzahl von bankadress bits
				dqsize				: integer := 16   -- Die Groesse des Datenbus
            );

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
        -- clk and reset signals Ende
	
		  -- Benutzer Schnittstelle 
        addr_from_up 				: IN STD_LOGIC_VECTOR (addr_bits_from_up -1 DOWNTO 0) ;
        rd_n_from_up 				: IN STD_LOGIC ;
        wr_n_from_up 				: IN STD_LOGIC ;
        dram_init_done  			: OUT STD_LOGIC ;
        dram_busy 					: OUT STD_LOGIC ;
		  datain							: IN STD_LOGIC_VECTOR(dqsize-1 downto 0);	--	Dateneingang fuer SDRAM Controller von Benutzer
        dataout 						: OUT STD_LOGIC_VECTOR(dqsize-1 downto 0);	--	Datenausgang fuer Benutzer von SDRAM Controller
		  write_ready					: OUT STD_LOGIC; -- Signalisiert dass der SDRAM bereit ist, Daten zu uebernehmen
		  read_ready					: OUT STD_LOGIC; -- Signalisiert dass der SDRAM bereit ist, Daten auszugeben
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
        for i in V'low to V'high loop 
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
        for i in V'low to V'high loop
            if(tb(i) = '0') then
                V(i) := not(V(i));
            end if;
        end loop;
        return V;
        end dcr_vec; -- end function
--Funktion Deklaration Ende


--Signal Deklaration
  SIGNAL sig_clk	 : STD_LOGIC ;
  SIGNAL delay_reg : STD_LOGIC_VECTOR(del-1 downto 0); -- Wertebereich 0 - 32768
  SIGNAL addr_sig  : STD_LOGIC_VECTOR(addr_bits_to_dram - 1 DOWNTO 0) ;
  SIGNAL ba_sig    : STD_LOGIC_VECTOR(ba_bits - 1 DOWNTO 0) ;

  SIGNAL dram_init_done_s   		: STD_LOGIC ;
  SIGNAL dram_init_done_s_del   	: STD_LOGIC ;
  SIGNAL reset_del_count   		: STD_LOGIC ; -- reset delay zaehler
  --wenn der dram ist schon initialisiert. Der zaehler funktioniert als
  --auto refreshs zaehler (7.81 us)

  SIGNAL command_bus   : STD_LOGIC_VECTOR (5 DOWNTO 0) ;
  --bit 5 = cs
  --bit 4 = ras
  --bit 3 = cas
  --bit 2 = we
  --bit 1 = dqm(1)
  --bit 0 = dqm(0)

  SIGNAL no_of_refs_needed   : STD_LOGIC_VECTOR(len_auto_ref - 1 downto 0) ;
  SIGNAL one_auto_ref_time_done   : STD_LOGIC ;
  SIGNAL one_auto_ref_complete: STD_LOGIC ;

  SIGNAL write_ready_sig: STD_LOGIC;
  SIGNAL read_ready_sig: STD_LOGIC;
  
  SIGNAL auto_ref_pending : STD_LOGIC ;
  SIGNAL write_req_pending: STD_LOGIC ;

  SIGNAL small_count: STD_LOGIC_VECTOR(len_small - 1 downto 0) ;
  SIGNAL small_all_zeros: STD_LOGIC;

  SIGNAL wr_n_from_up_del_1: STD_LOGIC;
  SIGNAL wr_n_from_up_del_2: STD_LOGIC;
  SIGNAL wr_n_from_up_pulse: STD_LOGIC;

  SIGNAL en_path_up_to_dram: STD_LOGIC;--en direction of data flwo up->dram
  SIGNAL en_path_dram_to_up: STD_LOGIC;--en direction of data flwo dram->up

  SIGNAL rd_wr_just_terminated: STD_LOGIC;--zeigt dass rd or write fertig ist
                                          --und auto precharge muss gemacht werden 
  SIGNAL dram_busy_sig : STD_LOGIC; --dram macht auto_ref zyklus
--Signal Deklaration Ende

--Konstanten Deklaration
  CONSTANT mod_reg_val     : std_logic_vector(11 downto 0) := "000000100000";
  -- ll,10 = reserved, 
  -- 9 = '0' programmed burst length,
  -- 8,7 = Op mode = 00
  -- 6,5,4 = CAS latency = 010 = cas latency of 2 
  -- 3 = Burst Type = '0' = Sequential
  -- 2,1,0 = Brust Length = 000 = Single Burst

  CONSTANT sd_init     : integer := 20000; -- = 2000 * f in MHz  = 200 ms (initialization Wartezeit)
  CONSTANT trp         : integer := 2;     -- = 20 ns (pre->act)
  CONSTANT trc         : integer := 7;     -- = 70 ns (pre->pre|act->act)
  CONSTANT tmrd        : integer := 2;     -- = 15 ns ~ 20 ns (Wartezeit nachdem mode register set)
  CONSTANT trcd        : integer := 2;     -- = 20 ns (trcd ist die Zeit, die gewartet werden muss nachdem ACTIVE geschickt wurde)
  CONSTANT cas_latenz  : integer := 2;     -- = 20 ns (Zeit von trcd auf lesen)

  CONSTANT auto_ref_co : integer := 780;   -- = auto_ref_co > 7.81 * F in MHz

  -- Konstanten fuer command_bus damit koennen wir zeilen sparen
  CONSTANT inhibit         : std_logic_vector(5 downto 0) := "111111";
  CONSTANT nop             : std_logic_vector(5 downto 0) := "011111";
  CONSTANT active          : std_logic_vector(5 downto 0) := "001111";
  CONSTANT read            : std_logic_vector(5 downto 0) := "010100"; --tbd
  CONSTANT write           : std_logic_vector(5 downto 0) := "010000"; --tbd
  CONSTANT burst_terminate : std_logic_vector(5 downto 0) := "011011";
  CONSTANT precharge       : std_logic_vector(5 downto 0) := "001011";
  CONSTANT auto_ref        : std_logic_vector(5 downto 0) := "000111";
  CONSTANT load_mode_reg   : std_logic_vector(5 downto 0) := "000011";

  CONSTANT read_high_byte  : std_logic_vector(5 downto 0) := "011111"; --tbd
  CONSTANT read_low_byte   : std_logic_vector(5 downto 0) := "011111"; --tbd
  CONSTANT write_high_byte : std_logic_vector(5 downto 0) := "011111"; --tbd
  CONSTANT write_low_byte  : std_logic_vector(5 downto 0) := "011111"; --tbd

  CONSTANT rd_wr_in_prog   : std_logic_vector(5 downto 0) := "011100"; --tbd (NOP)

--Konstants Deklaration Ende

	-- Component Deklarationen
	-- Phase locked
	component pll1 is
   port (
		inclk0        : in      std_logic;
		c0   		     : out     std_logic
	);
	end component;

BEGIN
	-- ############ Instanziierung altpll (inclk0 in 50Mhz, c0 out 100Mhz) ########
	-- bei 100Mhz, 1 clktick = 10 ns
	pll : pll1
	port map 
	(
			inclk0 	=> clk_in,
			c0  	   => sig_clk
	);

-- ######### Process init_sig_delay ############################################
-- # Inkrementiert zaehler um 200 microsekunde fuer SDRAM Init
-- # Wenn das schon fertig ist dann wird fuer auto refreshs zaehler benutzt
-- #############################################################################
	init_delay_reg: PROCESS(clk_in)
	BEGIN
          IF(RISING_EDGE(clk_in)) THEN
            IF(reset = '1') THEN
              delay_reg <= (others => '0');
              one_auto_ref_time_done <= '0';
            ELSE
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
          END IF; --(RISING_EDGE(clk_in))
	END PROCESS init_delay_reg;

-- #################### Prozess init_auto_ref_count_reg ########################
-- # Berechnet wieviel auto refresh gemacht werden mussen 
-- #############################################################################
	init_auto_ref_count_reg: PROCESS(clk_in)
	BEGIN
          IF(RISING_EDGE(clk_in)) THEN
              no_of_refs_needed <= (others => '0');
            IF(reset = '1') THEN
            ELSE
              IF(dram_init_done_s = '1') THEN
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
                    END IF;
                  END IF;
                END IF;
              END IF; --IF(dram_init_done_s = '1') THEN
            END IF; --(reset = '1')
          END IF; --(RISING_EDGE(clk_in))
	END PROCESS init_auto_ref_count_reg;


-- ######### Hauptprozess ################# ####################################
-- #  Hier werden alle operationen ausgefuehrt, spricht
-- #  init, write, read, precharge, auto refresh 
-- #############################################################################
	init_reg: PROCESS(clk_in)
	BEGIN
          IF(RISING_EDGE(clk_in)) THEN
            IF(reset = '1') THEN
              dram_init_done_s <= '0';
              command_bus <= inhibit;
              one_auto_ref_complete <= '0';
              rd_wr_just_terminated <= '0';
              addr_sig <= (others => '0');
              ba_sig <= (others => '0');
            ELSE
              IF(dram_init_done_s = '0') THEN
                ----------------------------------------------------
                --dram init 
                ----------------------------------------------------
                IF(to_integer(unsigned(delay_reg)) = sd_init) THEN -- 200 ms
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= precharge;
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  addr_sig(10) <=  '1';
                  ba_sig <= ba_sig;
                ELSIF(to_integer(unsigned(delay_reg)) = sd_init + trp) THEN -- autoref 1.
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= auto_ref; 
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;
                ELSIF(to_integer(unsigned(delay_reg)) -- autoref 2.
                = sd_init + trp + trc ) THEN
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= auto_ref;  
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;
                ELSIF(to_integer(unsigned(delay_reg)) -- autoref 3.
                = sd_init + trp + 2*trc ) THEN
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= auto_ref; 
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;
					 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 4.
                = sd_init + trp + 3*trc ) THEN
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= auto_ref; 
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;
					 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 5.
                = sd_init + trp + 4*trc ) THEN
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= auto_ref; 
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;
					 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 6.
                = sd_init + trp + 5*trc ) THEN
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= auto_ref; 
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;	
					 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 7.
                = sd_init + trp + 6*trc ) THEN
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= auto_ref; 
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;	
					 ELSIF(to_integer(unsigned(delay_reg)) -- autoref 8.
                = sd_init + trp + 7*trc ) THEN
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= auto_ref; 
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;				
                ELSIF(to_integer(unsigned(delay_reg)) = 
                sd_init + trp + 8*trc ) THEN -- MRS
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= load_mode_reg;
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  addr_sig(11 downto 0) <= mod_reg_val;
                  ba_sig <= ba_sig;
                ELSIF(to_integer(unsigned(delay_reg)) = 
                sd_init + trp + 2*trc + tmrd) THEN -- 1.NOP
                  dram_init_done_s <= '1';
                  command_bus <= nop; 
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  ba_sig <= ba_sig;
                ELSE -- 2.NOP
                  dram_init_done_s <= dram_init_done_s;
                  command_bus <= nop; 
                  dram_init_done_s <= dram_init_done_s;
                  one_auto_ref_complete <= one_auto_ref_complete;
                  rd_wr_just_terminated <= rd_wr_just_terminated;
                  addr_sig <= (others => '0');
                  addr_sig(10) <=  addr_sig(10);
                  ba_sig <= ba_sig;
                END IF;
                ----------------------------------------------------
                --dram init fertig
                ----------------------------------------------------


                ----------------------------------------------------
                --dram write mit auto precharge
                ----------------------------------------------------
              ELSIF((wr_n_from_up = '0') AND (rd_wr_just_terminated = '0'))THEN
                IF(wr_n_from_up_del_1 = '1') THEN 
                  ba_sig <= addr_from_up(23 downto 22) ;
                  command_bus <= active; 
                  --addresse allokierung
                  --23 downto 22 sind bank selectors, total banks = 4
                  --21 downto 9  sind row  selectors, total rows  = 8192
                  --9  downto 0  sind col  selectors, total cols  = 512
                  --total space available 4 x 8192 x 512 = 16 Meg
                  addr_sig <= addr_from_up(21 downto 9) ; 
                ELSIF(to_integer(unsigned(small_count)) = trcd) THEN
                  ba_sig <= addr_from_up(23 downto 22) ;
                  command_bus <= write;
                  addr_sig(8 downto 0) <= addr_from_up(8 downto 0) ; 
						DRAM_DQ <= datain;
                ELSE
                  ba_sig <= ba_sig;
                  command_bus <= rd_wr_in_prog; --dqm ist 00 sonst ein NOP
                  addr_sig <= addr_sig; 
                END IF;
                ----------------------------------------------------
                --dram write Ende
                ----------------------------------------------------


                ----------------------------------------------------
                --dram read mit auto precharge
                ----------------------------------------------------
              ELSIF((rd_n_from_up = '0')  AND (rd_wr_just_terminated = '0'))THEN
                IF(wr_n_from_up_del_1 = '1') THEN
                  ba_sig <= addr_from_up(23 downto 22);
                  command_bus <= active; 
                  addr_sig <= addr_from_up(21 downto 9);
					   read_ready_sig <= '0';	
                ELSIF(to_integer(unsigned(small_count)) = trcd) THEN
                  ba_sig <= ba_sig;
                  command_bus <= read;
                  addr_sig(8 downto 0) <= addr_from_up(8 downto 0); 
						addr_sig(10) <= '1'; --auto precharge
			         read_ready_sig <= '0';			
					 ELSIF(to_integer(unsigned(small_count)) = trcd + cas_latenz) THEN
					   ba_sig <= ba_sig;
					   command_bus <= rd_wr_in_prog; --dqm ist 00 sonst ein NOP
						addr_sig <= addr_sig; 
					   read_ready_sig <= '1'; 
						dataout <= DRAM_DQ; --Daten weiterleiten
                ELSE
                  ba_sig <= ba_sig;
                  command_bus <= rd_wr_in_prog; --dqm ist 00 sonst ein NOP
                  addr_sig <= addr_sig; 
						read_ready_sig <= '0';
                END IF;
                ----------------------------------------------------
                --dram read Ende
                ----------------------------------------------------

                ----------------------------------------------------
                --Burst Terminierung
                ----------------------------------------------------
              ELSIF((wr_n_from_up = '1' OR rd_n_from_up = '1') 
                   AND (wr_n_from_up_del_1 = '0')) THEN
                  command_bus <= burst_terminate; 
                  rd_wr_just_terminated <= '1';

              ELSIF(rd_wr_just_terminated = '1') THEN
                    IF(to_integer(unsigned(small_count)) = 1) THEN
                      ba_sig <= addr_from_up(23 downto 22) ;
                      command_bus <= precharge;
                      addr_sig <= addr_sig; 
                      rd_wr_just_terminated <= '1';
                    ELSIF(to_integer(unsigned(small_count)) = trp) THEN
                      ba_sig <= ba_sig; 
                      command_bus <= nop;
                      rd_wr_just_terminated <= '0';
                      addr_sig <= addr_sig; 
                    ELSE
                      ba_sig <= ba_sig; 
                      command_bus <= nop;
                      addr_sig <= addr_sig; 
                      rd_wr_just_terminated <= rd_wr_just_terminated;
                    END IF;

                ----------------------------------------------------
                --dram auto_refereshes
                ----------------------------------------------------
              ELSIF(auto_ref_pending = '1') THEN
              --fuehrt auto ref aus und dekrementiert auto ref zaehler
                IF (small_all_zeros = '1')THEN --trp 
                  command_bus <= auto_ref; 
                  one_auto_ref_complete <= '0'; 
                ELSIF ((to_integer(unsigned(small_count)) = trc)) THEN
                  command_bus <= nop; 
                  one_auto_ref_complete <= '1'; 
                ELSE
                  command_bus <= nop; 
                  one_auto_ref_complete <= '0'; 
                END IF;
                ----------------------------------------------------
                --dram auto_refereshes Ende
                ----------------------------------------------------
              END IF; --(if dram_init_done_s = '1')
            END IF; --IF(reset = '1')
          END IF; --IF(RISING_EDGE(clk_in))
	END PROCESS init_reg;

--##############################################################################
--  Prozess:  
--##############################################################################
	reset_del_count_gen_reg: PROCESS(clk_in)
	BEGIN
        IF(RISING_EDGE(clk_in)) THEN
          dram_init_done_s_del <= dram_init_done_s;
        END IF;
	END PROCESS reset_del_count_gen_reg;

--generiert ein pulse auf reset_del_count wenn dram_init_done_s auf high geht
reset_del_count <= dram_init_done_s AND not(dram_init_done_s_del);


--##############################################################################
--  Prozess:  
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
-- Prozess: Dieser Prozess ist verantwortlich für die Generierung von zahlen, die fuer 
-- die Erzeugung von Verzögerungen noetwendig ist, nachdem ein Befehl zum DRAM ausgestellt wird,
-- Um Die verschiedenen Timing-Anforderungen für den DRAM sorgen
-- Es ist so gedacht dass dieser Zaehler sobald zurueckgesetzt
-- Einen Befehl erteilt wird, zur bernischen wir produzieren können Verzögerungen
-- Bzgl. der Anzahl in diesem Register gehalten
-- Seit ein Befehl von command_bus gekennzeichnet (4)
-- Command_bus (3) und command_bus (2), wenn einer von ihnen ist
-- '0 ', Werden wir Zähler zuruecksetzen.
--##############################################################################
	small_count_reg: PROCESS(clk_in,reset)
        VARIABLE all_ones: std_logic;
	BEGIN
        IF(reset = '1') THEN
            small_count <= (others => '0');
        ELSIF(RISING_EDGE(clk_in)) THEN
          --IF((command_bus(2) = '0') OR (command_bus(3) = '0') 
          --OR (command_bus(4) = '0')) THEN
            all_ones  := small_count(0);
            FOR i in 1 to len_small - 1 LOOP
              all_ones := all_ones AND small_count(i);
            END LOOP;
				--Wenn kein read oder write cyklus am laufen ist
				--dann nur auto ref events
            IF((one_auto_ref_time_done = '1' AND wr_n_from_up = '1'
                AND rd_n_from_up = '1') OR 				 
				  	--Wenn kein read oder write cyklus am laufen ist
				   --dann nur auto ref events
              (one_auto_ref_complete = '1' AND wr_n_from_up = '1'
                AND rd_n_from_up = '1') OR 
					--read / write ist fertig
              (wr_n_from_up_del_1 = '0' AND rd_n_from_up = '1'
               AND wr_n_from_up = '1') OR
              (wr_n_from_up_pulse = '1') OR

              (  (to_integer(unsigned(small_count)) = trp) AND
                 (rd_wr_just_terminated = '1')  )

              ) THEN
				  --Nachdem read & write fertig ist und der ausgestellte Befehl
				  --auch fertig ist, dann wird small counter resettet, um
				  --auto_ref cyklus zu zaehlen
				  -- Zusammenfassend dem Zurücksetzen des small_count wird durchgeführt
              -- 1) Im Auto-Modus referesh bei jedem refresh ende
              -- 2) Während Schreibvorgang zaehlt die Trcd 
              -- 3) Während Lesevorgang zaehlt die Trcd 
              -- 4) Kurz nach Lese-/Schreibefehl ist vorbei, für PRECHARGE op
              -- 5) Kurz nach Lese-/Schreibefehl vorbei ist und PRECHARGE ist auch fertig
				  -- ,beginnt er von vorne die Zaehlung fuer A_REF.
              small_count <= (others => '0');
            ELSIF(all_ones = '1') THEN
              small_count <= small_count;
            ELSE
				  --Zaehlt small_count bis maximum
				  --dann wartet auf reset command
              --IF((wr_n_from_up = '0') OR (rd_n_from_up = '0') 
              --OR (auto_ref_pending = '1')) THEN
                small_count <= incr_vec(small_count);
              --ELSE
              --  small_count <= small_count;
              --END IF;
            END IF; -- IF(all_ones = '1')
          --END IF; --((command_bus(2) = '0')...
        END IF; --reset
      --END IF; --(RISING_EDGE(clk_in))

	END PROCESS small_count_reg;

--##############################################################################
--  Prozess:  
--##############################################################################
	gen_small_all_zeros_cmb: PROCESS (small_count)
	VARIABLE small_all_zeros_var: std_logic;
	BEGIN
          small_all_zeros_var := small_count(0);
        FOR i in 1 to len_small - 1 LOOP
          small_all_zeros_var := small_all_zeros_var OR small_count(i);
        END LOOP;
        small_all_zeros <= not(small_all_zeros_var);
	END PROCESS gen_small_all_zeros_cmb;

--##############################################################################
--  Prozess:  
--##############################################################################
	wr_n_from_up_del_reg: PROCESS(clk_in)
	BEGIN
        IF(RISING_EDGE(clk_in)) THEN
          wr_n_from_up_del_1 <= wr_n_from_up AND rd_n_from_up;
          wr_n_from_up_del_2 <= wr_n_from_up_del_1;
        END IF;
	END PROCESS wr_n_from_up_del_reg;
        wr_n_from_up_pulse <= not(wr_n_from_up AND rd_n_from_up) 
                                 AND (wr_n_from_up_del_1);
        --wr_n_from_up_pulse <= not(wr_n_from_up_del_1) AND (wr_n_from_up_del_2);

--##############################################################################
--  Prozess:  
--##############################################################################
	dram_busy_gen: PROCESS(clk_in)
        BEGIN
        IF(RISING_EDGE(clk_in)) THEN
          IF(reset = '1') THEN
            dram_busy_sig <= '0';
          ELSE
            IF((to_integer(unsigned(no_of_refs_needed)) /= 0) AND 
            (( wr_n_from_up_del_1 = '0' AND 
               rd_n_from_up = '1' AND wr_n_from_up = '1'))) THEN
              dram_busy_sig <= '1';
            ELSIF((to_integer(unsigned(no_of_refs_needed)) /= 0) AND
            ( wr_n_from_up = '0' OR rd_n_from_up = '0')) THEN
              dram_busy_sig <= '0';
            ELSIF(to_integer(unsigned(no_of_refs_needed)) = 0) THEN
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
	cke_gen_reg: PROCESS(clk_in)
        BEGIN
          IF(RISING_EDGE(clk_in)) THEN
            IF(reset = '1') THEN
              oDRAM0_CKE <= '0';
            ELSE
              oDRAM0_CKE <= '1';
            END IF;
          END IF;
	END PROCESS cke_gen_reg;

	
dram_init_done <= dram_init_done_s;
dram_busy <= dram_busy_sig ;
	
-- ########## intern signal => extern signal zuweisung (DRAM Schnittstelle) ##################
oDRAM0_A		   <= addr_sig; 	
oDRAM0_BA      <=	ba_sig;	
oDRAM0_CS_N		<=	command_bus(5);
oDRAM0_CAS_N   <=	command_bus(4);
oDRAM0_RAS_N   <=	command_bus(3);
oDRAM0_WE_N	   <=	command_bus(2);
oDRAM0_UDQM1	<=	command_bus(1); 
oDRAM0_LDQM0   <=	command_bus(0);
oDRAM0_CLK		<= sig_clk;	

write_ready <= write_ready_sig;
read_ready <= read_ready_sig;

END verhalten;