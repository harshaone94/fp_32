`include "fpalu_add.v"
`include "fpalu_mul.v"

module fpalu(input[31:0] a_in,b_in,input clock,reset,op, output reg[31:0]result,output reg flow,done);
wire [31:0] result_mul,result_add;
wire flow_mul,flow_add,done_add,done_mul;
reg mul,add,r;

always@(*)
	begin
		if(op)
			begin
			mul<=1;
			add<=0;
			r=!reset;
			end
		else
			begin
			add<=1;
			mul<=0;
			end
	end

fpalu_adder a1(.a_in(a_in),.b_in(b_in),.start(add),.reset(reset),.clock(clock),.sum_result(result_add),.sum_overflow(flow_add),.done(done_add));
fpalu_multi m1(.a_in(a_in),.b_in(b_in),.enable_in(mul),.clock(clock),.reset(r),.product(result_mul),.overflow(flow_mul),.done(done_mul));


always@(posedge clock or negedge reset)
begin
	if(!reset)
		begin
		result<=0;
		end

	else if(op)
		begin
		result<=result_mul;
		flow<=flow_mul;
		done<=done_mul;
		end
	else
		begin
		result<=result_add;
		flow<=flow_add;
		done<=done_add;
		end
	end
endmodule

			
	
