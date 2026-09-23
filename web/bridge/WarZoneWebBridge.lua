-- WarZone Caucasus -> Web Command Center bridge
-- Auto-discovers live WarZone state from BattleCommander / ZoneCommander.
-- Public telemetry only: no enemy aircraft, SAM or ground-unit coordinates.

WarZoneWebBridge = WarZoneWebBridge or {}
WarZoneWebBridge.version = WarZoneWebBridge.version or "4.47"
WarZoneWebBridge.outputFile = WarZoneWebBridge.outputFile or "WarZoneWebState.json"
WarZoneWebBridge.interval = WarZoneWebBridge.interval or 2
WarZoneWebBridge.maxPlayers = WarZoneWebBridge.maxPlayers or 32
WarZoneWebBridge.maxEvents = WarZoneWebBridge.maxEvents or 40
WarZoneWebBridge.events = WarZoneWebBridge.events or {}
WarZoneWebBridge.previousOwners = WarZoneWebBridge.previousOwners or {}
WarZoneWebBridge.previousOperations = WarZoneWebBridge.previousOperations or {}

local function isArray(t)
    if type(t) ~= "table" then return false end
    local max, count = 0, 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then return false end
        if k > max then max = k end
        count = count + 1
    end
    return max == count
end

local function jsonEscape(v)
    local s = tostring(v or "")
    s = s:gsub("\\", "\\\\"):gsub('"', '\\"')
    s = s:gsub("\b", "\\b"):gsub("\f", "\\f"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    return s
end

local function jsonEncode(v, seen)
    local tv = type(v)
    if tv == "nil" then return "null" end
    if tv == "boolean" then return v and "true" or "false" end
    if tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "null" end
        return tostring(v)
    end
    if tv == "string" then return '"' .. jsonEscape(v) .. '"' end
    if tv ~= "table" then return '"' .. jsonEscape(tostring(v)) .. '"' end

    seen = seen or {}
    if seen[v] then return "null" end
    seen[v] = true

    local out = {}
    if isArray(v) then
        for i = 1, #v do out[#out + 1] = jsonEncode(v[i], seen) end
        seen[v] = nil
        return "[" .. table.concat(out, ",") .. "]"
    end

    for k, value in pairs(v) do
        out[#out + 1] = '"' .. jsonEscape(k) .. '":' .. jsonEncode(value, seen)
    end
    table.sort(out)
    seen[v] = nil
    return "{" .. table.concat(out, ",") .. "}"
end

local function tableCount(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

local function sideKey(side)
    if side == 2 then return "blue" end
    if side == 1 then return "red" end
    return "neutral"
end

local function hhmmss(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02d:%02d:%02d", h, m, s)
end

local function utcNow()
    if os and os.date then
        local ok, value = pcall(os.date, "!%Y-%m-%dT%H:%M:%SZ")
        if ok then return value end
    end
    return ""
end

local function eventTime()
    return hhmmss(timer and timer.getTime and timer.getTime() or 0)
end

function WarZoneWebBridge.pushEvent(side, text, kind)
    table.insert(WarZoneWebBridge.events, 1, {
        time = eventTime(),
        side = side or "neutral",
        kind = kind or "campaign",
        text = text or ""
    })
    while #WarZoneWebBridge.events > WarZoneWebBridge.maxEvents do
        table.remove(WarZoneWebBridge.events)
    end
end

local function toLatLon(point)
    if not point or not coord or not coord.LOtoLL then return nil end
    local ok, lat, lon = pcall(coord.LOtoLL, point)
    if not ok or not lat or not lon then return nil end
    return { lat = lat, lon = lon }
end

local function zoneGeometry(zoneName)
    if not CustomZone or not CustomZone.getByName then return nil end
    local ok, z = pcall(CustomZone.getByName, CustomZone, zoneName)
    if not ok or not z then return nil end

    local geometry = {
        type = (z.isQuad and z:isQuad()) and "polygon" or "circle",
        radius = tonumber(z.radius) or 0,
        center = toLatLon(z.point)
    }

    if z.vertices then
        geometry.vertices = {}
        for _, p in ipairs(z.vertices) do
            local ll = toLatLon(p)
            if ll then geometry.vertices[#geometry.vertices + 1] = ll end
        end
    end
    return geometry
end

local function sectorId(zone, index)
    if tonumber(zone.sectorId) then return tonumber(zone.sectorId) end
    if tonumber(zone.id) then return tonumber(zone.id) end
    local name = tostring(zone.zone or zone.name or "")
    local n = name:match("[Ss][Ee][Cc][Tt][Oo][Rr][%s_%-#]*(%d+)")
    return tonumber(n) or index
end

local function getBattleCommander()
    if BattleCommander and BattleCommander.zones and BattleCommander.zones[1] then
        local instance = BattleCommander.zones[1].battleCommander
        if instance and type(instance) == "table" then return instance end
    end
    return BattleCommander
end

local function buildZoneIndex(bc)
    local byName = {}
    for i, zone in ipairs((bc and bc.zones) or {}) do
        byName[zone.zone] = { zone = zone, id = sectorId(zone, i), index = i }
    end
    return byName
end

local function isFrontline(zone, bc, byName)
    if not zone.active then return false end
    for _, c in ipairs((bc and bc.connections) or {}) do
        local otherName = nil
        if c.from == zone.zone then otherName = c.to elseif c.to == zone.zone then otherName = c.from end
        local other = otherName and byName[otherName] and byName[otherName].zone
        if other and other.active and (other.side == 0 or zone.side == 0 or other.side ~= zone.side) then
            return true
        end
    end
    return false
end

local function collectPlayers()
    local players = {}
    if not coalition or not coalition.getPlayers then return players end
    for _, side in ipairs({1, 2}) do
        local ok, units = pcall(coalition.getPlayers, side)
        if ok then
            for _, u in ipairs(units or {}) do
                if u and u.isExist and u:isExist() then
                    local name = "Pilot"
                    if u.getPlayerName then
                        local pok, pname = pcall(u.getPlayerName, u)
                        if pok and pname then name = pname end
                    end
                    local aircraft = "Unknown"
                    if u.getTypeName then
                        local tok, tname = pcall(u.getTypeName, u)
                        if tok and tname then aircraft = tname end
                    end
                    players[#players + 1] = { name = name, side = sideKey(side), aircraft = aircraft }
                end
            end
        end
    end
    table.sort(players, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return players
end

local function collectOperations(bc, byName)
    local operations, current = {}, {}
    local activeStates = { preparing=true, takeoff=true, inair=true, landed=true, enroute=true, atdestination=true }
    for _, zone in ipairs((bc and bc.zones) or {}) do
        for _, g in ipairs(zone.groups or {}) do
            if activeStates[g.state] then
                local target = byName[g.targetzone]
                local op = {
                    id = tostring(g.name or (g.mission or "OP")),
                    type = string.upper(tostring(g.mission or "operation")),
                    side = sideKey(g.side),
                    status = string.upper(tostring(g.state or "active")),
                    source = zone.zone,
                    target = g.targetzone,
                    sector = target and target.id or sectorId(zone, 0),
                    platform = g.type or "unknown",
                    title = string.format("%s → %s", tostring(zone.zone or "?"), tostring(g.targetzone or "?"))
                }
                operations[#operations + 1] = op
                current[op.id] = op.status

                local previous = WarZoneWebBridge.previousOperations[op.id]
                if previous and previous ~= op.status and (op.status == "INAIR" or op.status == "ENROUTE") then
                    WarZoneWebBridge.pushEvent(op.side, op.id .. " launched toward " .. tostring(op.target or "objective"), "operation")
                end
            end
        end
    end
    WarZoneWebBridge.previousOperations = current
    return operations
end

local function collectConnections(bc, byName)
    local result = {}
    for _, c in ipairs((bc and bc.connections) or {}) do
        local a, b = byName[c.from], byName[c.to]
        if a and b then
            result[#result + 1] = { from = a.id, to = b.id, fromName = c.from, toName = c.to }
        end
    end
    return result
end

local function collectSectors(bc, byName)
    local sectors = {}
    local firstFront = nil
    for i, zone in ipairs((bc and bc.zones) or {}) do
        local id = sectorId(zone, i)
        local owner = sideKey(zone.side)
        local frontline = isFrontline(zone, bc, byName)
        local status = not zone.active and "destroyed" or (frontline and "frontline" or (owner == "neutral" and "neutral" or "controlled"))
        local sector = {
            id = id,
            name = zone.zone or ("Sector " .. id),
            owner = owner,
            status = status,
            active = zone.active == true,
            frontline = frontline,
            level = tableCount(zone.built),
            income = tonumber(zone.income) or 0,
            geometry = zoneGeometry(zone.zone)
        }
        sectors[#sectors + 1] = sector
        if frontline and not firstFront then firstFront = id end

        local oldOwner = WarZoneWebBridge.previousOwners[zone.zone]
        if oldOwner and oldOwner ~= owner then
            local who = owner == "blue" and "NATO" or (owner == "red" and "RED" or "NEUTRAL")
            WarZoneWebBridge.pushEvent(owner, who .. " now controls " .. tostring(zone.zone), "capture")
        end
        WarZoneWebBridge.previousOwners[zone.zone] = owner
    end
    table.sort(sectors, function(a, b) return (tonumber(a.id) or 0) < (tonumber(b.id) or 0) end)
    return sectors, firstFront
end

local function walletSummary(bc)
    local total, count = 0, 0
    for _, amount in pairs((bc and bc.playerWallets) or {}) do
        total = total + (tonumber(amount) or 0)
        count = count + 1
    end
    return total, count
end

function WarZoneWebBridge.collect()
    local bc = getBattleCommander()
    local byName = buildZoneIndex(bc)
    local sectors, activeSector = collectSectors(bc, byName)
    local players = collectPlayers()
    local walletTotal, walletCount = walletSummary(bc)
    local blueCredits = bc and bc.accounts and tonumber(bc.accounts[2]) or 0
    local redCredits = bc and bc.accounts and tonumber(bc.accounts[1]) or 0

    return {
        campaign = "WarZone Caucasus",
        version = WarZoneWebBridge.version,
        status = (#sectors > 0) and "ONLINE" or "STARTING",
        updatedAt = utcNow(),
        missionSeconds = timer and timer.getTime and timer.getTime() or 0,
        missionTime = hhmmss(timer and timer.getTime and timer.getTime() or 0),
        playersOnline = #players,
        maxPlayers = WarZoneWebBridge.maxPlayers,
        players = players,
        activeSector = activeSector,
        coalitions = {
            blue = { name = "NATO", credits = blueCredits, walletTotal = walletTotal, walletCount = walletCount },
            red = { name = "RED", credits = redCredits }
        },
        sectors = sectors,
        connections = collectConnections(bc, byName),
        operations = collectOperations(bc, byName),
        events = WarZoneWebBridge.events
    }
end

function WarZoneWebBridge.writeSnapshot(snapshot)
    if not io or not lfs then
        env.info("[WarZoneWebBridge] io/lfs unavailable - telemetry disabled")
        return false
    end

    local base = lfs.writedir() .. "WarZoneWeb\\"
    pcall(lfs.mkdir, base)
    local dst = base .. WarZoneWebBridge.outputFile
    local file, err = io.open(dst, "w")
    if not file then
        env.info("[WarZoneWebBridge] cannot open state file: " .. tostring(err))
        return false
    end
    file:write(jsonEncode(snapshot))
    file:flush()
    file:close()
    return true
end

function WarZoneWebBridge.tick(_, time)
    local ok, err = pcall(function()
        WarZoneWebBridge.writeSnapshot(WarZoneWebBridge.collect())
    end)
    if not ok and env and env.info then env.info("[WarZoneWebBridge] error: " .. tostring(err)) end
    return time + WarZoneWebBridge.interval
end

function WarZoneWebBridge.start()
    if WarZoneWebBridge.started then return end
    WarZoneWebBridge.started = true
    timer.scheduleFunction(WarZoneWebBridge.tick, nil, timer.getTime() + 2)
    if env and env.info then env.info("[WarZoneWebBridge] LIVE telemetry started") end
end

WarZoneWebBridge.start()
return WarZoneWebBridge
