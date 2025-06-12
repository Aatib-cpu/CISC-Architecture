`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.04.2023 20:14:02
// Design Name: 
// Module Name: synth_cisc
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


module synth_cisc(
    input clk,
    input rst,
//    output reg [17:0] cntrl,
    input [15:0] edb,
    output reg signed [15:0] eab
    //output reg signed [15:0] ao
//    output reg zero,
//    output reg overflow,
//    output reg sign,
//    output reg carry
//    output reg signed [15:0] pc,
//    output reg signed [15:0] t1,
//    output reg signed [15:0] t2,
//    output reg signed [15:0] di,
//    output reg signed [15:0] do,
//    output reg signed [15:0] irf,
//    output reg signed [15:0] ire,
//    output reg [4:0] ib,
//    output reg [4:0] sb,
//    output reg [4:0] bc
    
    );
    
//    reg signed [15:0] ire;
    
    reg [17:0] cntrl;
    reg [2:0] srcA,srcB;
    reg [1:0] destA;
    reg [2:0] destB;
    reg signed [15:0] busA,busB;
    reg signed [15:0] pc,t1,t2,di,do,irf,ire;
    reg signed [15:0] reg_file [0:15];
    reg zero,overflow,sign,carry;
    reg signed [15:0] ao;
    
    
    reg signed [16:0] aluout;
    reg signed [15:0] alua,alub;
    
    /*
    //initializing registers and ire - for simulation
    initial
    begin
    reg_file[1]=16'd0;
    reg_file[2]=16'd2;
    #3 ire=16'b000001_0001_10_0010;
    end
      
  //simulation of the register value -displaying them
  always@(reg_file[1],reg_file[2])
  begin
  $display("r1 = %h",reg_file[1]);
    $display("r2 = %h",reg_file[2]);
  end
    */
    //assigning value to busA based on control signals
    always@(pc,t1,t2,cntrl[17:15],ire)                                  //include reg_file
    begin
    case(cntrl[17:15])
    3'b011:busA=pc;
    3'b101:busA=t1;
    3'b010:busA=reg_file[ire[3:0]];
    3'b110:busA=t2;    
    3'b001:busA=reg_file[ire[9:6]];
    3'b000:busA=16'd0;
    default: busA=16'd0;
    endcase
    end
    
    //assigning value to bus B based on control signals
    always@(di,t1,t2,cntrl[12:10])                                  //include reg_file in sensitivity list
    begin
    case(cntrl[12:10])
    3'b111:busB=di;
    3'b010:busB=reg_file[ire[3:0]];
    3'b101:busB=t1;
    3'b110:busB=t2;
    3'b001:busB=reg_file[ire[9:6]];
    3'b000:busB=16'd0;
    default: busB=16'd0;
    endcase
    end
    
    //assigning value to dest of bus A based on control signals
    always@(posedge clk,posedge rst)
    begin
    if(rst==1)
    begin
    pc<=0;
    t2<=0;
    //reg?
    
    end
    else if(cntrl[14:13]!=2'b00)
    begin
        case(cntrl[14:13])
        2'b11:pc<=busA;
        2'b01:t2<=busA;
        2'b10:reg_file[ire[3:0]]<=busA;
//        2'b00:pc<=busA;        
//        default: ;
        endcase
    end
    else if(cntrl[9:7]!=3'b000)
    begin
        case(cntrl[9:7])
        3'b100:t2<=busB;
        3'b011:pc<=busB;
        3'b101:begin
        t2<=busB;
        reg_file[ire[9:6]]<=busB;
        end
        3'b110:begin
        t2<=busB;
        reg_file[ire[3:0]]<=busB;
        end
        3'b010: reg_file[ire[3:0]]<=busB;
        3'b001: reg_file[ire[9:6]]<=busB;
//      default:
        endcase    
    
    end
    
    
    end

    //alu
    always@(busA,busB,cntrl[6:4])
    begin
    case(cntrl[6:4])
    3'b001: aluout=busA+16'd1;
    3'b010: aluout=busA+busB;
    3'b110: begin
            case(ire[15:10])
            6'b001100: aluout=busA+busB;
            6'b010100: aluout=busA-busB;
            6'b011100: aluout=busA&busB;
            6'b000101: aluout=busA-busB;
            default: aluout=busA+busB;
            endcase
            end
    3'b100: aluout=busA+16'd0;
    3'b011: aluout=busA+-16'd1;
    3'b000: aluout=busA+16'd0;
    default: aluout=busA+16'd0;
    endcase
    end
    
    //CC
    always@(posedge clk,posedge rst)
    begin
    if(rst==1)
    begin
        zero<=1'b0;
        overflow<=1'b0;
        sign<=1'b0;
        carry<=1'b0;
    end    
    else
    begin
    if((cntrl[6:4]==3'b110)||(cntrl[6:4]==3'b100))
    begin
    
    if(aluout==16'd0)
    zero<=1'b1;
    else
    zero<=1'b0;
    
    if(aluout[16]!=aluout[15]) // (~s[7]&a[7]&b[7])|(s[7]&(~a[7])&(~b[7])))
    overflow<=1'b1;
    else 
    overflow<=1'b0;
    
    if(aluout[15]==1'b1)
    sign<=1'b1;
    else
    sign<=1'b0;
    
    if(aluout[16]==1'b1)
    carry<=1'b1;
    else
    carry<=1'b0;
    end
    end
    end

    //assigning value from external memory
    always@(posedge clk,posedge rst)
    begin
    if(rst==1)
    begin
    di<=16'd0;
    irf<=16'd0;
    do<=16'd0;
    end
    else
    begin
        case(cntrl[3:1])
        3'b001: di<=edb;
        3'b010: irf<=edb;
        3'b101: di<=edb;
        3'b111: do<=busA;               ///not writing to edb??
        default: ;
        endcase
    end
    end


    always@(cntrl,busA,busB,rst)
    begin
    if(rst==1)
    begin
    ao<=0;
    end
    else
    begin
        case(cntrl[3:1])
        3'b001: begin
                ao<=busA;
                end
        3'b010: ao<=busA;
        3'b101: ao<=busB;
        3'b111: ao<=busB;
        3'b000: ao<=busA;
        default: ao<=busA;
        endcase
    end
    end

    
    always@(ao) 
    begin
    eab<=ao;
    end
    
    
        //assigning value to ire from irf
    always@(posedge clk,posedge rst)
    begin
    if(rst==1)
    begin
    ire<=16'd0;
    end
    else if(cntrl[0]==1'b1)
    begin
    ire<=irf;
    end
    end


        //assigning value to t1 from aluout
    always@(posedge clk,posedge rst)
    begin
    if(rst==1)
    begin
    t1<=16'd0;
    end
    else 
    begin
    t1<=aluout;
    end 
    end


///////////////////////////////////////////////////////CONTROL//////////////////////////////////////////

reg [4:0] cntrl_addr;
//reg [1:0] next_state;
reg [4:0] ib,sb,bc;
//reg [17:0] cntrl;

always@(cntrl_addr)
begin
case(cntrl_addr)
5'd1:cntrl<=18'b001_00_010_000_110_000_0;  //oprr1
5'd2:cntrl<=18'b011_00_101_010_001_010_0;  //oprr2
5'd3:cntrl<=18'b011_00_000_000_001_001_0;  //abdm1
5'd4:cntrl<=18'b101_11_000_000_000_000_0;  //abdm2
5'd5:cntrl<=18'b010_00_111_000_010_000_0;  //abdm3
5'd6:cntrl<=18'b101_01_000_000_000_001_0;  //abdm4
5'd7:cntrl<=18'b000_00_010_100_000_101_0;  //adrm1
5'd8:cntrl<=18'b011_00_111_101_001_010_0;  //ldrm1
5'd9:cntrl<=18'b110_00_101_011_100_000_1;  //ldrm2
5'd10:cntrl<=18'b001_00_110_000_100_111_0;  //strm1
5'd11:cntrl<=18'b011_00_111_100_001_010_0; //test1 
5'd12:cntrl<=18'b001_00_111_000_110_000_0; //oprm1
5'd13:cntrl<=18'b101_00_110_000_000_111_0; //oprm2
5'd14:cntrl<=18'b010_00_000_000_001_010_0; //brzz1
5'd15:cntrl<=18'b000_00_101_011_000_000_1; //brzz2
5'd16:cntrl<=18'b011_00_000_000_001_010_0; //brzz3
default: cntrl<=18'd0;
endcase
end

//instr decoder 
always@(ire)
begin
if(ire[15:10]==000101)
ib<=5'd14;
else
begin
case(ire[5:4])
2'b00:ib<=5'd1;//reg_direct
2'b01:ib<=5'd7;//reg_indirect
2'b10:ib<=5'd3;//base_plus_displacement
default:ib<=5'd0;
endcase
end
case(ire[15:10])
6'b000_001:sb<=5'd8;//load
6'b000_010:sb<=5'd10;//store
6'b000_011:sb<=5'd11;//test
6'b001_100:sb<=5'd12;//add
6'b010_100:sb<=5'd12;//sub
6'b011_100:sb<=5'd12;//and
//6'b000_101:sb<=;//bz
default: sb<=5'd0;
endcase
end

//next state control
always@(posedge clk,posedge rst)
begin
if(rst==1)
    cntrl_addr<=5'd0;
else
begin
case(cntrl)
  //give ib,sb or direct branch or branch control? how to do branch?
18'd0:cntrl_addr<=ib;
18'b001_00_010_000_110_000_0:cntrl_addr<=5'd2;  //oprr1
18'b011_00_101_010_001_010_0:cntrl_addr<=5'd15;  //oprr2
18'b011_00_000_000_001_001_0:cntrl_addr<=5'd4;  //abdm1
18'b101_11_000_000_000_000_0:cntrl_addr<=5'd5;  //abdm2
18'b010_00_111_000_010_000_0:cntrl_addr<=5'd6;  //abdm3
18'b101_01_000_000_000_001_0:cntrl_addr<=sb;  //abdm4
18'b000_00_010_100_000_101_0:cntrl_addr<=sb;  //adrm1
18'b011_00_111_101_001_010_0:cntrl_addr<=5'd9;  //ldrm1
18'b110_00_101_011_100_000_1:cntrl_addr<=ib;  //ldrm2
18'b001_00_110_000_100_111_0:cntrl_addr<=5'd16;  //strm1
18'b011_00_111_100_001_010_0:cntrl_addr<=5'd9; //test1 
18'b001_00_111_000_110_000_0:cntrl_addr<=5'd13; //oprm1
18'b101_00_110_000_000_111_0:cntrl_addr<=5'd16; //oprm2
18'b010_00_000_000_001_010_0:cntrl_addr<=bc; //brzz1
18'b000_00_101_011_000_000_1:cntrl_addr<=ib; //brzz2
18'b011_00_000_000_001_010_0:cntrl_addr<=5'd15; //brzz3
default:cntrl_addr<=5'd0;
endcase
end
end

//branch control block
always@(zero)
begin
if(zero==1)
bc<=5'd15;
else
bc<=5'd16;
end

endmodule


