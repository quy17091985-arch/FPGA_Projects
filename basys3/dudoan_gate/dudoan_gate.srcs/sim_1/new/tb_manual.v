`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2026 08:34:16 PM
// Design Name: 
// Module Name: tb_manual
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


module tb_manual;

    reg clk = 0;
    always #5 clk = ~clk;

    // Cong tac ban dau
    reg [2:0] sw = 3'b000;
    reg sw15 = 0;
    reg btnc = 0;

    wire [4:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire dp;

    record_gate #(
        .BTN_DEBOUNCE_CYCLES(3),
        .SCAN_DIV(3),
        .PAGE_CYCLES(200000)
    ) dut (
        .clk(clk),
        .sw(sw),
        .sw15(sw15),
        .btnc(btnc),
        .led(led),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

endmodule
