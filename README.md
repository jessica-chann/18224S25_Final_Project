# 18-224/624 S25 Tapeout Template


1. Add your verilog source files to `source_files` in `info.yaml`. The top level of your chip should remain in `chip.sv` and be named `my_chip`

  
  

2. Optionally add other details about your project to `info.yaml` as well (this is only for GitHub - your final project submission will involve submitting these in a different format)

3. Do NOT edit `toplevel_chip.v`  `config.tcl` or `pin_order.cfg`

 # Final Project Submission Details 
  
1. Your design must synthesize at 30MHz but you can run it at any arbitrarily-slow frequency (including single-stepping the clock) on the manufactured chip. If your design must run at an exact frequency, it is safest to choose a lower frequency (i.e. 5MHz)

  

2. For your final project, we will ask you to submit some sort of testbench to verify your design. Include all relevant testing files inside the `testbench` repository

  
  

3. For your final project, we will ask you to submit documentation on how to run/test your design, as well as include your project proposal and progress reports. Include all these files inside the `docs` repository

  
  

4. Optionally, if you use any images in your documentation (diagrams, waveforms, etc) please include them in a separate `img` repository

  

5. Feel free to edit this file and include some basic information about your project (short description, inputs and outputs, diagrams, how to run, etc). An outline is provided below

## Memory Game

The Memory Game is a Simon Says–style interactive game. Players are presented with a sequence of LED flashes and must replicate the sequence using button inputs. The sequence grows longer with each round, and players can choose between three game modes: Classic, Reverse, and Time Challenge.

Internally, the game uses a combination of FSMs, LFSRs for pseudo-random pattern generation, shift registers for pattern storage, and comparators for input checking. User interaction is handled via buttons, and game feedback is provided through LEDs and a simple score display.

Refer to docs/Memory_Game_Final_Progress_Report.pdf for full details.

## IO

An IO table listing all of your inputs and outputs and their function, like the one below:

| Input/Output	| Description|																
|---------------|----------------------------------------------------|
| io_in[0]      | Start button to begin a new game                   |
| io_in[1:8]    | 8 one-hot encoded pattern input buttons            |
| io_in[8:10]   | 2-bit mode select: 00=Classic, 01=Time, 10=Reverse |
| io_in[11]     | unused                                             |
| io_out[0:7]   | Pattern output LEDs                                |
| io_out[8]     | Game active status LED                             |
| io_out[9]     | Game over status LED                               |
| io_out[10:11] | Score display                                      |

## How to Test

### After tapeout, you can test the design as follows:
1. Power the chip and connect the required buttons and LEDs:
- Connect 8 button for input.
- Use an external controller to toggle start.
- Use buttons to select a game mode.

2. Start the game:
- Set mode (Classic, Time Challenge, or Reverse).
- Press the start button.

3. Observe the pattern:
- LEDs will flash in a generated sequence.
- After the sequence, press buttons in the correct order.

4. Score and status:
- Score is shown.
- Green lights while the game is active.
- Red lights when the game ends (loss or timeout).

5. Play again:
- Wait for the replay window, then press start again to replay.
