/**
  * @param i_ar0, i_ar1 first and second address to read a register from
  * @param i_clk - clock on which writes are done
  * @param i_we - write enabled
  * @return o_a0, o_a1 - content of registers referenced by i_ar0 and i_ar1
  */
module m_register(input [4:0] i_ar0, i_ar1, i_aw, input i_clk, i_we, input [31:0] i_wd, output reg [31:0] o_a0, o_a1);
  reg [31:0] matrix [31:0];

  always @(*) begin
    if (i_ar0 == 0)
      o_a0 <= 0;
    else
      o_a0 <= matrix[i_ar0];
  end
  always @(*) begin
    if (i_ar1 == 0)
      o_a1 <= 0;
    else
      o_a1 <= matrix[i_ar1];
  end

  always @(posedge i_clk) begin
    if (i_we) begin
      matrix[i_aw] <= i_wd;
    end
  end
endmodule

