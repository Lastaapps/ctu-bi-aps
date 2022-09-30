
module m_send(input i_clk, input [31:0] i_data, output reg [31:0] o_out);
  always @(posedge i_clk) begin
    o_out <= i_data;
  end
endmodule

