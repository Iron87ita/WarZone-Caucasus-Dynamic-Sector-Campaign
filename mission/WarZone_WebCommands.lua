-- WarZone Web -> DCS command inbox
-- Reads one-command files written by the web service into Saved Games/WarZoneWeb/commands.
-- DCS Lua 5.1 compatible.

WZ_WEB_COMMANDS = WZ_WEB_COMMANDS or {}
WZ_WEB_COMMANDS.interval = 1
WZ_WEB_COMMANDS.started = false

local function log(text)
    if env and env.info then env.info("[WZ_WEB_COMMANDS] " .. tostring(text)) end
end

local function playerOnlineOnSide(playerName, side)
    if not coalition or not coalition.getPlayers then return false end
    local ok, players = pcall(coalition.getPlayers, tonumber(side))
    if not ok then return false end
    for _, unit in ipairs(players or {}) do
        if unit and unit.isExist and unit:isExist() and unit.getPlayerName then
            local pok, name = pcall(unit.getPlayerName, unit)
            if pok and tostring(name or "") == tostring(playerName or "") then return true end
        end
    end
    return false
end

local function commandDir()
    if not lfs or not lfs.writedir then return nil end
    local base = lfs.writedir() .. "WarZoneWeb\\"
    pcall(lfs.mkdir, base)
    local dir = base .. "commands\\"
    pcall(lfs.mkdir, dir)
    return dir
end

local function parseLine(line)
    if type(line) ~= "string" then return nil end
    local version, command, taskId, playerName, requestId = line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t\r\n]*)")
    if version ~= "WZCMD1" then return nil end
    return {
        command = command,
        taskId = tonumber(taskId),
        playerName = playerName,
        requestId = requestId
    }
end

function WZ_WEB_COMMANDS.processFile(fullPath, fileName)
    local file = io and io.open and io.open(fullPath, "r") or nil
    if not file then return end
    local line = file:read("*l")
    file:close()

    local cmd = parseLine(line)
    if not cmd then
        log("invalid command file: " .. tostring(fileName))
        if os and os.remove then pcall(os.remove, fullPath) end
        return
    end

    if cmd.command == "ACCEPT_TASK" then
        local task = WZ_TASKS and WZ_TASKS.get and WZ_TASKS.get(cmd.taskId) or nil
        if not task then
            log("reject ACCEPT_TASK #" .. tostring(cmd.taskId) .. ": task not found")
        elseif not playerOnlineOnSide(cmd.playerName, task.coalition) then
            log("reject ACCEPT_TASK #" .. tostring(cmd.taskId) .. ": player not online on required coalition: " .. tostring(cmd.playerName))
            if WarZoneWebBridge and WarZoneWebBridge.pushEvent then
                pcall(WarZoneWebBridge.pushEvent, "neutral", "Task #" .. tostring(cmd.taskId) .. " rejected: pilot validation failed", "task")
            end
        else
            local ok, result = WZ_TASKS.accept(cmd.taskId, cmd.playerName)
            if ok then
                log("accepted task #" .. tostring(cmd.taskId) .. " for " .. tostring(cmd.playerName) .. " request=" .. tostring(cmd.requestId))
            else
                log("reject ACCEPT_TASK #" .. tostring(cmd.taskId) .. ": " .. tostring(result))
            end
        end
    else
        log("unknown command: " .. tostring(cmd.command))
    end

    if os and os.remove then pcall(os.remove, fullPath) end
end

function WZ_WEB_COMMANDS.poll(_, time)
    local ok, err = pcall(function()
        if not io or not lfs then return end
        local dir = commandDir()
        if not dir then return end
        for fileName in lfs.dir(dir) do
            if fileName ~= "." and fileName ~= ".." and fileName:match("%.cmd$") then
                WZ_WEB_COMMANDS.processFile(dir .. fileName, fileName)
            end
        end
    end)
    if not ok then log("poll error: " .. tostring(err)) end
    return time + WZ_WEB_COMMANDS.interval
end

function WZ_WEB_COMMANDS.start()
    if WZ_WEB_COMMANDS.started then return end
    WZ_WEB_COMMANDS.started = true
    if not io or not lfs then
        log("io/lfs unavailable - web commands disabled")
        return
    end
    commandDir()
    timer.scheduleFunction(WZ_WEB_COMMANDS.poll, nil, timer.getTime() + 3)
    log("command inbox started")
end

WZ_WEB_COMMANDS.start()
return WZ_WEB_COMMANDS
