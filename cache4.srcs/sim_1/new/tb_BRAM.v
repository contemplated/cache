`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/13 13:32:47
// Design Name: 
// Module Name: tb_BRAM
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


module tb_BRAM(

    );
    reg clk,rst,cpu_v,cpu_RorW;
    reg [11:0]cpu_addr;
    reg [31:0]cpu_wdata;
    wire [1:0]state;
    wire [26:0]count;
    wire hit,hit1,hit2,hit3,hit4;
    wire [1:0]way;
    wire cpu_ready;
    wire [31:0]cpu_rdata;
    initial
    begin
    clk=0;
    rst=0;
    cpu_v=1'b1;
    cpu_RorW=1'b0;//读主存块17，低32位，cache不命中，调主存再读，3，无脏位
    cpu_addr=12'b0000010001_00;
    cpu_wdata=32'hf;
    #1
    rst=1;
    #99
    cpu_RorW=1'b1;//写主存块17 次32位，cache命中 1 变脏
    cpu_addr=12'b0000010001_00;
    cpu_wdata=32'hf;
    #100
    cpu_RorW=1'b0;//读主存块17 次32位 cache命中 1
    cpu_addr=12'b0000010001_00;
    cpu_wdata=32'hf;
    #100
    cpu_RorW=1'b1;//写主存块33 次32位 cache不命中，调主存再写 3，无脏位 变脏
    cpu_addr=12'b0000100001_01;
    cpu_wdata=32'he;
    #100
    cpu_RorW=1'b1;//写主存块1 次32位 cache不命中 3，脏位
    cpu_addr=12'b0000000001_01;
    cpu_wdata=32'hc;
    #100
    cpu_RorW=1'b0;//读主存块33 次32位 cache不命中 3，脏位
    cpu_addr=12'b0000100001_01;
    cpu_wdata=32'hc;
    end
    always#5
    clk=~clk;
    
    BRAM u_BRAM(
clk,rst,cpu_v,cpu_RorW,cpu_addr,cpu_wdata,cpu_ready,cpu_rdata,state,count,hit,hit1,hit2,hit3,hit4,way );
endmodule
