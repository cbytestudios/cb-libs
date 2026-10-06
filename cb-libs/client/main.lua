local function detectFramework()
    return CBLibsConfig.framework ~= 'auto' and CBLibsConfig.framework or CBLibsProviders.Detect('framework')[1]
end

local framework = detectFramework()
local cachedPlayerData

local function detectedFrameworks()
    return CBLibsProviders.Detect('framework')
end

local function getPlayerData()
    local coreResource = framework == 'rsg' and 'rsg-core'
    if coreResource and GetResourceState(coreResource) == 'started' then
        local ok, data = pcall(function() return exports[coreResource]:GetCoreObject().Functions.GetPlayerData() end)
        if ok then return data end
    end

    if framework == 'vorp' and GetResourceState('vorp_core') == 'started' then
        local ok, character = pcall(function()
            local core = exports.vorp_core:GetCore()
            return core.GetCharacterData and core.GetCharacterData() or nil
        end)
        if ok and character then
            return {
                citizenid = character.identifier or character.charIdentifier,
                charinfo = { firstname = character.firstname or '', lastname = character.lastname or '' },
                job = { name = character.job or 'unemployed', label = character.jobLabel or character.job, grade = { level = tonumber(character.jobGrade) or 0 }, onduty = true },
                money = { cash = tonumber(character.money) or 0, gold = tonumber(character.gold) or 0, rol = tonumber(character.rol) or 0 },
            }
        end
    end

    if framework == 'tpz' and GetResourceState('tpz_core') == 'started' then
        local ok, character = pcall(function()
            return exports.tpz_core:getCoreAPI().GetPlayerClientData()
        end)
        if ok and character then
            return {
                citizenid = character.charIdentifier or character.identifier,
                charinfo = { firstname = character.firstname or '', lastname = character.lastname or '', birthdate = character.dob, gender = character.gender },
                job = { name = character.job or 'unemployed', label = character.job or 'Unemployed', grade = { level = tonumber(character.jobGrade) or 0 }, onduty = true },
                money = { cash = tonumber(character.money) or 0, gold = tonumber(character.gold) or 0, blackmoney = tonumber(character.blackmoney) or 0 },
            }
        end
    end
    return cachedPlayerData
end

local function requestPlayerData()
    TriggerServerEvent('cb-libs:server:requestPlayerData')
end

local function notify(data)
    data = data or {}
    local provider = CBLibsConfig.notifications
    if provider == 'auto' then
        provider = framework
            or (GetResourceState('bln_notify') == 'started' and 'bln')
            or (GetResourceState('ox_lib') == 'started' and 'ox_lib')
    end

    if provider == 'bln' and GetResourceState('bln_notify') == 'started' then
        local templateByType = {
            success = 'SUCCESS',
            error = 'ERROR',
            warning = 'TIP',
            inform = 'INFO',
            info = 'INFO',
        }
        local options = {
            title = data.title or 'Codebyte',
            description = data.description or data.text or '',
            icon = data.icon,
            placement = data.placement or 'middle-right',
            duration = data.duration,
            progress = data.progress,
            keyActions = data.keyActions,
            isRTL = data.isRTL,
            contentAlignment = data.contentAlignment,
        }
        exports.bln_notify:send(options, data.template or templateByType[data.type])
        return true
    end

    if provider == 'ox_lib' and GetResourceState('ox_lib') == 'started' then
        lib.notify(data)
        return true
    end

    if provider == 'rsg' and GetResourceState('rsg-core') == 'started' then
        local core = exports['rsg-core']:GetCoreObject()
        core.Functions.Notify(data)
        return true
    end

    if provider == 'tpz' and GetResourceState('tpz_core') == 'started' then
        exports.tpz_core:getCoreAPI().NotifyTip(data.description or data.text or '', data.duration or 4000)
        return true
    end

    if provider == 'vorp' and GetResourceState('vorp_core') == 'started' then
        exports.vorp_core:GetCore().NotifyRightTip(data.description or data.text or '', data.duration or 4000)
        return true
    end

    return false
end

local function progress(data)
    if GetResourceState('ox_lib') == 'started' then return lib.progressCircle(data) end
    return false
end

local function keybind(name)
    local resource = framework == 'rsg' and 'rsg-core'
    if not resource or GetResourceState(resource) ~= 'started' then return nil end
    local core = exports[resource]:GetCoreObject()
    return core.Shared and core.Shared.Keybinds and core.Shared.Keybinds[name] or nil
end

local fallbackPrompts = {}
local fallbackPromptThread = false

local function runPrompt(prompt)
    local options = prompt.options or {}
    local args = options.args or {}
    if options.type == 'server' then
        TriggerServerEvent(options.event, table.unpack(args))
    else
        TriggerEvent(options.event, table.unpack(args))
    end
end

local function ensureFallbackPromptThread()
    if fallbackPromptThread then return end
    fallbackPromptThread = true
    CreateThread(function()
        local showing = false
        while next(fallbackPrompts) do
            local closest, closestDistance
            local coords = GetEntityCoords(PlayerPedId())
            for _, prompt in pairs(fallbackPrompts) do
                local distance = #(coords - prompt.coords)
                if distance <= 2.0 and (not closestDistance or distance < closestDistance) then
                    closest, closestDistance = prompt, distance
                end
            end
            if closest then
                if GetResourceState('ox_lib') == 'started' then
                    lib.showTextUI(('[%s] %s'):format(closest.key or 'E', closest.label))
                    showing = true
                end
                if IsControlJustReleased(0, closest.control or 0xCEFD9220) then runPrompt(closest) end
                Wait(0)
            else
                if showing and GetResourceState('ox_lib') == 'started' then lib.hideTextUI() end
                showing = false
                Wait(200)
            end
        end
        if showing and GetResourceState('ox_lib') == 'started' then lib.hideTextUI() end
        fallbackPromptThread = false
    end)
end

local function createPrompt(id, coords, control, label, options)
    if framework == 'rsg' and GetResourceState('rsg-core') == 'started' then
        return exports['rsg-core']:createPrompt(id, coords, control, label, options)
    end
    local handle = ('cb-libs:%s'):format(id)
    fallbackPrompts[handle] = { coords = coords, control = control, label = label, options = options }
    ensureFallbackPromptThread()
    return handle
end

local function deletePrompt(handle)
    if framework == 'rsg' and GetResourceState('rsg-core') == 'started' then
        return exports['rsg-core']:deletePrompt(handle)
    end
    fallbackPrompts[handle] = nil
    return true
end

exports('GetFramework', function() return framework end)
exports('GetDetectedFrameworks', detectedFrameworks)
exports('GetPlayerData', getPlayerData)
exports('Notify', notify)
exports('Progress', progress)
exports('GetKeybind', keybind)
exports('CreatePrompt', createPrompt)
exports('DeletePrompt', deletePrompt)

RegisterNetEvent('cb-libs:client:playerData', function(data)
    cachedPlayerData = data
    TriggerEvent('cb-libs:client:playerDataUpdated', data)
    if framework == 'vorp' and data then
        TriggerEvent('cb-libs:client:playerLoaded', data)
    end
end)

-- Resources consume these neutral lifecycle events instead of framework events.
if framework == 'rsg' then
    RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
        TriggerEvent('cb-libs:client:playerLoaded', getPlayerData())
    end)
    RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
        TriggerEvent('cb-libs:client:playerUnloaded')
    end)
    RegisterNetEvent('RSGCore:Player:SetPlayerData', function(data)
        TriggerEvent('cb-libs:client:playerDataUpdated', data)
    end)
elseif framework == 'tpz' then
    RegisterNetEvent('tpz_core:isPlayerReady', function()
        TriggerEvent('cb-libs:client:playerLoaded', getPlayerData())
    end)
    RegisterNetEvent('tpz_core:getPlayerJob', function()
        TriggerEvent('cb-libs:client:playerDataUpdated', getPlayerData())
    end)
elseif framework == 'vorp' then
    RegisterNetEvent('vorp:SelectedCharacter', function()
        requestPlayerData()
        TriggerEvent('cb-libs:client:playerLoaded', getPlayerData())
    end)
end

CreateThread(function()
    Wait(1000)
    requestPlayerData()
end)
