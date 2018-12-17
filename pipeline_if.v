//instruction fetch
`timescale 1ns/1ps
`include "defines.v"

module p_if(
    //common input
    input wire rst_in,
    input wire rdy_in,
    //branch
    input wire jump,
    input wire[31:0] next_addr,
    //instruction fetch
    input wire[31:0] inst_in,
    output reg re, 
    output reg[31:0] fetch_addr,
    output reg[2:0] len_in_byte,
    output wire[1:0] port_id,
    //ctrl
    input wire mem_busy,
    input wire mem_done,
    //output
    output reg[31:0] inst_pc,
    output reg[31:0] inst,
    output wire busy_out
);

    assign port_id[0] = 1;
    assign port_id[1] = 0;
    
    reg[31:0] pc;
    reg[31:0] next_pc;
    reg[31:0] local_inst;
    reg state;
    reg is_discarded;

    assign len_in_byte <= 4;

    localparam STATE_IDLE = 0;
    localparam STATE_WAITING_FOR_MC = 1;

    always @ (*) begin
        if (rst_in) begin
            pc <= 0;
            state <= STATE_IDLE;
            next_pc <= 0;
            local_inst <= 0;
            is_discarded <= 0;
            busy_out <= 0;
        end 
        else begin
            if (jump && !is_discarded) begin
                next_pc <= next_addr;
                is_discarded <= 1;
            end
            if (!mem_busy) begin
            /*case (state)
            STATE_IDLE: begin
                read_enable <= 1;
                busy_out <= 1;
                tmp_pc <= pc;
                state <= STATE_FETCH_1;
            end
            STATE_FETCH_1: begin
                local_inst[31:24] <= inst_in;
                busy_out <= 1;
                tmp_pc <= pc + 1;
                read_enable <= 1;
                state <= STATE_FETCH_2;
            end
            STATE_FETCH_2: begin
                local_inst[23:16] <= inst_in;
                busy_out <= 1;
                tmp_pc <= pc + 2;
                read_enable <= 1;
                state <= STATE_FETCH_3;
            end
            STATE_FETCH_3: begin
                local_inst[15:8] <= inst_in;
                busy_out <= 1;
                tmp_pc <= pc + 3;
                read_enable <= 1;
                state <= STATE_FETCH_4;
            end
            STATE_FETCH_4: begin
                local_inst[7:0] <= inst_in;
                tmp_pc <= pc;
                pc <= next_pc;
                if (!is_discarded) begin
                    busy_out <= 0;
                    read_enable <= 0;
                    state <= STATE_IDLE;
                end
                else begin
                    busy_out <= 1;
                    read_enable <= 1;
                    state <= STATE_FETCH_1;
                    is_discarded <= 0;
                end
            end
            endcase*/
                case (state)
                STATE_IDLE: begin
                    re <= 1;
                    fetch_addr <= pc;
                    state <= STATE_WAITING_FOR_MC;
                    busy_out <= 1;
                end
                STATE_WAITING_FOR_MC: begin
                    if (mem_busy) begin
                        busy_out <= 1;
                    end
                    else if (mem_done) begin
                        if (!is_discarded) begin
                            local_inst <= inst_in;
                            re <= 0;
                            fetch_addr <= 0;
                            pc <= next_pc;
                            next_pc <= next_pc + 4;
                            busy_out <= 0;
                            state <= STATE_IDLE;
                        end
                        else begin
                            busy_out <= 1;
                            re <= 1;
                            pc <= next_pc;
                            fetch_addr <= next_pc;
                            next_pc <= next_pc + 4;
                            is_discarded <= 0;
                        end
                    end
                end
                endcase
            end
        end
    end

    assign inst = local_inst;

endmodule