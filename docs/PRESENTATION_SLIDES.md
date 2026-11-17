# COURSE PROJECT PRESENTATION SLIDES (PPT OUTLINE)
**Course:** Microprocessors & Computer Architecture / RISC-V Architecture  
**Guideline Compliance:** Maximum 8 Slides | Strict "No Code in PPT" Policy  

---

### **SLIDE 1: TITLE SLIDE**
- **Title:** Design & Implementation of a Two-Player Pong Game in RISC-V Assembly Language (RV32I ALP)
- **Subtitle:** Hardware-Software Interfacing via Memory-Mapped I/O (MMIO) and Framebuffer Bitmap Graphics
- **Team Members (Max 3):**
  - Student 1: [Name] (SRN: [PES1UGXXXXX]) - *Game Loop, Input & State Management*
  - Student 2: [Name] (SRN: [PES1UGXXXXX]) - *Physics, Collision Mechanics & Scoring*
  - Student 3: [Name] (SRN: [PES1UGXXXXX]) - *Framebuffer Architecture, Text & Rendering*
- **Course Title & Code:** Microprocessors and Computer Architecture [Code: XXXX]
- **Course Instructor:** [Faculty Name, Department]
- **Institution:** [College Name / Department Logo]

---

### **SLIDE 2: INTRODUCTION & APPLICATIONS**
- **Project Motivation:**
  - Exploring bare-metal programming on the open-standard RISC-V (RV32I) ISA.
  - Interfacing directly with hardware abstractions without an Operating System (OS).
- **Key Objectives:**
  - Real-time interactive two-player gameplay at deterministic frame rates.
  - Low-latency asynchronous peripheral polling using Memory-Mapped I/O.
  - Direct pixel manipulation on a memory-mapped digital display framebuffer.
- **Real-World Applications:**
  - **Embedded Systems & Retro Consoles:** Ultra-low-overhead graphics for microcontrollers.
  - **FPGA Soft-Core Verification:** Serving as an interactive benchmark for synthesized RV32I cores.
  - **Industrial HMI Displays:** Low-overhead telemetry dashboards and input control loops.

---

### **SLIDE 3: SYSTEM ARCHITECTURE & TOOLS**
- **Hardware Simulation Tools (RARS 1.6):**
  - **Target Core:** RV32I Base Integer Instruction Set (32 general-purpose registers).
  - **Bitmap Display Tool:** Memory-Mapped Framebuffer at base address `0x10010000` (64×32 grid, 16×16 px units, 1024×512 resolution).
  - **Keyboard MMIO Simulator:** Control Register (`0xFFFF0000`), Data Register (`0xFFFF0004`).
- **Architectural Block Diagram:**
  - MMIO Keyboard Device $\rightarrow$ Polling Unit $\rightarrow$ State Engine $\rightarrow$ Physics & Bounds Calculation $\rightarrow$ Framebuffer Graphics RAM $\rightarrow$ Bitmap Display.
- **Register Allocation Strategy:**
  - Callee-saved registers (`s0`–`s11`) permanently pinned to critical game variables for maximum speed (zero memory thrashing during gameplay).

---

### **SLIDE 4: GAMEPLAY CONTROLS & FINITE STATE MACHINE (FSM)**
- **User Controls (Asynchronous Polling):**
  - **Player 1 (Left):** `W` (Up), `S` (Down)
  - **Player 2 (Right):** `I` (Up), `K` (Down)
  - **System Controls:** `Space` (Start / Instant Rematch), `P` (Pause / Resume)
- **Finite State Machine Flow:**
  - **State 0 (Ready Screen):** Display title banner and wait for `Space`.
  - **State 1 (Playing):** Execute physics, paddle bounds, ball trajectory, and redraws.
  - **State 2 (Paused):** Freeze physics updates, maintain screen buffer, display "PAUSE".
  - **State 3 / 4 (Winner State):** Triggered when either player reaches 5 points; display winner prompt; pressing `Space` restarts match.

---

### **SLIDE 5: PHYSICS, BOUNDS & SPEED PROGRESSION**
- **Paddle Motion & Bounds Clamping:**
  - Paddles are 8 cells high on a 32-row court.
  - Position strictly clamped to $[0, 24]$ to guarantee paddles never leave the court.
- **Ball Trajectory & Wall Reflections:**
  - Velocity vectors: $\Delta X = \pm 1$, $\Delta Y = \pm 1$.
  - Reflects vertically ($V_Y = -V_Y$) upon impinging top ($Y \le 0$) or bottom ($Y \ge 31$) walls.
- **Paddle Collision Geometry:**
  - Checks ball row against paddle span: $Top \le Ball\_Y < Top + 8$.
  - Successful hit: Reverses horizontal direction ($V_X = -V_X$).
  - Miss: Opponent awarded point, ball reset to center, and serve inverted.
- **Dynamic Speed Progression:**
  - Pacing automatically quickens every 2 total points scored (capped at tier 3).

---

### **SLIDE 6: GRAPHICS ENGINE & BITMAP TYPOGRAPHY**
- **Framebuffer Organization:**
  - Row-major memory layout: $\text{Address} = \text{Base} + 4 \times (Y \times 64 + X)$.
  - 32-bit RGB color palette: Turf Green, Deep Blue Paddles, Bright Orange Ball, Pitch Black Net.
- **Incremental Dynamic Rendering (Zero-Flicker):**
  - Full refresh is executed **only** during state transitions (Ready / Reset).
  - Normal gameplay updates **only** erase previous moving coordinates (paddles and ball) and draw current ones ($<20$ memory writes vs. 2,048 writes).
- **Custom 5×7 Monospaced Font Engine:**
  - Built-in character generator stored in data segment (`glyph_rows`).
  - Bit-serial unpacker renders scores, "PRESS START SPACE", "PAUSE", and "WINS".

---

### **SLIDE 7: KEY TECHNICAL MODIFICATIONS & OPTIMIZATIONS**
- **1. Elimination of Display Flicker:**
  - Replaced naive 2,048-word full-frame clearing with dirty-rectangle incremental erasure, cutting memory traffic by **99.1%**.
- **2. Net/Divider Dash Reconstruction Heuristic:**
  - Erasing the ball across the central dashed divider previously left blank holes; added bitwise modulo logic ($Y \pmod 4 < 2$) to automatically reconstruct black net dashes.
- **3. Temporal Speed Scaling vs. Spatial Teleportation:**
  - Rather than increasing coordinate step sizes (which causes collision skipping), speed is scaled via software timing loops while keeping spatial steps at 1 cell.
- **4. Stack Frame Integrity for Rematch Support:**
  - Preserved return addresses (`ra`) across nested subroutines on the stack, enabling seamless rematches without simulator crashes or manual resets.

---

### **SLIDE 8: RESULTS, DEMONSTRATION & CONCLUSION**
- **Implementation Outcomes:**
  - 100% pure RV32I Assembly Language implementation (~660 lines, ~1.8 KB binary footprint).
  - Fully functional 2-player interactive game meeting all academic ALP guidelines.
  - Verified and validated under RARS 1.6 with zero assembly warnings or errors.
- **Live Demo Checklist:**
  - [x] Initial boot and ready screen with custom bitmap font.
  - [x] Responsive simultaneous paddle control via MMIO.
  - [x] Top/bottom bounces and paddle reflections.
  - [x] Real-time scoreboard tracking and speed progression.
  - [x] First-to-5 win banner and instant spacebar rematch.
- **Conclusion:**
  - Successfully demonstrated that high-performance, real-time graphical applications can be built directly on bare-metal RISC-V hardware architectures.
