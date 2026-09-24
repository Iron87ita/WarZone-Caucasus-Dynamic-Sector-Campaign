-- WarZone Task Manager MVP
-- Stable task IDs + briefing/state exported to the Web Command Center.
-- DCS Lua 5.1 compatible.

WZ_TASKS = WZ_TASKS or {}
WZ_TASKS.version = "1.0.0-mvp"
WZ_TASKS.tasks = WZ_TASKS.tasks or {}
WZ_TASKS.order = WZ_TASKS.order or {}

local function now()
    return timer and timer.getTime and timer.getTime() or 0
end

local function sideKey(side)
    if tonumber(side) == 2 then return "blue" end
    if tonumber(side) == 1 then return "red" end
    return "neutral"
end

local function copyArray(values)
    local out = {}
    for i, value in ipairs(values or {}) do out[i] = value end
    return out
end

function WZ_TASKS.register(def)
    if type(def) ~= "table" or not tonumber(def.id) then return false, "invalid task definition" end
    local id = tonumber(def.id)
    if WZ_TASKS.tasks[id] then return false, "duplicate task id" end

    local task = {
        id = id,
        type = string.upper(tostring(def.type or "MISSION")),
        title = tostring(def.title or ("Task " .. id)),
        briefing = tostring(def.briefing or "No briefing available."),
        objective = tostring(def.objective or ""),
        sector = tonumber(def.sector),
        coalition = tonumber(def.coalition) or 2,
        reward = tonumber(def.reward) or 0,
        threats = copyArray(def.threats),
        recommendedAircraft = copyArray(def.recommendedAircraft),
        status = string.upper(tostring(def.status or "AVAILABLE")),
        acceptedBy = nil,
        acceptedAt = nil,
        completedAt = nil,
        activationId = def.activationId,
        onAccept = def.onAccept
    }

    WZ_TASKS.tasks[id] = task
    WZ_TASKS.order[#WZ_TASKS.order + 1] = id
    table.sort(WZ_TASKS.order)
    return true, task
end

function WZ_TASKS.get(id)
    return WZ_TASKS.tasks[tonumber(id)]
end

function WZ_TASKS.refreshAvailability()
    for _, id in ipairs(WZ_TASKS.order) do
        local task = WZ_TASKS.tasks[id]
        if task and (task.status == "AVAILABLE" or task.status == "LOCKED") and task.sector and WZ_SECTOR and WZ_SECTOR.unlocked then
            task.status = WZ_SECTOR.unlocked[task.sector] and "AVAILABLE" or "LOCKED"
        end
    end
end

function WZ_TASKS.accept(id, playerName)
    local task = WZ_TASKS.get(id)
    if not task then return false, "TASK_NOT_FOUND" end
    WZ_TASKS.refreshAvailability()
    if task.status ~= "AVAILABLE" then return false, "TASK_NOT_AVAILABLE" end

    task.status = "ACTIVE"
    task.acceptedBy = tostring(playerName or "Unknown")
    task.acceptedAt = now()

    local text = string.format("WARZONE | TASK #%d ACCEPTED\n%s\nPilot: %s", task.id, task.title, task.acceptedBy)
    if trigger and trigger.action and trigger.action.outTextForCoalition then
        pcall(trigger.action.outTextForCoalition, task.coalition, text, 15)
    end
    if WarZoneWebBridge and WarZoneWebBridge.pushEvent then
        pcall(WarZoneWebBridge.pushEvent, sideKey(task.coalition), string.format("Task #%d accepted by %s: %s", task.id, task.acceptedBy, task.title), "task")
    end

    local binding = nil
    if type(WZ_TASK_BINDINGS) == "table" then binding = WZ_TASK_BINDINGS[task.id] end
    if type(binding) == "function" then
        local ok, err = pcall(binding, task, task.acceptedBy)
        if not ok and env and env.info then env.info("[WZ_TASKS] binding error for #" .. task.id .. ": " .. tostring(err)) end
    elseif type(task.onAccept) == "function" then
        local ok, err = pcall(task.onAccept, task, task.acceptedBy)
        if not ok and env and env.info then env.info("[WZ_TASKS] onAccept error for #" .. task.id .. ": " .. tostring(err)) end
    end

    return true, task
end

function WZ_TASKS.complete(id)
    local task = WZ_TASKS.get(id)
    if not task then return false, "TASK_NOT_FOUND" end
    if task.status ~= "ACTIVE" then return false, "TASK_NOT_ACTIVE" end
    task.status = "SUCCESS"
    task.completedAt = now()

    if task.acceptedBy and task.reward > 0 and type(bc) == "table" and type(bc.playerWallets) == "table" then
        bc.playerWallets[task.acceptedBy] = (tonumber(bc.playerWallets[task.acceptedBy]) or tonumber(bc.startingWallet) or 0) + task.reward
    end

    if WarZoneWebBridge and WarZoneWebBridge.pushEvent then
        pcall(WarZoneWebBridge.pushEvent, sideKey(task.coalition), string.format("Task #%d completed: %s (+%d CR)", task.id, task.title, task.reward), "task")
    end
    return true, task
end

function WZ_TASKS.fail(id, reason)
    local task = WZ_TASKS.get(id)
    if not task then return false, "TASK_NOT_FOUND" end
    if task.status ~= "ACTIVE" then return false, "TASK_NOT_ACTIVE" end
    task.status = "FAILED"
    task.completedAt = now()
    if WarZoneWebBridge and WarZoneWebBridge.pushEvent then
        pcall(WarZoneWebBridge.pushEvent, sideKey(task.coalition), string.format("Task #%d failed: %s%s", task.id, task.title, reason and (" - " .. tostring(reason)) or ""), "task")
    end
    return true, task
end

function WZ_TASKS.getWebState()
    WZ_TASKS.refreshAvailability()
    local result = {}
    for _, id in ipairs(WZ_TASKS.order) do
        local task = WZ_TASKS.tasks[id]
        if task then
            result[#result + 1] = {
                id = task.id,
                type = task.type,
                title = task.title,
                briefing = task.briefing,
                objective = task.objective,
                sector = task.sector,
                coalition = sideKey(task.coalition),
                reward = task.reward,
                threats = copyArray(task.threats),
                recommendedAircraft = copyArray(task.recommendedAircraft),
                status = task.status,
                acceptedBy = task.acceptedBy,
                acceptedAt = task.acceptedAt,
                activationId = task.activationId
            }
        end
    end
    return result
end

function WZ_TASKS.getState()
    local state = {}
    for _, id in ipairs(WZ_TASKS.order) do
        local task = WZ_TASKS.tasks[id]
        state[id] = {
            status = task.status,
            acceptedBy = task.acceptedBy,
            acceptedAt = task.acceptedAt,
            completedAt = task.completedAt
        }
    end
    return state
end

function WZ_TASKS.loadState(state)
    for rawId, saved in pairs(state or {}) do
        local task = WZ_TASKS.get(rawId)
        if task and type(saved) == "table" then
            task.status = saved.status or task.status
            task.acceptedBy = saved.acceptedBy
            task.acceptedAt = saved.acceptedAt
            task.completedAt = saved.completedAt
        end
    end
end

-- MVP task catalog. These IDs are stable and are the contract between the .miz and the web UI.
-- WZ_TASK_BINDINGS[id] can later connect each ID to the existing WarZone CAP/SEAD/CAS/STRIKE logic.
WZ_TASKS.register({
    id=1101, type="CAP", title="Mountain Shield", sector=3, coalition=2, reward=100,
    objective="Establish fighter cover over the Sector 3 mountain corridor.",
    threats={"Enemy fighter activity", "Long-range SAM coverage"},
    recommendedAircraft={"F-16C", "F/A-18C", "JF-17", "F-15E"},
    briefing=[[NATO COMMAND // TASK 1101

Enemy air activity is threatening friendly operations in Sector 3.
Establish combat air patrol over the mountain corridor and protect coalition strike packages.

PRIMARY OBJECTIVE
Maintain air superiority over the assigned sector and defeat hostile fighter activity.

ROE
Engage confirmed hostile aircraft threatening coalition forces.]]
})

WZ_TASKS.register({
    id=2101, type="SEAD", title="Wild Weasel", sector=3, coalition=2, reward=150,
    objective="Suppress enemy radar-guided air defenses protecting Sector 3.",
    threats={"Radar-guided SAM", "AAA", "MANPADS", "Enemy CAP"},
    recommendedAircraft={"F-16C", "F/A-18C", "JF-17"},
    briefing=[[NATO COMMAND // TASK 2101

Enemy radar-guided air defenses are restricting access to Sector 3.
Locate and suppress the hostile SAM network to open the corridor for follow-on packages.

PRIMARY OBJECTIVE
Destroy or suppress the primary tracking/fire-control radar.

SECONDARY OBJECTIVE
Reduce remaining launchers and supporting air-defense assets.]]
})

WZ_TASKS.register({
    id=3101, type="CAS", title="Hammer Support", sector=3, coalition=2, reward=120,
    objective="Provide close air support to coalition forces operating in Sector 3.",
    threats={"AAA", "MANPADS", "Armored vehicles"},
    recommendedAircraft={"A-10C II", "F-16C", "F/A-18C", "JF-17"},
    briefing=[[NATO COMMAND // TASK 3101

Coalition ground forces are engaged along the Sector 3 front.
Provide close air support and reduce hostile armored and mechanized resistance.

PRIMARY OBJECTIVE
Destroy hostile ground forces threatening the coalition advance.

CAUTION
Confirm targets before weapons release and avoid friendly positions.]]
})

WZ_TASKS.register({
    id=4101, type="STRIKE", title="Broken Spear", sector=3, coalition=2, reward=200,
    objective="Strike a high-value enemy support objective in Sector 3.",
    threats={"SAM", "AAA", "Enemy CAP"},
    recommendedAircraft={"F-15E", "F-16C", "F/A-18C", "JF-17"},
    briefing=[[NATO COMMAND // TASK 4101

A high-value enemy support objective has been identified inside Sector 3.
Destroy the objective to degrade the enemy's ability to sustain operations on the front.

PRIMARY OBJECTIVE
Destroy the designated strategic target.

PACKAGE NOTE
SEAD and CAP support are recommended before entering the target area.]]
})

if env and env.info then env.info("[WZ_TASKS] Task Manager MVP initialized; tasks=" .. tostring(#WZ_TASKS.order)) end

return WZ_TASKS
