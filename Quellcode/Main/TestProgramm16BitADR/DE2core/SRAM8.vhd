-----------------------------------------------------------------------
-- Funktion     : Ansteuerung des extern SRAM Speichers auf dem DE2 Board
-- Filename     : SRAM8.vhd
-- Beschreibung : Das externe Single-Port 256k x 16 SRAM wird als Pseudo-
--                Dual-Port Speicher mit gebuffertem Eingang betrieben.
--                Das Steuermodul SRAM stellt je 19 Bit Schreib- und 
--                Leseadressen (ADR_IN, ADR_OUT) und 8 Bit -daten (DATA_IN, 
--                DATA_OUT) zur Verfügung. RESET löscht den Speicherinhalt.
--				  Alle SRAM Anschlüsse sind fest auf dem DE2 Board verdrahtet.
-- Standard     : VHDL 1993
-- Author       : Ulrich Sandkuehler
-- Revision     : Version 1.7 19.5.2009
----------------------------------------------------------------------- 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity SRAM8 is 
port (CLOCK, RESET		: in std_logic;    -- Takt, Löschen des Speichers
	  DATA_IN           : in std_logic_vector(7 downto 0);
	  ADR_IN            : in std_logic_vector(18 downto 0);
	  ADR_OUT           : in std_logic_vector(18 downto 0);
	  DATA_OUT          : out std_logic_vector(7 downto 0);
	  WE                : in std_logic;    -- Write Enable active low
	  SRAM_ADDR			: out std_logic_vector(17 downto 0);
	  SRAM_DQ			: inout std_logic_vector(15 downto 0);
	  SRAM_WE_N			: buffer std_logic;
	  SRAM_CE_N, SRAM_OE_N, SRAM_UB_N, SRAM_LB_N : out std_logic);
end SRAM8;

architecture VERHALTEN of SRAM8 is
signal WR		: STD_LOGIC;
signal REG_DATA : std_logic_vector(15 downto 0); 
signal REG_ADR  : std_logic_vector(18 downto 0);

begin
process(CLOCK)
variable CNT : std_logic_vector(18 downto 0); --Adresszählvariable
   begin
	  if rising_edge(CLOCK) then
	     if RESET = '0' then	-- LÖSCHEN DES SPEICHERS:
			WR  <= '0';				      -- Schreiben
			REG_DATA <= (others => '0');  -- 0-Daten
			CNT := CNT + 1;     -- Hochzählen des Zählers
		    REG_ADR <= CNT;     -- Adresse der gelöschten Speicherzelle
		 else
		    WR <= WE;         -- Register für Write Enable (active low)
	        REG_DATA  <= DATA_IN & DATA_IN;    -- Register für Eingangsdaten
	        if (WE = '0') then REG_ADR <= ADR_IN;  -- Umschaltung Schreib- /
	                      else REG_ADR <= ADR_OUT; -- Leseadressen
	        end if;
         end if;
	  end if;
	end process;
	
	SRAM_WE_N <= WR;		                     -- SRAM Write Enable
    SRAM_ADDR <= REG_ADR(17 downto 0);	         -- SRAM Speicheradresse
	SRAM_DQ   <= REG_DATA WHEN (SRAM_WE_N = '0') -- SRAM Dateneingabe
						  ELSE "ZZZZZZZZZZZZZZZZ";
	DATA_OUT  <= SRAM_DQ(7 downto 0)  when REG_ADR(18) = '0'  else
				 SRAM_DQ(15 downto 8);			 -- SRAM Datenausgabe
	SRAM_CE_N <= '0';					-- SRAM Chip Enable
	SRAM_OE_N <= '0';					-- SRAM Output Enable
	SRAM_UB_N <= not REG_ADR(18);		-- SRAM Enable für oberes Daten Byte
	SRAM_LB_N <= REG_ADR(18);			-- SRAM Enable für unters Daten Byte
end VERHALTEN;

