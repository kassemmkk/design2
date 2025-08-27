`default_nettype none

module multi_periph_top (
    input  wire        clk,
    input  wire        rst_n,
    
    // Wishbone slave interface
    input  wire        wb_cyc_i,
    input  wire        wb_stb_i,
    input  wire        wb_we_i,
    input  wire [3:0]  wb_sel_i,
    input  wire [31:0] wb_adr_i,
    input  wire [31:0] wb_dat_i,
    output wire [31:0] wb_dat_o,
    output wire        wb_ack_o,
    
    // SPI Master 0 interface
    input  wire        spi0_miso,
    output wire        spi0_mosi,
    output wire        spi0_sclk,
    output wire        spi0_csb,
    output wire        spi0_irq,
    
    // SPI Master 1 interface  
    input  wire        spi1_miso,
    output wire        spi1_mosi,
    output wire        spi1_sclk,
    output wire        spi1_csb,
    output wire        spi1_irq,
    
    // I2C interface
    input  wire        i2c_scl_i,
    output wire        i2c_scl_o,
    output wire        i2c_scl_oen_o,
    input  wire        i2c_sda_i,
    output wire        i2c_sda_o,
    output wire        i2c_sda_oen_o,
    output wire        i2c_irq,
    
    // GPIO interface
    input  wire [1:0]  gpio_in,
    output wire [1:0]  gpio_out,
    output wire [1:0]  gpio_oe,
    output wire        gpio_irq
);

    // Address decode
    wire spi0_sel, spi1_sel, i2c_sel, gpio_sel;
    wire [31:0] spi0_dat_o, spi1_dat_o, i2c_dat_o, gpio_dat_o;
    wire spi0_ack_o, spi1_ack_o, i2c_ack_o, gpio_ack_o;
    
    // Address decoding
    assign spi0_sel = wb_cyc_i && wb_stb_i && (wb_adr_i[31:8] == 24'h300000);  // 0x3000_0000 - 0x3000_00FF
    assign spi1_sel = wb_cyc_i && wb_stb_i && (wb_adr_i[31:8] == 24'h300001);  // 0x3000_0100 - 0x3000_01FF
    assign i2c_sel  = wb_cyc_i && wb_stb_i && (wb_adr_i[31:8] == 24'h300010);  // 0x3000_1000 - 0x3000_10FF
    assign gpio_sel = wb_cyc_i && wb_stb_i && (wb_adr_i[31:8] == 24'h300020);  // 0x3000_2000 - 0x3000_20FF
    
    // Output muxing
    assign wb_dat_o = spi0_sel ? spi0_dat_o :
                      spi1_sel ? spi1_dat_o :
                      i2c_sel  ? i2c_dat_o  :
                      gpio_sel ? gpio_dat_o : 32'h00000000;
                      
    assign wb_ack_o = spi0_ack_o | spi1_ack_o | i2c_ack_o | gpio_ack_o;

    // SPI Master 0
    CF_SPI_WB #(
        .CDW(8),
        .FAW(4)
    ) spi0_inst (
        .clk_i(clk),
        .rst_i(~rst_n),
        .adr_i(wb_adr_i),
        .dat_i(wb_dat_i),
        .dat_o(spi0_dat_o),
        .sel_i(wb_sel_i),
        .cyc_i(spi0_sel),
        .stb_i(spi0_sel),
        .ack_o(spi0_ack_o),
        .we_i(wb_we_i),
        .IRQ(spi0_irq),
        .miso(spi0_miso),
        .mosi(spi0_mosi),
        .csb(spi0_csb),
        .sclk(spi0_sclk)
    );

    // SPI Master 1
    CF_SPI_WB #(
        .CDW(8),
        .FAW(4)
    ) spi1_inst (
        .clk_i(clk),
        .rst_i(~rst_n),
        .adr_i(wb_adr_i),
        .dat_i(wb_dat_i),
        .dat_o(spi1_dat_o),
        .sel_i(wb_sel_i),
        .cyc_i(spi1_sel),
        .stb_i(spi1_sel),
        .ack_o(spi1_ack_o),
        .we_i(wb_we_i),
        .IRQ(spi1_irq),
        .miso(spi1_miso),
        .mosi(spi1_mosi),
        .csb(spi1_csb),
        .sclk(spi1_sclk)
    );

    // I2C Controller
    EF_I2C_WB #(
        .DEFAULT_PRESCALE(1),
        .FIXED_PRESCALE(0),
        .CMD_FIFO(1),
        .CMD_FIFO_DEPTH(16),
        .WRITE_FIFO(1),
        .WRITE_FIFO_DEPTH(16),
        .READ_FIFO(1),
        .READ_FIFO_DEPTH(16)
    ) i2c_inst (
        .clk_i(clk),
        .rst_i(~rst_n),
        .adr_i(wb_adr_i),
        .dat_i(wb_dat_i),
        .dat_o(i2c_dat_o),
        .sel_i(wb_sel_i),
        .cyc_i(i2c_sel),
        .stb_i(i2c_sel),
        .ack_o(i2c_ack_o),
        .we_i(wb_we_i),
        .IRQ(i2c_irq),
        .scl_i(i2c_scl_i),
        .scl_o(i2c_scl_o),
        .scl_oen_o(i2c_scl_oen_o),
        .sda_i(i2c_sda_i),
        .sda_o(i2c_sda_o),
        .sda_oen_o(i2c_sda_oen_o)
    );

    // GPIO Controller
    gpio_edge_detect gpio_inst (
        .clk(clk),
        .rst_n(rst_n),
        .bus_we(gpio_sel && wb_we_i),
        .bus_addr(wb_adr_i[7:0]),
        .bus_wdata(wb_dat_i),
        .bus_rdata(gpio_dat_o),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .irq(gpio_irq)
    );
    
    // GPIO ACK generation
    reg gpio_ack_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gpio_ack_reg <= 1'b0;
        else if (gpio_sel && !gpio_ack_reg)
            gpio_ack_reg <= 1'b1;
        else
            gpio_ack_reg <= 1'b0;
    end
    assign gpio_ack_o = gpio_ack_reg;

endmodule

`default_nettype wire