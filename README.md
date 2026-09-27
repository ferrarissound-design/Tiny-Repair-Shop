# Tiny Repair Shop 🔧

A cozy Roblox repair-shop game built in **Luau** and managed with **Rojo**.

## Current playable loop

1. Walk to the customer at the front counter.
2. Open the customer's repair offers and choose which job to take.
3. Go to the workbench.
4. Inspect the broken item to reveal its hidden fault.
5. Perform repair actions.
6. For hands-on steps, stop the timing needle inside the target zone.
7. Mistakes lower repair quality but do not brick the job: retry the step.
8. Test the repaired item.
9. Earn cash, reputation, rare-find bonuses, and a quality bonus.
10. Reputation unlocks more complicated devices.
11. Spend cash at the Tool Cabinet to permanently upgrade your tools.
12. Better tools widen timing windows, making precise repairs more forgiving.

Current repair families:

- Desk fan
- Portable radio
- Toy car
- Game controller
- Alarm clock
- Instant camera

Each item has multiple hidden fault paths, so the same device can require a different repair.

Customer offers now also have personalities and repair modifiers. A normal fan repair can arrive as a rush job, a precious keepsake, or a precision order. Special orders change timing difficulty and payout instead of being cosmetic labels.

At Reputation 5+, a live-server offer board has an 8% chance to contain one **Odd Job**. Roblox Studio uses 35% to make testing practical. Odd Jobs are rare story-flavored repairs with higher payouts, slightly tougher timing, a subtle visual glow, and their own persistent completion counter. Closing and reopening the offer board does not reroll the same set of jobs.

## Roblox-first design

- Runtime code is **Luau**.
- Rojo-managed source tree.
- Touch, controller, and keyboard friendly.
- Server-validated customer offer selection with up to three unlocked jobs at once.
- Six customer personalities and weighted special-order modifiers.
- Perfect-repair streaks that add a capped cash bonus for consistent zero-mistake work.
- Rare Odd Jobs with persistent completion tracking and cached offer rolls.
- Repair prompts use Roblox \`ProximityPrompt\`.
- Timing minigame uses a large touch-friendly button.
- Server-authoritative repair progress, minigame judging, and rewards.
- English by default; Japanese HUD text is selected automatically for \`ja\` Roblox locales.
- Workshop and device models are generated from Roblox primitives, so no external asset setup is required for the prototype.
- Cash and reputation persist through DataStore when API access is available.

## Rojo

From the repository folder:

\`\`\`powershell
rojo serve
\`\`\`

Connect Roblox Studio with the Rojo plugin and sync:

\`\`\`
default.project.json
\`\`\`

Then press **Play**. The server generates the workshop automatically.

## Structure

\`\`\`
src/
  client/
    TinyRepairShop.client.luau
  server/
    TinyRepairShop.server.luau
  shared/
    Localization.luau
    RepairCatalog.luau
    ShopFlavor.luau
\`\`\`

## Progression

- Reputation 0: Desk Fan
- Reputation 2: Portable Radio
- Reputation 5: Toy Car
- Reputation 9: Game Controller
- Reputation 13: Alarm Clock
- Reputation 18: Instant Camera

### Odd Jobs

Odd Jobs never appear in the normal unlocked-job pool. Starting at Reputation 5, the server can replace one offer with a rare repair:

- **Midnight Radio** — a radio that still tunes itself after the batteries are removed.
- **Laughing Toy Car** — a toy car that rolls toward closed doors and laughs.
- **Blank Photo Camera** — a camera whose blank photos keep showing an uninvited silhouette.

Odd Jobs use the dedicated Odd Job modifier and increment a persistent `OddJobs` stat when completed.

Each unique Odd Job also unlocks a permanent entry in the player's **Curiosities shelf** at the back of the workshop. Undiscovered slots show `???`; discovered jobs display a miniature of the repaired item and a localized name plaque. The shelf contents are rendered locally, so each player sees their own collection even in multiplayer. Completing all three current oddities adds a collection-complete badge to the shelf.

Discovered curiosities now have rare ambient events while the player is near the shelf: the Midnight Radio's dial turns and its glow pulses, the Laughing Toy Car quietly shifts on the shelf, and the Blank Photo Camera flashes by itself. Live play waits roughly 38–72 seconds between event attempts; Studio uses 10–20 seconds for easier testing. Events are suppressed while the repair-offer picker or timing minigame is open.

Perfect repairs receive the highest quality bonus. One mistake still gets a smaller bonus; additional mistakes simply reduce quality.

Zero-mistake repairs also build a session perfect streak. Each level adds a small cash bonus, capped so the streak feels valuable without overpowering job choice. Special orders can add their own perfect-work premium.

### Tool upgrades

The Tool Cabinet provides a persistent cash sink:

- Level 1: $150
- Level 2: $400
- Level 3: $900

Each level slightly widens skill-check success zones. This makes money useful beyond being a scoreboard number and gives the workshop a light long-term progression loop.

## Good next steps

- Workshop upgrades and decoration
- Repeat-customer story arcs
- Physical tool animations and sound feedback
- Repair collection shelf
- Odd Job follow-up story arcs
- More Curiosities shelf entries and ambient behaviors as new oddities are added
- Workshop upgrades and visible trophies
- Multiplayer workbench roles
