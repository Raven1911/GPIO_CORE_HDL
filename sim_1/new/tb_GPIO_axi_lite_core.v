`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2026 03:43:01 PM
// Design Name: 
// Module Name: tb_GPIO_axi_lite_core
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


module tb_GPIO_axi_lite_core();

    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter WIDTH_PORT = 8;
    parameter CLK_PERIOD = 10;

    // AXI Addresses defined in your module
    parameter ADDR_REG0 = 32'h0200_7000; // [8]: we, [7:0]: define_io
    parameter ADDR_REG1 = 32'h0200_7004; // [7:0]: write_data
    parameter ADDR_REG2 = 32'h0200_7008; // Read data

    // Signals
    reg clk;
    reg resetn;

    // Write Address Channel
    reg [ADDR_WIDTH-1:0] awaddr;
    reg awvalid;
    wire awready;

    // Write Data Channel
    reg [DATA_WIDTH-1:0] wdata;
    reg [3:0] wstrb;
    reg wvalid;
    wire wready;

    // Write Response Channel
    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    // Read Address Channel
    reg [ADDR_WIDTH-1:0] araddr;
    reg arvalid;
    wire arready;

    // Read Data Channel
    wire [DATA_WIDTH-1:0] rdata;
    wire rvalid;
    wire [1:0] rresp;
    reg rready;

    // GPIO
    wire [WIDTH_PORT-1:0] gpio_io;
    reg [WIDTH_PORT-1:0] gpio_drive; // Để mô phỏng thiết bị ngoại vi đẩy dữ liệu vào

    // Drive inout port: Nếu bit nào là Input (0), ta sẽ đẩy dữ liệu từ TB vào
    // Lưu ý: define_io trong code của bạn: 1 là Output, 0 là Input
    // Ở đây tôi giả sử testbench chỉ "lái" bus khi chân đó được cấu hình là Input
    assign gpio_io = gpio_drive; 

    // Instantiate UUT
    GPIO_axi_lite_core #(
        .WIDTH_PORT(WIDTH_PORT)
    ) uut (
        .clk(clk),
        .resetn(resetn),
        .i_axi_awaddr(awaddr),
        .i_axi_awvalid(awvalid),
        .o_axi_awready(awready),
        .i_axi_awprot(3'b000),
        .i_axi_wdata(wdata),
        .i_axi_wstrb(wstrb),
        .i_axi_wvalid(wvalid),
        .o_axi_wready(wready),
        .o_axi_bresp(bresp),
        .o_axi_bvalid(bvalid),
        .i_axi_bready(bready),
        .i_axi_araddr(araddr),
        .i_axi_arvalid(arvalid),
        .o_axi_arready(arready),
        .i_axi_arprot(3'b000),
        .o_axi_rdata(rdata),
        .o_axi_rvalid(rvalid),
        .o_axi_rresp(rresp),
        .i_axi_rready(rready),
        .gpio_io(gpio_io)
    );

    // Clock generator
    always #(CLK_PERIOD/2) clk = ~clk;

    // Task: Write AXI-Lite
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
    begin
        @(posedge clk);
        awaddr = addr;
        awvalid = 1;
        wdata = data;
        wvalid = 1;
        wstrb = 4'hf;
        bready = 1;

        // Wait for handshake
        wait(awready && wready);
        @(posedge clk);
        awvalid = 0;
        wvalid = 0;
        
        // Wait for BVALID
        wait(bvalid);
        @(posedge clk);
        bready = 0;
        $display("[WRITE] Addr: %h, Data: %h", addr, data);
    end
    endtask

    // Task: Read AXI-Lite
    task axi_read(input [ADDR_WIDTH-1:0] addr);
    begin
        @(posedge clk);
        araddr = addr;
        arvalid = 1;
        rready = 1;

        wait(arready);
        @(posedge clk);
        arvalid = 0;

        wait(rvalid);
        $display("[READ] Addr: %h, Data: %h", addr, rdata);
        @(posedge clk);
        rready = 0;
    end
    endtask

    // Stimulus
    initial begin
        // Initialize
        clk = 0;
        resetn = 0;
        awaddr = 0; awvalid = 0;
        wdata = 0; wvalid = 0; wstrb = 0;
        bready = 0;
        araddr = 0; arvalid = 0;
        rready = 0;
        gpio_drive = 8'bz; // Ban đầu High-Z

        repeat(5) @(posedge clk);
        resetn = 1;
        $display("--- Reset Released ---");

        // 1. Cấu hình PORT: Tất cả là Output (0xFF) và Enable Write (Bit 8 = 1) -> 9'h1FF
        axi_write(ADDR_REG0, 32'h0000_01FF);
        
        // 2. Xuất dữ liệu 8'hAA ra GPIO
        axi_write(ADDR_REG1, 32'h0000_00AA);
        repeat(5) @(posedge clk);
        
        // Kiểm tra xem GPIO có xuất AA không
        if (gpio_io === 8'hAA) $display("SUCCESS: GPIO Output correct!");
        else $display("ERROR: GPIO Output mismatch! Got %h", gpio_io);

        // 3. Cấu hình PORT: Tất cả là Input (0x00) -> 9'h100
        axi_write(ADDR_REG0, 32'h0000_0100);
        gpio_drive = 8'h55; // Giả lập thiết bị ngoài đẩy 0x55 vào
        repeat(10) @(posedge clk); // Đợi qua 2 tầng sync trong module GPI

        // 4. Đọc dữ liệu từ Register 2
        axi_read(ADDR_REG2);
        
        if (rdata[7:0] === 8'h55) $display("SUCCESS: GPIO Input read correct!");
        else $display("ERROR: GPIO Input mismatch! Got %h", rdata);

        repeat(10) @(posedge clk);

        // ---------------------------------------------------------
        // TEST CASE: MIXED MODE (4-bit Out, 4-bit In)
        // ---------------------------------------------------------
        $display("\n--- Starting Mixed Mode Test ---");
        
        // 1. Cấu hình: [7:4] là Output (1), [3:0] là Input (0)
        // define_io = 8'b1111_0000 (0xF0), we = 1 -> Dữ liệu ghi: 9'h1F0
        axi_write(ADDR_REG0, 32'h0000_01F0);

        // 2. Chuẩn bị dữ liệu:
        // - AXI ghi 0xA ra 4 bit cao (REG1 = 8'hA0)
        // - Testbench đẩy 0x5 vào 4 bit thấp thông qua chân pin
        axi_write(ADDR_REG1, 32'h0000_00A0); 
        gpio_drive = 8'bzzzz_0101; // TB chỉ lái 4 bit thấp, 4 bit cao để Z để tránh xung đột

        repeat(10) @(posedge clk); // Đợi đồng bộ hóa

        // 3. Kiểm tra chân vật lý (Physical Pins)
        // Kết quả mong đợi trên bus gpio_io: 8'hA5 (1010_0101)
        if (gpio_io === 8'hA5) 
            $display("SUCCESS: Physical Pins are 0x%h (Correct!)", gpio_io);
        else 
            $display("ERROR: Physical Pins Mismatch! Got 0x%h, Expected 0xA5", gpio_io);

        // 4. Đọc lại qua AXI (Register 2)
        axi_read(ADDR_REG2);
        if (rdata[7:0] === 8'hA5)
            $display("SUCCESS: AXI Read Value is 0x%h (Correct!)", rdata[7:0]);
        else
            $display("ERROR: AXI Read Mismatch! Got 0x%h", rdata[7:0]);

        $finish;
    end

endmodule
