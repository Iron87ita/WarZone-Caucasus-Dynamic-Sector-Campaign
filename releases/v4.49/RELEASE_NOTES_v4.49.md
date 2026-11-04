# WarZone Caucasus v4.49 – Friendly Escorts, AI Combat & SEAD / Bingo RTB Fixes

Released on 2026-11-04. Created by IRON87ITA.

## Download and install

Download **WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_49.miz** from this release, stop the current mission/server, load the new mission and restart. Back up the campaign persistence file and retain the compatible save. No save-format migration is introduced by these changes.

This release uses the author's supplied V4.49 mission. Its Mission Editor changes, mission table, warehouses and other assets are preserved; only the briefing/version labels and activity-module version metadata are aligned to 4.49 before publication.

## Friendly escorts and enemy interception

- **Friendly AI:** accept escort/protection tasks for live friendly CAP, BARCAP, CAS, SEAD, AWACS, tanker, reconnaissance and transport flights, including helicopters.
- Standard escort requires five minutes airborne within 5 NM. Every aircraft alive in the protected group at acceptance must survive.
- Cargo escorts require confirmed delivery, at least 60 seconds nearby and presence within escort range at delivery. Failed delivery or aircraft loss does not award completion.
- **Enemy AI:** retain intercept/attack tasks against live opposing aircraft, ground groups, defenses and ships. Destroy every unit; task bonuses require a credited kill in the assigned player group.
- A live AI group can simultaneously have one friendly escort and one opposing intercept. Assignments, tracks and rewards are coalition-separated. Each player group can hold one AI task.
- F10 lists and assigned-group tracks refresh every 30 seconds. Personal task bonuses remain pending until safe RTB. Completed escorts cannot be repeated on the same flight.

## Simpler F10 menu

`F10 > WARZONE MISSIONS` has six main entries:

1. Current task / F10 track
2. Cancel task
3. Friendly AI
4. Enemy AI
5. Sector missions
6. Reports / help

AI status, operations tempo, reinforcement requests and column controls are under **Friendly AI > Operations**. Flight and target catalogs appear directly in their AI menus and use five items per page. Existing CAP, BARCAP, CAS, SEAD and STRIKE player missions remain under Sector missions.

## Actual AI combat tasking

- Combat dispatchers receive a route and role-specific tasks for their assigned operational area after takeoff. They no longer rely on the template's original route to match campaign metadata.
- CAP/BARCAP receive airborne search/interception tasks. CAS receives ground-attack tasks for the selected operational area. Targeting follows changes in sector ownership.
- Explicit engagement/radar settings replace inherited restrictions. HOT parking departures are retained; periodic checks preserve an ongoing attack rather than restarting it.
- The supplied author's V4.49 RED CAP templates use JF-17 aircraft. These Mission Editor selections and their loadouts are preserved, together with the existing compatible legacy-template cleanup.

## SEAD direct attacks and compatible weapons

- SEAD directly attacks individual defense units using **AttackUnit**, prioritizing SAM search/tracking radars and EWR units. New SEAD launches require a live defense objective in an unlocked enemy operational area.
- Dispatched F-16s carry AGM-88 plus AGM-65 missiles. Dispatched Su-34s carry Kh-31P plus Kh-29T missiles. Fuel tanks and defensive air-to-air weapons are retained.
- Emitting radars receive ARM attacks. Silent radars and non-radar defenses receive attacks using compatible guided ground weapons.
- An ongoing attack is preserved. Destroying a target advances to the next live objective. Stalled attempts are limited to three minutes after entering weapon range, with at most two attempts per target. Radar silence triggers weapon reconsideration.
- Clearing objectives, expending compatible weapons, exhausting attempts or reaching the sortie deadline orders RTB instead of an indefinite orbit.

## Explicit nearest-base bingo RTB

- Every combat flight monitors every living airborne aircraft. The lowest-fuel aircraft triggers group RTB at **30% internal fuel**, or earlier when measured consumption requires more return/approach reserve.
- RTB cancels attack and orbit orders and assigns an explicit approach/landing route to the **nearest currently friendly airport from the flight's position**. The departure airbase has no preference.
- Both DCS coalition and campaign ownership are checked. FARPs and carriers are excluded for these fixed-wing flights.
- RTB remains active for the rest of the sortie. New targets cannot reactivate an attack. A captured landing base causes diversion to another friendly runway.
- English notifications report the return reason and selected airbase.

## Briefings, compatibility and scope

The general, NATO and RF briefings describe the updated tasks and fuel procedures in English. Version labels now identify **V4.49**. Existing persistence filenames and schemas are retained. AI task claims and tempo settings remain session-specific.

Web Command Center files on `main` remain separate source integrations; this release does not add those modules to the playable mission.

## Validation

- ZIP integrity and archive-entry checks passed.
- 22 embedded Lua scripts/mission tables compile with DCS Lua 5.1.
- **49 simulated scenarios passed against this release copy:** 14 activity/escort tests and 35 combat/SEAD/fuel tests.
- The supplied mission table, warehouses and other resources are preserved. Only version/briefing metadata differs from the author's input.
- SHA-256 checksums are supplied for the downloadable package.

These checks verify code and decisions with simulated DCS APIs. Live weapon employment, taxiing, landing and server performance still require an in-simulator session; automated checks are not proof of live combat success.

Mission SHA-256: `b477889a910921443864d11966b8c06131bdd43ee1134dec824e479f8b63079c`.

See the [player guide](https://github.com/Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign/blob/main/docs/AI_CONTROL_AND_TASKS.md) and [changelog](https://github.com/Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign/blob/main/CHANGELOG.md).
