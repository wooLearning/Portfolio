//----------------------------------------------------------------------------------------------------------------+
//----------------------------------------------------------------------------------------------------------------+
// Project: AIX 2025
// Module: bram_ctrl_wr.v
// Description:
//      Address control module for CNN (Only read from RAM to Reg)
//
// History: 2025.04.05 
//----------------------------------------------------------------------------------------------------------------+

module bram_ctrl_wr #(                           
    parameter ADDR_WIDTH        = 14,
    parameter BUF_NUM           = 16,
    parameter CONV02            = 1'b0,
    parameter CONV04            = 1'b0    

) ( input                           i_clk,
    input                           i_rstn,
    input                           i_start,
    input                           i_end,        
    input                           i_restart,
    input                           i_rvalid,
    input                           i_read_done,
    input                           i_read_data_vld,
    input       [7:0]               i_read_data_cnt,

    input                           i_done_00,
    input                           i_done_02,

    // test
    output                          o_stop,

    output                          o_conv_00,
    output                          o_conv_02,
    output                          o_cal,
    output                          o_break,
    output                          o_bram_en,
    output      [BUF_NUM-1:0]       o_bram_cs,
    output      [ADDR_WIDTH-1:0]    o_bram_addr

);


//-----------------------------------------------------------------------------------------------------------------
// Local-parameter
//-----------------------------------------------------------------------------------------------------------------
    // FSM
    localparam      ST_IDLE     = 3'b000,
                    ST_RESET    = 3'b001,
                    ST_WAIT     = 3'b010,
                    ST_END      = 3'b011,
                    ST_EVEN0007 = 3'b101,   
                    ST_EVEN0815 = 3'b100,
                    ST_ODD0007  = 3'b111,   
                    ST_ODD0815  = 3'b110;    


//-----------------------------------------------------------------------------------------------------------------
// Define
//-----------------------------------------------------------------------------------------------------------------
    // Define Reg
    reg  [2:0]              r_cstate;
    reg  [2:0]              r_nstate;
    reg  [2:0]              r_st_buf;

    reg  [1:0]              r_burst_cnt;
    reg                     r_burst_cnt_stop;
    reg  [3:0]              r_pixel_num;
    reg                     r_pixel_num_stop;
    reg                     r_nxt_state_rst;
    reg                     r_nxt_state;

    reg                     r_conv_00;
    reg                     r_conv_02;   
    reg                     r_nxt_en;
    reg                     r_nxt_dn;       
    reg                     r_cal;   
    reg                     r_break;
    reg                     r_bram_en;   
    reg  [1:0]              r_mode;
    reg  [BUF_NUM-1:0]      r_bram_cs;

    // Define Wire
    wire                    w_burst_end;
    wire [2:0]              w_pixel_end;
    wire [2:0]              w_break_en;
    wire [3:0]              w_burst_cnt;
    

//-----------------------------------------------------------------------------------------------------------------
// Assignment
//-----------------------------------------------------------------------------------------------------------------
    assign  w_burst_end     = i_read_data_cnt[4];
    assign  w_burst_cnt     = i_read_data_cnt[3:0];
    assign  w_pixel_end     = r_pixel_num[3:0];
    assign  w_break_en      = r_pixel_num[2:0];
    assign  o_conv_00       = r_conv_00;
    assign  o_conv_02       = r_conv_02;
    assign  o_cal           = r_cal;
    assign  o_break         = r_break;
    assign  o_stop          = ((r_st_buf == ST_EVEN0007) || (r_st_buf == ST_ODD0007));
    assign  o_bram_en       = r_bram_en;
    assign  o_bram_addr     = {CONV02, r_pixel_num, CONV04, r_mode, r_burst_cnt, w_burst_cnt};
    assign  o_bram_cs       = r_bram_cs;                


//-----------------------------------------------------------------------------------------------------------------
// FSM
//-----------------------------------------------------------------------------------------------------------------
    // State configuration (r_cstate)
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn) 
            r_cstate <= ST_IDLE;

        else 
            r_cstate <= r_nstate;

    end

    // State configuration (r_nstate)               
    always @(*) begin
        if(i_end)
           r_nstate = ST_END; 

        else 
            case(r_cstate)
                ST_IDLE     :   begin
                    if(i_start)         begin
                        r_nstate = ST_RESET;
                        r_mode   = 2'b00;
                        r_nxt_en = 1'b0;
                        r_nxt_dn = 1'b1;
                    end

                    else        begin
                        r_nstate = ST_IDLE;
                        r_st_buf = ST_IDLE;
                    end
                        
                end 

                ST_RESET    :   begin
                    if(r_nxt_state_rst) begin
                        r_nstate = ST_EVEN0007;
                        r_mode   = 2'b01;
                        r_nxt_en = 1'b0;
                        r_nxt_dn = 1'b1;
                    end
                        
                    else
                        r_nstate = ST_RESET;

                end 

                ST_EVEN0007 :   begin                     
                    if(r_nxt_state)     begin
                        r_nstate = ST_WAIT;
                        r_st_buf = ST_EVEN0815;
                        r_mode   = 2'b01;
                        r_nxt_en = 1'b0;
                    end

                    else
                        r_nstate = ST_EVEN0007;

                end 

                ST_EVEN0815 :   begin
                    if(r_nxt_state)     begin
                        r_nstate = ST_WAIT;
                        r_st_buf = ST_ODD0007;
                        r_mode   = 2'b00;

                        case (r_nxt_dn)
                            1'b0    : r_nxt_en = 1'b1;
                            1'b1    : r_nxt_en = 1'b0; 
                        endcase
                    end

                    else
                        r_nstate = ST_EVEN0815;

                end
                
                ST_ODD0007  :   begin
                    if(r_nxt_state)     begin
                        r_nstate = ST_WAIT;
                        r_st_buf = ST_ODD0815;
                        r_mode   = 2'b00;
                        r_nxt_en = 1'b0;
                        r_nxt_dn = 1'b0;
                    end

                    else
                        r_nstate = ST_ODD0007;

                end

                ST_ODD0815  :   begin
                    if(r_nxt_state)     begin
                        r_nstate = ST_WAIT;
                        r_st_buf = ST_EVEN0007;
                        r_mode   = 2'b01;

                        case (r_nxt_dn)
                            1'b0    : r_nxt_en = 1'b1;
                            1'b1    : r_nxt_en = 1'b0; 
                        endcase
                    end

                    else
                        r_nstate = ST_ODD0815;

                end

                ST_WAIT     :   begin
                    if(i_restart)
                        r_nstate = r_st_buf;

                    else 
                        r_nstate = ST_WAIT;

                end

                ST_END      :   begin
                    if(i_restart)
                        r_nstate = ST_IDLE;

                    else 
                        r_nstate = ST_END;

                end

                default     : 
                        r_nstate = ST_IDLE;

            endcase

    end


//-----------------------------------------------------------------------------------------------------------------
// Operation
//-----------------------------------------------------------------------------------------------------------------
    // Operation configuration (r_burst_cnt_stop)       
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn) 
            r_burst_cnt_stop    <= 1'b0;

        else
            case(w_burst_end)
                1'b0    :   r_burst_cnt_stop    <= 1'b0;
                1'b1    :   r_burst_cnt_stop    <= 1'b1;
                default :   r_burst_cnt_stop    <= r_burst_cnt_stop;
            endcase

    end 


    // Operation configuration (r_burst_cnt)
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn) 
            r_burst_cnt <= 2'b0;

        else if((w_burst_end) && (!r_burst_cnt_stop))
            r_burst_cnt <= r_burst_cnt + 1;

        else
            r_burst_cnt <= r_burst_cnt;

    end

    
    // Operation configuration (r_pixel_num_stop)
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn) 
            r_pixel_num_stop    <= 1'b0;

        else
            case(r_burst_cnt)
                2'd0    :   r_pixel_num_stop    <= 1'b0;
                2'd1    :   r_pixel_num_stop    <= 1'b0;
                2'd2    :   r_pixel_num_stop    <= 1'b0;
                2'd3    :   r_pixel_num_stop    <= 1'b1;
                default :   r_pixel_num_stop    <= r_pixel_num_stop;
            endcase

    end


    // Operation configuration (r_cal)       
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn) 
            r_cal               <= 1'b0;

        else if((r_nstate == ST_IDLE) || (r_nstate == ST_RESET))
            r_cal               <= 1'b0;

        else
            r_cal               <= 1'b1;

    end 


    // Operation configuration (r_pixel_num)
    always @(posedge i_clk or negedge i_rstn)   begin   
        if(!i_rstn) 
            r_pixel_num         <= 3'b0;

        else if((r_burst_cnt == 2'd3) && (r_pixel_num_stop) && (w_burst_end) && (!r_burst_cnt_stop))
            r_pixel_num         <= r_pixel_num + 1;

        else
            r_pixel_num         <= r_pixel_num;

    end


    // Operation configuration (r_nxt_state_rst)
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn)
            r_nxt_state_rst     <= 1'b0;

        else if((r_cstate == ST_RESET) && (r_pixel_num == 4'd15) && (r_burst_cnt == 2'd3) && (r_pixel_num_stop) && (w_burst_end) && (!r_burst_cnt_stop))
            r_nxt_state_rst     <= 1'b1;
            
        else
            r_nxt_state_rst     <= 1'b0;        

    end


    // Operation configuration (r_nxt_state)
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn)
            r_nxt_state         <= 1'b0;

        else if((w_pixel_end == 3'd7) && (r_burst_cnt == 2'd3) && (r_pixel_num_stop) && (w_burst_end) && (!r_burst_cnt_stop))
            r_nxt_state         <= 1'b1;
            
        else
            r_nxt_state         <= 1'b0;

    end


    // Operation configuration (r_bram_cs)                                          
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn)
            r_bram_cs <= 16'h0000;

        else if(i_rvalid) begin
            case(r_pixel_num)
                4'd0   :   r_bram_cs <= 16'b0000_0000_0000_0001;
                4'd1   :   r_bram_cs <= 16'b0000_0000_0000_0010;
                4'd2   :   r_bram_cs <= 16'b0000_0000_0000_0100;
                4'd3   :   r_bram_cs <= 16'b0000_0000_0000_1000;
                4'd4   :   r_bram_cs <= 16'b0000_0000_0001_0000;
                4'd5   :   r_bram_cs <= 16'b0000_0000_0010_0000;
                4'd6   :   r_bram_cs <= 16'b0000_0000_0100_0000;
                4'd7   :   r_bram_cs <= 16'b0000_0000_1000_0000;
                4'd8   :   r_bram_cs <= 16'b0000_0001_0000_0000;
                4'd9   :   r_bram_cs <= 16'b0000_0010_0000_0000;
                4'd10  :   r_bram_cs <= 16'b0000_0100_0000_0000;
                4'd11  :   r_bram_cs <= 16'b0000_1000_0000_0000;
                4'd12  :   r_bram_cs <= 16'b0001_0000_0000_0000;
                4'd13  :   r_bram_cs <= 16'b0010_0000_0000_0000;
                4'd14  :   r_bram_cs <= 16'b0100_0000_0000_0000;
                4'd15  :   r_bram_cs <= 16'b1000_0000_0000_0000;

            endcase

        end

        else
            r_bram_cs <= 16'h0000;

    end


    // Operation configuration (r_break)
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn)
            r_break             <= 1'b0;

        else if(i_restart)
            r_break             <= 1'b0;
 
        else if((r_nstate != ST_RESET) && (i_read_done) && (r_burst_cnt == 2'd3) && (w_break_en == 3'b111))
            r_break             <= 1'b1;
            
        else
            r_break             <= r_break;

    end

    
    // Operation configuration (r_bram_en)
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn)
            r_bram_en           <= 1'b0;

        else if((i_read_data_vld) || (i_rvalid))
            r_bram_en           <= 1'b1;
            
        else
            r_bram_en           <= 1'b0;

    end


    // Operation configuration (r_conv_00)       
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn) 
            r_conv_00           <= 1'b0;

        else if(!((r_nstate == ST_IDLE) || (r_nstate == ST_RESET)) && ((!r_break) || (!i_done_00) || (!i_done_02)))
            r_conv_00           <= 1'b1;

        else
            r_conv_00           <= 1'b0;

    end


    // Operation configuration (r_conv_02)       
    always @(posedge i_clk or negedge i_rstn)   begin
        if(!i_rstn) 
            r_conv_02           <= 1'b0;

        else if((r_break) && (r_nxt_en) && ((r_st_buf == ST_EVEN0007) || (r_st_buf == ST_ODD0007)))
            r_conv_02           <= 1'b1;

        else if((r_break) && (i_done_02))
            r_conv_02           <= 1'b0;

        else
            r_conv_02           <= r_conv_02;

    end


endmodule