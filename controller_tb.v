
module m_controller_test();
  reg [2:0] opt = 0;
  wire [1:0] aluCtl;
  wire aluSrc, regWr, memWr, br;

  m_controller u_component(opt, aluCtl, aluSrc, regWr, memWr, br);

  initial begin
    opt = 0;
  end

  always @(*) #4 opt <= opt + 1;

  always @(*) #1 $display(
    "ctl %d> opt: %d, aluCtl: %d, aluSrc: %d, regWr: %d, memWr: %d, br: %b",
    $time, opt, aluCtl, aluSrc, regWr, memWr, br
  );
endmodule
