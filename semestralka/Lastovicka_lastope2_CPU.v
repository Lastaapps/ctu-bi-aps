`default_nettype none
module processor( input i_clk, _reset,
                  output [31:0] o_PC,
                  input  [31:0] i_instruction,
                  output o_WE,
                  output [31:0] o_address_to_mem,
                  output [31:0] o_data_to_mem,
                  input  [31:0] i_data_from_mem
                );


endmodule


/** Registers
  * @param i_ar0, i_ar1 first and second address to read a register from
  * @param i_clk - clock on which writes are done
  * @param i_we - write enabled
  * @return o_a0, o_a1 - content of registers referenced by i_ar0 and i_ar1
  */
module m_register(input [4:0] i_ar0, i_ar1, i_aw, input i_clk, i_we, input [31:0] i_wd, output reg [31:0] o_a0, o_a1);
  reg [31:0] matrix [31:0];

  always @(*) begin
    if (i_ar0 == 0) o_a0 <= 0;
    else o_a0 <= matrix[i_ar0];
  end
  always @(*) begin
    if (i_ar1 == 0) o_a1 <= 0;
    else o_a1 <= matrix[i_ar1];
  end

  always @(posedge i_clk) begin
    if (i_we) matrix[i_aw] <= i_wd;
    else ;
  end
endmodule


/** Operation codes decoder
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


/** ALU
  * @param i_d0, i_d1 - registers to sum
  * @param k_ctl - mode control
  *   00 - and
  *   01 - sub
  *   10 - xor
  * @return o_data - operation result
  * @return o_zero - 1 if the operation result is 0
  */
module m_alu(input [31:0] i_d0, i_d1, input [1:0] i_ctl, output reg [31:0] o_data, output o_zero);
  wire [31:0] add, sub, x_or;
  assign add = i_d0 + i_d1;
  assign sub = i_d0 - i_d1;
  assign x_or = i_d0 ^ i_d1;
  assign or_zero = o_data == 0;

  always @(*) begin
    case (i_ctl)
      0: o_data <= add;
      1: o_data <= sub;
      2: o_data <= x_or;
      default: o_data <= 0;
    endcase
  end
endmodule


// Math library
module m_adder(input [31:0] i_a, i_b, input i_c0, output [31:0] o_sum, output o_c32);
  assign {o_c32, o_sum} = i_a + i_b + i_c0;
endmodule

module m_multiply4(input [31:0] i_d0, output [31:0] o_out);
  wire [1:0] trash;
  assign {trash, o_out} = 4 * i_d0;
endmodule

module m_equal(input [31:0] i_d0, i_d1, output o_out);
  assign o_out = i_d0 == i_d1;
endmodule

module m_expand(input [15:0] i_d0, output [31:0] o_out);
  assign o_out = {{16{i_d0[15]}}, i_d0};
endmodule

// Multiplexors
module m_multiplexor2_1(input [31:0] i_d0, i_d1, input i_select, output [31:0] o_out);
  assign o_out = i_select ? i_d1 : i_d0;
endmodule

module m_multiplexor4_1(input [31:0] i_d0, i_d1, i_d2, i_d3,
  input [1:0] i_select, output reg [31:0] o_out);

  always @(*)
    case (i_select)
      0: o_out <= i_d0;
      1: o_out <= i_d1;
      2: o_out <= i_d2;
      default: o_out <= i_d3;
    endcase
endmodule


// Register utilities
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



`default_nettype wire 
