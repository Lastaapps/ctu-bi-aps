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
  */
module m_controller(input [31:0] i_inst,
                    output [2:0] o_imm_ctl,
                    output o_alu_src, // 0 - register, 1 - imm
                    output [3:0] o_alu_ctl,
                    output o_mem_write,
                    output o_mem_to_reg,
                    output o_reg_write,
                    output o_imm_to_reg,
                    output o_br_jalr,
                    output o_br_jal,
                    output o_br_beq,
                    output o_br_bne,
                    output o_br_blt,
                    output o_aui);

  wire s_add  = 'b000_0_0000_0010_00000_0; // add
  wire s_addi = 'b001_1_0000_0010_00000_0; // add immediate
  wire s_and  = 'b000_0_0010_0010_00000_0; // and
  wire s_sub  = 'b000_0_0001_0010_00000_0; // substitute
  wire s_slt  = 'b000_0_0011_0010_00000_0; // compare, a < b -> 1
  wire s_div  = 'b000_0_0100_0010_00000_0; // divide
  wire s_rem  = 'b000_0_0101_0010_00000_0; // modulo

  wire s_beq  = 'b011_1_0001_0000_00100_0; // branch equal
  wire s_bne  = 'b011_1_0001_0000_00010_0; // branch not equal
  wire s_blt  = 'b011_1_0000_0000_00001_0; // jump if a < b

  wire s_lw   = 'b001_1_0000_0100_00000_0; // load word
  wire s_sw   = 'b010_1_0000_1000_00000_0; // save word
  wire s_lui  = 'b100_1_0000_0001_00000_0; // load immediate

  wire s_jal  = 'b101_0_0000_0000_01000_0; // jump relative to PC
  wire s_jalr = 'b001_1_0000_0000_10000_0; // jump relative to rd
  wire s_aui  = 'b100_0_0000_0000_00000_1; // rd <- r1 + PC

  wire s_sll  = 'b000_0_0110_0010_00000_0; // logical left shift
  wire s_srl  = 'b000_0_0111_0010_00000_0; // logical left shift
  wire s_sra  = 'b000_0_1000_0010_00000_0; // arithmetic left shift

  assign {
    o_imm_ctl, o_alu_src, o_alu_ctl,
    o_mem_write, o_mem_to_reg, o_reg_write, o_imm_to_reg,
    o_br_jalr, o_br_jal, o_br_beq, o_br_bne, o_br_blt, o_aui
    } = 
      i_inst == 'b0000000_?????_?????_000_?????_0110011 ? s_add  : // add
      i_inst == 'b???????_?????_?????_000_?????_0010011 ? s_addi : // addi
      i_inst == 'b0000000_?????_?????_111_?????_0110011 ? s_and  : // and
      i_inst == 'b0100000_?????_?????_000_?????_0110011 ? s_sub  : // sub
      i_inst == 'b0000000_?????_?????_010_?????_0110011 ? s_slt  : // slt
      i_inst == 'b0000001_?????_?????_100_?????_0110011 ? s_div  : // div
      i_inst == 'b0000001_?????_?????_110_?????_0110011 ? s_rem  : // rem
      i_inst == 'b0000000_?????_?????_001_?????_0110011 ? s_sll  : // sll
      i_inst == 'b0000000_?????_?????_101_?????_0110011 ? s_srl  : // srl
      i_inst == 'b0100000_?????_?????_101_?????_0110011 ? s_sra  : // sra

      i_inst == 'b???????_?????_?????_000_?????_1100011 ? s_beq  : // beq
      i_inst == 'b???????_?????_?????_001_?????_1100011 ? s_bne  : // bne
      i_inst == 'b???????_?????_?????_100_?????_1100011 ? s_blt  : // blt

      i_inst == 'b???????_?????_?????_010_?????_0000011 ? s_lw   : // lw
      i_inst == 'b???????_?????_?????_010_?????_0100011 ? s_sw   : // sw
      i_inst == 'b???????_?????_?????_???_?????_0110111 ? s_lui  : // lui

      i_inst == 'b???????_?????_?????_???_?????_1101111 ? s_jal  : // jal
      i_inst == 'b???????_?????_?????_000_?????_1100111 ? s_jalr : // jalr
      i_inst == 'b???????_?????_?????_???_?????_0010111 ? s_aui  : // auipc
      0;
endmodule

/* Decodes data stored in an instruction
* R - 000
* I - 001
* S - 010
* B - 011
* U - 100
* J - 101
*/
module m_imm_decoder(input [31:0] i_data, input [1:0] i_imm_ctl, output [31:0] o_data);
  wire [31:0] r, i, s, b, u, j;
  m_imm_dec_R u_r(i_data, r);
  m_imm_dec_I u_i(i_data, i);
  m_imm_dec_S u_s(i_data, s);
  m_imm_dec_B u_b(i_data, b);
  m_imm_dec_U u_u(i_data, u);
  m_imm_dec_J u_j(i_data, j);
  assign o_data =
    i_imm_ctl == 0 ? r : 
    i_imm_ctl == 1 ? i : 
    i_imm_ctl == 2 ? s : 
    i_imm_ctl == 3 ? b : 
    i_imm_ctl == 4 ? u : 
    i_imm_ctl == 5 ? j : 
    0;
endmodule

module m_imm_dec_R(input [31:0] i_data, output [31:0] o_data);
  assign o_data = 0;
endmodule

module m_imm_dec_I(input [31:0] i_data, output [31:0] o_data);
  assign o_data = {{20{i_data[31]}}, i_data[11:0]};
endmodule

module m_imm_dec_S(input [31:0] i_data, output [31:0] o_data);
  assign o_data = {{20{i_data[31]}}, i_data[31:25], i_data[11:7]};
endmodule

module m_imm_dec_B(input [31:0] i_data, output [31:0] o_data);
  assign o_data = {{19{i_data[31]}}, i_data[7], i_data[30:25], i_data[11:8]};
endmodule

module m_imm_dec_U(input [31:0] i_data, output [31:0] o_data);
  wire [11:0] zero = 0;
  assign o_data = {i_data[31:12], zero};
endmodule

module m_imm_dec_J(input [31:0] i_data, output [31:0] o_data);
  wire zero = 0;
  assign o_data = {{11{i_data[31]}}, i_data[19:12], i_data[20], i_data[30:21], zero};
endmodule

/** ALU
  * @param i_d0, i_d1 - registers to sum
  * @param k_ctl - mode control
  *   0000 - add
  *   0001 - sub
  *   0010 - and
  *   0011 - slt
  *   0100 - div
  *   0101 - rem
  *   0110 - sll
  *   0111 - srl
  *   1000 - sra
  * @return o_data - operation result
  * @return o_zero - 1 if the operation result is 0
  */
module m_alu(input [31:0] i_d0, i_d1, input [1:0] i_ctl, output [31:0] o_data, output o_zero);
  wire [31:0] w_add = i_d0 + i_d1;
  wire [31:0] w_sub = i_d0 - i_d1;
  wire [31:0] w_and = i_d0 ^ i_d1;
  wire [31:0] w_slt = i_d0 < i_d1 ? 1 : 0;
  wire [31:0] w_div = i_d0 / i_d1;
  wire [31:0] w_rem = i_d0 % i_d1;
  wire [31:0] w_sll = i_d0 << i_d1;
  wire [31:0] w_srl = i_d0 >> i_d1;
  wire [31:0] w_sra = i_d0 >>> i_d1;

  wire [31:0] result =
    'b0000 ? w_add :
    'b0001 ? w_sub :
    'b0010 ? w_and :
    'b0011 ? w_slt :
    'b0100 ? w_div :
    'b0101 ? w_rem :
    'b0110 ? w_sll :
    'b0111 ? w_srl :
    'b1000 ? w_sra :
    0;

  assign o_zero = result == 0;
  assign o_data = result;
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
