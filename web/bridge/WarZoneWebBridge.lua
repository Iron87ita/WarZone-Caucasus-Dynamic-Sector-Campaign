-- WarZone Caucasus -> Web Command Center bridge
-- v4.47 live adapter for the real WZ_SECTOR + BattleCommander runtime.
-- Public telemetry only: no enemy aircraft, SAM or ground-unit coordinates.

WarZoneWebBridge = WarZoneWebBridge or {}
WarZoneWebBridge.version = WarZoneWebBridge.version or "4.47"
WarZoneWebBridge.outputFile = WarZoneWebBridge.outputFile or "WarZoneWebState.json"
WarZoneWebBridge.interval = WarZoneWebBridge.interval or 2
WarZoneWebBridge.maxPlayers = WarZoneWebBridge.maxPlayers or 32
WarZoneWebBridge.maxEvents = WarZoneWebBridge.maxEvents or 40
WarZoneWebBridge.events = WarZoneWebBridge.events or {}
WarZoneWebBridge.previousSectors = WarZoneWebBridge.previousSectors or {}
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

local function sideName(side)
    if side == 2 then return "NATO" end
    if side == 1 then return "RED" end
    return "NEUTRAL"
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

local function getBattleCommander()
    if type(_G) == "table" and type(_G.bc) == "table" and type(_G.bc.zones) == "table" then
        return _G.bc
    end
    if type(bc) == "table" and type(bc.zones) == "table" then return bc end
    if BattleCommander and BattleCommander.zones and BattleCommander.zones[1] then
        local instance = BattleCommander.zones[1].battleCommander
        if instance and type(instance) == "table" then return instance end
    end
    return BattleCommander
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

local function sectorIndexForZone(zoneName)
    if WZ_SECTOR and WZ_SECTOR.getSectorIndex then
        local ok, idx = pcall(WZ_SECTOR.getSectorIndex, WZ_SECTOR, zoneName)
        if ok then return idx end
    end
    return nil
end

local function collectOperations(bcObj)
    local operations, current = {}, {}
    local activeStates = { preparing=true, takeoff=true, inair=true, landed=true, enroute=true, atdestination=true }
    for _, zone in ipairs((bcObj and bcObj.zones) or {}) do
        for _, g in ipairs(zone.groups or {}) do
            if activeStates[g.state] then
                local targetSector = sectorIndexForZone(g.targetzone)
                local sourceSector = sectorIndexForZone(zone.zone)
                local op = {
                    id = tostring(g.name or (g.mission or "OP")),
                    type = string.upper(tostring(g.mission or "operation")),
                    side = sideKey(g.side),
                    status = string.upper(tostring(g.state or "active")),
                    source = zone.zone,
                    sourceSector = sourceSector,
                    target = g.targetzone,
                    sector = targetSector or sourceSector,
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
    table.sort(operations, function(a,b) return tostring(a.id) < tostring(b.id) end)
    return operations
end

local function collectSectorConnections()
    local result, seen = {}, {}
    if WZ_SECTOR and type(WZ_SECTOR.nextFor) == "table" then
        for side, branch in pairs(WZ_SECTOR.nextFor) do
            for fromIdx, toIdx in pairs(branch or {}) do
                local a, b = tonumber(fromIdx), tonumber(toIdx)
                if a and b then
                    local lo, hi = math.min(a,b), math.max(a,b)
                    local key = tostring(lo) .. ":" .. tostring(hi)
                    if not seen[key] then
                        seen[key] = true
                        result[#result + 1] = { from = a, to = b, side = sideKey(tonumber(side)) }
                    end
                end
            end
        end
    end
    table.sort(result, function(a,b)
        if a.from == b.from then return a.to < b.to end
        return a.from < b.from
    end)
    return result
end

local function aggregateSectorGeometry(definition, bcObj)
    local zoneEntries = {}
    local latSum, lonSum, centerCount = 0, 0, 0
    for _, zoneName in ipairs(definition.zones or {}) do
        local zc = bcObj and bcObj.getZoneByName and bcObj:getZoneByName(zoneName) or nil
        local geo = zoneGeometry(zoneName)
        if geo and geo.center then
            latSum = latSum + geo.center.lat
            lonSum = lonSum + geo.center.lon
            centerCount = centerCount + 1
        end
        zoneEntries[#zoneEntries + 1] = {
            name = zoneName,
            owner = sideKey(zc and zc.side or 0),
            active = zc and zc.active == true or false,
            level = zc and tableCount(zc.built) or 0,
            income = zc and (tonumber(zc.income) or 0) or 0,
            geometry = geo
        }
    end
    return {
        type = "sector",
        center = centerCount > 0 and { lat = latSum / centerCount, lon = lonSum / centerCount } or nil,
        zones = zoneEntries
    }, zoneEntries
end

local function collectSectors(bcObj)
    local sectors, frontIds = {}, {}
    if not WZ_SECTOR or type(WZ_SECTOR.definitions) ~= "table" then return sectors, nil end

    for idx, definition in ipairs(WZ_SECTOR.definitions) do
        local unlocked = WZ_SECTOR.unlocked and WZ_SECTOR.unlocked[idx] == true or false
        local completedBy = tonumber(WZ_SECTOR.completedBy and WZ_SECTOR.completedBy[idx]) or 0
        local liveOwner = 0
        if WZ_SECTOR.sectorOwner then
            local ok, owner = pcall(WZ_SECTOR.sectorOwner, WZ_SECTOR, idx)
            if ok then liveOwner = tonumber(owner) or 0 end
        end

        local geometry, zoneEntries = aggregateSectorGeometry(definition, bcObj)
        local blueZones, redZones, neutralZones, level, income = 0, 0, 0, 0, 0
        for _, z in ipairs(zoneEntries) do
            if z.owner == "blue" then blueZones = blueZones + 1
            elseif z.owner == "red" then redZones = redZones + 1
            else neutralZones = neutralZones + 1 end
            level = level + (tonumber(z.level) or 0)
            income = income + (tonumber(z.income) or 0)
        end

        local owner = "neutral"
        if unlocked then owner = sideKey(liveOwner) end
        if not unlocked then owner = "neutral" end

        local secured = unlocked and completedBy ~= 0 and liveOwner == completedBy
        local frontline = unlocked and not secured
        local status = not unlocked and "locked" or (secured and "secured" or "frontline")
        if frontline then frontIds[#frontIds + 1] = idx end

        local totalZones = math.max(1, #zoneEntries)
        local sector = {
            id = idx,
            name = definition.name or ("Sector " .. idx),
            owner = owner,
            status = status,
            unlocked = unlocked,
            frontline = frontline,
            completedBy = sideKey(completedBy),
            level = level,
            income = income,
            blueProgress = math.floor((blueZones / totalZones) * 100 + 0.5),
            redProgress = math.floor((redZones / totalZones) * 100 + 0.5),
            neutralProgress = math.floor((neutralZones / totalZones) * 100 + 0.5),
            geometry = geometry
        }
        sectors[#sectors + 1] = sector

        local old = WarZoneWebBridge.previousSectors[idx]
        if old then
            if old.unlocked ~= unlocked and unlocked then
                WarZoneWebBridge.pushEvent("neutral", "Sector " .. idx .. " unlocked: " .. tostring(definition.name), "sector")
            end
            if old.completedBy ~= completedBy and completedBy ~= 0 then
                WarZoneWebBridge.pushEvent(sideKey(completedBy), sideName(completedBy) .. " secured Sector " .. idx .. ": " .. tostring(definition.name), "capture")
            elseif old.owner ~= owner and owner ~= "neutral" and frontline then
                WarZoneWebBridge.pushEvent(owner, sideName(liveOwner) .. " controls all objectives in Sector " .. idx, "capture")
            end
        end
        WarZoneWebBridge.previousSectors[idx] = { unlocked=unlocked, completedBy=completedBy, owner=owner }
    end

    local activeSector = (#frontIds == 1) and frontIds[1] or nil
    return sectors, activeSector
end

local function walletSummary(bcObj)
    local total, count = 0, 0
    for _, amount in pairs((bcObj and bcObj.playerWallets) or {}) do
        total = total + (tonumber(amount) or 0)
        count = count + 1
    end
    return total, count
end

function WarZoneWebBridge.collect()
    local bcObj = getBattleCommander()
    local sectors, activeSector = collectSectors(bcObj)
    local players = collectPlayers()
    local walletTotal, walletCount = walletSummary(bcObj)
    local blueCredits = bcObj and bcObj.accounts and tonumber(bcObj.accounts[2]) or 0
    local redCredits = bcObj and bcObj.accounts and tonumber(bcObj.accounts[1]) or 0

    return {
        campaign = "WarZone Caucasus",
        version = WarZoneWebBridge.version,
        status = (#sectors == 14) and "ONLINE" or ((#sectors > 0) and "STARTING" or "WAITING"),
        updatedAt = utcNow(),
        missionSeconds = timer and timer.getTime and timer.getTime() or 0,
        missionTime = hhmmss(timer and timer.getTime and timer.getTime() or 0),
        playersOnline = #players,
        maxPlayers = WarZoneWebBridge.maxPlayers,
        players = players,
        activeSector = activeSector,
        coalitions = {
            blue = { name = "NATO", credits = blueCredits },
            red = { name = "RED", credits = redCredits }
        },
        playerWallets = { total = walletTotal, count = walletCount },
        sectors = sectors,
        connections = collectSectorConnections(),
        operations = collectOperations(bcObj),
        events = WarZoneWebBridge.events
    }
end

function WarZoneWebBridge.writeSnapshot(snapshot)
    if not io or not lfs then
        if env and env.info then env.info("[WarZoneWebBridge] io/lfs unavailable - telemetry disabled") end
        return false
    end

    local base = lfs.writedir() .. "WarZoneWeb\\"
    pcall(lfs.mkdir, base)
    local dst = base .. WarZoneWebBridge.outputFile
    local tmp = dst .. ".tmp"
    local file, err = io.open(tmp, "w")
    if not file then
        if env and env.info then env.info("[WarZoneWebBridge] cannot open temp state file: " .. tostring(err)) end
        return false
    end
    file:write(jsonEncode(snapshot))
    file:flush()
    file:close()

    if os and os.remove and os.rename then
        pcall(os.remove, dst)
        local ok, renameErr = os.rename(tmp, dst)
        if ok then return true end
        if env and env.info then env.info("[WarZoneWebBridge] atomic rename unavailable: " .. tostring(renameErr)) end
    end

    local fallback, fallbackErr = io.open(dst, "w")
    if not fallback then
        if env and env.info then env.info("[WarZoneWebBridge] state publish failed: " .. tostring(fallbackErr)) end
        return false
    end
    fallback:write(jsonEncode(snapshot))
    fallback:close()
    if os and os.remove then pcall(os.remove, tmp) end
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
    if env and env.info then env.info("[WarZoneWebBridge] LIVE telemetry started for WZ_SECTOR v4.47") end
end

WarZoneWebBridge.start()
return WarZoneWebBridge
