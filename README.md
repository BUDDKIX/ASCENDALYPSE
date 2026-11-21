# ASCENDALYPSE

A 2D pixel-art precision platformer inspired by *Jump King*. **Playable now: the prologue and Floor 0.**

Two hundred years after humanity vanished, lightning strikes the antenna on Floor 10. The surge follows the wiring down to a generator on Floor 0. Beside it, a moss-covered service robot wakes up, still tethered to the machine. His creator is slumped at the workbench. When the bones begin to move, the Unit has to reckon with the one instruction his creator left him: “Never harm a human.”

## Inside the demo

1. **The Spark.** Watch the surge reach the generator. When the red bar shakes, tap Space eight times or hold both controller triggers (L2 + R2) to pull the cable free. After the explosion, wait for the title and press Space again to play.
2. **The Directive & the Mutation.** Inspect the Maker at his workbench. His first lunge gives you a reason to break the Unit’s oldest rule. Land six crescent strikes to open the gate. Two enemy hits knock a part loose; wait out the five-second countdown before picking it up.
3. **The Floodway.** Cross 32 jumps above the water. Touch the cyan beacon on landing 18 to set your checkpoint. If you fall, the Unit returns to the checkpoint, but the missing part stays on the last safe landing. Powering up the lift ends the demo.

## BOUNCE BACK

The jam theme is **BOUNCE BACK**. The Unit comes back to life after two centuries without power. His spring jump turns that idea into something you can feel: hold a charge on a narrow landing, aim, then let go. Miss the landing over water and you can return for the part you lost. The harder recovery is the Unit’s own: how can a machine built to protect people fight the remains of the person who built him?

## Who inhabits the tower?

- **The Unit** was built for domestic and maintenance work. Rust and moss cover his casing. His dialogue is designed around small bubbles: an icon, a code fragment, a few words.
- **The Creator**, called **the Maker** in the demo, is the engineer whose skeleton rests on Floor 0. Parasitic moss animates his remains. The encounter puts the Unit’s directive in conflict with his survival.
- **The Overgrown** are the planned enemies of the upper tower. Fungi and roots bind bones to discarded machinery; some creatures will guard parts of the lift.

## Controls

| Input | Action |
| --- | --- |
| Left / Right | Walk and steer in the air |
| Hold Space, then release | Charge and spring-jump |
| R | Cancel a charge |
| F | Inspect the Maker or activate the lift |
| Space | Continue from the title or dismiss dialogue |
| X | Crescent attack; allow half a second between strikes |
| E | Return to the active checkpoint |
| Q after battery loss | Start a fresh run |

## Beyond the demo: story roadmap (spoilers)

**Act II · The Ascent (Floors 1–9).** The plan is to climb the broken lift shaft floor by floor, recovering lift components guarded by the Overgrown. These are separate from the Unit’s own recoverable parts on Floor 0. Higher platforms give way to exposed steel and rain; a missed jump can cost part of the climb.

**Act III · The Guardian & the Sky (Floors 9–10).** An apex Overgrown guards the last lift mechanism on Floor 9. Beyond it lies the open terrace. The planned ending has no further fight: the storm clears, and the Unit steps outside under his own power.

## Art and sound direction

Floor 0 uses wet concrete, rust and deep moss greens so the Unit’s eyes, lightning and checkpoint light stand out. For the ascent, the proposed art plan groups the tower into three zones: flooded basement and lobby (0–3), overgrown offices (4–7), and storm-battered penthouse and terrace (8–10). More daylight would reach each successive zone. Sound and haptic targets include a rising generator hum, trigger rumble and a cut to silence at detonation, with small mechanical whirs and synth chirps in place of voiced dialogue. These are production targets, not promised features of this build.

## Run from source

Open `project.godot` in Godot 4.7.2 and press F5. For a browser build, export the **Web** preset as `index.html`. The opening scene is in `opening/`, robot movement and damage stages in `movement/`, and the integrity display in `hud/`. See [the project description](projects%20description.txt) for mechanics and asset notes.
