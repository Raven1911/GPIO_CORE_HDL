`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2026 03:09:26 PM
// Design Name: 
// Module Name: GPIO_axi_lite_core
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
module GPIO_axi_lite_core #(
    parameter NUM_MASTERS = 1,
    parameter ADDR_WIDTH = 32,          // Address width
    parameter DATA_WIDTH = 32,          // Data width
    parameter TRANS_W_STRB_W = 4,       // width strobe
    parameter TRANS_WR_RESP_W = 2,      // width response
    parameter TRANS_PROT      = 3,
    parameter CYCLE_CLOCK = 2,

    //config register timer
    parameter [ADDR_WIDTH-1:0] ADDR_REGISTERS_0= 32'h0200_7000,
    parameter [ADDR_WIDTH-1:0] ADDR_REGISTERS_1= 32'h0200_7004,
    parameter [ADDR_WIDTH-1:0] ADDR_REGISTERS_2= 32'h0200_7008,
    parameter WIDTH_PORT = 8
)(  
    input clk,
    input resetn,

    // AXI-Lite Write Address Channels
    input       [ADDR_WIDTH-1:0]        i_axi_awaddr,
    input                               i_axi_awvalid,
    output                              o_axi_awready,
    input       [TRANS_PROT-1:0]        i_axi_awprot,

    // AXI-Lite Write Data Channel
    input       [DATA_WIDTH-1:0]        i_axi_wdata,
    input       [TRANS_W_STRB_W-1:0]    i_axi_wstrb,
    input                               i_axi_wvalid,
    output                              o_axi_wready,

    // AXI-Lite Write Response Channels
    output      [TRANS_WR_RESP_W-1:0]   o_axi_bresp,
    output                              o_axi_bvalid,
    input                               i_axi_bready,

    // AXI-Lite Read Address Channels
    input       [ADDR_WIDTH-1:0]        i_axi_araddr,
    input                               i_axi_arvalid,
    output                              o_axi_arready,
    input       [TRANS_PROT-1:0]        i_axi_arprot,

    // AXI4-Lite Read Data Channel
    output      [DATA_WIDTH-1:0]        o_axi_rdata,
    output                              o_axi_rvalid,
    output      [TRANS_WR_RESP_W-1:0]   o_axi_rresp,
    input                               i_axi_rready,


    // GPIO Interface
    inout       [WIDTH_PORT-1:0]        gpio_io

    );

    //signals to connect
    //wire [3:0] o_wen;
    wire [ADDR_WIDTH-1:0] o_addr_w;
    // wire [ADDR_WIDTH-1:0] o_addr_r;                
    wire [DATA_WIDTH-1:0] o_data_w;
    wire [DATA_WIDTH-1:0] i_data_r;

    wire o_wr_w;
    // wire o_rd_r;

    // signal declaration
    wire wr_reg0;
    wire wr_reg1;
    // wire rd_reg2;


    reg  we;
    reg  [WIDTH_PORT-1:0] define_io;
    reg  [WIDTH_PORT-1:0] write_port;
    wire [WIDTH_PORT-1:0] read_port;


    // decoding
    assign wr_reg0       = (o_wr_w && (o_addr_w[31:0] == ADDR_REGISTERS_0)) ? 1 : 0;
    assign wr_reg1       = (o_wr_w && (o_addr_w[31:0] == ADDR_REGISTERS_1)) ? 1 : 0;
    // assign rd_reg2       = (/* o_rd_r &&  */(o_addr_r[31:0] == ADDR_REGISTERS_2)) ? 1 : 0;


    // write data
    always @(posedge clk or negedge resetn) begin
        if (~resetn) begin
            we <= 1'b0;
            define_io <= 0;
            write_port <= 0;
        end else begin
            we <= (wr_reg0) ? o_data_w[8] : we;
            define_io <= (wr_reg0) ? o_data_w[7:0] : define_io;
            write_port <= (wr_reg1) ? o_data_w[7:0] : write_port;
        end
    end


    // read data  
    assign i_data_r = read_port;
    


    // instantiate GPIO core
    GPIO_core #(
        .WIDTH_PORT(WIDTH_PORT)
    ) GPIO_core_uut (
        .clk_i         (clk),
        .resetn_i      (resetn),
        .we_i          (we),
        .define_io_i   (define_io),
        .write_port_i  (write_port),
        .read_port_o   (read_port),
        .gpio_io       (gpio_io)
    );

    axi_lite_slave_interface #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .TRANS_W_STRB_W(TRANS_W_STRB_W),
        .TRANS_WR_RESP_W(TRANS_WR_RESP_W),
        .TRANS_PROT(TRANS_PROT),
        .CYCLE_CLOCK(CYCLE_CLOCK),
        .NUM_MASTERS(NUM_MASTERS)
    ) timer_axi_lite_interface (
        .clk_i(clk),
        .resetn_i(resetn),

        .i_axi_awaddr(i_axi_awaddr),
        .i_axi_awvalid(i_axi_awvalid),
        .o_axi_awready(o_axi_awready),
        .i_axi_awprot(i_axi_awprot),

        .i_axi_wdata(i_axi_wdata),
        .i_axi_wstrb(i_axi_wstrb),
        .i_axi_wvalid(i_axi_wvalid),
        .o_axi_wready(o_axi_wready),

        .o_axi_bresp(o_axi_bresp),
        .o_axi_bvalid(o_axi_bvalid),
        .i_axi_bready(i_axi_bready),

        .i_axi_araddr(i_axi_araddr),
        .i_axi_arvalid(i_axi_arvalid),
        .o_axi_arready(o_axi_arready),
        .i_axi_arprot(i_axi_arprot),

        .o_axi_rdata(o_axi_rdata),
        .o_axi_rvalid(o_axi_rvalid),
        .o_axi_rresp(o_axi_rresp),
        .i_axi_rready(i_axi_rready),

        .o_addr_w(o_addr_w),
        .o_awprot_w(),

        .o_wen(),       
        .o_data_w(o_data_w),
        .o_write_data_w(o_wr_w),

        .i_bresp_w('b00),

        .o_addr_r(/* o_addr_r */),
        .o_arprot_r(),
        
        .i_data_r(i_data_r),
        .i_rresp_r('b00),
        .o_read_data_r(/* o_rd_r */)
    );

endmodule





module GPIO_core#(
    parameter WIDTH_PORT = 8
)(
    input                    clk_i,
    input                    resetn_i,

    input                    we_i,          // Write Enable cho GPO
    input   [WIDTH_PORT-1:0] define_io_i,   // 1: Output, 0: Input (Tri-state control)
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
            assign gpio_io[i] = (define_io_i[i]) ? gpo_to_tri[i] : 1'bz;
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




//////////////////////////////////////////////////

module axi_lite_slave_interface#(
    parameter ADDR_WIDTH = 32,          // Address width
    parameter DATA_WIDTH = 32,          // Data width
    parameter TRANS_W_STRB_W = 4,       // width strobe
    parameter TRANS_WR_RESP_W = 2,      // width response
    parameter TRANS_PROT      = 3,
    parameter CYCLE_CLOCK = 2,
    parameter NUM_MASTERS = 1
)(
    input                               clk_i,
    input                               resetn_i,

    // AXI-Lite Write Address Channels
    input       [ADDR_WIDTH-1:0]        i_axi_awaddr,
    input                               i_axi_awvalid,
    output                              o_axi_awready,
    input       [TRANS_PROT-1:0]        i_axi_awprot,

    // AXI-Lite Write Data Channel
    input       [DATA_WIDTH-1:0]        i_axi_wdata,
    input       [TRANS_W_STRB_W-1:0]    i_axi_wstrb,
    input                               i_axi_wvalid,
    output                              o_axi_wready,

    // AXI-Lite Write Response Channels
    output      [TRANS_WR_RESP_W-1:0]   o_axi_bresp,
    output                              o_axi_bvalid,
    input                               i_axi_bready,

    // AXI-Lite Read Address Channels
    input       [ADDR_WIDTH-1:0]        i_axi_araddr,
    input                               i_axi_arvalid,
    output                              o_axi_arready,
    input       [TRANS_PROT-1:0]        i_axi_arprot,

    // AXI4-Lite Read Data Channel
    output      [DATA_WIDTH-1:0]        o_axi_rdata,
    output                              o_axi_rvalid,
    output      [TRANS_WR_RESP_W-1:0]   o_axi_rresp,
    input                               i_axi_rready,

    // Channel for slave

    
    output      [ADDR_WIDTH-1:0]        o_addr_w,
    output      [TRANS_PROT-1:0]        o_awprot_w,

    output      [3:0]                   o_wen,
    output      [DATA_WIDTH-1:0]        o_data_w,
    output                              o_write_data_w,

    input       [TRANS_WR_RESP_W-1:0]   i_bresp_w,

    output      [ADDR_WIDTH-1:0]        o_addr_r,
    output      [TRANS_PROT-1:0]        o_arprot_r,

    input       [DATA_WIDTH-1:0]        i_data_r,
    input       [TRANS_WR_RESP_W-1:0]   i_rresp_r,
    output                              o_read_data_r

    );

    wire    axi_awready, axi_wready, axi_bvalid;
    wire    axi_arready, axi_rvalid;


    //response write channel
    ///AW//////////////////////////////
    tick_timer #(
        .CYCLE_CLOCK(CYCLE_CLOCK)
    ) AW_slave (
        .clk_i(clk_i),
        .start_i(i_axi_awvalid),
        .resetn_i(i_axi_awvalid),
        .set_i(axi_awready),
        .tick_timer(axi_awready)
    );

    // Instantiate the DFF module
    generate
        if (NUM_MASTERS == 1) begin
            register_DFF #(
                .SIZE_BITS(ADDR_WIDTH)
            ) register_DFF_AW_0 (
                .clk_i(axi_awready),
                .resetn_i(resetn_i),
                .D_i(i_axi_awaddr),
                .Q_o(o_addr_w)
            );
        end

        else begin
            register_DFF_negedge #(
                .SIZE_BITS(ADDR_WIDTH)
            ) register_DFF_AW_0 (
                .clkn_i(axi_awready),
                .resetn_i(resetn_i),
                .D_i(i_axi_awaddr),
                .Q_o(o_addr_w)
            );
        end
    endgenerate
    

    register_DFF #(
        .SIZE_BITS(TRANS_PROT)
    ) register_DFF_AW_1 (
        .clk_i(axi_awready),
        .resetn_i(resetn_i),
        .D_i(i_axi_awprot),
        .Q_o(o_awprot_w)
    );

    
    ////////////////////////////W//////////////////////////////
    tick_timer #(
        .CYCLE_CLOCK(CYCLE_CLOCK)
    ) W_slave (
        .clk_i(clk_i),
        .start_i(i_axi_wvalid),
        .resetn_i(i_axi_wvalid),
        .set_i(axi_wready),
        .tick_timer(axi_wready)
    );


    // Instantiate the DFF module
    register_DFF #(
        .SIZE_BITS(DATA_WIDTH)
    ) register_DFF_W_0 (
        .clk_i(axi_wready),
        .resetn_i(resetn_i),
        .D_i(i_axi_wdata),
        .Q_o(o_data_w)
    );

    register_DFF #(
        .SIZE_BITS(TRANS_W_STRB_W)
    ) register_DFF_W_1 (
        .clk_i(axi_wready),
        .resetn_i(resetn_i),
        .D_i(i_axi_wstrb),
        .Q_o(o_wen)
    );



    /////////B//////////////////////////////////////
    tick_timer #(
        .CYCLE_CLOCK(CYCLE_CLOCK)
    ) B_slave (
        .clk_i(clk_i),
        .start_i(i_axi_bready),
        .resetn_i(i_axi_bready),
        .set_i(axi_bvalid),
        .tick_timer(axi_bvalid)
    );

    register_DFF #(
        .SIZE_BITS(TRANS_WR_RESP_W)
    ) register_DFF_B_0 (
        .clk_i(axi_bvalid),
        .resetn_i(resetn_i),
        .D_i(i_bresp_w),
        .Q_o(o_axi_bresp)
    );





    //response read channel
    tick_timer #(
        .CYCLE_CLOCK(CYCLE_CLOCK)
    ) AR_slave (
        .clk_i(clk_i),
        .start_i(i_axi_arvalid),
        .resetn_i(i_axi_arvalid),
        .set_i(axi_arready),
        .tick_timer(axi_arready)
    );  


    generate
        if (NUM_MASTERS == 1) begin
                register_DFF #(
                    .SIZE_BITS(ADDR_WIDTH)
                ) register_DFF_AR_0 (
                    .clk_i(axi_arready),
                    .resetn_i(resetn_i),
                    .D_i(i_axi_araddr),
                    .Q_o(o_addr_r)
                );
        end

        else begin
            register_DFF_negedge #(
                .SIZE_BITS(ADDR_WIDTH)
            ) register_DFF_AR_0 (
                .clkn_i(axi_arready),
                .resetn_i(resetn_i),
                .D_i(i_axi_araddr),
                .Q_o(o_addr_r)
            );
        end
    endgenerate


    register_DFF #(
        .SIZE_BITS(TRANS_PROT)
    ) register_DFF_AR_1 (
        .clk_i(axi_arready),
        .resetn_i(resetn_i),
        .D_i(i_axi_arprot),
        .Q_o(o_arprot_r)
    );



    tick_timer #(
        .CYCLE_CLOCK(CYCLE_CLOCK)
    ) R_slave (
        .clk_i(clk_i),
        .start_i(i_axi_rready),
        .resetn_i(i_axi_rready),
        .set_i(axi_rvalid),
        .tick_timer(axi_rvalid)
    );

    register_DFF #(
        .SIZE_BITS(DATA_WIDTH)
    ) register_DFF_R_0 (
        .clk_i(axi_rvalid),
        .resetn_i(resetn_i),
        .D_i(i_data_r),
        .Q_o(o_axi_rdata)
    );

    register_DFF #(
        .SIZE_BITS(TRANS_WR_RESP_W)
    ) register_DFF_R_1 (
        .clk_i(axi_rvalid),
        .resetn_i(resetn_i),
        .D_i(i_rresp_r),
        .Q_o(o_axi_rresp)
    );



    assign  o_axi_awready       = axi_awready;

    assign  o_axi_wready        = axi_wready;
    assign  o_write_data_w      = axi_wready;

    assign  o_axi_bvalid        = axi_bvalid;

    assign  o_axi_arready       = axi_arready;

    assign  o_axi_rvalid        = axi_rvalid;
    assign  o_read_data_r       = i_axi_rready;

endmodule


module register_DFF#(
    SIZE_BITS = 32
)(  
    input                           clk_i,
    input                           resetn_i,
    input       [SIZE_BITS-1:0]    D_i,

    output  reg [SIZE_BITS-1:0]    Q_o
);
    always @(posedge clk_i, negedge resetn_i) begin
        if (~resetn_i) begin
            Q_o <= 0;
        end
        else begin
            Q_o <= D_i;
        end
    end

endmodule

module register_DFF_negedge#(
    SIZE_BITS = 32
)(  
    input                           clkn_i,
    input                           resetn_i,
    input       [SIZE_BITS-1:0]     D_i,

    output  reg [SIZE_BITS-1:0]     Q_o
);
    always @(negedge clkn_i, negedge resetn_i) begin
        if (~resetn_i) begin
            Q_o <= 0;
        end
        else begin
            Q_o <= D_i;
        end
    end

endmodule


module tick_timer#(
    parameter CYCLE_CLOCK = 2 // cycle

)(  
    input   clk_i,
    input   start_i,
    input   resetn_i,
    input   set_i,

    output  tick_timer

);

    reg [$clog2(CYCLE_CLOCK)-1:0] count_next, count_reg;
    reg                            tick_next, tick_reg;

    always @(posedge clk_i or negedge resetn_i) begin
        if (~resetn_i) begin
            count_reg <= 0;
            tick_reg <= 0;
        end

        
        else begin
            tick_reg <= tick_next;
            count_reg <= count_next;
        end
    end

    always @(*) begin
        count_next = count_reg;
        tick_next = 0;
        if (start_i) begin
            if (count_reg >= CYCLE_CLOCK - 1) begin
                count_next = 0;
                tick_next = 1;
            end
            else if (set_i)begin
                count_next = 0;
            end
            else begin  
                count_next = count_next + 1;
                tick_next = 0;
            end
        end
    end

    assign tick_timer = tick_reg;

endmodule