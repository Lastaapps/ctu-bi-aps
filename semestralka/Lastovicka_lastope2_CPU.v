`default_nettype none

/** Links all the components together - RAM is external */
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



/** Operation codes decoder */
module m_controller(input [31:0] i_inst,
                    output [2:0] o_imm_ctl,
                    output o_alu_src,
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

  // Output definition

  // register arithmetic
  wire [17:0] s_add  = 'b000_0_0000_0010_00000_0; // add
  wire [17:0] s_and  = 'b000_0_0010_0010_00000_0; // and
  wire [17:0] s_sub  = 'b000_0_0001_0010_00000_0; // substitute
  wire [17:0] s_slt  = 'b000_0_0011_0010_00000_0; // compare, a < b -> 1
  wire [17:0] s_sltu = 'b000_0_1011_0010_00000_0; // compare, a < b -> 1
  wire [17:0] s_div  = 'b000_0_0100_0010_00000_0; // divide
  wire [17:0] s_rem  = 'b000_0_0101_0010_00000_0; // modulo
  wire [17:0] s_or   = 'b000_0_1001_0010_00000_0; // or
  wire [17:0] s_xor  = 'b000_0_1010_0010_00000_0; // xor
  wire [17:0] s_sll  = 'b000_0_0110_0010_00000_0; // logical left shift
  wire [17:0] s_srl  = 'b000_0_0111_0010_00000_0; // logical left shift
  wire [17:0] s_sra  = 'b000_0_1000_0010_00000_0; // arithmetic left shift

  // immediate arithmetic
  wire [17:0] s_addi  = 'b001_1_0000_0010_00000_0; // add immediate
  wire [17:0] s_andi  = 'b001_1_0010_0010_00000_0; // and immediate
  wire [17:0] s_slti  = 'b001_1_0011_0010_00000_0; // compare, a < b -> 1 immediate
  wire [17:0] s_sltiu = 'b001_1_1011_0010_00000_0; // compare, a < b -> 1 immediate
  wire [17:0] s_ori   = 'b001_1_1001_0010_00000_0; // or immediate
  wire [17:0] s_xori  = 'b001_1_1010_0010_00000_0; // xor immediate
  wire [17:0] s_slli  = 'b110_1_0110_0010_00000_0; // logical left shift immediate
  wire [17:0] s_srli  = 'b110_1_0111_0010_00000_0; // logical left shift immediate
  wire [17:0] s_srai  = 'b110_1_1000_0010_00000_0; // arithmetic left shift immediate

  // branching
  wire [17:0] s_beq  = 'b011_0_0001_0000_00100_0; // branch equal
  wire [17:0] s_bne  = 'b011_0_0001_0000_00010_0; // branch not equal
  wire [17:0] s_blt  = 'b011_0_0000_0000_00001_0; // jump if a < b

  // memory
  wire [17:0] s_lw   = 'b001_1_0000_0110_00000_0; // load word
  wire [17:0] s_sw   = 'b010_1_0000_1000_00000_0; // save word
  wire [17:0] s_lui  = 'b100_1_0000_0011_00000_0; // load immediate

  // jumping
  wire [17:0] s_jal  = 'b101_0_0000_0010_01000_0; // jump relative to PC
  wire [17:0] s_jalr = 'b001_1_0000_0010_10000_0; // jump relative to rd
  wire [17:0] s_aui  = 'b100_0_0000_0010_00000_1; // rd <- rn + PC


  // parsing
  wire [6:0] opt  = i_inst[6:0];
  wire [3:0] fun3 = i_inst[14:12];
  wire [6:0] fun7 = i_inst[31:25];

  wire [31:0] out = 
    // register arithmetic
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
        fun7 == 'b0000000 ? s_xor : // xor
        fun7 == 'b0000001 ? s_div : // div
        0 :
      fun3 == 'b110 ?
        fun7 == 'b0000000 ? s_or  : // or
        fun7 == 'b0000001 ? s_rem : // rem
        0 :
      fun3 == 'b001 ?
        fun7 == 'b0000000 ? s_sll : 0 : // sll
      fun3 == 'b101 ?
        fun7 == 'b0000000 ? s_srl : // srl
        fun7 == 'b0100000 ? s_sra : // sra
        0 :
      fun3 == 'b011 ?
        fun7 == 'b0000000 ? s_sltu : 0 : // sltu
    0) :

    // immediate arithmetic
    opt == 'b0010011 ? 
      fun3 == 'b000 ? s_addi : // addi
      fun3 == 'b001 ? s_slli : // slli
      fun3 == 'b010 ? s_slti : // slti
      fun3 == 'b011 ? s_sltiu : // sltiu
      fun3 == 'b100 ? s_xori : // xori
      fun3 == 'b101 ?
        fun7 == 'b0000000 ? s_srli : // srli
        fun7 == 'b0100000 ? s_srai : // srai
        0 :
      fun3 == 'b110 ? s_ori : // ori
      fun3 == 'b111 ? s_andi : // andi
      0 :

    // branching
    opt == 'b1100011 ? 
      fun3 == 'b000 ? s_beq  : // beq
      fun3 == 'b001 ? s_bne  : // bne
      fun3 == 'b100 ? s_blt  : // blt
      0 :

    // memory
    opt == 'b0000011 ?
      fun3 == 'b010 ? s_lw   : 0 : // lw
    opt == 'b0100011 ?
      fun3 == 'b010 ? s_sw   : 0 : // sw
    opt == 'b0110111 ? s_lui  : // lui

    // jumps
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






/** Decodes data stored in an instruction
  * R - 000
  * I - 001
  * S - 010
  * B - 011
  * U - 100
  * J - 101
  * A - 110
  *
  * A is no an usual encoding. It's similar to I, but first 7 bits are trimmed
  * it is used by bit shift instructions
  * https://stackoverflow.com/questions/39489318/risc-v-implementing-slli-srli-and-srai
  */
module m_imm_decoder(input [31:0] i_data, input [2:0] i_imm_ctl, output [31:0] o_data);

  supply0 zero;

  wire [31:0] r = 0;
  wire [31:0] i = {{20{i_data[31]}}, i_data[31:20]};
  wire [31:0] s = {{20{i_data[31]}}, i_data[31:25], i_data[11:7]};
  wire [31:0] b = {{20{i_data[31]}}, i_data[7], i_data[30:25], i_data[11:8], zero};
  wire [31:0] u = {i_data[31:12], {12{zero}}};
  wire [31:0] j = {{12{i_data[31]}}, i_data[19:12], i_data[20], i_data[30:21], zero};
  wire [31:0] a = {{27{i_data[24]}}, i_data[24:20]};

  assign o_data =
    i_imm_ctl == 0 ? r : 
    i_imm_ctl == 1 ? i : 
    i_imm_ctl == 2 ? s : 
    i_imm_ctl == 3 ? b : 
    i_imm_ctl == 4 ? u : 
    i_imm_ctl == 5 ? j : 
    i_imm_ctl == 6 ? a : 
    0;

  // always @(*) #1 $display("dec: %b - %b -> %b(%h)", i_imm_ctl, i_data, o_data, o_data);
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
  *   1001 - or
  *   1010 - xor
  *   1011 - sltu
  * @return o_data - operation result
  * @return o_zero - 1 if the operation result is 0
  */
module m_alu(input signed [31:0] i_d0, i_d1, input [3:0] i_ctl, output [31:0] o_data, output o_zero, output o_gt);
  wire [31:0] unsigned_d0 = i_d0;
  wire [31:0] unsigned_d1 = i_d1;

  wire [31:0] w_add  = i_d0 + i_d1;
  wire [31:0] w_sub  = i_d0 - i_d1;
  wire [31:0] w_and  = i_d0 & i_d1;
  wire [31:0] w_slt  = i_d0 < i_d1 ? 1 : 0;
  wire [31:0] w_div  = i_d0 / i_d1;
  wire [31:0] w_rem  = i_d0 % i_d1;
  wire [31:0] w_sll  = i_d0 << i_d1;
  wire [31:0] w_srl  = i_d0 >> i_d1;
  wire [31:0] w_sra  = i_d0 >>> i_d1;
  wire [31:0] w_or   = i_d0 | i_d1;
  wire [31:0] w_xor  = i_d0 ^ i_d1;
  wire [31:0] w_sltu = unsigned_d0 < unsigned_d1 ? 1 : 0;

  wire [31:0] result =
    i_ctl == 'b0000 ? w_add  :
    i_ctl == 'b0001 ? w_sub  :
    i_ctl == 'b0010 ? w_and  :
    i_ctl == 'b0011 ? w_slt  :
    i_ctl == 'b0100 ? w_div  :
    i_ctl == 'b0101 ? w_rem  :
    i_ctl == 'b0110 ? w_sll  :
    i_ctl == 'b0111 ? w_srl  :
    i_ctl == 'b1000 ? w_sra  :
    i_ctl == 'b1001 ? w_or   :
    i_ctl == 'b1010 ? w_xor  :
    i_ctl == 'b1011 ? w_sltu :
    0;

  // always @(*) #1 $display("alu: %h %b %h -> %h", i_d0, i_ctl, i_d1, result);
  // always @(*) #1 $display("zero: %b", o_zero);

  assign o_zero = result == 0;
  assign o_gt = i_d0 < i_d1;
  assign o_data = result;
endmodule

/** Reset-able register
  * updates it's value to the next one on clk tick unless reset is on
  * if reset is 1, 0 is saved to the register
  */
module m_reset(input i_clk, i_reset, input [31:0] i_data, output reg [31:0] o_out);
  always @(posedge i_clk) begin
    if (i_reset) o_out <= 0;
    else o_out <= i_data;
  end
endmodule

// down just to see not warnings in the top main part
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
