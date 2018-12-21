// RISCV32I CPU top module
// port modification allowed for debugging purposes

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
	input  wire					 rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

    //memory controller to cpu interface
    wire mc_mem_wr;
    wire[7:0] mc_mem_r_data;
    wire[7:0] mc_mem_w_data;
    wire[31:0] mc_mem_addr; 

    assign mem_wr = mc_mem_wr;
    assign mc_mem_r_data = mem_din;
    assign mem_dout = mc_mem_w_data;
    assign mem_a = mc_mem_addr;

    //memory controller to IF
    wire if_re;
    wire[31:0] if_inst_in;
    wire[31:0] if_addr;
    wire[2:0] if_len_in_byte;
    wire[1:0] if_port_id;
    wire if_mem_busy;
    wire if_mem_done;

    //memory controller to MEM
    wire mem_re;
    wire mem_we;
    wire[31:0] mem_w_data;
    wire[31:0] mem_r_data;
    wire[31:0] mem_addr;
    wire[2:0] mem_len_in_byte;
    wire[1:0] mem_port_id;
    wire mem_mem_busy;
    wire mem_mem_done;

    //memory controller
    wire[1:0] mc_re;
    wire[1:0] mc_we;
    wire[3:0] mc_port_id;
    wire[63:0] mc_addr;
    wire[63:0] mc_w_data;
    wire[63:0] mc_r_data;
    wire[5:0] mc_len_in_byte;
    wire[1:0] mc_busy;
    wire[1:0] mc_done;

    assign mc_re[0] = if_re;
    assign mc_re[1] = mem_re;
    assign mc_we[0] = 0;
    assign mc_we[1] = mem_we;
    assign mc_port_id[1:0] = if_port_id;
    assign mc_port_id[3:2] = mem_port_id;
    assign mc_addr[31:0] = if_addr;
    assign mc_addr[63:32] = mem_addr;
    assign mc_w_data[31:0] = 0;
    assign mc_w_data[63:32] = mem_w_data;
    assign if_inst_in = mc_r_data[31:0];
    assign mem_r_data = mc_r_data[63:32];
    assign mc_len_in_byte[2:0] = if_len_in_byte;
    assign mc_len_in_byte[5:3] = mem_len_in_byte;
    assign if_mem_busy = mc_busy[0];
    assign mem_mem_busy = mc_busy[1];
    assign if_mem_done = mc_done[0];
    assign mem_mem_done = mc_done[1];

    mc mc0(
        .clk_in(clk_in), 
        .rst_in(rst_in), 
        .rdy_in(rdy_in),
        .re(mc_re), 
        .we(mc_we), 
        .port_id(mc_port_id),
        .addr(mc_addr),
        .w_data(mc_w_data), 
        .r_data(mc_r_data),
        .len_in_byte(mc_len_in_byte),
        .mem_wr(mc_mem_wr), 
        .mem_w_data(mc_mem_w_data), 
        .mem_r_data(mc_mem_r_data),
        .mem_addr(mc_mem_addr),
        .state_busy(mc_busy), 
        .state_done(mc_done)
    );

    // IF to IF/ID
    wire[31:0] if_inst_pc;
    wire[31:0] if_inst;
    wire if_busy_out;

    // IF/ID to ID
    wire[31:0] id_inst_pc;
    wire[31:0] id_inst;
    wire id_busy_in;

    // ID to Regfile
    wire id_re1;
    wire[31:0] id_r_addr1;
    wire[31:0] id_r_data1;
    wire id_re2;
    wire[31:0] id_r_addr2;
    wire[31:0] id_r_data2;

    // ID to IF
    wire jump;
    wire[31:0] next_addr;
    
    // ID to ID/EX
    wire[2:0] id_inst_catagory;
    wire[4:0] id_local_opcode;
    wire[31:0] id_ari_op1;
    wire[31:0] id_ari_op2;
    wire id_we;
    wire[31:0] id_w_addr;
    wire[31:0] id_link_addr;
    wire[31:0] id_offset;
    wire id_busy_out;

    // ID/EX to EX
    wire[2:0] ex_inst_catagory;
    wire[4:0] ex_local_opcode;
    wire[31:0] ex_ari_op1;
    wire[31:0] ex_ari_op2;
    wire ex_we;
    wire[31:0] ex_w_addr;
    wire[31:0] ex_link_addr;
    wire[31:0] ex_offset;
    wire ex_busy_in;

    // EX to EX/MEM
    wire ex_out_we;
    wire[31:0] ex_out_w_addr;
    wire[31:0] ex_out_w_data;
    wire[4:0] ex_out_opcode;
    wire[31:0] ex_out_mem_addr;
    wire ex_busy_out;

    // EX/MEM to MEM
    wire mem_mem_we;
    wire[31:0] mem_mem_w_addr;
    wire[31:0] mem_mem_w_data;
    wire[4:0] mem_mem_opcode;
    wire[31:0] mem_mem_addr;
    wire mem_busy_in;

    // MEM to MEM/WB
    wire mem_out_we;
    wire[31:0] mem_out_w_addr;
    wire[31:0] mem_out_w_data;
    wire mem_busy_out;

    // MEM/WB to Regfile
    wire wb_we;
    wire[31:0] wb_w_addr;
    wire[31:0] wb_w_data;

    regfile regfile0(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .re1(id_re1),
        .r_addr1(id_r_addr1),
        .r_data1(id_r_data1),
        .re2(id_re2),
        .r_addr2(id_r_addr2),
        .r_data2(id_r_data2),
        .we(wb_we),
        .w_addr(wb_w_addr),
        .w_data(wb_w_data)
    );

    p_if p_if0(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .jump(jump),
        .next_addr(next_addr),
        .inst_in(if_inst_in),
        .re(if_re),
        .fetch_addr(if_addr),
        .len_in_byte(if_len_in_byte),
        .port_id(if_port_id),
        .mem_busy(if_mem_busy),
        .mem_done(if_mem_done),
        .inst_pc(if_inst_pc),
        .inst(if_inst),
        .busy_out(if_busy_out)
    );

    r_if_id r_if_id0(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .if_inst_pc(if_inst_pc),
        .if_inst(if_inst),
        .busy_in(if_busy_out),
        .id_inst_pc(id_inst_pc),
        .id_inst(id_inst),
        .busy_out(id_busy_in)
    );

    p_id p_id0(
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .inst_pc(id_inst_pc),
        .inst(id_inst),
        .busy_in(id_busy_in),
        .re1(id_re1),
        .r_addr1(id_r_addr1),
        .re2(id_re2),
        .r_addr2(id_r_addr2),
        .r_data1(id_r_data1),
        .r_data2(id_r_data2),
        .ex_we(ex_out_we),
        .ex_w_addr(ex_out_w_addr),
        .ex_w_data(ex_out_w_data),
        .ex_is_loading(ex_busy_out),
        .mem_we(mem_out_we),
        .mem_w_addr(mem_out_w_addr),
        .mem_w_data(mem_out_w_data),
        .jump(jump),
        .next_addr(next_addr),
        .link_addr(id_link_addr),
        .offset(id_offset),
        .we(id_we),
        .w_addr(id_w_addr),
        .inst_catagory(id_inst_catagory),
        .local_opcode(id_local_opcode),
        .ari_op1(id_ari_op1),
        .ari_op2(id_ari_op2),
        .busy_out(id_busy_out)
    );

    r_id_ex r_id_ex0(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .id_inst_catagory(id_inst_catagory),
        .id_local_opcode(id_local_opcode),
        .id_ari_op1(id_ari_op1),
        .id_ari_op2(id_ari_op2),
        .id_we(id_we),
        .id_w_addr(id_w_addr),
        .id_link_addr(id_link_addr),
        .id_offset(id_offset),
        .busy_in(id_busy_out),
        .ex_inst_catagory(ex_inst_catagory),
        .ex_local_opcode(ex_local_opcode),
        .ex_ari_op1(ex_ari_op1),
        .ex_ari_op2(ex_ari_op2),
        .ex_we(ex_we),
        .ex_w_addr(ex_w_addr),
        .ex_link_addr(ex_link_addr),
        .ex_offset(ex_offset),
        .busy_out(ex_busy_in)
    );

    p_ex p_ex0(
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .inst_catagory(ex_inst_catagory),
        .local_opcode(ex_local_opcode),
        .ari_op1(ex_ari_op1),
        .ari_op2(ex_ari_op2),
        .we(ex_we),
        .w_addr(ex_w_addr),
        .link_addr(ex_link_addr),
        .offset(ex_offset),
        .busy_in(ex_busy_in),
        .out_we(ex_out_we),
        .out_w_addr(ex_out_w_addr),
        .out_w_data(ex_out_w_data),
        .out_opcode(ex_out_opcode),
        .mem_addr(ex_out_mem_addr),
        .busy_out(ex_busy_out)
    );

    r_ex_mem r_ex_mem0(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .ex_we(ex_out_we),
        .ex_w_addr(ex_out_w_addr),
        .ex_w_data(ex_out_w_data),
        .ex_opcode(ex_out_opcode),
        .ex_mem_addr(ex_out_mem_addr),
        .busy_in(ex_busy_out),
        .mem_we(mem_mem_we),
        .mem_w_addr(mem_mem_w_addr),
        .mem_w_data(mem_mem_w_data),
        .mem_opcode(mem_mem_opcode),
        .mem_mem_addr(mem_mem_addr),
        .busy_out(mem_busy_in)
    );

    p_mem p_mem0(
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .we(mem_mem_we),
        .w_addr(mem_mem_w_addr),
        .w_data(mem_mem_w_data),
        .opcode(mem_mem_opcode),
        .mem_addr(mem_mem_addr),
        .busy_in(mem_busy_in),
        .sl_addr(mem_addr),
        .s_data(mem_w_data),
        .l_data(mem_r_data),
        .l_re(mem_re),
        .s_we(mem_we),
        .len_in_byte(mem_len_in_byte),
        .port_id(mem_port_id),
        .mem_busy(mem_mem_busy),
        .mem_done(mem_mem_done),
        .out_we(mem_out_we),
        .out_w_addr(mem_out_w_addr),
        .out_w_data(mem_out_w_data),
        .busy_out(mem_busy_out)
    );

    r_mem_wb r_mem_wb0(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),
        .mem_we(mem_out_we),
        .mem_w_addr(mem_out_w_addr),
        .mem_w_data(mem_out_w_data),
        .busy_in(mem_busy_out),
        .wb_we(wb_we),
        .wb_w_addr(wb_w_addr),
        .wb_w_data(wb_w_data)
    );

endmodule