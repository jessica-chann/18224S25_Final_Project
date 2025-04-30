`default_nettype none

module my_chip (
    input  logic [11:0] io_in, 
    output logic [11:0] io_out, 
    input  logic        clock,
    input  logic        reset // Important: Reset is ACTIVE-HIGH
);
    
    logic rst_n;
    assign rst_n = ~reset;
    
    // Input mapping
    logic       start_button;          
    logic [7:0] pattern_buttons;  
    logic [1:0] mode_select;     
    
    assign start_button    = io_in[0];
    assign pattern_buttons = io_in[8:1]; 
    assign mode_select     = io_in[10:9];    
    
    // Output mapping
    logic [7:0] pattern_leds;    
    logic       game_active_led;       
    logic       game_over_led;         
    logic [1:0] score_display;   
    
    assign io_out[7:0]   = pattern_leds;
    assign io_out[8]     = game_active_led;
    assign io_out[9]     = game_over_led;
    assign io_out[11:10] = score_display; 
    
    // Game state signals
    logic start_classic, start_time, start_reverse;
    logic gen_pattern, received_input, is_equal, play_again;
    logic incr_score, clr, input_handler_en;
    logic game_over, time_over;
    
    // Game counters and data
    logic [15:0] count;           
    logic [2:0]  random_number;     
    logic [2:0]  encoded_button;    
    logic [74:0] game_pattern;     
    logic [74:0] reversed_pattern; 
    logic [74:0] user_guess;       
    logic [3:0]  score;             
    
    // Button encoder (one-hot to binary)
    always_comb begin
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
    
    // Mode selection
    gameModeSelect mode_select_inst (
        .rst_n(rst_n),
        .sel(mode_select),
        .start_classic(start_classic),
        .start_time(start_time),
        .start_reverse(start_reverse)
    );
    
    // Random number generator
    random_bit_generator rng (
        .clk(clock),
        .rst_n(rst_n),
        .en(gen_pattern),
        .random_number(random_number)
    );
    
    // Pattern storage
    shift_reg pattern_reg (
        .clk(clock),
        .rst_n(rst_n),
        .en(gen_pattern), 
        .in(random_number),         
        .is_reverse(start_reverse),
        .data(game_pattern),
        .reversed_data(reversed_pattern)
    );
    
    // Input handler
    input_handler ih (
        .clk(clock),
        .rst_n(rst_n),
        .in(encoded_button),
        .en(input_handler_en),
        .clr(clr),
        .count(count),
        .received_input(received_input),
        .user_guess(user_guess)
    );
    
    // Pattern comparison
    comparator cmp (
        .received_input(received_input),
        .game_pattern(start_reverse ? reversed_pattern : game_pattern),
        .input_pattern(user_guess),
        .is_equal(is_equal)
    );
    
    // Pattern counter
    counter pattern_counter (
        .clk(clock),
        .rst_n(rst_n),
        .en(incr_score),
        .clr(clr),
        .game_over(game_over || time_over),
        .count(count)
    );
    
    // Game mode FSMs
    logic classic_gen_pattern, classic_incr_score, classic_clr, classic_input_en, classic_game_over;
    logic time_gen_pattern, time_incr_score, time_clr, time_input_en;
    logic reverse_gen_pattern, reverse_incr_score, reverse_clr, reverse_input_en, reverse_game_over;
    
    // Classic game mode
    classicMode classic_fsm (
        .clk(clock),
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
    
    // Timed game mode
    timeChallengeMode time_fsm (
        .clk(clock),
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
    
    // Reverse game mode
    reverseMode reverse_fsm (
        .clk(clock),
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
    
    // Mux control signals based on active game mode
    always_comb begin
        if (start_classic) begin
            gen_pattern = classic_gen_pattern;
            incr_score = classic_incr_score;
            clr = classic_clr;
            input_handler_en = classic_input_en;
            game_over = classic_game_over;
        end else if (start_time) begin
            gen_pattern = time_gen_pattern;
            incr_score = time_incr_score;
            clr = time_clr;
            input_handler_en = time_input_en;
            game_over = 1'b0;  
        end else if (start_reverse) begin
            gen_pattern = reverse_gen_pattern;
            incr_score = reverse_incr_score;
            clr = reverse_clr;
            input_handler_en = reverse_input_en;
            game_over = reverse_game_over;
        end else begin
            gen_pattern = 1'b0;
            incr_score = 1'b0;
            clr = 1'b1;  // Default to reset
            input_handler_en = 1'b0;
            game_over = 1'b0;
        end
    end
    
    // Display pattern on LEDs
    display_pattern pattern_display (
        .clk(clock),
        .rst_n(rst_n),
        .en(gen_pattern),
        .count(count),
        .pattern(start_reverse ? reversed_pattern : game_pattern),
        .led(pattern_leds)
    );
    
    // Status indicators
    assign game_active_led = (count > 0) && ~(game_over || time_over);
    assign game_over_led = game_over || time_over;
    
    // Score counter
    always_ff @(posedge clock or negedge rst_n) begin
        if (~rst_n || clr) begin
            score <= 4'd0;
        end else if (incr_score) begin
            score <= score + 1'd1;
        end
    end
    
    assign score_display = score[1:0];
    
    // Play again logic
    logic [9:0] play_again_counter;
    logic play_again_ready;
    
    always_ff @(posedge clock or negedge rst_n) begin
        if (~rst_n) begin
            play_again_counter <= 10'd0;
            play_again_ready <= 1'b0;
            play_again <= 1'b0;
        end else if (game_over || time_over) begin
            if (play_again_counter < 10'd500) begin  // Half-second delay
                play_again_counter <= play_again_counter + 1'd1;
                play_again_ready <= 1'b0;
            end else begin
                play_again_ready <= 1'b1;
            end
            
            if (play_again_ready && start_button) begin
                play_again <= 1'b1;
            end else begin
                play_again <= 1'b0;
            end
        end else begin
            play_again_counter <= 10'd0;
            play_again_ready <= 1'b0;
            play_again <= 1'b0;
        end
    end

endmodule