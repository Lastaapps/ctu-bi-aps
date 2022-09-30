
module m_test_init();

  initial begin
    $dumpfile("test_out");
    $dumpvars;
    #1 // for printing
    #160 $finish;
  end
endmodule
