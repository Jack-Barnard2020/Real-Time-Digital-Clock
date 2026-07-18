/* ========= Digit Driver =========
   Author: Jack Barnard
   Date: 2026-07-11
   Description: Given a 4 bit binary number provides the requied segmemts to be illuminated on a seven segment display
                Module is written for the Altera Terasic DE1-SoC board
   Change Log:
   ======================================== */
/* ========= Parameter/Input/Output Table =========
   Input:
   - value
   Output:
   - Segments
   ================================================ */

module DigitDriver(
    input logic [3:0] value,
    output logic [6:0] segments
);

always_comb begin
    case(value)
        4'd0: segments = 7'b1000000; // Displays '0'
        4'd1: segments = 7'b1111001; // Displays '1'
        4'd2: segments = 7'b0100100; // Displays '2'
        4'd3: segments = 7'b0110000; // Displays '3'
        4'd4: segments = 7'b0011001; // Displays '4'
        4'd5: segments = 7'b0010010; // Displays '5'
        4'd6: segments = 7'b0000010; // Displays '6'
        4'd7: segments = 7'b1111000; // Displays '7'
        4'd8: segments = 7'b0000000; // Displays '8'
        4'd9: segments = 7'b0010000; // Displays '9'
        default: segments = 7'b1111111; // Turns all segments off for errors
    endcase
end

endmodule
