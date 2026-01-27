`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2026 03:58:02 PM
// Design Name: 
// Module Name: GPIO_core
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module GPIO_core#(
    parameter WIDTH_PORT = 8
)(
    input                    clk_i,
    input                    resetn_i,

    input                    we_i,          // Write Enable cho GPO
    input   [WIDTH_PORT-1:0] select_io_i,   // 1: Output, 0: Input (Tri-state control)
    input   [WIDTH_PORT-1:0] write_port_i,  
    output  [WIDTH_PORT-1:0] read_port_o,

    inout   [WIDTH_PORT-1:0] gpio_io

    );


    // Dây nối nội bộ giữa các module
    wire [WIDTH_PORT-1:0] gpo_to_tri;
    wire [WIDTH_PORT-1:0] tri_to_gpi;

    // 1. Instance module GPO: Lưu trữ dữ liệu xuất ra
    GPO #(.WIDTH_PORT(WIDTH_PORT)) u_gpo (
        .clk_i      (clk_i),
        .resetn_i    (resetn_i),
        .we_i       (we_i),
        .write_port (write_port_i),
        .gpo_o      (gpo_to_tri)
    );

    // 2. Điều khiển Tri-state Buffer cho từng bit
    // Nếu select_io = 1: chân gpio_io là OUTPUT, xuất giá trị từ GPO
    // Nếu select_io = 0: chân gpio_io là INPUT (High-Z), để nhận tín hiệu ngoài
    genvar i;
    generate
        for (i = 0; i < WIDTH_PORT; i = i + 1) begin : gpio_tri_state
            assign gpio_io[i] = (select_io_i[i]) ? gpo_to_tri[i] : 1'bz;
        end
    endgenerate

    // 3. Tín hiệu đi vào GPI là giá trị thực tế trên chân pin
    assign tri_to_gpi = gpio_io;

    // 4. Instance module GPI: Đồng bộ dữ liệu đọc về để khử metastability
    GPI #(.WIDTH_PORT(WIDTH_PORT)) u_gpi (
        .clk_i      (clk_i),
        .resetn_i    (resetn_i),
        .gpi_i      (tri_to_gpi),
        .read_port  (read_port_o)
    );

endmodule


module GPO #(
    parameter WIDTH_PORT = 8
)(  
    input                    clk_i,
    input                    resetn_i,
    input                    we_i,         
    input   [WIDTH_PORT-1:0] write_port,
    output  [WIDTH_PORT-1:0] gpo_o
);

    reg [WIDTH_PORT-1:0] buf_reg;

    always @(posedge clk_i or negedge resetn_i) begin
        if (!resetn_i) begin
            buf_reg <= {WIDTH_PORT{1'b0}};
        end else if (we_i) begin  
            buf_reg <= write_port;
        end
    end

    assign gpo_o = buf_reg;

endmodule



module GPI #(
    parameter WIDTH_PORT = 8
)(  
    input                    clk_i,
    input                    resetn_i,
    input   [WIDTH_PORT-1:0] gpi_i,
    output  [WIDTH_PORT-1:0] read_port
);

    reg [WIDTH_PORT-1:0] sync_reg_1;
    reg [WIDTH_PORT-1:0] sync_reg_2;

    always @(posedge clk_i or negedge resetn_i) begin
        if (!resetn_i) begin
            sync_reg_1 <= {WIDTH_PORT{1'b0}};
            sync_reg_2 <= {WIDTH_PORT{1'b0}};
        end else begin
            sync_reg_1 <= gpi_i;      
            sync_reg_2 <= sync_reg_1; 
        end
    end

    // Output lấy từ tầng thứ 2
    assign read_port = sync_reg_2;

endmodule



