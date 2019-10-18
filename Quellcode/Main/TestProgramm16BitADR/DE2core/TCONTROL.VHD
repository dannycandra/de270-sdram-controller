-------------------------------------------------------------------------
-- Funktion     : Zugsteuerung
-- Filename     : TCONTROL.VHD
-- Beschreibung : Steuerung von zwei Zuegen, die sich entgegen dem 
--                Uhrzeigersinn bewegen entsprechend dem Modell in
--				  Hamblen, Rapid Prototypimg of Digital Systerms.
--                Das Programm ist Teil der Video-Darstellung train.vhd.
--                Sensorwerte, Weichenstellungen und verschiedene Zug-
--                parameter werden an train.vhd uebergeben und dort
--                mittels VGA-Monitor, LCD-Display und 7-Segmentanzeige
--                dargestellt.
-- Standard     : VHDL 1993
-- Revision     : Version 1.5 23.01.2007
-------------------------------------------------------------------------

LIBRARY IEEE;
USE  IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

-- Definition der Ein- und Ausgangssignale der Zustandsmaschine.
-- Bitte nicht veraendern!
ENTITY Tcontrol IS
   PORT(reset, clock, sensor1, sensor2      : IN std_logic;
        sensor3, sensor4, sensor5           : IN std_logic;
        switch1, switch2, switch3           : OUT std_logic;  -- Weichen
        track1, track2, track3, track4      : OUT std_logic;
        dirA, dirB                          : OUT std_logic_vector(1 DOWNTO 0);
        Acount, Bcount                      : OUT std_logic_vector(3 DOWNTO 0);
        status                              : OUT string(1 TO 6));
END Tcontrol;

-- Der folgende Code beschreibt die Arbeitsweise der Zustandsmaschine.
-- Aenderungen in der Arbeitsweise fuer andere FSMs sind hier vorzunehmen.
ARCHITECTURE verhalten OF Tcontrol IS
TYPE STATE_TYPE IS (ABup, Adown, Bdown, Astop, Bstop); -- Zustaende
SIGNAL state                         : STATE_TYPE;
SIGNAL sensor12, sensor13, sensor24  : std_logic_vector(1 DOWNTO 0);
SIGNAL Acnt, Bcnt : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
-- Zusammenfassung von Sensoren:
sensor12 <= sensor1 & sensor2;
sensor13 <= sensor1 & sensor3;
sensor24 <= sensor2 & sensor4;

PROCESS (clock, reset)
   BEGIN
-- Asynchroner Reset der FSM auf Zustand ABup
   IF reset = '1' THEN
      state <= ABup;
   ELSIF clock'EVENT AND clock = '1' THEN
		
-- Bedingte Uebergaenge in die verschiedenen Folgezustaende:
      CASE state IS
         WHEN ABup =>                 -- Zustand ABup
            CASE Sensor12 IS          -- Abfrage der Sensoren 1 und 2
               WHEN "00"   => state <= ABup;
               WHEN "01"   => state <= Bdown;
               WHEN "10"   => state <= Adown;
               WHEN "11"   => state <= Adown;
               WHEN OTHERS => state <= ABup;
            END CASE;

         WHEN Adown =>                -- Zustand Adown
            CASE Sensor24 IS          -- Abfrage der Sensoren 2 und 4
               WHEN "00"   => state <= Adown;
               WHEN "01"   => state <= ABup;
               WHEN "10"   => state <= Bstop;
               WHEN "11"   => state <= ABup;
               WHEN OTHERS => state <= ABup;
            END CASE;

         WHEN Bdown =>                -- Zustand Bdown
            CASE Sensor13 IS          -- Abfrage der Sensoren 1 und 3
               WHEN "00"   => state <= Bdown;
               WHEN "01"   => state <= ABup;
               WHEN "10"   => state <= Astop;
               WHEN "11"   => state <= ABup;
               WHEN OTHERS => state <= ABup;
            END CASE;

         WHEN Astop =>                -- Zustand Astop
            IF Sensor3 = '1' THEN     -- Abfrage des Sensors 3
                  state <= Adown;
            ELSE  state <= Astop;
            END IF;

         WHEN Bstop =>                -- Zustand Bstop
            IF Sensor4 = '1' THEN     -- Abfrage des Sensors 4
                 state <= Bdown;
            ELSE state <= Bstop;
			END IF;
      END CASE;
   END IF;
END PROCESS;

-- Die folgenden Ausgaenge sind in allen Zustaenden gleich:
	Track1  <= '0';
	Track3  <= '1';
    Track4  <= '0';
    Switch3 <= '0';

-- Ausgabe der Steuersignale:
	WITH state SELECT               -- Zuordnung der Lok zum Track
		Track2	<=	'0'	WHEN ABup,
					'0'	WHEN Adown,
					'1'	WHEN Bdown,
                	'1' WHEN Astop,
                	'0' WHEN Bstop;
	WITH state SELECT               -- Weichenstellung SW1
		Switch1 <=	'0'	WHEN ABup,
					'0'	WHEN Adown,
					'1'	WHEN Bdown,
                	'1' WHEN Astop,
                	'0' WHEN Bstop;
	WITH state SELECT               -- Weichenstellung SW2
		Switch2 <=	'0'	WHEN ABup,
					'0'	WHEN Adown,
					'1'	WHEN Bdown,
                	'1' WHEN Astop,
                	'0' WHEN Bstop;
	WITH state SELECT               -- Fahrtrichtung Lok A
		DirA 	<=	"01" WHEN ABup,
					"01" WHEN Adown,
					"01" WHEN Bdown,
                	"00" WHEN Astop,
                	"01" WHEN Bstop;
	WITH state SELECT               -- Fahrtrichtung Lok B
		DirB 	<=	"01" WHEN ABup,
					"01" WHEN Adown,
					"01" WHEN Bdown,
                	"01" WHEN Astop,
                	"00" WHEN Bstop;
    WITH state SELECT                -- Statusausgabe für TRAIN.VHD
		status 	<=	"ABup  " WHEN ABup,
					"Adown " WHEN Adown,
					"Bdown " WHEN Bdown,
                	"Astop " WHEN Astop,
                	"Bstop " WHEN Bstop;

-- Zaehlen der Passagen von Zug A bei Sensor 1:
PROCESS (Sensor1)
BEGIN
   IF reset = '1' THEN
      Acnt <= "0000";
   ELSIF FALLING_EDGE(Sensor1)  THEN 
      Acnt <= Acnt + 1;
   END IF;
END PROCESS;
Acount <= Acnt;

-- Zaehlen der Passagen von Zug B bei Sensor 2:
PROCESS (Sensor2)
BEGIN
   IF reset = '1' THEN
      Bcnt <= "0000";
   ELSIF FALLING_EDGE(Sensor2)  THEN 
      Bcnt <= Bcnt + 1;
   END IF;
END PROCESS;
Bcount <= Bcnt;
END verhalten;
