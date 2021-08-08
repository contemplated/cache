`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/13 20:58:26
// Design Name: 
// Module Name: b_BRAM
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


module b_BRAM(

    );
reg clk,rst,cpu_v,cpu_RorW;
    reg [11:0]cpu_addr;
    reg [31:0]cpu_wdata;
    wire [1:0]state;
    wire hit;
    wire cpu_ready;
    wire [31:0]cpu_rdata;
    initial
    begin
    clk=0;
    rst=0;
    cpu_v=1'b1;
    cpu_RorW=1'b0;//�������49����32λ��cache�����У��������ٶ���3������λ
    cpu_addr=12'b00001_10001_00;
    cpu_wdata=32'hf;
    #1
    rst=1;
    #99
    cpu_RorW=1'b1;//д�����49 ��32λ��cache���� 1 ����
    cpu_addr=12'b00001_10001_01;
    cpu_wdata=32'hf;
    #100
    cpu_RorW=1'b0;//�������49 ��32λ cache���� 1
    cpu_addr=12'b00001_10001_01;
    cpu_wdata=32'hf;
    #100
    cpu_RorW=1'b1;//д�����113 ��32λ cache�����У���������д 3����λ
    cpu_addr=12'b00011_10001_01;
    cpu_wdata=32'he;
    #100
    cpu_RorW=1'b1;//д�����33 ��32λ cache������ 3������λ������
    cpu_addr=12'b00001_00001_01;
    cpu_wdata=32'hc;
    #100
    cpu_RorW=1'b0;//�������33 ��32λ cache������ 3����λ
    cpu_addr=12'b00000_00001_01;
    cpu_wdata=32'hc;
    end
    always#5
    clk=~clk;
    
    BRAM u_BRAM(
clk,rst,cpu_v,cpu_RorW,cpu_addr,cpu_wdata,cpu_ready,cpu_rdata,state,hit);
endmodule
