`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/12 23:04:11
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

//cache32行，分为16组，每组2块，2路组相联，1块4字，1字4字节，即数据128-bit
//主存地址12位，6-bit Tag，4-bit 组号，2-bit 块内地址
//cache每行136-bit：1-bitV + 1-bitD + 6-bitTag + 128-bitData
//LRU替换，回写法，写分配，2路组相联
//测试数据tb给出
module BRAM(
clk,rst,cpu_v,cpu_RorW,cpu_addr,cpu_wdata,cpu_ready,cpu_rdata,state,count,hit,hit1,hit2,way );
    input clk,rst,cpu_v,cpu_RorW;//cpu输入是否有效；cpu要读还是写
    input [11:0]cpu_addr;//cpu给的地址
    input [31:0]cpu_wdata;//cpu要写的地址
    wire [127:0]ram_rdata;//ram读出的主存块数据
    output reg cpu_ready;//cpu读/写是否完成
    output reg [31:0]cpu_rdata;//cpu读出的数据
    reg [11:0]ram_addr;//给ram的地址
    reg [127:0]ram_wdata;//要写入ram的数据
    parameter schv=0,cmprtag=1,cinram=2,rerw=3;
    parameter V=135,D=134,TM=133,TL=128,DM=127,DL=0;
    output reg[1:0]state;
    reg[135:0]cache[31:0];
    reg [1:0]nextstate;
    reg ram_RorW,ram_v,ram_ready;//cache对ram读还是写；cache和ram之间数据方向；ram写还是读
    output reg hit,hit1,hit2,way;//命中标志；0路；1路；要选择写入哪一路
    output reg[11:0]count;//最近使用频率队列，00->0路，01->1路，11->无使用
    reg          ena;        //RAM PORT  A 写使能，高电平有效
    reg          enb;        //RAM PORT  B 读使能，高电平有效
    integer i,count0,count1;//0路使用次数,1路使用次数
    initial               //初始化
    begin
     count0=0;
     count1=0;
     count=12'b111111111111;
     state=schv;
     nextstate=schv;
     hit=1'b0;
     hit1=1'b0;
     hit2=1'b0;
     way=1'b0;
     for(i=0;i<32;i=i+1)
     begin
      cache[i]=136'b0;
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
      else if(ram_v==1'b0&&ram_RorW==1'b0)
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
               if(cache[2*cpu_addr[5:2]][V]==1'b1&&cache[2*cpu_addr[5:2]][TM:TL]==cpu_addr[11:6])
               begin
                hit1=1'b1;
               end
               else
               begin
                hit1=1'b0;
               end
               //判断是否命中1路
               if(cache[2*cpu_addr[5:2]+1][V]==1'b1&&cache[2*cpu_addr[5:2]+1][TM:TL]==cpu_addr[11:6])
               begin
                hit2=1'b1;
               end
               else
               begin
                hit2=1'b0;
               end
               //判断是否命中
               hit=hit1||hit2;
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
                  if(count0+count1>5)//总次数为5
                  begin
                   //超过队列长度，删除头元素
                   if(count[11:10]==2'b01)
                   begin
                    count1=count1-1;
                   end
                   else
                   begin
                    count0=count0-1;
                   end
                  end
                  count={count[9:0],2'b00};
                  //LRU结束
                  cpu_rdata=cache[2*cpu_addr[5:2]][32*cpu_addr[1:0] +:32];//将0路数据读出
                 end
                 else//命中1路
                 begin
                  //LRU开始
                  count1=count1+1;
                  if(count0+count1>5)//超过队列长度，删除头元素
                  begin
                   if(count[11:10]==2'b01)
                   begin
                    count1=count1-1;
                   end
                   else
                   begin
                    count0=count0-1;
                   end
                  end
                  count={count[9:0],2'b01};
                  //LRU结束
                  cpu_rdata=cache[2*cpu_addr[5:2]+1][32*cpu_addr[1:0] +:32];//读1路数据
                 end
                end
                if(cpu_RorW==1'b1)                        //若cpu写命中，直接写，不更新主存
                begin
                 cpu_ready<=1'b1;
                 if(hit1) //命中0路
                 begin
                  //LRU开始
                  count0=count0+1;
                  if(count0+count1>5)
                  begin
                   if(count[11:10]==2'b01)
                   begin
                    count1=count1-1;
                   end
                   else
                   begin
                   count0=count0-1;
                   end 
                  end
                  count={count[9:0],2'b00};
                  //LRU结束
                  cache[2*cpu_addr[5:2]][32*cpu_addr[1:0]+:32]=cpu_wdata;
                  cache[2*cpu_addr[5:2]][D]=1'b1;
                 end
                 else //命中1路
                 begin
                  //LRU开始
                  count1=count1+1;
                  if(count0+count1>5)
                  begin
                   if(count[11:10]==2'b01)
                   begin
                    count1=count1-1;
                   end
                   else
                   begin
                    count0=count0-1;
                   end
                  end
                  count={count[9:0],2'b01};
                  //LRU结束
                  cache[2*cpu_addr[5:2]+1][32*cpu_addr[1:0] +:32]=cpu_wdata;
                  cache[2*cpu_addr[5:2]+1][D]=1'b1;
                 end
                end
               end
               else if(hit==1'b0)///若cpu没命中
               begin
                cpu_ready<=1'b0;//cpu->cache没命中
                case({cache[2*cpu_addr[5:2]][V],cache[2*cpu_addr[5:2]+1][V]})//判断要替换哪一路
                 2'b01:way=1'b0; 
                 2'b10:way=1'b1;
                 2'b00:way=(count0<=count1)?1'b0:1'b1;
                 2'b11:way=(count0<=count1)?1'b0:1'b1; 
                 default:way=(count0<=count1)?1'b0:1'b1;
                endcase
                if(cpu_RorW==1'b1)                       //cpu写不命中，先调主存入cache，再更新cache，写分配法
                begin
                 if(cache[2*cpu_addr[5:2]+way][D]==1'b1)//要替换掉的cache行脏了，先将该行调入主存
                 begin
                  ram_wdata=cache[2*cpu_addr[5:2]+way][DM:DL];
                  ram_addr={cache[2*cpu_addr[5:2]+way][TM:TL],cpu_addr[5:2],2'b00};//后两位无所谓
                  ram_RorW=1'b1;
                  ram_v=1'b1;//cache->ram
                 end
                 nextstate=cinram;
                end
                if(cpu_RorW==1'b0)//cpu读不命中 ，将对应主存块调入cache再读
                begin
                 if(cache[2*cpu_addr[5:2]+way][D]==1'b1)//要替换掉的cache行脏了，先将该行调入主存
                 begin
                  ram_wdata=cache[2*cpu_addr[5:2]+way][DM:DL];
                  ram_addr={cache[2*cpu_addr[5:2]+way][TM:TL],cpu_addr[5:2],2'b00};//后两位无所谓
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
               ram_v=1'b0;//ram->cache
               ram_addr=cpu_addr;
               ram_wdata=128'b0;//清零，不写
               cpu_ready=1'b1;
               cache[2*cpu_addr[5:2]+way]={2'b10,cpu_addr[11:6],ram_rdata};//调内存，脏位置0，有效位置1，没有设主存和cache都找不到的情况
               //LRU开始
               if(way)//1路
               begin
                count1=1;
                count={count[9:0],2'b01};
               end
               else//0路
               begin
                count0=1;
                count={count[9:0],2'b00};
               end
               //LRU结束
              end
             end   
      rerw:begin
            nextstate=schv;
            if(cpu_RorW==1'b0&&ram_ready==1'b0)//读ram且原本要读
            begin
             cpu_rdata=cache[2*cpu_addr[5:2]][32*cpu_addr[1:0]+:32];
            end
            else if(cpu_RorW==1'b1&&ram_ready==1'b0)//调主存成功且原本要写
            begin
             cache[2*cpu_addr[5:2]+way][32*cpu_addr[1:0]+:32]=cpu_wdata;
             cache[2*cpu_addr[5:2]+way][D]=1'b1;
            end
           end      
      endcase
     end
    end
    blk_mem_gen_1 ram_ip_test ( 
    .clka      (clk          ),            // input clka 
    .ena       (ena          ),            // input ena
    .addra     (ram_addr       ),            // input [11 : 0] addra 
    .dina      (ram_wdata       ),            // input [127 : 0] dina 
    .clkb     (clk          ),            // input clkb 
    .enb      (enb     )   ,
    .addrb    (ram_addr       ),            // input [11 : 0] addrb 
    .doutb    (ram_rdata       )             // output [127 : 0] doutb 
    ); 

 endmodule


    


    
