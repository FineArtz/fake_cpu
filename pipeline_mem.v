//memory access
`timescale 1ns/1ps
`include "defines.v"

module p_mem(
    //common
    input wire rst_in,
    input wire rdy_in,
    //from ex/mem
    input wire we,
    input wire[31:0] w_addr,
    input wire[31:0] w_data,
    input wire[4:0] opcode,
    input wire[31:0] mem_addr,
    input wire busy_in,
    //memory controller
    output reg[31:0] sl_addr,
    output reg[31:0] s_data,
    input wire[31:0] l_data,
    output reg l_re,
    output reg s_we,
    output reg[2:0] len_in_byte, 
    output wire[1:0] port_id,
    input wire mem_busy,
    input wire mem_done,
    //output
    output reg out_we,
    output reg[31:0] out_w_addr,
    output reg[31:0] out_w_data,
    output wire busy_out
);

    assign port_id[0] = 0;
    assign port_id[1] = 1;
    
    reg state;
    localparam STATE_IDLE = 0;
    localparam STATE_WATING_FOR_MC = 1;

    task send_to_mc:
        input wire _l_re;
        input wire _s_we;
        input wire[31:0] _sl_addr;
        input wire[31:0] _s_data;
        input wire[2:0] _len_in_byte;
        begin
            l_re <= _l_re;
            s_we <= _s_we;
            sl_addr <= _sl_addr;
            s_data <= _s_data;
            len_in_byte <= _len_in_byte;
        end
    endtask

    always @ (*) begin 
        if (rst_in) begin
            state <= STATE_IDLE;
            send_to_mc(0, 0, 0, 0, 0);
            out_we <= 0;
            out_w_addr <= 0;
            out_w_data <= 0;
            busy_out <= 0;
        end
        else if (busy_in) begin
            send_to_mc(0, 0, 0, 0, 0);
            out_we <= 0;
            out_w_addr <= 0;
            out_w_data <= 0;
            busy_out <= 1;
        end
        else begin
            out_we <= we;
            out_w_addr <= w_addr;
            case (state)
            STATE_IDLE: begin
                case (opcode)
                `INS_LB, `INS_LBU: begin
                    send_to_mc(1, 0, mem_addr, 0, 1);
                end
                `INS_LH, `INS_LHU: begin
                    send_to_mc(1, 0, mem_addr, 0, 2);
                end
                `INS_LW: begin
                    send_to_mc(1, 0, mem_addr, 0, 4);
                end
                `INS_SB: begin
                    send_to_mc(0, 1, mem_addr, {24'b0, w_data[7:0]}, 1);
                end
                `INS_SH: begin
                    send_to_mc(0, 1, mem_addr, {16'b0, w_data[15:0]}, 2);
                end
                `INS_SW: begin
                    send_to_mc(0, 1, mem_addr, w_data, 4);
                end
                endcase
                state <= (opcode == `INS_LB || opcode == `INS_LBU || opcode == `INS_LH || opcode == `INS_LHU || opcode == `INS_LW
                       || opcode == `INS_SB || opcode == `INS_SH || opcode == `INS_SW) ? STATE_WATING_FOR_MC : STATE_IDLE;
                busy_out <= 1;
            end
            STATE_WATING_FOR_MC: begin
                if (mem_busy) begin
                    busy_out <= 1;
                end
                else if (mem_done) begin
                    case (opcode)
                    `INS_LB: begin
                        out_w_data <= {24{l_data[7]}, l_data[7:0]};
                    end
                    `INS_LBU: begin
                        out_w_data <= {24'b0, l_data[7:0]};
                    end
                    `INS_LH: begin
                        out_w_data <= {16{l_data[15]}, l_data[15:0]};
                    end
                    `INS_LHU: begin
                        out_w_data <= {16'b0, l_data[15:0]};
                    end
                    `INS_LW: begin
                        out_w_data <= l_data;
                    end
                    default:
                        out_w_data <= 0;
                    end
                    endcase
                    busy_out <= 0;
                    state <= STATE_IDLE;
                    send_to_mc(0, 0, 0, 0, 0);
                end
            end
            endcase
        end
    end
                
endmodule
