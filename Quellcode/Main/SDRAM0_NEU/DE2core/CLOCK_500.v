// Initialisierungsprogramm für den Audiocodec WM8731 auf dem DE2 Board
// Angepasst als Komponente fur das Modul DE2_i2sound.vhd

`define rom_size 6'd8 //6bits dezimal mit Inhalt "001000"

module CLOCK_500(CLOCK,
	             CLOCK_500,
	             DATA,
	             ENDT,
	             RESET,
	             VOL_OUT,
	             VOL_IN,
	             MIC,
	             SR,
	             GO,
	             CLOCK_2);
	input  CLOCK;		 //50MHz
	input  ENDT;		 //aus I2C-Modul
	input  RESET;		
	input  [6:0]VOL_OUT; //Ausgangspegel
	input  [4:0]VOL_IN;  //Eingangsempfindlichkeit
	input  [2:0]SR;      //SampleRate Input
	input  MIC;          //Auswahl Mic / Line In
	output CLOCK_500;	 //to I2C
	output [23:0]DATA;   //to I2C
	output GO;			 //to I2C
	output CLOCK_2;		 //Audio-XCK

reg  [10:0]COUNTER_500;  //register COUNTER_500 mit 11bits increment mit 50MHz

wire  CLOCK_500=COUNTER_500[9];	//CLOCK_500 taktet mit 48,828 kHz
wire  CLOCK_2=COUNTER_500[1];	//CLOCK_2 taktet mit 12,5 MHz

reg  [15:0]ROM[`rom_size:0];
reg  [15:0]DATA_A;
reg  [5:0]address;
wire [23:0]DATA={8'h34,DATA_A};
	
wire  GO =((address <= `rom_size) && (ENDT==1))? COUNTER_500[10]:1;
always @(negedge RESET or posedge ENDT) begin
	if (!RESET) address=0;
	else 
	if (address <= `rom_size) address=address+1;
end

always @(posedge ENDT) begin
// Initialisierungs ROM:
	ROM[0]= 16'h0c00;	                 //power down (alles ist an)
	ROM[1]= 16'h0e5b;	                 //DSP, 24bit, LRP-2nd, master
	ROM[2]= {12'h081,1'b0,MIC,2'b0};     //Auswahl Mic / Line In
	ROM[3]= {8'h10,3'b0,SR[2:0],2'b0};   //Einstellung der Abtastrate
	ROM[4]= {8'h00,3'b0,VOL_IN[4:0]};	 //left linein vol (variabel durch KEY[0])
	ROM[5]= {8'h02,3'b0,VOL_IN[4:0]};	 //right linein vol (variabel durch KEY[0])	
	ROM[6]= {8'h04,1'b0,VOL_OUT[6:0]};	 //sound out volume (variabel durch KEY[0])
	ROM[7]= {8'h06,1'b0,VOL_OUT[6:0]};	 //sound out volume (variabel durch KEY[0])
	ROM[`rom_size]= 16'h1201;			 //device ist aktiv
	DATA_A=ROM[address];
end

always @(posedge CLOCK ) begin
	COUNTER_500=COUNTER_500+1;
end
endmodule