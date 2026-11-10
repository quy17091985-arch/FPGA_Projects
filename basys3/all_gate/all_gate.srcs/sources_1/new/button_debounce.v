`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 09:05:14 PM
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
    output reg pressed = 1'b0
);

    // Bit dem
    localparam integer W =
        (CYCLES < 2) ? 1 : $clog2(CYCLES);

    // Dong bo nut nhan
    reg meta = 1'b0;
    reg sync = 1'b0;
    reg stable = 1'b0;

    reg [W-1:0] count = 0;

    always @(posedge clk) begin
        meta <= button_raw;
        sync <= meta;

        pressed <= 1'b0;

        if (sync == stable) begin
            count <= 0;
        end
        else if (count == CYCLES - 1) begin
            count <= 0;
            stable <= sync;

            if (sync)
                pressed <= 1'b1;
        end
        else begin
            count <= count + 1'b1;
        end
    end

endmodule

