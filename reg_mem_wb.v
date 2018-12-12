//register mem/wb
`timescale 1ns/1ps
`include "defines.v"

module r_mem_wb(
    //common
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //from mem
    input wire mem_we,
    input wire[31:0] mem_w_addr,
    input wire[31:0] mem_w_data,
    input wire busy_in,
    //to wb
    output reg wb_we,
    output reg[31:0] wb_w_addr,
    output reg[31:0] wb_w_data,
    output wire busy_out
);

    always @ (posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            wb_we <= 0;
            wb_w_addr <= 0;
            wb_w_data <= 0;
            busy_out <= 0;
        end
        else if (busy_in) begin
            wb_we <= 0;
            wb_w_addr <= 0;
            wb_w_data <= 0;
            busy_out <= 1;
        end
        else begin
            wb_we <= mem_we;
            wb_w_addr <= mem_w_addr;
            wb_w_data <= mem_w_data;
            busy_out <= 0;
        end
    end
    
endmodule
