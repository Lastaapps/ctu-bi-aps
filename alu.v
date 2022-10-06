/**
  * @param i_d0, i_d1 - registers to sum
  * @param k_ctl - mode control
  *   00 - and
  *   01 - sub
  *   10 - xor
  * @return o_data - operation result
  * @return o_zero - 1 if the operation result is 0
  */
module m_alu(input [31:0] i_d0, i_d1, input [1:0] i_ctl, output reg [31:0] o_data, output o_zero);
  wire [31:0] add, sub, x_or;
  assign add = i_d0 + i_d1;
  assign sub = i_d0 - i_d1;
  assign x_or = i_d0 ^ i_d1;
  assign or_zero = o_data == 0;

  always @(*) begin
    case (i_ctl)
      0: o_data <= add;
      1: o_data <= sub;
      2: o_data <= x_or;
      default: o_data <= 0;
    endcase
  end
endmodule

