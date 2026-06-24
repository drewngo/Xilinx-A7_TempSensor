module i2c_master(
  input clk,
  input rst,
  output [15:0] data,
  output SCL,
  inout SDA
);
  
  // ------
  localparam STATE_IDLE = ;
  localparam STATE_START = ;
  localparam STATE_ADDR_WR = ;
  localparam STATE_ACK_1 = ;
  localparam STATE_PTR = ;
  localparam STATE_ACK_2 = ;
  localparam STATE_RESTART = ;
  localparam STATE_ADDR_RD = ;
  localparam STATE_ACK_3 = ;
  localparam STATE_READ_MSB = ;
  localparam STATE_MASTER_ACK = ;
  localparam STATE_READ_LSB = ;
  localparam STATE_MASTER_NACK = ;
  localparam STATE_STOP = ;

  // ------
  reg [3:0] current_state;
  reg [3:0] next_state;

  // ------
  reg [9:0] clk_counter;
  reg [2:0] addr_bit_counter;
  reg i2c_clk;

  // ------ 100 kHz clock for i2c
  wire i2c_tick = (clk_counter == 10'd499);

  always @(posedge clk or negedge rst) begin
    
    if (!rst) begin
      clk_counter      <= 10'b0;
      i2c_clk          <= 1'b1;
      addr_bit_counter <= 3'd7;
    end

    else begin
    
      // i2c clock
      if (clk_counter == 10'd499) begin
        clk_counter <= 10'b0;
        i2c_clk     <= ~i2c_clk;
      end
      else
        clk_counter <= clk_counter + 1'b1;
      
      // i2c tick for address bit counter
      if (i2c_tick) begin
        case (current_state)
          STATE_START, STATE_RESTART:   addr_bit_counter <= 3'd7;
          STATE_ADDR_WR, STATE_ADDR_RD: addr_bit_counter <= addr_bit_counter - 1'b1;

          default: addr_bit_counter <= addr_bit_counter;
        endcase
      end
    
    end

  end

  // ------ open drain bus
  assign SCL = (i2c_clk) ? 1'bz : 1'b0;


  // ------
  always @(*) begin
    next_state = current_state;

    case (current_state)
      STATE_IDLE: begin
        next_state = STATE_START;
      end

      STATE_START: begin
        next_state = STATE_ADDR_WR;
      end

      STATE_ADDR_WR: begin
        if (i2c_tick && addr_bit_counter == 3'd0) begin
          next_state = STATE_ACK_1;
        end
        else begin
          next_state = STATE_ADDR_WR;
        end
      end
    endcase
  end

endmodule