
module m_alu_test();
  
  reg [31:0] a0, a1;
  reg [2:1] cli;
  wire [31:0] out;
  wire zero;

  m_alu u_alu(a0, a1, cli, out, zero);

  initial begin
    // add
    cli = 'b00;
    a0 = 42;
    a1 = 69;
    #1 $display( "alu %d> out: %d, zero: %b, cli: %d, a0: %d, a1: %d", $time, out, zero, cli, a0, a1);
    #1
    a0 = 42;
    a1 = -69;
    #1 $display( "alu %d> out: %d, zero: %b, cli: %d, a0: %d, a1: %d", $time, out, zero, cli, a0, a1);
    #1

    // sub
    cli = 'b01;
    a0 = 42;
    a1 = -69;
    #1 $display( "alu %d> out: %d, zero: %b, cli: %d, a0: %d, a1: %d", $time, out, zero, cli, a0, a1);
    #1
    a0 = 42;
    a1 = 69;
    #1 $display( "alu %d> out: %d, zero: %b, cli: %d, a0: %d, a1: %d", $time, out, zero, cli, a0, a1);

    // xor
    cli = 'b10;
    a0 = 'b101010101;
    a1 = 'b010101010;
    #1 $display( "alu %d> out: %d, zero: %b, cli: %d, a0: %d, a1: %d", $time, out, zero, cli, a0, a1);
    #1
    a0 = 'b101010101;
    a1 = 'b101010101;
    #1 $display( "alu %d> out: %d, zero: %b, cli: %d, a0: %d, a1: %d", $time, out, zero, cli, a0, a1);

  end
endmodule

