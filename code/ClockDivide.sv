/* ========= Clock Divider Module =========
   Author: Jack Barnard
   Date: 2026-07-11
   Description: This module takes in the 50 Mhz clock produced by the DE1-Soc Board and divides it down to a desired frequency.
   Change Log:
   - Initial creation of the module. (Jack Barnard, 2026-07-11)
   ========================================== */
/* ========== P/I/O Table ==========
   Parameter: DesiredClk - The desired clock frequency in Hz.
   Input: clk - 50 Mhz clock input
   Input: rst - Reset input (active low)
   Output: clk_out - Output clock at the desired frequency
    =================================== */

module ClockDivide #(
    parameter DesiredClk = 1_000_000 // Default desired clock frequency is 1 MHz
)(
    input logic clk, // 50 Mhz clock input
    input logic rst, // Reset input (active low)
    output logic clk_out // Output clock at the desired frequency
);

initial begin: parameter_check
    if (DesiredClk <= 0) begin
        $fatal("DesiredClk must be greater than 0.");
    end
end

logic [31:0] divider; // Divider value to achieve the desired frequency
logic [31:0] counter; // Counter to keep track of clock cycles

assign divider = 50_000_000 / DesiredClk;

always_ff @(posedge clk, negedge rst) begin
    if (!rst) begin
        counter <= 0; // Reset the counter to 0
        clk_out <= 0; // Reset the output clock to 0
    end else if (counter >= divider) begin
        clk_out <= ~clk_out; // Toggle the output clock
        counter <= 0; // Reset the counter
    end else begin
        counter <= counter + 1;
    end
end

endmodule