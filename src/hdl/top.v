`timescale 1ns / 1ps

module top(
  input clk,
  input rst,
  output [7:0] an,
  output [6:0] seg
);

  wire [15:0] test = 16'h2605;
  
  seven_seg_driver display(
    .clk(clk),
    .rst(rst),
    .data_in(test),
    .an(an),
    .seg(seg)
  );


endmodule
