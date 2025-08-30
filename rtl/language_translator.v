`default_nettype none

module language_translator (
    input  wire        clk,
    input  wire        rst_n,
    
    // Wishbone interface
    input  wire        bus_cyc,
    input  wire        bus_stb,
    input  wire        bus_we,
    input  wire [3:0]  bus_sel,
    input  wire [7:0]  bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,
    output reg         bus_ack,
    
    // External interface for translation services
    output wire        ext_req,
    output wire [7:0]  ext_cmd,
    output wire [31:0] ext_data,
    input  wire        ext_ack,
    input  wire [31:0] ext_result,
    
    // Interrupt output
    output wire        irq
);

    // Register map
    localparam REG_CONTROL      = 8'h00;  // Control register
    localparam REG_STATUS       = 8'h04;  // Status register
    localparam REG_SRC_LANG     = 8'h08;  // Source language
    localparam REG_DST_LANG     = 8'h0C;  // Destination language
    localparam REG_INPUT_DATA   = 8'h10;  // Input data (write)
    localparam REG_OUTPUT_DATA  = 8'h14;  // Output data (read)
    localparam REG_INPUT_LEN    = 8'h18;  // Input length
    localparam REG_OUTPUT_LEN   = 8'h1C;  // Output length
    localparam REG_IRQ_MASK     = 8'h20;  // Interrupt mask
    localparam REG_IRQ_STATUS   = 8'h24;  // Interrupt status
    localparam REG_IRQ_CLEAR    = 8'h28;  // Interrupt clear
    localparam REG_BUFFER_CTRL  = 8'h2C;  // Buffer control
    
    // Language codes
    localparam LANG_ENGLISH     = 8'h01;
    localparam LANG_SPANISH     = 8'h02;
    localparam LANG_FRENCH      = 8'h03;
    localparam LANG_GERMAN      = 8'h04;
    localparam LANG_ITALIAN     = 8'h05;
    localparam LANG_PORTUGUESE  = 8'h06;
    localparam LANG_CHINESE     = 8'h07;
    localparam LANG_JAPANESE    = 8'h08;
    localparam LANG_KOREAN      = 8'h09;
    localparam LANG_ARABIC      = 8'h0A;
    
    // Internal registers
    reg [31:0] control_reg;
    reg [31:0] status_reg;
    reg [7:0]  src_lang_reg;
    reg [7:0]  dst_lang_reg;
    reg [15:0] input_len_reg;
    reg [15:0] output_len_reg;
    reg [31:0] irq_mask_reg;
    reg [31:0] irq_status_reg;
    reg [31:0] buffer_ctrl_reg;
    
    // Input/Output buffers (256 bytes each)
    reg [7:0]  input_buffer [0:255];
    reg [7:0]  output_buffer [0:255];
    reg [7:0]  input_ptr;
    reg [7:0]  output_ptr;
    
    // Translation state machine
    reg [2:0]  trans_state;
    reg [7:0]  trans_counter;
    reg        trans_busy;
    reg        trans_done;
    reg        trans_error;
    
    localparam STATE_IDLE       = 3'b000;
    localparam STATE_PREPARE    = 3'b001;
    localparam STATE_TRANSLATE  = 3'b010;
    localparam STATE_RECEIVE    = 3'b011;
    localparam STATE_COMPLETE   = 3'b100;
    localparam STATE_ERROR      = 3'b101;
    
    // Control register bits
    wire start_trans = control_reg[0];
    wire reset_buffers = control_reg[1];
    wire enable_trans = control_reg[2];
    
    // Status register bits
    always @(*) begin
        status_reg = {
            16'h0000,           // Reserved
            trans_error,        // [15] Translation error
            trans_done,         // [14] Translation complete
            trans_busy,         // [13] Translation in progress
            1'b0,               // [12] Reserved
            (input_ptr == 8'hFF),   // [11] Input buffer full
            (input_ptr == 8'h00),   // [10] Input buffer empty
            (output_ptr == 8'hFF),  // [9] Output buffer full
            (output_ptr == 8'h00),  // [8] Output buffer empty
            trans_state,        // [7:5] Current state
            5'b00000            // [4:0] Reserved
        };
    end
    
    // Interrupt generation
    wire trans_complete_irq = trans_done && irq_mask_reg[0];
    wire trans_error_irq = trans_error && irq_mask_reg[1];
    wire buffer_full_irq = (input_ptr == 8'hFF) && irq_mask_reg[2];
    
    assign irq = trans_complete_irq || trans_error_irq || buffer_full_irq;
    
    // External interface
    assign ext_req = (trans_state == STATE_TRANSLATE);
    assign ext_cmd = {src_lang_reg[3:0], dst_lang_reg[3:0]};
    assign ext_data = {input_buffer[trans_counter+3], input_buffer[trans_counter+2], 
                       input_buffer[trans_counter+1], input_buffer[trans_counter]};
    
    // Wishbone interface
    wire valid_access = bus_cyc && bus_stb;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_ack <= 1'b0;
        end else begin
            bus_ack <= valid_access && !bus_ack;
        end
    end
    
    // Register read/write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_reg <= 32'h00000000;
            src_lang_reg <= LANG_ENGLISH;
            dst_lang_reg <= LANG_SPANISH;
            input_len_reg <= 16'h0000;
            output_len_reg <= 16'h0000;
            irq_mask_reg <= 32'h00000000;
            irq_status_reg <= 32'h00000000;
            buffer_ctrl_reg <= 32'h00000000;
            input_ptr <= 8'h00;
            output_ptr <= 8'h00;
            bus_rdata <= 32'h00000000;
        end else if (valid_access) begin
            if (bus_we) begin
                // Write operations
                case (bus_addr)
                    REG_CONTROL: begin
                        if (bus_sel[0]) control_reg[7:0] <= bus_wdata[7:0];
                        if (bus_sel[1]) control_reg[15:8] <= bus_wdata[15:8];
                        if (bus_sel[2]) control_reg[23:16] <= bus_wdata[23:16];
                        if (bus_sel[3]) control_reg[31:24] <= bus_wdata[31:24];
                    end
                    REG_SRC_LANG: begin
                        if (bus_sel[0]) src_lang_reg <= bus_wdata[7:0];
                    end
                    REG_DST_LANG: begin
                        if (bus_sel[0]) dst_lang_reg <= bus_wdata[7:0];
                    end
                    REG_INPUT_DATA: begin
                        // Write to input buffer
                        if (input_ptr < 8'hFC) begin
                            if (bus_sel[0]) begin
                                input_buffer[input_ptr] <= bus_wdata[7:0];
                                input_ptr <= input_ptr + 1;
                            end
                            if (bus_sel[1]) begin
                                input_buffer[input_ptr+1] <= bus_wdata[15:8];
                                input_ptr <= input_ptr + 2;
                            end
                            if (bus_sel[2]) begin
                                input_buffer[input_ptr+2] <= bus_wdata[23:16];
                                input_ptr <= input_ptr + 3;
                            end
                            if (bus_sel[3]) begin
                                input_buffer[input_ptr+3] <= bus_wdata[31:24];
                                input_ptr <= input_ptr + 4;
                            end
                        end
                    end
                    REG_INPUT_LEN: begin
                        if (bus_sel[0]) input_len_reg[7:0] <= bus_wdata[7:0];
                        if (bus_sel[1]) input_len_reg[15:8] <= bus_wdata[15:8];
                    end
                    REG_IRQ_MASK: begin
                        if (bus_sel[0]) irq_mask_reg[7:0] <= bus_wdata[7:0];
                        if (bus_sel[1]) irq_mask_reg[15:8] <= bus_wdata[15:8];
                        if (bus_sel[2]) irq_mask_reg[23:16] <= bus_wdata[23:16];
                        if (bus_sel[3]) irq_mask_reg[31:24] <= bus_wdata[31:24];
                    end
                    REG_IRQ_CLEAR: begin
                        // Write-1-to-clear
                        irq_status_reg <= irq_status_reg & ~bus_wdata;
                    end
                    REG_BUFFER_CTRL: begin
                        if (bus_sel[0]) buffer_ctrl_reg[7:0] <= bus_wdata[7:0];
                        if (bus_sel[1]) buffer_ctrl_reg[15:8] <= bus_wdata[15:8];
                        if (bus_sel[2]) buffer_ctrl_reg[23:16] <= bus_wdata[23:16];
                        if (bus_sel[3]) buffer_ctrl_reg[31:24] <= bus_wdata[31:24];
                        
                        // Buffer reset
                        if (bus_wdata[0]) begin
                            input_ptr <= 8'h00;
                        end
                        if (bus_wdata[1]) begin
                            output_ptr <= 8'h00;
                        end
                    end
                endcase
            end else begin
                // Read operations
                case (bus_addr)
                    REG_CONTROL:     bus_rdata <= control_reg;
                    REG_STATUS:      bus_rdata <= status_reg;
                    REG_SRC_LANG:    bus_rdata <= {24'h000000, src_lang_reg};
                    REG_DST_LANG:    bus_rdata <= {24'h000000, dst_lang_reg};
                    REG_OUTPUT_DATA: begin
                        // Read from output buffer
                        if (output_ptr < output_len_reg) begin
                            bus_rdata <= {output_buffer[output_ptr+3], output_buffer[output_ptr+2],
                                         output_buffer[output_ptr+1], output_buffer[output_ptr]};
                            output_ptr <= output_ptr + 4;
                        end else begin
                            bus_rdata <= 32'h00000000;
                        end
                    end
                    REG_INPUT_LEN:   bus_rdata <= {16'h0000, input_len_reg};
                    REG_OUTPUT_LEN:  bus_rdata <= {16'h0000, output_len_reg};
                    REG_IRQ_MASK:    bus_rdata <= irq_mask_reg;
                    REG_IRQ_STATUS:  bus_rdata <= irq_status_reg;
                    REG_BUFFER_CTRL: bus_rdata <= buffer_ctrl_reg;
                    default:         bus_rdata <= 32'h00000000;
                endcase
            end
        end
    end
    
    // Translation state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trans_state <= STATE_IDLE;
            trans_counter <= 8'h00;
            trans_busy <= 1'b0;
            trans_done <= 1'b0;
            trans_error <= 1'b0;
            output_len_reg <= 16'h0000;
        end else begin
            case (trans_state)
                STATE_IDLE: begin
                    trans_busy <= 1'b0;
                    trans_done <= 1'b0;
                    trans_error <= 1'b0;
                    if (start_trans && enable_trans && (input_len_reg > 0)) begin
                        trans_state <= STATE_PREPARE;
                        trans_busy <= 1'b1;
                        trans_counter <= 8'h00;
                    end
                end
                
                STATE_PREPARE: begin
                    // Prepare for translation
                    output_ptr <= 8'h00;
                    output_len_reg <= 16'h0000;
                    trans_state <= STATE_TRANSLATE;
                end
                
                STATE_TRANSLATE: begin
                    // Send translation request
                    if (ext_ack) begin
                        trans_state <= STATE_RECEIVE;
                    end
                end
                
                STATE_RECEIVE: begin
                    // Receive translated data
                    if (ext_ack) begin
                        // Store result in output buffer
                        if (output_len_reg < 252) begin
                            output_buffer[output_len_reg] <= ext_result[7:0];
                            output_buffer[output_len_reg+1] <= ext_result[15:8];
                            output_buffer[output_len_reg+2] <= ext_result[23:16];
                            output_buffer[output_len_reg+3] <= ext_result[31:24];
                            output_len_reg <= output_len_reg + 4;
                        end
                        
                        trans_counter <= trans_counter + 4;
                        if (trans_counter >= input_len_reg) begin
                            trans_state <= STATE_COMPLETE;
                        end else begin
                            trans_state <= STATE_TRANSLATE;
                        end
                    end
                end
                
                STATE_COMPLETE: begin
                    trans_busy <= 1'b0;
                    trans_done <= 1'b1;
                    irq_status_reg[0] <= 1'b1;  // Translation complete interrupt
                    trans_state <= STATE_IDLE;
                end
                
                STATE_ERROR: begin
                    trans_busy <= 1'b0;
                    trans_error <= 1'b1;
                    irq_status_reg[1] <= 1'b1;  // Translation error interrupt
                    trans_state <= STATE_IDLE;
                end
                
                default: begin
                    trans_state <= STATE_IDLE;
                end
            endcase
            
            // Clear start bit after use
            if (start_trans) begin
                control_reg[0] <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire