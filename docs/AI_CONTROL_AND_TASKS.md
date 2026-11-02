# WarZone Caucasus v4.48 – AI Control and Dynamic Tasks

```text
WARZONE CAUCASUS V4.48 EN
ENHANCED AI ACTIVITY, F10 CONTROLS AND TASKS AGAINST ENEMY SPAWNS

Open WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_48_Iron87Ita_EN.miz in DCS.
All mission menus, task briefings, notifications and status messages are in
English. The mission briefing includes the current V4.48 AI settings.

AI CONTROL

F10 > WARZONE MISSIONS > AI CONTROL
- Status / current limits: profile, human player counts and active AI groups.
- Operations tempo: AUTO, LOW, NORMAL, HIGH, OFFENSIVE or NEW LAUNCHES PAUSED.
- Request AI reinforcements: CAP, CAS, SEAD, GROUND columns or a NAVAL raid.
- Halt active columns / Resume column movement.

Each coalition controls its own AI. Settings are shared by its players and
reset to AUTO when the mission restarts. Pause suspends new launches while
active groups continue their missions. Requests and activity changes respect
base ownership, unlocked sectors, group limits and parking availability.
An empty server does not launch new groups. Column movement controls apply
to the campaign's ground dispatcher columns.

DYNAMIC AI TASKS

F10 > WARZONE MISSIONS > DYNAMIC AI TASKS
1. Select Refresh target list.
2. Open ENEMY GROUP LIST and select a target.
3. Read Briefing / position, then select Accept task.
4. Use Active task / F10 track for the current briefing and tracking marker.
5. Cancel AI task releases the target for another player group.

Example: BLUE SENAKI SEAD#001 becomes an INTERCEPT SEAD task for RED.
A RED SEAD spawn becomes a corresponding task for BLUE.
Eligible spawns include CAP/BARCAP, CAS, AWACS, tankers, cargo, recon aircraft,
ground columns, dynamic SAM defenses and ships. Initial groups, inactive
templates, human groups and CSAR survivors are excluded from new-spawn tasks.

One task per player group and one assigned group per target. AI tasks can run
alongside existing territorial missions. Refresh the paginated catalog from
the menu. Briefings identify the exact group, origin/destination when known,
coordinates, bearing/range, altitude, speed and surviving unit count.
The assigned group's F10 tracking marker updates every 30 seconds.

Destroy ALL units in the assigned target group. Withdrawal or despawn does
not count as destruction. A task bonus requires at least one kill credited
to a player in the assigned group. Bonuses are added to pending earnings and
redeemed after safe RTB under existing WarZone rules. Other-forces-only kills
do not award the assigned group a bonus. Disconnecting or starting a new life
releases the previous assignment.

ENHANCED ACTIVITY

AUTO uses these limits PER COALITION while at least one human is present:
Total players    Combat flights    Ground columns
1-2              3                 2
3-4              4                 3
5-6              6                 3
7+               8                 4
Up to 1 AWACS and 2 tankers per coalition are available in addition.

LOW:       2 combat flights / 1 column.
NORMAL:    4 combat flights / 2 columns.
HIGH:      6 combat flights / 3 columns.
OFFENSIVE: 8 combat flights / 4 columns.
These are upper limits; campaign conditions may permit fewer active groups.
With at least three combat slots, capacity is shared between CAP, CAS and SEAD.

Initial flights are staggered at approximately 1.5-6.5 minutes, with shorter
subsequent launch gaps. Initial ground columns start after approximately
4-5 minutes, with additional departures staggered. AUTO solo/duo ground
respawn delays are 8-12 minutes, compared with the previous 30-40 minutes.

Four ground dispatchers per coalition are available. After securing a sector,
a column can advance toward the next objective instead of being removed.
Road routes include a final off-road leg when required. A stalled column can
receive a new route after four minutes without progress, with a maximum of
three recovery attempts per leg. Recovery is suspended while the column is
halted through F10. Surviving vehicles continue receiving orders after the
lead vehicle is lost. AIEN permits up to 18 groups moving tactically at once.
Initial naval raid attempts occur after 8-9 minutes, with shorter cooldowns.

VERIFICATION

All embedded Lua scripts and mission tables compile with DCS lua.dll.
Simulated DCS API tests cover opposing spawn tasks, assignment, private
tracking, F10 pagination, partial/full kills, one-time pending bonuses,
despawn handling, disconnects, coalition controls and activity limits.
Tests also exercise the actual campaign scaler, air dispatchers, convoy
continuation, route recovery and paused/empty-server naval launch gates.
Language checks cover all embedded Lua string literals and briefing text;
existing reference images were already in English.

The English release changes the campaign script, briefing dictionary and
three AIEN diagnostic messages. Gameplay logic matches V4.48. The archive
passes ZIP integrity checks. Original input files remain untouched.

A flight session has not been run inside DCS. Taxi behavior, actual terrain
pathfinding and performance still require an in-simulator check.

```
