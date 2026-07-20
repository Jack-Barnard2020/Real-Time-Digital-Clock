/* ======== main module ========
   Author: Jack Barnard
   Date: 2026/07/11
   Description: Takes in the value of the switches and displays it to the seven segment displays
   Change Log:
   - Initial (Jack Barnard, 2026/07/11)
   - Added variable number of displays (Jack Barnard, 2026/07/12)
   - Added start and stop key to clock counter (Jack Barnard, 2026/07/15)
   - Clock adjustment & Setting (Jack Barnard, 2026/07/15)
   - Added live switch preview during configuration (Jack Barnard, 2026/07/15)
   - Added 24 hr and 12 hr switch (Jack Barnard, 2026/07/15)
   - Substantial changes allowing for updated features (Jack Barnard, 2026/07/18)
   - Now adjust clock with push buttons (Jack, Barnard, 2026/07/18)
   - Fixed 12/24 hour switching glitch mid-count (Jack Barnard, 2026/07/18)
   - Fixed slow clocking (Jack Barnard, 2026/07/18)
   - Fixed clock over division (Jack Barnard, 2026/07/20)
   ============================= */
/* ======== Parameter/Input/Output Table ========
   Input
   - SW0 -> SW9 - Switches
   - KEY0 -> KEY3 - Push Buttons (Active-Low)
   - CLK_50 - Clock signal
   output:
   - HEX0 -> HEX5 - Seven Segment Displays
   ================================================ */

module main(
    input logic CLK_50,
    input logic [9:0] SW,
    input logic [3:0] KEY,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

// =========================
//  VARIABLES AND REGISTERS
// =========================
logic clk; // 50 MHz clock signal
logic clk_out; // 1 Hz clock signal from ClockDivide
logic clk_out_prev, clk_out_pulse; // For 1 Hz edge detection
logic rst; // Reset signal (Active Low)

logic [19:0] DisplayedValue; // Value written to the seven segment displays
logic [5:0] HH, MM, SS; // Hours (always 0-23 internally), Minutes, and Seconds
logic [5:0] muxed_hour; // Dynamic formatting container for hours

logic Hour24; // Active high for 24-hour mode

logic Ok, OkPrev, OkPulse;
logic Add, AddPrev, AddPulse;

logic [5:0] Display; // Controls which display is being written to
logic [6:0] Segments; // Controls which segments are illuminated

enum logic [1:0] {COUNT, HOURS, MINS, SECS} next_state, present_state;


// =============
//  ASSIGNMENTS
// =============
assign clk = CLK_50;
assign rst = KEY[0];
assign Hour24 = SW[9];

// Combinational Mux: Dynamically changes format based on the switch state instantly
assign muxed_hour = Hour24 ? HH : 
                    (HH == 6'd0)  ? 6'd12 : 
                    (HH > 6'd12)  ? (HH - 6'd12) : HH;

// Combines the dynamically converted hours, minutes, and seconds 
assign DisplayedValue = (muxed_hour * 10_000) + (MM * 100) + SS;


// ===============
//  Instantiations
// ===============

// Desired clk need to be twice as fast as desired due to edge check
ClockDivide #(.DesiredClk(2)) clock_divider (
    .clk(clk),
    .rst(rst),
    .clk_out(clk_out)
);

SevenSegDriver #(.NoOfDisplays(6), .BinWidth(20)) display_driver (
    .clk(clk),
    .rst(rst),
    .BinValue(DisplayedValue), 
    .Display(Display),
    .Segments(Segments)
);


// ================
//  EDGE DETECTION
// ================

always_ff @(posedge clk, negedge rst) begin : EdgeDetection
    if (!rst) begin
        Add         <= 1'b0;
        AddPrev     <= 1'b0;
        Ok          <= 1'b0;
        OkPrev      <= 1'b0;
        clk_out_prev<= 1'b0;
    end else begin
        Add         <= ~KEY[3]; // Inverting active-low buttons
        Ok          <= ~KEY[2];

        AddPrev     <= Add;
        OkPrev      <= Ok;
        
        clk_out_prev<= clk_out; // Tracking the 1 Hz clock edge
    end
end

assign AddPulse       = Add && !AddPrev;
assign OkPulse        = Ok && !OkPrev;
assign clk_out_pulse  = clk_out && !clk_out_prev;


// ======================
//  FINITE STATE MACHINE 
// ======================

always_comb begin : NextStateLogic
    next_state = present_state;

    unique case (present_state)
        COUNT: begin
            if (OkPulse) next_state = HOURS;
        end
        HOURS: begin
            if (OkPulse) next_state = MINS;          
        end
        MINS: begin
            if (OkPulse) next_state = SECS;            
        end
        SECS: begin
            if (OkPulse) next_state = COUNT;
        end
    endcase
end

always_ff @(posedge clk, negedge rst) begin : ClockLogic
    if (!rst) begin
        present_state <= COUNT; 

        HH <= 6'd0;
        MM <= 6'd0;
        SS <= 6'd0;

        HEX0 <= 7'b1111111;
        HEX1 <= 7'b1111111;
        HEX2 <= 7'b1111111;
        HEX3 <= 7'b1111111;
        HEX4 <= 7'b1111111;
        HEX5 <= 7'b1111111;

    end else begin
        present_state <= next_state;

        // Configuration and counting logic
        if (present_state == HOURS) begin
            if (AddPulse) begin
                // Internally steps 0-23. The muxed_hour handles mapping it to 1-12 on screen live.
                HH <= (HH == 23) ? 6'd0 : HH + 1;
            end
        end else if (present_state == MINS) begin
            if (AddPulse) begin
                MM <= (MM == 59) ? 6'd0 : MM + 1;
            end
        end else if (present_state == SECS) begin  
            if (AddPulse) begin
                SS <= (SS == 59) ? 6'd0 : SS + 1;
            end
        // Main counter tracking logic (Simplified to standard 24-hour sequence)
        end else if (present_state == COUNT && clk_out_pulse) begin
            if (SS == 59) begin
                SS <= 0;
                if (MM == 59) begin
                    MM <= 0;
                    HH <= (HH == 23) ? 6'd0 : HH + 1;
                end else begin
                    MM <= MM + 1;
                end
            end else begin
                SS <= SS + 1;
            end
        end

        // ==============
        //  Output Logic
        // ==============
        if (Display[0]) HEX0 <= Segments;
        if (Display[1]) HEX1 <= Segments;
        if (Display[2]) HEX2 <= Segments;
        if (Display[3]) HEX3 <= Segments;
        if (Display[4]) HEX4 <= Segments;
        if (Display[5]) HEX5 <= Segments;
    end
end

endmodule
