//stall instruction
`include "defines.v"

module stall(
    input wire rst_in,
    input wire stall_if,
    input wire stall_id,
    input wire stall_ex,
    input wire stall_mem,
    output reg[5:0] stall
);
    always @(*) begin 
        if (rst_in) begin
            stall <= 6'b000000;
        end
        else if (stall_if) begin
            stall <= 6'b011111;
        end
        else if (stall_id) begin
            stall <= 6'b001111;
        end
        else if (stall_ex) begin
            stall <= 6'b000111;
        end
        else if (stall_mem) begin
            stall <= 6'b000011;
        end
        else begin
            stall <= 6'b000000;
        end
    end
endmodule
