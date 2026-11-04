# WarZone Caucasus v4.49 – Friendly Escorts, AI Combat & SEAD / Bingo RTB Fixes

Released on 2026-11-04. Created by IRON87ITA.

## CAP / supply hotfix — replacement build (2026-11-04)

This replaces the previous v4.49 download under the same mission filename and release URL.

- Prioritize CAP dispatchers at friendly airfields near the assigned front, preventing distant western bases from consuming every shared CAP slot before northern bases are processed.
- Add a short retry delay when compatible parking is unavailable.
- Set the intended coalition and country explicitly for spawned combat and cargo aircraft.
- Validate cargo destination ownership before launch, before routing and throughout the flight. Supply aircraft serve friendly active, unlocked zones; capture aircraft serve eligible adjacent neutral zones.
- Cancel cargo flights if their destination becomes ineligible or their actual coalition differs from the requested coalition. Cargo origins must also be friendly in DCS.

The corrected CAP_SUPPLY_FIX mission is copied byte-for-byte to the standard v4.49 download filename. Only essential syntax, cargo-coalition guard and archive-integrity checks were performed for this hotfix; the previous 49-scenario suite was not rerun.

## Download and install

Download **WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_49.miz** from this release, stop the current mission/server, load the new mission and restart. Back up the campaign persistence file and retain the compatible save. No save-format migration is introduced by these changes.

This release uses the author's supplied V4.49 mission with the CAP/supply hotfix. The corrected mission is published unchanged under the standard release filename.

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

The general, NATO and RF briefings describe the updated tasks and fuel procedures in English. The release remains **v4.49**. Existing persistence filenames and schemas are retained. AI task claims and tempo settings remain session-specific.

Web Command Center files on `main` remain separate source integrations; this release does not add those modules to the playable mission.

## Validation

The original v4.49 base passed 49 simulated scenarios and compilation of its embedded Lua resources. Those broader checks were not rerun for this targeted hotfix. This revision passed the essential campaign syntax, cargo coalition-guard and ZIP-integrity checks. The downloadable mission matches the selected CAP_SUPPLY_FIX artifact byte-for-byte. Live behavior still requires validation inside DCS.

Current mission SHA-256: `c87a6321ef66070cdb4c5d44fa3ffd211b9bbe86b124dc97270fd1c87b1eda65`.
