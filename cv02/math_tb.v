
module m_equeal_test();
  reg [31:0] a0, a1;
  wire [31:0] out;

  m_equal u_component(a0, a1, out);

  initial begin
    a0 = 0;
    #20
    a0 = ~a0;
  end

  always @(out) #1 $display( "exp %d> out: %b, a0: %b", $time, out[0], a0[0]);

endmodule

module m_expand_test();
  reg [15:0] a0;
  wire [31:0] out;

  m_expand u_component(a0, out);

  initial begin
    a0 = 0;
    #20
    a0 = ~a0;
  end

  always @(out) #1 $display( "exp %d> out: %b, a0: %b", $time, out[0], a0[0]);

endmodule

