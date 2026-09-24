-- WarZone Task Bindings
-- IMPORTANT: this adapter is embedded after the existing PLAYER MISSION BOARD in the
-- main WarZone mission chunk so it can bind stable web IDs to the proven local
-- requestMission/PLAYER_MISSIONS logic without duplicating CAP/CAS/SEAD/STRIKE gameplay.

WZ_TASK_BINDINGS = WZ_TASK_BINDINGS or {}
WZ_TASK_ACTIVE_BY_SIDE = WZ_TASK_ACTIVE_BY_SIDE or {}

local WEB_TASK_IDS = {
    [2] = { CAP=1101, SEAD=2101, CAS=3101, STRIKE=4101 },
    [1] = { CAP=1102, SEAD=2102, CAS=3102, STRIKE=4102 },
}

local function taskLog(text)
    if env and env.info then env.info('[WZ_TASK_BINDINGS] '..tostring(text)) end
end

local function registerRedTasks()
    if not WZ_TASKS or not WZ_TASKS.register then return end
    if not WZ_TASKS.get(1102) then
        WZ_TASKS.register({id=1102,type='CAP',title='Northern Guard',coalition=1,reward=50,
            objective='Establish fighter cover over the active Russian Federation frontline.',
            threats={'Enemy fighter activity','Long-range SAM coverage'},
            recommendedAircraft={'F-16C','F/A-18C','JF-17','F-15E'},
            briefing=[[RF AIR OPERATIONS // TASK 1102

Establish combat air patrol over friendly frontline territory.
The precise patrol area is assigned by the live WarZone mission board when the task is accepted.]]})
    end
    if not WZ_TASKS.get(2102) then
        WZ_TASKS.register({id=2102,type='SEAD',title='Radar Hunter',coalition=1,reward=45,
            objective='Suppress enemy radar-guided air defenses on the active frontline.',
            threats={'Radar-guided SAM','AAA','MANPADS','Enemy CAP'},
            recommendedAircraft={'F-16C','F/A-18C','JF-17'},
            briefing=[[RF AIR OPERATIONS // TASK 2102

Suppress the nearest eligible enemy air-defense group on the live frontline.
The exact AO and target group are assigned when the task is accepted.]]})
    end
    if not WZ_TASKS.get(3102) then
        WZ_TASKS.register({id=3102,type='CAS',title='Frontline Hammer',coalition=1,reward=55,
            objective='Neutralize enemy control of the nearest eligible frontline sector.',
            threats={'AAA','MANPADS','Armored vehicles'},
            recommendedAircraft={'A-10C II','F-16C','F/A-18C','JF-17'},
            briefing=[[RF AIR OPERATIONS // TASK 3102

Provide close air support against the nearest eligible enemy frontline sector.
The exact AO is assigned from the live campaign state when accepted.]]})
    end
    if not WZ_TASKS.get(4102) then
        WZ_TASKS.register({id=4102,type='STRIKE',title='Strategic Hammer',coalition=1,reward=20,
            objective='Destroy all remaining strategic static targets in the assigned enemy sector.',
            threats={'SAM','AAA','Enemy CAP'},
            recommendedAircraft={'F-15E','F-16C','F/A-18C','JF-17'},
            briefing=[[RF AIR OPERATIONS // TASK 4102

Strike the nearest eligible strategic target complex on the live frontline.
The exact AO and target set are assigned when accepted.]]})
    end
end

local function playerGroupId(side, playerName)
    for _,u in ipairs(coalition.getPlayers(side) or {}) do
        if u and u:isExist() and u:getPlayerName()==playerName then
            local g=u:getGroup()
            if g then return g:getID() end
        end
    end
    return nil
end

local function sectorForZone(zoneName)
    if WZ_SECTOR and WZ_SECTOR.getSectorIndex and zoneName then
        local ok,idx=pcall(WZ_SECTOR.getSectorIndex,WZ_SECTOR,zoneName)
        if ok then return idx end
    end
    return nil
end

local function setTaskFromMission(task,m)
    if not task or not m then return end
    task.status=m.objectiveComplete and 'RTB_REQUIRED' or 'ACTIVE'
    task.acceptedBy=m.requesterPlayer or task.acceptedBy
    task.acceptedAt=task.acceptedAt or m.started
    task.zone=m.zone
    task.sector=sectorForZone(m.zone)
    task.target=m.targetGroup
    task.reward=m.reward or task.reward
    task.requestRangeNm=m.requestRangeNm
    task.briefing=missionText(m)
end

local function markTerminal(side,success,reason)
    local id=WZ_TASK_ACTIVE_BY_SIDE[side]
    if not id then return end
    local task=WZ_TASKS and WZ_TASKS.get and WZ_TASKS.get(id) or nil
    if task then
        task.status=success and 'SUCCESS' or 'FAILED'
        task.completedAt=timer.getTime()
        task.webTerminalUntil=timer.getTime()+30
        if WarZoneWebBridge and WarZoneWebBridge.pushEvent then
            local sk=(side==2) and 'blue' or 'red'
            local text='Task #'..tostring(id)..' '..(success and 'completed' or 'closed')..': '..tostring(task.title)
            if reason then text=text..' - '..tostring(reason) end
            pcall(WarZoneWebBridge.pushEvent,sk,text,'task')
        end
    end
    WZ_TASK_ACTIVE_BY_SIDE[side]=nil
end

local function resetOffer(task)
    task.acceptedBy=nil
    task.acceptedAt=nil
    task.completedAt=nil
    task.webTerminalUntil=nil
    task.zone=nil
    task.sector=nil
    task.target=nil
    task.requestRangeNm=nil
end

local function availability(side)
    local enemyZones=frontlineEnemyZones(side)
    local patrolZones=frontlinePatrolZones(side)
    local seadList=seadCandidates(enemyZones)
    local strikeZones=WZ_STRIKE.candidates(side)
    return {
        CAP=#patrolZones>0,
        CAS=#enemyZones>0,
        SEAD=#seadList>0,
        STRIKE=#strikeZones>0,
    }
end

local function bindRequest(task,playerName)
    local side=task.coalition
    local groupId=playerGroupId(side,playerName)
    if not groupId then
        task.status='AVAILABLE'
        task.acceptedBy=nil
        trigger.action.outTextForCoalition(side,'WEB TASK REJECTED: requesting pilot is not in an active DCS player slot.',8)
        return
    end

    local before=PLAYER_MISSIONS[side]
    requestMission(side,task.type,groupId)
    local m=PLAYER_MISSIONS[side]
    if m and m~=before and m.type==task.type then
        WZ_TASK_ACTIVE_BY_SIDE[side]=task.id
        setTaskFromMission(task,m)
        taskLog('task #'..tostring(task.id)..' bound to live '..tostring(m.type)..' mission for '..tostring(playerName))
    elseif m and m.type==task.type and m.requesterPlayer==playerName then
        WZ_TASK_ACTIVE_BY_SIDE[side]=task.id
        setTaskFromMission(task,m)
    else
        task.status='AVAILABLE'
        task.acceptedBy=nil
        task.acceptedAt=nil
        taskLog('task #'..tostring(task.id)..' could not create live mission')
    end
end

local function installBindings()
    registerRedTasks()
    for side,ids in pairs(WEB_TASK_IDS) do
        for missionType,id in pairs(ids) do
            local task=WZ_TASKS.get(id)
            if task then
                task.sector=nil -- availability is controlled by the actual PLAYER MISSION BOARD, not a hardcoded sector.
                task.activationId='PLAYER_MISSION_BOARD:'..missionType
                task.defaultBriefing=task.briefing
                task.defaultObjective=task.objective
                task.defaultReward=task.reward
                WZ_TASK_BINDINGS[id]=bindRequest
            end
        end
    end
end

local originalClearMission=clearMission
clearMission=function(side,completed)
    local tracked=WZ_TASK_ACTIVE_BY_SIDE[side]
    originalClearMission(side,completed)
    if tracked then markTerminal(side,completed==true,completed and nil or 'CANCELLED / EXPIRED') end
end

local originalCompleteStrikeMission=completeStrikeMission
completeStrikeMission=function(side,m)
    local tracked=WZ_TASK_ACTIVE_BY_SIDE[side]
    originalCompleteStrikeMission(side,m)
    if tracked and not PLAYER_MISSIONS[side] then markTerminal(side,true) end
end

local originalCompletePatrolMission=completePatrolMission
completePatrolMission=function(side,m)
    originalCompletePatrolMission(side,m)
    local id=WZ_TASK_ACTIVE_BY_SIDE[side]
    local task=id and WZ_TASKS.get(id) or nil
    if task and m and m.objectiveComplete then
        task.status='RTB_REQUIRED'
        task.briefing=missionText(m)
    end
end

local originalMissionRTB=_G.WZ_OnPlayerMissionRTB
_G.WZ_OnPlayerMissionRTB=function(side,player,result)
    local tracked=WZ_TASK_ACTIVE_BY_SIDE[side]
    local before=PLAYER_MISSIONS[side]
    originalMissionRTB(side,player,result)
    if tracked and before and not PLAYER_MISSIONS[side] then
        markTerminal(side,result=='LANDED',result)
    end
end

local function taskSync(_,t)
    local ok,err=pcall(function()
        for side,ids in pairs(WEB_TASK_IDS) do
            local live=PLAYER_MISSIONS[side]
            local available=availability(side)

            if live and not WZ_TASK_ACTIVE_BY_SIDE[side] then
                local id=ids[live.type]
                if id then WZ_TASK_ACTIVE_BY_SIDE[side]=id end
            end

            for missionType,id in pairs(ids) do
                local task=WZ_TASKS.get(id)
                if task then
                    local tracked=(WZ_TASK_ACTIVE_BY_SIDE[side]==id)
                    if tracked and live and live.type==missionType then
                        setTaskFromMission(task,live)
                    elseif task.webTerminalUntil and t<task.webTerminalUntil then
                        -- Keep SUCCESS/FAILED visible briefly on the web dashboard.
                    else
                        resetOffer(task)
                        task.briefing=task.defaultBriefing or task.briefing
                        task.objective=task.defaultObjective or task.objective
                        task.reward=task.defaultReward or task.reward
                        if live then task.status='LOCKED'
                        else task.status=available[missionType] and 'AVAILABLE' or 'LOCKED' end
                    end
                end
            end
        end
    end)
    if not ok then taskLog('sync error: '..tostring(err)) end
    return t+2
end

installBindings()
timer.scheduleFunction(taskSync,nil,timer.getTime()+1)
taskLog('live Player Mission Board bindings enabled')

return WZ_TASK_BINDINGS
