-- Beschreibung:	Parallel-Seriell-Umsetzer 
--					speziell für den Audio-Codec WM8731 von Wolfson 
--					im "DSP", "Master" und (n/2)-Bit Betrieb
-- Autor: Christoph Kozicki 10005775
-- Datum: 08.08.2008	

LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY aud_ps IS
	GENERIC	(n : NATURAL := 48);
	PORT	(AUD_BCLK, AUD_DACLRCK : IN STD_LOGIC;	
			 ctrl_in : IN STD_LOGIC;		--bei '1' Ist "p_in" gültig
			 p_in_L : IN STD_LOGIC_VECTOR(n-25 DOWNTO 0); --paralleler Eingang Bit n-1 = MSB des linken Kanals, Bit n-25 = MSB des rechten Kanals, Bit 0 = LSB des rechten Kanals
			 p_in_R : IN STD_LOGIC_VECTOR(n-25 DOWNTO 0);
			 AUD_DACDAT : OUT STD_LOGIC);		--Serieller Ausgang
END ENTITY aud_ps;

ARCHITECTURE verhalten OF aud_ps IS
	BEGIN
		p1: PROCESS(ctrl_in, AUD_BCLK, AUD_DACLRCK) IS
			VARIABLE reg : STD_LOGIC_VECTOR(n-1 DOWNTO 0);	
			VARIABLE s_out : STD_LOGIC;		
			VARIABLE cnt : NATURAL:=0; --Zählt von n-1 bis 0
			BEGIN
				IF (AUD_DACLRCK = '1') THEN -- Reset & Starte Serielle Ausgabe, da Daten erwartet werden
				    cnt := n-1;			
					AUD_DACDAT <= reg(n-1);	-- MSB des linken Kanals muss schon hier ausgegeben werden, da die erste fallende Flanke von bitclk nicht erkannt wird.
				ELSIF (ctrl_in = '1') THEN		--"p_in" ist gültig, also kopiere ins Register 				
					reg(n-1 DOWNTO n-24):=p_in_L;    
					reg(n-25 DOWNTO 0):=p_in_R;     				
				ELSE
					IF (AUD_BCLK'EVENT AND AUD_BCLK = '0') THEN	--Setzte bei jeder fallenden Flanke (Außer wenn "dac_LRc" oder "ctrl_in" = '1' sind) den Ausgang
						IF (cnt = 0) THEN				 --Daten werden nicht mehr erwartet
							s_out := '0';						
						ELSE
							s_out := reg(cnt-1);   		--Bitweise Ausgabe. Starte mit dem n-2 ten Bit
							cnt := cnt-1;
						END IF;				
						AUD_DACDAT <= s_out;
					END IF;
				END IF;				  
			END PROCESS p1;
END ARCHITECTURE verhalten;