`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2026 08:18:05 PM
// Design Name: 
// Module Name: tb_led_output
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


module tb_led_output;

    // Tin hieu dau vao
    reg clk = 0;
    reg [5:0] sw = 0;
    reg sw15 = 0;

    reg btnU = 0;
    reg btnR = 0;
    reg btnD = 0;
    reg btnL = 0;
    reg btnC = 0;

    wire [6:0] seg;
    wire [3:0] an;
    wire dp;

    integer errors = 0;
    integer total = 0;

    // Clock 100 MHz
    always #5 clk = ~clk;

    // Goi module chinh
    led_output #(
        .BTN_FILTER(3),
        .SCAN_TICKS(3)
    ) dut (
        .clk(clk),
        .sw(sw),
        .sw15(sw15),
        .btnU(btnU),
        .btnR(btnR),
        .btnD(btnD),
        .btnL(btnL),
        .btnC(btnC),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    // Cho n chu
    task wait_clk;
        input integer n;
        begin
            repeat(n) @(negedge clk);
        end
    endtask

    // Nhan va tha button
    // 0=C, 1=L, 2=R, 3=U, 4=D
    task click_button;
        input integer id;
        begin
            case (id)
                0: btnC = 1;
                1: btnL = 1;
                2: btnR = 1;
                3: btnU = 1;
                4: btnD = 1;
            endcase

            wait_clk(12);

            btnC = 0;
            btnL = 0;
            btnR = 0;
            btnU = 0;
            btnD = 0;

            wait_clk(12);
        end
    endtask

    // Luu mot ky tu
    task save_char;
        input [5:0] code;
        begin
            sw = code;
            wait_clk(8);
            click_button(0);
        end
    endtask

    // Kiem tra ket qua
    task check_result;
        input condition;
        input [8*80-1:0] message;
        begin
            total = total + 1;

            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s", message);
            end
            else
                $display("PASS: %0s", message);
        end
    endtask

    initial begin

        wait_clk(10);

        // Test 1: Ban dau
        check_result(
            dut.mem0 == 63 &&
            dut.mem1 == 63 &&
            dut.mem2 == 63 &&
            dut.mem3 == 63,
            "Initial memory blank"
        );

        check_result(
            dut.cursor == 3,
            "Initial cursor AN3"
        );

        // Test 2: Bat che do nhap
        sw15 = 1;
        wait_clk(8);

        check_result(
            dut.mode_sync == 1,
            "Edit mode ON"
        );

        // Test 3: Nhap H E L 0
        save_char(17);
        save_char(14);
        save_char(21);
        save_char(0);

        check_result(
            dut.mem3 == 17 &&
            dut.mem2 == 14 &&
            dut.mem1 == 21 &&
            dut.mem0 == 0,
            "Save HEL0"
        );

        check_result(
            dut.cursor == 3,
            "Cursor wraps to AN3"
        );

        // Test 4: Xem truoc ky tu A
        sw = 10;
        wait_clk(8);

        check_result(
            dut.view3 == 10 &&
            dut.mem3 == 17,
            "Preview A without saving"
        );

        // Test 5: Tat che do nhap
        sw15 = 0;
        wait_clk(8);

        check_result(
            dut.view3 == 17 &&
            dut.view2 == 14 &&
            dut.view1 == 21 &&
            dut.view0 == 0,
            "Display saved HEL0"
        );

        check_result(
            dp == 1,
            "Cursor dot OFF in view mode"
        );

        // Test 6: Khong luu khi SW15 OFF
        click_button(0);

        check_result(
            dut.mem3 == 17,
            "Ignore save in view mode"
        );

        // Test 7: Di chuyen con tro
        sw15 = 1;
        wait_clk(8);

        click_button(2);

        check_result(
            dut.cursor == 2,
            "Move right"
        );

        click_button(1);

        check_result(
            dut.cursor == 3,
            "Move left"
        );

        // Test 8: Xoa ky tu hien tai
        click_button(3);

        check_result(
            dut.mem3 == 63 &&
            dut.mem2 == 14,
            "Clear current character"
        );

        // Test 9: Xoa tat ca
        click_button(4);

        check_result(
            dut.mem0 == 63 &&
            dut.mem1 == 63 &&
            dut.mem2 == 63 &&
            dut.mem3 == 63,
            "Clear all characters"
        );

        check_result(
            dut.cursor == 3,
            "Cursor reset to AN3"
        );

        // Test 10: Kiem tra ma khong hop le
        sw = 6'd40;
        wait_clk(8);
        click_button(0);

        check_result(
            dut.mem3 == 63 &&
            dut.cursor == 3,
            "Reject invalid code"
        );

        // Ket qua
        $display("==========================");

        if (errors == 0)
            $display(
                "ALL TESTS PASS: %0d CHECKS",
                total
            );
        else
            $display(
                "TEST FAILED: %0d / %0d",
                errors, total
            );

        $display("==========================");

        $finish;

    end

endmodule
