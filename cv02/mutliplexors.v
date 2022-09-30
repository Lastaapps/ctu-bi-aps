
module m_multiplexor2_1(input [31:0] i_d0, i_d1, input i_select, output [31:0] o_out);
  assign o_out = i_select ? i_d1 : i_d0;
endmodule

module m_multiplexor4_1(input [31:0] i_d0, i_d1, i_d2, i_d3,
  input [1:0] i_select, output reg [31:0] o_out);

  always @(*)
    case (i_select)
      0: o_out = i_d0;
      1: o_out = i_d1;
      2: o_out = i_d2;
      default: o_out = i_d3;
    endcase

endmodule
