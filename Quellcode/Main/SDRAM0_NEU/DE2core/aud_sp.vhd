-- Beschreibung:	Seriell-Parallel-Umsetzer 
--					speziell für den Audio-Codec WM8731 von Wolfson 
--					im "DSP", "Master" und (n/2)-Bit Betrieb
-- Autor: Christoph Kozicki 10005775
-- Datum: 08.08.2008	


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY aud_sp IS
	GENERIC	(n : NATURAL := 48);
	PORT	(AUD_BCLK, AUD_ADCLRCK, AUD_ADCDAT : IN STD_LOGIC;	--Bit-Takt
			 ctrl_out : OUT STD_LOGIC;  					--bei '1' Ist "p_out" gültig
			 p_out_L : OUT STD_LOGIC_VECTOR(n-25 DOWNTO 0);
			 p_out_R : OUT STD_LOGIC_VECTOR(n-25 DOWNTO 0)); --paralleler Ausgang Bit n-1 = MSB des linken Kanals, Bit n-25 = MSB des rechten Kanals, Bit 0 = LSB des rechten Kanals
END ENTITY aud_sp;

ARCHITECTURE verhalten OF aud_sp IS
	BEGIN
		p0: PROCESS(AUD_BCLK, AUD_ADCLRCK) IS
			VARIABLE reg : STD_LOGIC_VECTOR(n-1 DOWNTO 0);	--Stereo-Audioregister 
			VARIABLE count : NATURAL:= n;	--Zählt von 0 bis n
			VARIABLE aktiv : NATURAL:= 0;	--Bei 1 wird ausgegeben
			BEGIN			
				IF RISING_EDGE(AUD_BCLK) THEN	
					IF (AUD_ADCLRCK = '1') THEN	--Reset& Starte Seriell-Parallel-Umsetzung, da ADC-Daten folgen
						count := 0;
						reg := (OTHERS => '0');	
						aktiv := 1;
						--ctrl_out <= '0';
					ELSIF (AUD_ADCLRCK = '0') THEN		
						IF (aktiv = 1) THEN
							IF (count = n) THEN	 --Starte Ausgabe
								p_out_L <= reg(n-1 DOWNTO n-24);     -- Ausgabe  
								p_out_R <= reg(n-25 DOWNTO 0);     -- Ausgabe
								ctrl_out <= '1';	--Setze für 1Bclk-Takt Ausgabe:gültig
								aktiv := 0;
							ELSE				-- Seriell-Parallel-Umsetzung
								reg := reg(n-2 DOWNTO 0) & AUD_ADCDAT;  --linksschieben (MSB liegt an Bit: n-1)
								count := count+1;
							END IF;	
						ELSE
							ctrl_out <= '0'; --Setze 1Bclk-Takt nach Ausgabe:gültig auf Ausgabe:ungültig
						END IF;
					END IF;		
				END IF;				
			END PROCESS p0;
END ARCHITECTURE verhalten;