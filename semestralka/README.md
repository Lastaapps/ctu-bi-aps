# RISC V CPU

This projects tries to implement an one cycle CPU,
which can handle some basic RISC V instructions.
RAM is expected to be externally provided.

This project also includes a simple really stupid asm code to determinate
if a number in a list given is prime or not.

This project has been develop for BI-APS subject.

## Instructions
Supported instructions are:

### ALU
- add, addi
- sub
- slt, slti
- sltu, sltiu
- div
- rem
- and, andi
- or, ori
- xor, xori
- sll, slli
- srl, srli
- sra, srai

### Branching
- beq
- bne
- blt

### Memory
- lw
- sw
- lui

### Jumps
- jal
- jalr
- aui
