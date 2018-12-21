//instruction decode
`timescale 1ns/1ps
`include "defines.v"

module p_id(
    //common
    input rst_in,
    input rdy_in,
    //instruction
    input wire[31:0] inst_pc,
    input wire[31:0] inst,
    input wire busy_in,
    //data to regfile
    output reg re1,
    output reg[31:0] r_addr1,
    output reg re2,
    output reg[31:0] r_addr2,
    //data from regfile
    input wire[31:0] r_data1,
    input wire[31:0] r_data2,
    //forwarding
    input wire ex_we,
    input wire[31:0] ex_w_addr,
    input wire[31:0] ex_w_data,
    input wire ex_is_loading,
    input wire mem_we,
    input wire[31:0] mem_w_addr,
    input wire[31:0] mem_w_data,
    //output
    output reg jump,
    output reg[31:0] next_addr,
    output reg[31:0] link_addr,
    output reg[31:0] offset,
    output reg we,
    output reg[31:0] w_addr,

    output reg[2:0] inst_catagory,
    output reg[4:0] local_opcode,
    output reg[31:0] ari_op1,
    output reg[31:0] ari_op2,

    output wire busy_out
);

    wire[31:0] rd;
    wire[31:0] rs1;
    wire[31:0] rs2;

    wire[6:0] opcode;
    wire[2:0] funct3;
    wire[6:0] funct7;

    assign opcode = inst[6:0];
    assign rd = inst[11:7];
    assign funct3 = inst[14:12];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];
    assign funct7 = inst[31:25];
    
    wire[31:0] imm_I;
    wire[31:0] imm_S;
    wire[31:0] imm_B;
    wire[31:0] imm_U;
    wire[31:0] imm_J;

    assign imm_I = {{20{inst[31]}}, inst[31:20]};
    assign imm_S = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign imm_B = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
    assign imm_U = {inst[31:12], 12'b0};
    assign imm_J = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

    wire[31:0] PC_PLUS_4;
    wire[31:0] RS1_PLUS_I;
    wire[31:0] PC_PLUS_B;
    wire[31:0] PC_PLUS_J;

    assign PC_PLUS_4 = inst_pc + 4; //for LINK
    assign RS1_PLUS_I = r_data1 + imm_I; //for JALR
    assign PC_PLUS_B = inst_pc + imm_B; //for BRANCH
    assign PC_PLUS_J = inst_pc + imm_J; //for JAL

   /* wire IS_EQ;
    wire IS_NE;
    wire IS_LT;
    wire IS_GE;
    wire IS_LTU;
    wire IS_GEU;

    assign IS_EQ = (ari_op1 == ari_op2);
    assign IS_NE = (ari_op1 != ari_op2);
    assign IS_LT = ($signed(ari_op1) < $signed(ari_op2));
    assign IS_GE = ($signed(ari_op1) >= $signed(ari_op2));
    assign IS_LTU = (ari_op1 < ari_op2);
    assign IS_GEU = (ari_op1 >= ari_op2);
*/
    
    reg inst_busy;
    reg r1_busy;
    reg r2_busy;
    assign busy_out = inst_busy | r1_busy | r2_busy;

    reg[31:0] tmp_ari_op1;
    reg[31:0] tmp_ari_op2;

    task fill_inst;
        input reg _re1; 
        input reg[31:0] _r_addr1;
        input reg _re2; 
        input reg[31:0] _r_addr2;
        input reg _we;
        input reg[31:0] _w_addr;
        input reg[2:0] _inst_catagory;
        input reg[4:0] _local_opcode;
        input reg[31:0] _tmp_ari_op1;
        input reg[31:0] _tmp_ari_op2;
        input reg[31:0] _offset;
        input wire _jump;
        input wire[31:0] _next_addr;
        input wire[31:0] _link_addr;
        begin
            re1 = _re1;
            r_addr1 = _r_addr1;
            re2 = _re2;
            r_addr2 = _r_addr2;
            we = _we;
            w_addr = _w_addr;
            inst_catagory = _inst_catagory;
            local_opcode = _local_opcode;
            tmp_ari_op1 = _tmp_ari_op1;
            tmp_ari_op2 = _tmp_ari_op2;
            offset = _offset;
            jump = _jump;
            next_addr = _next_addr;
            link_addr = _link_addr;
        end 
    endtask

    always @ (*) begin 
        if (rst_in) begin
            fill_inst(0, rs1, 0, rs2, 0, rd, `IC_EMP, `INS_EMP, 0, 0, 0, 0, 0, 0);
            inst_busy = 0;
        end
        else if (busy_in) begin
            fill_inst(0, rs1, 0, rs2, 0, rd, `IC_EMP, `INS_EMP, 0, 0, 0, 0, 0, 0);
            inst_busy = 1;
        end
        else begin
            case (opcode)
            `OP_LUI: begin
                fill_inst(0, 0, 0, 0, 1, rd, `IC_ARI, `INS_ADD, imm_U, 0, 0, 0, 0, 0);
            end
            `OP_AUIPC: begin
                fill_inst(0, 0, 0, 0, 1, rd, `IC_ARI, `INS_ADD, imm_U, inst_pc, 0, 0, 0, 0);
            end
            `OP_JAL: begin
                fill_inst(0, 0, 0, 0, 1, rd, `IC_JMP, `INS_JAL, 0, 0, 0, 1, PC_PLUS_J, PC_PLUS_4);
            end
            `OP_JALR: begin
                fill_inst(1, rs1, 0, 0, 1, rd, `IC_JMP, `INS_JALR, 0, 0, 0, 1, RS1_PLUS_I, PC_PLUS_4);
            end
            `OP_BX: begin
                case (funct3)
                `FUNCT3_BEQ: begin
                    if (ari_op1 == ari_op2) begin 
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BEQ, 0, 0, 0, 1, PC_PLUS_B, 0);
                    end
                    else begin
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BEQ, 0, 0, 0, 0, 0, 0);
                    end
                end
                `FUNCT3_BNE: begin
                    if (ari_op1 != ari_op2) begin 
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BNE, 0, 0, 0, 1, PC_PLUS_B, 0);
                    end
                    else begin
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BNE, 0, 0, 0, 0, 0, 0);
                    end
                end
                `FUNCT3_BLT: begin
                    if ($signed(ari_op1) < $signed(ari_op2)) begin 
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BLT, 0, 0, 0, 1, PC_PLUS_B, 0);
                    end
                    else begin
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BLT, 0, 0, 0, 0, 0, 0);
                    end
                end
                `FUNCT3_BGE: begin
                    if ($signed(ari_op1) >= $signed(ari_op2)) begin 
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BGE, 0, 0, 0, 1, PC_PLUS_B, 0);
                    end
                    else begin
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BGE, 0, 0, 0, 0, 0, 0);
                    end
                end
                `FUNCT3_BLTU: begin
                    if (ari_op1 < ari_op2) begin 
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BLTU, 0, 0, 0, 1, PC_PLUS_B, 0);
                    end
                    else begin
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BLTU, 0, 0, 0, 0, 0, 0);
                    end
                end
                `FUNCT3_BGEU: begin
                    if (ari_op1 < ari_op2) begin 
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BGEU, 0, 0, 0, 1, PC_PLUS_B, 0);
                    end
                    else begin
                        fill_inst(1, rs1, 1, rs2, 0, 0, `IC_JMP, `INS_BGEU, 0, 0, 0, 0, 0, 0);
                    end
                end
                endcase
            end
            `OP_LX: begin
                case (funct3)
                `FUNCT3_LB: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_LAS, `INS_LB, 0, 0, imm_I, 0, 0, 0);
                end
                `FUNCT3_LH: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_LAS, `INS_LB, 0, 0, imm_I, 0, 0, 0);
                end
                `FUNCT3_LW: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_LAS, `INS_LW, 0, 0, imm_I, 0, 0, 0);
                end
                `FUNCT3_LBU: begin  
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_LAS, `INS_LBU, 0, 0, imm_I, 0, 0, 0);
                end
                `FUNCT3_LHU: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_LAS, `INS_LHU, 0, 0, imm_I, 0, 0, 0);
                end
                endcase
            end
            `OP_SX: begin
                case (funct3)
                `FUNCT3_SB: begin
                    fill_inst(1, rs1, 1, rs2, 0, 0, `IC_LAS, `INS_SB, 0, 0, imm_S, 0, 0, 0);
                end
                `FUNCT3_SH: begin
                    fill_inst(1, rs1, 1, rs2, 0, 0, `IC_LAS, `INS_SB, 0, 0, imm_S, 0, 0, 0);
                end
                `FUNCT3_SW: begin
                    fill_inst(1, rs1, 1, rs2, 0, 0, `IC_LAS, `INS_SB, 0, 0, imm_S, 0, 0, 0);
                end
                endcase
            end
            `OP_AI: begin
                case (funct3)
                `FUNCT3_ADDI: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_ARI, `INS_ADD, 0, imm_I, 0, 0, 0, 0);
                end
                `FUNCT3_SLTI: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_ARI, `INS_SLT, 0, imm_I, 0, 0, 0, 0);
                end
                `FUNCT3_SLTIU: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_ARI, `INS_SLTU, 0, imm_I, 0, 0, 0, 0);
                end
                `FUNCT3_XORI: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_LGC, `INS_XOR, 0, imm_I, 0, 0, 0, 0);
                end
                `FUNCT3_ORI: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_LGC, `INS_OR, 0, imm_I, 0, 0, 0, 0);
                end
                `FUNCT3_ANDI: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_LGC, `INS_AND, 0, imm_I, 0, 0, 0, 0);
                end
                `FUNCT3_SLLI: begin
                    fill_inst(1, rs1, 0, 0, 1, rd, `IC_SFT, `INS_SLL, 0, rs2, 0, 0, 0, 0);
                end
                `FUNCT3_SRI: begin
                    case (funct7)
                    `FUNCT7_SRLI: begin
                        fill_inst(1, rs1, 0, 0, 1, rd, `IC_SFT, `INS_SRL, 0, rs2, 0, 0, 0, 0);
                    end
                    `FUNCT7_SRAI: begin
                        fill_inst(1, rs1, 0, 0, 1, rd, `IC_SFT, `INS_SRA, 0, rs2, 0, 0, 0, 0);
                    end
                    endcase
                end
                endcase
            end
            `OP_AX: begin
                case (funct3)
                `FUNCT3_ADD: begin
                    case (funct7)
                    `FUNCT7_ADD: begin
                        fill_inst(1, rs1, 1, rs2, 1, rd, `IC_ARI, `INS_ADD, 0, 0, 0, 0, 0, 0);
                    end
                    `FUNCT7_SUB: begin
                        fill_inst(1, rs1, 1, rs2, 1, rd, `IC_ARI, `INS_SUB, 0, 0, 0, 0, 0, 0);
                    end
                    endcase
                end
                `FUNCT3_SLL: begin
                    fill_inst(1, rs1, 1, rs2, 1, rd, `IC_LGC, `INS_SLL, 0, 0, 0, 0, 0, 0);
                end
                `FUNCT3_SLT: begin
                    fill_inst(1, rs1, 1, rs2, 1, rd, `IC_ARI, `INS_SLT, 0, 0, 0, 0, 0, 0);
                end
                `FUNCT3_SLTU: begin
                    fill_inst(1, rs1, 1, rs2, 1, rd, `IC_ARI, `INS_SLTU, 0, 0, 0, 0, 0, 0);
                end
                `FUNCT3_XOR: begin
                    fill_inst(1, rs1, 1, rs2, 1, rd, `IC_LGC, `INS_XOR, 0, 0, 0, 0, 0, 0);
                end
                `FUNCT3_SR: begin
                    case (funct7)
                    `FUNCT7_SRL: begin
                        fill_inst(1, rs1, 1, rs2, 1, rd, `IC_SFT, `INS_SRL, 0, 0, 0, 0, 0, 0);
                    end
                    `FUNCT7_SRA: begin
                        fill_inst(1, rs1, 1, rs2, 1, rd, `IC_SFT, `INS_SRA, 0, 0, 0, 0, 0, 0);
                    end
                    endcase
                end
                `FUNCT3_OR: begin
                    fill_inst(1, rs1, 1, rs2, 1, rd, `IC_LGC, `INS_OR, 0, 0, 0, 0, 0, 0);
                end
                `FUNCT3_AND: begin
                    fill_inst(1, rs1, 1, rs2, 1, rd, `IC_LGC, `INS_AND, 0, 0, 0, 0, 0, 0);
                end
                endcase
            end
            endcase
            inst_busy = 0;
        end
    end
    
    always @ (*) begin
        if (rst_in) begin
            ari_op1 = 0;
            r1_busy = 0;
        end
        else if (re1 && ex_is_loading && (r_addr1 == ex_w_addr)) begin
            r1_busy = 1;
        end
        else if (re1 && ex_we && (r_addr1 == ex_w_addr)) begin
            ari_op1 = ex_w_addr;
            r1_busy = 0;
        end
        else if (re1 && mem_we && (r_addr1 == mem_w_addr)) begin
            ari_op1 = mem_w_data;
            r1_busy = 0;
        end
        else if (re1) begin
            ari_op1 = r_data1;
            r1_busy = 0;
        end
        else if (!re1) begin
            ari_op1 = tmp_ari_op1;
            r1_busy = 0;
        end
        else begin
            ari_op1 = 0;
            r1_busy = 0;
        end
    end

    always @ (*) begin
        if (rst_in) begin
            ari_op2 = 0;
            r2_busy = 0;
        end
        else if (re2 && ex_is_loading && (r_addr2 == ex_w_addr)) begin
            r2_busy = 1;
        end
        else if (re2 && ex_we && (r_addr2 == ex_w_addr)) begin
            ari_op2 = ex_w_addr;
            r2_busy = 0;
        end
        else if (re2 && mem_we && (r_addr2 == mem_w_addr)) begin
            ari_op2 = mem_w_data;
            r2_busy = 0;
        end
        else if (re2) begin
            ari_op2 = r_data1;
            r2_busy = 0;
        end
        else if (!re2) begin
            ari_op2 = tmp_ari_op2;
            r2_busy = 0;
        end
        else begin
            ari_op2 = 0;
            r2_busy = 0;
        end
    end

endmodule
