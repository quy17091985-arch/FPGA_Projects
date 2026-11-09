`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2026 09:11:12 PM
// Design Name: 
// Module Name: tb_record_gate_startup
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


module tb_record_gate_startup;
    reg clk = 0;
    reg [2:0] sw = 3'b000;
    reg sw15 = 0;
    reg btnc = 0;

wire [4:0] led;
wire [6:0] seg;
wire [3:0] an;
wire dp;

integer errors = 0;

always #5 clk = ~clk;

record_gate #(
    .BTN_DEBOUNCE_CYCLES(3),
    .SCAN_DIV(3),
    .PAGE_CYCLES(200)
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

task tick;
input integer n;
begin
repeat (n) @(negedge clk);
end
endtask

task save_row;
input [2:0] value;
begin
    sw = value;
    tick(8);

    btnc = 1;
    tick(12);

    btnc = 0;
    tick(12);
end
endtask

initial begin

// TEST 1: Khoi dong ON15
tick(10);

if (dut.screen_word !== "ON15" ||
    led[4] !== 1'b0) begin
$display("FAIL: KHOI DONG ON15");
    errors = errors + 1;
end
else
$display("PASS: KHOI DONG ON15");

// TEST 2: Bat SW15, hien GHI
    sw15 = 1;
    tick(10);

if (dut.screen_word !== " GHI") begin
$display("FAIL: CHE DO GHI");
    errors = errors + 1;
end
else
    $display("PASS: CHE DO GHI");

// TEST 3: Nhap bang AND
save_row(3'b000);
save_row(3'b010);
save_row(3'b100);
save_row(3'b111);

if (dut.recorded_rows !== 4'b1111 ||
    dut.y_zero !== 4'b0111 ||
    dut.y_one !== 4'b1000) begin
$display("FAIL: LUU BANG AND");
    errors = errors + 1;
end
else
$display("PASS: LUU BANG AND");

// TEST 4: Tat SW15, nhan dien AND
sw15 = 0;
tick(10);

if (dut.screen_word !== " And" ||
    dut.matches !== 8'b00000001) begin
$display("FAIL: NHAN DIEN AND");
    errors = errors + 1;
end
else
$display("PASS: NHAN DIEN AND");

// TEST 5: Bat SW15 de xoa bang cu
    sw15 = 1;
    tick(10);

if (dut.recorded_rows !== 4'b0000 ||
    dut.screen_word !== " GHI") begin
$display("FAIL: RESET BANG CU");
    errors = errors + 1;
end
else
$display("PASS: RESET BANG CU");

// TEST 6: Tat SW15 khi chua ghi
sw15 = 0;
tick(10);

if (dut.screen_word !== " LOI" ||
    led[4] !== 1'b1) begin
$display("FAIL: NHAN DIEN LOI");
    errors = errors + 1;
end
else
$display("PASS: NHAN DIEN LOI");

if (errors == 0)
$display("PASS: TAT CA TEST DEU DAT");
else
$display("FAIL: CO %0d LOI", errors);

$finish;
end

endmodule
