 `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 09:01:13 PM
// Design Name: 
// Module Name: all_gate_top
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


module all_gate_top #(
    parameter integer CLK_HZ = 100000000,
    parameter integer BTN_DEBOUNCE_CYCLES = 2000000,
    parameter integer MULTICLICK_CYCLES = 40000000,
    parameter integer SHOW_CYCLES = 100000000,
    parameter integer SCAN_DIV = 100000
)(
    input wire clk,
    input wire [15:0] sw,
    input wire btnU, btnR, btnD, btnL, btnC,
    output reg [15:0] led,
    output reg [6:0] seg,
    output reg [3:0] an,
    output wire dp
);

    localparam integer CLICK_W =
        (MULTICLICK_CYCLES < 2) ? 1 :
        $clog2(MULTICLICK_CYCLES);

    localparam integer SHOW_W =
        (SHOW_CYCLES < 2) ? 1 :
        $clog2(SHOW_CYCLES);

    localparam integer SCAN_W =
        (SCAN_DIV < 2) ? 1 :
        $clog2(SCAN_DIV);

    localparam [2:0] NO_PARTNER = 3'd7;

    localparam [2:0]
        MSG_NONE = 0,
        MSG_SAVE = 1,
        MSG_MERGE = 2,
        MSG_ERROR = 3,
        MSG_OFF = 4;

    // Dong bo 16 cong tac
    reg [15:0] sw_meta = 16'b0;
    reg [15:0] sw_sync = 16'b0;
    reg [15:0] sw_prev = 16'b0;

    always @(posedge clk) begin
        sw_meta <= sw;
        sw_sync <= sw_meta;
        sw_prev <= sw_sync;
    end

    wire sw14_rise = sw_sync[14] && !sw_prev[14];
    wire sw14_fall = !sw_sync[14] && sw_prev[14];

    wire sw15_rise = sw_sync[15] && !sw_prev[15];
    wire sw15_fall = !sw_sync[15] && sw_prev[15];

    // Chong doi 5 nut nhan
    wire [4:0] press;

    button_debounce #(
        .CYCLES(BTN_DEBOUNCE_CYCLES)
    ) b_u(clk, btnU, press[0]);

    button_debounce #(
        .CYCLES(BTN_DEBOUNCE_CYCLES)
    ) b_r(clk, btnR, press[1]);

    button_debounce #(
        .CYCLES(BTN_DEBOUNCE_CYCLES)
    ) b_d(clk, btnD, press[2]);

    button_debounce #(
        .CYCLES(BTN_DEBOUNCE_CYCLES)
    ) b_l(clk, btnL, press[3]);

    button_debounce #(
        .CYCLES(BTN_DEBOUNCE_CYCLES)
    ) b_c(clk, btnC, press[4]);

    // Xac dinh button duoc nhan
    reg button_event;
    reg [2:0] button_id;

    always @(*) begin
        button_event = |press;
        button_id = 3'd0;

        if (press[4])
            button_id = 3'd4;
        else if (press[3])
            button_id = 3'd3;
        else if (press[2])
            button_id = 3'd2;
        else if (press[1])
            button_id = 3'd1;
        else if (press[0])
            button_id = 3'd0;
    end

    // Chon 10 phep logic
    function [3:0] chosen_operation;
        input [2:0] which;
        input second_click;
        begin
            case (which)
                3'd0: chosen_operation =
                    second_click ? 4'd1 : 4'd0;

                3'd1: chosen_operation =
                    second_click ? 4'd3 : 4'd2;

                3'd2: chosen_operation =
                    second_click ? 4'd5 : 4'd4;

                3'd3: chosen_operation =
                    second_click ? 4'd7 : 4'd6;

                3'd4: chosen_operation =
                    second_click ? 4'd9 : 4'd8;

                default: chosen_operation = 4'd4;
            endcase
        end
    endfunction

    // Ten gate
    function [31:0] gate_text;
        input [3:0] op;
        begin
            case (op)
                4'd0: gate_text = "notA";
                4'd1: gate_text = "notb";
                4'd2: gate_text = " or ";
                4'd3: gate_text = " nor";
                4'd4: gate_text = "And ";
                4'd5: gate_text = "nAnd";
                4'd6: gate_text = "Hor ";
                4'd7: gate_text = "Hnor";
                4'd8: gate_text = "bUFA";
                4'd9: gate_text = "bUFb";
                default: gate_text = "----";
            endcase
        end
    endfunction

    // Luu cong dang duoc chon
    reg [3:0] selected_gate = 4'd4;
    reg selected_valid = 1'b0;

    // Xu ly nhan 1, 2, 3 lan
    reg [2:0] last_button = 3'd7;
    reg [1:0] click_number = 0;
    reg click_window = 0;
    reg [CLICK_W-1:0] click_timer = 0;

    reg reset_armed = 0;
    reg merge_mode = 0;

    // Chon hai SW khi SW14 dang ON
    reg [1:0] select_count = 0;
    reg [3:0] selected_a = 0;
    reg [3:0] selected_b = 0;


    // Phat hien SW thay doi
    wire [13:0] change_mask =
        sw_sync[13:0] ^ sw_prev[13:0];

    wire change_valid = |change_mask;
    wire [13:0] first_change;

    assign first_change[0] = change_mask[0];

    // Chon SW co chi so nho nhat
    genvar enc;

    generate
        for (enc = 1; enc < 14; enc = enc + 1) begin: ENC
            assign first_change[enc] =
                change_mask[enc] &
                ~(|change_mask[enc-1:0]);
        end
    endgenerate

    // Ma hoa chi so SW
    wire [3:0] change_index;

    assign change_index[0] =
        first_change[1]  | first_change[3] |
        first_change[5]  | first_change[7] |
        first_change[9]  | first_change[11] |
        first_change[13];

    assign change_index[1] =
        first_change[2]  | first_change[3] |
        first_change[6]  | first_change[7] |
        first_change[10] | first_change[11];

    assign change_index[2] =
        first_change[4]  | first_change[5] |
        first_change[6]  | first_change[7] |
        first_change[12] | first_change[13];

    assign change_index[3] =
        |first_change[13:8];

    // Luu chi so SW vao thanh ghi
    reg edge_valid_d = 1'b0;
    reg [3:0] edge_index_d = 4'd0;

    always @(posedge clk) begin
        edge_valid_d <= change_valid;
        edge_index_d <= change_index;
    end

    // Bo nho toi da 7 cap
    reg [6:0] slot_valid = 7'b0;

    reg [3:0] slot_a [0:6];
    reg [3:0] slot_b [0:6];
    reg [3:0] slot_op [0:6];

    reg [2:0] partner [0:6];
    reg [2:0] last_single = NO_PARTNER;

    integer init_i;

    initial begin
        for (init_i = 0; init_i < 7; init_i = init_i + 1) begin
            slot_a[init_i] = 0;
            slot_b[init_i] = 0;
            slot_op[init_i] = 4'd4;
            partner[init_i] = NO_PARTNER;
        end
    end

    // Kiem tra SW bi trung va slot trong
    reg duplicate_pin;
    reg free_found;
    reg [2:0] free_slot;

    integer f;

    always @(*) begin
        duplicate_pin = 0;
        free_found = 0;
        free_slot = 0;

        for (f = 0; f < 7; f = f + 1) begin

            if (slot_valid[f]) begin

                if (
                    slot_a[f] == selected_a ||
                    slot_a[f] == selected_b ||
                    slot_b[f] == selected_a ||
                    slot_b[f] == selected_b
                )
                    duplicate_pin = 1;

            end
            else if (!free_found) begin
                free_found = 1;
                free_slot = f;
            end
        end
    end

    // Trang thai thong bao tren LED 7 doan
    reg [2:0] msg_kind = MSG_NONE;
    reg [3:0] msg_gate = 4'd4;
    reg msg_phase = 0;
    reg [SHOW_W-1:0] msg_timer = 0;

    integer r;

    // Bo dieu khien chinh
    always @(posedge clk) begin

        // Reset khi nhan BTNC 3 lan va bat SW15
        if (sw15_rise && reset_armed) begin

            slot_valid <= 7'b0;

            for (r = 0; r < 7; r = r + 1) begin
                slot_a[r] <= 0;
                slot_b[r] <= 0;
                slot_op[r] <= 4'd4;
                partner[r] <= NO_PARTNER;
            end

            last_single <= NO_PARTNER;

            merge_mode <= 0;
            selected_valid <= 0;
            reset_armed <= 0;

            select_count <= 0;

            click_window <= 0;
            click_timer <= 0;
            click_number <= 0;
            last_button <= 3'd7;

            msg_kind <= MSG_OFF;
            msg_gate <= 4'd4;
            msg_phase <= 0;
            msg_timer <= 0;

        end
        else begin

            // SW15 ON: ghep cong
            // SW15 OFF: luu cap doc lap
            if (sw15_rise)
                merge_mode <= 1'b1;

            if (sw15_fall)
                merge_mode <= 1'b0;

            // Xu ly su kien nhan nut
            if (button_event) begin

                // Nhan lan thu 2
                if (
                    click_window &&
                    last_button == button_id &&
                    click_number == 1
                ) begin

                    click_number <= 2;

                    selected_gate <=
                        chosen_operation(button_id, 1'b1);

                    selected_valid <= 1;

                end

                // BTNC lan thu 3: cho reset
                else if (
                    click_window &&
                    last_button == button_id &&
                    click_number == 2 &&
                    button_id == 4 &&
                    !sw_sync[15]
                ) begin

                    click_number <= 3;
                    reset_armed <= 1;
                    selected_valid <= 0;

                end
                else begin

                    click_number <= 1;

                    selected_gate <=
                        chosen_operation(button_id, 1'b0);

                    selected_valid <= 1;

                end

                last_button <= button_id;
                click_window <= 1;
                click_timer <= MULTICLICK_CYCLES - 1;

            end
            else if (click_window) begin

                if (click_timer == 0) begin
                    click_window <= 0;
                    click_number <= 0;
                end
                else begin
                    click_timer <= click_timer - 1'b1;
                end

            end

            // Bat dau chon cap SW
            // Bat dau chon cap
            if (sw14_rise) begin

                select_count <= 2'd0;
                selected_a <= 4'd0;
                selected_b <= 4'd0;

            end

            // Luu tung SW da chon
            else if (sw_sync[14] && edge_valid_d) begin

                // SW thu nhat
                if (select_count == 2'd0) begin

                    selected_a <= edge_index_d;
                    select_count <= 2'd1;

                end

                // SW thu hai
                else if (
                    select_count == 2'd1 &&
                    edge_index_d != selected_a
                ) begin

                    selected_b <= edge_index_d;
                    select_count <= 2'd2;

                end

            end


            // SW14 OFF: chot cap
            if (sw14_fall) begin

                selected_valid <= 0;

                msg_phase <= 0;
                msg_timer <= 0;

                if (
                    select_count != 2 ||
                    !selected_valid ||
                    duplicate_pin ||
                    !free_found ||
                    (merge_mode &&
                     last_single == NO_PARTNER)
                ) begin

                    msg_kind <= MSG_ERROR;

                end
                else begin

                    slot_valid[free_slot] <= 1;

                    slot_a[free_slot] <= selected_a;
                    slot_b[free_slot] <= selected_b;
                    slot_op[free_slot] <= selected_gate;

                    msg_gate <= selected_gate;

                    if (merge_mode) begin

                        partner[free_slot] <= last_single;
                        partner[last_single] <= free_slot;

                        last_single <= NO_PARTNER;
                        msg_kind <= MSG_MERGE;

                    end
                    else begin

                        partner[free_slot] <= NO_PARTNER;
                        last_single <= free_slot;

                        msg_kind <= MSG_SAVE;

                    end

                end

            end
            else if (msg_kind != MSG_NONE) begin

                if (msg_timer == SHOW_CYCLES - 1) begin

                    msg_timer <= 0;

                    if (
                        (msg_kind == MSG_SAVE ||
                         msg_kind == MSG_MERGE) &&
                        !msg_phase
                    )
                        msg_phase <= 1;
                    else
                        msg_kind <= MSG_NONE;

                end
                else begin
                    msg_timer <= msg_timer + 1'b1;
                end

            end

        end
    end

    // Tinh ket qua cua 7 cap cong logic
    wire [6:0] pair_value;

    genvar g;

    generate
        for (g = 0; g < 7; g = g + 1) begin: GP

            gate_select u_gate (
                .a(sw_sync[slot_a[g]]),
                .b(sw_sync[slot_b[g]]),
                .code(slot_op[g]),
                .y(pair_value[g])
            );

        end
    endgenerate

    // Cap doc lap: Y = gate(A,B)
    // Cap ghep: Y = Y1 AND Y2
    integer p;
    reg result_value;

    always @(*) begin

        led = 16'b0;
        result_value = 1'b0;

        for (p = 0; p < 7; p = p + 1) begin

            if (slot_valid[p]) begin

                result_value = pair_value[p];

                if (
                    partner[p] != NO_PARTNER &&
                    slot_valid[partner[p]]
                )
                    result_value =
                        pair_value[p] &
                        pair_value[partner[p]];

                led[slot_a[p]] = result_value;
                led[slot_b[p]] = result_value;

            end
        end

    end

    // Hien thi thong bao
    reg [31:0] screen_word;

    always @(*) begin

        screen_word = "    ";

        if (reset_armed)
            screen_word = "rSt ";

        else if (msg_kind == MSG_ERROR)
            screen_word = "Err ";

        else if (msg_kind == MSG_OFF)
            screen_word = "OFF ";

        else if (
            msg_kind == MSG_SAVE ||
            msg_kind == MSG_MERGE
        ) begin

            if (!msg_phase)
                screen_word = gate_text(msg_gate);

            else if (msg_kind == MSG_SAVE)
                screen_word = "LUU ";

            else
                screen_word = "GOP ";

        end
        else if (selected_valid)
            screen_word = gate_text(selected_gate);

    end

    // Quet LED 7 doan
    reg [SCAN_W-1:0] scan_count = 0;
    reg [1:0] digit = 0;
    reg [7:0] character;

    always @(posedge clk) begin

        if (scan_count == SCAN_DIV - 1) begin
            scan_count <= 0;
            digit <= digit + 1'b1;
        end
        else
            scan_count <= scan_count + 1'b1;

    end

    always @(*) begin

        case (digit)

            2'd0: begin
                an = 4'b1110;
                character = screen_word[7:0];
            end

            2'd1: begin
                an = 4'b1101;
                character = screen_word[15:8];
            end

            2'd2: begin
                an = 4'b1011;
                character = screen_word[23:16];
            end

            default: begin
                an = 4'b0111;
                character = screen_word[31:24];
            end

        endcase

        seg = char_segments(character);

    end

    assign dp = 1'b1;

    // seg = {g,f,e,d,c,b,a}
    // 0 la sang, 1 la tat
    function [6:0] char_segments;

        input [7:0] c;

        begin
            case (c)

                "0","O":
                    char_segments = 7'b1000000;

                "1","I":
                    char_segments = 7'b1111001;

                "A":
                    char_segments = 7'b0001000;

                "n","N":
                    char_segments = 7'b0101011;

                "d":
                    char_segments = 7'b0100001;

                "o":
                    char_segments = 7'b0100011;

                "r":
                    char_segments = 7'b0101111;

                "t":
                    char_segments = 7'b0000111;

                "H":
                    char_segments = 7'b0001001;

                "G":
                    char_segments = 7'b0000010;

                "L":
                    char_segments = 7'b1000111;

                "U":
                    char_segments = 7'b1000001;

                "b":
                    char_segments = 7'b0000011;

                "F":
                    char_segments = 7'b0001110;

                "P":
                    char_segments = 7'b0001100;

                "S":
                    char_segments = 7'b0010010;

                "E":
                    char_segments = 7'b0000110;

                "-":
                    char_segments = 7'b0111111;

                default:
                    char_segments = 7'b1111111;

            endcase
        end
    endfunction

endmodule

