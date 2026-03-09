 `timescale 1ns / 1ps


module mul(
    input wire clk,
    input wire         [ 7:0] a, b,   // 8-bit INT8 inputs
    input wire signed  [ 7:0] c,      // 8-bit INT8 weight
    output wire signed [15:0] ac,
    output wire signed [15:0] bc
);
    reg signed  [32:0] p;    // DSP output
    // Sign-extend and pack inputs for DSP48E1
    //    wire signed [24:0] packed_ab = {a, 17'b0} + {{17{b[7]}}, b};  // a << 17 + b
    // wire signed [17:0] weight_c = {{10{c[7]}},c};           // sign-extended c to 18-bits

    wire [ 7:0] weight_c = c;                           // just 8-bits

    wire temp = (b==0) ? 1'b0 : c[7];
    wire [31:0] w_carry = {temp,16'b0};
    wire               [23:0] dspin_a = {a, 16'b0};
    wire               [23:0] dspin_b = {{16{b[7]}}, b};

    // DSP result
    wire signed [33:0] dsp_p;

    dsp_macro_4  u_dsp (
        .CLK(clk),
        .C(w_carry),
        .A(dspin_a),       // 25-bit input  -> 24-bit input
        .D(dspin_b),       // 25-bit input  -> 24-bit input
        .B(weight_c),      // 18-bit weight ->  7-bit input
        .P(dsp_p)          // 48-bit output -> 33-bit output
    );


    //wire cond = (dspin_b == 0) ? 1'b0 : p[31];
    // Split output
    assign bc = dsp_p[15:0];            // Lower product
    assign ac = dsp_p[31:16];// + c[7];//cond;           // Upper product

endmodule




// `timescale 1ns / 1ps


// module mul(
//     input wire clk,
//     input  wire         [ 7:0] a,
//     input  wire         [ 7:0]  b,   // 8-bit INT8 inputs
//     input wire signed  [ 7:0] c,      // 8-bit INT8 weight
//     output wire signed [15:0] ac,
//     output wire signed [15:0] bc
// );

//     // Sign-extend and pack inputs for DSP48E1
//     //    wire signed [24:0] packed_ab = {a, 17'b0} + {{17{b[7]}}, b};  // a << 17 + b
//     // wire signed [17:0] weight_c = {{10{c[7]}},c};           // sign-extended c to 18-bits
//     wire signed [ 7:0] weight_c = c;                           // just 8-bits
    
//     wire [23:0] dspin_a = {a, 16'b0};
//     wire [23:0] dspin_b = {{16{b[7]}}, b};

//     // DSP result
//     wire signed [32:0] dsp_p; 

//     dsp_macro_3 u_dsp (
//         .CLK(clk),
//         .A(dspin_a),       // 25-bit input  -> 24-bit input
//         .D(dspin_b),       // 25-bit input  -> 24-bit input
//         .B(weight_c),      // 18-bit weight ->  7-bit input
//         .P(dsp_p)          // 48-bit output -> 33-bit output
//     );

//     // Split output
//     assign bc = dsp_p[15:0];            // Lower product

//    //this block should be modified // adding condtion if weight pos or negative
//    //1'b1 => weight's msb
//     assign ac = dsp_p[31:16] + c[7];    // Upper product

// endmodule