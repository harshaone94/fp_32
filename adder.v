module fpalu_adder( input [31:0] a_in,b_in, 
		input start, reset,clock, 
		output reg [31:0] sum_result,
		output reg sum_overflow, done);
	
reg [31:0] a,b,a_next,b_next,sum;
reg s_a_int,s_b_int,s_a,s_b,s_r_int,s_r;
reg [7:0] e_a_int,e_b_int,e_a,e_b,difference,e_r_int,e_r;
reg [24:0] m_a,m_b,m_a_int,m_b_int,m_r_int,m_r_sum,m_a_comp,m_b_comp,m_r;// local reg // change: 24 to 25 bits

parameter [3:0] get_inputs = 4'b0000, split = 4'b0001, exceptions= 4'b0010, exponent_difference = 4'b0011, adder=4'b0100, normalize=4'b0101, rounding=4'b0110, check_normalize=4'b0111, result=4'b1000;
reg [3:0] state,statenext;

always@(posedge clock or negedge reset)
begin
if(!reset)
	begin
	state <= get_inputs;
	a <= 0;
	b <= 0;
	s_a <= 0;
	s_b <= 0;
	e_a <= 0;
	e_b <= 0;
	m_a <= 0;
	m_b <= 0;
	m_r <= 0;
	s_r <= 0;
	e_r <= 0;
	end
else
	begin
	// Update state register
	state<= statenext;

	// Update other internal registers
	a <= a_next;
	b <= b_next;
	s_a <= s_a_int;
	s_b <= s_b_int;
	s_r <= s_r_int;
	e_a <= e_a_int;
	e_b <= e_b_int;
	e_r <= e_r_int;
	m_a <= m_a_int;
	m_b <= m_b_int;
	m_r <= m_r_int;
	end
end

always@(*)
begin
statenext = 4'b0000;
// default values
m_r_int = m_r;
done = 1'b0;
case(state)

get_inputs : 
begin
if(start)
	begin
		a_next = a_in;
		b_next = b_in;
		statenext = split;
	end
	else statenext = get_inputs;
end

split: 
begin
	s_a_int = a[31];
	s_b_int = b[31];
	e_a_int = a[30:23];
	e_b_int = b[30:23];
	m_a_int = {2'b01,a[22:0]}; // Adjust for zero input
	m_b_int = {2'b01,b[22:0]};
	statenext = exceptions;
end
exceptions:
begin
//if a is NaN or b is NaN, return NaN
if ((e_a == 255 && m_a[22:0] != 0) || (e_b == 256 && m_b[22:0] != 0)) begin
	s_r_int = 1;
	e_r_int = 255;
	//sum_result[22] = 1;
	//sum_result[21:0] = 0;
	m_r_int[22]= 1;
	m_r_int[21:0] = 0;
	statenext = result;
	end

// if a is infinite 
else if(e_a == 255 && m_a[22:0] == 0) begin
	s_r_int = s_a;
	e_r_int = 255;
	m_r_int = 0;
	statenext = result;
	end

// if b is infinite
else if(e_b == 255 && m_b[22:0] == 0) begin
	s_r_int = s_b;
	e_r_int = 255;
	m_r_int = 0;
	statenext = result;
	end
	
// if a is zero and b isnt
else if ( a==32'b0) begin
	s_r_int = s_b;
	e_r_int = e_b;
	m_r_int = m_b;
	statenext = result;
	end
	
// if b is zero and a isn't
else if ( b==32'b0) begin
	s_r_int = s_a;
	e_r_int = e_a;
	m_r_int = m_a;
	statenext = result;
	end 
else begin
	statenext = exponent_difference;
	end
end


exponent_difference : 
begin	
	if(e_a > e_b)
		begin
		e_r_int = e_a;
		difference =  e_a - e_b;
		m_b_int = m_b >> difference;
		statenext = adder;
		end
	else if(e_b > e_a)
		begin
		e_r_int = e_b;
		difference = e_b - e_a;
		m_a_int = m_a  >> difference;
		statenext = adder;
		end
	else begin
		e_r_int=e_a; 
		statenext = adder;
	end
end

adder:
begin
	if (s_a == s_b) // Simply add the significands when signs are equal. Sign of result = sign of a and b
		begin
		s_r_int = s_a;
		m_r_int = m_a + m_b;
		end

	if (s_a != s_b) // Negate the significand of the negative number and add both significands. Sign of result = sign of sum. Negate the sum if negative.
		begin
		if (s_a == 1'b1) // only a is negative
			begin
			m_a_int = (~m_a) + 1'b1; // 2's complement of a
			m_b_int = m_b;
			end	

		else // only b is negative
			begin
			m_b_int = ~m_b + 1'b1; // 2's complement of b
			m_a_int = m_a;
			end
		
	m_r_int = m_a_int + m_b_int;

	if (m_r_int[24] == 1'b1) // sum is negative
		begin
		m_r_int = (~m_r_int) + 1'b1; // 2's complement of sum
		s_r_int = 1'b1; 
		end
	else
	begin
		m_r_int = m_r_int;
		s_r_int = 1'b0; 
	end
end

statenext = normalize;
end

normalize:
begin
	if(m_r[24] == 0 && m_r[23] == 0 && e_r < 255 && e_r > 0) begin
		e_r_int = e_r - 1'b1;
		m_r_int = m_r << 1;
		$display("24=0");
		statenext = normalize;
	end
	
	if ( m_r[24] == 1 && m_r[23] == 0 && e_r < 255 && e_r > 0) begin
		e_r_int = e_r + 1'b1;
		m_r_int = m_r >> 1;
		$display("24=1");
		statenext = rounding;
	end
	else 
		statenext = rounding;
end

rounding: 
begin
if(m_r[0] == 1 && e_r < 255 && e_r > 0) begin
	m_r_int = m_r + 1'b1;
	statenext = check_normalize;
	end
else 
	statenext = check_normalize;
end

check_normalize:
if(m_r[23] != 1 && e_r < 255 && e_r > 0) begin
	statenext = normalize;
	end
else
begin
	statenext = result;
end

result:
begin
done = 1'b1;
if (e_r >= 255) begin
	sum_overflow = 1;
	end
else begin
	sum_overflow = 0;
	end
sum_result = {s_r,e_r,m_r[22:0]};
statenext = get_inputs;
end

endcase
end
endmodule 
