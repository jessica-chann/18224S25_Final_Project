module gameModeSelect (
    input  logic        rst_n,
    input  logic  [1:0] sel,
    output logic        start_classic, start_time, start_reverse

);
always_comb begin
        case (sel)
            2'd0: begin
                start_classic = 1;
                start_time = 0;
                start_reverse = 0;
            end
            2'd1: begin
                start_classic = 0;
                start_time = 1;
                start_reverse = 0;
            end
            2'd2: begin
                start_classic = 0;
                start_time = 0;
                start_reverse = 1;
            end
            default: begin
                start_classic = 0;
                start_time = 0;
                start_reverse = 0;
            end
        endcase
    end

endmodule : gameModeSelect


module classicMode (
    input  logic        clk, rst_n, sel,
    input  logic        start, received_input, is_equal, play_again, 

    output logic        gen_pattern, incr_score, clr, input_handler_en, game_over
);

    enum logic [1:0] {INIT, PATTERN_GEN, WAIT, GAME_OVER} state, next_state;

    logic mode_selected, play;

    always_ff @(posedge clk) begin
        if (~rst_n || play_again) begin
            state <= INIT;
            mode_selected <= 0;
            play <= 0;
        end else if (sel) begin
            state <= INIT;
            mode_selected <= 1;
            play <= 0;
        end else if (mode_selected && (start || play)) begin
            state <= next_state;
            mode_selected <= 1;
            play <= 1;
        end
    end

    // next state logic
    always_comb begin
        case (state)
            INIT: next_state = (start) ? PATTERN_GEN : INIT;
            PATTERN_GEN: next_state = WAIT;
            WAIT: begin
                if (received_input && is_equal) next_state = PATTERN_GEN;
                else if (received_input && !is_equal) next_state = GAME_OVER;
                else next_state = WAIT;
            end
            GAME_OVER: next_state = (play_again) ? INIT : GAME_OVER;
            default: next_state = INIT;
        endcase
    end

    // output logic
    // assign gen_pattern = (state == INIT && start) ? 1 : 0;
    assign gen_pattern = (next_state == PATTERN_GEN);
    assign incr_score = (state == WAIT && is_equal) ? 1 : 0;
  	// assign input_handler_en = (state == PATTERN_GEN ) || state == WAIT));
    assign input_handler_en = (state == WAIT && next_state == WAIT);
    assign clr = (state == INIT || play_again == 1) ? 1 : 0;
  	assign game_over = (next_state == GAME_OVER);

endmodule : classicMode


module timeChallengeMode ( // still need to add clock divider
    input  logic        clk, rst_n,
    input  logic        start, received_input, is_equal, play_again, 
    
    output logic        gen_pattern, incr_score, clr, input_handler_en, time_over
);

    enum logic [2:0] {INIT, PATTERN_GEN, WAIT, TIME_OVER} state, next_state;

    logic [5:0] timer; // 6-bit timer for 60 seconds (0-59)
    logic timer_done;  // Timer done signal to trigger state change

    // State transition on clock or reset
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            state <= INIT;
            timer <= 0;
        end else begin
            if (state == PATTERN_GEN) timer <= timer + 1;
            state <= next_state;
        end
    end

    // Next state logic
    always_comb begin
        case (state)
            INIT: next_state = (start) ? PATTERN_GEN : INIT;
            PATTERN_GEN: next_state = WAIT;
            WAIT: begin
                if (received_input && is_equal) next_state = PATTERN_GEN;
                else if (received_input && !is_equal) next_state = TIME_OVER;
                else if (timer_done) next_state = TIME_OVER; // Transition to TIME_OVER after timer reaches 60
                else next_state = WAIT;
            end
            TIME_OVER: next_state = (play_again) ? INIT : TIME_OVER;
            default: next_state = INIT;
        endcase
    end

    // Output logic
    assign gen_pattern = (next_state == PATTERN_GEN);
    assign incr_score = (state == WAIT && is_equal) ? 1 : 0;
    assign input_handler_en = (state == WAIT && next_state == WAIT);
    assign clr = (state == INIT || play_again == 1) ? 1 : 0;
    assign time_over = (next_state == TIME_OVER);
    assign timer_done = (timer == 'd60) ? 1 : 0;

endmodule : timeChallengeMode


module reverseMode (
    input  logic        clk, rst_n,
    input  logic        start, received_input, is_equal, play_again, 

    output logic        gen_pattern, incr_score, clr, input_handler_en, game_over
);

    enum logic [1:0] {INIT, PATTERN_GEN, WAIT, GAME_OVER} state, next_state;

    always_ff @(posedge clk) begin
        if (~rst_n) state <= INIT;
        else state <= next_state;
    end

    // next state logic
    always_comb begin
        case (state)
            INIT: next_state = (start) ? PATTERN_GEN : INIT;
            PATTERN_GEN: next_state = WAIT;
            WAIT: begin
                if (received_input && is_equal) next_state = PATTERN_GEN;
                else if (received_input && !is_equal) next_state = GAME_OVER;
                else next_state = WAIT;
            end
            GAME_OVER: next_state = (play_again) ? INIT : GAME_OVER;
            default: next_state = INIT;
        endcase
    end

    // output logic
    // assign gen_pattern = (state == INIT && start) ? 1 : 0;
    assign gen_pattern = (next_state == PATTERN_GEN);
    assign incr_score = (state == WAIT && is_equal) ? 1 : 0;
  	// assign input_handler_en = (state == PATTERN_GEN ) || state == WAIT));
    assign input_handler_en = (state == WAIT && next_state == WAIT);
    assign clr = (state == INIT || play_again == 1) ? 1 : 0;
  	assign game_over = (next_state == GAME_OVER);

endmodule : reverseMode


module random_bit_generator (
    input  logic clk, rst_n, en,     
    output logic [2:0] random_number  // 3-bit number, range from 0 to 7
);

    logic [31:0] lfsr_reg;

    // LFSR polynomial: x^32 + x^22 + x^2 + x^1 + 1 (maximal length)
    always_ff @(posedge clk) begin
        if (!rst_n) 
            lfsr_reg <= 32'hABCD1234; // Use a fixed seed value for synthesis
        else if (en)
            lfsr_reg <= {lfsr_reg[30:0], lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0]};
    end

    // Output the lower 3 bits of the LFSR for a number between 0 to 7
    assign random_number = lfsr_reg[2:0];

endmodule : random_bit_generator


module display_pattern (
    input  logic        clk, rst_n, en,
    input  logic [15:0] count,
    input  logic [74:0] pattern,
    output logic [7:0]  led
);

    logic [15:0] counter;

    always_ff @(posedge clk) begin
        if (~rst_n || ~en) begin
            led <= 0;
            counter <= 0;
        end else if (en && counter < count) begin
            counter <= counter + 'd3;
            if (pattern[counter] == 'd0) begin
                led[0] <= 1;
                led[1] <= 0;
                led[2] <= 0;
                led[3] <= 0;
                led[4] <= 0;
                led[5] <= 0;
                led[6] <= 0;
                led[7] <= 0;
            end else if (pattern[counter] == 'd1) begin
                led[0] <= 0;
                led[1] <= 1;
                led[2] <= 0;
                led[3] <= 0;
                led[4] <= 0;
                led[5] <= 0;
                led[6] <= 0;
                led[7] <= 0;
            end else if (pattern[counter] == 'd2) begin
                led[0] <= 0;
                led[1] <= 0;
                led[2] <= 1;
                led[3] <= 0;
                led[4] <= 0;
                led[5] <= 0;
                led[6] <= 0;
                led[7] <= 0;
            end else if (pattern[counter] == 'd3) begin
                led[0] <= 0;
                led[1] <= 0;
                led[2] <= 0;
                led[3] <= 1;
                led[4] <= 0;
                led[5] <= 0;
                led[6] <= 0;
                led[7] <= 0;
            end else if (pattern[counter] == 'd4) begin
                led[0] <= 0;
                led[1] <= 0;
                led[2] <= 0;
                led[3] <= 0;
                led[4] <= 1;
                led[5] <= 0;
                led[6] <= 0;
                led[7] <= 0;
            end else if (pattern[counter] == 'd5) begin
                led[0] <= 0;
                led[1] <= 0;
                led[2] <= 0;
                led[3] <= 0;
                led[4] <= 0;
                led[5] <= 1;
                led[6] <= 0;
                led[7] <= 0;
            end else if (pattern[counter] == 'd6) begin
                led[0] <= 0;
                led[1] <= 0;
                led[2] <= 0;
                led[3] <= 0;
                led[4] <= 0;
                led[5] <= 0;
                led[6] <= 1;
                led[7] <= 0;
            end else if (pattern[counter] == 'd7) begin
                led[0] <= 0;
                led[1] <= 0;
                led[2] <= 0;
                led[3] <= 0;
                led[4] <= 0;
                led[5] <= 0;
                led[6] <= 0;
                led[7] <= 1;
            end
        end
    end
endmodule : display_pattern


module shift_reg (
    input  logic        clk, rst_n, en, is_reverse,
    input  logic [2:0]  in,
    output logic [74:0] data, reversed_data

);
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            data <= 'b0;
            reversed_data <= 'b0;
        end else if (en) begin
            data <= {data[71:0], in};
            if (is_reverse) reversed_data <= {in, data[71:0]};
        end

    end
endmodule : shift_reg


module counter (
    input  logic        clk, rst_n, en, clr, game_over,
    output logic [15:0] count
);
    always_ff @(posedge clk) begin
        if (~rst_n || clr) count <= 1;
        else if (en) count <= count + 1;
        else if (game_over) count <= count - 1;
    end
endmodule : counter


module comparator (
    input  logic        received_input,
    input  logic [74:0] game_pattern, input_pattern,
    output logic        is_equal   
);
    assign is_equal = (received_input && (game_pattern == input_pattern));

endmodule : comparator


module input_handler (
    input  logic        clk, rst_n, en, clr,
    input  logic [2:0]  in,
    input  logic [15:0] count,
    output logic        received_input,
    output logic [74:0] user_guess
);
    logic [15:0] bit_counter;

    always_ff @(posedge clk) begin
      if (~rst_n || clr) begin
            user_guess      <= 'd0;
            bit_counter     <= 'd0;
      end else if (en) begin
            if (bit_counter != count) begin
                user_guess  <= {user_guess[71:0], in};
                bit_counter <= bit_counter + 1;
            end
        end
    end

    assign received_input = (count != 0 && bit_counter + 1 == count);

endmodule : input_handler
