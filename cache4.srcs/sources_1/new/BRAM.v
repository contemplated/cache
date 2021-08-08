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


//cache32�У���Ϊ8�飬ÿ��4�飬4·��������1��4�֣�1��4�ֽڣ�������128-bit�����湲1024��
//�����ַ12λ��7-bit Tag��3-bit ��ţ�2-bit ���ڵ�ַ
//cacheÿ��137-bit��1-bitV + 1-bitD + 7-bitTag + 128-bitData
//LRU�滻����д����д���䣬4·������
//��������tb����
module BRAM(
clk,rst,cpu_v,cpu_RorW,cpu_addr,cpu_wdata,cpu_ready,cpu_rdata,state,count,hit,hit1,hit2,hit3,hit4,way );
    input clk,rst,cpu_v,cpu_RorW;//cpu�����Ƿ���Ч��cpuҪ������д
    input [11:0]cpu_addr;//cpu���ĵ�ַ
    input [31:0]cpu_wdata;//cpuҪд�ĵ�ַ
    wire [127:0]ram_rdata;//ram���������������
    output reg cpu_ready;//cpu��/д�Ƿ����
    output reg [31:0]cpu_rdata;//cpu����������
    reg [11:0]ram_addr;//��ram�ĵ�ַ
    reg [127:0]ram_wdata;//Ҫд��ram������
    parameter schv=0,cmprtag=1,cinram=2,rerw=3;
    parameter V=136,D=135,TM=134,TL=128,DM=127,DL=0,MAX=10;
    output reg[1:0]state;
    reg[136:0]cache[31:0];
    reg [1:0]nextstate;
    reg ram_RorW,ram_v,ram_ready;//cache��ram������д��cache��ram֮�����ݷ���ramд���Ƕ�
    output reg hit,hit1,hit2,hit3,hit4;//���б�־��0·��1·��2·��3·
    output reg [1:0]way;//Ҫѡ��д����һ·
    output reg[26:0]count;//���ʹ��Ƶ�ʶ��У�000->0·��001->1·��010->2·��011->3·��111->��ʹ�ã��ܴ���8�Σ�����Ӧ��9�Σ�һ��Ϊɾ����
    reg          ena;        //RAM PORT  A дʹ�ܣ��ߵ�ƽ��Ч
    reg          enb;        //RAM PORT  B ��ʹ�ܣ��ߵ�ƽ��Ч
    integer i,count0,count1,count2,count3;//0·ʹ�ô���,1·ʹ�ô���,��������
    function [1:0]max;//�ó���һ·���ʹ��
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

    initial               //��ʼ��
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
               //�ж��Ƿ�����0·
               if(cache[4*cpu_addr[4:2]][V]==1'b1&&cache[4*cpu_addr[4:2]][TM:TL]==cpu_addr[11:5])
               begin
                hit1=1'b1;
               end
               else
               begin
                hit1=1'b0;
               end
               //�ж��Ƿ�����1·
               if(cache[4*cpu_addr[4:2]+1][V]==1'b1&&cache[4*cpu_addr[4:2]+1][TM:TL]==cpu_addr[11:5])
               begin
                hit2=1'b1;
               end
               else
               begin
                hit2=1'b0;
               end
               //�ж��Ƿ�����2·
               if(cache[4*cpu_addr[4:2]+2][V]==1'b1&&cache[4*cpu_addr[4:2]+2][TM:TL]==cpu_addr[11:5])
               begin
                hit3=1'b1;
               end
               else
               begin
                hit3=1'b0;
               end
               //�ж��Ƿ�����3·
               if(cache[4*cpu_addr[4:2]+3][V]==1'b1&&cache[4*cpu_addr[4:2]+3][TM:TL]==cpu_addr[11:5])
               begin
                hit4=1'b1;
               end
               else
               begin
                hit4=1'b0;
               end
               //�ж��Ƿ�����
               hit=hit1|hit2|hit3|hit4;
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
                  if(count0+count1+count2+count3>8)//�ܴ���Ϊ8
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b000};
                  //LRU����
                  cpu_rdata=cache[4*cpu_addr[4:2]][32*cpu_addr[1:0] +:32];//��0·���ݶ���
                 end
                 else if(hit2)//����1·
                 begin
                  //LRU��ʼ
                  count1=count1+1;
                  if(count0+count1+count2+count3>8)//�ܴ���Ϊ8
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b001};
                  //LRU����
                  cpu_rdata=cache[4*cpu_addr[4:2]+1][32*cpu_addr[1:0] +:32];//��1·����
                 end
                 else if(hit3)//����2·
                 begin
                  //LRU��ʼ
                  count2=count2+1;
                  if(count0+count1+count2+count3>8)//�ܴ���Ϊ8
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b010};
                  //LRU����
                  cpu_rdata=cache[4*cpu_addr[4:2]+2][32*cpu_addr[1:0] +:32];//��2·����
                 end
                 else if(hit4)//����3·
                 begin
                  //LRU��ʼ
                  count3=count3+1;
                  if(count0+count1+count2+count3>8)//�ܴ���Ϊ8
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b011};
                  //LRU����
                  cpu_rdata=cache[4*cpu_addr[4:2]+3][32*cpu_addr[1:0] +:32];//��3·����
                 end
                end
                if(cpu_RorW==1'b1)                        //��cpuд���У�ֱ��д������������
                begin
                 cpu_ready<=1'b1;
                 if(hit1) //����0·
                 begin
                  //LRU��ʼ
                  count0=count0+1;
                  if(count0+count1+count2+count3>8)//�ܴ���Ϊ8
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b000};
                  //LRU����
                  cache[4*cpu_addr[4:2]][32*cpu_addr[1:0]+:32]=cpu_wdata;
                  cache[4*cpu_addr[4:2]][D]=1'b1;
                 end
                 else if(hit2)//����1·
                 begin
                  //LRU��ʼ
                  count1=count1+1;
                  if(count0+count1+count2+count3>8)//�ܴ���Ϊ8
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b001};
                  //LRU����
                  cache[4*cpu_addr[4:2]+1][32*cpu_addr[1:0] +:32]=cpu_wdata;
                  cache[4*cpu_addr[4:2]+1][D]=1'b1;
                 end
                 else if(hit3)//����2·
                 begin
                  //LRU��ʼ
                  count2=count2+1;
                  if(count0+count1+count2+count3>8)//�ܴ���Ϊ8
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b010};
                  //LRU����
                  cache[4*cpu_addr[4:2]+2][32*cpu_addr[1:0] +:32]=cpu_wdata;
                  cache[4*cpu_addr[4:2]+2][D]=1'b1;
                 end
                 else if(hit4)//����3·
                 begin
                  //LRU��ʼ
                  count3=count3+1;
                  if(count0+count1+count2+count3>8)//�ܴ���Ϊ8
                  begin
                   //�������г��ȣ�ɾ��ͷԪ��
                   case(count[26:24])
                    3'b000:count0=count0-1;
                    3'b001:count1=count1-1;
                    3'b010:count2=count2-1;
                    3'b011:count3=count3-1;
                   endcase
                  end
                  count={count[26:3],3'b011};
                  //LRU����
                  cache[4*cpu_addr[4:2]+3][32*cpu_addr[1:0]+:32]=cpu_wdata;
                  cache[4*cpu_addr[4:2]+3][D]=1'b1;
                 end
                end
               end
               else if(hit==1'b0)///��cpuû����
               begin
                cpu_ready<=1'b0;//cpu->cacheû����
                case({cache[4*cpu_addr[4:2]][V],cache[4*cpu_addr[4:2]+1][V],cache[4*cpu_addr[4:2]+2][V],cache[4*cpu_addr[4:2]+3][V]})//�ж�Ҫ�滻��һ·
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
                if(cpu_RorW==1'b1)                       //cpuд�����У��ȵ�������cache���ٸ���cache��д���䷨
                begin
                 if(cache[4*cpu_addr[4:2]+way][D]==1'b1)//Ҫ�滻����cache�����ˣ��Ƚ����е�������
                 begin
                  ram_wdata=cache[4*cpu_addr[4:2]+way][DM:DL];
                  ram_addr={cache[4*cpu_addr[4:2]+way][TM:TL],cpu_addr[4:2],2'b00};//����λ����ν
                  ram_RorW=1'b1;
                  ram_v=1'b1;//cache->ram
                 end
                 nextstate=cinram;
                end
                if(cpu_RorW==1'b0)//cpu�������� ������Ӧ��������cache�ٶ�
                begin
                 if(cache[4*cpu_addr[4:2]+way][D]==1'b1)//Ҫ�滻����cache�����ˣ��Ƚ����е�������
                 begin
                  ram_wdata=cache[4*cpu_addr[4:2]+way][DM:DL];
                  ram_addr={cache[4*cpu_addr[4:2]+way][TM:TL],cpu_addr[4:2],2'b00};//����λ����ν
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
               cache[4*cpu_addr[4:2]+way]={2'b10,cpu_addr[11:5],ram_rdata};//���ڴ棬��λ��0����Чλ��1��û���������cache���Ҳ��������
               //LRU��ʼ
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
               //LRU����
              end
             end   
      rerw:begin
            nextstate=schv;
            if(cpu_RorW==1'b0&&ram_ready==1'b0)//��ram��ԭ��Ҫ��
            begin
             cpu_rdata=cache[4*cpu_addr[4:2]][32*cpu_addr[1:0]+:32];
            end
            else if(cpu_RorW==1'b1&&ram_ready==1'b0)//��ram��ԭ��Ҫд
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

