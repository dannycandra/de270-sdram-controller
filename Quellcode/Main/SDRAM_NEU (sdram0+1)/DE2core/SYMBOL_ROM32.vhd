----------------------------------------------------------------------
-- Funktion     : Character Rom fuer 16 Symbole
-- Filename     : SYMBOL_ROM32.vhd
-- Beschreibung : 32x32 Pixel, 16 Symbole CHAR_ROM mit Aktivierung des 
--				  In-System Memory Content Editors.
--                Benötigt wird die Datei SYMBOL32.mif
-- Standard     : VHDL 1993
-- Author       : Ulrich Sandkuehler
-- Revision     : Version 1.2 29.03.2009
-----------------------------------------------------------------------
library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY SYMBOL_ROM32 IS
	PORT(clock				: IN 	STD_LOGIC;
		 character_address	: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
		 font_row, font_col	: IN 	STD_LOGIC_VECTOR(4 DOWNTO 0);
		 rom_mux_output	    : OUT	STD_LOGIC);
END SYMBOL_ROM32;

ARCHITECTURE BEHAVIOR OF SYMBOL_ROM32 IS

COMPONENT altsyncram
GENERIC (clock_enable_input_a	: STRING;
		 clock_enable_output_a	: STRING;
		 init_file				: STRING;
		 intended_device_family	: STRING;
		 lpm_hint				: STRING;
		 lpm_type				: STRING;
		 numwords_a				: NATURAL;
		 operation_mode			: STRING;
		 outdata_aclr_a			: STRING;
		 outdata_reg_a			: STRING;
		 widthad_a				: NATURAL;
		 width_a				: NATURAL;
		 width_byteena_a		: NATURAL);
PORT (clock0	: IN STD_LOGIC ;
	  address_a	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);    -- Adressbreite
	  q_a		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)); -- Zeichenbreite
END COMPONENT;
    
SIGNAL	rom_data:    STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

rom_mux_output <= rom_data ( (CONV_INTEGER(NOT font_col(4 downto 0))));

altsyncram_component : altsyncram
GENERIC MAP(clock_enable_input_a  => "BYPASS",
			clock_enable_output_a => "BYPASS",
			init_file 			  => "SYMBOL32.MIF",	-- Fontsatz für CHAR_ROM
			intended_device_family=> "Cyclone II",
			lpm_hint 			  => -- Aktivierung des In-System Memory Content Editors
									 "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=ROM",
			lpm_type 			  => "altsyncram",
			numwords_a 			  => 512,	    -- Zeichenhöhe in Pixel x Zeichenanzahl
			operation_mode 		  => "ROM",
			outdata_aclr_a 	      => "NONE",
			outdata_reg_a 		  => "UNREGISTERED",
			widthad_a             => 9,			-- Adressbreite für "numwords_a"
			width_a 			  => 31,		-- Zeichenbreite in Pixel
			width_byteena_a 	  => 1)
PORT MAP(clock0    => clock,
		 address_a => character_address & font_row,
		 q_a       => rom_data);

END BEHAVIOR;

