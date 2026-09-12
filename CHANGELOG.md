HOTFIX V4.46 – AI GROUND COUNTERATTACK & SHOP PERSISTENCE

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


# WarZone Caucasus – Changelog

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
