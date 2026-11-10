module gate_nor(input wire a, b, output wire y);
    assign y = ~(a | b);
endmodule