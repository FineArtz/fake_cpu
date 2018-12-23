//register ex/mem
`timescale 1ns/1ps
`include "defines.v"

module r_ex_mem(
    //common
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //from ex
    input wire ex_we,
    input wire[31:0] ex_w_addr,
    input wire[31:0] ex_w_data,
    input wire[4:0] ex_opcode,
    input wire[31:0] ex_mem_addr,
    input wire busy_in,
    //to mem
    output reg mem_we,
    output reg[31:0] mem_w_addr,
    output reg[31:0] mem_w_data,
    output reg[4:0] mem_opcode,
    output reg[31:0] mem_mem_addr,
    output reg busy_out,
    
    input wire mem_stall
);

    always @ (posedge clk_in or posedge rst_in) begin 
        if (rst_in) begin
            mem_we <= 0;
            mem_w_addr <= 0;
            mem_w_data <= 0;
            mem_opcode <= 0;
            mem_mem_addr <= 0;
            busy_out <= 0;
        end
        else if (busy_in) begin
            mem_we <= 0;
            mem_w_addr <= 0;
            mem_w_data <= 0;
            mem_opcode <= 0;
            mem_mem_addr <= 0;
            busy_out <= 1;
        end
        else if (!mem_stall) begin
            mem_we <= ex_we;
            mem_w_addr <= ex_w_addr;
            mem_w_data <= ex_w_data;
            mem_opcode <= ex_opcode;
            mem_mem_addr <= ex_mem_addr;
            busy_out <= 0;
        end
    end

endmodule
