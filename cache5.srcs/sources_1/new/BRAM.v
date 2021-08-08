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

//cache32�У�1��4�֣�1��4�ֽڣ�������128-bit������1024��
//�����ַ12λ��5-bit Tag��5-bit �кţ�2-bit ���ڵ�ַ
//cacheÿ��135-bit��1-bitV + 1-bitD + 5-bitTag + 128-bitData
//��д����д���䣬ֱ��ӳ��
//��������tb����
module BRAM(
clk,rst,cpu_v,cpu_RorW,cpu_addr,cpu_wdata,cpu_ready,cpu_rdata,state,hit );
    input clk,rst,cpu_v,cpu_RorW;//cpu�����Ƿ���Ч��cpuҪ������д
    input [11:0]cpu_addr;//cpu���ĵ�ַ
    input [31:0]cpu_wdata;//cpuҪд�ĵ�ַ
    wire [127:0]ram_rdata;//ram���������������
    output reg cpu_ready;//cpu��/д�Ƿ����
    output reg [31:0]cpu_rdata;//cpu����������
    reg [11:0]ram_addr;//��ram�ĵ�ַ
    reg [127:0]ram_wdata;//Ҫд��ram������
    parameter schv=0,cmprtag=1,cinram=2,rerw=3;
    parameter V=134,D=133,TM=132,TL=128,DM=127,DL=0;
    output reg[1:0]state;
    reg[134:0]cache[31:0];
    reg [1:0]nextstate;
    reg ram_RorW,ram_v,ram_ready;//cache��ram������д��cache��ram֮�����ݷ���ramд���Ƕ�
    output reg hit;//���б�־��
    reg          ena;        //RAM PORT  A дʹ�ܣ��ߵ�ƽ��Ч
    reg          enb;        //RAM PORT  B ��ʹ�ܣ��ߵ�ƽ��Ч
    integer i;
    initial               //��ʼ��
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
       ram_ready=1'b1;//��ramд����
      end
      else if(ram_v==1'b1&&ram_RorW==1'b0)
      begin
       enb=1'b1;
       ram_ready=1'b0;
      end
      case(state)
      schv:begin//״̬0���ж�cpu���������Ƿ���Ч
            if(cpu_v)
            begin
             nextstate=cmprtag;
            end
           end
      cmprtag:begin//״̬1�����к�Ķ�д�������е���һ���жϼ�cache���滻
               //�ж��Ƿ�����
               if(cache[cpu_addr[6:2]][V]==1'b1&&cache[cpu_addr[6:2]][TM:TL]==cpu_addr[11:7])
               begin
                hit=1'b1;
               end
               else
               begin
                hit=1'b0;
               end
               //����
               if(hit)
               begin
                nextstate=schv;//���к�������¸�״̬�ж���һ��ָ��
                if(cpu_RorW==1'b0)                        //��cpu�����У�ֱ�Ӷ���ȥ
                begin
                 cpu_ready<=1'b1;//cpu->cache����
                 cpu_rdata=cache[cpu_addr[6:2]][32*cpu_addr[1:0] +:32];//�����ݶ���
                end
                if(cpu_RorW==1'b1)                        //��cpuд���У�ֱ��д������������
                begin
                 cpu_ready<=1'b1;
                 cache[cpu_addr[6:2]][32*cpu_addr[1:0]+:32]=cpu_wdata;
                 cache[cpu_addr[6:2]][D]=1'b1;
                end
               end
               else///��cpuû����
               begin
                cpu_ready<=1'b0;//cpu->cacheû����
                if(cpu_RorW==1'b1)                       //cpuд�����У��ȵ�������cache���ٸ���cache��д���䷨
                begin
                 if(cache[cpu_addr[6:2]][D]==1'b1)//Ҫ�滻����cache�����ˣ��Ƚ����е�������
                 begin
                  ram_wdata=cache[cpu_addr[6:2]][DM:DL];
                  ram_addr={cache[cpu_addr[6:2]][TM:TL],cpu_addr[6:2],2'b00};//����λ����ν
                  ram_RorW=1'b1;
                  ram_v=1'b1;//cache->ram
                 end
                 nextstate=cinram;
                end
                if(cpu_RorW==1'b0)//cpu�������� ������Ӧ��������cache�ٶ�
                begin
                 if(cache[cpu_addr[6:2]][D]==1'b1)//Ҫ�滻����cache�����ˣ��Ƚ����е�������
                 begin
                  ram_wdata=cache[cpu_addr[6:2]][DM:DL];
                  ram_addr={cache[cpu_addr[6:2]][TM:TL],cpu_addr[6:2],2'b00};//����λ����ν
                  ram_RorW=1'b1;//cache��ram
                  ram_v=1'b1;//cache->ram
                 end
                 nextstate=cinram;
                end
               end
              end
      cinram:begin//�������ٽ��ж�/д����
              nextstate=rerw;
              begin
               ram_RorW=1'b0;//ram��cache
               ram_addr=cpu_addr;
               ram_wdata=128'b0;//���㣬��д
               cpu_ready=1'b1;
               cache[cpu_addr[6:2]]={2'b10,cpu_addr[11:7],ram_rdata};//���ڴ棬��λ��0����Чλ��1��û���������cache���Ҳ��������
              end
             end   
      rerw:begin
            nextstate=schv;
            if(cpu_RorW==1'b0&&ram_ready==1'b0)//��ram��ԭ��Ҫ��
            begin
             cpu_rdata=cache[cpu_addr[6:2]][32*cpu_addr[1:0]+:32];
            end
            else if(cpu_RorW==1'b1&&ram_ready==1'b0)//������ɹ���ԭ��Ҫд
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


    


    



    


    

