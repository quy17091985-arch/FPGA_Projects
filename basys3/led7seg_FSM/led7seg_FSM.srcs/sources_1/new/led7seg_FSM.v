`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/11/2026 09:16:58 PM
// Design Name: 
// Module Name: led7seg_FSM
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


module led7seg_FSM #(
    parameter integer SEC_TICKS = 100000000,
    parameter integer SCAN_TICKS = 100000
)(
    input wire clk,
    input wire sw0,
    output reg [6:0] seg,
    output reg [3:0] an,
    output wire dp
);

    // 2 trang thai
    localparam S_WAIT  = 1'b0;
    localparam S_SHIFT = 1'b1;

    localparam integer SEC_W =
        (SEC_TICKS < 2) ? 1 : $clog2(SEC_TICKS);

    localparam integer SCAN_W =
        (SCAN_TICKS < 2) ? 1 : $clog2(SCAN_TICKS);

    reg state = S_WAIT;

    // Dong bo SW0
    reg sw_meta = 0;
    reg sw_sync = 0;

    always @(posedge clk) begin
        sw_meta <= sw0;
        sw_sync <= sw_meta;
    end

    // Bo dem 1 giay
    reg [SEC_W-1:0] sec_count = 0;

    // Vi tri ky tu trong chuoi
    reg [5:0] char_index = 0;

    // Bo nho 4 ky tu
    reg [31:0] display_chars = "    ";

    // Chuoi: VIET NAM CHIEN THANG
    function [7:0] letter_at;
        input [5:0] idx;
        begin
            case (idx)

                // VIET
                6'd0: letter_at = "t";
                6'd1: letter_at = "e";
                6'd2: letter_at = "i";
                6'd3: letter_at = "v";

                // Khoang trang
                6'd4, 6'd5, 6'd6, 6'd7:
                    letter_at = " ";

                // NAM
                6'd8:  letter_at = "m";
                6'd9:  letter_at = "a";
                6'd10: letter_at = "n";

                // Khoang trang
                6'd11, 6'd12, 6'd13, 6'd14:
                    letter_at = " ";

                // CHIEN
                6'd15: letter_at = "n";
                6'd16: letter_at = "e";
                6'd17: letter_at = "i";
                6'd18: letter_at = "h";
                6'd19: letter_at = "c";

                // Khoang trang
                6'd20, 6'd21, 6'd22, 6'd23:
                    letter_at = " ";

                // THANG
                6'd24: letter_at = "g";
                6'd25: letter_at = "n";
                6'd26: letter_at = "a";
                6'd27: letter_at = "h";
                6'd28: letter_at = "t";

                // Khoang trang va lap lai
                6'd29, 6'd30, 6'd31, 6'd32:
                    letter_at = " ";

                default: letter_at = " ";

            endcase
        end
    endfunction

    // Dieu khien FSM
    always @(posedge clk) begin

        if (sw_sync) begin

            case (state)

                S_WAIT: begin

                    if (sec_count == SEC_TICKS - 2) begin
                        sec_count <= 0;
                        state <= S_SHIFT;
                    end
                    else begin
                        sec_count <= sec_count + 1'b1;
                    end

                end

                S_SHIFT: begin

                    // Dich cac ky tu sang phai
                    display_chars <= {
                        letter_at(char_index),
                        display_chars[31:8]
                    };

                    // Chuyen sang ky tu tiep theo
                    if (char_index == 6'd32)
                        char_index <= 0;
                    else
                        char_index <= char_index + 1'b1;

                    state <= S_WAIT;

                end

                default: state <= S_WAIT;

            endcase

        end

    end

    // Khai bao
    reg [SCAN_W-1:0] scan_count = 0;
    reg [1:0] digit = 0;

    always @(posedge clk) begin

        if (scan_count == SCAN_TICKS - 1) begin
            scan_count <= 0;
            digit <= digit + 1'b1;
        end
        else begin
            scan_count <= scan_count + 1'b1;
        end

    end

    // Chon ky tu hien thi
    reg [7:0] current_char;

    always @(*) begin

        case (digit)

            2'd0: begin
                an = 4'b1110;
                current_char = display_chars[7:0];
            end

            2'd1: begin
                an = 4'b1101;
                current_char = display_chars[15:8];
            end

            2'd2: begin
                an = 4'b1011;
                current_char = display_chars[23:16];
            end

            default: begin
                an = 4'b0111;
                current_char = display_chars[31:24];
            end

        endcase

        seg = char_to_seg(current_char);

    end

    assign dp = 1'b1;

   // Muc 0 sang, muc 1 tat
    function [6:0] char_to_seg;
        input [7:0] c;

        begin
            case (c)

                "v": char_to_seg = 7'b1100011;
                "i": char_to_seg = 7'b1111001;
                "e": char_to_seg = 7'b0000110;
                "t": char_to_seg = 7'b0000111;

                "n": char_to_seg = 7'b0101011;
                "a": char_to_seg = 7'b0001000;
                "m": char_to_seg = 7'b0101011;

                "c": char_to_seg = 7'b0100111;
                "h": char_to_seg = 7'b0001011;
                "g": char_to_seg = 7'b0000010;

                " ": char_to_seg = 7'b1111111;

                default:
                    char_to_seg = 7'b1111111;

            endcase
        end
    endfunction

endmodule

