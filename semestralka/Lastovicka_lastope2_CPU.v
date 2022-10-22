`default_nettype none
module m_processor( input i_clk, i_reset,
                  output [31:0] o_PC,
                  input  [31:0] i_inst,
                  output o_WE,
                  output [31:0] o_address_to_mem,
                  output [31:0] o_data_to_mem,
                  input  [31:0] i_data_from_mem
                );
  // blue controller wires
  wire [2:0] imm_ctl;
  wire alu_src;
  wire [3:0] alu_ctl;
  wire mem_write, mem_to_reg, reg_write, imm_to_reg;
  wire br_jalr, br_jal, br_beq, br_bne, br_blt;
  wire br_outcome, br_jalx;
  wire aui;

  wire [31:0]
    pc, pc_plus, imm_op, pc_imm,
    rs0, rs1,
    alu_src_a, alu_src_b, alu_out,
    br_target, res,
    tmp0, tmp1, tmp2;
  wire alu_zero, alu_gt;

  // PC
  wire [31:0] pc_new;
  m_reset u_pc_reg(i_clk, i_reset, pc_new, pc);

  // Linking wires
  assign alu_src_a = rs0;
  assign alu_src_b = alu_src ? imm_op : rs1;
  assign o_data_to_mem = rs1;
  assign o_address_to_mem = alu_out;
  assign o_WE = mem_write;
  assign pc_plus = pc + 4;
  assign o_PC = pc;
  assign pc_imm = pc + imm_op;
  assign br_outcome = (br_beq && alu_zero) || (br_bne && !alu_zero) || (br_blt && alu_gt) || br_jalx;
  assign pc_new = br_outcome ? br_target : pc_plus;
  assign br_jalx = br_jal || br_jalr;
  assign br_target = br_jalr ? alu_out : pc_imm;
  assign tmp0 = br_jalx ? pc_plus : alu_out;
  assign tmp1 = aui ? pc_imm : tmp0;
  assign tmp2 = imm_to_reg ? imm_op : tmp1;
  assign res = mem_to_reg ? i_data_from_mem : tmp2;


  // Components
  m_controller u_ctl(
    i_inst,
    imm_ctl, alu_src, alu_ctl,
    mem_write, mem_to_reg, reg_write, imm_to_reg,
    br_jalr, br_jal, br_beq, br_bne, br_blt, aui
  );
  m_register u_reg(i_inst, i_clk, reg_write, res, rs0, rs1);
  m_imm_decoder u_imm_dec(i_inst, imm_ctl, imm_op);
  m_alu u_alu(alu_src_a, alu_src_b, alu_ctl, alu_out, alu_zero, alu_gt);
endmodule


/** Registers
  * @param i_ar0, i_ar1 first and second address to read a register from
  * @param i_clk - clock on which writes are done
  * @param i_we - write enabled
  * @return o_a0, o_a1 - content of registers referenced by i_ar0 and i_ar1
  */
module m_register(input [31:0] i_inst, input i_clk, i_we, input [31:0] i_wd, output [31:0] o_a0, o_a1);
  reg [31:0] matrix [31:0];

  wire [4:0] ar0 = i_inst[19:15], ar1 = i_inst[24:20], aw = i_inst[11:7];

  assign o_a0 = ar0 == 0 ? 0 : matrix[ar0];
  assign o_a1 = ar1 == 0 ? 0 : matrix[ar1];

  always @(posedge i_clk) begin
    if (i_we) matrix[aw] <= i_wd;
    else ;
  end

  // always @(*) #1 $display("reg in: %b %h", i_we, i_wd);
  // always @(*) #1 $display("reg outA:  %h", o_a0);
  // always @(*) #1 $display("reg outB:  %h", o_a1);

  /*
  always @(matrix[0]) #1 $display("x0: %h", matrix[0]);
  always @(matrix[1]) #1 $display("ra: %h", matrix[1]);
  always @(matrix[2]) #1 $display("sp: %h", matrix[2]);
  always @(matrix[3]) #1 $display("gp: %h", matrix[3]);
  always @(matrix[4]) #1 $display("tp: %h", matrix[4]);
  always @(matrix[5]) #1 $display("t0: %h", matrix[5]);
  always @(matrix[6]) #1 $display("t1: %h", matrix[6]);
  always @(matrix[7]) #1 $display("t2: %h", matrix[7]);
  always @(matrix[8]) #1 $display("s0: %h", matrix[8]);
  always @(matrix[9]) #1 $display("s1: %h", matrix[9]);
  always @(matrix[10]) #1 $display("a0: %h", matrix[10]);
  always @(matrix[11]) #1 $display("a1: %h", matrix[11]);
  always @(matrix[12]) #1 $display("a2: %h", matrix[12]);
  always @(matrix[13]) #1 $display("a3: %h", matrix[13]);
  always @(matrix[14]) #1 $display("a4: %h", matrix[14]);
  always @(matrix[15]) #1 $display("a5: %h", matrix[15]);
  always @(matrix[16]) #1 $display("a6: %h", matrix[16]);
  always @(matrix[17]) #1 $display("a7: %h", matrix[17]);
  always @(matrix[18]) #1 $display("s2: %h", matrix[18]);
  always @(matrix[19]) #1 $display("s3: %h", matrix[19]);
  always @(matrix[20]) #1 $display("s4: %h", matrix[20]);
  always @(matrix[21]) #1 $display("s5: %h", matrix[21]);
  always @(matrix[22]) #1 $display("s6: %h", matrix[22]);
  always @(matrix[23]) #1 $display("s7: %h", matrix[23]);
  always @(matrix[24]) #1 $display("s8: %h", matrix[24]);
  always @(matrix[25]) #1 $display("s9: %h", matrix[25]);
  always @(matrix[26]) #1 $display("sa: %h", matrix[26]);
  always @(matrix[27]) #1 $display("sb: %h", matrix[27]);
  always @(matrix[28]) #1 $display("t3: %h", matrix[28]);
  always @(matrix[29]) #1 $display("t4: %h", matrix[29]);
  always @(matrix[30]) #1 $display("t5: %h", matrix[30]);
  always @(matrix[31]) #1 $display("t6: %h", matrix[31]);
  */
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

  wire [17:0] s_add  = 'b000_0_0000_0010_00000_0; // add
  wire [17:0] s_addi = 'b001_1_0000_0010_00000_0; // add immediate
  wire [17:0] s_and  = 'b000_0_0010_0010_00000_0; // and
  wire [17:0] s_sub  = 'b000_0_0001_0010_00000_0; // substitute
  wire [17:0] s_slt  = 'b000_0_0011_0010_00000_0; // compare, a < b -> 1
  wire [17:0] s_div  = 'b000_0_0100_0010_00000_0; // divide
  wire [17:0] s_rem  = 'b000_0_0101_0010_00000_0; // modulo

  wire [17:0] s_beq  = 'b011_0_0001_0000_00100_0; // branch equal
  wire [17:0] s_bne  = 'b011_0_0001_0000_00010_0; // branch not equal
  wire [17:0] s_blt  = 'b011_0_0000_0000_00001_0; // jump if a < b

  wire [17:0] s_lw   = 'b001_1_0000_0110_00000_0; // load word
  wire [17:0] s_sw   = 'b010_1_0000_1000_00000_0; // save word
  wire [17:0] s_lui  = 'b100_1_0000_0011_00000_0; // load immediate

  wire [17:0] s_jal  = 'b101_0_0000_0010_01000_0; // jump relative to PC
  wire [17:0] s_jalr = 'b001_1_0000_0010_10000_0; // jump relative to rd
  wire [17:0] s_aui  = 'b100_0_0000_0010_00000_1; // rd <- rn + PC

  wire [17:0] s_sll  = 'b000_0_0110_0010_00000_0; // logical left shift
  wire [17:0] s_srl  = 'b000_0_0111_0010_00000_0; // logical left shift
  wire [17:0] s_sra  = 'b000_0_1000_0010_00000_0; // arithmetic left shift

  wire [6:0] opt  = i_inst[6:0];
  wire [3:0] fun3 = i_inst[14:12];
  wire [6:0] fun7 = i_inst[31:25];
  wire [31:0] out = 
    opt == 'b0110011 ? ( 
      fun3 == 'b000 ? 
        fun7 == 'b0000000 ? s_add : // add
        fun7 == 'b0100000 ? s_sub : // sub
        0 : 
      fun3 == 'b010 ? 
        fun7 == 'b0000000 ? s_slt : 0 : // slt
      fun3 == 'b111 ? 
        fun7 == 'b0000000 ? s_and : 0 : // and
      fun3 == 'b100 ?
        fun7 == 'b0000001 ? s_div : 0 : // div
      fun3 == 'b110 ?
        fun7 == 'b0000001 ? s_rem : 0 : // rem
      fun3 == 'b001 ?
        fun7 == 'b0000000 ? s_sll : 0 : // sll
      fun3 == 'b101 ?
        fun7 == 'b0000000 ? s_srl : // srl
        fun7 == 'b0100000 ? s_sra : // sra
        0 : 0) :
      opt == 'b0010011 ? 
        fun3 == 'b000 ? s_addi : 0 : // addi

      opt == 'b1100011 ? 
        fun3 == 'b000 ? s_beq  : // beq
        fun3 == 'b001 ? s_bne  : // bne
        fun3 == 'b100 ? s_blt  : // blt
        0 :

      opt == 'b0000011 ?
        fun3 == 'b010 ? s_lw   : 0 : // lw
      opt == 'b0100011 ?
        fun3 == 'b010 ? s_sw   : 0 : // sw
      opt == 'b0110111 ? s_lui  : // lui

      opt == 'b1101111 ? s_jal  : // jal
      opt == 'b1100111 ? 
        fun3 == 'b000 ? s_jalr : 0 : // jalr
      opt == 'b0010111 ? s_aui  : // auipc
   0;

  assign {
    o_imm_ctl, o_alu_src, o_alu_ctl,
    o_mem_write, o_mem_to_reg, o_reg_write, o_imm_to_reg,
    o_br_jalr, o_br_jal, o_br_beq, o_br_bne, o_br_blt, o_aui
    } = out;

  // always @(*) #1 $display("ctl: %b (%h) -> %b", i_inst, i_inst, out);
  // always @(*) #1 $display("opt: %b, fun3: %b, fun7: %b", opt, fun3, fun7);
endmodule






/* Decodes data stored in an instruction
* R - 000
* I - 001
* S - 010
* B - 011
* U - 100
* J - 101
*/
module m_imm_decoder(input [31:0] i_data, input [2:0] i_imm_ctl, output [31:0] o_data);
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

  // always @(*) #1 $display("dec: %b - %b -> %b(%h)", i_imm_ctl, i_data, o_data, o_data);
endmodule

module m_imm_dec_R(input [31:0] i_data, output [31:0] o_data);
  assign o_data = 0;
endmodule

module m_imm_dec_I(input [31:0] i_data, output [31:0] o_data);
  assign o_data = {{20{i_data[31]}}, i_data[31:20]};
endmodule

module m_imm_dec_S(input [31:0] i_data, output [31:0] o_data);
  assign o_data = {{20{i_data[31]}}, i_data[31:25], i_data[11:7]};
endmodule

module m_imm_dec_B(input [31:0] i_data, output [31:0] o_data);
  wire zero = 0;
  assign o_data = {{20{i_data[31]}}, i_data[7], i_data[30:25], i_data[11:8], zero};
endmodule

module m_imm_dec_U(input [31:0] i_data, output [31:0] o_data);
  wire [11:0] zero = 0;
  assign o_data = {i_data[31:12], zero};
endmodule

module m_imm_dec_J(input [31:0] i_data, output [31:0] o_data);
  wire zero = 0;
  assign o_data = {{12{i_data[31]}}, i_data[19:12], i_data[20], i_data[30:21], zero};
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
module m_alu(input signed [31:0] i_d0, i_d1, input [3:0] i_ctl, output [31:0] o_data, output o_zero, output o_gt);
  wire [31:0] w_add = i_d0 + i_d1;
  wire [31:0] w_sub = i_d0 - i_d1;
  wire [31:0] w_and = i_d0 & i_d1;
  wire [31:0] w_slt = i_d0 < i_d1 ? 1 : 0;
  wire [31:0] w_div = i_d0 / i_d1;
  wire [31:0] w_rem = i_d0 % i_d1;
  wire [31:0] w_sll = i_d0 << i_d1;
  wire [31:0] w_srl = i_d0 >> i_d1;
  wire [31:0] w_sra = i_d0 >>> i_d1;

  wire [31:0] result =
    i_ctl == 'b0000 ? w_add :
    i_ctl == 'b0001 ? w_sub :
    i_ctl == 'b0010 ? w_and :
    i_ctl == 'b0011 ? w_slt :
    i_ctl == 'b0100 ? w_div :
    i_ctl == 'b0101 ? w_rem :
    i_ctl == 'b0110 ? w_sll :
    i_ctl == 'b0111 ? w_srl :
    i_ctl == 'b1000 ? w_sra :
    0;

  // always @(*) #1 $display("alu: %h %b %h -> %h", i_d0, i_ctl, i_d1, result);
  // always @(*) #1 $display("zero: %b", o_zero);

  assign o_zero = result == 0;
  assign o_gt = i_d0 < i_d1;
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


module processor( input clk, reset,
                  output [31:0] PC,
                  input  [31:0] instruction,
                  output        WE,
                  output [31:0] address_to_mem,
                  output [31:0] data_to_mem,
                  input  [31:0] data_from_mem
                );
  m_processor u_cpu(clk, reset, PC, instruction, WE, address_to_mem, data_to_mem, data_from_mem);
endmodule

`default_nettype wire 

/*
  wire [31:0] out = 
      i_inst === 'b0000000_?????_?????_000_?????_0110011 ? s_add  : // add
      i_inst === 'b0000000_?????_?????_111_?????_0110011 ? s_and  : // and
      i_inst === 'b0100000_?????_?????_000_?????_0110011 ? s_sub  : // sub
      i_inst === 'b0000000_?????_?????_010_?????_0110011 ? s_slt  : // slt
      i_inst === 'b0000001_?????_?????_100_?????_0110011 ? s_div  : // div
      i_inst === 'b0000001_?????_?????_110_?????_0110011 ? s_rem  : // rem
      i_inst === 'b0000000_?????_?????_001_?????_0110011 ? s_sll  : // sll
      i_inst === 'b0000000_?????_?????_101_?????_0110011 ? s_srl  : // srl
      i_inst === 'b0100000_?????_?????_101_?????_0110011 ? s_sra  : // sra

      i_inst === 'b???????_?????_?????_000_?????_0010011 ? s_addi : // addi

      i_inst === 'b???????_?????_?????_000_?????_1100011 ? s_beq  : // beq
      i_inst === 'b???????_?????_?????_001_?????_1100011 ? s_bne  : // bne
      i_inst === 'b???????_?????_?????_100_?????_1100011 ? s_blt  : // blt

      i_inst === 'b???????_?????_?????_010_?????_0000011 ? s_lw   : // lw
      i_inst === 'b???????_?????_?????_010_?????_0100011 ? s_sw   : // sw
      i_inst === 'b???????_?????_?????_???_?????_0110111 ? s_lui  : // lui

      i_inst === 'b???????_?????_?????_???_?????_1101111 ? s_jal  : // jal
      i_inst === 'b???????_?????_?????_000_?????_1100111 ? s_jalr : // jalr
      i_inst === 'b???????_?????_?????_???_?????_0010111 ? s_aui  : // auipc
      0;
*/
