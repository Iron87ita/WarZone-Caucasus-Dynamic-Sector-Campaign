# WarZone Caucasus v4.49 – AI Control, Escorts and Intercepts

Open `WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_49.miz` in DCS. Menus, task briefings and notifications are in English.

## CAP / supply hotfix — replacement build (2026-11-04)

This replaces the previous v4.49 download under the same mission filename and release URL.

- Prioritize CAP dispatchers at friendly airfields near the assigned front, preventing distant western bases from consuming every shared CAP slot before northern bases are processed.
- Add a short retry delay when compatible parking is unavailable.
- Set the intended coalition and country explicitly for spawned combat and cargo aircraft.
- Validate cargo destination ownership before launch, before routing and throughout the flight. Supply aircraft serve friendly active, unlocked zones; capture aircraft serve eligible adjacent neutral zones.
- Cancel cargo flights if their destination becomes ineligible or their actual coalition differs from the requested coalition. Cargo origins must also be friendly in DCS.

The corrected CAP_SUPPLY_FIX mission is copied byte-for-byte to the standard v4.49 download filename. Only essential syntax, cargo-coalition guard and archive-integrity checks were performed for this hotfix; the previous 49-scenario suite was not rerun.

## F10 quick start

Open **F10 > WARZONE MISSIONS**:

| Entry | Purpose |
| --- | --- |
| Current task / F10 track | Current AI task, live tracking and active sector tasking |
| Cancel task | Release the AI task or sector mission separately |
| Friendly AI | Read a friendly flight briefing and accept an escort |
| Enemy AI | Read an enemy-group briefing and accept an intercept/attack |
| Sector missions | Random mission, CAP, BARCAP, CAS, SEAD and STRIKE |
| Reports / help | Aircraft roster, naval threats and the AI task guide |

Lists appear directly in Friendly AI and Enemy AI. They refresh every 30 seconds, provide a manual refresh command and use five entries per page.

## Escort tasks

For an ordinary friendly flight, accept **Escort** and accumulate five minutes airborne within 5 NM of a protected aircraft. Altitude separation counts. Time outside range or on the ground does not count. Every aircraft alive in the protected group when accepted must survive.

Cargo escort instead requires confirmed capture, supply or map-marker delivery, at least 60 seconds of nearby airborne escort and presence within range at delivery. Failed or invalid delivery, aircraft loss and withdrawal do not complete the escort.

Each participating pilot must individually accumulate the required escort time for a bonus. The bonus remains pending until safe RTB. A completed escort cannot be repeated on the same AI flight.

## Enemy intercept/attack tasks

Accept a live enemy group and destroy all of its units. Aircraft, convoys, defenses and ships remain eligible. A task bonus requires at least one credited player kill in the assigned group; other-forces-only kills do not award that bonus. Withdrawal, despawn and successful enemy cargo delivery do not count as destruction. Redeem pending credits through safe RTB.

There is one AI task per player group. A live AI group can have one friendly escort and one opposing interception assignment at the same time. Claims, map markers and rewards are separate. Disconnecting or starting a new life releases the old task. AI tasks can coexist with sector tasking.

## Friendly AI operations

**Friendly AI > Operations** provides status/current limits, operations tempo, AI reinforcement requests and halt/resume controls for campaign columns. Each coalition controls its own forces. AUTO, LOW, NORMAL, HIGH, OFFENSIVE and NEW LAUNCHES PAUSED remain available. Requests obey ownership, sector access, traffic limits and parking checks. An empty server suspends new launches; pausing does not stop groups already in action.

AUTO limits per coalition:

| Total human players | Combat flights | Ground columns |
| --- | ---: | ---: |
| 1–2 | 3 | 2 |
| 3–4 | 4 | 3 |
| 5–6 | 6 | 3 |
| 7+ | 8 | 4 |

Up to one AWACS and two tankers are available in addition. Zone defenses retain their operational strength. Manual LOW/NORMAL/HIGH/OFFENSIVE limits remain 2/1, 4/2, 6/3 and 8/4 combat flights/columns, subject to campaign conditions.

## What the AI does

CAP and BARCAP patrol/intercept airborne threats. CAS attacks ground formations in its assigned operational area. Combat tasks are installed after takeoff and run automatically, regardless of whether a player accepts an escort/intercept task.

SEAD receives direct attacks against individual defense units, with radar units first. Mixed ARM and guided ground-attack loads permit attacks on emitting radars, silent radars and non-radar defenses. The controller changes target after destruction, uses bounded retries and returns when objectives, compatible weapons or attack attempts are exhausted. It does not rely on an indefinite search orbit.

Combat flights check the lowest fuel among their living airborne aircraft. **Bingo is 30% internal fuel**, or earlier if measured consumption requires a larger return reserve. Bingo overrides attack orders with a landing route to the **nearest currently friendly airport**, without favoring the departure base. RTB stays active despite new targets. If the runway is captured, the flight diverts to another friendly airport.

## Updating and verification

Restart the mission after replacing the `.miz`; running sorties do not receive code changes from a file replacement. Keep a backup of the compatible campaign save. No persistence filename/schema migration is introduced.

The original release base passed DCS Lua 5.1 compilation and 49 simulated scenarios. This targeted CAP/supply replacement received only essential syntax, cargo-coalition guard and archive checks; the full suite was not rerun. Live aircraft behavior and landing still require validation inside DCS. See the v4.49 release notes and validation report for the exact verification scope.
