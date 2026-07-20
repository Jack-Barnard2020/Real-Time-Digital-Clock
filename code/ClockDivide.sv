/* ========= Clock Divider Module =========
   Author: Jack Barnard
   Date: 2026-07-11
   Description: This module takes in the 50 Mhz clock produced by the DE1-Soc Board and divides it down to a desired frequency.
   Change Log:
   - Initial creation of the module. (Jack Barnard, 2026-07-11)
   - fixed over divison (Jack Barnard, 2026-07-20)
   ========================================== */
/* ========== P/I/O Table ==========
   Parameter: DesiredClk - The desired clock frequency in Hz.
   Input: clk - 50 Mhz clock input
   Input: rst - Reset input (active low)
   Output: clk_out - Output clock at the desired frequency
    =================================== */

module ClockDivide #(
    parameter DesiredClk = 1_000_000
)(
    input  logic clk,
    input  logic rst,
    output logic clk_out
);
    localparam int TOGGLE_VAL = (50_000_000 / (2 * DesiredClk)) - 1;

    logic [31:0] counter;

    always_ff @(posedge clk, negedge rst) begin
        if (!rst) begin
            counter <= 0;
            clk_out <= 0;
        end else if (counter >= TOGGLE_VAL) begin
            clk_out <= ~clk_out; // Toggles every 1 cycle -> Resulting in a 25 MHz clock
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end
    end

endmodule
