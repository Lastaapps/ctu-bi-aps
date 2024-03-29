//-------------------------------------------------------------------
module m_top (input i_clk, i_reset, output [31:0] o_data_to_mem, o_address_to_mem, output o_write_enable);
  wire [31:0] pc, instruction, data_from_mem;
  
  m_inst_mem  u_imem(pc[8:2], instruction);
  m_data_mem  u_dmem(i_clk, o_write_enable, o_address_to_mem, o_data_to_mem, data_from_mem);
  processor   u_CPU(i_clk, i_reset, pc, instruction, o_write_enable, o_address_to_mem, o_data_to_mem, data_from_mem);

  always @(*) $display("\nPC: %h (%1d)", pc, pc / 4);
endmodule

//-------------------------------------------------------------------
module m_data_mem (input i_clk, i_we,
  input  [31:0] i_address, i_wd,
  output [31:0] o_rd);

  reg [31:0] RAM[127:0];
  
  initial begin
    $readmemh ("memfile_data.hex",RAM,0,127);
  end

  assign o_rd = RAM[i_address[31:2]]; // word aligned
  
  always @ (posedge i_clk)
    if (i_we) RAM[i_address[31:2]] <= i_wd;
    else ;
endmodule

//-------------------------------------------------------------------
module m_inst_mem (input  [6:0]  i_address,
  output [31:0] o_rd);

  reg [31:0] RAM[127:0];
  initial begin
    $readmemh ("memfile_inst.hex",RAM,0,127);
  end
  assign o_rd = RAM[i_address]; // word aligned
endmodule

module m_testbench();
  reg clk;
  reg reset;
  wire [31:0] data_to_mem, address_to_mem;
  wire write_enable;
  
  m_top u_simulated_system (clk, reset, data_to_mem, address_to_mem, write_enable);
  
  initial begin
    $dumpfile("test");
    $dumpvars;
    reset<=1; # 8; reset<=0;
    // #1024;
    #65_536;
    $writememh ("memfile_data_after_simulation.hex", u_simulated_system.u_dmem.RAM, 0, 127);
    $finish;
  end
  
  // generate clock
  always begin
    clk<=1; # 4; clk<=0; # 4;
  end
endmodule

module m_imm();
  reg [31:0] in;
  reg [2:0] ctl;
  wire [31:0] out;

  m_imm_decoder u_imm(in, ctl, out);

  initial begin
    in <= -1;
    #2 ctl <= 0; #2 ctl <= 1; #2 ctl <= 2; #2 ctl <= 3; #2 ctl <= 4; #2 ctl <= 5; #2 ctl <= 6;
  end

  always @(*) #1 $display("imm: %b -> %h", ctl, out);

endmodule

