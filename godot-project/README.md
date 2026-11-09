# Dijah's Delights Candy Run

A finished 3D candy runner game for Dijah, built with **Godot 4.2+**.
Dijah runs away from the camera down a floating candy track over a syrup
sea — dodge the holes, grab the sugar stars, beat all 20 boards.

- **20 boards**, each with its own look, objective, and obstacle
  (Candyland, Chocolate World, Gummy Jungle, Neon Night, … Sugar Rush Finale)
- **Dijah** as the hero — braids, teal top, candy sneakers, built from
  Godot primitives (no model files, no photo imports)
- **Touch only**: swipe left/right to steer, tap to jump
- **3 hearts** per run — fall 3 times and it's game over
- **Power-ups**: Speed Boost, Shield, Magnet, 2x Score, and the green
  sour-face **Sour Star** (dodge it — it slows you down and breaks your streak)
- **Sugar Rush** streaks, near-miss bonuses, star bursts, confetti on a new best
- **Roadmap map** — boards stay locked until you beat the one before
- **Outfit shop** — spend sugar stars on new looks for Dijah
- **Music matches the board** — a fresh procedural tune per board, with a mute button
- **No blue anywhere** — cherry red and candy colors only

## Play it on Android

1. Go to the repo's **Releases** page (or the Actions tab → latest run →
   `dijah-dash-apk` artifact) and download `dijah-dash.apk`.
2. On the phone, open the APK in Chrome/Downloads and tap **Install**.
   If the phone asks, allow **"Install unknown apps"** for Chrome — this
   is a normal sideload, the APK is built from this source.
3. Open **Dijah's Delights Candy Run** and play. Progress, best scores, stars, and outfits
   are saved on the phone.

## Build it yourself (Godot 4.2)

1. Install **Godot 4.2** (or newer 4.x) from https://godotengine.org
   and the **Android export templates** (Editor → Manage Export Templates).
2. Open this folder (`godot-project/`) in Godot.
3. Generate a debug keystore once (the export preset expects it):
   ```
   cd godot-project
   keytool -keyalg RSA -genkeypair -alias androiddebugkey \
     -keypass android -keystore debug.keystore -storepass android \
     -dname "CN=Android Debug,O=Android,C=US" -validity 9999 \
     -deststoretype pkcs12
   ```
4. Project → Export → **Android** → Export Project (debug APK),
   or from the command line:
   ```
   godot --headless --import --path godot-project
   godot --headless --path godot-project --export-debug "Android" dijah-dash.apk
   ```
5. To run on desktop for testing: press **F5** in the editor
   (arrow keys steer, Space jumps — touch works on a real phone).

## How the cloud build works

`.github/workflows/android.yml` runs on every push to `main` and on
version tags (`v1.0.0`, …):

- Uses the `barichello/godot-ci:4.2` image (Godot + export templates).
- Generates a debug keystore, imports the project, exports the debug APK.
- Uploads the APK as a build artifact on every run.
- On a tag push, publishes a **GitHub Release** with the APK attached.

No secrets are needed — the release uses the automatic `GITHUB_TOKEN`.

## Project layout

```
godot-project/
  project.godot            portrait 720x1280, stretch canvas_items, touch on
  export_presets.cfg       Android export preset (arm64, debug APK)
  icon.svg                 app icon
  scenes/                  main_menu / roadmap / shop / game (.tscn, thin shells)
  scripts/
    boards.gd              all 20 boards: palette, objective, obstacle, music
    save_manager.gd        JSON save: unlocks, bests, stars, outfits, mute
    music_manager.gd       procedural per-board music + SFX (generated WAVs)
    dijah_character.gd     Dijah from primitives + run/jump animation + outfits
    track_builder.gd       endless waffle track, holes, stars, scenery
    obstacle.gd            all 20 obstacle variants + collision checks
    star.gd                sugar stars (normal / big / rainbow) + pink ring
    powerup.gd             speed / shield / magnet / 2x / sour star
    hud.gd                 score panels, hearts, messages, end panels, speed lines
    game.gd                gameplay: steering, jumping, hearts, objectives, juice
    main_menu.gd roadmap.gd shop.gd
  .github/workflows/android.yml
```

## Known limits

- The game has never been play-tested on a real phone yet — first APK
  run is the real test. If something feels off (speed, jump, a board
  being too hard), report what happened on the phone and it gets fixed.
- Music is procedural chiptune generated in code, not recorded tracks.
