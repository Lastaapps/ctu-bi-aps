
module m_send(input i_clk, input [31:0] i_data, output reg [31:0] o_out);
  always @(posedge i_clk) begin
    o_out <= i_data;
  end
endmodule

module m_reset(input i_clk, i_reset, input [31:0] i_data, output reg [31:0] o_out);
  always @(posedge i_clk) begin
    if (i_reset) o_out <= 0;
    else o_out <= i_data;
  end
endmodule

