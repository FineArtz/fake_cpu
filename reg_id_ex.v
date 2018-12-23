//register id/ex
`timescale 1ns/1ps
`include "defines.v"

module r_id_ex(
    //common
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //from id
    input wire[2:0] id_inst_catagory,
    input wire[4:0] id_local_opcode,
    input wire[31:0] id_ari_op1,
    input wire[31:0] id_ari_op2,
    input wire id_we,
    input wire[31:0] id_w_addr,
    input wire[31:0] id_link_addr,
    input wire[31:0] id_offset,
    input wire busy_in,
    //to ex
    output reg[2:0] ex_inst_catagory,
    output reg[4:0] ex_local_opcode,
    output reg[31:0] ex_ari_op1,
    output reg[31:0] ex_ari_op2,
    output reg ex_we,
    output reg[31:0] ex_w_addr,
    output reg[31:0] ex_link_addr,
    output reg[31:0] ex_offset,
    output reg busy_out,
    
    input wire mem_stall
);
    always @ (posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            ex_inst_catagory <= `IC_EMP;
            ex_local_opcode <= `INS_EMP;
            ex_ari_op1 <= 0;
            ex_ari_op2 <= 0;
            ex_we <= 0;
            ex_w_addr <= 0;
            ex_link_addr <= 0;
            ex_offset <= 0;
            busy_out <= 0;
        end
        else if (busy_in) begin
            ex_inst_catagory <= `IC_EMP;
            ex_local_opcode <= `INS_EMP;
            ex_ari_op1 <= 0;
            ex_ari_op2 <= 0;
            ex_we <= 0;
            ex_w_addr <= 0;
            ex_link_addr <= 0;
            ex_offset <= 0;
            busy_out <= 1;
        end
        else if (!mem_stall) begin
            ex_inst_catagory <= id_inst_catagory;
            ex_local_opcode <= id_local_opcode;
            ex_ari_op1 <= id_ari_op1;
            ex_ari_op2 <= id_ari_op2;
            ex_we <= id_we;
            ex_w_addr <= id_w_addr;
            ex_link_addr <= id_link_addr;
            ex_offset <= id_offset;
            busy_out <= 0;
        end
    end

endmodule