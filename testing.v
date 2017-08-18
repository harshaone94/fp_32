`timescale 1ns / 1ps
`include "fpalu.v"
`include "fpalu_ver.v"


module fpalu_verify_fixture;

	// Inputs
	reg [31:0] a_in;
	reg [31:0] b_in;
	reg op;
	reg clock;
	reg reset;
	
	// Outputs
	wire [31:0] result,result_model_tb;
	wire flow,overflow_model_tb;
	wire done;

	
fpalu m1 (
		.a_in(a_in), 
		.b_in(b_in), 
		.clock(clock), 
		.reset(reset), 
		.op(op), 
		.result(result), 
		.flow(flow), 
		.done(done)
	);


fpalu_verify m2(
		.a_in(a_in), 
		.b_in(b_in), 
		.op(op), 
		.result_model_tb(result_model_tb), 
		.overflow_model_tb(overflow_model_tb)
	);
	



initial
      		 $vcdpluson;

initial 
	begin
	clock=1;
	forever #2 clock=!clock;
	end

	
task reset_DUT();
	begin
	reset = 1'b0;
	#2 reset = 1'b1;
	end
endtask

task send_inputs;
	input integer count;
	input op;
	integer i;
	reg pass;
		
	if(op)
	begin//multiplication
	i=1;
	while(i<=count)
	begin	
		@(negedge clock)
		a_in = $random;
		b_in = $random;
		$strobe ("New inputs:\t Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
		#15 i=i+1;
		$strobe ("Operation Complete: \t Result = %b, Overflow = %b\n ",result,flow);
		checker(result,result_model_tb,flow,overflow_model_tb);
			
	end
	end
	
	else
	begin//addition
	for(i=0;i<count;i=i+1)
	begin	
		@(negedge clock)
		a_in = $random;
		b_in = $random;
		$strobe ("New inputs:Operation = %b, a = %b, b = %b\n", op, a_in, b_in);
		wait(done);
		$strobe ("Operation Complete: \tResult = %b, Overflow = %b\n",result,flow);
		@(posedge done);
		checker(result,result_model_tb,flow,overflow_model_tb);
	end
	end
endtask


initial
	begin
	reset_DUT();
	op=1;
	$display("\n Random Test: 1 and operator = MULTIPLICATION\n");
	send_inputs(50,1);//multiplication
	
	#20 op=1;
	$display("\n Exception Test: 1 and operator = MULTIPLICATION\n");
	exceptions_multi(op);
		
	reset_DUT();
	
	#20 op=0;	
	$display("\n Exception Test: 1 and operator = ADDITION\n");	
	exceptions_adder(op);

	op=0;
	$display("\n Random Test: 2 and operator= ADDITION\n");
	send_inputs(50,0);//addition
	
	
	
	reset_DUT();
	$display("\n MULTIPLICATION AND ADDITION\n");
	op=1;
	send_inputs(1,1);
	op=0;
	send_inputs(1,0);
	

	#50 $finish;
end

task checker;
input [31:0] result,result_model_tb;
input flow,overflow_model_tb;
begin
	if((result==result_model_tb)&&(flow==overflow_model_tb))
		begin
		$display(" verification test PASS!!!!\n");
		end
	else
		begin
		$display(" verification test FAIL:(\n");
		end
end
endtask

task exceptions_multi;
	input op;
	begin
	a_in = 32'b0_00000000_00000000000000000000000;//0
	b_in = 32'b1_11100110_11100011100011100011101;//-1.915561E31 
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	#15 $display (" Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	checker(result,result_model_tb,flow,overflow_model_tb);
	
	a_in = 32'b0_11111111_00011000000000000000000;//NaN
	b_in = 32'b0_11001101_11001001101001101001110;//-5.4029872E23
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	#15 $display (" Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	checker(result,result_model_tb,flow,overflow_model_tb);
			
	a_in = 32'b0_01111111_00000000000000000000000;//1
	b_in = 32'b1_00100101_01101100001101101100110;//-1.1492569E-27
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	#15 $display (" Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	checker(result,result_model_tb,flow,overflow_model_tb);
			
	a_in = 32'b0_11111111_00000000000000000000000;//a is infinity
	b_in = 32'b1_10101010_10101010101010101010101;//-1.46601547E13
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	#15 $display (" Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	checker(result,result_model_tb,flow,overflow_model_tb);
		
	a_in = 32'b0_10100101_11111111111111111111111;//5.49755781E11
	b_in = 32'b0_00000000_00000000000000000000000;//0
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	#15 $display (" Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	checker(result,result_model_tb,flow,overflow_model_tb);
	
	a_in = 32'b0_11111110_01110010000000010000000;//3.2167837E38
	b_in = 32'b0_11111110_01111110010000101000000;//2.540552E38
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	#15 $display (" Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	checker(result,result_model_tb,flow,overflow_model_tb);
	
	a_in = 32'b1_10101010_10101010101010101010101;//-1.46601547E13
	b_in = 32'b0_11111111_00000000000000000000000;//b is infinity
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	#15 $display (" Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	checker(result,result_model_tb,flow,overflow_model_tb);

	b_in = 32'b0_11111111_00011000000000000000000;//NaN
	a_in = 32'b0_11001101_11001001101001101001110;//-5.4029872E23
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	#15 $display (" Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	checker(result,result_model_tb,flow,overflow_model_tb);
	end				
endtask

task exceptions_adder;
	input op;
	begin
	a_in = 32'b0_00000000_00000000000000000000000;//0
	b_in = 32'b1_11100110_11100011100011100011101;//-1.915561E31 
	$strobe ("New inputs:Operation = %b, a = %b, b = %b\n", op, a_in, b_in);
	wait(done);
	//$strobe ("Operation Complete: \tResult = %b, Overflow = %b\n",result,flow);
	@(posedge done);
	checker(result,result_model_tb,flow,overflow_model_tb);
	
	a_in = 32'b0_11111111_00011000000000000000000;//NaN
	b_in = 32'b0_11001101_11001001101001101001110;//-5.4029872E23
	$strobe ("New inputs:Operation = %b, a = %b, b = %b\n", op, a_in, b_in);
	wait(done);
	$strobe ("Operation Complete: \tResult = %b, Overflow = %b\n",result,flow);
	@(posedge done);
	checker(result,result_model_tb,flow,overflow_model_tb);
			
		
	a_in = 32'b0_11111111_00000000000000000000000;//a is infinity
	b_in = 32'b1_10101010_10101010101010101010101;//-1.46601547E13
	$strobe ("New inputs:Operation = %b, a = %b, b = %b\n", op, a_in, b_in);
	wait(done);
	$strobe ("Operation Complete: \tResult = %b, Overflow = %b\n",result,flow);
	@(posedge done);
	checker(result,result_model_tb,flow,overflow_model_tb);

		
	a_in = 32'b0_10100101_11111111111111111111111;//5.49755781E11
	b_in = 32'b0_00000000_00000000000000000000000;//0
	$strobe ("New inputs:Operation = %b, a = %b, b = %b\n", op, a_in, b_in);
	wait(done);
	$strobe ("Operation Complete: \tResult = %b, Overflow = %b\n",result,flow);
	@(posedge done);
	checker(result,result_model_tb,flow,overflow_model_tb);
	
	a_in = 32'b0_11111110_01110010000000010000000;//3.2167837E38
	b_in = 32'b0_11111110_01111110010000101000000;//2.540552E38
	$strobe ("New inputs:Operation = %b, a = %b, b = %b\n", op, a_in, b_in);
	wait(done);
	$strobe ("Operation Complete: \tResult = %b, Overflow = %b\n",result,flow);
	@(posedge done);
	checker(result,result_model_tb,flow,overflow_model_tb);
	
	@(posedge done);	
	a_in = 32'b1_10101010_10101010101010101010101;//-1.46601547E13
	b_in = 32'b0_11111111_00000000000000000000000;//b is infinity
	$strobe ("New inputs:Operation = %b, a = %b, b = %b\n", op, a_in, b_in);
	wait(done);
	$strobe ("Operation Complete: \tResult = %b, Overflow = %b\n",result,flow);
	@(posedge done);
	checker(result,result_model_tb,flow,overflow_model_tb);

	@(posedge done);	
	b_in = 32'b0_11111111_00011000000000000000000;//NaN
	a_in = 32'b0_11001101_11001001101001101001110;//-5.4029872E23
	$display ("New inputs: Operation = %b, a = %b, b = %b\n",op,a_in,b_in);
	wait(done);
	$display ("Operation Complete: Result = %b, Overflow = %b \n",result,flow);
	@(posedge done);	
	checker(result,result_model_tb,flow,overflow_model_tb);
	end				
endtask

endmodule	
		
		
	
