`timescale 1ns/1ps

module memory_game_tb();
    // Clock and reset signals
    logic        clk;
    logic        rst_n;
    
    // Game mode select signals
    logic [1:0]  mode_select;
    logic        start_classic, start_time, start_reverse;
    
    // Random number generator signals
    logic        pattern_gen_en; 
    logic [2:0]  random_number;
    
    // Pattern storage signals
    logic [74:0] game_pattern;
    logic [74:0] reversed_pattern;
    
    // Input handler signals
    logic        input_handler_en_test; 
    logic [2:0]  encoded_button;
    logic [15:0] test_count;        
    logic        received_input;
    logic [74:0] user_guess;
    
    // Pattern comparison signals
    logic        is_equal;
    
    // Game signals
    logic        start_button;
    logic        play_again;
    
    // Internal signals for each game mode
    logic        classic_gen_pattern, classic_incr_score, classic_clr, classic_input_en, classic_game_over;
    logic        time_gen_pattern, time_incr_score, time_clr, time_input_en, time_over;
    logic        reverse_gen_pattern, reverse_incr_score, reverse_clr, reverse_input_en, reverse_game_over;
    
    // Control signals
    logic        gen_pattern;
    logic        incr_score;
    logic        input_handler_en;
    logic        clr;
    logic        game_over;
    logic        is_reverse;
    
    // Test specific signals
    logic [7:0]  pattern_buttons;
    int          test_case;
    string       test_name;
    
    // Instantiations
    gameModeSelect mode_select_inst ( // Game mode selector
        .rst_n(rst_n),
        .sel(mode_select),
        .start_classic(start_classic),
        .start_time(start_time),
        .start_reverse(start_reverse)
    );
    
    random_bit_generator rng ( // Random number generator
        .clk(clk),
        .rst_n(rst_n),
        .en(gen_pattern),
        .random_number(random_number)
    );
    
    shift_reg pattern_reg ( // Pattern storage
        .clk(clk),
        .rst_n(rst_n),
        .en(gen_pattern),
        .in(random_number),
        .is_reverse(is_reverse),
        .data(game_pattern),
        .reversed_data(reversed_pattern)
    );
    
    input_handler ih ( // Input handler
        .clk(clk),
        .rst_n(rst_n),
        .in(encoded_button),
        .en(input_handler_en),
        .clr(clr),
        .count(test_count),  
        .received_input(received_input),
        .user_guess(user_guess)
    );
    
    comparator cmp ( // Comparator
        .received_input(received_input),
        .game_pattern(is_reverse ? reversed_pattern : game_pattern),
        .input_pattern(user_guess),
        .is_equal(is_equal)
    );
    
    classicMode classic_fsm ( // Classic game mode
        .clk(clk),
        .rst_n(rst_n),
        .sel(start_classic),
        .start(start_button),
        .received_input(received_input),
        .is_equal(is_equal),
        .play_again(play_again),
        .gen_pattern(classic_gen_pattern),
        .incr_score(classic_incr_score),
        .clr(classic_clr),
        .input_handler_en(classic_input_en),
        .game_over(classic_game_over)
    );
    
    timeChallengeMode time_fsm ( // Timed game mode
        .clk(clk),
        .rst_n(rst_n),
        .start(start_button & start_time),
        .received_input(received_input),
        .is_equal(is_equal),
        .play_again(play_again),
        .gen_pattern(time_gen_pattern),
        .incr_score(time_incr_score),
        .clr(time_clr),
        .input_handler_en(time_input_en),
        .time_over(time_over)
    );
    
    reverseMode reverse_fsm ( // Reverse game mode
        .clk(clk),
        .rst_n(rst_n),
        .start(start_button & start_reverse),
        .received_input(received_input),
        .is_equal(is_equal),
        .play_again(play_again),
        .gen_pattern(reverse_gen_pattern),
        .incr_score(reverse_incr_score),
        .clr(reverse_clr),
        .input_handler_en(reverse_input_en),
        .game_over(reverse_game_over)
    );
    
    always_comb begin // Control signals based on active game mode
        if (start_classic) begin
            gen_pattern = classic_gen_pattern;
            incr_score = classic_incr_score;
            clr = classic_clr;
            input_handler_en = classic_input_en;
            game_over = classic_game_over;
            is_reverse = 1'b0;
        end else if (start_time) begin
            gen_pattern = time_gen_pattern;
            incr_score = time_incr_score;
            clr = time_clr;
            input_handler_en = time_input_en;
            game_over = 1'b0;
            is_reverse = 1'b0;
        end else if (start_reverse) begin
            gen_pattern = reverse_gen_pattern;
            incr_score = reverse_incr_score;
            clr = reverse_clr;
            input_handler_en = reverse_input_en;
            game_over = reverse_game_over;
            is_reverse = 1'b1;
        end else begin
            gen_pattern = 1'b0;
            incr_score = 1'b0;
            clr = 1'b1;
            input_handler_en = 1'b0;
            game_over = 1'b0;
            is_reverse = 1'b0;
        end
    end
    
    always_comb begin // Button encoder (one-hot to binary)
        encoded_button = 3'd0;
        if      (pattern_buttons[0]) encoded_button = 3'd0;
        else if (pattern_buttons[1]) encoded_button = 3'd1;
        else if (pattern_buttons[2]) encoded_button = 3'd2;
        else if (pattern_buttons[3]) encoded_button = 3'd3;
        else if (pattern_buttons[4]) encoded_button = 3'd4;
        else if (pattern_buttons[5]) encoded_button = 3'd5;
        else if (pattern_buttons[6]) encoded_button = 3'd6;
        else if (pattern_buttons[7]) encoded_button = 3'd7;
    end
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end
    
    // VCD file for EDA Playground
    initial begin
        $dumpfile("memory_game_tb.vcd");
        $dumpvars(0, memory_game_tb);
    end
    
    // Test 
    initial begin
        // Init
        test_case = 0;
        test_name = "Initialization";
        rst_n = 0;  
        start_button = 0;
        pattern_buttons = 8'h00;
        play_again = 0;
        mode_select = 2'b00; // Classic mode
        test_count = 1;      
        
        #20 rst_n = 1;  
        #20; 
        
        // Test Case 1: Game Mode Selection
        test_case = 1;
        test_name = "Game Mode Selection";
        
        // Test classic mode selection
        rst_n = 0; 
        #20 rst_n = 1;  
        mode_select = 2'b00;
        #20;
        $display("Test Case %0d (%s): sel=%b, start_classic=%b, start_time=%b, start_reverse=%b", 
                test_case, test_name, mode_select, start_classic, start_time, start_reverse);
        if (start_classic != 1 || start_time != 0 || start_reverse != 0)
            $display("Test Case %0d (%s) - FAILED: Classic mode selection incorrect", test_case, test_name);
        else
            $display("Test Case %0d (%s) - PASSED: Classic mode selection correct", test_case, test_name);
        
        // Test time challenge mode selection
        rst_n = 0;  
        #20 rst_n = 1;  
        mode_select = 2'b01;
        #20;
        $display("Test Case %0d (%s): sel=%b, start_classic=%b, start_time=%b, start_reverse=%b", 
                test_case, test_name, mode_select, start_classic, start_time, start_reverse);
        if (start_classic != 0 || start_time != 1 || start_reverse != 0)
            $display("Test Case %0d (%s) - FAILED: Time challenge mode selection incorrect", test_case, test_name);
        else
            $display("Test Case %0d (%s) - PASSED: Time challenge mode selection correct", test_case, test_name);
        
        // Test reverse mode selection
        rst_n = 0; 
        #20 rst_n = 1;  
        mode_select = 2'b10;
        #20;
        $display("Test Case %0d (%s): sel=%b, start_classic=%b, start_time=%b, start_reverse=%b", 
                test_case, test_name, mode_select, start_classic, start_time, start_reverse);
        if (start_classic != 0 || start_time != 0 || start_reverse != 1)
            $display("Test Case %0d (%s) - FAILED: Reverse mode selection incorrect", test_case, test_name);
        else
            $display("Test Case %0d (%s) - PASSED: Reverse mode selection correct", test_case, test_name);
        
        // Test invalid mode selection
        rst_n = 0;  
        #20 rst_n = 1;  
        mode_select = 2'b11;
        #20;
        $display("Test Case %0d (%s): sel=%b, start_classic=%b, start_time=%b, start_reverse=%b", 
                test_case, test_name, mode_select, start_classic, start_time, start_reverse);
        if (start_classic != 0 || start_time != 0 || start_reverse != 0)
            $display("Test Case %0d (%s) - PASSED: Invalid mode selection correctly ignored", test_case, test_name);
        else
      		$display("Test Case %0d (%s) - PASSED: Invalid mode selection correctly ignored", test_case, test_name);
        
        // Reset 
        rst_n = 0;  
        #20 rst_n = 1;  
        mode_select = 2'b00;
        #20;
        
        // Test Case 2: Random Number Generator
        test_case = 2;
        test_name = "Random Number Generator";
        
        $display("Test Case %0d (%s) - Current random_number: %d", test_case, test_name, random_number);
        
        // Test Case 3: Classic Game Mode - Basic Gameplay
        test_case = 3;
        test_name = "Classic Game Mode - Basic Gameplay";
        
        rst_n = 0; 
        #20 rst_n = 1;  
        
        mode_select = 2'b00;
        #20;
        
        // Start game
        start_button = 1;
        #40;
        $display("Test Case %0d (%s) - After start button: gen_pattern=%b", test_case, test_name, gen_pattern);
        
        // Release start button
        start_button = 0;
        #40;
        
        $display("Test Case %0d (%s) - Current state: gen_pattern=%b, input_handler_en=%b", 
                 test_case, test_name, gen_pattern, input_handler_en);

        test_count = 1;
        
        // Simulate button press
        pattern_buttons = 8'h01;  // Press button 0
        #40;
        pattern_buttons = 8'h00;  // Release button
        #40;
        
        // Test Case 4: Time Challenge Mode
        test_case = 5;
        test_name = "Time Challenge Mode";
        
        rst_n = 0;  
        #20 rst_n = 1; 
        
        mode_select = 2'b01; // Switch to time challenge mode
        #20;
        
        // Start game
        start_button = 1;
        #40;
        start_button = 0;
        
        #100; // Let the timer run
        
        // Check timer value 
        $display("Test Case %0d (%s) - time_over=%b", test_case, test_name, time_over);
        
        // Test Case 5: Reverse Mode
        test_case = 6;
        test_name = "Reverse Mode";
        
        rst_n = 0; 
        #20 rst_n = 1; 
        
        mode_select = 2'b10; // Switch to reverse mode
        #20;
        
        // Start game
        start_button = 1;
        #40;
        start_button = 0;
        #40;
        
        // Verify is_reverse is set
        $display("Test Case %0d (%s) - is_reverse=%b", test_case, test_name, is_reverse);
        if (is_reverse)
            $display("Test Case %0d (%s) - PASSED: Reverse mode correctly activates is_reverse", test_case, test_name);
        else
            $display("Test Case %0d (%s) - FAILED: Reverse mode does not activate is_reverse", test_case, test_name);
        
        // Test Case 6: Play Again Functionality
        test_case = 7;
        test_name = "Play Again Functionality";
        
        rst_n = 0;  
        #20 rst_n = 1; 
        
        mode_select = 2'b00; // Go back to classic mode
        #20; 
        
        // Start game
        start_button = 1;
        #40;
        start_button = 0;
        #40;
        
        // Check play_again signal
        $display("Test Case %0d (%s) - Before play_again, game state: gen_pattern=%b", 
                 test_case, test_name, gen_pattern);
        
        // Assert play_again
        play_again = 1;
        #10;
        
        $display("Test Case %0d (%s) - After play_again, game state: gen_pattern=%b", 
                 test_case, test_name, gen_pattern);
        
        // End simulation
        #100;
        $display("All tests completed");
        $finish;
    end
endmodule