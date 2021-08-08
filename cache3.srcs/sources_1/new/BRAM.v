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

//cache32�У���Ϊ16�飬ÿ��2�飬2·��������1��4�֣�1��4�ֽڣ�������128-bit
//�����ַ12λ��6-bit Tag��4-bit ��ţ�2-bit ���ڵ�ַ
//cacheÿ��136-bit��1-bitV + 1-bitD + 6-bitTag + 128-bitData
//LRU�滻����д����д���䣬2·������
//��������tb����
module BRAM(
clk,rst,cpu_v,cpu_RorW,cpu_addr,cpu_wdata,cpu_ready,cpu_rdata,state,count,hit,hit1,hit2,way );
    input clk,rst,cpu_v,cpu_RorW;//cpu�����Ƿ���Ч��cpuҪ������д
    input [11:0]cpu_addr;//cpu���ĵ�ַ
    input [31:0]cpu_wdata;//cpuҪд�ĵ�ַ
    wire [127:0]ram_rdata;//ram���������������
    output reg cpu_ready;//cpu��/д�Ƿ����
    output reg [31:0]cpu_rdata;//cpu����������
    reg [11:0]ram_addr;//��ram�ĵ�ַ
    reg [127:0]ram_wdata;//Ҫд��ram������
    parameter schv=0,cmprtag=1,cinram=2,rerw=3;
    parameter V=135,D=134,TM=133,TL=128,DM=127,DL=0;
    output reg[1:0]state;
    reg[135:0]cache[31:0];
    reg [1:0]nextstate;
    reg ram_RorW,ram_v,ram_ready;//cache��ram������д��cache��ram֮�����ݷ���ramд���Ƕ�
    output reg hit,hit1,hit2,way;//���б�־��0·��1·��Ҫѡ��д����һ·
    output reg[11:0]count;//���ʹ��Ƶ�ʶ��У�00->0·��01->1·��11->��ʹ��
    reg          ena;        //RAM PORT  A дʹ�ܣ��ߵ�ƽ��Ч
    reg          enb;        //RAM PORT  B ��ʹ�ܣ��ߵ�ƽ��Ч
    integer i,count0,count1;//0·ʹ�ô���,1·ʹ�ô���
    initial               //��ʼ��
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
       ram_ready=1'b1;//��ramд����
      end
      else if(ram_v==1'b0&&ram_RorW==1'b0)
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
               //�ж��Ƿ�����0·
               if(cache[2*cpu_addr[5:2]][V]==1'b1&&cache[2*cpu_addr[5:2]][TM:TL]==cpu_addr[11:6])
               begin
                hit1=1'b1;
               end
               else
               begin
                hit1=1'b0;
               end
               //�ж��Ƿ�����1·
               if(cache[2*cpu_addr[5:2]+1][V]==1'b1&&cache[2*cpu_addr[5:2]+1][TM:TL]==cpu_addr[11:6])
               begin
                hit2=1'b1;
               end
               else
               begin
                hit2=1'b0;
               end
               //�ж��Ƿ�����
               hit=hit1||hit2;
               //����
               if(hit)
               begin
                nextstate=schv;//���к�������¸�״̬�ж���һ��ָ��
                if(cpu_RorW==1'b0)                        //��cpu�����У�ֱ�Ӷ���ȥ
                begin
                 cpu_ready<=1'b1;//cpu->cache����
                 if(hit1)//����0·
                 begin
                  //LRU��ʼ
                  count0=count0+1;
                  if(count0+count1>5)//�ܴ���Ϊ5
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
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
                  //LRU����
                  cpu_rdata=cache[2*cpu_addr[5:2]][32*cpu_addr[1:0] +:32];//��0·���ݶ���
                 end
                 else//����1·
                 begin
                  //LRU��ʼ
                  count1=count1+1;
                  if(count0+count1>5)//�������г��ȣ�ɾ��ͷԪ��
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
                  //LRU����
                  cpu_rdata=cache[2*cpu_addr[5:2]+1][32*cpu_addr[1:0] +:32];//��1·����
                 end
                end
                if(cpu_RorW==1'b1)                        //��cpuд���У�ֱ��д������������
                begin
                 cpu_ready<=1'b1;
                 if(hit1) //����0·
                 begin
                  //LRU��ʼ
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
                  //LRU����
                  cache[2*cpu_addr[5:2]][32*cpu_addr[1:0]+:32]=cpu_wdata;
                  cache[2*cpu_addr[5:2]][D]=1'b1;
                 end
                 else //����1·
                 begin
                  //LRU��ʼ
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
                  //LRU����
                  cache[2*cpu_addr[5:2]+1][32*cpu_addr[1:0] +:32]=cpu_wdata;
                  cache[2*cpu_addr[5:2]+1][D]=1'b1;
                 end
                end
               end
               else if(hit==1'b0)///��cpuû����
               begin
                cpu_ready<=1'b0;//cpu->cacheû����
                case({cache[2*cpu_addr[5:2]][V],cache[2*cpu_addr[5:2]+1][V]})//�ж�Ҫ�滻��һ·
                 2'b01:way=1'b0; 
                 2'b10:way=1'b1;
                 2'b00:way=(count0<=count1)?1'b0:1'b1;
                 2'b11:way=(count0<=count1)?1'b0:1'b1; 
                 default:way=(count0<=count1)?1'b0:1'b1;
                endcase
                if(cpu_RorW==1'b1)                       //cpuд�����У��ȵ�������cache���ٸ���cache��д���䷨
                begin
                 if(cache[2*cpu_addr[5:2]+way][D]==1'b1)//Ҫ�滻����cache�����ˣ��Ƚ����е�������
                 begin
                  ram_wdata=cache[2*cpu_addr[5:2]+way][DM:DL];
                  ram_addr={cache[2*cpu_addr[5:2]+way][TM:TL],cpu_addr[5:2],2'b00};//����λ����ν
                  ram_RorW=1'b1;
                  ram_v=1'b1;//cache->ram
                 end
                 nextstate=cinram;
                end
                if(cpu_RorW==1'b0)//cpu�������� ������Ӧ��������cache�ٶ�
                begin
                 if(cache[2*cpu_addr[5:2]+way][D]==1'b1)//Ҫ�滻����cache�����ˣ��Ƚ����е�������
                 begin
                  ram_wdata=cache[2*cpu_addr[5:2]+way][DM:DL];
                  ram_addr={cache[2*cpu_addr[5:2]+way][TM:TL],cpu_addr[5:2],2'b00};//����λ����ν
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
               ram_v=1'b0;//ram->cache
               ram_addr=cpu_addr;
               ram_wdata=128'b0;//���㣬��д
               cpu_ready=1'b1;
               cache[2*cpu_addr[5:2]+way]={2'b10,cpu_addr[11:6],ram_rdata};//���ڴ棬��λ��0����Чλ��1��û���������cache���Ҳ��������
               //LRU��ʼ
               if(way)//1·
               begin
                count1=1;
                count={count[9:0],2'b01};
               end
               else//0·
               begin
                count0=1;
                count={count[9:0],2'b00};
               end
               //LRU����
              end
             end   
      rerw:begin
            nextstate=schv;
            if(cpu_RorW==1'b0&&ram_ready==1'b0)//��ram��ԭ��Ҫ��
            begin
             cpu_rdata=cache[2*cpu_addr[5:2]][32*cpu_addr[1:0]+:32];
            end
            else if(cpu_RorW==1'b1&&ram_ready==1'b0)//������ɹ���ԭ��Ҫд
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


    


    
