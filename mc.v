// memory controller

module mc(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    input wire[7:0] mem_din,
    output wire[7:0] mem_dout,
    output wire[31:0] mem_a,
    
    
)