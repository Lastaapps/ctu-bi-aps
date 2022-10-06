/**
  * @param i_opt - operation code
  * @return o_aluCtl - controlls ALU
  * @return o_aluSrc - chooses between register(0) and address(1) ALU intput
  * @return o_regWrite - enabled write into registers
  * @return o_mem - memori write enable
  * @return o_branch - branching is happening
  */
module m_controller(input [2:0] i_opt, output [1:0] o_aluCtl, output o_aluSrc, o_regWr, o_memWr, o_br);
  reg [5:0] out;
  assign {o_aluCtl, o_aluSrc, o_regWr, o_memWr, o_br} = out;

  always @(*)
    case (i_opt)
      //opt          aCtl aSrc regWr memWr branch
      'b000: out <= 'b00_____0_____1_____0______0;
      'b001: out <= 'b00_____1_____1_____0______0;
      'b010: out <= 'b01_____0_____1_____0______0;
      'b011: out <= 'b00_____1_____1_____0______0;
      'b100: out <= 'b00_____1_____0_____1______0;
      'b101: out <= 'b01_____0_____0_____0______1;
      default: out <= 0;
    endcase
endmodule
