// memory controller
`timescale 1ns/1ps

module mc(
    //common
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,
    //memory access
    input wire[1:0] re,
    input wire[1:0] we,
    input wire[3:0] port_id, //1 for if, 2 for mem
    input wire[63:0] addr,
    input wire[63:0] w_data,
    output wire[63:0] r_data,
    input wire[5:0] len_in_byte,
    //cpu interface
    output reg mem_wr, //1 for write
    output reg[7:0] mem_w_data,
    input wire[7:0] mem_r_data,
    output reg[31:0] mem_addr,
    //ctrl
    output reg[1:0] state_busy,
    output reg[1:0] state_done
);

    //localize
    wire local_re[1:0];
    wire local_we[1:0];
    wire[1:0] local_port_id[1:0];
    wire[31:0] local_addr[1:0];
    wire[31:0] local_w_data[1:0];
    reg[31:0] local_r_data[1:0];
    wire[2:0] local_len_in_byte[1:0];

    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin
            assign local_re[i] = re[i];
            assign local_we[i] = we[i];
            assign local_port_id[i] = port_id[2 * i + 1 : 2 * i];
            assign local_addr[i] = addr[32 * i + 31 : 32 * i];
            assign local_w_data[i] = w_data[32 * i + 31 : 32 * i];
            assign r_data[32 * i + 31 : 32 * i] = local_r_data[i];
            assign local_len_in_byte[i] = len_in_byte[3 * i + 2 : 3 * i];
        end
    endgenerate

    wire[1:0] rw_flag[1:0]; //1 for write, 2 for read
    assign rw_flag[0] = {local_re[0], local_we[0]};
    assign rw_flag[1] = {local_re[1], local_we[1]};

    reg[1:0] pending_rw_flag[1:0];
    reg[31:0] pending_addr[1:0];
    reg[31:0] pending_w_data[1:0];
    reg[2:0] pending_data_len[1:0];
    reg[1:0] pending_port[1:0];
    reg[1:0] wait_port = 2'b10;
    reg[1:0] serv_port = 2'b10;
    
    localparam NOPORT = 2;

    task set_pending;
        input wire p_id;
        begin
            if (rw_flag[p_id] != 0 && state_busy[p_id] == 0) begin
                pending_rw_flag[p_id] <= rw_flag[p_id];
                pending_addr[p_id] <= local_addr[p_id];
                pending_w_data[p_id] <= local_w_data[p_id];
                pending_data_len[p_id] <= local_len_in_byte[p_id];
                pending_port[p_id] <= p_id;
                state_busy[p_id] <= 1;
                if (wait_port == NOPORT) begin
                    wait_port <= p_id;
                end
            end
        end
    endtask

    task send_request;
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
    localparam STATE_WAIT_FOR_RECV_5 = 5;
    reg[2:0] state;
    reg[31:0] tmp_r_data;
    integer j;

    always @ (posedge clk_in or posedge rst_in) begin
        state_done[0] <= 0;
        state_done[1] <= 0;
        if (rst_in) begin
            state <= STATE_IDLE;
            state_busy[0] <= 0;
            state_busy[1] <= 0;
            local_r_data[0] <= 0;
            local_r_data[1] <= 0;
            wait_port <= NOPORT;
            serv_port <= NOPORT;
            tmp_r_data <= 0;
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
                    if (j != wait_port) begin
                        set_pending(j);
                    end
                end
                if (wait_port != NOPORT) begin
                    if (pending_rw_flag[wait_port] != 0) begin
                        /*case (pending_data_len[wait_port])
                        1: begin
                            send_request(pending_rw_flag[wait_port], pending_addr[wait_port], 
                            pending_w_data[wait_port][7:0]);
                        end
                        2: begin
                            send_request(pending_rw_flag[wait_port], pending_addr[wait_port], 
                            pending_w_data[wait_port][7:0]);
                        end
                        4: begin
                            
                        end
                        endcase*/
                        send_request(pending_rw_flag[wait_port], pending_addr[wait_port], 
                        pending_w_data[wait_port][7:0]);
                        serv_port <= wait_port;
                        state_busy[wait_port] <= 1;
                        state <= STATE_WAIT_FOR_RECV_1;
                    end
                end
            end
            STATE_WAIT_FOR_RECV_1: begin
                case (pending_data_len[serv_port])
                1: begin
                    state_busy[pending_port[serv_port]] <= 1;
                    state_done[pending_port[serv_port]] <= 0;
                    state <= STATE_WAIT_FOR_RECV_2;
                end
                2: begin
                    state_busy[pending_port[serv_port]] <= 1;
                    state_done[pending_port[serv_port]] <= 0;
                    send_request(pending_rw_flag[serv_port], pending_addr[serv_port] + 1, 
                    pending_w_data[serv_port][15:8]);
                    state <= STATE_WAIT_FOR_RECV_2;
                end
                4: begin
                    state_busy[pending_port[serv_port]] <= 1;
                    state_done[pending_port[serv_port]] <= 0;
                    send_request(pending_rw_flag[serv_port], pending_addr[serv_port] + 1, 
                    pending_w_data[serv_port][15:8]);
                    state <= STATE_WAIT_FOR_RECV_2;
                end
                endcase
            end
            STATE_WAIT_FOR_RECV_2: begin
                case (pending_data_len[serv_port])
                1: begin
                    tmp_r_data[7:0] <= mem_r_data;
                    local_r_data[pending_port[serv_port]][7:0] <= mem_r_data;
                    state_busy[pending_port[serv_port]] <= 0;
                    state_done[pending_port[serv_port]] <= 1;
                    pending_rw_flag[serv_port] <= 0;
                    serv_port <= NOPORT;
                    if (wait_port == 0 && pending_rw_flag[1] != 0) begin
                        wait_port <= 1;
                    end
                    else if (wait_port == 1 && pending_rw_flag[0] != 0) begin
                        wait_port <= 0;
                    end
                    else begin
                        wait_port <= NOPORT;
                    end
                    state <= STATE_IDLE;
                end
                2: begin
                    tmp_r_data[7:0] <= mem_r_data;
                    state_busy[pending_port[serv_port]] <= 1;
                    state_done[pending_port[serv_port]] <= 0;
                    state <= STATE_WAIT_FOR_RECV_3;
                end
                4: begin
                    tmp_r_data[7:0] <= mem_r_data;
                    state_busy[pending_port[serv_port]] <= 1;
                    state_done[pending_port[serv_port]] <= 0;
                    send_request(pending_rw_flag[serv_port], pending_addr[serv_port] + 2, 
                    pending_w_data[serv_port][23:16]);
                    state <= STATE_WAIT_FOR_RECV_3;
                end
                endcase
            end
            STATE_WAIT_FOR_RECV_3: begin
                case (pending_data_len[serv_port])
                2: begin
                    tmp_r_data[15:8] <= mem_r_data;
                    local_r_data[pending_port[serv_port]][7:0] <= tmp_r_data[7:0];
                    local_r_data[pending_port[serv_port]][15:8] <= mem_r_data;
                    state_busy[pending_port[serv_port]] <= 0;
                    state_done[pending_port[serv_port]] <= 1;
                    pending_rw_flag[serv_port] <= 0;
                    serv_port <= NOPORT;
                    if (wait_port == 0 && pending_rw_flag[1] != 0) begin
                        wait_port <= 1;
                    end
                    else if (wait_port == 1 && pending_rw_flag[0] != 0) begin
                        wait_port <= 0;
                    end
                    else begin
                        wait_port <= NOPORT;
                    end
                    state <= STATE_IDLE;
                end
                4: begin
                    tmp_r_data[15:8] <= mem_r_data;
                    state_busy[pending_port[serv_port]] <= 1;
                    state_done[pending_port[serv_port]] <= 0;
                    send_request(pending_rw_flag[serv_port], pending_addr[serv_port] + 3, 
                    pending_w_data[serv_port][31:24]);
                    state <= STATE_WAIT_FOR_RECV_4;
                end
                endcase
            end
            STATE_WAIT_FOR_RECV_4: begin
                tmp_r_data[23:16] <= mem_r_data;
                state_busy[pending_port[serv_port]] <= 1;
                state_done[pending_port[serv_port]] <= 0;
                state <= STATE_WAIT_FOR_RECV_5;
            end
            STATE_WAIT_FOR_RECV_5: begin
                tmp_r_data[31:24] <= mem_r_data;
                local_r_data[pending_port[serv_port]][23:0] <= tmp_r_data[23:0];
                local_r_data[pending_port[serv_port]][31:24] <= mem_r_data;
                state_busy[pending_port[serv_port]] <= 0;
                state_done[pending_port[serv_port]] <= 1;
                pending_rw_flag[serv_port] <= 0;
                serv_port <= NOPORT;
                if (wait_port == 0 && pending_rw_flag[1] != 0) begin
                    wait_port <= 1;
                end
                else if (wait_port == 1 && pending_rw_flag[0] != 0) begin
                    wait_port <= 0;
                end
                else begin
                    wait_port <= NOPORT;
                end
                state <= STATE_IDLE;
            end
            endcase
        end
    end

endmodule
