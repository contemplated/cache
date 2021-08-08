`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/13 11:16:21
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


//cache32行，分为8组，每组4块，4路组相联，1块4字，1字4字节，即数据128-bit，主存共1024块
//主存地址12位，7-bit Tag，3-bit 组号，2-bit 块内地址
//cache每行137-bit：1-bitV + 1-bitD + 7-bitTag + 128-bitData
//LRU替换，回写法，写分配，4路组相联
//测试数据tb给出
module BRAM(
clk,rst,cpu_v,cpu_RorW,cpu_addr,cpu_wdata,cpu_ready,cpu_rdata,state,count,hit,hit1,hit2,hit3,hit4,way );
    input clk,rst,cpu_v,cpu_RorW;//cpu输入是否有效；cpu要读还是写
    input [11:0]cpu_addr;//cpu给的地址
    input [31:0]cpu_wdata;//cpu要写的地址
    wire [127:0]ram_rdata;//ram读出的主存块数据
    output reg cpu_ready;//cpu读/写是否完成
    output reg [31:0]cpu_rdata;//cpu读出的数据
    reg [11:0]ram_addr;//给ram的地址
    reg [127:0]ram_wdata;//要写入ram的数据
    parameter schv=0,cmprtag=1,cinram=2,rerw=3;
    parameter V=136,D=135,TM=134,TL=128,DM=127,DL=0,MAX=10;
    output reg[1:0]state;
    reg[136:0]cache[31:0];
    reg [1:0]nextstate;
    reg ram_RorW,ram_v,ram_ready;//cache对ram读还是写；cache和ram之间数据方向；ram写还是读
    output reg hit,hit1,hit2,hit3,hit4;//命中标志；0路；1路；2路；3路
    output reg [1:0]way;//要选择写入哪一路
    output reg[26:0]count;//最近使用频率队列，000->0路，001->1路，010->2路，011->3路，111->无使用，总次数8次，队列应排9次，一次为删除次
    reg          ena;        //RAM PORT  A 写使能，高电平有效
    reg          enb;        //RAM PORT  B 读使能，高电平有效
    integer i,count0,count1,count2,count3;//0路使用次数,1路使用次数,依此类推
    function [1:0]max;//得出哪一路最不常使用
    input [3:0]count0,count1,count2,count3;
    begin
     if(count0<=count1&&count0<=count2&&count0<=count3)
        max=2'b00;
     else if(count1<=count0&&count1<=count2&&count1<=count3)
        max=2'b01;
     else if(count2<=count0&&count2<=count1&&count2<=count3)
        max=2'b10;
     else 
        max=2'b11;
    end
    endfunction

    initial               //初始化
    begin
     count0=0;
     count1=0;
     count2=0;
     count3=0;
     count=27'b11_11111_11111_11111_11111_11111;
     state=schv;
     nextstate=schv;
     hit=1'b0;
     hit1=1'b0;
     hit2=1'b0;
     hit3=1'b0;
     hit4=1'b0;
     way=1'b0;
     for(i=0;i<32;i=i+1)
     begin
      cache[i]=137'b0;
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
               //判断是否命中0路
               if(cache[4*cpu_addr[4:2]][V]==1'b1&&cache[4*cpu_addr[4:2]][TM:TL]==cpu_addr[11:5])
               begin
                hit1=1'b1;
               end
               else
               begin
                hit1=1'b0;
               end
               //判断是否命中1路
               if(cache[4*cpu_addr[4:2]+1][V]==1'b1&&cache[4*cpu_addr[4:2]+1][TM:TL]==cpu_addr[11:5])
               begin
                hit2=1'b1;
               end
               else
               begin
                hit2=1'b0;
               end
               //判断是否命中2路
               if(cache[4*cpu_addr[4:2]+2][V]==1'b1&&cache[4*cpu_addr[4:2]+2][TM:TL]==cpu_addr[11:5])
               begin
                hit3=1'b1;
               end
               else
               begin
                hit3=1'b0;
               end
               //判断是否命中3路
               if(cache[4*cpu_addr[4:2]+3][V]==1'b1&&cache[4*cpu_addr[4:2]+3][TM:TL]==cpu_addr[11:5])
               begin
                hit4=1'b1;
               end
               else
               begin
                hit4=1'b0;
               end
               //判断是否命中
               hit=hit1|hit2|hit3|hit4;
               //命中
               if(hit)
               begin
                nextstate=schv;//命中后操作完下个状态判断下一条指令
                if(cpu_RorW==1'b0)                        //若cpu读命中，直接读出去
                begin
                 cpu_ready<=1'b1;//cpu->cache命中
                 if(hit1)//命中0路
                 begin
                  //LRU开始
                  count0=count0+1;
                  if(count0+count1+count2+count3>8)//总次数为8
                  begin
                   //超过队列长度，删除头元素
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b000};
                  //LRU结束
                  cpu_rdata=cache[4*cpu_addr[4:2]][32*cpu_addr[1:0] +:32];//将0路数据读出
                 end
                 else if(hit2)//命中1路
                 begin
                  //LRU开始
                  count1=count1+1;
                  if(count0+count1+count2+count3>8)//总次数为8
                  begin
                   //超过队列长度，删除头元素
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b001};
                  //LRU结束
                  cpu_rdata=cache[4*cpu_addr[4:2]+1][32*cpu_addr[1:0] +:32];//读1路数据
                 end
                 else if(hit3)//命中2路
                 begin
                  //LRU开始
                  count2=count2+1;
                  if(count0+count1+count2+count3>8)//总次数为8
                  begin
                   //超过队列长度，删除头元素
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b010};
                  //LRU结束
                  cpu_rdata=cache[4*cpu_addr[4:2]+2][32*cpu_addr[1:0] +:32];//读2路数据
                 end
                 else if(hit4)//命中3路
                 begin
                  //LRU开始
                  count3=count3+1;
                  if(count0+count1+count2+count3>8)//总次数为8
                  begin
                   //超过队列长度，删除头元素
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b011};
                  //LRU结束
                  cpu_rdata=cache[4*cpu_addr[4:2]+3][32*cpu_addr[1:0] +:32];//读3路数据
                 end
                end
                if(cpu_RorW==1'b1)                        //若cpu写命中，直接写，不更新主存
                begin
                 cpu_ready<=1'b1;
                 if(hit1) //命中0路
                 begin
                  //LRU开始
                  count0=count0+1;
                  if(count0+count1+count2+count3>8)//总次数为8
                  begin
                   //超过队列长度，删除头元素
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b000};
                  //LRU结束
                  cache[4*cpu_addr[4:2]][32*cpu_addr[1:0]+:32]=cpu_wdata;
                  cache[4*cpu_addr[4:2]][D]=1'b1;
                 end
                 else if(hit2)//命中1路
                 begin
                  //LRU开始
                  count1=count1+1;
                  if(count0+count1+count2+count3>8)//总次数为8
                  begin
                   //超过队列长度，删除头元素
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b001};
                  //LRU结束
                  cache[4*cpu_addr[4:2]+1][32*cpu_addr[1:0] +:32]=cpu_wdata;
                  cache[4*cpu_addr[4:2]+1][D]=1'b1;
                 end
                 else if(hit3)//命中2路
                 begin
                  //LRU开始
                  count2=count2+1;
                  if(count0+count1+count2+count3>8)//总次数为8
                  begin
                   //超过队列长度，删除头元素
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b010};
                  //LRU结束
                  cache[4*cpu_addr[4:2]+2][32*cpu_addr[1:0] +:32]=cpu_wdata;
                  cache[4*cpu_addr[4:2]+2][D]=1'b1;
                 end
                 else if(hit4)//命中3路
                 begin
                  //LRU开始
                  count3=count3+1;
                  if(count0+count1+count2+count3>8)//总次数为8
                  begin
                   //超过队列长度，删除头元素
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b011};
                  //LRU结束
                  cache[4*cpu_addr[4:2]+3][32*cpu_addr[1:0]+:32]=cpu_wdata;
                  cache[4*cpu_addr[4:2]+3][D]=1'b1;
                 end
                end
               end
               else if(hit==1'b0)///若cpu没命中
               begin
                cpu_ready<=1'b0;//cpu->cache没命中
                case({cache[4*cpu_addr[4:2]][V],cache[4*cpu_addr[4:2]+1][V],cache[4*cpu_addr[4:2]+2][V],cache[4*cpu_addr[4:2]+3][V]})//判断要替换哪一路
                 4'h0:way=max(count0,count1,count2,count3); 
                 4'h1:way=max(count0,count1,count2,MAX); 
                 4'h2:way=max(count0,count1,MAX,count3); 
                 4'h3:way=max(count0,count1,MAX,MAX); 
                 4'h4:way=max(count0,MAX,count2,count3); 
                 4'h5:way=max(count0,MAX,count2,MAX);  
                 4'h6:way=max(count0,MAX,MAX,count3);  
                 4'h7:way=2'b00; 
                 4'h8:way=max(MAX,count1,count2,count3);
                 4'h9:way=max(MAX,count1,count2,MAX);
                 4'hA:way=max(MAX,count1,MAX,count3); 
                 4'hB:way=2'b01;
                 4'hC:way=max(MAX,MAX,count2,count3); 
                 4'hD:way=2'b10;
                 4'hE:way=2'b11;
                 4'hF:way=max(count0,count1,count2,count3);
                endcase
                if(cpu_RorW==1'b1)                       //cpu写不命中，先调主存入cache，再更新cache，写分配法
                begin
                 if(cache[4*cpu_addr[4:2]+way][D]==1'b1)//要替换掉的cache行脏了，先将该行调入主存
                 begin
                  ram_wdata=cache[4*cpu_addr[4:2]+way][DM:DL];
                  ram_addr={cache[4*cpu_addr[4:2]+way][TM:TL],cpu_addr[4:2],2'b00};//后两位无所谓
                  ram_RorW=1'b1;
                  ram_v=1'b1;//cache->ram
                 end
                 nextstate=cinram;
                end
                if(cpu_RorW==1'b0)//cpu读不命中 ，将对应主存块调入cache再读
                begin
                 if(cache[4*cpu_addr[4:2]+way][D]==1'b1)//要替换掉的cache行脏了，先将该行调入主存
                 begin
                  ram_wdata=cache[4*cpu_addr[4:2]+way][DM:DL];
                  ram_addr={cache[4*cpu_addr[4:2]+way][TM:TL],cpu_addr[4:2],2'b00};//后两位无所谓
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
               cache[4*cpu_addr[4:2]+way]={2'b10,cpu_addr[11:5],ram_rdata};//调内存，脏位置0，有效位置1，没有设主存和cache都找不到的情况
               //LRU开始
               case(way)
                2'b00:begin
                count0=1;count={count[26:3],3'b000};
                end
                2'b01:
                begin
                count1=1;count={count[26:3],3'b001};
                end
                2'b10:begin
                count2=1;count={count[26:3],3'b010};
                end
                2'b11:begin
                count3=1;count={count[26:3],3'b011};
                end
               endcase
               //LRU结束
              end
             end   
      rerw:begin
            nextstate=schv;
            if(cpu_RorW==1'b0&&ram_ready==1'b0)//读ram且原本要读
            begin
             cpu_rdata=cache[4*cpu_addr[4:2]][32*cpu_addr[1:0]+:32];
            end
            else if(cpu_RorW==1'b1&&ram_ready==1'b0)//读ram且原本要写
            begin
             cache[4*cpu_addr[4:2]+way][32*cpu_addr[1:0]+:32]=cpu_wdata;
             cache[4*cpu_addr[4:2]+way][D]=1'b1;
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

