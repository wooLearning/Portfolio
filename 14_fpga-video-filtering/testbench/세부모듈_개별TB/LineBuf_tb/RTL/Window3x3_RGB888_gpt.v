module Window3x3_RGB888#(
    parameter DATA_W = 24,
    parameter ADDR_W = 17,
    parameter WIDTH  = 480,
    parameter HEIGHT = 272,
    parameter DEPTH  = 130560     // WIDTH * HEIGHT
)(
    input                   iClk,
    input                   iRst,   // active low
    input                   iEn,

    /* for bram */
    output                  oCs,
    output [ADDR_W-1:0]     oAddr,
    input  [DATA_W-1:0]     iPixel,

    /* next block 3x3 pixel */
    output [DATA_W-1:0]     oOut0,
    output [DATA_W-1:0]     oOut1,
    output [DATA_W-1:0]     oOut2,
    output [DATA_W-1:0]     oOut3,
    output [DATA_W-1:0]     oOut4,
    output [DATA_W-1:0]     oOut5,
    output [DATA_W-1:0]     oOut6,
    output [DATA_W-1:0]     oOut7,
    output [DATA_W-1:0]     oOut8,
    output                  oValid
);

    //-------------------------------------------------------------
    // 1. Address counter (0 ~ DEPTH-1)
    //-------------------------------------------------------------
    reg [ADDR_W-1:0] rAddr;
    always @(posedge iClk or negedge iRst) begin
        if (!iRst)
            rAddr <= {ADDR_W{1'b0}};
        else if (iEn)
            rAddr <= (rAddr == DEPTH - 1) ? {ADDR_W{1'b0}} : rAddr + 1'b1;
    end

    assign oAddr = rAddr;
    assign oCs   = iEn;

    //-------------------------------------------------------------
    // 2. BRAM read delay (sync read 보정)
    //-------------------------------------------------------------
    reg [DATA_W-1:0] iPixel_d1;
    always @(posedge iClk) begin
        iPixel_d1 <= iPixel;
    end

    //-------------------------------------------------------------
    // 3. Row / Col counters (row-major 입력 가정)
    //-------------------------------------------------------------
    localparam COL_W = $clog2(WIDTH);
    localparam ROW_W = $clog2(HEIGHT);

    reg [COL_W-1:0] rColCnt;
    reg [ROW_W-1:0] rRowCnt;

    always @(posedge iClk or negedge iRst) begin
        if (!iRst) begin
            rColCnt <= {COL_W{1'b0}};
            rRowCnt <= {ROW_W{1'b0}};
        end
        else if (iEn) begin
            if (rColCnt == WIDTH - 1) begin
                rColCnt <= {COL_W{1'b0}};
                rRowCnt <= (rRowCnt == HEIGHT - 1) ? {ROW_W{1'b0}} : rRowCnt + 1'b1;
            end
            else begin
                rColCnt <= rColCnt + 1'b1;
            end
        end
    end

    wire wFirstCol = (rColCnt == 0);

    //-------------------------------------------------------------
    // 4. Line buffers (row-1, row-2)
    //-------------------------------------------------------------
    reg [DATA_W-1:0] linebuf0 [0:WIDTH-1];   // row-1
    reg [DATA_W-1:0] linebuf1 [0:WIDTH-1];   // row-2
    integer i;

    always @(posedge iClk or negedge iRst) begin
        if (!iRst) begin
            for (i = 0; i < WIDTH; i = i + 1) begin
                linebuf0[i] <= {DATA_W{1'b0}};
                linebuf1[i] <= {DATA_W{1'b0}};
            end
        end
        else if (iEn) begin
            linebuf1[rColCnt] <= linebuf0[rColCnt];
            linebuf0[rColCnt] <= iPixel_d1;
        end
    end

    wire [DATA_W-1:0] wPixRowM1 = linebuf0[rColCnt]; // row-1
    wire [DATA_W-1:0] wPixRowM2 = linebuf1[rColCnt]; // row-2

    //-------------------------------------------------------------
    // 5. 3x3 horizontal shift registers
    //    r*_c0 : col-2, r*_c1 : col-1, r*_c2 : col
    //-------------------------------------------------------------
    reg [DATA_W-1:0] r0_c0, r0_c1, r0_c2;
    reg [DATA_W-1:0] r1_c0, r1_c1, r1_c2;
    reg [DATA_W-1:0] r2_c0, r2_c1, r2_c2;

    always @(posedge iClk or negedge iRst) begin
        if (!iRst) begin
            {r0_c0,r0_c1,r0_c2,
             r1_c0,r1_c1,r1_c2,
             r2_c0,r2_c1,r2_c2} <= {9*DATA_W{1'b0}};
        end
        else if (iEn) begin
            if (wFirstCol) begin
                // col == 0, 왼쪽 두 칸은 0
                r0_c0 <= {DATA_W{1'b0}};
                r0_c1 <= {DATA_W{1'b0}};
                r0_c2 <= wPixRowM2;

                r1_c0 <= {DATA_W{1'b0}};
                r1_c1 <= {DATA_W{1'b0}};
                r1_c2 <= wPixRowM1;

                r2_c0 <= {DATA_W{1'b0}};
                r2_c1 <= {DATA_W{1'b0}};
                r2_c2 <= iPixel_d1;
            end
            else begin
                r0_c0 <= r0_c1;
                r0_c1 <= r0_c2;
                r0_c2 <= wPixRowM2;

                r1_c0 <= r1_c1;
                r1_c1 <= r1_c2;
                r1_c2 <= wPixRowM1;

                r2_c0 <= r2_c1;
                r2_c1 <= r2_c2;
                r2_c2 <= iPixel_d1;
            end
        end
    end

    //-------------------------------------------------------------
    // 6. Valid flag
    //    - 이 설계에서는 "완전히 내부에 있는 3x3 윈도우"
    //      (대략 row >= 2, col >= 2) 부터만 사용한다고 가정.
    //-------------------------------------------------------------
    wire wValid_next = (rRowCnt >= 2) && (rColCnt >= 2);

    reg rValid;
    always @(posedge iClk or negedge iRst) begin
        if (!iRst)
            rValid <= 1'b0;
        else if (iEn)
            rValid <= wValid_next;
        else
            rValid <= 1'b0;
    end

    //-------------------------------------------------------------
    // 7. Output (oValid=0일 때는 전부 0으로 마스킹)
    //-------------------------------------------------------------
    wire [DATA_W-1:0] wOut0 = r0_c0;
    wire [DATA_W-1:0] wOut1 = r0_c1;
    wire [DATA_W-1:0] wOut2 = r0_c2;
    wire [DATA_W-1:0] wOut3 = r1_c0;
    wire [DATA_W-1:0] wOut4 = r1_c1;
    wire [DATA_W-1:0] wOut5 = r1_c2;
    wire [DATA_W-1:0] wOut6 = r2_c0;
    wire [DATA_W-1:0] wOut7 = r2_c1;
    wire [DATA_W-1:0] wOut8 = r2_c2;

    assign oOut0 = rValid ? wOut0 : {DATA_W{1'b0}};
    assign oOut1 = rValid ? wOut1 : {DATA_W{1'b0}};
    assign oOut2 = rValid ? wOut2 : {DATA_W{1'b0}};
    assign oOut3 = rValid ? wOut3 : {DATA_W{1'b0}};
    assign oOut4 = rValid ? wOut4 : {DATA_W{1'b0}};
    assign oOut5 = rValid ? wOut5 : {DATA_W{1'b0}};
    assign oOut6 = rValid ? wOut6 : {DATA_W{1'b0}};
    assign oOut7 = rValid ? wOut7 : {DATA_W{1'b0}};
    assign oOut8 = rValid ? wOut8 : {DATA_W{1'b0}};

    assign oValid = rValid;

endmodule
