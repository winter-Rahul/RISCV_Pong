# RISC-V Pong

A two-player Pong game written in RISC-V assembly for the **RARS 1.6** simulator. It uses RARS's Bitmap Display for the court and Keyboard and Display MMIO Simulator for player input. It runs in the simulator; it is not configured for a physical RISC-V board.

## What you need

- Windows, macOS, or Linux
- Java to launch the included `rars1_6.jar`
- The RARS Bitmap Display and Keyboard and Display MMIO Simulator tools (included in the RARS application)

The main game source is [`src/main.s`](src/main.s). The project also includes a standalone keyboard-input example at [`tests/keyboardtest.s`](tests/keyboardtest.s); that example is not part of the Pong game. See [`TEAM_CONTRIBUTIONS.md`](TEAM_CONTRIBUTIONS.md) for a suggested three-person project split.

## Start the game

1. Download or clone this repository and open its project folder.
2. Launch RARS 1.6. For example, from a terminal in the project folder run:

   ```text
   java -jar rars1_6.jar
   ```

3. In RARS, open `src/main.s` and click **Assemble**.
4. Open **Tools > Bitmap Display** and set:
   - **Unit Width:** 16
   - **Unit Height:** 16
   - **Display Width:** 1024
   - **Display Height:** 512
   - **Base address for display:** `0x10010000 (static data)`
5. Click **Connect to Program** in the Bitmap Display.
6. Open **Tools > Keyboard and Display MMIO Simulator** and click **Connect to Program**.
7. Click **Run** in RARS. The court should show the ready screen.
8. Click the keyboard input area in the MMIO Simulator and press **Space** to start.

The display settings above make each of the game's 64-by-32 cells 16 screen pixels wide and high. You can use 8-by-8 units with a 512-by-256 display instead; keep the same base address and connect the display to the program.

## Controls

| Key | Action |
| --- | --- |
| `Space` | Start from the ready screen |
| `W` / `S` | Move the left paddle up / down |
| `I` / `K` | Move the right paddle up / down |
| `P` | Pause or resume |
| `Space` on the winner screen | Reset the scores and start a new match |

Uppercase and lowercase letters are accepted. Enter these keys in the **Keyboard and Display MMIO Simulator's input area**, not in the RARS console or source editor. The game reads one key per update, so if you type several keys quickly, it may take a few frames to process them.

## How to play

- Each paddle is eight cells tall. Move it to intercept the ball.
- The ball bounces off the top and bottom walls.
- A ball that reaches a paddle's column scores a hit if its row is within that paddle's span. Otherwise, the other player earns a point.
- After a point, the ball returns to the center for the next serve.
- The ball's pace increases gently every second point, up to a limit. It still moves one cell per game update so it does not skip over a paddle.
- The first player to **five points** wins. A winner banner appears and the game waits for **Space**.
- Press **Space** in the MMIO keyboard input area on the winner screen to reset both scores and start the next match. You do not need to close or relaunch RARS.

## Display and game layout

The logical court is 64 columns by 32 rows. The left paddle is at column 2 and the right paddle at column 61. The center divider is at column 32. The ball starts at `(31, 15)`.

The Bitmap Display framebuffer uses one 32-bit word per logical cell. The address for column `x`, row `y` is:

```text
0x10010000 + 4 * (y * 64 + x)
```

The program draws a full frame when the screen needs to be refreshed (for example, on start or reset). During play it redraws only the moving ball and paddles to reduce flicker. Scoreboard and status text are rendered using a small bitmap font.

## Troubleshooting

- **The display is blank:** Check the Bitmap Display base address and dimensions, connect it to the program, then run the assembled program.
- **Keys do nothing:** Confirm the Keyboard and Display MMIO Simulator says it is connected. Click its input area before typing.
- **The ball does not start moving:** The game waits on the ready screen until you press **Space** in the MMIO keyboard input area. Press **P** again if the pause label is showing.
- **The next match does not start:** On the winner screen, focus the MMIO keyboard input area and press **Space**. If you have changed the source, assemble and run the updated `src/main.s` before testing.
- **The display is too small:** Increase both unit dimensions and display dimensions by the same factor (for example, 16-by-16 units and a 1024-by-512 display). Keep the base address at `0x10010000`.

## Optional command-line assembly check

From the project folder, you can ask RARS to assemble the source without opening the GUI:

```text
java -jar rars1_6.jar a nc src/main.s
```

Use the GUI steps above to play; the command-line assembly check does not connect the Bitmap Display or keyboard.
