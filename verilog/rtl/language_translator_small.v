`default_nettype none
`timescale 1ns / 1ps

module language_translator_small (
    input  wire        clk,
    input  wire        rst_n,
    
    // Bus interface
    input  wire        bus_we,
    input  wire [7:0]  bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,
    
    // External interface (via logic analyzer)
    output wire [7:0]  ext_data_out,
    input  wire [7:0]  ext_data_in,
    output wire        ext_valid_out,
    input  wire        ext_valid_in,
    output wire        ext_ready_out,
    input  wire        ext_ready_in,
    
    // Interrupt output
    output wire        irq
);

    // Register addresses
    localparam CTRL_ADDR     = 8'h00;
    localparam STATUS_ADDR   = 8'h04;
    localparam CONFIG_ADDR   = 8'h08;
    localparam INPUT_ADDR    = 8'h10;
    localparam OUTPUT_ADDR   = 8'h14;
    localparam IRQ_EN_ADDR   = 8'h18;
    localparam IRQ_STAT_ADDR = 8'h1C;
    
    // Control register bits
    localparam CTRL_START    = 0;
    localparam CTRL_RESET    = 1;
    
    // Status register bits
    localparam STAT_BUSY     = 0;
    localparam STAT_DONE     = 1;
    localparam STAT_ERROR    = 2;
    
    // State machine
    localparam IDLE          = 2'b00;
    localparam TRANSLATE     = 2'b01;
    localparam DONE          = 2'b10;
    
    // Registers
    reg [31:0] ctrl_reg;
    reg [31:0] status_reg;
    reg [31:0] config_reg;
    reg [31:0] input_reg;
    reg [31:0] output_reg;
    reg [31:0] irq_en_reg;
    reg [31:0] irq_stat_reg;
    
    // State machine
    reg [1:0]  state;
    reg [1:0]  next_state;
    
    // Control signals
    wire start_cmd = ctrl_reg[CTRL_START];
    wire reset_cmd = ctrl_reg[CTRL_RESET];
    
    // Status signals
    wire busy = (state != IDLE);
    wire done = (state == DONE);
    
    // External interface
    assign ext_data_out = input_reg[7:0];
    assign ext_valid_out = (state == TRANSLATE);
    assign ext_ready_out = 1'b1;
    
    // Interrupt generation
    assign irq = |(irq_stat_reg & irq_en_reg);
    
    // Bus read logic
    always @(*) begin
        case (bus_addr)
            CTRL_ADDR:     bus_rdata = ctrl_reg;
            STATUS_ADDR:   bus_rdata = status_reg;
            CONFIG_ADDR:   bus_rdata = config_reg;
            INPUT_ADDR:    bus_rdata = input_reg;
            OUTPUT_ADDR:   bus_rdata = output_reg;
            IRQ_EN_ADDR:   bus_rdata = irq_en_reg;
            IRQ_STAT_ADDR: bus_rdata = irq_stat_reg;
            default:       bus_rdata = 32'h00000000;
        endcase
    end
    
    // Register write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 32'h00000000;
            config_reg <= 32'h00000000;
            input_reg <= 32'h00000000;
            irq_en_reg <= 32'h00000000;
        end else if (bus_we) begin
            case (bus_addr)
                CTRL_ADDR:     ctrl_reg <= bus_wdata;
                CONFIG_ADDR:   config_reg <= bus_wdata;
                INPUT_ADDR:    input_reg <= bus_wdata;
                IRQ_EN_ADDR:   irq_en_reg <= bus_wdata;
                IRQ_STAT_ADDR: irq_stat_reg <= irq_stat_reg & ~bus_wdata; // W1C
                default: ;
            endcase
        end else begin
            // Auto-clear start bit
            ctrl_reg[CTRL_START] <= 1'b0;
        end
    end
    
    // Status register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 32'h00000000;
        end else begin
            status_reg[STAT_BUSY] <= busy;
            status_reg[STAT_DONE] <= done;
            status_reg[STAT_ERROR] <= 1'b0; // No error handling in simple version
        end
    end
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else if (reset_cmd) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start_cmd) begin
                    next_state = TRANSLATE;
                end
            end
            TRANSLATE: begin
                if (ext_ready_in && ext_valid_in) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // Output register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_reg <= 32'h00000000;
            irq_stat_reg <= 32'h00000000;
        end else if (state == TRANSLATE && ext_ready_in && ext_valid_in) begin
            output_reg <= {24'h000000, ext_data_in};
            irq_stat_reg[STAT_DONE] <= 1'b1;
        end else if (bus_we && bus_addr == IRQ_STAT_ADDR) begin
            irq_stat_reg <= irq_stat_reg & ~bus_wdata; // W1C
        end
    end

endmodule

`default_nettype wire