// memory controller
`timescale 1ns/1ps

module mc(
    //common
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //memory access
    input wire re[1:0],
    input wire we[1:0],
    input wire[1:0] port_id[1:0], //1 for if, 2 for mem
    input wire[31:0] addr[1:0],
    input wire[31:0] w_data[1:0],
    output reg[31:0] r_data[1:0],
    input wire[2:0] len_in_byte[1:0],
    //cpu interface
    output reg mem_wr, //1 for write
    output reg[7:0] mem_w_data,
    input wire[7:0] mem_r_data,
    output reg[31:0] mem_addr,
    //ctrl
    output reg state_busy[1:0],
    output reg state_done[1:0]
);

    wire[1:0] rw_flag[1:0]; //1 for write, 2 for read
    assign rw_flag[0] = {re[0], we[0]};
    assign rw_flag[1] = {re[1], we[1]};

    reg[1:0] pending_rw_flag[1:0];
    reg[31:0] pending_addr[1:0];
    reg[31:0] pending_w_data[1:0];
    reg[2:0] pending_data_len[1:0];
    reg[1:0] pending_port[1:0] = 2'b00;
    reg[1:0] wait_port = 2'b10;
    reg[1:0] serv_port = 2'b10;
    
    localparam NOPORT = 2;

    task set_pending:
        input wire p_id;
        begin
            if (local_rw_flag[p_id] != 0 && state_busy[p_id] == 0) begin
                pending_rw_flag[p_id] <= local_rw_flag[p_id];
                pending_addr[p_id] <= addr[p_id];
                pending_w_data[p_id] <= w_data[p_id];
                pending_data_len[p_id] <= len_in_byte[p_id];
                pending_port[p_id] <= p_id;
                state_busy[p_id] <= 1;
            end
        end
    endtask

    task send_request:
        input wire[1:0] in_flag;
        input wire[31:0] in_addr;
        input wire[7:0] in_w_data;
        begin
            if (in_flag == 1) begin //write
                mem_wr <= 1;
                mem_addr <= in_addr;
                mem_w_data <= in_w_data;
            end
            else if (in_flag == 2) begin //read
                mem_wr <= 0;
                mem_addr <= in_addr;
            end
        end
    endtask

    localparam STATE_IDLE = 0;
    localparam STATE_WAIT_FOR_RECV_1 = 1;
    localparam STATE_WAIT_FOR_RECV_2 = 2;
    localparam STATE_WAIT_FOR_RECV_3 = 3;
    localparam STATE_WAIT_FOR_RECV_4 = 4;
    reg[2:0] state;
    reg[31:0] local_r_data;
    integer j;

    always @ (posedge clk_in or posedge rst_in) begin
        state_done <= 0;
        if (rst_in) begin
            state <= STATE_IDLE;
            state_busy <= 0;
            r_data[0] <= 0;
            r_data[1] <= 1;
            wait_port <= NOPORT;
            serv_port <= NOPORT;
            local_r_data <= 0;
            for (j = 0; j < 2; j = j + 1) begin
                pending_rw_flag[j] <= 0;
                pending_addr[j] <= 0;
                pending_w_data[j] <= 0;
                pending_data_len[j] <= 0;
                pending_port[j] <= 0;
            end
        end
        else begin
            if (state != STATE_IDLE) begin
                for (j = 0; j < 2; j = j + 1) begin
                    set_pending(j);
                end
            end
            case (state)
            STATE_IDLE: begin
                for (j = 0; j < 2; j = j + 1) begin
                    if (j != next_id) begin
                        set_pending(j);
                    end
                end
                if (wait_port != NOPORT) begin
                    if (pending_rw_flag[wait_port] != 0) begin
                        send_request(pending_rw_flag[wait_port], pending_addr[wait_port], 
                        pending_w_data[wait_port][pending_data_len[serv_port] * 8 - 1 : pending_data_len[serv_port] * 8 - 8]);
                        serv_port <= wait_port;
                        state_busy[wait_port] <= 1;
                        state <= STATE_WAIT_FOR_RECV_1;
                    end
                end
            end
            STATE_WAIT_FOR_RECV_1: begin
                local_r_data[pending_data_len[serv_port] * 8 - 1 : pending_data_len[serv_port] * 8 - 8] <= mem_r_data;
                if (pending_data_len[serv_port] == 1) begin
                    r_data[pending_port[serv_port]] <= local_r_data;
                    state_busy[pending_port[serv_port]] <= 0;
                    state_done[pending_port[serv_port]] <= 1;
                    pending_rw_flag[serv_port] <= 0;
                    serv_port <= NOPORT;
                    if (wait_port == 0 && pending_rw_flag[1] != 0) begin
                        wait_port <= 1;
                    else if (wait_port == 1 && pending_rw_flag[0] != 0) begin
                        wait_port <= 0;
                    else begin
                        wait_port <= NOPORT;
                    end
                    state <= STATE_IDLE;
                end
                else begin
                    state_busy[pending_port[serv_port]] <= 1;
                    state_done[pending_port[serv_port]] <= 0;
                    send_request(pending_rw_flag[serv_port], pending_addr[serv_port] + 1, 
                    pending_w_data[serv_port][pending_data_len[serv_port] * 8 - 9 : pending_data_len[serv_port] * 8 - 16])
                    state <= STATE_WAIT_FOR_RECV_2;
                end
            end
            STATE_WAIT_FOR_RECV_2: begin
                local_r_data[pending_data_len[serv_port] * 8 - 9 : pending_data_len[serv_port] * 8 - 16] <= mem_r_data;
                if (pending_data_len[serv_port] == 2) begin
                    r_data[pending_port[serv_port]] <= local_r_data;
                    state_busy[pending_port[serv_port]] <= 0;
                    state_done[pending_port[serv_port]] <= 1;
                    pending_rw_flag[serv_port] <= 0;
                    serv_port <= NOPORT;
                    if (wait_port == 0 && pending_rw_flag[1] != 0) begin
                        wait_port <= 1;
                    else if (wait_port == 1 && pending_rw_flag[0] != 0) begin
                        wait_port <= 0;
                    else begin
                        wait_port <= NOPORT;
                    end
                    state <= STATE_IDLE;
                end
                else begin
                    state_busy[pending_port[serv_port]] <= 1;
                    state_done[pending_port[serv_port]] <= 0;
                    send_request(pending_rw_flag[serv_port], pending_addr[serv_port] + 2, 
                    pending_w_data[serv_port][pending_data_len[serv_port] * 8 - 17 : pending_data_len[serv_port] * 8 - 24])
                    state <= STATE_WAIT_FOR_RECV_3;
                end
            end
            STATE_WAIT_FOR_RECV_3: begin
                local_r_data[pending_data_len[serv_port] * 8 - 17 : pending_data_len[serv_port] * 8 - 24] <= mem_r_data;
                state_busy[pending_port[serv_port]] <= 1;
                state_done[pending_port[serv_port]] <= 0;
                send_request(pending_rw_flag[serv_port], pending_addr[serv_port] + 3, 
                pending_w_data[serv_port][pending_data_len[serv_port] * 8 - 25 : pending_data_len[serv_port] * 8 - 32])
                state <= STATE_WAIT_FOR_RECV_4;
            end
            STATE_WAIT_FOR_RECV_4: begin
                local_r_data[pending_data_len[serv_port] * 8 - 25 : pending_data_len[serv_port] * 8 - 32] <= mem_r_data;
                r_data[pending_port[serv_port]] <= local_r_data;
                state_busy[pending_port[serv_port]] <= 0;
                state_done[pending_port[serv_port]] <= 1;
                pending_rw_flag[serv_port] <= 0;
                serv_port <= NOPORT;
                if (wait_port == 0 && pending_rw_flag[1] != 0) begin
                    wait_port <= 1;
                else if (wait_port == 1 && pending_rw_flag[0] != 0) begin
                    wait_port <= 0;
                else begin
                    wait_port <= NOPORT;
                end
                state <= STATE_IDLE;
            end
            endcase
        end
    end

endmodule
