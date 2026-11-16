# RISC-V Pong

## Project overview

This project is a two-player Pong game written in RISC-V assembly for the RARS 1.6 simulator on a PC. It uses RARS's Bitmap Display and Keyboard and Display MMIO Simulator tools. It is a simulator-based game, not a physical ARIES board implementation.

## Features

- Two paddles and a ball on a 64 x 32 logical playfield.
- Left paddle controls: **W/S**. Right paddle controls: **I/K**. Both uppercase and lowercase letters are accepted; each received key moves its paddle one row during play.
- The game opens on a ready screen. Press **Space** in the Keyboard and Display MMIO Simulator to start. Press **P** to pause or resume; a pause label appears on the court. Paddle controls are ignored until play starts and while paused.
- The ball moves diagonally. It reverses vertical direction at the top and bottom walls and horizontal direction when it hits a paddle. A missed paddle gives the point to the other player.
- Scores are tracked in the left and right score registers and drawn as `P1 <score>   P2 <score>` at the top of the display with a larger 5 x 7 pixel font. The ball resets to the centre after a point. The first player to five points wins; a message is printed in the RARS console and the program exits.
- The court background is light green, the dashed center divider and scoreboard are black, the paddles are dark blue, and the ball is bright orange.
- Ball speed is controlled by a software countdown after each frame. `li t0, 16000` sets the delay-loop count; reducing it speeds up play, while increasing it slows play. Keyboard polling happens before the delay on each frame.

## Requirements and project structure

- **RARS 1.6** on a PC.
- RARS **Bitmap Display** and **Keyboard and Display MMIO Simulator** tools.
- `src/main.s` contains the game loop, MMIO keyboard polling, paddle and ball movement, collisions, scoring, framebuffer drawing, scoreboard glyphs, and winner output.
- `tests/keyboardtest.s` is a small standalone receiver-polling example. It recognizes lowercase `w` and exits; it is not the game and should be assembled/run separately.
- `README.md` contains setup, implementation notes, and troubleshooting.
- `rars1_6.jar` is bundled at the project root.

## Setup and execution

1. Start RARS 1.6, open `src/main.s`, and choose **Assemble**.
2. Open **Tools > Bitmap Display** and set:
   - **Unit Width:** 8
   - **Unit Height:** 8
   - **Display Width:** 512
   - **Display Height:** 256
   - **Base address:** `0x10010000 (static data)`
3. Press **Connect to Program** in Bitmap Display.
4. Open **Tools > Keyboard and Display MMIO Simulator** and press **Connect to Program**. It must be connected to the running program for keyboard input to reach the game.
5. Run the program. The ready screen shows **PRESS / START / SPACE**. Enter Space in the keyboard simulator's keyboard input area to start. During play, enter `w`, `s`, `i`, or `k` to move the paddles, or `p` to pause/resume (uppercase also works).

### Enlarge the display

To make the game larger, increase the Bitmap Display's unit size and scale its display dimensions by the same amount. For example, use **Unit Width: 16**, **Unit Height: 16**, **Display Width: 1024**, and **Display Height: 512**. Keep the base address at `0x10010000 (static data)` and reconnect to the program. This enlarges the 64 x 32 game grid without changing the assembly. You can also maximize the Bitmap Display tool window; whether it fills the screen depends on your desktop resolution and RARS window layout.

## Game layout and physics

The logical grid is 64 columns by 32 rows. A position is written `(x, y)`, where `x` is the column and `y` is the row. The ball has direction `(dx, dy)`; each component is either `+1` or `-1`, so it moves diagonally by one cell per frame. Positive `dx` moves right; positive `dy` moves down.

- Left paddle: column 2. Right paddle: column 61. Both paddles are 8 cells high; their top row is clamped to 0 through 24.
- Ball starts at `(31, 15)` with `dx = +1`, `dy = +1`.
- At the top and bottom wall, `dy` is reversed and the ball remains within rows 0 through 31.
- At a paddle column, a ball within the paddle's 8-row range reverses `dx`, preserving `dy`. If it misses, the opposing player scores as the ball passes that paddle.
- After scoring, the ball returns to `(31, 15)`. The first player to 5 points wins.

Framebuffer byte address for logical cell `(x, y)`:

```text
address = 0x10010000 + 4 * (y * 64 + x)
```

Each logical cell is one 32-bit pixel word. The default 8 x 8 Bitmap Display unit size scales each logical cell to 8 x 8 screen pixels, giving a 512 x 256 display. A 16 x 16 unit size gives a 1024 x 512 display while keeping the same 64 x 32 logical grid.

## Implementation lessons learned

- **Keyboard MMIO:** The game polls receiver control address `0xFFFF0000`; bit 0 indicates that a character is ready. It then reads the character from receiver data address `0xFFFF0004`. The source compares ASCII values for W/S/I/K in both cases. It reads at most one character each frame, so the MMIO simulator must be connected and focused for input.
- **Bitmap memory:** A framebuffer cell is four bytes. A complete court is drawn at startup and after state changes. During normal play, the code redraws only the old/new ball and paddle cells to reduce display jitter. The display may appear blank until the program executes this drawing code; connect the tool before running or rerun after connecting.
- **Scoreboard redraw:** Clearing all 2048 cells erases every visible pixel, including the score. `draw_frame` therefore calls `draw_scoreboard` after drawing the ball. Glyph row bytes and winner strings are placed at `0x10012000`, just after the 8192-byte framebuffer range, so the clear loop does not overwrite them.
- **Frame pacing:** The countdown at `li t0, 16000` is a software delay, not a wall-clock timer. Its perceived speed depends on the simulator and computer. Tune that count if movement is too fast or slow; the run-speed slider is not the only control.
- **Subroutine returns:** `draw_frame` calls other drawing routines, and `draw_scoreboard` calls `draw_glyph` repeatedly. They save and restore `ra` around nested calls so that returning from a helper does not lose the caller's return address. `draw_paddle` and `draw_glyph` are leaf routines and return directly.

## Testing and troubleshooting

### Checks completed

The user reported that the game assembled and ran in RARS 1.6, with both paddles and the ball visible and keyboard controls working. They also reported that the ball moved too slowly, which led to lowering the delay count. Collision and scoring behavior were part of the implementation but have not been independently confirmed in the conversation.

The scoreboard was added afterward. An assembly attempt reported that `.byte` and `.asciz` cannot appear in the text segment. The glyph table and winner strings were then moved to data address `0x10012000`, beyond the framebuffer. The latest font was enlarged to 5 x 7 for clearer digits. These changes have not yet been reassembled or run in RARS, so scoreboard visibility and the latest source's successful assembly still need verification. The ready screen and P pause/resume controls also need a RARS run to verify.

### Troubleshooting

- **Blank or black display:** Check the Bitmap Display dimensions, unit size, and base address; press **Connect to Program** before running or rerun the program after connecting. The game draws the initial image by writing framebuffer memory during execution.
- **Keyboard does not respond:** Connect Keyboard and Display MMIO Simulator to the program that is running, focus its keyboard input area, and use W/S/I/K. The game accepts uppercase and lowercase input and reads one character per frame.
- **Ball moves too slowly:** Lower the countdown constant `16000` before `delay_loop`; increasing it slows the game. The software delay adds a wait on every frame.
- **Display jitters during play:** Normal gameplay now redraws only the old and new ball/paddle cells. If the display still flickers, confirm that the Bitmap Display is connected before the program starts and avoid changing its settings while the game is running.
- **Scoreboard is invisible:** Confirm the latest source assembled, that the Bitmap Display is connected at `0x10010000`, and that `draw_frame` calls `draw_scoreboard` after the clear. The glyph table is expected at `0x10012000`, outside the framebuffer. The scoreboard fix still requires a RARS run to verify.
- **Game seems frozen:** On the ready screen, press Space in the keyboard simulator. During play, P pauses and resumes; the screen displays `PAUSE` while paused.

## Limitations and future improvements

- Keyboard polling handles one character per frame; buffering or handling multiple queued inputs could make simultaneous/frequent controls smoother.
- There is no restart flow after a winner; the program exits when a player reaches five points.
- The game and its display/input are specific to RARS; hardware input and display support would need a separate implementation for a physical board.
