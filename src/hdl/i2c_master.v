module i2c_master(
    input         clk,
    input         rst,
    output [15:0] data,
    output        SCL,
    inout         SDA
);
    
//--------------------------------------------------------------------------

    localparam STATE_IDLE        = 4'd0,
               STATE_START       = 4'd1,
               STATE_ADDR_WR     = 4'd2, // ADT7420 ~ 7'h4B , Write ~ 1'b0
               STATE_ACK_1       = 4'd3,
               STATE_PTR         = 4'd4,
               STATE_ACK_2       = 4'd5,
               STATE_RESTART     = 4'd6,
               STATE_ADDR_RD     = 4'd7,
               STATE_ACK_3       = 4'd8,
               STATE_READ_MSB    = 4'd9,
               STATE_MASTER_ACK  = 4'd10,
               STATE_READ_LSB    = 4'd11,
               STATE_MASTER_NACK = 4'd12,
               STATE_STOP        = 4'd13;
    
//--------------------------------------------------------------------------

    reg [3:0] current_state;
    reg [3:0] next_state;

//--------------------------------------------------------------------------

    reg [9:0] clk_counter;
    reg [2:0] addr_bit_counter;
    reg       i2c_clk;

    wire i2c_tick = (clk_counter == 10'd499);

//--------------------------------------------------------------------------

    // 100 kHz clock for i2c
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
                    STATE_START, 
                    STATE_RESTART, 
                    STATE_ACK_1,
                    STATE_ACK_2,
                    STATE_ACK_3,
                    STATE_MASTER_ACK:
                        addr_bit_counter <= 3'd7;

                    STATE_ADDR_WR,
                    STATE_PTR,
                    STATE_ADDR_RD,
                    STATE_READ_MSB,
                    STATE_READ_LSB:
                        addr_bit_counter <= addr_bit_counter - 1'b1;

                    default: addr_bit_counter <= addr_bit_counter;
                endcase
            end
        end

    end

//--------------------------------------------------------------------------

    // SCL AND SDA BIZ
    // open drain bus
    assign SCL = (i2c_clk) ? 1'bz : 1'b0;

    // SDA high on write, SDA low on read (impendance)
    wire sda_mode = (
        current_state == STATE_IDLE || 
        current_state == STATE_START ||
        current_state == STATE_ADDR_WR ||
        current_state == STATE_PTR ||
        current_state == STATE_ADDR_RD ||
        current_state == STATE_MASTER_ACK
        ) ? 1'b1 : 1'b0;
    
    reg sda_out;

    // tri-state buffer
    assign SDA = (sda_mode) ? ((sda_out) ? 1'bz : 1'b0) : 1'bz;

//--------------------------------------------------------------------------

    // state register
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            current_state <= STATE_IDLE;
        end
        else if (i2c_tick) begin
            current_state <= next_state;
        end
    end

//--------------------------------------------------------------------------

    // state traversal
    always @(*) begin
        next_state = current_state;

        case (current_state)
            STATE_IDLE        : begin
                next_state = STATE_START;
            end
            STATE_START       : begin
                next_state = STATE_ADDR_WR;
            end
            STATE_ADDR_WR     : begin
                if (i2c_tick && addr_bit_counter == 3'd0) begin
                    next_state = STATE_ACK_1;
                end
                else begin
                    next_state = STATE_ADDR_WR;
                end
            end
            STATE_ACK_1       : begin
                if (i2c_tick && i2c_clk) begin
                    next_state = STATE_PTR;
                end
                else begin
                    next_state = STATE_ACK_1;
                end
            end
            STATE_PTR         : begin
                if (i2c_tick && addr_bit_counter == 3'd0) begin
                    next_state = STATE_ACK_2;
                end
                else begin
                    next_state = STATE_PTR;
                end
            end
            STATE_ACK_2       : begin
                if (i2c_tick && i2c_clk) begin
                    next_state = STATE_RESTART;
                end
                else begin
                    next_state = STATE_ACK_2;
                end
            end
            STATE_RESTART     : begin
                next_state = STATE_ADDR_RD;
            end
            STATE_ADDR_RD     : begin
                if (i2c_tick && addr_bit_counter == 3'd0) begin
                    next_state = STATE_ACK_3;
                end
                else begin
                    next_state = STATE_ADDR_RD;
                end
            end
            STATE_ACK_3       : begin
                if (i2c_tick && i2c_clk) begin
                    next_state = STATE_READ_MSB;
                end
                else begin
                    next_state = STATE_ACK_3;
                end
            end
            STATE_READ_MSB    : begin
                if (i2c_tick && addr_bit_counter == 3'd0) begin
                    next_state = STATE_MASTER_ACK;
                end
                else begin
                    next_state = STATE_READ_MSB;
                end
            end
            STATE_MASTER_ACK  : begin
                if (i2c_tick && i2c_clk) begin
                    next_state = STATE_READ_LSB;
                end
                else begin
                    next_state = STATE_MASTER_ACK;
                end
            end
            STATE_READ_LSB    : begin
                if (i2c_tick && addr_bit_counter == 3'd0) begin
                    next_state = STATE_MASTER_NACK;
                end
                else begin
                    next_state = STATE_READ_LSB;
                end
            end
            STATE_MASTER_NACK : begin
                if (i2c_tick && i2c_clk) begin
                    next_state = STATE_STOP;
                end
                else begin
                    next_state = STATE_MASTER_NACK;
                end
            end
            STATE_STOP        : begin
                next_state = STATE_IDLE;
            end
        endcase
    end

//--------------------------------------------------------------------------

endmodule
