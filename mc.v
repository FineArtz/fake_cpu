// memory controller
`timescale 1ns/1ps

module mc(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    output reg is_sending,
    output reg[31:0] s_data,
    output reg[4:0] s_len,

    output reg is_recving,
    input wire[31:0] r_data,
    input wire[4:0] r_len,

    input wire se,
    input wire re,

    input wire[3:0] rw_flag,    //write: 1, read: 2
    input wire[63:0] addr,      //address
    output wire[63:0] r_data,   //read data
    input wire[63:0] w_data,    //write data
    input wire[7:0] w_mask,     //writing mask

    output reg[1:0] state_busy,
    output reg[1:0] state_done
);
    wire[1:0] local_rw_flag[1:0];
    wire[31:0] local_addr[1:0];
    reg[31:0] local_r_data[1:0];
    wire[31:0] local_w_data[1:0];
    wire[7:0] local_w_mask[1:0];

    //localize
    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin
            assign local_rw_flag[i] = rw_flag[(i + 1) * 2 - 1 : i * 2];
            assign local_addr[i] = addr[(i + 1) * 32 - 1 : i * 32];
            assign r_data[(i + 1) * 32 - 1 : i * 32] = local_r_data[i];
            assign local_w_data[i] = w_data[(i + 1) * 32 - 1 : i * 32];
            assign local_w_mask[i] = w_mask[(i + 1) * 8 - 1 : i * 8];
        end
    endgenerate
    
    reg[1:0] pending_flag[1:0];
    reg[31:0] pending_addr[1:0];
    reg[31:0] pending_w_data[1:0];
    reg[31:0] pending_w_mask[1:0];
    
    localparam NOPORT = 3;
    wire[1:0] wait_port;
    reg[1:0] serv_port;
    wire[1:0] tmp_wait_port[1:0];
    assign wait_port = tmp_wait_port[1];

    generate
        if (local_rw_flag[0] == 0 && pending_flag[0] == 0) begin
            assign tmp_wait_port[0] = NOPORT;
        else
            assign tmp_wait_port[0] = 0;
        end
        for (i = 1; i < 2; i = i + 1) begin
            if (tmp_wait_port[i - 1] != NOPORT || (local_rw_flag[i] == 0 && pending_flag[i] == 0)) begin
                assign tmp_wait_port[i] = tmp_wait_port[i - 1];
            else
                assign tmp_wait_port[i] = i;
            end
        end
    endgenerate 

    task set_pending:
        input wire[1:0] p_id;
        begin
            if (local_rw_flag[p_id] != 0 && state_busy[p_id] == 0) begin
                state_busy[p_id] <= 1;
                pending_flag[p_id] <= local_rw_flag[p_id];
                pending_addr[p_id] <= local_addr[p_id];
                pending_w_data[p_id] <= local_w_data[p_id];
                pending_w_mask[p_id] <= local_w_mask[p_id];
            end
        end
    endtask

    task send_request:
        input wire[1:0] in_flag;
        input wire[31:0] in_addr;
        input wire[31:0] in_w_data;
        input wire{7:0} in_w_mask;
        begin
            if (in_flag == 1) begin //write
                s_data <= {1'b0, in_addr};
                s_len <= 5;
                is_sending <= 1;
            end
            else if (in_flag == 2) begin //read
                s_data <= {1'b1, in_w_mask, in_addr, in_w_data};
                s_len <= 9;
                is_sending <= 1;
            end
        end
    endtask

    localparam STATE_IDLE = 0;
    localparam STATE_WAIT_FOR_RECV = 1;
    reg state;
    integer j;

    always @(posedge clk_in or posedge rst_in) begin
        is_sending <= 0;
        is_recving <= 0;
        state_done <= 0;
        if (rst_in) begin
            state <= STATE_IDLE;
            s_data <= 0;
            s_len <= 0;
            serv_port <= NOPORT;
            state_busy <= 0;
            for (j = 0; j < 2; j = j + 1) begin
                r_data[j] <= 0;
                pending_flag[j] <= 0;
                pending_addr[j] <= 0;
                pending_w_data[j] <= 0;
                pending_w_mask[j] <= 0;
            end
        end
        else begin
            if (state != STATE_IDLE) begin
                for (j = 0; j < 2; j = j + 1) begin
                    set_pending(i);
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
                    if (se) begin
                        if (pending_flag[wait_port] != 0) begin
                            send_request(
                                pending_flag[wait_port], 
                                pending_addr[wait_port], 
                                pending_w_data[wait_port], 
                                pending_w_mask[wait_port]
                            );
                            if (rw_flag[wait_port] == 2) begin //read
                                pending_flag[wait_port] <= 0;
                                state_busy[wait_port] <= 0;
                                state_done[wait_port] <= 1;
                            end
                            else begin
                                serv_port <= wait_port;
                                state_busy[wait_port] <= 1;
                                state <= STATE_WAIT_FOR_RECV;
                            end
                        end
                    end
                    else begin
                        if (rw_flag[wait_port] != 0) begin
                            set_pending(wait_port);
                        end
                    end
                end
            end
            STATE_WAIT_FOR_RECV: begin
                if (re) begin
                    is_recving <= 1;
                    local_r_data[serv_port] <= r_data[31:0];
                    state_busy[serv_port] <= 0;
                    state_done[serv_port] <= 1;
                    pending_flag[serv_port] <= 0;
                    serv_port = NOPORT;
                    state <= STATE_IDLE;
                end
            end
            endcase
        end
    end
endmodule