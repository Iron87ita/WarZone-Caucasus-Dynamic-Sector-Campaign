-- Extends the existing WarZoneWebBridge snapshot with WZ_TASKS state.
-- Kept separate so the proven v4.47 bridge remains unchanged.

WZ_TASK_BRIDGE_PATCH = WZ_TASK_BRIDGE_PATCH or {}

function WZ_TASK_BRIDGE_PATCH.apply()
    if WZ_TASK_BRIDGE_PATCH.applied then return true end
    if not WarZoneWebBridge or type(WarZoneWebBridge.collect) ~= "function" then return false end

    local originalCollect = WarZoneWebBridge.collect
    WarZoneWebBridge.collect = function(...)
        local state = originalCollect(...)
        if type(state) ~= "table" then state = {} end

        if WZ_TASKS and type(WZ_TASKS.getWebState) == "function" then
            local ok, tasks = pcall(WZ_TASKS.getWebState)
            state.tasks = (ok and type(tasks) == "table") and tasks or {}
        else
            state.tasks = {}
        end

        -- Backward-compatible wallet aliases expected by the current browser UI.
        if state.playerWallets and state.coalitions and state.coalitions.blue then
            state.coalitions.blue.walletTotal = state.playerWallets.total
            state.coalitions.blue.walletCount = state.playerWallets.count
        end
        return state
    end

    WZ_TASK_BRIDGE_PATCH.applied = true
    if env and env.info then env.info("[WZ_TASKS] Web bridge task export enabled") end
    return true
end

WZ_TASK_BRIDGE_PATCH.apply()
return WZ_TASK_BRIDGE_PATCH
