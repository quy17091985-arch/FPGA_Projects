`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/09/2026 08:09:20 PM
// Design Name: 
// Module Name: tbgate_recorder
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


module tbgate_recorder;

    reg clk = 1'b0;
    reg [2:0] sw = 3'b000;
    reg sw15 = 1'b0;
    reg btnc = 1'b0;

    wire [4:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire dp;

    // Tao clock 100 MHz
    always #5 clk = ~clk;

    // Giam so chu ky de mo phong nhanh
    record_gate #(
        .BTN_DEBOUNCE_CYCLES(3),
        .SCAN_DIV(3),
        .PAGE_CYCLES(30)
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

    integer errors = 0;
    integer g, r;
    reg [3:0] truth;

    // Cho n chu ky clock
    task wait_clk;
        input integer n;
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(posedge clk);
            #1;
        end
    endtask

    // Bat SW15 de bat dau ghi bang moi
    task start_record;
        begin
            btnc = 1'b0;
            sw15 = 1'b1;
            wait_clk(12);

            if (dut.recorded_rows !== 4'b0000 ||
                dut.screen_word !== " GHI" ||
                led[1] !== 1'b1) begin
                $display("FAIL: GHI / XOA BANG CU");
                errors = errors + 1;
            end
        end
    endtask

    // Dat A B Y, nhan va tha BTNC
    task save_row;
        input a, b, y;
        input [3:0] expected_rows;
        begin
            sw = {a, b, y};
            wait_clk(8);

            btnc = 1'b1;
            wait_clk(12);

            btnc = 1'b0;
            wait_clk(12);

            $display("LUU: A=%b B=%b Y=%b | rows=%b",
                     a, b, y, dut.recorded_rows);

            if (dut.recorded_rows !== expected_rows) begin
                $display("FAIL: LUU SAI HANG");
                errors = errors + 1;
            end
        end
    endtask

    // Bang chan tri cua 8 cong
    // Bit 0: AB=00
    // Bit 1: AB=01
    // Bit 2: AB=10
    // Bit 3: AB=11

    function [3:0] gate_truth;
        input integer gate_id;
        begin
            case (gate_id)
                0: gate_truth = 4'b1000; // AND
                1: gate_truth = 4'b1110; // OR
                2: gate_truth = 4'b0011; // NOT A
                3: gate_truth = 4'b0111; // NAND
                4: gate_truth = 4'b0001; // NOR
                5: gate_truth = 4'b0110; // XOR
                6: gate_truth = 4'b1001; // XNOR
                7: gate_truth = 4'b1100; // BUFFER
                default: gate_truth = 4'b0000;
            endcase
        end
    endfunction

    // Ten hien thi mong doi
    function [31:0] gate_label;
        input integer gate_id;
        begin
            case (gate_id)
                0: gate_label = " And";
                1: gate_label = "  or";
                2: gate_label = " not";
                3: gate_label = "nAnd";
                4: gate_label = " nor";
                5: gate_label = " Hor";
                6: gate_label = "Hnor";
                7: gate_label = " buF";
                default: gate_label = "    ";
            endcase
        end
    endfunction

    // Tat SW15 va kiem tra ket qua
    task stop_and_check;
        input [7:0] expect_mask;
        input [31:0] expect_text;
        begin
            sw15 = 1'b0;
            wait_clk(12);

            $display("NHAN DIEN: mask=%b | screen=%s",
                     dut.matches, dut.screen_word);

            if (dut.matches !== expect_mask ||
                dut.screen_word !== expect_text) begin
                $display("FAIL: MONG DOI %s", expect_text);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        wait_clk(10);

        // TEST 1 - GHI CONG AND THU CONG
        $display("=== TEST 1: AND ===");

        start_record;

        // Thay SW khi chua nhan BTNC
        sw = 3'b111;
        wait_clk(12);

        if (dut.recorded_rows !== 4'b0000) begin
            $display("FAIL: TU DONG GHI");
            errors = errors + 1;
        end

        // A=0 B=0 Y=0
        save_row(0, 0, 0, 4'b0001);

        // A=0 B=1 Y=0
        save_row(0, 1, 0, 4'b0011);

        // A=1 B=0 Y=0
        save_row(1, 0, 0, 4'b0111);

        // A=1 B=1 Y=1
        save_row(1, 1, 1, 4'b1111);

        if (led[2] !== 1'b1) begin
            $display("FAIL: LD2 KHONG SANG");
            errors = errors + 1;
        end

        stop_and_check(8'b00000001, " And");

        if (led[3] !== 1'b1) begin
            $display("FAIL: LD3 KHONG SANG");
            errors = errors + 1;
        end

        // TEST 2 - ALL gate
        $display("=== TEST 2: 7 CONG CON LAI ===");

        for (g = 1; g < 8; g = g + 1) begin

            $display("TEST GATE %0d", g);
            start_record;

            truth = gate_truth(g);

            for (r = 0; r < 4; r = r + 1) begin
                save_row(
                    r[1],
                    r[0],
                    truth[r],
                    (4'b0001 << (r+1)) - 1'b1
                );
            end

            stop_and_check(
                (8'b00000001 << g),
                gate_label(g)
            );
        end

        // TEST 3 - BANG NOT B -> LOI
        $display("=== TEST 3: LOI NOT B ===");

        start_record;

        save_row(0, 0, 1, 4'b0001);
        save_row(0, 1, 0, 4'b0011);
        save_row(1, 0, 1, 4'b0111);
        save_row(1, 1, 0, 4'b1111);

        stop_and_check(8'b00000000, " LOI");

        if (led[4] !== 1'b1) begin
            $display("FAIL: LD4 KHONG SANG");
            errors = errors + 1;
        end
        
        // TEST 4 - DU LIEU MAU THUAN
        $display("=== TEST 4: MAU THUAN ===");

        start_record;

        save_row(0, 0, 0, 4'b0001);
        save_row(0, 0, 1, 4'b0001);

        stop_and_check(8'b00000000, " LOI");

        // TEST 5 - CHUA DU BANG CHAN TRI
        $display("=== TEST 5: THIEU HANG ===");

        start_record;

        save_row(0, 0, 0, 4'b0001);

        sw15 = 1'b0;
        wait_clk(12);

        // 4 cong co the phu hop
        if (dut.match_count !== 4 ||
            dut.matches !== 8'b10100011 ||
            led[3] !== 1'b0) begin
            $display("FAIL: BANG CHUA DU");
            errors = errors + 1;
        end

        // TEST 6 - NHAN GIU BTNC
        $display("=== TEST 6: GIU BTNC ===");

        start_record;

        sw = 3'b000;
        wait_clk(8);

        // Nhan giu nut
        btnc = 1'b1;
        wait_clk(12);

        // Doi Y khi van giu nut
        sw = 3'b001;
        wait_clk(12);

        // Tha nut
        btnc = 1'b0;
        wait_clk(12);

        // Chi duoc ghi Y=0 mot lan
        if (dut.y_zero !== 4'b0001 ||
            dut.y_one !== 4'b0000) begin
            $display("FAIL: GHI LAP KHI GIU BTNC");
            errors = errors + 1;
        end
        if (errors == 0)
            $display("PASS: TAT CA BAI KIEM TRA DAT");
        else
            $display("FAIL: %0d LOI - CHUA DUOC NAP KIT",
                     errors);

        $finish;
    end

endmodule

