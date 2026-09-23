-- WarZone Caucasus -> Web Command Center bridge (MVP)
--
-- Purpose:
--   Serialize a safe campaign snapshot that the web server can read.
--   This file defines the contract only; hook it into the existing WarZone
--   campaign state once the concrete ZoneCommander/mission objects are available.
--
-- IMPORTANT:
--   DCS mission scripting must have io/lfs enabled for file output.
--   Write only strategic/public data here; do not export enemy unit positions.

WarZoneWebBridge = WarZoneWebBridge or {}
WarZoneWebBridge.outputFile = WarZoneWebBridge.outputFile or "WarZoneWebState.json"
WarZoneWebBridge.interval = WarZoneWebBridge.interval or 2

local function esc(value)
    value = tostring(value or "")
    value = value:gsub("\\", "\\\\")
    value = value:gsub('"', '\\"')
    value = value:gsub("\n", "\\n")
    value = value:gsub("\r", "\\r")
    return value
end

local function bool(v) return v and "true" or "false" end

function WarZoneWebBridge.encodeSnapshot(s)
    local sectors = {}
    for _, z in ipairs(s.sectors or {}) do
        sectors[#sectors + 1] = string.format(
            '{"id":%d,"name":"%s","owner":"%s","status":"%s","blueProgress":%d,"redProgress":%d}',
            tonumber(z.id) or 0, esc(z.name), esc(z.owner), esc(z.status),
            tonumber(z.blueProgress) or 0, tonumber(z.redProgress) or 0
        )
    end

    local operations = {}
    for _, op in ipairs(s.operations or {}) do
        operations[#operations + 1] = string.format(
            '{"id":"%s","type":"%s","sector":%d,"status":"%s","title":"%s"}',
            esc(op.id), esc(op.type), tonumber(op.sector) or 0, esc(op.status), esc(op.title)
        )
    end

    return string.format([[
{
  "campaign":"%s",
  "version":"%s",
  "status":"%s",
  "updatedAt":"%s",
  "playersOnline":%d,
  "maxPlayers":%d,
  "missionTime":"%s",
  "activeSector":%d,
  "coalitions":{
    "blue":{"name":"NATO","credits":%d},
    "red":{"name":"RED","credits":%d}
  },
  "sectors":[%s],
  "operations":[%s],
  "events":[]
}
]],
        esc(s.campaign or "WarZone Caucasus"),
        esc(s.version or "4.47"),
        esc(s.status or "ONLINE"),
        esc(s.updatedAt or ""),
        tonumber(s.playersOnline) or 0,
        tonumber(s.maxPlayers) or 32,
        esc(s.missionTime or ""),
        tonumber(s.activeSector) or 3,
        tonumber(s.blueCredits) or 0,
        tonumber(s.redCredits) or 0,
        table.concat(sectors, ","),
        table.concat(operations, ",")
    )
end

function WarZoneWebBridge.writeSnapshot(snapshot)
    if not io or not lfs then
        env.info("WarZoneWebBridge: io/lfs unavailable; web state not written")
        return false
    end

    local base = lfs.writedir() .. "WarZoneWeb\\"
    lfs.mkdir(base)
    local tmp = base .. WarZoneWebBridge.outputFile .. ".tmp"
    local dst = base .. WarZoneWebBridge.outputFile

    local file, err = io.open(tmp, "w")
    if not file then
        env.info("WarZoneWebBridge: cannot open state file: " .. tostring(err))
        return false
    end

    file:write(WarZoneWebBridge.encodeSnapshot(snapshot))
    file:close()
    os.remove(dst)
    local ok, renameErr = os.rename(tmp, dst)
    if not ok then
        env.info("WarZoneWebBridge: rename failed: " .. tostring(renameErr))
        return false
    end
    return true
end

-- Replace this function with adapters to the real WarZone state.
function WarZoneWebBridge.collect()
    return {
        campaign = "WarZone Caucasus",
        version = "4.47",
        status = "ONLINE",
        updatedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        playersOnline = 0,
        maxPlayers = 32,
        missionTime = tostring(math.floor(timer.getTime())),
        activeSector = 3,
        blueCredits = 0,
        redCredits = 0,
        sectors = {},
        operations = {}
    }
end

function WarZoneWebBridge.tick(_, time)
    local ok, err = pcall(function()
        WarZoneWebBridge.writeSnapshot(WarZoneWebBridge.collect())
    end)
    if not ok then env.info("WarZoneWebBridge error: " .. tostring(err)) end
    return time + WarZoneWebBridge.interval
end

function WarZoneWebBridge.start()
    timer.scheduleFunction(WarZoneWebBridge.tick, nil, timer.getTime() + 2)
    env.info("WarZoneWebBridge started")
end

return WarZoneWebBridge
