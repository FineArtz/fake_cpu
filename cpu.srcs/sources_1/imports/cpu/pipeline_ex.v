//instruction execute
`timescale 1ns/1ps
`include "defines.v"

module p_ex(
    //common
    input rst_in,
    input rdy_in,
    //from id/ex
    input wire[2:0] inst_catagory,
    input wire[4:0] local_opcode,
    input wire[31:0] ari_op1,
    input wire[31:0] ari_op2,
    input wire we,
    input wire[31:0] w_addr,
    input wire[31:0] link_addr,
    input wire[31:0] offset,
    input wire busy_in,
    //output
    output reg out_we,
    output reg[31:0] out_w_addr,
    output reg[31:0] out_w_data,

    output reg[4:0] out_opcode,
    output reg[31:0] mem_addr,
    
    output reg busy_out
);

    always @ (*) begin 
        if (rst_in || inst_catagory == `IC_EMP) begin
            out_we = 0;
            out_w_addr = 0;
            out_w_data = 0;
            out_opcode = `INS_EMP;
            busy_out = 0;
        end 
        else if (busy_in) begin
            out_we = 0;
            out_w_addr = 0;
            out_w_data = 0;
            out_opcode = `INS_EMP;
            busy_out = 1;
        end
        else begin
            out_opcode = local_opcode;
            out_we = we;
            out_w_addr = w_addr;
            busy_out = 0;
            case (inst_catagory)
            `IC_LAS: begin
                out_w_data = 0;
                mem_addr = ari_op1 + offset;
            end
            `IC_ARI: begin
                case (local_opcode)
                `INS_ADD: begin
                    out_w_data = ari_op1 + ari_op2;
                    mem_addr = 0;
                end
                `INS_SUB: begin
                    out_w_data = ari_op1 - ari_op2;
                    mem_addr = 0;
                end
                `INS_SLT: begin
                    out_w_data = ($signed(ari_op1) < $signed(ari_op2));
                    mem_addr = 0;
                end
                `INS_SLTU: begin
                    out_w_data = (ari_op1 < ari_op2);
                    mem_addr = 0;
                end
                endcase
            end
            `IC_SFT: begin
                case (local_opcode)
                `INS_SLL: begin
                    out_w_data = ari_op1 << ari_op2[4:0];
                    mem_addr = 0;
                end
                `INS_SRL: begin
                    out_w_data = ari_op1 >> ari_op2[4:0];
                    mem_addr = 0;
                end
                `INS_SRA: begin
                    out_w_data = $signed(ari_op1) >>> ari_op2[4:0];
                    mem_addr = 0;
                end
                endcase
            end
            `IC_LGC: begin
                case (local_opcode)
                `INS_XOR: begin
                    out_w_data = ari_op1 ^ ari_op2;
                    mem_addr = 0;
                end
                `INS_OR: begin
                    out_w_data = ari_op1 | ari_op2;
                    mem_addr = 0;
                end
                `INS_AND: begin
                    out_w_data = ari_op1 & ari_op2;
                    mem_addr = 0;
                end
                endcase
            end
            default: begin
                out_w_data = 0;
                mem_addr = 0;
            end
            endcase
        end
    end

endmodule
