`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:44:16 PM
// Design Name: 
// Module Name: gate_select
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


module gate_select (
    input wire a, b,
    input wire [3:0] code,
    output reg y
);

    wire and_y, nand_y;
    wire or_y, nor_y;
    wire xor_y, xnor_y;
    wire not_a_y, not_b_y;
    wire buf_a_y, buf_b_y;

    gate_and u_and (
        .a(a), .b(b), .y(and_y)
    );

    gate_nand u_nand (
        .a(a), .b(b), .y(nand_y)
    );

    gate_or u_or (
        .a(a), .b(b), .y(or_y)
    );

    gate_nor u_nor (
        .a(a), .b(b), .y(nor_y)
    );

    gate_xor u_xor (
        .a(a), .b(b), .y(xor_y)
    );

    gate_xnor u_xnor (
        .a(a), .b(b), .y(xnor_y)
    );

    gate_not u_not_a (
        .a(a), .y(not_a_y)
    );

    gate_not u_not_b (
        .a(b), .y(not_b_y)
    );

    gate_buffer u_buf_a (
        .a(a), .y(buf_a_y)
    );

    gate_buffer u_buf_b (
        .a(b), .y(buf_b_y)
    );

    always @(*) begin
        case (code)
            4'd0: y = not_a_y;
            4'd1: y = not_b_y;
            4'd2: y = or_y;
            4'd3: y = nor_y;
            4'd4: y = and_y;
            4'd5: y = nand_y;
            4'd6: y = xor_y;
            4'd7: y = xnor_y;
            4'd8: y = buf_a_y;
            4'd9: y = buf_b_y;
            default: y = 1'b0;
        endcase
    end

endmodule

