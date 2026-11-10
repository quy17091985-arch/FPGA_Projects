`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 09:13:31 PM
// Design Name: 
// Module Name: tb_all_gate_top
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


module tb_all_gate_top;
    reg clk = 0;
    reg [15:0] sw = 0;

    reg btnU = 0;
    reg btnR = 0;
    reg btnD = 0;
    reg btnL = 0;
    reg btnC = 0;

    wire [15:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire dp;

    integer errors = 0;
    integer total = 0;
    integer i, j;

    reg a = 0;
    reg b = 0;
    reg [3:0] gate_code = 0;
    reg expected;
    wire gate_y;

    // Tao clock 100 MHz
    always #5 clk = ~clk;

    // Goi module chinh
    all_gate_top #(
        .BTN_DEBOUNCE_CYCLES(3),
        .MULTICLICK_CYCLES(100),
        .SHOW_CYCLES(40),
        .SCAN_DIV(3)
    ) dut (
        .clk(clk),
        .sw(sw),
        .btnU(btnU),
        .btnR(btnR),
        .btnD(btnD),
        .btnL(btnL),
        .btnC(btnC),
        .led(led),
        .seg(seg),
        .an(an),
        .dp(dp)
    );

    // Kiem tra cong logic
    gate_select test_gate (
        .a(a),
        .b(b),
        .code(gate_code),
        .y(gate_y)
    );

    // Tinh ket qua mong doi
    function expected_gate;
        input integer code;
        input x, y;
        begin
            case (code)
                0: expected_gate = ~x;
                1: expected_gate = ~y;
                2: expected_gate = x | y;
                3: expected_gate = ~(x | y);
                4: expected_gate = x & y;
                5: expected_gate = ~(x & y);
                6: expected_gate = x ^ y;
                7: expected_gate = ~(x ^ y);
                8: expected_gate = x;
                9: expected_gate = y;
                default: expected_gate = 0;
            endcase
        end
    endfunction

    // Cho n chu ky
    task wait_clk;
        input integer n;
        begin
            repeat(n) @(negedge clk);
        end
    endtask

    // Kiem tra PASS FAIL
    task check_result;
        input condition;
        input [8*100-1:0] message;
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

    // Nhan va tha button
    task press_button;
        input integer id;
        begin
            case (id)
                0: btnU = 1;
                1: btnR = 1;
                2: btnD = 1;
                3: btnL = 1;
                4: btnC = 1;
            endcase

            wait_clk(10);

            btnU = 0;
            btnR = 0;
            btnD = 0;
            btnL = 0;
            btnC = 0;

            wait_clk(10);
        end
    endtask

    // Chon va luu 2 switch
    task save_pair;
        input integer sw_a;
        input integer sw_b;
        begin
            sw[14] = 1;
            wait_clk(10);

            sw[sw_a] = ~sw[sw_a];
            wait_clk(10);

            sw[sw_b] = ~sw[sw_b];
            wait_clk(10);

            sw[14] = 0;
            wait_clk(12);
        end
    endtask

    initial begin

        $display("START TEST ALL GATE");

        // Test 1: Bang chan tri
        for (i = 0; i < 10; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin

                gate_code = i;
                a = (j >> 1) & 1;
                b = j & 1;

                #1;

                expected = expected_gate(i, a, b);

                check_result(
                    gate_y === expected,
                    "Gate truth table"
                );
            end
        end

        wait_clk(12);

        // Test 2: Trang thai ban dau
        check_result(
            led === 16'h0000,
            "All LEDs OFF"
        );

        check_result(
            dut.screen_word === "    ",
            "7SEG BLANK"
        );

        // Test 3: Chon AND
        press_button(2);

        check_result(
            dut.selected_gate === 4'd4,
            "BTND selects AND"
        );

        check_result(
            dut.selected_valid === 1'b1,
            "Gate selected"
        );

        check_result(
            dut.screen_word === "And ",
            "Display AND"
        );

        // Test 4: Luu SW0 SW1
        save_pair(0, 1);

        check_result(
            dut.slot_valid === 7'b0000001,
            "First pair saved"
        );

        check_result(
            dut.slot_a[0] === 4'd0 &&
            dut.slot_b[0] === 4'd1,
            "SW0 SW1 selected"
        );

        check_result(
            dut.slot_op[0] === 4'd4,
            "AND stored"
        );

        check_result(
            led[1:0] === 2'b11,
            "AND(1,1) = 1"
        );

        check_result(
            dut.screen_word === "And ",
            "Display AND"
        );

        wait_clk(42);

        check_result(
            dut.screen_word === "LUU ",
            "Display LUU"
        );

        wait_clk(42);

        check_result(
            dut.screen_word === "    ",
            "Display blank"
        );

        // Test 5: Bat che do gop
        sw[15] = 1;
        wait_clk(10);

        check_result(
            dut.merge_mode === 1'b1,
            "Merge mode ON"
        );

        // Test 6: Nhan doi XNOR
        press_button(3);
        press_button(3);

        check_result(
            dut.selected_gate === 4'd7,
            "Double BTNL selects XNOR"
        );

        // Test 7: Gop SW2 SW3
        save_pair(2, 3);

        check_result(
            dut.slot_valid === 7'b0000011,
            "Second pair saved"
        );

        check_result(
            dut.partner[0] === 3'd1 &&
            dut.partner[1] === 3'd0,
            "Pairs connected"
        );

        check_result(
            led[3:0] === 4'b1111,
            "Merged output HIGH"
        );

        wait_clk(42);

        check_result(
            dut.screen_word === "GOP ",
            "Display GOP"
        );

        // Test 8: Doi input
        sw[3] = 0;
        wait_clk(12);

        check_result(
            led[3:0] === 4'b0000,
            "Merged output LOW"
        );

        sw[3] = 1;
        wait_clk(12);

        check_result(
            led[3:0] === 4'b1111,
            "Merged output HIGH"
        );

        // Test 9: Chon NOR
        sw[15] = 0;
        wait_clk(10);

        press_button(1);
        press_button(1);

        check_result(
            dut.selected_gate === 4'd3,
            "Double BTNR selects NOR"
        );

        save_pair(4, 5);

        check_result(
            dut.slot_valid === 7'b0000111,
            "Third pair saved"
        );

        check_result(
            led[5:4] === 2'b00,
            "NOR(1,1) = 0"
        );

        sw[4] = 0;
        sw[5] = 0;
        wait_clk(12);

        check_result(
            led[5:4] === 2'b11,
            "NOR(0,0) = 1"
        );

        // Test 10: Reset
        wait_clk(105);

        press_button(4);
        press_button(4);
        press_button(4);

        check_result(
            dut.reset_armed === 1'b1,
            "Triple BTNC reset"
        );

        check_result(
            dut.screen_word === "rSt ",
            "Display rSt"
        );

        sw[15] = 1;
        wait_clk(12);

        check_result(
            dut.slot_valid === 7'b0000000,
            "All pairs cleared"
        );

        check_result(
            led === 16'h0000,
            "All LEDs OFF"
        );

        check_result(
            dut.merge_mode === 1'b0,
            "Merge disabled"
        );

        check_result(
            dut.screen_word === "OFF ",
            "Display OFF"
        );

        // Test 11: Luu sau reset
        press_button(1);
        save_pair(6, 7);

        check_result(
            dut.slot_valid === 7'b0000001 &&
            dut.slot_op[0] === 4'd2,
            "Save OR after reset"
        );

        check_result(
            led[7:6] === 2'b11,
            "OR(1,1) = 1"
        );

        // Test 12: Trung switch
        press_button(2);
        save_pair(6, 8);

        check_result(
            dut.slot_valid === 7'b0000001,
            "Duplicate SW rejected"
        );

        check_result(
            dut.screen_word === "Err ",
            "Display Err"
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
