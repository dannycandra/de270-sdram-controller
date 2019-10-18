---------------------------------------------------------------------------
-- Funktion     : Scancode-Decoder
-- Filename     : scan2char.vhd
-- Beschreibung	: Umsetzung des Scan-Codes, wie er von KEYBOARD geliefert
--                wird, in den Character-Code des CHAR_ROM (Sonderzeichen
--				  werden nur eingeschraenkt umgesetzt).
-- Standard     : VHDL 1993
-- Author       : Ulrich Sandkuehler
-- Revision     : Version 1.2 30.08.2007
---------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY scan2char IS
  PORT (scan : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        scan_ready, CLOCK_50 : IN STD_LOGIC;
        char : BUFFER STD_LOGIC_VECTOR(5 DOWNTO 0);
        read_reset : OUT STD_LOGIC);
END ENTITY scan2char;

ARCHITECTURE verhalten OF scan2char IS
BEGIN
  WITH scan SELECT   -- scan zu Character Code-Umsetzung:
    char <= o"01" WHEN x"1C",  -- A
            o"02" WHEN x"32",  -- B
            o"03" WHEN x"21",  -- C
            o"04" WHEN x"23",  -- D
            o"05" WHEN x"24",  -- E
            o"06" WHEN x"2B",  -- F
            o"07" WHEN x"34",  -- G
            o"10" WHEN x"33",  -- H
            o"11" WHEN x"43",  -- I
            o"12" WHEN x"3B",  -- J
            o"13" WHEN x"42",  -- K
            o"14" WHEN x"4B",  -- L
            o"15" WHEN x"3A",  -- M
            o"16" WHEN x"31",  -- N
            o"17" WHEN x"44",  -- O
            o"20" WHEN x"4D",  -- P
            o"21" WHEN x"15",  -- Q
            o"22" WHEN x"2D",  -- R
            o"23" WHEN x"1B",  -- S
            o"24" WHEN x"2C",  -- T
            o"25" WHEN x"3C",  -- U
            o"26" WHEN x"2A",  -- V
            o"27" WHEN x"1D",  -- W
            o"30" WHEN x"22",  -- X
            o"31" WHEN x"1A",  -- Y
            o"32" WHEN x"35",  -- Z
            o"40" WHEN x"29",  -- Leertaste
            o"53" WHEN x"5B",  -- +
            o"37" WHEN x"61",  -- <
            o"54" WHEN x"41",  -- ,
            o"55" WHEN x"4A",  -- -
            o"56" WHEN x"49",  -- .
            o"47" WHEN x"55",  -- '
            o"60" WHEN x"45",  -- 0
            o"61" WHEN x"16",  -- 1
            o"62" WHEN x"1E",  -- 2
            o"63" WHEN x"26",  -- 3
            o"64" WHEN x"25",  -- 4
            o"65" WHEN x"2E",  -- 5
            o"66" WHEN x"36",  -- 6
            o"67" WHEN x"3D",  -- 7
            o"70" WHEN x"3E",  -- 8
            o"71" WHEN x"46",  -- 9
            o"43" WHEN x"5D",  -- #
            o"34" WHEN x"5A",  -- Enter
            o"36" WHEN x"66",  -- Backspace
            o"00" WHEN OTHERS; -- @ Sonderzeichen
            
-- Generierung eines Rücksetzsignals für KEYBOARD :
reset_scan: PROCESS (CLOCK_50, scan_ready) IS
--SUBTYPE short IS INTEGER RANGE 0 TO 5000000;
--VARIABLE count : short;
BEGIN
     IF RISING_EDGE(CLOCK_50) THEN
--        count := count+1;
      	IF (scan_ready = '1') --AND (count = 5000000)
           THEN read_reset <= '1';
           ELSE read_reset <= '0';
        END IF;
     END IF;
     END PROCESS reset_scan;

END ARCHITECTURE verhalten;

