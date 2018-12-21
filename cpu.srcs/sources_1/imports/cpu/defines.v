//common defines
`ifndef DEFINES_V
`define DEFINES_V

//opcode
`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_JAL      7'b1101111
`define OP_JALR     7'b1100111
`define OP_BX       7'b1100111
`define OP_LX       7'b0000011
`define OP_SX       7'b0100011
`define OP_AI       7'b0010011
`define OP_AX       7'b0110011
`define OP_FENCE    7'b0001111 

//funct3
`define FUNCT3_JALR     3'b000 

`define FUNCT3_BEQ      3'b000
`define FUNCT3_BNE      3'b001 
`define FUNCT3_BLT      3'b100 
`define FUNCT3_BGE      3'b101 
`define FUNCT3_BLTU     3'b110 
`define FUNCT3_BGEU     3'b111 

`define FUNCT3_LB       3'b000
`define FUNCT3_LH       3'b001
`define FUNCT3_LW       3'b010 
`define FUNCT3_LBU      3'b100 
`define FUNCT3_LHU      3'b101 

`define FUNCT3_SB       3'b000
`define FUNCT3_SH       3'b001
`define FUNCT3_SW       3'b010

`define FUNCT3_ADDI     3'b000
`define FUNCT3_SLTI     3'b010  
`define FUNCT3_SLTIU    3'b011
`define FUNCT3_XORI     3'b100 
`define FUNCT3_ORI      3'b110 
`define FUNCT3_ANDI     3'b111 
`define FUNCT3_SLLI     3'b001 
`define FUNCT3_SRI      3'b101 

`define FUNCT3_ADD      3'b000
`define FUNCT3_SLL      3'b001
`define FUNCT3_SLT      3'b010
`define FUNCT3_SLTU     3'b011
`define FUNCT3_XOR      3'b100
`define FUNCT3_SR       3'b101
`define FUNCT3_OR       3'b110
`define FUNCT3_AND      3'b111

`define FUNCT3_FENCE    3'b000
`define FUNCT3_FENCEI   3'b001 

//funct7
`define FUNCT7_SLLI     7'b0000000
`define FUNCT7_SRLI     7'b0000000
`define FUNCT7_SRAI     7'b0100000

`define FUNCT7_ADD      7'b0000000
`define FUNCT7_SUB      7'b0100000
`define FUNCT7_SLL      7'b0000000
`define FUNCT7_SLT      7'b0000000
`define FUNCT7_SLTU     7'b0000000
`define FUNCT7_XOR      7'b0000000
`define FUNCT7_SRL      7'b0000000
`define FUNCT7_SRA      7'b0100000
`define FUNCT7_OR       7'b0000000
`define FUNCT7_AND      7'b0000000

//instruction catagory
`define IC_EMP          3'b000
`define IC_JMP          3'b001
`define IC_LAS          3'b010
`define IC_ARI          3'b011
`define IC_SFT          3'b100
`define IC_LGC          3'b101
`define IC_MOV          3'b110

//instructions need ALU
`define INS_EMP         5'b00000  
`define INS_JAL         5'b00001 
`define INS_JALR        5'b00010 
`define INS_BEQ         5'b00011 
`define INS_BNE         5'b00100 
`define INS_BLT         5'b00101 
`define INS_BGE         5'b00110 
`define INS_BLTU        5'b00111 
`define INS_BGEU        5'b01000 
`define INS_LB          5'b01001 
`define INS_LH          5'b01010 
`define INS_LW          5'b01011 
`define INS_LBU         5'b01100 
`define INS_LHU         5'b01101 
`define INS_SB          5'b01110 
`define INS_SH          5'b01111 
`define INS_SW          5'b10000
`define INS_ADD         5'b10001 
`define INS_SUB         5'b10010  
`define INS_SLL         5'b10011 
`define INS_SLT         5'b10100  
`define INS_SLTU        5'b10101  
`define INS_XOR         5'b10110  
`define INS_SRL         5'b10111  
`define INS_SRA         5'b11000  
`define INS_OR          5'b11001 
`define INS_AND         5'b11010  

`endif
