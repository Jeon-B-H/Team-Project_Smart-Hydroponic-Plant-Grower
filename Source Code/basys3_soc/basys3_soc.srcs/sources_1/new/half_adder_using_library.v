module half_adder (
    input a, b,
    output s, c); 
    
    and(c, a, b);
    xor(s, a, b);
    
endmodule