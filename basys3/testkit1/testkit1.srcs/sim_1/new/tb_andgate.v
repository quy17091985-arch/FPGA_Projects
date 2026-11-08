`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2026 08:40:08 PM
// Design Name: 
// Module Name: tb_andgate
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


module tb_andgate;

    reg [1:0] sw;
    wire led;

    // Goi mach can kiem tra
    and_gate dut (
        .sw(sw),
        .led(led)
    );

    initial begin
        sw = 2'b00;
        #10;

        sw = 2'b01;
        #10;

        sw = 2'b10;
        #10;

        sw = 2'b11;
        #10;

        $finish;
    end

endmodule
