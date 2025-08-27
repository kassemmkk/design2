`default_nettype none

module gpio_edge_detect (
    input  wire        clk,
    input  wire        rst_n,
    
    // Bus interface
    input  wire        bus_we,
    input  wire [7:0]  bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,
    
    // GPIO pins
    input  wire [1:0]  gpio_in,
    output wire [1:0]  gpio_out,
    output wire [1:0]  gpio_oe,
    
    // Interrupt output
    output wire        irq
);

    // Register addresses
    localparam DATAI_ADDR   = 8'h00;
    localparam DATAO_ADDR   = 8'h04;
    localparam DIR_ADDR     = 8'h08;
    localparam EDGE_CFG_ADDR = 8'h0C;
    localparam IM_ADDR      = 8'h10;
    localparam RIS_ADDR     = 8'h14;
    localparam MIS_ADDR     = 8'h18;
    localparam IC_ADDR      = 8'h1C;

    // Registers
    reg [1:0]  datao_reg;
    reg [1:0]  dir_reg;
    reg [3:0]  edge_cfg_reg;  // [1:0] = pin0 config, [3:2] = pin1 config
                              // 00=none, 01=rising, 10=falling, 11=both
    reg [3:0]  im_reg;        // Interrupt mask
    reg [3:0]  ris_reg;       // Raw interrupt status
    
    // Edge detection
    reg [1:0]  gpio_sync1, gpio_sync2;
    wire [1:0] gpio_rise, gpio_fall;
    
    // Synchronize inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gpio_sync1 <= 2'b00;
            gpio_sync2 <= 2'b00;
        end else begin
            gpio_sync1 <= gpio_in;
            gpio_sync2 <= gpio_sync1;
        end
    end
    
    // Edge detection
    assign gpio_rise = gpio_sync1 & ~gpio_sync2;
    assign gpio_fall = ~gpio_sync1 & gpio_sync2;
    
    // Interrupt generation
    wire [3:0] edge_events;
    assign edge_events[0] = gpio_rise[0] & (edge_cfg_reg[1:0] == 2'b01 || edge_cfg_reg[1:0] == 2'b11);
    assign edge_events[1] = gpio_fall[0] & (edge_cfg_reg[1:0] == 2'b10 || edge_cfg_reg[1:0] == 2'b11);
    assign edge_events[2] = gpio_rise[1] & (edge_cfg_reg[3:2] == 2'b01 || edge_cfg_reg[3:2] == 2'b11);
    assign edge_events[3] = gpio_fall[1] & (edge_cfg_reg[3:2] == 2'b10 || edge_cfg_reg[3:2] == 2'b11);
    
    // Raw interrupt status register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ris_reg <= 4'b0000;
        end else begin
            // Set interrupt flags on edge events
            ris_reg <= (ris_reg | edge_events) & ~(bus_we && (bus_addr == IC_ADDR) ? bus_wdata[3:0] : 4'b0000);
        end
    end
    
    // Register writes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            datao_reg <= 2'b00;
            dir_reg <= 2'b00;
            edge_cfg_reg <= 4'b0000;
            im_reg <= 4'b0000;
        end else if (bus_we) begin
            case (bus_addr)
                DATAO_ADDR:   datao_reg <= bus_wdata[1:0];
                DIR_ADDR:     dir_reg <= bus_wdata[1:0];
                EDGE_CFG_ADDR: edge_cfg_reg <= bus_wdata[3:0];
                IM_ADDR:      im_reg <= bus_wdata[3:0];
            endcase
        end
    end
    
    // Register reads
    always @(*) begin
        bus_rdata = 32'h00000000;
        case (bus_addr)
            DATAI_ADDR:   bus_rdata[1:0] = gpio_sync2;
            DATAO_ADDR:   bus_rdata[1:0] = datao_reg;
            DIR_ADDR:     bus_rdata[1:0] = dir_reg;
            EDGE_CFG_ADDR: bus_rdata[3:0] = edge_cfg_reg;
            IM_ADDR:      bus_rdata[3:0] = im_reg;
            RIS_ADDR:     bus_rdata[3:0] = ris_reg;
            MIS_ADDR:     bus_rdata[3:0] = ris_reg & im_reg;
            default:      bus_rdata = 32'h00000000;
        endcase
    end
    
    // GPIO outputs
    assign gpio_out = datao_reg;
    assign gpio_oe = dir_reg;
    
    // Interrupt output
    assign irq = |(ris_reg & im_reg);

endmodule

`default_nettype wire