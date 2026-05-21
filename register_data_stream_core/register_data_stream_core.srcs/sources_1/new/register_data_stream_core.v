`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Gill Electronics
// Engineer: Ryan Gill
// 
// Create Date: 05/20/2026 08:03:18 PM
// Design Name: register_data_stream_core
// Module Name: register_data_stream_core
// Project Name: Register Data Stream Core
// Target Devices: Artix 7
// Tool Versions: Vivado 2025.2
// Description: Custom IP core that allows the client to write to and read from a 
//set of registers while the FPGA streams data to the client

// Revision: 0
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module register_data_stream_core #(
    parameter reg0_def = 0,
    parameter reg1_def = 0,
    parameter reg2_def = 0,
    parameter reg3_def = 0,
    parameter reg4_def = 0,
    parameter reg5_def = 0,
    parameter reg6_def = 0,
    parameter reg7_def = 0,
    parameter reg8_def = 0,
    parameter reg9_def = 0,
    parameter reg10_def = 0,
    parameter reg11_def = 0,
    parameter reg12_def = 0,
    parameter reg13_def = 0,
    parameter reg14_def = 0,
    parameter reg15_def = 0
)(
    input clk,
    input rst,  //active high
    
    //Interface from client to server
    input from_client_tvalid,
    output reg from_client_tready = 0,
    input [7:0] from_client_tdata,
    input from_client_tlast,
    
    //Interface from server to client
    output reg to_client_primary_tvalid = 0,
    input to_client_primary_tready,
    output reg [7:0] to_client_primary_tdata = 0,
    output reg to_client_primary_tlast = 0,
    
    //Registers client can write to
    output reg [31:0] reg0 = reg0_def,
    output reg [31:0] reg1 = reg1_def,
    output reg [31:0] reg2 = reg2_def,
    output reg [31:0] reg3 = reg3_def,
    output reg [31:0] reg4 = reg4_def,
    output reg [31:0] reg5 = reg5_def,
    output reg [31:0] reg6 = reg6_def,
    output reg [31:0] reg7 = reg7_def,
    output reg [31:0] reg8 = reg8_def,
    output reg [31:0] reg9 = reg9_def,
    output reg [31:0] reg10 = reg10_def,
    output reg [31:0] reg11 = reg11_def,
    output reg [31:0] reg12 = reg12_def,
    output reg [31:0] reg13 = reg13_def,
    output reg [31:0] reg14 = reg14_def,
    output reg [31:0] reg15 = reg15_def,
    
    //Registers client can only read
    input [31:0] reg16,
    input [31:0] reg17,
    input [31:0] reg18,
    input [31:0] reg19,
    input [31:0] reg20,
    input [31:0] reg21,
    input [31:0] reg22,
    input [31:0] reg23,
    input [31:0] reg24,
    input [31:0] reg25,
    input [31:0] reg26,
    input [31:0] reg27,
    input [31:0] reg28,
    input [31:0] reg29,
    input [31:0] reg30,
    input [31:0] reg31,
    
    //Register flags
    output reg client_updated = 0,
    input update_ackd,
    
    //Trigger output
    output reg trigger = 0
    
    //TODO memory buffer
);

//The longest message we will get is 67 bytes: 3 bytes for the header and 
//64 bytes for the payload (write all registers). 67 bytes * 8 = 536 bits
localparam MAX_MSG_BITS = 536;

//Create buffer to rx incoming message and variables for state machine
reg [MAX_MSG_BITS-1:0] buffer = 0;
reg [7:0] cur_state = 0;
reg [15:0] buf_idx = 0;

//Server logic
always @ (posedge(clk)) begin
    if (rst) begin
        from_client_tready <= 0;
        to_client_primary_tvalid <= 0;
        to_client_primary_tdata <= 0;
        to_client_primary_tlast <= 0;
        reg0 <= reg0_def;
        reg1 <= reg1_def;
        reg2 <= reg2_def;
        reg3 <= reg3_def;
        reg4 <= reg4_def;
        reg5 <= reg5_def;
        reg6 <= reg6_def;
        reg7 <= reg7_def;
        reg8 <= reg8_def;
        reg9 <= reg9_def;
        reg10 <= reg10_def;
        reg11 <= reg11_def;
        reg12 <= reg12_def;
        reg13 <= reg13_def;
        reg14 <= reg14_def;
        reg15 <= reg15_def;
        client_updated <= 0;
        trigger <= 0;
        buffer <= 0;
        cur_state <= 0;
        buf_idx <= 0;
    end
    else begin
        case (cur_state)
            0: begin    //READY TO RECEIVE
                //We are ready to receive a command so bring the ready signal high
                from_client_tready <= 1;
                buf_idx <= 0;
                cur_state <= 1;
            end
            1: begin    //RECEIVING
                //We are now receiving so everytime a valid signal comes along 
                //we put it in the buffer
                if (from_client_tvalid) begin
                    buffer[buf_idx +: 8] <= from_client_tdata;
                    if ((buf_idx >= (MAX_MSG_BITS - 8)) && !from_client_tlast) begin
                        //We have reached the end of the buffer before tlast went 
                        //high meaning we have received a packet that is too big and 
                        //therefore an unknown command
                        from_client_tready <= 0;
                        buf_idx <= 0;
                        cur_state <= 2;
                    end
                    else begin
                        //We have not uet filler the buffer to check if we 
                        //are at the end of the packet
                        if (from_client_tlast) begin
                            //Reached end of the packet so stop receiving
                            from_client_tready <= 0;
                            buf_idx <= 0;
                            cur_state <= 4;
                        end
                        else begin
                            //Have not yet reached the end of the packet nor end of 
                            //buffer so keep receiving
                            buf_idx <= buf_idx + 8;
                        end
                    end
                end
            end
            2: begin    //UNKNOWN COMMAND RESPONSE
                //Respond with unknown command
                to_client_primary_tdata <= 1;
                to_client_primary_tvalid <= 1;
                to_client_primary_tlast <= 1;
                cur_state <= 3;
            end
            3: begin    //UNKNOWN COMMAND RESPONSE
                //Make sure command sent
                if (to_client_primary_tready) begin
                    to_client_primary_tdata <= 0;
                    to_client_primary_tvalid <= 0;
                    to_client_primary_tlast <= 0;
                    cur_state <= 0;
                end
            end
            4: begin    //INTERPRET RECEIVED PACKET
                //Received a packet so interpret it
                case (buffer[7:0])
                    3: begin    //WRITE SINGLE REGISTER
                        case (buffer[31:24])
                            0: begin
                                reg0 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            1: begin
                                reg1 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            2: begin
                                reg2 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            3: begin
                                reg3 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            4: begin
                                reg4 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            5: begin
                                reg5 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            6: begin
                                reg6 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            7: begin
                                reg7 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            8: begin
                                reg8 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            9: begin
                                reg9 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            10: begin
                                reg10 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            11: begin
                                reg11 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            12: begin
                                reg12 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            13: begin
                                reg13 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            14: begin
                                reg14 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            15: begin
                                reg15 <= buffer[63:32];
                                client_updated <= 1;
                                cur_state <= 5;
                            end
                            default: begin
                                cur_state <= 2;
                            end
                        endcase
                    end
                    4: begin    //WRITE ALL REGISTERS
                        reg0 <= buffer[24 +: 32];
                        reg1 <= buffer[56 +: 32];
                        reg2 <= buffer[88 +: 32];
                        reg3 <= buffer[120 +: 32];
                        reg4 <= buffer[152 +: 32];
                        reg5 <= buffer[184 +: 32];
                        reg6 <= buffer[216 +: 32];
                        reg7 <= buffer[248 +: 32];
                        reg8 <= buffer[280 +: 32];
                        reg9 <= buffer[312 +: 32];
                        reg10 <= buffer[344 +: 32];
                        reg11 <= buffer[376 +: 32];
                        reg12 <= buffer[408 +: 32];
                        reg13 <= buffer[440 +: 32];
                        reg14 <= buffer[472 +: 32];
                        reg15 <= buffer[504 +: 32];
                        client_updated <= 1;
                        cur_state <= 5;
                    end
                    5: begin    //READ SINGLE REGISTER
                        //TODO
                    end
                    7: begin    //READ ALL REGISTERS
                        //TODO
                    end
                    9: begin    //TRIGGER COMMAND
                        trigger <= 1;
                        cur_state <= 5;
                    end
                    default: begin  //UNKNOWN COMMAND
                        cur_state <= 2;
                    end
                endcase
            end
            5: begin    //ACK write / trigger command response
                trigger <= 0;
                to_client_primary_tvalid <= 1;
                to_client_primary_tdata <= 2;
                to_client_primary_tlast <= 0;
                cur_state <= 6;
            end
            6: begin
                if (to_client_primary_tready) begin
                    to_client_primary_tdata <= buffer[15:8];
                    cur_state <= 7;
                end
            end
            7: begin
                if (to_client_primary_tready) begin
                    to_client_primary_tdata <= buffer[23:16];
                    to_client_primary_tlast <= 1;
                    cur_state <= 8;
                end
            end
            8: begin
                if (to_client_primary_tready) begin
                    to_client_primary_tvalid <= 0;
                    to_client_primary_tdata <= 0;
                    to_client_primary_tlast <= 0;
                    if (client_updated) begin
                        cur_state <= 9;
                    end
                    else begin
                        cur_state <= 10;
                    end
                end
            end
            9: begin    //ACKNOWLEDGE UPDATE
                if (update_ackd) begin
                    client_updated <= 0;
                    cur_state <= 0;
                end
            end
        endcase
    end
end

endmodule
