`timescale 1ns / 1ps
`default_nettype none

module multi_periph_wb_wrapper (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
`endif

    // Wishbone Slave ports (WB MI A)
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire        wbs_stb_i,
    input  wire        wbs_cyc_i,
    input  wire        wbs_we_i,
    input  wire [3:0]  wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output wire        wbs_ack_o,
    output wire [31:0] wbs_dat_o,
    
    // Interrupt outputs
    output wire [2:0]  user_irq,
    
    // SPI Master 0 interface
    input  wire        spi0_miso,
    output wire        spi0_mosi,
    output wire        spi0_sclk,
    output wire        spi0_csb,
    
    // SPI Master 1 interface  
    input  wire        spi1_miso,
    output wire        spi1_mosi,
    output wire        spi1_sclk,
    output wire        spi1_csb,
    
    // I2C interface
    input  wire        i2c_scl_i,
    output wire        i2c_scl_o,
    output wire        i2c_scl_oen_o,
    input  wire        i2c_sda_i,
    output wire        i2c_sda_o,
    output wire        i2c_sda_oen_o,
    
    // GPIO interface
    input  wire [1:0]  gpio_in,
    output wire [1:0]  gpio_out,
    output wire [1:0]  gpio_oe
);

    wire spi0_irq, spi1_irq, i2c_irq, gpio_irq;
    
    // Interrupt mapping
    assign user_irq[0] = spi0_irq;
    assign user_irq[1] = spi1_irq;
    assign user_irq[2] = i2c_irq | gpio_irq;  // OR I2C and GPIO interrupts

    // Main peripheral integration
    multi_periph_top periph_top (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        
        // Wishbone interface
        .wb_cyc_i(wbs_cyc_i),
        .wb_stb_i(wbs_stb_i),
        .wb_we_i(wbs_we_i),
        .wb_sel_i(wbs_sel_i),
        .wb_adr_i(wbs_adr_i),
        .wb_dat_i(wbs_dat_i),
        .wb_dat_o(wbs_dat_o),
        .wb_ack_o(wbs_ack_o),
        
        // SPI Master 0
        .spi0_miso(spi0_miso),
        .spi0_mosi(spi0_mosi),
        .spi0_sclk(spi0_sclk),
        .spi0_csb(spi0_csb),
        .spi0_irq(spi0_irq),
        
        // SPI Master 1
        .spi1_miso(spi1_miso),
        .spi1_mosi(spi1_mosi),
        .spi1_sclk(spi1_sclk),
        .spi1_csb(spi1_csb),
        .spi1_irq(spi1_irq),
        
        // I2C
        .i2c_scl_i(i2c_scl_i),
        .i2c_scl_o(i2c_scl_o),
        .i2c_scl_oen_o(i2c_scl_oen_o),
        .i2c_sda_i(i2c_sda_i),
        .i2c_sda_o(i2c_sda_o),
        .i2c_sda_oen_o(i2c_sda_oen_o),
        .i2c_irq(i2c_irq),
        
        // GPIO
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .gpio_irq(gpio_irq)
    );

endmodule

`default_nettype wire