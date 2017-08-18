module fpalu_verify(input [31:0]a_in,b_in,input op,output reg [31:0]result_model_tb,output reg overflow_model_tb);
reg enable;


always@(*) 
begin

verification_model (a_in,b_in,op,result_model_tb,overflow_model_tb);

end

task  verification_model;
input [31:0] a_in, b_in;
input op;
output reg [31:0] result_task;
output reg overflow;
begin

if(op == 0)
    calculateadd (a_in, b_in, result_task,overflow);
else
    calculatemulti(a_in,b_in,result_task,overflow);
	
end
endtask



task calculateadd (input [31:0] x, y, output [31:0] sum, output overflow);
reg sa, sb, isexception;
reg [7:0] ea, eb;
reg [24:0] ma, mb;
reg of;
reg [31:0] res;
begin

split (x, y, sa, sb, ea, eb, ma, mb);
exception_adder (x, y, sa, sb, ea, eb, ma, mb, isexception, of, res);

if (!isexception)
begin
        // Call other tasks

	add_normal(x, y, sa, sb, ea, eb, ma, mb, overflow, sum);


end
else
begin
	if (res[30:23]>= 255) begin
	overflow = 1;
	end
	else begin
	overflow = 0;
	end
sum=res;
end
end
endtask

task calculatemulti (input [31:0] x, y, output [31:0] product, output overflow_multi);
reg sa, sb, isexception;
reg [7:0] ea, eb;
reg [24:0] ma, mb;
reg of;
reg [31:0] res;
begin
of=0;
res=0;
split (x, y, sa, sb, ea, eb, ma, mb);
exception_multi (x, y, sa, sb, ea, eb, ma, mb, isexception,of,res);

if (!isexception)
begin
        
	multi_normal(sa, sb, ea, eb, ma, mb, overflow_multi,product);

end
else
begin
	product=res;
	overflow_multi=of;
end
end
endtask

task split;
input [31:0] a_in, b_in;
output reg sa,sb;
output reg [7:0] ea,eb;
output reg [24:0] ma,mb;
begin

        sa = a_in[31];
        sb = b_in[31];
        ea = a_in[30:23];
        eb = b_in[30:23];
        ma = {2'b01,a_in[22:0]}; // Adjust for zero input
        mb = {2'b01,b_in[22:0]};
end
endtask



task exception_adder;
input [31:0] a_in, b_in;
input sa,sb;
input [7:0] ea,eb;
input [24:0] ma,mb;
output reg isexception, overflow_model;
output reg [31:0] result_model; 

reg sr;
reg [7:0] er;
reg [22:0] mr;

begin
	isexception = 0;
        //if a is NaN or b is NaN, return NaN
        if ((ea == 255 && ma[22:0] != 0) || (eb == 255 && mb[22:0] != 0)) begin
                sr = 1;
                er = 255;
                mr[22]= 1;
                mr[21:0] = 0;
                result_model = {sr, er, mr[22],mr[21:0]};
                overflow_model = 1;
                isexception = 1;
                end

        // if a is infinite
        else if(ea == 255 && ma[22:0] == 0) begin
                sr = sa;
                er = 255;
                mr = 0;
                result_model = {sr, er, mr};
                overflow_model = 1;
                isexception = 1;
                end

        // if b is infinite
        else if(eb == 255 && mb[22:0] == 0) begin
                sr = sb;
		er = 255;
                mr = 0;
                result_model = {sr, er, mr};
                overflow_model = 1;
                isexception = 1;
                end

        // if a is zero and b isnt
        else if ( a_in ==32'b0) begin
                sr = sb;
                er = eb;
                mr = b_in[22:0];
                result_model = {sr, er, mr};
                overflow_model = 0;
                isexception = 1;
                end

        // if b is zero and a isn't
        if ( b_in ==32'b0) begin
                sr = sa;
                er = ea;
                mr = a_in[22:0];
                result_model = {sr, er, mr};
                overflow_model = 0;
                isexception = 1;
                end
//done = 1'b1;
end
endtask

task exception_multi;
input [31:0] a_in, b_in;
input sa,sb;
input [7:0] ea,eb;
input [24:0] ma,mb;
output reg isexception, overflow_model;
output reg [31:0] result_model; 

reg sr;
reg [7:0] er;
reg [22:0] mr;

begin
	isexception = 0;
	// if a  or b is zero 
        
	if ( (a_in ==0)||( b_in ==0)) begin
                result_model = 0;
                overflow_model=0;
                isexception = 1;
                end
	// if a or b  is infinite
	else if (((a_in[30:23]==8'b11111111)&&(a_in[22:0]==0))|((b_in[30:23]==8'b11111111)&&(b_in[22:0]==0))) begin
                sr = 0;
                er = 8'b1111_1111;
                mr = 0;
                result_model = {sr, er, mr};
		overflow_model=0;
                isexception = 1;
                end
            
	 //if a is NaN or b is NaN, return NaN
       else if((a_in[30:23]==8'b11111111)|(b_in[30:23]==8'b11111111))begin
                sr = 0;
                er = 8'b1111_1111;
		mr[22]=1'b1;
		mr[21:0]=0;
                result_model = {sr,er,mr};
		overflow_model=0;
                isexception = 1;
                end

             
	else 
	begin	
	if((a_in[30:23]+b_in[30:23]-8'd127)>255)
	begin
	result_model=0;
	overflow_model=1;
	isexception=1;
	end
	end
   
       
end
endtask

task add_normal;//addition block
	input [31:0] a_in, b_in;
	input sa,sb;
	input [7:0] ea,eb;
	input [24:0] ma,mb;
	output reg overflow_model;
	output reg [31:0] result_model; 
		reg [24:0] mr;
		reg sr;
		reg [7:0] er;	
	integer i;

begin

begin : stage1
	reg [7:0] difference;

        if(ea > eb)
                begin
                er = ea;
                difference =  ea - eb;
                mb = mb >> difference;
                end
        else if(eb > ea)
                begin
                er = eb;
                difference = eb - ea;
                ma = ma  >> difference;
                end
        else begin
                er=ea;
                end
end

begin : stage2
        if (sa == sb) // Simply add the significands when signs are equal. Sign of result = sign of a and b
                begin
                sr = sa;
                mr = ma + mb;
                end

        if (sa != sb) // Negate the significand of the negative number and add both significands. Sign of result = sign of sum. Negate the sum if negative.
                begin
                if (sa == 1'b1) // only a is negative
                        begin
                        ma = (~ma) + 1'b1; // 2's complement of a
                        mb = mb;
                        end

                else // only b is negative
                        begin
                        mb = ~mb + 1'b1; // 2's complement of b
                        ma = ma;
                        end

        mr = ma + mb;
                

        if (mr[24] == 1'b1) // sum is negative
                begin
                mr = (~mr) + 1'b1; // 2's complement of sum
                sr = 1'b1;
                end
        else
		begin
                mr = mr;
                sr = 1'b0;
		end

end
end


begin


        if(mr[24] == 0 && mr[23] == 0 && er < 255 && er > 0) begin
                for(i=0;i<24;i=i+1)
                er = er - 1'b1;
                mr = mr << 1;
        end

        if ( mr[24] == 1 && mr[23] == 0 && er < 255 && er > 0) begin
                er = er + 1'b1;
                mr = mr >> 1;
        end

end



begin
if(mr[0] == 1 && er < 255 && er > 0) begin
        mr = mr + 1'b1;
        end

end


begin
if (er >= 255) begin
        overflow_model = 1;
        end
else begin
        overflow_model = 0;
        end
result_model = {sr,er,mr[22:0]};

//done = 1'b1;
end

end

endtask

task multi_normal;//multiplication block
	input sa,sb;
	input [7:0] ea,eb;
	input [24:0] ma,mb;
	output reg overflow_model;
	output reg [31:0] product_model;
		
		reg of1,of2;
		reg [47:0]pm,p;// 2n number of bits in the result 24*2.
		reg [8:0] pe,pe1,pe2;
		reg [23:0] a,b;// for 22 +1 bit
		reg [24:0] pm1,pm2;// to store the normalized product
		

begin
	
begin
	pe=ea+eb-8'd127; //Adding exponents of the two inputs and subtracting the bias to get new biased exponent
	product_model[31]=sa^sb;
	pm=ma*mb;	
end

begin
	if(pm[47]==1'b1)
		begin
		p=pm>>1;//right shift
		pe1=pe+1'b1;//increment the exp by 1
		
		if(pe1[8])
		    begin
		    of1=1'b1;        
		    end
		else
			begin
			of1=1'b0;
			end
		end
	else 
	 begin
        p=pm;
	pe1=pe;
        end
end

//to round off the final bit of the product
begin
	if(p[22]==1'b1) //if the last bit is 1 the add 1 to the previous term
	    begin
	    pm1=p[47:23]+1'b1;
	    end 
	else// if its not zero the continue the process
	    begin
	    pm1=p[47:23];
	    end
end

begin//checkiing for normalization for the 2nd time
		if(pm1[24]==1'b1)
		begin
			pm2=pm1>>1;
			pe2=pe1+1'b1;
			
			if(pe2[8])
		        begin
		        of2=1'b1;        
		        end
			else
			begin
			of2=1'b0;
			end
		end
		else
		begin
		pm2=pm1;
            	pe2=pe1;    
	        end
end

begin
	if(of1||of2)
		begin
		product_model=0;
		overflow_model=1;
		end

	else
		begin
		product_model[30:23]=pe2[7:0];
		product_model[22:0]=pm2;
		overflow_model=0;						
		end
	
end
end
endtask

endmodule 
