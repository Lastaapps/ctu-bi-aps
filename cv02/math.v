module adder(input [31:0] i_a, i_b, input i_c0, output [31:0] o_sum, output o_c32);

  assign {o_c32, o_sum} = i_a + i_b + i_c0;

endmodule

module multiply4(input [31:0] i_d0, output [31:0] o_out);
  wire [1:0] trash;
  assign {trash, o_out} = 4 * i_d0;
endmodule

module equal(input [31:0] i_d0, i_d1, output o_out);
  assign o_out = i_d0 == i_d1;
endmodule

module expand(input [15:0] i_d0, output [31:0] o_out);
  assign o_out = {{16{i_d0[15]}}, i_d0};
endmodule

