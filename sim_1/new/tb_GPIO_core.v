`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/27/2026 04:33:29 PM
// Design Name: 
// Module Name: tb_GPIO_core
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



module tb_GPIO_core();

    // Parameters
    parameter WIDTH_PORT = 8;
    parameter CLK_PERIOD = 10; // 100MHz

    // Signals
    reg                     clk_i;
    reg                     resetn_i;
    reg                     we_i;
    reg  [WIDTH_PORT-1:0]   select_io_i;
    reg  [WIDTH_PORT-1:0]   write_port_i;
    wire [WIDTH_PORT-1:0]   read_port_o;
    wire [WIDTH_PORT-1:0]   gpio_io;

    // Reg để mô phỏng thiết bị bên ngoài lái chân inout
    reg  [WIDTH_PORT-1:0]   ext_gpio_drive;

    // Logic điều khiển chân inout từ phía Testbench
    // Khi select_io_i = 0 (Input mode), TB sẽ lái giá trị ext_gpio_drive vào gpio_io
    // Khi select_io_i = 1 (Output mode), TB thả nổi (Hi-Z) để FPGA tự lái
    // assign gpio_io = (select_io_i == 8'h00) ? ext_gpio_drive : {WIDTH_PORT{1'bz}};

    genvar i;
    generate
        for (i = 0; i < WIDTH_PORT; i = i + 1) begin : gpio_tri_state
            assign gpio_io[i] = (select_io_i[i] == 0) ? ext_gpio_drive[i] : 1'bz;
        end
    endgenerate

    // Instantiate Unit Under Test (UUT)
    GPIO_core #(
        .WIDTH_PORT(WIDTH_PORT)
    ) uut (
        .clk_i         (clk_i),
        .resetn_i      (resetn_i),
        .we_i          (we_i),
        .select_io_i   (select_io_i),
        .write_port_i  (write_port_i),
        .read_port_o   (read_port_o),
        .gpio_io       (gpio_io)
    );

    // Clock Generation
    initial begin
        clk_i = 0;
        forever #(CLK_PERIOD/2) clk_i = ~clk_i;
    end

    // Stimulus Process
    initial begin
        // --- 1. Khởi tạo ---
        resetn_i       = 0;
        we_i           = 0;
        select_io_i    = 8'h00; // Mặc định là Input
        write_port_i   = 8'h00;
        ext_gpio_drive = 8'hzz; // Chưa lái gì cả
        
        #(CLK_PERIOD*5);
        resetn_i = 1;
        #(CLK_PERIOD*2);

        // --- 2. Test Output Mode (FPGA xuất dữ liệu ra chân Pin) ---
        $display("TEST OUTPUT MODE: FPGA -> PIN");
        select_io_i  = 8'hFF; // Cấu hình tất cả là Output
        write_port_i = 8'hAA; // Giá trị muốn xuất: 10101010
        we_i         = 1;      // Cho phép ghi vào GPO
        #(CLK_PERIOD);
        we_i         = 0;
        
        #(CLK_PERIOD*2);
        if (gpio_io === 8'hAA) 
            $display("[PASS] GPIO_IO xuat dung gia tri 0xAA");
        else 
            $display("[FAIL] GPIO_IO sai gia tri: %h", gpio_io);

        // --- 3. Test Input Mode (Thiết bị ngoài lái vào FPGA) ---
        $display("TEST INPUT MODE: PIN -> FPGA");
        select_io_i    = 8'h00; // Cấu hình tất cả là Input
        ext_gpio_drive = 8'h55; // Bên ngoài lái giá trị 0x55
        
        // Đợi 3 chu kỳ clock vì GPI có 2 tầng thanh ghi đồng bộ (2 clocks) + 1 clock trễ TB
        #(CLK_PERIOD*3);
        
        if (read_port_o === 8'h55)
            $display("[PASS] Read_port_o doc dung gia tri 0x55");
        else
            $display("[FAIL] Read_port_o sai gia tri: %h", read_port_o);

        // --- 4. Test Mixed Mode (Vừa Input vừa Output) ---
        $display("TEST MIXED MODE");
        select_io_i    = 8'h0F; // 4 bit thấp là Output, 4 bit cao là Input
        write_port_i   = 8'h0A; // Xuất 0xA ra 4 bit thấp
        we_i           = 1;
        ext_gpio_drive = 8'hB0; // Lái 0xB vào 4 bit cao
        #(CLK_PERIOD);
        we_i           = 0;
        
        #(CLK_PERIOD*3);
        $display("GPIO_IO hien tai: %h (Ky vong: B A)", gpio_io);
        $display("Read_port_o hien tai: %h", read_port_o);

        #(CLK_PERIOD*10);
        $display("Simulation Finished!");
        $finish;
    end

endmodule
