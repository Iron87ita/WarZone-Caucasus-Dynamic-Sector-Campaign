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
