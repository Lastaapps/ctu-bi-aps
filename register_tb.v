
module m_registers_test();
  reg [4:0] a0, a1, a2;
  reg [31:0] data;
  reg clk, we;
  wire [31:0] out0, out1, reference;

  m_register u_component(a0, a1, a2, clk, we, data, out0, out1);

  initial begin
    a0 = 14;
    a1 = 21;
    a2 = 14;
    clk = 0;
    we = 0;
    data = 69;
    #16 
    clk = 1;
    #16
    clk = 0;
    #16
    clk = 1;
    we = 1;
    #16
    clk = 0;
    #16
    a2 = 21;
    data = 42;
    #16
    clk = 1;
    we = 1;
  end

  always @(*) #1 $display(
    "reg %d> out0: %d, out1: %d, a0: %d, a1: %d, a2: %d, clk: %b, we: %b, data: %d",
    $time, out0, out1, a0, a1, a2, clk, we, data
  );

endmodule

module m_registers_zero_test();
  reg [4:0] a0, a1, a2;
  reg [31:0] data;
  reg clk, we;
  wire [31:0] out0, out1, reference;

  m_register u_component(a0, a1, a2, clk, we, data, out0, out1);

  initial begin
    a0 = 0;
    a1 = 0;
    a2 = 0;
    clk = 0;
    we = 1;
    data = 420;
    #16 
    clk = 1;
    #16 
    clk = 0;
    #16 
    clk = 1;
  end

  always @(out0) #1 $display( "re0 %d> out: %d, clk: %b", $time, out0, clk);
endmodule

