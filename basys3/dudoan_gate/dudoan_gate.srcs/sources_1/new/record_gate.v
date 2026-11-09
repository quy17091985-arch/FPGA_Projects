
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/09/2026 03:50:58 PM
// Design Name:
// Module Name: record_gate
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



module record_gate #(
    parameter integer BTN_DEBOUNCE_CYCLES = 2000000,
    parameter integer SCAN_DIV = 100000,
    parameter integer PAGE_CYCLES = 200000000
)(
    input wire clk,
    input wire [2:0] sw,
    input wire sw15,
    input wire btnc,

    output wire [4:0] led,
    output reg [6:0] seg,
    output reg [3:0] an,
    output wire dp
);

    // BTN_DEBOUNCE_CYCLES: 20 ms
    // SCAN_DIV: 1 ms cho moi LED 7 doan
    // PAGE_CYCLES: 2 giay doi ten cong

    localparam integer BTN_W =
        (BTN_DEBOUNCE_CYCLES <= 1) ? 1 :
        $clog2(BTN_DEBOUNCE_CYCLES);

    localparam integer SCAN_W =
        (SCAN_DIV <= 1) ? 1 : $clog2(SCAN_DIV);

    localparam integer PAGE_W =
        (PAGE_CYCLES <= 1) ? 1 :
        $clog2(PAGE_CYCLES);

    // SW2 = A, SW1 = B, SW0 = Y

    reg [2:0] sw_meta = 3'b0;
    reg [2:0] sw_sync = 3'b0;

    reg mode_meta = 1'b0;
    reg mode_sync = 1'b0;
    reg mode_prev = 1'b0;

    reg btn_meta = 1'b0;
    reg btn_sync = 1'b0;

    always @(posedge clk) begin
        sw_meta <= sw;
        sw_sync <= sw_meta;

        mode_meta <= sw15;
        mode_sync <= mode_meta;
        mode_prev <= mode_sync;

        btn_meta <= btnc;
        btn_sync <= btn_meta;
    end

    // Chong doi

    reg [BTN_W-1:0] btn_count = 0;
    reg btn_stable = 0;
    reg btn_stable_prev = 0;

    always @(posedge clk) begin
        btn_stable_prev <= btn_stable;

        if (btn_sync == btn_stable) begin
            btn_count <= 0;
        end
        else if (btn_count == BTN_DEBOUNCE_CYCLES - 1) begin
            btn_count <= 0;
            btn_stable <= btn_sync;
        end
        else begin
            btn_count <= btn_count + 1'b1;
        end
    end

    wire btn_press = btn_stable && !btn_stable_prev;

    // Luu bang trang thai
    // row_id = {A,B}
    // 00 = hang 0, 01 = hang 1
    // 10 = hang 2, 11 = hang 3

    reg [3:0] y_zero = 4'b0000;
    reg [3:0] y_one = 4'b0000;

    reg session_started = 1'b0;

    wire [1:0] row_id = {sw_sync[2], sw_sync[1]};
    wire [3:0] recorded_rows = y_zero | y_one;

    always @(posedge clk) begin

        // SW15 OFF -> ON: xoa bang cu
        // RESET lai loi -> phai co
        if (mode_sync && !mode_prev) begin
            y_zero <= 4'b0000;
            y_one <= 4'b0000;
            session_started <= 1'b1;
        end

        // SW15 ON va nhan BTNC: luu A,B,Y
        else if (mode_sync && btn_press) begin

            if (sw_sync[0] == 1'b1)
                y_one[row_id] <= 1'b1;
            else
                y_zero[row_id] <= 1'b1;

        end
    end

    // Hạm check

    function gate_matches;
        input [3:0] truth;
        input [3:0] zeros;
        input [3:0] ones;
        begin
            gate_matches =
                ((zeros | ones) != 4'b0000) &&
                ((ones & ~truth) == 4'b0000) &&
                ((zeros & truth) == 4'b0000);
        end
    endfunction

    // A B = 11, 10, 01, 00

    wire [7:0] matches;

    assign matches[0] =
        gate_matches(4'b1000, y_zero, y_one); // AND

    assign matches[1] =
        gate_matches(4'b1110, y_zero, y_one); // OR

    assign matches[2] =
        gate_matches(4'b0011, y_zero, y_one); // NOT A

    assign matches[3] =
        gate_matches(4'b0111, y_zero, y_one); // NAND

    assign matches[4] =
        gate_matches(4'b0001, y_zero, y_one); // NOR

    assign matches[5] =
        gate_matches(4'b0110, y_zero, y_one); // XOR

    assign matches[6] =
        gate_matches(4'b1001, y_zero, y_one); // XNOR

    assign matches[7] =
        gate_matches(4'b1100, y_zero, y_one); // BUFFER A

    // Dem so cong phu hop

    reg [3:0] match_count;
    integer i;

    always @(*) begin
        match_count = 0;
        for (i = 0; i < 8; i = i + 1)
            match_count = match_count + matches[i];
    end

    // Chon cong hien thi

    function [2:0] find_match;
        input [7:0] mask;
        input [2:0] start_at;

        integer k;
        reg found;
        reg [2:0] idx;

        begin
            find_match = start_at;
            found = 0;

            for (k = 0; k < 8; k = k + 1) begin
                idx = start_at + k;

                if (!found && mask[idx]) begin
                    find_match = idx;
                    found = 1;
                end
            end
        end
    endfunction

    reg [PAGE_W-1:0] page_count = 0;
    reg [2:0] page_gate = 0;

    wire [2:0] shown_gate =
        find_match(matches, page_gate);

    always @(posedge clk) begin

        if (mode_sync) begin
            page_count <= 0;
            page_gate <= 0;
        end

        else if (page_count == PAGE_CYCLES - 1) begin
            page_count <= 0;
            page_gate <=
                find_match(matches, shown_gate + 3'd1);
        end

        else begin
            page_count <= page_count + 1'b1;
        end
    end

    // gate -> led7seg

    reg [31:0] gate_name;
    reg [31:0] screen_word;

    always @(*) begin

        case (shown_gate)
            3'd0: gate_name = " And";
            3'd1: gate_name = "  or";
            3'd2: gate_name = " not";
            3'd3: gate_name = "nAnd";
            3'd4: gate_name = " nor";
            3'd5: gate_name = " Hor";
            3'd6: gate_name = "Hnor";
            3'd7: gate_name = " buF";
            default: gate_name = "    ";
        endcase

        if (!session_started && !mode_sync)
            screen_word = "ON15";

        // SW15 ON
        else if (mode_sync)
            screen_word = " GHI";

        // SW15 OFF ma khong co cong khop
        else if (match_count == 0)
            screen_word = " LOI";

        // Co cong phu hop
        else
            screen_word = gate_name;

    end

    // Quet 4 led7seg

    reg [SCAN_W-1:0] scan_count = 0;
    reg [1:0] digit_sel = 0;
    reg [7:0] ch;

    always @(posedge clk) begin
        if (scan_count == SCAN_DIV - 1) begin
            scan_count <= 0;
            digit_sel <= digit_sel + 1'b1;
        end
        else begin
            scan_count <= scan_count + 1'b1;
        end
    end

    always @(*) begin
        case (digit_sel)

            2'd0: begin
                an = 4'b1110;
                ch = screen_word[7:0];
            end

            2'd1: begin
                an = 4'b1101;
                ch = screen_word[15:8];
            end

            2'd2: begin
                an = 4'b1011;
                ch = screen_word[23:16];
            end

            default: begin
                an = 4'b0111;
                ch = screen_word[31:24];
            end

        endcase

        seg = char_to_seg(ch);
    end

    assign dp = 1'b1;

    // seg = {g,f,e,d,c,b,a}
    // 0 = sang, 1 = tat

    function [6:0] char_to_seg;
        input [7:0] c;
        begin
            case (c)
                "A": char_to_seg = 7'b0001000;
                "n": char_to_seg = 7'b0101011;
                "d": char_to_seg = 7'b0100001;
                "o": char_to_seg = 7'b0100011;
                "r": char_to_seg = 7'b0101111;
                "t": char_to_seg = 7'b0000111;

                "H": char_to_seg = 7'b0001001;
                "G": char_to_seg = 7'b0000010;
                "I": char_to_seg = 7'b1111001;

                "L": char_to_seg = 7'b1000111;
                "O": char_to_seg = 7'b1000000;

                "b": char_to_seg = 7'b0000011;
                "u": char_to_seg = 7'b1100011;
                "F": char_to_seg = 7'b0001110;

                "N": char_to_seg = 7'b0101011;
                "1": char_to_seg = 7'b1111001;
                "5": char_to_seg = 7'b0010010;

                " ": char_to_seg = 7'b1111111;

                default:
                    char_to_seg = 7'b1111111;
            endcase
        end
    endfunction

    // led trang thai

    assign led[0] = sw_sync[0]; // Y dang nhap
    assign led[1] = mode_sync;  // Dang ghi
    assign led[2] = (recorded_rows == 4'b1111);
    assign led[3] = !mode_sync && (match_count == 1);
    assign led[4] = session_started &&
                    !mode_sync && (match_count == 0);

endmodule