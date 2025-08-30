`default_nettype none

module multi_periph_wb_wrapper (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,
    
    // SPI Master 0 interface
    output spi0_sclk,
    output spi0_mosi,
    input  spi0_miso,
    output spi0_cs_n,
    
    // SPI Master 1 interface  
    output spi1_sclk,
    output spi1_mosi,
    input  spi1_miso,
    output spi1_cs_n,
    
    // I2C interface
    inout  i2c_scl,
    inout  i2c_sda,
    
    // GPIO interface
    inout  [1:0] gpio_io,
    
    // Interrupt outputs
    output [2:0] irq_o
);

    wire valid;
    wire write_enable;
    wire read_enable;

    assign valid = wbs_cyc_i && wbs_stb_i;
    assign write_enable = wbs_we_i && valid;
    assign read_enable = ~wbs_we_i && valid;

    // Multi-peripheral top module
    multi_periph_top periph_top (
        .clk(wb_clk_i),
        .rst_n(!wb_rst_i),
        
        // Wishbone interface
        .wb_cyc_i(wbs_cyc_i),
        .wb_stb_i(wbs_stb_i),
        .wb_we_i(wbs_we_i),
        .wb_sel_i(wbs_sel_i),
        .wb_adr_i(wbs_adr_i),
        .wb_dat_i(wbs_dat_i),
        .wb_dat_o(wbs_dat_o),
        .wb_ack_o(wbs_ack_o),
        
        // SPI Master 0 interface
        .spi0_sclk(spi0_sclk),
        .spi0_mosi(spi0_mosi),
        .spi0_miso(spi0_miso),
        .spi0_cs_n(spi0_cs_n),
        
        // SPI Master 1 interface  
        .spi1_sclk(spi1_sclk),
        .spi1_mosi(spi1_mosi),
        .spi1_miso(spi1_miso),
        .spi1_cs_n(spi1_cs_n),
        
        // I2C interface
        .i2c_scl(i2c_scl),
        .i2c_sda(i2c_sda),
        
        // GPIO interface
        .gpio_io(gpio_io),
        
        // Interrupt outputs
        .irq_o(irq_o)
    );

endmodule

`default_nettype wire