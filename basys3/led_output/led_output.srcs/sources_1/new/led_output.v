`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/12/2026 07:14:29 PM
// Design Name: 
// Module Name: led_output
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


module led_output #(
    parameter integer BTN_FILTER = 2000000,
    parameter integer SCAN_TICKS = 100000
)(
    input wire clk,
    input wire [5:0] sw,
    input wire sw15,
    input wire btnU, btnR, btnD, btnL, btnC,
    output reg [6:0] seg,
    output reg [3:0] an,
    output wire dp
);

    localparam [5:0] BLANK = 6'd63;

    localparam integer SCAN_W =
        (SCAN_TICKS < 2) ? 1 : $clog2(SCAN_TICKS);

    // Dong bo switch
    reg [5:0] sw_meta = 0;
    reg [5:0] sw_sync = 0;
    reg mode_meta = 0;
    reg mode_sync = 0;

    always @(posedge clk) begin
        sw_meta <= sw;
        sw_sync <= sw_meta;
        mode_meta <= sw15;
        mode_sync <= mode_meta;
    end

    // Chong doi nut
    wire pU, pR, pD, pL, pC;

    button_debounce #(.CYCLES(BTN_FILTER)) db_u (
        .clk(clk), .button_raw(btnU), .pressed(pU)
    );

    button_debounce #(.CYCLES(BTN_FILTER)) db_r (
        .clk(clk), .button_raw(btnR), .pressed(pR)
    );

    button_debounce #(.CYCLES(BTN_FILTER)) db_d (
        .clk(clk), .button_raw(btnD), .pressed(pD)
    );

    button_debounce #(.CYCLES(BTN_FILTER)) db_l (
        .clk(clk), .button_raw(btnL), .pressed(pL)
    );

    button_debounce #(.CYCLES(BTN_FILTER)) db_c (
        .clk(clk), .button_raw(btnC), .pressed(pC)
    );

    // mem
    reg [5:0] mem0 = BLANK;
    reg [5:0] mem1 = BLANK;
    reg [5:0] mem2 = BLANK;
    reg [5:0] mem3 = BLANK;

    // Bat dau tu vi tri ben trai
    reg [1:0] cursor = 2'd3;

    // Dieu khien nhap va luu
    always @(posedge clk) begin

        if (mode_sync) begin

            // Xoa tat ca
            if (pD) begin
                mem0 <= BLANK;
                mem1 <= BLANK;
                mem2 <= BLANK;
                mem3 <= BLANK;
                cursor <= 2'd3;
            end

            // Xoa ky tu hien tai
            else if (pU) begin
                case (cursor)
                    2'd0: mem0 <= BLANK;
                    2'd1: mem1 <= BLANK;
                    2'd2: mem2 <= BLANK;
                    2'd3: mem3 <= BLANK;
                endcase
            end

            // Luu ky tu
            else if (pC) begin

                if (sw_sync <= 6'd35) begin

                    case (cursor)
                        2'd0: mem0 <= sw_sync;
                        2'd1: mem1 <= sw_sync;
                        2'd2: mem2 <= sw_sync;
                        2'd3: mem3 <= sw_sync;
                    endcase

                    cursor <= cursor - 1'b1;

                end

            end

            // Di chuyen sang trai
            else if (pL) begin
                cursor <= cursor + 1'b1;
            end

            // Di chuyen sang phai
            else if (pR) begin
                cursor <= cursor - 1'b1;
            end

        end

    end

    // Xem truoc ky tu khi nhap
    wire [5:0] view0 =
        (mode_sync && cursor == 2'd0) ? sw_sync : mem0;

    wire [5:0] view1 =
        (mode_sync && cursor == 2'd1) ? sw_sync : mem1;

    wire [5:0] view2 =
        (mode_sync && cursor == 2'd2) ? sw_sync : mem2;

    wire [5:0] view3 =
        (mode_sync && cursor == 2'd3) ? sw_sync : mem3;

    // Bo quet LED 7 doan
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

    // Chon vi tri hien thi
    reg [5:0] current_code;

    always @(*) begin

        case (digit)

            2'd0: begin
                an = 4'b1110;
                current_code = view0;
            end

            2'd1: begin
                an = 4'b1101;
                current_code = view1;
            end

            2'd2: begin
                an = 4'b1011;
                current_code = view2;
            end

            default: begin
                an = 4'b0111;
                current_code = view3;
            end

        endcase

        seg = char_to_seg(current_code);

    end

    // Dau cham chi vi tri dang nhap
    assign dp =
        (mode_sync && digit == cursor) ? 1'b0 : 1'b1;

    // Ma LED 7 doan: {g,f,e,d,c,b,a}
    // Muc 0 sang, muc 1 tat
    function [6:0] char_to_seg;
        input [5:0] code;

        begin
            case (code)

                // So 0 - 9
                6'd0: char_to_seg = 7'b1000000;
                6'd1: char_to_seg = 7'b1111001;
                6'd2: char_to_seg = 7'b0100100;
                6'd3: char_to_seg = 7'b0110000;
                6'd4: char_to_seg = 7'b0011001;
                6'd5: char_to_seg = 7'b0010010;
                6'd6: char_to_seg = 7'b0000010;
                6'd7: char_to_seg = 7'b1111000;
                6'd8: char_to_seg = 7'b0000000;
                6'd9: char_to_seg = 7'b0010000;

                // Chu A - Z
                6'd10: char_to_seg = 7'b0001000; // A
                6'd11: char_to_seg = 7'b0000011; // b
                6'd12: char_to_seg = 7'b1000110; // C
                6'd13: char_to_seg = 7'b0100001; // d
                6'd14: char_to_seg = 7'b0000110; // E
                6'd15: char_to_seg = 7'b0001110; // F
                6'd16: char_to_seg = 7'b0000010; // G
                6'd17: char_to_seg = 7'b0001001; // H
                6'd18: char_to_seg = 7'b1111001; // I
                6'd19: char_to_seg = 7'b1100001; // J
                6'd20: char_to_seg = 7'b0001001; // K
                6'd21: char_to_seg = 7'b1000111; // L
                6'd22: char_to_seg = 7'b0101011; // M
                6'd23: char_to_seg = 7'b0101011; // n
                6'd24: char_to_seg = 7'b1000000; // O
                6'd25: char_to_seg = 7'b0001100; // P
                6'd26: char_to_seg = 7'b0011000; // q
                6'd27: char_to_seg = 7'b0101111; // r
                6'd28: char_to_seg = 7'b0010010; // S
                6'd29: char_to_seg = 7'b0000111; // t
                6'd30: char_to_seg = 7'b1000001; // U
                6'd31: char_to_seg = 7'b1100011; // V
                6'd32: char_to_seg = 7'b1000001; // W
                6'd33: char_to_seg = 7'b0001001; // X
                6'd34: char_to_seg = 7'b0010001; // Y
                6'd35: char_to_seg = 7'b0100100; // Z

                // Khoang trang
                6'd63: char_to_seg = 7'b1111111;

                // Ma khong hop le
                default: char_to_seg = 7'b0111111;

            endcase
        end

    endfunction

endmodule
