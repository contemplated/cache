`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/13 20:12:59
// Design Name: 
// Module Name: BRAM
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

//cache32行，1块4字，1字4字节，即数据128-bit，主存1024块
//主存地址12位，5-bit Tag，5-bit 行号，2-bit 块内地址
//cache每行135-bit：1-bitV + 1-bitD + 5-bitTag + 128-bitData
//回写法，写分配，直接映射
//测试数据tb给出
module BRAM(
clk,rst,cpu_v,cpu_RorW,cpu_addr,cpu_wdata,cpu_ready,cpu_rdata,state,hit );
    input clk,rst,cpu_v,cpu_RorW;//cpu输入是否有效；cpu要读还是写
    input [11:0]cpu_addr;//cpu给的地址
    input [31:0]cpu_wdata;//cpu要写的地址
    wire [127:0]ram_rdata;//ram读出的主存块数据
    output reg cpu_ready;//cpu读/写是否完成
    output reg [31:0]cpu_rdata;//cpu读出的数据
    reg [11:0]ram_addr;//给ram的地址
    reg [127:0]ram_wdata;//要写入ram的数据
    parameter schv=0,cmprtag=1,cinram=2,rerw=3;
    parameter V=134,D=133,TM=132,TL=128,DM=127,DL=0;
    output reg[1:0]state;
    reg[134:0]cache[31:0];
    reg [1:0]nextstate;
    reg ram_RorW,ram_v,ram_ready;//cache对ram读还是写；cache和ram之间数据方向；ram写还是读
    output reg hit;//命中标志；
    reg          ena;        //RAM PORT  A 写使能，高电平有效
    reg          enb;        //RAM PORT  B 读使能，高电平有效
    integer i;
    initial               //初始化
    begin
     state=schv;
     nextstate=schv;
     hit=1'b0;
     for(i=0;i<32;i=i+1)
     begin
      cache[i]=135'b0;
     end
    end
    always@(posedge clk or negedge rst)
    begin
     if(!rst)
     begin
      ram_RorW=1'b0;
      ram_v=1'b0;
      cpu_ready=1'b0;
      cpu_rdata=32'b0;
      ram_addr=12'b0;
      ram_wdata=128'b0;
      state=schv;
      ena=1'b0;
      enb=1'b0;
     end
     else
     begin
      state=nextstate;
      if(ram_v==1'b1&&ram_RorW==1'b1&&ram_ready==1'b0) 
      begin
       ena=1'b1;
       ram_ready=1'b1;//向ram写数据
      end
      else if(ram_v==1'b1&&ram_RorW==1'b0)
      begin
       enb=1'b1;
       ram_ready=1'b0;
      end
      case(state)
      schv:begin//状态0，判断cpu输入数据是否有效
            if(cpu_v)
            begin
             nextstate=cmprtag;
            end
           end
      cmprtag:begin//状态1，命中后的读写，不命中的下一步判断及cache行替换
               //判断是否命中
               if(cache[cpu_addr[6:2]][V]==1'b1&&cache[cpu_addr[6:2]][TM:TL]==cpu_addr[11:7])
               begin
                hit=1'b1;
               end
               else
               begin
                hit=1'b0;
               end
               //命中
               if(hit)
               begin
                nextstate=schv;//命中后操作完下个状态判断下一条指令
                if(cpu_RorW==1'b0)                        //若cpu读命中，直接读出去
                begin
                 cpu_ready<=1'b1;//cpu->cache命中
                 cpu_rdata=cache[cpu_addr[6:2]][32*cpu_addr[1:0] +:32];//将数据读出
                end
                if(cpu_RorW==1'b1)                        //若cpu写命中，直接写，不更新主存
                begin
                 cpu_ready<=1'b1;
                 cache[cpu_addr[6:2]][32*cpu_addr[1:0]+:32]=cpu_wdata;
                 cache[cpu_addr[6:2]][D]=1'b1;
                end
               end
               else///若cpu没命中
               begin
                cpu_ready<=1'b0;//cpu->cache没命中
                if(cpu_RorW==1'b1)                       //cpu写不命中，先调主存入cache，再更新cache，写分配法
                begin
                 if(cache[cpu_addr[6:2]][D]==1'b1)//要替换掉的cache行脏了，先将该行调入主存
                 begin
                  ram_wdata=cache[cpu_addr[6:2]][DM:DL];
                  ram_addr={cache[cpu_addr[6:2]][TM:TL],cpu_addr[6:2],2'b00};//后两位无所谓
                  ram_RorW=1'b1;
                  ram_v=1'b1;//cache->ram
                 end
                 nextstate=cinram;
                end
                if(cpu_RorW==1'b0)//cpu读不命中 ，将对应主存块调入cache再读
                begin
                 if(cache[cpu_addr[6:2]][D]==1'b1)//要替换掉的cache行脏了，先将该行调入主存
                 begin
                  ram_wdata=cache[cpu_addr[6:2]][DM:DL];
                  ram_addr={cache[cpu_addr[6:2]][TM:TL],cpu_addr[6:2],2'b00};//后两位无所谓
                  ram_RorW=1'b1;//cache换ram
                  ram_v=1'b1;//cache->ram
                 end
                 nextstate=cinram;
                end
               end
              end
      cinram:begin//调主存再进行读/写操作
              nextstate=rerw;
              begin
               ram_RorW=1'b0;//ram换cache
               ram_addr=cpu_addr;
               ram_wdata=128'b0;//清零，不写
               cpu_ready=1'b1;
               cache[cpu_addr[6:2]]={2'b10,cpu_addr[11:7],ram_rdata};//调内存，脏位置0，有效位置1，没有设主存和cache都找不到的情况
              end
             end   
      rerw:begin
            nextstate=schv;
            if(cpu_RorW==1'b0&&ram_ready==1'b0)//读ram且原本要读
            begin
             cpu_rdata=cache[cpu_addr[6:2]][32*cpu_addr[1:0]+:32];
            end
            else if(cpu_RorW==1'b1&&ram_ready==1'b0)//调主存成功且原本要写
            begin
             cache[cpu_addr[6:2]][32*cpu_addr[1:0]+:32]=cpu_wdata;
             cache[cpu_addr[6:2]][D]=1'b1;
            end
           end      
      endcase
     end
    end
    blk_mem_gen_0 ram_ip_test ( 
    .clka      (clk          ),            // input clka 
    .ena       (ena          ),            // input ena
    .addra     (ram_addr[11:2]       ),            // input [11 : 2] addra 
    .dina      (ram_wdata       ),            // input [127 : 0] dina 
    .clkb     (clk          ),            // input clkb 
    .enb      (enb     )   ,
    .addrb    (ram_addr[11:2]       ),            // input [11 : 2] addrb 
    .doutb    (ram_rdata       )             // output [127 : 0] doutb 
    ); 

 endmodule


    


    



    


    

