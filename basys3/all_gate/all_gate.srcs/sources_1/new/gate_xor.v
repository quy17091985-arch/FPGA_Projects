module gate_xnor(input wire a, b, output wire y);
    assign y = ~(a ^ b);
endmodule