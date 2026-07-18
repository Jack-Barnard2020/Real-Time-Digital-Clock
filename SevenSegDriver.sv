/* ======== Seven Segment Display Driver ========
   Author: Jack Barnard
   Date: 2026/07/11
   Description: Module to drive the 6 Seven Segment Displays on the Altera Terasic DE1-Soc Board
                Takes in a binary string of maximum decimal value 999,999
   Change Log:
   - Initial version (Jack Barnard, 2026/07/11)
   - Added variable number of displays (Jack Barnard, 2026/07/12)
   =============================================== */
/* ======== Parameter/Input/Output Table ========
   Input:
   - clk - clock signal
   - rst - negative reset
   - BinValue - Binary Value
   Outputs:
   - Display - current display being written
   - Segements - Segment values for the current display
   =============================================== */

module SevenSegDriver #(
    parameter int NoOfDisplays = 6,
    parameter int BinWidth = 20
)(
    input logic clk,
    input logic rst,
    input logic [BinWidth - 1:0] BinValue,
    output logic [NoOfDisplays - 1:0] Display,
    output logic [6:0] Segments
);

logic [(NoOfDisplays * 4) - 1:0] bcd_output;
logic start;
logic done;
logic clk_out;

assign start = 1'b1;

// Instantate Binary to BCD converter module
BinToBCD #(.InputWidth(BinWidth), .OutputWidth(NoOfDisplays * 4)) binToBCD (
    .clk         (clk),
    .rst         (rst),
    .start       (start),
    .binary_input(BinValue),
    .bcd_output  (bcd_output),
    .done        (done)
);


// Instantate clk divde module
ClockDivide #(.DesiredClk(1_000_000)) clockDivide (
    .clk    (clk),
    .rst    (rst),
    .clk_out(clk_out)
);

// Internal state tracking for the multiplexer loop
logic [$clog2(NoOfDisplays)-1:0] current_digit;
logic [3:0] active_bcd_nibble;

// 1. Multiplexed display scanning loop
always_ff @(posedge clk_out or negedge rst) begin
    if (!rst) begin
        current_digit <= 3'd0;
    end else begin
        if (current_digit >= 3'd5) begin
            current_digit <= 3'd0;
        end else begin
            current_digit <= current_digit + 1'b1;
        end
    end
end

// 2. Combinational Mux: Select BCD chunk and drive one-hot display pin
always_comb begin
    // Default assignments (support parameterized number of displays)
    Display = {NoOfDisplays{1'b0}};
    active_bcd_nibble = 4'hF;

    if (current_digit < NoOfDisplays) begin
        Display = (1 << current_digit);
        active_bcd_nibble = bcd_output[(current_digit*4) +: 4];
    end
end

// 3. Connect the active BCD digit to the Seven-Segment Decoder
DigitDriver digitDecoder (
    .value(active_bcd_nibble),
    .segments(Segments)
);

endmodule