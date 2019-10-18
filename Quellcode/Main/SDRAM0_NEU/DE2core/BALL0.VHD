--------------------------------------------------------------------------
-- Funktion     : Bewegter Ball
-- Filename     : ball0.vhd
-- Beschreibung : Ein rechteckiger, farbiger Ball bewegt sich in 
--				  Y-Richtung auf einem VGA-Monitor in unterschiedlicher,
--                einstellbarer Geschwindigkeit.
-- Standard     : VHDL 1993
-- Author       : Ulrich Sandkuehler
-- Revision     : Version 1.5  03.03.2007
--------------------------------------------------------------------------
LIBRARY IEEE;                    
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_ARITH.all;         -- Bibliotheken fuer numerische Operationen
USE IEEE.STD_LOGIC_UNSIGNED.all;

ENTITY ball0 IS
PORT(pixel_row, pixel_column	: IN  STD_LOGIC_VECTOR(9 DOWNTO 0); --VGA
     Red,Green,Blue 			: OUT STD_LOGIC;   -- VGA Ausgang
     vert_sync	                : IN  STD_LOGIC;   -- VGA Vertical Sync
     SW               : IN  STD_LOGIC_VECTOR(2 DOWNTO 0));  -- Geschwindigkeit, Reset
END ball0;

ARCHITECTURE behavior OF ball0 IS
-- Video Display Signals:   
SIGNAL Ball_on, reset          	: STD_LOGIC;                     -- Balldarstellung
SIGNAL Size 					: STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Ballgroesse
SIGNAL Ball_X_pos, Ball_Y_pos	: STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Ballposition
SIGNAL Yup                      : BIT;       -- Flugrichtung up/down

BEGIN           
reset <= SW(2);								-- Resetuebergabe
Size  <= CONV_STD_LOGIC_VECTOR(8,10);       -- Ballgroesse (8 Pixel, Rechteck)
Red   <= '1';				                -- Ballfarbe
-- Ausschalten der Hintergrundfarben Green/Blue bei der Darstellung des Balls:
Green <= NOT Ball_on;
Blue  <= NOT Ball_on;


-- Display-Ausgabe des Balls:
RGB_Display: Process (Ball_X_pos, Ball_Y_pos, pixel_column, pixel_row, Size)
BEGIN
-- Setzen von Ball_on ='1' um den Ball darzustellen:
IF (Ball_X_pos <= pixel_column + Size) AND  -- rechte Ballkante
   (Ball_X_pos + Size >= pixel_column) AND  -- linke Ballkante
   (Ball_Y_pos <= pixel_row + Size)    AND  -- obere Ballkante
   (Ball_Y_pos + Size >= pixel_row )   THEN  Ball_on <= '1';  -- untere Ballkante
 	                                   ELSE  Ball_on <= '0';
END IF;
END process RGB_Display;


-- Ballbewegung um einen Schritt mit jedem vertikalen Sync-Impuls:
Move_Ball: PROCESS(vert_sync, reset)
BEGIN
IF reset = '0' THEN 							 -- Reset fuer
   Ball_X_pos <= CONV_STD_LOGIC_VECTOR(320,10);  -- X-Position
   Ball_Y_pos <= CONV_STD_LOGIC_VECTOR(240,10);  -- Y-Position

   ELSIF (vert_sync'event AND vert_sync = '1') THEN
	  -- Reflexion (Richtungsaenderung in Y) am oberen oder unteren Bildschirmrand:
	  IF    (Yup = '1') AND (Ball_Y_pos >= 480 - Size) THEN 
	         Yup <= '0';             -- Richtungsaenderung am oberen Rand
	  ELSIF (Yup = '0') AND (Ball_Y_pos <= Size)       THEN 
	         Yup <= '1';             -- Richtungsaenderung am unterern Rand
	  ELSE  NULL;
	  END IF;
	  
	  -- Positionsaenderung des Balls in Y-Richtung:
      IF   Yup = '1' THEN 
           Ball_Y_pos <= Ball_Y_pos + SW(1 DOWNTO 0); -- negative Y-Geschwindigkeit
	  ELSE Ball_Y_pos <= Ball_Y_pos - SW(1 DOWNTO 0); -- positive Y-Geschwindigkeit
      END IF;
	
END IF;
END PROCESS Move_Ball;
END behavior;
