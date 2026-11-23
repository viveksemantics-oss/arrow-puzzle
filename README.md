# Arrow Maze

A commercial-quality, deeply engaging mobile logic puzzle game built with Flutter and Dart that runs seamlessly on both **Android** and **iOS** from a single codebase.

---

## 🎯 1. Core Game Mechanics

- **Snake-Like Polylines:** Each arrow is a continuous winding snake made of connected cells (length 2 to 40+ cells) with several 90° bends (L-shapes, U-turns, zigzags, and spirals), drawn as a thick rounded vector line with a sharp geometric arrowhead at its head.
- **Clear Exit Ray Rule:** When an arrow is tapped, the engine inspects the straight ray extending in front of the head to the board's edge.
  - **Free to Exit:** If no other arrow occupies any cell along that ray, the arrow slithers forward like a snake (the head leads out of the board, the body follows along its exact polyline path, and it disappears off-screen).
  - **Blocked Feedback:** If any cell is occupied, the arrow shakes with haptic vibration, flashes the blocking arrow in vibrant red, and the player **loses 1 life (heart)**.
- **Lives & Failure:** Players start each level with 3 hearts. Losing all hearts fails the level and triggers the Game Over dialog (Retry / Watch Ad for +1 Life).
- **Goal:** Unravel the maze and remove every snake arrow from the board.

---

## 🧠 2. Procedural Level Generator & Solvability Guarantee

The game features an infinite procedural generator supporting **10,000+ unique, dense, and interlocking labyrinth levels**, without any hard-coded level files.

### Solvability Algorithm (Reverse Construction)
1. **Procedural Silhouette Masks:** Playable cells are rasterized from procedural silhouette shapes:
   - *Beginner (1-25):* Square grids (8×8 to 12×12)
   - *Easy (26-60):* Iconic silhouettes including **Trophy Cup**, **Anchor**, **Chess Knight**, **Heart** (12×12 to 16×16)
   - *Medium (61-150):* Intricate shapes including **Puppy Dog**, **Butterfly**, **Star**, **Diamond**, **Pine Tree**, **House** (18×18 to 26×26)
   - *Hard (151-300):* Dense maze silhouettes (28×28 to 38×38)
   - *Expert (301-10,000+):* Massive complex labyrinths (40×40 to 50×50, 300+ arrows)
2. **Reverse Topological Placement:**
   - Starts with an empty board.
   - Generates random self-avoiding walks with a strong weighted preference for 90° turns to form winding snake bodies.
   - Evaluates path endpoints to place the head pointing in a direction whose straight exit ray to the board edge does **not** intersect any already-placed arrow cells.
   - Because earlier reverse arrows correspond to the *last* arrows cleared in forward gameplay, each newly placed arrow is guaranteed to have a completely unobstructed exit ray when its turn comes.
   - Leftover cells are merged into neighboring paths to ensure $\ge 90-95\%$ board coverage.
3. **Automated Solver Verification:**
   - Every generated level is verified using `PuzzleSolver.solve()`.
   - The greedy topological solver extracts the complete forward solution order used for the intelligent **Hint** feature.
   - Rejects levels with $> 38\%$ arrows free at the start for levels $> 20$ to maintain deep dependency chains.
4. **Deterministic Reproducibility:**
   - Uses seeded random generators `Random(levelNumber * 10007 + 7919)` so Level $N$ is 100% identical on every device worldwide.
   - Generated levels are cached in memory and computed asynchronously via `compute` isolates so the UI never drops frames.

---

## 🎨 3. UI, Themes & Rendering Performance

- **Dual Color Themes:**
  - **Classic Obsidian (#F7F8FA):** Minimalist white card with dark charcoal/navy ink arrows.
  - **Eye Comfort Paper (#F6EEDF):** Warm cream paper background with dark espresso/sepia ink arrows, designed for relaxed evening play. Switchable with one tap via the palette icon.
- **True Snake Slithering Animation:**
  - Parametric continuous interpolation along the extended polyline trajectory.
  - The head leads the movement while body segments follow precisely along existing bends.
- **InteractiveViewer (Zoom & Pan):**
  - Smooth pinch-to-zoom (0.8x to 4.0x) and pan for navigating large 40×40+ boards.
  - Zoom-aware Euclidean distance hit testing ensures effortless, accurate taps on small mobile touchscreens.
- **Layout (Matching Design Specifications):**
  - **Top Bar:** Circular pause button, Level Title + Tier badge pill (`BEGINNER`, `EASY`, `MEDIUM`, `HARD`, `EXPERT`), Stopwatch Timer pill.
  - **Status Row:** Remaining arrow counter, Percent cleared, Thin animated progress bar.
  - **Lives:** 3 Hearts row (hearts turn grey when lost).
  - **Center:** Rounded card board with subtle dot grid.
  - **Bottom Bar:** 3 action buttons: Undo, Hint (with live count badge), and Restart.

---

## 📱 4. Platforms & Build Instructions

### Android Build
```powershell
# Set Java and Android SDK environment variables
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME = "C:\Users\vivek.kumar2\AppData\Local\Android\sdk"
$env:PATH = "F:\flutter\bin;$env:JAVA_HOME\bin;$env:PATH"

# Build Release APK
cd android
.\gradlew.bat assembleRelease

# Build Google Play App Bundle (AAB)
.\gradlew.bat bundleRelease
```
Compiled deliverables:
- **Direct Sideload APK:** `ArrowMaze.apk` (62.2 MB)
- **Google Play Bundle:** `ArrowMaze.aab` (61.3 MB)

### iOS Build (macOS / Codemagic)
1. **Clone repository on macOS:**
   ```bash
   git clone https://github.com/your-repo/ArrowMaze.git
   cd ArrowMaze
   flutter pub get
   ```
2. **Pod Installation:**
   ```bash
   cd ios
   pod install
   cd ..
   ```
3. **Build unsigned Release IPA:**
   ```bash
   flutter build ipa --release --no-codesign
   ```
4. **Xcode Archive:**
   Open `ios/Runner.xcworkspace` in Xcode, select your Apple Developer Team, configure App ID (`com.arrowmaze.game`), and click **Product > Archive > Distribute App**.

---

## 🧪 5. Testing & Verification

Run the comprehensive automated test suite:
```bash
# Analyze codebase (0 issues)
flutter analyze

# Run unit tests and procedural verification of 200 sample levels across all 5 tiers
flutter test
```
- **Static Analysis:** `flutter analyze` reported **0 issues found**.
- **Unit & Widget Tests:** **26 / 26 tests passed**.
  - `Procedural Level Generator - 200 Sample Levels Across All Tiers Verifies that all 200 sample levels across all 5 tiers are 100% solvable` (PASSED).
  - `Core Verification: Levels 1, 24, 100, and 300 Load, Render, and Solve` (PASSED).
  - `Deterministic repeatability: Level N produces identical output across calls` (PASSED).
  - `MainMenuScreen`, `LevelSelectScreen`, `StatisticsScreen`, `DailyChallengeScreen` (PASSED).
