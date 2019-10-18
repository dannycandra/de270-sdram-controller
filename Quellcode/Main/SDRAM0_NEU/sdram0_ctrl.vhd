---------------------------------------------------------------------------
-- Funktion : Ansteuerung des extern SDRAM0 Speichers auf dem DE2-70 Board
-- Filename : sdram0_ctrl.vhd
-- Beschreibung : 4M x 16bit x 4 Banks SDRAM
--                single burst write or read with autoprecharge
--                100 Mhz (1 clktick = 10ns)
-- Standard : VHDL 1993

-- Author : Danny Candra
-- Revision : Version 0.1 
---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.numeric_std.all; -- to_integer()


entity sdram0_ctrl is
	generic
	(
		-- SD Spezifikationen
		-- Die Zeilenadresse, Spaltenadresse, Bankadresse werden in einem Signal zusammengefasst
		-- d.h ADDR[0..8] => Spaltenadresse, ADDR[9..21] => Zeilenadresse, ADDR[22..23] => Bankadresse
		ASIZE				:	integer := 24;	 -- Die Groesse der Eingangsadresse
		DQSIZE			:	integer := 32;  -- Die Groesse des Datenbus      
		ROWSIZE			:	integer := 13;  -- Die Groesse der Zeilenadresse
		COLSIZE			:	integer := 9;   -- Die Groesse der Spalteadresse
		BANKSIZE			:	integer := 2;	 -- Die Groesse der Bankadresse
		ROWSTART			:	integer := 9;	 -- Die Startadresse von Zeilenadresse innerhalb Eingang ADDR	
		COLSTART			:	integer := 0;	 -- Die Startadresse von Spaltenadresse innerhalb Eingang ADDR
		BANKSTART		:	integer := 22	 -- Die Startadresse von Bankadresse innerhalb Eingang ADDR
	);
	
	port
	(
		-- Benutzer Schnittstelle 
		CMD				:	in		std_logic_vector(1 downto 0);				-- Befehle von User (MRS,Lesen,Schreiben,NOP)
		ADDR				:	in		std_logic_vector(ASIZE-1 downto 0); 	-- Adresseingabe von User
		DATAIN			:	in    std_logic_vector(DQSIZE-1 downto 0);	--	Dateneingang fuer SDRAM Controller von Benutzer
      DATAOUT        :	out	std_logic_vector(DQSIZE-1 downto 0);	--	Datenausgang fuer Benutzer von SDRAM Controller
		DM					:	in		std_logic_vector(1 downto 0);  			-- Datenmask
		CLK				:	in		std_logic;										-- Clock
		RESET				: 	in		std_logic;										-- Reset
		DRAM_INIT_DONE	:	out 	std_logic;										-- Benachrichtigung fuer Benutzer dass Init fertig ist
		
		-- SDRAM Schnittstelle
		-- SDRAM0 
		oDRAM0_A			:	out	std_logic_vector(ROWSIZE-1 downto 0);	-- SDRAM0 Adresse
		oDRAM0_BA		:	out	std_logic_vector(BANKSIZE-1 downto 0);	-- SDRAM0 Bank
		oDRAM0_CKE		:	out	std_logic;	-- Clock enable
		oDRAM0_CLK		:	out	std_logic;	-- Clock
		oDRAM0_CAS_N	:	out	std_logic;	-- Spaltenadresse Abtastzeit
		oDRAM0_RAS_N	:	out	std_logic;	-- Zeilenadresse Abtastzeit
		oDRAM0_WE_N		:	out	std_logic;	-- Write enable
		oDRAM0_CS_N		:	out	std_logic;	-- Chip select
		oDRAM0_LDQM0	:	out	std_logic;	--	Untere Datenmaske
		oDRAM0_UDQM1	:	out	std_logic;	--	Obere Datenmaske
		
		-- Datenbus
		DRAM_DQ			:	inout	std_logic_vector(DQSIZE-1 downto 0)	-- SDRAM DQ 0-15 => SDRAM0, 16-31 => SDRAM1
	);
end sdram0_ctrl;

architecture VERHALTEN of sdram0_ctrl is

   --Funktion Deklaration 
	--#################################################################################
	--Diese Funktion inkrementiert ein std_logic_vector typ um '1'
	--typische benutzung next_count <= incr_vec(next_count);
	--wenn zaehler erreicht den hochsten Wert(alle ein) dann ist der naechste Wert 0
	--when count reaches the highest value(all ones), the next count is zero.
	--##################################################################################
	function incr_vec(s1:std_logic_vector) return std_logic_vector is  
	  variable V : std_logic_vector(s1'high downto s1'low) ; 
	  variable tb : std_logic_vector(s1'high downto s1'low); 
	  begin 
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
	end incr_vec; -- ende funktion 
	--######################### ENDE FUNKTION incr_vec #################################
	
	--##################################################################################
	--Diese Funktion dekrementiert ein std_logic_vector typ um '1'
	--typische benutzung next_count <= dcr_vec(next_count);
	--wenn zaehler erreicht den niedrigsten Wert(alle 0) dann ist der naechste Wert alle ein
	--##################################################################################
	function  dcr_vec(s1:std_logic_vector) return std_logic_vector is			
	  variable V : std_logic_vector(s1'high downto s1'low) ;
	  variable tb : std_logic_vector(s1'high downto s1'low);
	  begin
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
	end dcr_vec; -- ende funktion
	--######################### ENDE FUNKTION dcr_vec ################################
	
	-- Enumeration Deklarationen 
	Type AZUSTAND is (OFF,IDLE,INIT,LESEN,SCHREIBEN,ZURUECKSETZEN,AUTO_REFRESH); -- Aktuellezustand
	
   -- Signale Deklarationen
	signal sig_clk			    				: std_logic;
	signal sig_aktZustand    				: AZUSTAND;
	signal sig_doReset       				: std_logic;
	signal sig_doAutoRef						: std_logic;
	signal sig_doInit        				: std_logic;
	signal sig_doWrite      	 			: std_logic;
	signal sig_doRead       				: std_logic;
	signal sig_done			 				: std_logic; -- Ob ein Prozess schon fertig ist oder nicht
   signal sig_resetDone						: std_logic; -- signalisiert wenn Reset gemacht wurde
	signal sig_addr			 				: std_logic_vector(ROWSIZE-1 downto 0);
	signal sig_ba			    				: std_logic_vector(BANKSIZE-1 downto 0);
	signal sig_command						: std_logic_vector(5 downto 0); 	
													--bit 5 = cs
													--bit 4 = ras
													--bit 3 = cas
													--bit 2 = we
													--bit 1 = dqm(1)
													--bit 0 = dqm(0)
	signal sig_delay         				: std_logic_vector(15-1 downto 0); -- Wertebereich 0 - 32768
	signal sig_one_auto_ref_time_done 	: std_logic; -- signalisiert wenn auto refresh timer abklingt
	signal sig_one_auto_ref_complete		: std_logic; -- signalisiert wenn ein auto refresh gemacht wurde
	signal sig_auto_ref_pending         : std_logic; -- signalisiert wenn ein auto refresh bevorsteht
	signal sig_no_of_refs_needed			: std_logic_vector(9 downto 0); -- anzahl refresh zu machen
	signal sig_dram_init_done_s			: std_logic; -- init fertig
	signal sig_dram_init_done_s_del 		: std_logic; -- init fertig
	signal sig_reset_del_count				: std_logic; -- delay zaehler zurueckgesetzt	
	signal sig_delay2							: std_logic; -- zaehler fuer write , read , auto refresh
	
	
	-- Konstanten
	constant sd_init     : integer := 20000; -- = 2000 * f in MHz (200 microsekunde)
   constant trp         : integer := 4;     -- = 20 ns (20 ns < (trp - 1)* T);
   constant trfc        : integer := 8;     -- = 66 ns (66 ns < (trfc - 1)* T);
   constant tmrd        : integer := 3;     -- = 2 Warte Zeit nachdem mode register set
   constant trcd        : integer := 2;     -- = 15 ns (15 ns < (trcd)*T), 
	                                         -- trcd ist die Zeit, die gewartet werden muss nachdem ACTIVE geschickt wurde
   constant auto_ref_co 	 : integer := 780;   -- = auto_ref_co > 7.81 * F in MHz	
	
	-- Konstanten fuer sig_command damit koennen wir zeilen sparen
	constant inhibit         : std_logic_vector(5 downto 0) := "111111";
	constant nop             : std_logic_vector(5 downto 0) := "011111";
	constant active          : std_logic_vector(5 downto 0) := "001111";
	constant reada           : std_logic_vector(5 downto 0) := "010100"; --tbd
	constant writea          : std_logic_vector(5 downto 0) := "010000"; --tbd
	constant burst_terminate : std_logic_vector(5 downto 0) := "011011";
	constant precharge       : std_logic_vector(5 downto 0) := "001011";
	constant auto_ref        : std_logic_vector(5 downto 0) := "000111";
	constant load_mode_reg   : std_logic_vector(5 downto 0) := "000011";	
	constant read_high_byte  : std_logic_vector(5 downto 0) := "011111"; --tbd
	constant read_low_byte   : std_logic_vector(5 downto 0) := "011111"; --tbd
	constant write_high_byte : std_logic_vector(5 downto 0) := "011111"; --tbd
	constant write_low_byte  : std_logic_vector(5 downto 0) := "011111"; --tbd
	constant rd_wr_in_prog   : std_logic_vector(5 downto 0) := "011100"; --tbd
	
	-- Component Deklarationen
	-- Phase locked
	component pll1 is
   port (
		inclk0        : in      std_logic;
		c0   		     : out     std_logic
	);
	end component;
	
	-- ############## Begin Architecture #############################################
	begin	
	
		-- ############ Instanziierung altpll (inclk0 in 50Mhz, c0 out 100Mhz) ########
		-- bei 100Mhz, 1 clktick = 10 ns
		pll : pll1
		port map 
		(
			inclk0 	=> CLK,
			c0  	   => sig_clk
		);
		
		-- ######### Process init_sig_delay ############################################
		-- # Inkrementiert zaehler um 200 microsekunde fuer SDRAM Init
		-- # Wenn das schon fertig ist dann wird fuer auto refreshs zaehler benutzt
		-- #############################################################################
		init_sig_delay: process(sig_clk)
		begin
		 if(rising_edge(sig_clk)) then
			if(RESET = '1') then
			  sig_delay <= (others => '0');
			  sig_one_auto_ref_time_done <= '0';
			else
			  if(sig_reset_del_count = '1') then 
				 sig_delay <= (others => '0');
			  elsif(sig_dram_init_done_s_del = '1') then
				 if(to_integer(unsigned(sig_delay)) = auto_ref_co) then
				 --d.h sig_delay hat schon 780 clockticks gezaehlt
				 --und wir mussen den Timer zuruckstellen und refresh signalisiert
					sig_delay <= (others => '0');
					sig_one_auto_ref_time_done <= '1';
				 else -- solange 780 clockticks noch nicht errreicht, weiter inkrementieren
					sig_delay <= incr_vec(sig_delay);
					sig_one_auto_ref_time_done <= '0';
				 end if;
			  else -- Initialisierungszeit (200 ms)
					sig_delay <= incr_vec(sig_delay);
					sig_one_auto_ref_time_done <= '0';
			  end if; 
			end if; 
		 end if; 
		end process init_sig_delay;
		-- ############# ende Prozess init_sig_delay ###################################
		
		-- #################### Prozess init_auto_ref_count_reg ########################
		-- # Berechnet wieviel auto refresh gemacht werden mussen 
		-- #############################################################################
		init_auto_ref_count_reg: PROCESS(sig_clk)
		begin
		 if(rising_edge(sig_clk)) then
			  sig_no_of_refs_needed <= (others => '0');
			if(reset = '1') then
			else
			  if(sig_dram_init_done_s = '1') then
				 if(sig_no_of_refs_needed = "1111111111") then
					sig_no_of_refs_needed <= sig_no_of_refs_needed;
				 else
					--sig_auto_ref_tim_done wird '1' for one clock cycle just
					--nach 780 clocks
					if(sig_one_auto_ref_time_done = '1') then
					  sig_no_of_refs_needed <= incr_vec(sig_no_of_refs_needed); 
					elsif(sig_one_auto_ref_complete = '1') then
					  --es muss geprueft werden dass der zaehler nicht unter 0 geht
					  --sollte eigentlich nicht passieren
					  if(sig_no_of_refs_needed = "0000000000") THEN
					    sig_no_of_refs_needed <= sig_no_of_refs_needed; 
					  else
						 sig_no_of_refs_needed <= dcr_vec(sig_no_of_refs_needed); 
					  end if;
					end if;
				 end if;
			  end if; --IF(dram_init_done_s = '1') THEN
			end if; --(reset = '1')
		 end if; --(RISING_EDGE(clk_in))
		end process init_auto_ref_count_reg;	
	   -- ############# ende Prozess init_auto_ref_count_reg ##########################
		
		-- ######### Prozess Befehle interpretieren ####################################
		-- # Uebernehmen das Befehl von Benutzer und leitet weiter intern
		-- # Grund, damit der User CMD nicht halten muss
		-- #############################################################################
		befehl_interpretieren: process(sig_clk,RESET)
		begin	
			if(rising_edge(sig_clk))then
				if(RESET = '1') and (sig_aktZustand=IDLE) then 	     -- Reset
					sig_doReset 	<= '1';
					sig_doInit 		<= '0';			
					sig_doRead 		<= '0';
					sig_doWrite 	<= '0';
					sig_doAutoRef 	<= '0';
				else		
				   -- Wenn irgendein Befehl vollstaendig durchgefuehrt,
					-- dann werden folgende Signale initialisiert um weitere Befehle aufzunehmen
		         if (sig_done='1') then
					sig_doReset 	<= '0';
					sig_doInit  	<= '0';
					sig_doWrite 	<= '0';
					sig_doRead  	<= '0';
				   sig_doAutoRef 	<= '0';	
			     	end if;
					
					if (sig_aktZustand=OFF) then     -- Initialisierung 
						sig_doReset 	<= '0';
						sig_doInit 		<= '1';			
						sig_doRead 		<= '0';
						sig_doWrite 	<= '0';
						sig_doAutoRef 	<= '0';
					elsif(sig_aktZustand=IDLE) and (sig_auto_ref_pending = '1') then -- Auto refresh
						sig_doReset 	<= '0';
						sig_doInit 		<= '0';			
						sig_doRead 		<= '0';
						sig_doWrite 	<= '0';
						sig_doAutoRef 	<= '1';			
					elsif(CMD = "01") and (sig_aktZustand=IDLE) then  -- Lesen 
						sig_doReset 	<= '0';
						sig_doInit 		<= '0';			
						sig_doRead 		<= '1';
						sig_doWrite 	<= '0';
						sig_doAutoRef 	<= '0';
					elsif(CMD = "10") and (sig_aktZustand=IDLE) then  -- Schreiben 
						sig_doReset 	<= '0';
						sig_doInit 		<= '0';			
						sig_doRead 		<= '0';
						sig_doWrite 	<= '1';
						sig_doAutoRef 	<= '0';
					elsif(CMD = "11") and (sig_aktZustand=IDLE) then  -- NOP 
						sig_doReset 	<= '0';
						sig_doInit 		<= '0';			
						sig_doRead 		<= '0';
						sig_doWrite 	<= '0';
						sig_doAutoRef 	<= '0';
					else
						sig_doInit 		<= sig_doInit;			
						sig_doRead 		<= sig_doRead;
						sig_doWrite 	<= sig_doWrite;
						sig_doReset 	<= sig_doReset;
						sig_doAutoRef 	<= sig_doAutoRef;						
					end if;				
				end if;
				
				
			end if;
		end process befehl_interpretieren;	
	  -- ############# ende Prozess befehl_interpretieren #############################
	  
	  -- ######### Prozess Befehle Ausfuehren #########################################
	  -- # Bearbeitet befehl signale und die Zustaende wechseln
	  -- ##############################################################################
	  befehl_ausfuehren: process(sig_clk)
	  begin
		  if(rising_edge(sig_clk))then
		     if(sig_done='1') then
			     sig_aktZustand <= IDLE;
			  end if;
		  	  if(sig_resetDone='1') then	
				  sig_aktZustand <= OFF;			  
			  elsif(sig_doReset='1') then
				  sig_aktZustand <= ZURUECKSETZEN;
			  elsif(sig_doAutoRef='1') then
				  sig_aktZustand <= AUTO_REFRESH;
			  elsif(sig_doInit='1') then
			     sig_aktZustand <= INIT;
			  elsif(sig_doWrite='1')then
				  sig_aktZustand <= SCHREIBEN;
			  elsif(sig_doRead='1') then
				  sig_aktZustand <= LESEN;
			  end if;		  
		  end if;	
	  end process befehl_ausfuehren;
	  -- ############# ende Prozess befehl_ausfuehren #################################
	  
	  -- ######### Prozess Zustandsbearbeitung ########################################
	  -- # Bearbeitet die Zustaende
	  -- ##############################################################################
     zustandsbearbeitung: process(sig_clk)
	  begin
	    if(rising_edge(sig_clk)) then
		 
		   -- ################## OFF ###################################################
		   if (sig_aktZustand=OFF) then
					sig_resetDone <= '0';
					
			-- ################## IDLE ##################################################	
			elsif (sig_aktZustand=IDLE) then
					sig_command 					<= nop;
					sig_addr 						<= (others => '0');
				   sig_ba 							<= sig_ba;	
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;
					
			-- ################## Initialisierung #######################################
			elsif (sig_aktZustand=INIT) then	
				sig_done <= '0';	
			   -- POWER ON (200 microsekunde warten)	
				-- Wenn 200 microsekunde schon vergangen ist dann 
				-- Precharge 
			   if(to_integer(unsigned(sig_delay)) = sd_init) then	 
					sig_command 					<= precharge;
					sig_addr 						<= (others => '0');
	            sig_addr(10) 					<= '1'; -- alle banken prechargen
			      sig_ba 							<= "11";		-- alle banken prechargen
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s; -- signal halten	
				-- 1. Auto Refresh 
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp) then	
					sig_command 					<= auto_ref;
					sig_addr 						<= (others => '0');
					sig_ba 							<= sig_ba;
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;		
				-- 2. Auto Refresh 
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + trfc) then	
					sig_command 					<= auto_ref;
					sig_addr 						<= (others => '0');
					sig_ba 							<= sig_ba;
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;				
				-- 3. Auto Refresh
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + 2*trfc) then
					sig_command 					<= auto_ref;
					sig_addr 						<= (others => '0');
					sig_ba 							<= sig_ba;
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;					
				-- 4. Auto Refresh
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + 3*trfc) then
					sig_command 					<= auto_ref;
					sig_addr 						<= (others => '0');
					sig_ba 							<= sig_ba;
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;					
				-- 5. Auto Refresh
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + 4*trfc) then
					sig_command 					<= auto_ref;
					sig_addr 						<= (others => '0');
					sig_ba 							<= sig_ba;
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;				
				-- 6. Auto Refresh
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + 5*trfc) then
					sig_command 					<= auto_ref;
					sig_addr 						<= (others => '0');
					sig_ba 							<= sig_ba;
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;				
				-- 7. Auto Refresh
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + 6*trfc) then
					sig_command 					<= auto_ref;
					sig_addr 						<= (others => '0');
					sig_ba 							<= sig_ba;
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;					
				-- 8. Auto Refresh
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + 7*trfc) then
					sig_command 					<= auto_ref;
					sig_addr 						<= (others => '0');
					sig_ba 							<= sig_ba;
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;				
				-- Mode Register Set
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + 8*trfc) then
					sig_command 					<= load_mode_reg;				
					sig_addr 						<= "0000000100000"; -- MRS Einstellung siehe Unten (notizen)
					sig_ba   						<= "00";		
				   sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;	
				   sig_dram_init_done_s 		<= sig_dram_init_done_s;
				-- Mode Register Set fertig
				elsif(to_integer(unsigned(sig_delay)) = sd_init + trp + 2*trfc + tmrd) then				
					sig_command 					<= nop;
					sig_addr 						<= (others => '0');
				   sig_ba 							<= sig_ba;	
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= '1';
					sig_done 						<= '1';		
				-- NOP wenn kein Befehl ausgefuehrt wird
				else 
				   sig_command 					<= nop;
					sig_addr 						<= (others => '0');
				   sig_ba 							<= sig_ba;	
					sig_one_auto_ref_complete 	<= sig_one_auto_ref_complete;
					sig_dram_init_done_s 		<= sig_dram_init_done_s;
				end if;
				
			-- ####################### Lesen ############################################
			elsif (sig_aktZustand=LESEN) then
			
			-- ####################### Schreiben ########################################
			elsif (sig_aktZustand=SCHREIBEN) then
			
			-- ####################### Zuruecksetzen ####################################
			elsif (sig_aktZustand=ZURUECKSETZEN) then
				-- Alles zuruecksetzen
				sig_command    		<= "000000";	
				sig_dram_init_done_s <= '0';
				sig_addr       		<= (others => '0');
				sig_ba					<=	(others => '0');	
            sig_resetDone			<= '1';		
				
			-- ####################### Auto Refresh #####################################	
		   elsif (sig_aktZustand=AUTO_REFRESH) then
				-- auto refresh ausfuehren und dekrementiert auto ref zaehler
				
			end if;		
		 end if;
	  end process zustandsbearbeitung;
	  -- ############# ende Prozess befehl_ausfuehren #################################
	  
	  -- ########## Prozess CKE generierung  ##########################################
	  -- # Generiert cke anhand reset 
	  -- ##############################################################################
	  delay_count: process(sig_clk)
     begin
		 if(rising_edge(sig_clk)) then

		  end if;
	  end process delay_count;
	  -- ############# ende Prozess befehl_ausfuehren #################################	
	  
	  -- ########## Prozess CKE generierung  ##########################################
	  -- # Generiert cke anhand reset 
	  -- ##############################################################################
	  cke_gen_reg: process(sig_clk)
     begin
		 if(rising_edge(sig_clk)) then
			if(RESET = '1') then
			  oDRAM0_CKE <= '0';
			else
			  oDRAM0_CKE <= '1';
			end if;
		  end if;
	  end process cke_gen_reg;
	  -- ############# ende Prozess befehl_ausfuehren #################################
	  
	  -- ############## Prozess reset_del_count_gen_reg ###############################
	  -- #  
	  -- ##############################################################################
			reset_del_count_gen_reg: PROCESS(sig_clk)
			BEGIN
				  IF(RISING_EDGE(sig_clk)) THEN
					 sig_dram_init_done_s_del <= sig_dram_init_done_s;
				  END IF;
			END PROCESS reset_del_count_gen_reg;
		-- ############# ende Prozess reset_del_count_gen_reg ##########################
		
	  -- generiert ein pulse reset_del_count waehrend dram_init_done_s high ist
	  sig_reset_del_count <= sig_dram_init_done_s AND not(sig_dram_init_done_s_del);
	  
	  -- ########## Prozess gen_auto_ref_pending_cmb ##################################
	  -- # Generiert auto_ref_signal anhand no_of_refs_needed
	  -- ##############################################################################
	  gen_auto_ref_pending_cmb: process (sig_no_of_refs_needed)
	  begin
		  if(to_integer(unsigned(sig_no_of_refs_needed)) = 0) then 
			 sig_auto_ref_pending <= '0';
		  else
			 sig_auto_ref_pending <= '1';
		  end if;
	  end process gen_auto_ref_pending_cmb;
	  -- ############# ende Prozess gen_auto_ref_pending_cmb ##########################
	  
	-- ########## extern signal <= intern signal zuweisung (benutzer Schnittstelle) ##################
	DRAM_INIT_DONE <= sig_dram_init_done_s;
	
	-- ########## extern signal <= intern signal zuweisung (DRAM Schnittstelle) ##################
	oDRAM0_A		   <= sig_addr; 	
	oDRAM0_BA      <=	sig_ba;	
	oDRAM0_CS_N		<=	sig_command(5);
	oDRAM0_CAS_N   <=	sig_command(4);
	oDRAM0_RAS_N   <=	sig_command(3);
	oDRAM0_WE_N	   <=	sig_command(2);
	oDRAM0_UDQM1	<=	sig_command(1); 
	oDRAM0_LDQM0   <=	sig_command(0);
   oDRAM0_CLK		<= sig_clk;
	
end VERHALTEN;

-- ###################################################################################
-- Notizen:
-- ###################################################################################
-- MRS Einstellung
-- oDRAM0_A[0]  <= '0'; -- Burst Length: 1
-- oDRAM0_A[1]  <= '0'; -- 
-- oDRAM0_A[2]  <= '0'; --
-- oDRAM0_A[3]  <= '0'; -- Burst Type: sequential
-- oDRAM0_A[4]  <= '0'; -- Latency Mode: 2 CAS
-- oDRAM0_A[5]  <= '1'; -- 
-- oDRAM0_A[6]  <= '0'; --
-- oDRAM0_A[7]  <= '0'; -- Operating Mode: Standard
-- oDRAM0_A[8]  <= '0'; --
-- oDRAM0_A[9]  <= '0'; -- Write Burst Mode: 0 Programmed Burst Length
-- oDRAM0_A[10] <= '0'; -- Reserved
-- oDRAM0_A[11] <= '0'; -- Reserved
-- oDRAM0_A[12] <= '0'; -- Reserved
-- oDRAM0_BA[0] <= '0'; -- Reserved
-- oDRAM0_BA[1] <= '0'; -- Reserved