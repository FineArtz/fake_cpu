//register if/id
`timescale 1ns/1ps
`include "defines.v"

module r_if_id(
    //common
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //from if
    input wire[31:0] if_inst_pc,
    input wire[31:0] if_inst,
    input wire busy_in,
    //to id
    output reg[31:0] id_inst_pc,
    output reg[31:0] id_inst,
    output reg busy_out,
    
    input wire mem_stall
);

    always @ (posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            id_inst_pc <= 0;
            id_inst <= 0;
            busy_out <= 0;
        end
        else if (busy_in) begin
            id_inst_pc <= 0;
            id_inst <= 0;
            busy_out <= 1;
        end 
        else if (!mem_stall && rdy_in) begin  
            id_inst_pc <= if_inst_pc;
            id_inst <= if_inst;
            busy_out <= 0;
        end
    end

endmodule
