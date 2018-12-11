//regfile
`timescale 1ns/1ps
`include "defines.v"

module regfile(
    //common
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //read
    input wire re1,
    input wire[31:0] r_addr1,
    output reg[31:0] r_data1,
    input wire re2,
    input wire[31:0] r_addr2,
    output reg[31:0] r_data2,
    //write
    input wire we,
    input wire[31:0] w_addr,
    input wire[31:0] w_data
);

    reg[31:0] regf[0:31];
    assign regf[0] = 32'b0000_0000_0000_0000;

    task reset_regf:
        begin
            integer i;
            for (i = 0; i < 32; i = i + 1) begin 
                regf[i] <= 0;
            end
        end
    endtask

    always @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin 
            reset_regf();
            r_data1 <= 0;
            r_data2 <= 0;
        end
        else if (we) begin
            regf[w_addr] <= w_data;
        end
    end

    always @(*) begin
        if (!re1 || r_addr1 == 0) begin
            r_data1 <= 0;
        end
        else if (we && w_addr == r_addr1) begin
            r_data1 <= w_data;
        end
        else begin
            r_data1 <= regf[r_addr1];
        end
    end

    always @(*) begin
        if (!re2 || r_addr2 == 0) begin
            r_data1 <= 0;
        end
        else if (we && w_addr == r_addr2) begin
            r_data2 <= w_data;
        end
        else begin
            r_data2 <= regf[r_addr2];
        end
    end

endmodule
