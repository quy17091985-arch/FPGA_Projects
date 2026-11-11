`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2026 09:25:04 PM
// Design Name: 
// Module Name: tb_led7seg_FSM
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


module tb_led7seg_FSM;

    // Khai bao tin hieu
    reg clk = 0;
    reg sw0 = 0;

    wire [6:0] seg;
    wire [3:0] an;
    wire dp;

    integer errors = 0;
    integer total = 0;

    reg [31:0] paused_text;
    reg [5:0] paused_index;

    // Tao clock 100 MHz
    always #5 clk = ~clk;

    // Goi module FSM
    led7seg_FSM #(
        .SEC_TICKS(6),
        .SCAN_TICKS(2)
    ) dut (
        .clk(clk),
        .sw0(sw0),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    // Cho n chu ky
    task wait_clk;
        input integer n;
        begin
            repeat(n) @(negedge clk);
        end
    endtask

    // Kiem tra PASS / FAIL
    task check_result;
        input condition;
        input [8*80-1:0] message;
        begin
            total = total + 1;

            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: %0s", message);
            end
            else begin
                $display("PASS: %0s", message);
            end
        end
    endtask

    // Kiem tra vi tri va chu
    task check_frame;
        input [5:0] expected_index;
        input [31:0] expected_text;

        integer timeout;

        begin
            timeout = 0;

            while (
                dut.char_index !== expected_index &&
                timeout < 1000
            ) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 1000) begin
                total = total + 1;
                errors = errors + 1;

                $display(
                    "FAIL: TIMEOUT index=%0d",
                    expected_index
                );
            end
            else begin
                check_result(
                    dut.display_chars === expected_text,
                    "Character shift"
                );

                $display(
                    "INDEX=%0d TEXT=%s",
                    dut.char_index,
                    dut.display_chars
                );
            end
        end
    endtask

    initial begin

        $display("========================");
        $display("START TEST LED7SEG FSM");
        $display("========================");

        // Test 1: Trang thai ban dau
        wait_clk(20);

        check_result(
            dut.display_chars === "    ",
            "Initial blank"
        );

        check_result(
            dut.char_index === 0,
            "Initial index"
        );

        // Test 2: Bat SW0
        sw0 = 1;

        check_frame(1, "t   ");
        check_frame(2, "et  ");
        check_frame(3, "iet ");
        check_frame(4, "viet");

        // Test 3: Tam dung
        sw0 = 0;
        wait_clk(4);

        paused_text = dut.display_chars;
        paused_index = dut.char_index;

        wait_clk(30);

        check_result(
            dut.display_chars === paused_text,
            "Text frozen"
        );

        check_result(
            dut.char_index === paused_index,
            "Index frozen"
        );

        // Test 4: Chay tiep
        sw0 = 1;

        check_frame(5, " vie");
        check_frame(8, "    ");

        // Test 5: Tu NAM
        check_frame(9,  "m   ");
        check_frame(11, "nam ");

        // Test 6: Tu CHIEN
        check_frame(19, "hien");
        check_frame(20, "chie");

        // Test 7: Tu THANG
        check_frame(28, "hang");
        check_frame(29, "than");

        // Test 8: Lap lai
        check_frame(0, "    ");
        check_frame(1, "t   ");

        check_result(
            dp === 1'b1,
            "Decimal point OFF"
        );

        // Ket qua
        $display("========================");

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

        $display("========================");

        $finish;

    end

endmodule
