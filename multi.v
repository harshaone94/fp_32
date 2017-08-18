module fpalu_multi(input [31:0] a_in,b_in, input enable_in,clock,reset,output reg [31:0] product,output reg overflow,done);
reg enable,sign,of1,of2,u,ovi,en;
reg [47:0]pm,pro,p;// 2n number of bits in the result 24*2.
reg [8:0] pe,pe1,pe2;
reg [23:0] a,b;// for 22 +1 bit
reg [24:0] pm1,pm2;// to store the normalized product
reg [31:0] product1;



always@(posedge clock or negedge reset)// block to handle exceptions
begin	
	
	if(!reset)
	begin
		if(enable_in)
		begin
			if(a_in==0|| b_in==0)//either of the numbers are zero
				begin
				product1<=0;//product id zero
				enable<=0;u<=0;
				end
			else if (((a_in[30:23]==8'b11111111)&(a_in[22:0]==0))|((b_in[30:23]==8'b11111111)&(b_in[22:0]==0)))// either of the numbers are infininty
				begin
				product1[31]<=0;
				product1[30:23]<=8'b11111111;//product is infininty
				product1[22:0]<=0;
				enable<=0;u<=0;
				end
			else if((a_in[30:23]==8'b11111111)|(b_in[30:23]==8'b11111111))//either of the numbers are NaN
				begin
				product1[31]<=0;
				product1[30:23]<=8'b1111_1111;//product is NaN
				product1[21:0]<=0;
				product1[22]<=1'b1;
				enable<=0;
				u<=0;
				end
			else if((a_in[30:23]+b_in[30:23]-8'd127)>255)
				begin
				product1<=0;
				enable<=0;
				u<=1;
				end
			else
				begin
				enable<=1;
				u<=0;
				end				
		end	
		else
		begin
		enable<=0;
		product1<=0;
		end
	end
	else
	begin
	enable<=0;
	end
end

always@(posedge clock or negedge reset)
	begin
	if(!reset)
	begin
	en<=enable;
	end
	else
	begin
	en<=0;
	end	
end

always@(*)
begin
	if(en)
		begin
		pe=a_in[30:23]+b_in[30:23]-8'd127; //Adding exponents of the two inputs and subtracting the bias to get new biased exponent
		a={1'b1,a_in[22:0]};
       		b={1'b1,b_in[22:0]};
        	sign=a_in[31]^b_in[31];
      		end
	else 
		begin 
 		sign=1'b0;
		a=0;
		b=0;
		pe=0;
        	end 
end

	


		
always@(*)
	begin
	pro=a*b;
	end

always@(posedge clock or negedge reset)
begin
	if(!reset)
	begin
	pm<=pro;
	end
	else
	begin
	pm<=0;
	end
end
	
	
		
always@(*)//normalization for 1st time
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



always@(*)//to round off the final bit of the product
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

always@(*)//checkiing for normalization for the 2nd time
begin
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

always@(*)
begin	
	
	if(enable)
	begin
		product[30:23]=pe2[7:0];
		product[22:0]=pm2;
		product[31]=sign;
		overflow=0;						
	end
	else
	begin
		if((of1||of2||u)==1)
		begin
		product=product1;
		overflow=1;
		end
		else
		begin
		overflow=0;
		product=product1;
		end
	end
end
endmodule
