/* ======== Binary to BCD Converter Module ========
   Author: Jack Barnard
   Date: 2026-07-11
   Description: This module takes in an x-digit binary number and converts it to a BCD representation.
   Change Log:
    - Initial version (2026-07-11)
   ================================================= */
/* ========= Input/Output Ports ========
   Parameters:
    - InputWidth: The width of the binary input number
    - OutputWidth: The width of the BCD output number
    Inputs:
    - clk: Clock signal for synchronization.
    - rst: Reset signal to initialize the module.
    - binary_input: A binary number input that represents the digits to be converted to BCD.
    - start: A signal to start the conversion process.
    Outputs:
    - bcd_output: A BCD representation of the input binary number.
    - done: A signal indicating that the conversion process is complete.
    ====================================== */

module BinToBCD #(
    parameter InputWidth = 20,
    parameter OutputWidth = ((InputWidth * 302) / 1000 + 1) * 4 // floor(InputWidth * log10(2)) + 1
)(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [InputWidth-1:0] binary_input,
    output logic [OutputWidth-1:0] bcd_output,
    output logic done
);

// Internal Registers 
logic [InputWidth-1:0] binary_reg [0:InputWidth]; 
logic [OutputWidth-1:0] bcd_reg [0:InputWidth]; 
logic valid [0:InputWidth]; 

// Writing data to the initial registers
always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        valid[0]      <= 1'b0;
        binary_reg[0] <= '0;
        bcd_reg[0]    <= '0;
    end else begin
        valid[0]      <= start;
        binary_reg[0] <= binary_input;
        bcd_reg[0]    <= '0;
    end
end

// Pipeline and Calculation Logic
genvar i;
generate
    for (i = 0; i < InputWidth; i++) begin : PIPELINE
        logic [OutputWidth-1:0] bcd_temp;

        // Combinational ADD-3 logic step
        always_comb begin
            bcd_temp = bcd_reg[i];
            for (int j = 0; j < OutputWidth; j = j + 4) begin
                if (bcd_temp[j +: 4] >= 5) begin
                    bcd_temp[j +: 4] = bcd_temp[j +: 4] + 3;
                end
            end
        end

        // Sequential SHIFT step (Pipeline Stage)
        always_ff @(posedge clk or negedge rst) begin
            if (!rst) begin
                valid[i + 1]      <= 1'b0;
                binary_reg[i + 1] <= '0;
                bcd_reg[i + 1]    <= '0;
            end else begin
                valid[i + 1]      <= valid[i];
                // Shift left: MSB of binary moves into LSB of BCD
                bcd_reg[i + 1]    <= {bcd_temp[OutputWidth-2:0], binary_reg[i][InputWidth-1]};
                binary_reg[i + 1] <= {binary_reg[i][InputWidth-2:0], 1'b0};
            end
        end
    end
endgenerate

// Output Assignment
assign bcd_output = bcd_reg[InputWidth];
assign done       = valid[InputWidth];

endmodule