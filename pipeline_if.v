//instruction fetch
`timescale 1ns/1ps

module p_if(
    //common input
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //branch
    input wire jump,
    input wire[31:0] next_addr,
    //instruction fetch
    input wire[31:0] inst_in,
    output reg re, 
    output reg[31:0] fetch_addr,
    output wire[2:0] len_in_byte,
    output wire[1:0] port_id,
    //ctrl
    input wire mem_busy,
    input wire mem_done,
    //output
    (*mark_debug = "true"*) output reg[31:0] inst_pc,
    (*mark_debug = "true"*) output wire[31:0] inst,
    output reg busy_out,
    
    input wire mem_stall
);

    assign port_id[0] = 1;
    assign port_id[1] = 0;
    
    reg[31:0] pc;
    reg[31:0] next_pc;
    reg[31:0] tmp_pc;
    reg[31:0] local_inst;
    reg[1:0] state;
    reg refetch_flag;
    reg is_discarded;
    
    assign len_in_byte = 4;

    localparam STATE_IDLE = 0;
    localparam STATE_WAITING_FOR_MC = 1;
    localparam STATE_WAITING_FOR_RF = 2;

    always @ (*) begin
        if (rst_in) begin
            state = STATE_IDLE;
            local_inst = 0;
            busy_out = 0;
            refetch_flag = 0;
            tmp_pc = 0;
            re = 0;
            fetch_addr = 0;
            inst_pc = 0;
        end 
        else begin
            if (jump && next_addr != 0 && is_discarded && rdy_in) begin
                tmp_pc = next_addr;
            end
            if (!mem_stall && rdy_in) begin
                if (!mem_busy) begin
                    case (state)
                    STATE_IDLE: begin
                        re = 1;
                        fetch_addr = pc;
                        state = STATE_WAITING_FOR_MC;
                        busy_out = 1;
                    end
                    STATE_WAITING_FOR_MC: begin
                        if (mem_busy) begin
                            busy_out = 1;
                        end
                        else if (mem_done) begin
                            if (!is_discarded) begin
                                local_inst = inst_in;
                                inst_pc = pc;
                                re = 0;
                                fetch_addr = 0;
                                tmp_pc = next_pc + 4;
                                busy_out = 0;
                                state = STATE_IDLE;
                            end
                            else begin
                                busy_out = 1;
                                re = 1;
                                fetch_addr = next_pc;
                                tmp_pc = next_pc;
                                refetch_flag = 1;
                                state = STATE_WAITING_FOR_RF;
                            end
                        end
                        else begin
                        end
                    end
                    STATE_WAITING_FOR_RF: begin
                        if (mem_busy) begin
                            busy_out = 1;
                        end
                        else if (refetch_flag) begin
                            busy_out = 1;
                        end
                        else if (mem_done) begin
                            local_inst = inst_in;
                            inst_pc = pc;
                            re = 0;
                            fetch_addr = 0;
                            tmp_pc = next_pc + 4;
                            busy_out = 0;
                            state = STATE_IDLE;
                        end
                    end
                    default: begin
                    end
                    endcase
                end
                else begin
                    refetch_flag = 0;
                end
            end
            else begin
            end
        end
    end

    assign inst = local_inst;

    always @ (posedge clk_in) begin
        if (rst_in) begin
            next_pc <= 0;
            pc <= 0;
            is_discarded <= 0;
        end
        else  if (jump && next_addr != 0) begin
            is_discarded <= 1;
        end
        else if (state == STATE_WAITING_FOR_RF) begin
            is_discarded <= 0;
        end
        if (!mem_stall && rdy_in) begin
            next_pc <= tmp_pc;
            pc <= tmp_pc;
        end
    end
    
endmodule