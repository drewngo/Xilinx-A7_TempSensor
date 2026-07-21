module tb;

  reg clk = 0;
  reg rst;
  reg [15:0] data_in;

  wire [7:0] an;
  wire [6:0] seg;

  always #5 clk = ~clk;

  seven_seg_driver DUT (
    .clk    (clk),
    .rst    (rst),
    .data_in(data_in),
    .an     (an),
    .seg    (seg)
  );

  initial begin
    rst = 0;
    data_in = 16'h0000;

    #20;
    rst = 1;

    data_in = 16'h4321;
    #3_000_000;

    data_in = 16'h1234;
    #3_000_000;

    $finish;

  end

endmodule
