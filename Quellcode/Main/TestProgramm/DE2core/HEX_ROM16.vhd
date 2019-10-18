----------------------------------------------------------------------
-- Funktion     : Character Rom fuer 16 HEX Zeichen (0, 1, 2, ... , F)
-- Filename     : HEX_ROM16.vhd
-- Beschreibung : 16x16 Pixel, 16 Arial Zeichen CHAR_ROM mit Aktivierung
--				  des In-System Memory Content Editors.
--                Benötigt wird die Datei HEX.mif
-- Standard     : VHDL 1993
-- Author       : Ulrich Sandkuehler
-- Revision     : Version 1.2 10.04.2009
-----------------------------------------------------------------------
library IEEE;
use  IEEE.STD_LOGIC_1164.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY HEX_ROM16 IS
	PORT(clock				: IN 	STD_LOGIC;
		 character_address	: IN	STD_LOGIC_VECTOR(3 DOWNTO 0);
		 font_row, font_col	: IN 	STD_LOGIC_VECTOR(3 DOWNTO 0);
		 rom_mux_output	    : OUT	STD_LOGIC);
END HEX_ROM16;

ARCHITECTURE BEHAVIOR OF HEX_ROM16 IS

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
	  address_a	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);    -- Adressbreite
	  q_a		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)); -- Zeichenbreite
END COMPONENT;
    
SIGNAL	rom_data:    STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

rom_mux_output <= rom_data ( (CONV_INTEGER(NOT font_col(3 downto 0))));

altsyncram_component : altsyncram
GENERIC MAP(clock_enable_input_a  => "BYPASS",
			clock_enable_output_a => "BYPASS",
			init_file 			  => "HEX16.MIF",	-- Fontsatz für CHAR_ROM
			intended_device_family=> "Cyclone II",
			lpm_hint 			  => -- Aktivierung des In-System Memory Content Editors
									 "ENABLE_RUNTIME_MOD=YES, INSTANCE_NAME=ROM",
			lpm_type 			  => "altsyncram",
			numwords_a 			  => 256,	-- Zeichenhöhe in Pixel x Zeichenanzahl
			operation_mode 		  => "ROM",
			outdata_aclr_a 	      => "NONE",
			outdata_reg_a 		  => "UNREGISTERED",
			widthad_a             => 8,			-- Adressbreite für "numwords_a"
			width_a 			  => 16,		-- Zeichenbreite in Pixel
			width_byteena_a 	  => 1)
PORT MAP(clock0    => clock,
		 address_a => character_address & font_row,
		 q_a       => rom_data);

END BEHAVIOR;

