// Code your testbench here
// or browse Examples
module testbench();

    // Declare signals
    logic clk, rst_n;
    logic start, received_input, is_equal, play_again;
    logic in;
    logic clr;
    logic gen_pattern, incr_score, game_over;
  
  	logic input_handler_en;
    logic [15:0] count;
    logic [31:0] user_guess;
    logic [4:0] input_bits;

    logic bit_generated;
    logic [31:0] random_pattern;

    // Instantiate modules
    classicMode classic_fsm (
        .clk(clk), 
        .rst_n(rst_n),
        .start(start),
        .received_input(received_input),
        .is_equal(is_equal),
        .play_again(play_again),
        .gen_pattern(gen_pattern),
        .incr_score(incr_score),
        .clr(clr),
        .game_over(game_over),
        .input_handler_en(input_handler_en)
    );

    random_bit_generator generator (
        .clk(clk),
        .rst_n(rst_n),
        .en(gen_pattern),
        .random_bit(bit_generated)
    );

    shift_reg pattern_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(gen_pattern),
      	.bit_in(bit_generated),
        .data(random_pattern)
    );

    counter counter (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(incr_score),
        .clr(clr),
        .game_over(game_over),
        .count(count)
    );

    input_handler ih (
        .clk(clk), 
        .rst_n(rst_n), 
        .in(in),
      	.en(input_handler_en),
      	.clr(clr),
        .count(count), 
        .received_input(received_input), 
        .user_guess(user_guess)
    );

    comparator cmp (
        .received_input(received_input),
        .game_pattern(random_pattern),
        .input_pattern(user_guess),
        .is_equal(is_equal)
    );
  
  	initial begin
    	$dumpfile("dump.vcd");  // Specify the name of the VCD file
    	$dumpvars(0, testbench); // Dump all variables in the testbench module
	end
  	
  	initial begin
    	rst_n = 1'b0;
    	rst_n <= 1'b1;
    	clk = 1'b0;
    	forever #5 clk = ~clk;
  	end

    initial begin
        // Initialize values
      	rst_n <= 1'b0;
      	@(posedge clk);
    	rst_n <= 1'b1;
      
      	start <= 0;
        play_again <= 0;
      	@(posedge clk);
      
        start <= 1;
        @(posedge clk);
        $display("gen_pattern = %b", gen_pattern);
        @(posedge clk);
      	start <= 0;
        $display("gen_pattern = %b", gen_pattern);

        // count <= 'd1;
      	input_bits <= random_pattern;
      	//@(posedge clk);

        $display("bit_generated = %b", bit_generated);
      	
        $display("input_handler_en = %b", input_handler_en);
      	for (int i = 1; i > 0; i--) begin
          in <= random_pattern[i - 1];  // Shift in MSB first
            @(posedge clk);  // Synchronize to the rising edge of clk
            $display("Cycle %0d: in = %b, user_guess = %b, received_input = %b", 
                     i, in, user_guess, received_input);
        end

        @(posedge clk); // should be back to pattern gen
        // count <= 'd2;
        //@(posedge clk);

        $display("input_handler_en = %b", input_handler_en);
      	for (int i = 2; i > 0; i--) begin
          in <= random_pattern[i - 1];  // Shift in MSB first
            @(posedge clk);  // Synchronize to the rising edge of clk
            $display("Cycle %0d: in = %b, user_guess = %b, received_input = %b", 
                     i, in, user_guess, received_input);
        end

        @(posedge clk); // should be back to pattern gen
        // count <= 'd2;
        //@(posedge clk);

        $display("input_handler_en = %b", input_handler_en);
      	for (int i = 3; i > 0; i--) begin
          in <= random_pattern[i - 1];  // Shift in MSB first
            @(posedge clk);  // Synchronize to the rising edge of clk
            $display("Cycle %0d: in = %b, user_guess = %b, received_input = %b", 
                     i, in, user_guess, received_input);
        end

        @(posedge clk);
      	@(posedge clk);
      	@(posedge clk);
        $display("Final: user_guess = %b, received_input = %b", user_guess, received_input);

        $finish();
    end

endmodule : testbench
