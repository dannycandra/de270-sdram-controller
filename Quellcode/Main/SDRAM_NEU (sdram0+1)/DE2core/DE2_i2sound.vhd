--------------------------------------------------------------------------
-- Funktion     : Steuerprogramm für den WM8731 Audiocodec
-- Filename     : DE2_i2sound.vhd
-- Beschreibung : Über eine Generic Anweisung lassen sich die Abtastrate,
--				  die Ausgangslautstärke, die Eingangsempfindlichkeit und
--                das Eingangssignal (Line In oder Mic) einstellen.
--                Die Einstellungen werden durch eine Signalflanke auf dem 
--                Eingang RES übernommen.
--                Es werden die Komponenten i2c.v, keytr.v, clock_500.v 
--                und der PLL Baustein audio_clk.vhd benutzt.
-- Standard     : VHDL 1993
-- Author       : Ulrich Sandkuehler
-- Revision     : Version 1.0  10.09.2008
--------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all; 

ENTITY DE2_i2sound IS
-- Einstellung der Abtastrate:
    generic(sample_rate : std_logic_vector(2 downto 0) 
                        := "000";      -- 48 kHz
--                      := "110";      -- 32 kHz
--                      := "011";      --  8 kHz
--                      := "111";      -- 96 kHz
-- Einstellung der Ausgangslautstärke zwischen Minimum und Maximum
-- "0000000" bis "0101111" Stummschaltung:
             volume_out : std_logic_vector(6 downto 0)
--                      := "0110000";  -- -73 dB Minimum
                        := "1111001";  --   0 dB
--                      := "1111111";  --   6 dB Maximum
-- Einstellung der Eingangsempfindlichkeit zwischen Minimum und Maximum:
            sensitivity : std_logic_vector(4 downto 0)
--                      := "00000";    -- -34,5 dB Minimum
                        := "10111";    --   0 dB
--                      := "11111";    --  12 dB Maximum
-- Auswahl des Mikrofons / Line In Eingangs:
                    mic : std_logic
                        := '0');       -- Line In Eingang
--                      := '1');       -- Mikrofon Eingang
                    
	port(RES :       IN  STD_LOGIC;
		 CLOCK_50 :  IN  STD_LOGIC;
		 I2C_SDAT :  INOUT  STD_LOGIC;
		 I2C_SCLK :  OUT  STD_LOGIC;
		 AUD_XCK  : OUT  STD_LOGIC);
END DE2_i2sound;

ARCHITECTURE bdf_type OF DE2_i2sound IS 

component i2c                        -- Hilfsprogramm
	PORT(CLOCK : IN STD_LOGIC;
		 GO : IN STD_LOGIC;
		 RESET : IN STD_LOGIC;
		 I2C_SDAT : INOUT STD_LOGIC;
		 I2C_DATA : IN STD_LOGIC_VECTOR(23 downto 0);
		 I2C_SCLK : OUT STD_LOGIC;
		 ENDT : OUT STD_LOGIC);
end component;

component keytr                      -- Hilfsprogramm
	PORT(key : IN STD_LOGIC;
		 clock : IN STD_LOGIC;
		 KEYON : OUT STD_LOGIC);
end component;

component audio_clk                  -- PLL zur Erzeugung des Audiotaktes
	PORT(inclk0 : IN STD_LOGIC;
		 c0 : OUT STD_LOGIC;
		 c1 : OUT STD_LOGIC);
end component;

component clock_500                             -- Steuerprogramm
	PORT(CLOCK : IN STD_LOGIC;
		 ENDT : IN STD_LOGIC;
		 RESET : IN STD_LOGIC;
		 SR : IN STD_LOGIC_VECTOR(2 downto 0);        -- Abtastrate
		 VOL_IN : IN STD_LOGIC_VECTOR(4 downto 0);    -- Eingangsempfindlichkeit
		 VOL_OUT : IN STD_LOGIC_VECTOR(6 downto 0);   -- Ausgangspegel
		 MIC : IN STD_LOGIC;                          -- Auswahl Line In / Mic
		 CLOCK_500 : OUT STD_LOGIC;
		 GO : OUT STD_LOGIC;
		 CLOCK_2 : OUT STD_LOGIC;
		 DATA : OUT STD_LOGIC_VECTOR(23 downto 0));
end component;

signal	SYNTHESIZED_WIRE_7 :  STD_LOGIC;
signal	SYNTHESIZED_WIRE_1 :  STD_LOGIC;
signal	SYNTHESIZED_WIRE_2 :  STD_LOGIC;
signal	SYNTHESIZED_WIRE_3 :  STD_LOGIC_VECTOR(23 downto 0);
signal	SYNTHESIZED_WIRE_5 :  STD_LOGIC;
signal	SYNTHESIZED_WIRE_6 :  STD_LOGIC;

BEGIN 
SYNTHESIZED_WIRE_2 <= '1';

b2v_inst : i2c
PORT MAP(CLOCK => SYNTHESIZED_WIRE_7,
		 GO => SYNTHESIZED_WIRE_1,
		 RESET => SYNTHESIZED_WIRE_2,
		 I2C_SDAT => I2C_SDAT,
		 I2C_DATA => SYNTHESIZED_WIRE_3,
		 I2C_SCLK => I2C_SCLK,
		 ENDT => SYNTHESIZED_WIRE_5);

b2v_inst1 : keytr
PORT MAP(key => RES,              -- Übernahme der Einstellungen
		 clock => SYNTHESIZED_WIRE_7,
		 KEYON => SYNTHESIZED_WIRE_6);

b2v_inst14 : audio_clk            -- Generierung des Audiotaktes
PORT MAP(inclk0 => CLOCK_50,
		 c0 => AUD_XCK,
		 c1 => open);

b2v_inst4 : clock_500             -- Steuerprogramm
PORT MAP(CLOCK => CLOCK_50,
		 ENDT => SYNTHESIZED_WIRE_5,
		 RESET => SYNTHESIZED_WIRE_6,
		 SR => sample_rate,
		 VOL_IN => sensitivity,
		 VOL_OUT => volume_out,
		 MIC => mic,
		 CLOCK_500 => SYNTHESIZED_WIRE_7,
		 GO => SYNTHESIZED_WIRE_1,
		 DATA => SYNTHESIZED_WIRE_3);
END; 