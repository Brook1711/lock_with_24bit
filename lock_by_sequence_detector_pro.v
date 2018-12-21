`timescale 1ns/1ns
module lock_by_sequence_detector_pro(clk, rst, BTN, code_8bit, digit_seg, digit_cath, R_N5_T5, G_R3_T6);
parameter code2=8'b11111111;
parameter code1=8'b00000000;
parameter code0=8'b11111111;
input clk;
input rst;
input BTN;
input [7:0] code_8bit;
output [7:0] digit_seg;
output [1:0] digit_cath;
output[1:0] R_N5_T5;
output[1:0] G_R3_T6;

wire BTN_pulse;

reg [1:0] choose;
reg [1:0] cnt;
reg [23:0] code_temp;
reg self_lock;
reg correct;
reg false;
reg [1:0] R_N5_T5_temp;
reg [1:0] G_R3_T6_temp;
reg [27:0] flag_G;
reg [27:0] flag_R;

wire digit_seg_temp;
wire clk_2;
wire bell_code_music;

//assign digit_seg = self_lock==1? 8'b11111111:digit_seg_temp;
assign R_N5_T5[0] = self_lock==1?0:R_N5_T5_temp[0];
assign R_N5_T5[1] = self_lock==1?0:R_N5_T5_temp[1];
assign G_R3_T6[0] = self_lock==1?1:G_R3_T6_temp[0];
assign G_R3_T6[1] = self_lock==1?1:G_R3_T6_temp[1];

initial begin
	choose=0;
	cnt=0;
	code_temp=0;
	self_lock=0;
	correct=0;
	false=0;
	R_N5_T5_temp=2'b11;
	G_R3_T6_temp=2'b11;
	flag_R=0;
	flag_G=0;
end
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		G_R3_T6_temp<=2'b11;
	end
	else if(flag_G==25000000) begin
		G_R3_T6_temp<=2'b11;
	end
	else if (correct) begin
		G_R3_T6_temp<=0;
	end
	else begin
		G_R3_T6_temp<=G_R3_T6_temp;
	end
end
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		flag_G<=0;
	end
	else if (G_R3_T6_temp==0) begin
		flag_G<=flag_G+1;
	end
	else begin
		flag_G<=0;
	end
end
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		R_N5_T5_temp<=2'b11;
	end
	else if (flag_R==25000000) begin
		R_N5_T5_temp<=2'b11;
	end
	else if (false) begin
		R_N5_T5_temp<=0;
	end
	else begin
		R_N5_T5_temp<=R_N5_T5_temp;
	end
end
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		flag_R<=0;
	end
	else if (R_N5_T5_temp==0) begin
		flag_R<=flag_R+1;
	end
	else begin
		flag_R<=0;
	end
end

always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		cnt<=0;
	end

	else if (cnt==3) begin
		cnt<=0;
	end
	else if (BTN_pulse)begin
		cnt<=cnt+1;
	end
end

always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		code_temp<=0;
	end
	else if(BTN_pulse) begin
		if (cnt==0) begin
			code_temp[7:0]<=code_8bit;
		end
		else if (cnt==1) begin
			code_temp[15:8]<=code_8bit;
		end
		else begin
			code_temp[23:16]<=code_8bit;
		end
	end
	else begin
		code_temp<=code_temp;
	end
end

always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		choose<=0;
		self_lock<=0;
	end
	else if (correct==1) begin
		correct<=0;
	end
	else if (false==1) begin
		false<=0;
	end
		
	
	else if (choose==3) begin
		self_lock<=1;
	end
	else if (cnt == 3) begin
		if (code_temp!={code2, code1, code0}) begin
			choose<=choose+1;
			false<=1;
		end
		else begin
			choose<=0;
			correct<=1;
		end
	end
end
/*
always @(posedge clk or posedge rst) begin
	if (rst) begin
		// reset
		correct<=0;
	end
	else if (correct==1) begin
		correct<=0;
	end
	else if (code_temp=={code2, code1, code0}) begin
		correct<=1;
	end
	else begin
		correct<=correct;
	end
end
*/
frequency_divider #(.N(12500000)) u_clk_2(
	.clkin(clk),
	.clkout(clk_2)
	);

debounce u_debounce(.clk(clk),.rst(rst),.key(~BTN),.key_pulse(BTN_pulse));

seg_scan u_decode(.clk_50M(clk),.rst_button(rst), .switch(code_8bit), .digit_seg(digit_seg), .digit_cath(digit_cath));
endmodule


 module debounce (clk,rst,key,key_pulse);
 
        parameter       N  =  1;                      //要消除的按键的数量
 
	input             clk;
        input             rst;
        input 	[N-1:0]   key;                        //输入的按键					
	output  [N-1:0]   key_pulse;                  //按键动作产生的脉冲	
 
        reg     [N-1:0]   key_rst_pre;                //定义一个寄存器型变量存储上一个触发时的按键值
        reg     [N-1:0]   key_rst;                    //定义一个寄存器变量储存储当前时刻触发的按键值
 
        wire    [N-1:0]   key_edge;                   //检测到按键由高到低变化是产生一个高脉冲
 
        //利用非阻塞赋值特点，将两个时钟触发时按键状态存储在两个寄存器变量中
        always @(posedge clk  or  posedge rst)
          begin
             if (rst) begin
                 key_rst <= {N{1'b1}};                //初始化时给key_rst赋值全为1，{}中表示N个1
                 key_rst_pre <= {N{1'b1}};
             end
             else begin
                 key_rst <= key;                     //第一个时钟上升沿触发之后key的值赋给key_rst,同时key_rst的值赋给key_rst_pre
                 key_rst_pre <= key_rst;             //非阻塞赋值。相当于经过两个时钟触发，key_rst存储的是当前时刻key的值，key_rst_pre存储的是前一个时钟的key的值
             end    
           end
 
        assign  key_edge = key_rst_pre & (~key_rst);//脉冲边沿检测。当key检测到下降沿时，key_edge产生一个时钟周期的高电平
 
        reg	[17:0]	  cnt;                       //产生延时所用的计数器，系统时钟12MHz，要延时20ms左右时间，至少需要18位计数器     
 initial begin
 	cnt=0;
 end
        //产生20ms延时，当检测到key_edge有效是计数器清零开始计数
        always @(posedge clk or posedge rst)
           begin
             if(rst)
                cnt <= 18'h0;
             else if(key_edge)
                cnt <= 18'h0;
             else
                cnt <= cnt + 1'h1;
             end  
 
        reg     [N-1:0]   key_sec_pre;                //延时后检测电平寄存器变量
        reg     [N-1:0]   key_sec;                    
 
 
        //延时后检测key，如果按键状态变低产生一个时钟的高脉冲。如果按键状态是高的话说明按键无效
        always @(posedge clk  or  posedge rst)
          begin
             if (rst) 
                 key_sec <= {N{1'b1}};                
             else if (cnt==18'h3ffff)
                 key_sec <= key;  
          end
       always @(posedge clk  or  posedge rst)
          begin
             if (rst)
                 key_sec_pre <= {N{1'b1}};
             else                   
                 key_sec_pre <= key_sec;             
         end      
       assign  key_pulse = key_sec_pre & (~key_sec);     
       initial
       begin
       	cnt<=0;
       	key_rst<=0;
       	key_rst_pre<=0;
       	key_sec_pre<=0;
       	key_sec<=0;
       end
 
endmodule


module seg_scan(clk_50M,rst_button, switch, digit_seg, digit_cath);
input clk_50M; //板载50M晶振
input rst_button;
input [7:0] switch;
output reg [7:0] digit_seg; //七段数码管的段选端
output [1:0] digit_cath; //2个数码管的片选端
wire reset; //复位按键
assign reset = rst_button;

//计数分频，通过读取32位计数器div_count不同位数的上升沿或下降沿来获得频率不同的时钟
reg [31:0] div_count;
always @(posedge clk_50M,posedge reset)
begin
    if(reset)
        div_count <= 0;   //如果按下复位按键，计数清零
    else
        div_count <= div_count + 1;
end

//拨码开关控制数码管显示，每4位拨码开关控制一个七段数码管
wire [7:0] digit_display;
assign digit_display = switch;

wire [3:0] digit;
always @(*)      //对所有信号敏感
begin
    case (digit)
        4'h0:  digit_seg <= 8'b11111100; //显示0~F
        4'h1:  digit_seg <= 8'b01100000;   
        4'h2:  digit_seg <= 8'b11011010;
        4'h3:  digit_seg <= 8'b11110010;
        4'h4:  digit_seg <= 8'b01100110;
        4'h5:  digit_seg <= 8'b10110110;
        4'h6:  digit_seg <= 8'b10111110;
        4'h7:  digit_seg <= 8'b11100000;
        4'h8:  digit_seg <= 8'b11111110;
        4'h9:  digit_seg <= 8'b11110110;
        4'hA:  digit_seg <= 8'b11101110;
        4'hB:  digit_seg <= 8'b00111110;
        4'hC:  digit_seg <= 8'b10011100;
        4'hD:  digit_seg <= 8'b01111010;
        4'hE:  digit_seg <= 8'b10011110;
        4'hF:  digit_seg <= 8'b10001110;
    endcase
end

//通过读取32位计数器的第10位的上升沿得到分频时钟，用于数码管的扫描
reg segcath_holdtime;
always @(posedge div_count[10], posedge reset)
begin
if(reset)
     segcath_holdtime <= 0;
else
     segcath_holdtime <= ~segcath_holdtime;
end

//7段数码管位选控制
assign digit_cath ={segcath_holdtime, ~segcath_holdtime};
// 相应位数码管段选信号控制
assign digit =segcath_holdtime ? digit_display[7:4] : digit_display[3:0];

endmodule

module flash(clk_2, rst, finnal_flag, switch, bell_code);
input clk_2;
input rst;
input finnal_flag;
output reg switch;
output reg [2:0] bell_code;
reg [2:0] cnt;
initial
begin
	switch<=1;
	cnt<=0;
	bell_code<=0;
end

always @(posedge clk_2 or posedge rst) begin
	if (rst) begin
		// reset
		switch<=1;
		cnt<=0;
	end
	else if (finnal_flag==0 &cnt<6) begin
		switch<=~switch;
		cnt<=cnt+1;
	end
	else if (cnt==6) begin
		switch<=1;
		cnt<=7;
	end
	else begin
		switch<=switch;
	end
end

always @(posedge clk_2) begin
	case(cnt)
	0:begin
		bell_code<=0;
	end
	1:begin
		bell_code<=1;
	end
	2:begin
		bell_code<=2;
	end
	3:begin
		bell_code<=3;
	end
	4:begin
		bell_code<=4;
	end
	5:begin
		bell_code<=5;
	end
	6:begin
		bell_code<=6;
	end
	default:begin
		bell_code<=0;
	end
	endcase
end
endmodule

module frequency_divider(clkin, clkout);
parameter N = 1;
input clkin;
output reg clkout;
reg [27:0] cnt;
initial 
begin
cnt=0;
clkout<=0;
end
always @(posedge clkin) begin
	if (cnt==N) begin
		clkout <= !clkout;
		cnt <= 0;
	end
	else begin
		cnt <= cnt + 1;
	end
end
endmodule

