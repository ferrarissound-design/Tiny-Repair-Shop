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

Each item has multiple hidden fault paths, so the same device can require a different repair.

## Roblox-first design

- Runtime code is **Luau**.
- Rojo-managed source tree.
- Touch, controller, and keyboard friendly.
- Server-validated customer offer selection with up to three unlocked jobs at once.
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
\`\`\`

## Progression

- Reputation 0: Desk Fan
- Reputation 2: Portable Radio
- Reputation 5: Toy Car
- Reputation 9: Game Controller

Perfect repairs receive the highest quality bonus. One mistake still gets a smaller bonus; additional mistakes simply reduce quality.

### Tool upgrades

The Tool Cabinet provides a persistent cash sink:

- Level 1: $150
- Level 2: $400
- Level 3: $900

Each level slightly widens skill-check success zones. This makes money useful beyond being a scoreboard number and gives the workshop a light long-term progression loop.

## Good next steps

- Workshop upgrades and decoration
- Customer personalities and repeat customers
- Physical tool animations and sound feedback
- Repair collection shelf
- Daily/rare jobs and mystery devices
- More device families
- Multiplayer workbench roles
