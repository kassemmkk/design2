`default_nettype none

module multi_periph_top (
    // Clock and reset
    input  wire        clk,
    input  wire        rst_n,
    
    // Wishbone interface
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output reg  [31:0] wb_dat_o,
    output reg         wb_ack_o,
    
    // SPI Master 0 interface
    output wire        spi0_sclk,
    output wire        spi0_mosi,
    input  wire        spi0_miso,
    output wire        spi0_cs_n,
    
    // SPI Master 1 interface  
    output wire        spi1_sclk,
    output wire        spi1_mosi,
    input  wire        spi1_miso,
    output wire        spi1_cs_n,
    
    // I2C interface
    inout  wire        i2c_scl,
    inout  wire        i2c_sda,
    
    // GPIO interface
    inout  wire [1:0]  gpio_io,
    
    // Interrupt outputs
    output wire [2:0]  irq_o
);

    // Address decode
    wire spi0_sel = (wb_adr_i[31:8] == 24'h300000);
    wire spi1_sel = (wb_adr_i[31:8] == 24'h300001);
    wire i2c_sel  = (wb_adr_i[31:12] == 20'h30001);
    wire gpio_sel = (wb_adr_i[31:12] == 20'h30002);
    
    // Wishbone signals for each peripheral
    wire [31:0] spi0_dat_o, spi1_dat_o, i2c_dat_o, gpio_dat_o;
    wire        spi0_ack_o, spi1_ack_o, i2c_ack_o, gpio_ack_o;
    wire        spi0_irq, spi1_irq, i2c_irq, gpio_irq;
    
    // SPI Master 0
    CF_SPI_WB spi0_inst (
        .clk_i(clk),
        .rst_i(~rst_n),
        .stb_i(wb_stb_i && spi0_sel),
        .cyc_i(wb_cyc_i && spi0_sel),
        .we_i(wb_we_i),
        .sel_i(wb_sel_i),
        .dat_i(wb_dat_i),
        .adr_i({24'h0, wb_adr_i[7:0]}),
        .dat_o(spi0_dat_o),
        .ack_o(spi0_ack_o),
        .sclk(spi0_sclk),
        .mosi(spi0_mosi),
        .miso(spi0_miso),
        .csb(spi0_cs_n),
        .IRQ(spi0_irq)
    );
    
    // SPI Master 1
    CF_SPI_WB spi1_inst (
        .clk_i(clk),
        .rst_i(~rst_n),
        .stb_i(wb_stb_i && spi1_sel),
        .cyc_i(wb_cyc_i && spi1_sel),
        .we_i(wb_we_i),
        .sel_i(wb_sel_i),
        .dat_i(wb_dat_i),
        .adr_i({24'h0, wb_adr_i[7:0]}),
        .dat_o(spi1_dat_o),
        .ack_o(spi1_ack_o),
        .sclk(spi1_sclk),
        .mosi(spi1_mosi),
        .miso(spi1_miso),
        .csb(spi1_cs_n),
        .IRQ(spi1_irq)
    );
    
    // I2C Controller
    wire i2c_scl_i, i2c_scl_o, i2c_scl_oen_o;
    wire i2c_sda_i, i2c_sda_o, i2c_sda_oen_o;
    
    EF_I2C_WB i2c_inst (
        .clk_i(clk),
        .rst_i(~rst_n),
        .stb_i(wb_stb_i && i2c_sel),
        .cyc_i(wb_cyc_i && i2c_sel),
        .we_i(wb_we_i),
        .sel_i(wb_sel_i),
        .dat_i(wb_dat_i),
        .adr_i({20'h0, wb_adr_i[11:0]}),
        .dat_o(i2c_dat_o),
        .ack_o(i2c_ack_o),
        .scl_i(i2c_scl_i),
        .scl_o(i2c_scl_o),
        .scl_oen_o(i2c_scl_oen_o),
        .sda_i(i2c_sda_i),
        .sda_o(i2c_sda_o),
        .sda_oen_o(i2c_sda_oen_o),
        .IRQ(i2c_irq)
    );
    
    // I2C bidirectional buffer
    assign i2c_scl = i2c_scl_oen_o ? 1'bz : i2c_scl_o;
    assign i2c_scl_i = i2c_scl;
    assign i2c_sda = i2c_sda_oen_o ? 1'bz : i2c_sda_o;
    assign i2c_sda_i = i2c_sda;
    
    // GPIO with edge detection
    wire [1:0] gpio_in, gpio_out, gpio_oe;
    wire       gpio_we;
    
    assign gpio_we = wb_we_i && wb_cyc_i && wb_stb_i && gpio_sel;
    
    gpio_edge_detect gpio_inst (
        .clk(clk),
        .rst_n(rst_n),
        .bus_we(gpio_we),
        .bus_addr(wb_adr_i[7:0]),
        .bus_wdata(wb_dat_i),
        .bus_rdata(gpio_dat_o),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .irq(gpio_irq)
    );
    
    // GPIO bidirectional buffer
    assign gpio_io[0] = gpio_oe[0] ? gpio_out[0] : 1'bz;
    assign gpio_io[1] = gpio_oe[1] ? gpio_out[1] : 1'bz;
    assign gpio_in = gpio_io;
    
    // GPIO ACK generation
    reg gpio_ack_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gpio_ack_reg <= 1'b0;
        else if (wb_cyc_i && wb_stb_i && gpio_sel && ~gpio_ack_reg)
            gpio_ack_reg <= 1'b1;
        else
            gpio_ack_reg <= 1'b0;
    end
    assign gpio_ack_o = gpio_ack_reg;
    
    // Wishbone response multiplexing
    always @(*) begin
        case (1'b1)
            spi0_sel: begin
                wb_dat_o = spi0_dat_o;
                wb_ack_o = spi0_ack_o;
            end
            spi1_sel: begin
                wb_dat_o = spi1_dat_o;
                wb_ack_o = spi1_ack_o;
            end
            i2c_sel: begin
                wb_dat_o = i2c_dat_o;
                wb_ack_o = i2c_ack_o;
            end
            gpio_sel: begin
                wb_dat_o = gpio_dat_o;
                wb_ack_o = gpio_ack_o;
            end
            default: begin
                wb_dat_o = 32'h00000000;
                wb_ack_o = 1'b0;
            end
        endcase
    end
    
    // Interrupt mapping
    assign irq_o[0] = spi0_irq;
    assign irq_o[1] = spi1_irq | i2c_irq;
    assign irq_o[2] = gpio_irq;

endmodule

`default_nettype wire