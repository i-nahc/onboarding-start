module spi_peripheral (
    input wire clk,
    input wire rst_n,
    
    input wire COPI,
    input wire nCS,
    input wire SCLK,

    // from specs
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle 
);

    // need to synchronize nCS, SCLK, COPI
    reg [1:0] COPI_synced;
    reg [1:0] nCS_synced;
    reg [1:0] SCLK_synced;

    // tracking sclk edges (up to 16 reads = 5 bits needed to count)
    reg[4:0] SCLK_count;

    reg [15:0] data;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            en_reg_out_7_0 <= '0;
            en_reg_out_15_8 <= '0;
            en_reg_pwm_7_0 <= '0;
            en_reg_pwm_15_8 <= '0;
            pwm_duty_cycle <= '0;

            COPI_synced <= '0;
            nCS_synced <= '0;
            SCLK_synced <= '0;

            SCLK_count <= '0;
            data <= '0;
        end

        else begin
            // shift in
            COPI_synced <= {COPI_synced[0], COPI};
            nCS_synced <= {nCS_synced[0], nCS};
            SCLK_synced <= {SCLK_synced[0], SCLK};

            // notes: Transaction starts on nCS falling edge.   => condition: nCS = 2'b10 ; was high now low
            //        Data captured on SCLK rising edge.        => condition: SCLK = 2'b01 ; was low now high  
            if(nCS_synced == 2'b10) begin
                // reset
                SCLK_count <= '0;
                data <= '0;
            end

            
            else if(SCLK_synced == 2'b01) begin
                if(SCLK_count < 5'd16) begin
                    data <= {data[14:0], COPI_synced[1]};
                    SCLK_count += 1;
                end
            end

            // note from docs: Update registers only after the entire transaction completes (on nCS rising edge)
            // also make sure we read 16 bits
            // reads not handled
            if(data[15] && SCLK_count == 5'd16 && nCS_synced == 2'b01) begin
                case(data[14:8])
                    7'h00: en_reg_out_7_0 <= data[7:0];
                    7'h01: en_reg_out_15_8 <= data[7:0];
                    7'h02: en_reg_pwm_7_0 <= data[7:0];
                    7'h03: en_reg_pwm_15_8 <= data[7:0];
                    7'h04: pwm_duty_cycle <= data[7:0];
                    default:;
                endcase
            end
        end
    end
endmodule