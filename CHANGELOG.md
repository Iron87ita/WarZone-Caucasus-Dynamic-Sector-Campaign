# WarZone Caucasus – Changelog

# WarZone Caucasus v4.47

## Persistence & Dynamic Warfare Update

Version **4.47** focuses on improving campaign persistence and the reliability of dynamically deployed forces during long-running multiplayer campaigns.

### Fixed – Player Shop Unit Persistence

Units purchased and deployed through the player shop are now correctly included in the campaign persistence system.

Previously, shop units were spawned dynamically and existed normally during the mission, but they were not part of the standard ZoneCommander persistence data. As a result, purchased units disappeared after a mission or server restart.

This has now been corrected.

Purchased ground assets will now:

* Remain deployed after mission/server restart
* Restore their saved position and heading
* Preserve surviving units within partially damaged groups
* Be permanently removed from persistence when destroyed
* Continue operating normally after the campaign is reloaded

### MQ-9 / JTAC Persistence

MQ-9 Reaper / JTAC assets purchased through the shop are now also tracked by the persistence system.

Their deployment information is saved separately and reconstructed when the campaign is loaded again.

### Safe Integration with ZoneCommander

Shop persistence has been implemented using a dedicated persistence layer.

Purchased units are **not added to `ZoneCommander.built` or `remainingUnits`**.

This prevents interference with:

* Zone defense respawn
* Sector garrisons
* Ground dispatchers
* AI counterattack logic
* Zone capture mechanics
* Standard ZoneCommander unit restoration

The original WarZone respawn system therefore remains unchanged.

### Destroyed Unit Handling

Destroyed purchased units are automatically removed from the saved state.

This prevents destroyed shop assets from incorrectly returning after a server restart.

Multiple combat losses occurring within a short period are grouped into a single persistence update to avoid unnecessary save operations.

### Temporary Delivery Aircraft

Temporary aircraft used to deliver purchased forces are intentionally excluded from persistence.

Only the actual deployed combat/support assets are saved.

### Compatibility

Existing campaign save files remain compatible.

No campaign reset is required when upgrading to **v4.47**.

If no shop-unit persistence information exists in an older save file, WarZone simply starts with an empty purchased-unit registry while keeping the rest of the campaign state intact.

---

## Technical Improvements

* Added dedicated `shopSpawnedUnits` persistence state
* Added dynamic ground-group registration
* Added surviving-unit snapshots for purchased groups
* Added saved position and heading restoration
* Added coalition/country restoration
* Added MQ-9/JTAC persistence support
* Added automatic persistence updates after purchased-unit losses
* Added safe restoration after ZoneCommander initialization
* Prevented shop assets from entering standard zone respawn tables
* Preserved existing campaign persistence format and progression

---

## Recommended Server Update Procedure

1. Stop the current WarZone mission.
2. Replace the previous `.miz` with **WarZone Caucasus v4.47**.
3. Keep the existing WarZone persistence file.
4. Start the new mission.
5. Continue the campaign normally.

No campaign restart is required.

---

### WarZone Caucasus Dynamic Campaign

**Created by IRON87ITA**

Thank you to everyone testing the mission and reporting issues.

Your feedback continues to help improve WarZone and make the persistent campaign more reliable with every release.

## HOTFIX V4.46 – AI GROUND COUNTERATTACK & SHOP PERSISTENCE

* Fixed AI ground forces failing to continue offensive operations after the first campaign sectors.
* Reworked ground target selection to use the full sector connection network instead of the old limited progression chain.
* AI armored columns can now advance correctly across all 14 campaign sectors.
* Added proper ground counterattack/reclaim behavior: if a previously captured zone is lost, the opposing coalition can identify it as a valid target and attempt to retake it.
* Ground forces now deploy only from valid friendly zones directly connected to the selected target.
* Enemy-controlled zones are prioritized over neutral objectives where appropriate.
* Added automatic ground-front re-evaluation after sector captures, losses and new sector unlocks.
* Improved AI combat behavior for spawned armored groups with combat ROE and alert state applied where supported by DCS.
* Fixed shop-purchased units not surviving mission/server restarts.
* Player-purchased ground units are now saved in campaign persistence and restored automatically when the mission is loaded again.
* Saved shop units retain their unit type, coalition, position and heading.
* Destroyed shop units are removed from persistence and will not respawn after restart.
* MQ-9/JTAC assets purchased through the shop are also included in persistence.
* Temporary cargo/delivery aircraft are not persisted; only the deployed purchased asset is saved.
* Shop persistence saves immediately after successful deployment, preventing units from being lost if the server is restarted before the normal autosave cycle.
* Existing V4.44 / V4.45 persistence files remain compatible. No campaign reset is required.
* Corrected internal mission version references from V4.45 to V4.46.
* Updated briefing and kneeboard version information.
* Updated AI Ground Dispatcher and Persistence kneeboard information.
* Ground dispatcher limit aligned with the actual mission configuration: one active AI armored offensive group per coalition.

Campaign progression remains unchanged:

NATO:
Sector 3 → 2 → 1 → 6 → 7 → 8 → 9 → 10

RED:
Sector 3 → 4 → 5 → 11 → 12 → 13 → 14

IMPORTANT:
The persistence filename has intentionally not been changed in order to preserve compatibility with existing campaign progress.



## V4.55

Current stable build.

* Includes the extended 14-sector dynamic campaign system.
* Includes persistence self-healing introduced with the extended campaign.
* Maintains NATO and RED progressive sector paths.
* TAF / GCI system remains active.
* Dynamic AI Commander remains active.
* Updated campaign systems from previous V4.x releases are included.
* Current recommended mission file:

`WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_55.miz`

---

## V4.45 – Extended Sector Campaign Hotfix

### Campaign Progression

* Fixed campaign progression stopping after NATO captured Mozdok.
* Extended the dynamic campaign from 5 to 14 progressive sectors.

### NATO Campaign Path

`Sector 3 → 2 → 1 → 6 → 7 → 8 → 9 → 10`

### RED Campaign Path

`Sector 3 → 4 → 5 → 11 → 12 → 13 → 14`

### Strategic Expansion

Added new strategic fronts across:

* Northern Caucasus
* Krasnodar region
* Black Sea coast
* Georgia
* Abkhazia

### Dynamic Sector Activation

Sectors remain dynamically activated.

Only the current operational front and previously unlocked sectors are active.

### Persistence

* Added persistence self-healing to prevent the campaign from becoming stuck after a valid sector capture.
* Existing V4.44 / V4.37 persistence files remain compatible.
* No campaign reset is required.

### Scripting

* Fixed a potential `getGroup()` scripting error triggered by dynamically spawned static objects.

### Documentation

* Updated mission briefing.
* Updated kneeboard with the extended sector structure.

### Existing Systems

The following systems remain active:

* TAF / GCI
* Dynamic sector system
* WarZone Commander
* Existing V4.44 campaign features

### Important

Players continuing an existing NATO campaign that had already completed:

`Sector 3 → Sector 2 → Sector 1`

will automatically unlock **Sector 6** after mission startup.

Recommended build at the time:

`WarZone Caucasus MODERN V4.45 FINAL`
