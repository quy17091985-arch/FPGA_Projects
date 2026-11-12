`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2026 08:16:12 PM
// Design Name: 
// Module Name: button_debounce
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module button_debounce #(
    parameter integer CYCLES = 2000000
)(
    input wire clk,
    input wire button_raw,
    output reg pressed = 0
);

    // Bo dem chong doi
    localparam integer W =
        (CYCLES < 2) ? 1 : $clog2(CYCLES);

    reg meta = 0;
    reg sync = 0;
    reg stable = 0;

    reg [W-1:0] count = 0;

    always @(posedge clk) begin

        meta <= button_raw;
        sync <= meta;

        pressed <= 0;

        if (sync == stable) begin
            count <= 0;
        end
        else if (count == CYCLES - 1) begin

            count <= 0;
            stable <= sync;

            if (sync)
                pressed <= 1;

        end
        else begin
            count <= count + 1'b1;
        end

    end

endmodule
