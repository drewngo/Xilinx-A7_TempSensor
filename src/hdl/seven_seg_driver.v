module seven_seg_driver(
  input clk,
  input rst,
  input [15:0] data_in,
  output reg [7:0] an,
  output reg [6:0] seg
);

  // ------
  reg [15:0] clk_div;      // 100 MHz clock from Nexys A7 -> 1525.8Hz
  reg [1:0] digit_select;
  reg [3:0] BCD_digit;
  
  // ------
  always @(posedge clk or negedge rst) begin

    if (!rst) begin
      clk_div       <= 16'd0;
      digit_select <= 2'b00;

    end else begin
      clk_div <= clk_div + 1'b1;
      
      if (clk_div == 16'hFFFF) begin
        digit_select <= digit_select + 1'b1;
      end
    end
    
  end
  
  // ------
  always @(*) begin
    an = 8'b1111_1111;
    BCD_digit = 4'd0;
    
    case (digit_select)
      2'b00: begin
        an = 8'b1111_1110;
        BCD_digit = data_in[3:0];
      end
      2'b01: begin
        an = 8'b1111_1101;
        BCD_digit = data_in[7:4];
      end
      2'b10: begin
        an = 8'b1111_1011;
        BCD_digit = data_in[11:8];
      end
      2'b11: begin
        an = 8'b1111_0111;
        BCD_digit = data_in[15:12];
      end
    endcase
  end
  
  // ------
  always @(*) begin
    seg = 7'b111_1111;
  
    case (BCD_digit)
      4'd0:    seg = 7'b000_0001;
      4'd1:    seg = 7'b100_1111;
      4'd2:    seg = 7'b001_0010;
      4'd3:    seg = 7'b000_0110;
      4'd4:    seg = 7'b100_1100;
      4'd5:    seg = 7'b010_0100;
      4'd6:    seg = 7'b010_0000;
      4'd7:    seg = 7'b000_1111;
      4'd8:    seg = 7'b000_0000;
      4'd9:    seg = 7'b000_1100;
    endcase
  end
  
endmodule