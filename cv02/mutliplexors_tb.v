
module m_multiplexor2_1_test();
  reg [31:0] a0, a1;
  reg select;
  wire [31:0] out;

  m_multiplexor2_1 u_component(a0, a1, select, out);

  initial begin
    a0 = 0;
    a1 = ~a0;
    select = 0;
  end

  always #10 a0 = ~a0;
  always #10 a1 = ~a1;
  always #40 select = ~select;

  always @(out) #1 $display( "mp2 %d> out: %b, a0: %b, a1: %b", $time, out[0], a0[0], a1[0]);


endmodule

module m_multiplexor4_1_test();
  reg [31:0] a0, a1, a2, a3;
  reg [1:0] select;
  wire [31:0] out;

  m_multiplexor4_1 u_component(a0, a1, a2, a3, select, out);

  initial begin
    a0=0;
    a1=~a0;
    a2='h FFFF0000;
    a3=~a2;
    select=0;
  end

  always #10 a0 = ~a0;
  always #10 a1 = ~a1;
  always #10 a2 = ~a2;
  always #10 a3 = ~a3;
  always #40 select += 1;

  always @(out) #1 $display( "mp4 %d> out: %b, a0: %b, a1: %b, a2: %b, a3: %b", $time, out[0], a0[0] ,a1[0], a2[0], a3[0]);

endmodule





