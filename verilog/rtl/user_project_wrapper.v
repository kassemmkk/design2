// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
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

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

multi_periph_wb_wrapper mprj (
	.VPWR(vccd1),	// User area 1 1.8V power
	.VGND(vssd1),	// User area 1 digital ground

    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),

    // MGMT SoC Wishbone Slave

    .wbs_cyc_i(wbs_cyc_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),

    // IRQ
    .user_irq(user_irq),
    
    // SPI Master 0 - mapped to io_in[10:7], io_out[10:7]
    .spi0_miso(io_in[7]),
    .spi0_mosi(io_out[8]),
    .spi0_sclk(io_out[9]),
    .spi0_csb(io_out[10]),
    
    // SPI Master 1 - mapped to io_in[14:11], io_out[14:11]  
    .spi1_miso(io_in[11]),
    .spi1_mosi(io_out[12]),
    .spi1_sclk(io_out[13]),
    .spi1_csb(io_out[14]),
    
    // I2C - mapped to io_in[16:15], io_out[16:15] (open-drain)
    .i2c_scl_i(io_in[15]),
    .i2c_scl_o(io_out[15]),
    .i2c_scl_oen_o(io_oeb[15]),
    .i2c_sda_i(io_in[16]),
    .i2c_sda_o(io_out[16]),
    .i2c_sda_oen_o(io_oeb[16]),
    
    // GPIO - mapped to io_in[18:17], io_out[18:17]
    .gpio_in(io_in[18:17]),
    .gpio_out(gpio_out_internal),
    .gpio_oe(gpio_oe_internal)
);

// Unused logic analyzer signals
assign la_data_out = 128'h0;

// Configure unused I/O as inputs
assign io_out[6:0] = 7'h0;
assign io_oeb[6:0] = 7'h7F;  // All inputs

assign io_out[37:19] = 19'h0;
assign io_oeb[37:19] = 19'h7FFFF;  // All inputs

// SPI outputs are always enabled
assign io_oeb[10:8] = 3'b000;   // SPI0 outputs
assign io_oeb[14:12] = 3'b000;  // SPI1 outputs

// Fix undriven signals
assign io_out[7] = 1'b0;
assign io_oeb[7] = 1'b1;  // Input
assign io_out[11] = 1'b0;
assign io_oeb[11] = 1'b1;  // Input

// GPIO signals
wire [1:0] gpio_out_internal, gpio_oe_internal;
assign io_out[18:17] = gpio_out_internal;
assign io_oeb[18:17] = ~gpio_oe_internal;  // Invert for Caravel convention (0=output, 1=input)

endmodule	// user_project_wrapper

`default_nettype wire
