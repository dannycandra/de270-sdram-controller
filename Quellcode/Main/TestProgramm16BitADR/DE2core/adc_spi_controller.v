// --------------------------------------------------------------------
// Copyright (c) 2005 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	This funtion will config and read Touch Screen Digitizer 
// 					X an Y coordinate form LTM 
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| Johnny Fan        :| 06/03/23  :|      Initial Revision
// 
// Deutsches Kommentar von Christoph Kozicki, Matr.Nr. 10005775
// --------------------------------------------------------------------
module adc_spi_controller	(
					iCLK,
					iRST_n,
					oADC_DIN,
					oADC_DCLK,
					oADC_CS,
					iADC_DOUT,
					iADC_BUSY,
					iADC_PENIRQ_n,
					oTOUCH_IRQ,
					oNEW_COORD,
					oX_COORD,
					oY_COORD,
					///////////////////
					);
					
//============================================================================
// PARAMETER declarations
//============================================================================	
parameter SYSCLK_FRQ	= 50000000;
parameter ADC_DCLK_FRQ	= 1000;
parameter ADC_DCLK_CNT	= SYSCLK_FRQ/(ADC_DCLK_FRQ*2);
					
//===========================================================================
// PORT declarations
//=========================================================================== 
input			iCLK;
input			iRST_n; //0 = Reset, 1 = Ein
input			iADC_DOUT; //Daten aus dem ADC
input			iADC_PENIRQ_n; //Interrupt vom ADC
input			iADC_BUSY; //aktiver Datentransfer vom ADC
output			oADC_DIN; //Daten zum ADC
output			oADC_DCLK; //Bittakt für den ADC (hier ca. 12.5kHz, nicht synchron!!)
output			oADC_CS; //aktiver Datentransfer zum ADC 
output			oTOUCH_IRQ; //zur internen weiterverarbeitung
output			oNEW_COORD;	//zur internen weiterverarbeitung
output	[11:0]	oX_COORD; //Stift X-Koordinaten 0..4096
output	[11:0]	oY_COORD; //Stift Y-Koordinaten 0..4096			
//=============================================================================
// REG/WIRE declarations
//=============================================================================
reg				d1_PENIRQ_n;
reg				d2_PENIRQ_n;
wire			touch_irq;
reg		[15:0]	dclk_cnt;
wire			dclk;
reg				transmit_en;
reg		[6:0]	spi_ctrl_cnt;
wire			oADC_CS;
reg				mcs;
reg				mdclk;
wire	[7:0]	x_config_reg;
wire	[7:0]	y_config_reg;
wire	[7:0]	ctrl_reg;
reg		[7:0]	mdata_in;
reg				y_coordinate_config;
wire			eof_transmition;	
reg		[5:0]	bit_cnt;	
reg				madc_out;	        //Rohdaten aus dem ADC
reg		[11:0]	mx_coordinate;
reg		[11:0]	my_coordinate;	
reg		[11:0]	oX_COORD;
reg		[11:0]	oY_COORD;
wire			rd_coord_strob;
reg				oNEW_COORD;
reg		[5:0]	irq_cnt;
reg		[15:0]	clk_cnt;
//=============================================================================
// Structural coding
//=============================================================================
assign	x_config_reg = 8'h92; //"10010010" ADC-Konfiguration für l/r Kanal
assign	y_config_reg = 8'hd2; //"11010010" ADC-Konfiguration für l/r Kanal

always@(posedge iCLK or negedge iRST_n)
	begin
		if (!iRST_n)
			madc_out <= 0;
		else
			madc_out <= iADC_DOUT;
	end		

///////////////   pen irq detect  //////// 
always@(posedge iCLK or negedge iRST_n)
	begin	
		if (!iRST_n)
			begin
				d1_PENIRQ_n	<= 0;
				d2_PENIRQ_n	<= 0;
			end
		else
			begin
				d1_PENIRQ_n	<= iADC_PENIRQ_n;	
				d2_PENIRQ_n	<= d1_PENIRQ_n; //d2 erhält den Zustand 1 Takt später als d1
			end
	end
//bei Flankenwechsel '1' zu '0' an iADC_PENIRQ_n wird touch_irq '1'
assign		touch_irq = d2_PENIRQ_n & ~d1_PENIRQ_n; 
assign		oTOUCH_IRQ = touch_irq;

//Wenn touch_irq == '1', startet die Übertragung mit transmit_en <= '1'
//Wenn eof_transmition == '1' UND der Stift nicht mehr den Touchscreen berührt
//beende Übertragung mit transmit_en <= '0'
always@(posedge iCLK or negedge iRST_n)
	begin
		if (!iRST_n)
			transmit_en <= 0;
		else if (eof_transmition&&iADC_PENIRQ_n) 
			transmit_en <= 0;	
		else if (touch_irq)
			transmit_en <= 1;
	end			

//Zähle dclk_cnt fortwährend von 0 bis 25000
always@(posedge iCLK or negedge iRST_n)
	begin
		if (!iRST_n)
			dclk_cnt <= 0;
		else if (transmit_en) 
			begin
				if (dclk_cnt == ADC_DCLK_CNT) //25000
					dclk_cnt <= 0;
				else
					dclk_cnt <= dclk_cnt + 1;		
			end
		else
			dclk_cnt <= 0;
	end			

//dclk ist bei 0..24999 Low, bei 25000 High	(später wird der Takt noch halbiert)
assign	dclk =   (dclk_cnt == ADC_DCLK_CNT)? 1 : 0;		

//Zähle spi_ctrl_cnt fortwährend von 0 bis 65 für aktuelle Übertragung
always@(posedge iCLK or negedge iRST_n)
	begin
		if (!iRST_n)
			spi_ctrl_cnt <= 0;
		else if (dclk)	
			begin
				if (spi_ctrl_cnt == 65)
					spi_ctrl_cnt <= 0;						
				else
					spi_ctrl_cnt <= spi_ctrl_cnt + 1;		
			end
	end				

always@(posedge iCLK or negedge iRST_n)
  begin
	if (!iRST_n)
		begin
			mcs 	<= 1;
			mdclk	<= 0;
			mdata_in <= 0;
			y_coordinate_config <= 0; //Auswahl x oder y (0 = x)
			mx_coordinate <= 0; //Temporäre aktuelle Koordinaten
			my_coordinate <= 0;
		end
	else if (transmit_en)
		begin
			if (dclk)
				begin
					if (spi_ctrl_cnt == 0)
						begin
							mcs 	<= 0; //Chip-Select
							mdata_in <= ctrl_reg; //Enthält ADC-Konfiguration
						end	
					else if (spi_ctrl_cnt == 49)
						begin
							mdclk	<= 0;
							y_coordinate_config <= ~y_coordinate_config;//invertieren
							
							if (y_coordinate_config)
								mcs 	<= 1; //CS = 1 bei Y
							else
								mcs 	<= 0; //CS = 0 bei X
						end
					else if (spi_ctrl_cnt != 0)
						//invertieren	außer bei 0 & 49 (bei 49 mdclk = 0)
						//d.h ADC Takt erhält ca. 12,5kHz
						mdclk	<= ~mdclk;
								 			
					if (mdclk)
						//schiften der Konfiguration, (Ausgabe des MSB)
						mdata_in <= {mdata_in[6:0],1'b0};
					if (!mdclk)	//bei '0'
						begin
							if(rd_coord_strob)//lesen der Koordinaten vom ADC mit shiften
								begin
									if(y_coordinate_config)
										my_coordinate <= {my_coordinate[10:0],madc_out};
									else
										mx_coordinate <= {mx_coordinate[10:0],madc_out};	
								end
						end		
				end				
		end
  end

assign	oADC_CS  = mcs; //Chip-Select
assign	oADC_DIN = 	mdata_in[7]; //Ausgabe an ADC
assign	oADC_DCLK = mdclk; //Taktausgebe

//ctrl_reg enthält aktuelle ADC-Konfiguration, 
//y bei y_coordinate_config=1 und x bei y_coordinate_config=0
assign	ctrl_reg = y_coordinate_config ? y_config_reg : x_config_reg;
 
//Y-Konfig UND spi_ctrl_cnt=49 UND dclk = Ende der aktuellen Übertragung 
assign	eof_transmition = (y_coordinate_config & (spi_ctrl_cnt == 49) & dclk);

//rd_coord_strob = 1, wenn spi_ctrl_cnt zwischen 19 und 41, sonst 0
assign	rd_coord_strob = ((spi_ctrl_cnt>=19)&&(spi_ctrl_cnt<=41)) ? 1 : 0;

//Weise aktuelle Koordinaten nach der erfolgtreichen Übertragung dem Ausgang zu
always@(posedge iCLK or negedge iRST_n)
	begin
		if (!iRST_n)
			begin
				oX_COORD <= 0;	
				oY_COORD <= 0;
			end
		else if (eof_transmition&&(my_coordinate!=0))
			begin			
				oX_COORD <= mx_coordinate;	
				oY_COORD <= my_coordinate;
			end	
	end

//Melde mit oNEW_COORD='1' neue aktuelle Koordinaten
always@(posedge iCLK or negedge iRST_n)
	begin
		if (!iRST_n)
			oNEW_COORD <= 0;
		else if (eof_transmition&&(my_coordinate!=0))
			oNEW_COORD <= 1;
		else
			oNEW_COORD <= 0;		
	end

endmodule