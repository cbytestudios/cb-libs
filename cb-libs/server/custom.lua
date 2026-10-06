-- Server-only hooks for an unsupported/private framework or inventory.
-- Set framework and/or inventory to 'custom' in shared/config.lua, then add
-- only the handlers required by your resources below.
CBLibsCustomConfig = {
    framework = {},
    inventory = {},
}

--[[
Framework example
-----------------
Replace `my-core` and its method names with your framework's API. GetPlayer may
return the original framework object; NormalizePlayer converts it to the common
CB Libs shape used by CBLibs.GetPlayer and CBLibs.GetPlayerData.

local Core = exports['my-core']:GetCoreObject()

CBLibsCustomConfig.framework.GetPlayer = function(source)
    return Core.GetPlayer(source)
end

CBLibsCustomConfig.framework.NormalizePlayer = function(player, source)
    if not player then return nil end

    local data = {
        citizenid = player.id,
        charinfo = {
            firstname = player.firstname or '',
            lastname = player.lastname or '',
            birthdate = player.birthdate,
            gender = player.gender,
        },
        job = {
            name = player.job or 'unemployed',
            label = player.jobLabel or player.job or 'Unemployed',
            grade = { level = tonumber(player.jobGrade) or 0 },
            onduty = player.onduty ~= false,
        },
        money = {
            cash = tonumber(player.cash) or 0,
            gold = tonumber(player.gold) or 0,
        },
    }

    return {
        PlayerData = data,
        Functions = {
            GetMoney = function(account)
                return data.money[account or 'cash'] or 0
            end,
            AddMoney = function(account, amount, reason)
                return player.AddMoney(account or 'cash', amount, reason or 'cb-libs')
            end,
            RemoveMoney = function(account, amount, reason)
                return player.RemoveMoney(account or 'cash', amount, reason or 'cb-libs')
            end,
        },
        raw = player,
    }
end

CBLibsCustomConfig.framework.GetIdentifier = function(source)
    local player = Core.GetPlayer(source)
    return player and player.id or nil
end

CBLibsCustomConfig.framework.GetJob = function(source)
    local player = Core.GetPlayer(source)
    return player and { name = player.job, grade = player.jobGrade } or nil
end

CBLibsCustomConfig.framework.GetMoney = function(source, account)
    local player = Core.GetPlayer(source)
    return player and player.GetMoney(account or 'cash') or 0
end

CBLibsCustomConfig.framework.AddMoney = function(source, account, amount, reason)
    local player = Core.GetPlayer(source)
    return player and player.AddMoney(account or 'cash', amount, reason or 'cb-libs') or false
end

CBLibsCustomConfig.framework.RemoveMoney = function(source, account, amount, reason)
    local player = Core.GetPlayer(source)
    return player and player.RemoveMoney(account or 'cash', amount, reason or 'cb-libs') or false
end

CBLibsCustomConfig.framework.HasPermission = function(source, permission)
    return IsPlayerAceAllowed(source, permission)
end


Inventory example
-----------------
Replace `my-inventory` and its exports with the custom inventory's API. Mutation
handlers should return true only when the operation succeeds.

local Inventory = exports['my-inventory']

CBLibsCustomConfig.inventory.GetItemDefinition = function(item)
    return Inventory:GetItemDefinition(item)
end

CBLibsCustomConfig.inventory.GetInventory = function(source)
    return Inventory:GetInventory(source)
end

CBLibsCustomConfig.inventory.GetItem = function(source, item, metadata)
    return Inventory:GetItem(source, item, metadata)
end

CBLibsCustomConfig.inventory.GetItemCount = function(source, item, metadata)
    return Inventory:GetItemCount(source, item, metadata) or 0
end

CBLibsCustomConfig.inventory.CanAddItem = function(source, item, amount, metadata)
    return Inventory:CanCarryItem(source, item, amount, metadata) == true
end

CBLibsCustomConfig.inventory.AddItem = function(source, item, amount, metadata, reason)
    return Inventory:AddItem(source, item, amount, metadata, reason or 'cb-libs') == true
end

CBLibsCustomConfig.inventory.RemoveItem = function(source, item, amount, metadata, reason)
    return Inventory:RemoveItem(source, item, amount, metadata, reason or 'cb-libs') == true
end

CBLibsCustomConfig.inventory.RegisterUsableItem = function(item, callback)
    return Inventory:RegisterUsableItem(item, function(source, itemData)
        callback(source, itemData)
    end)
end

CBLibsCustomConfig.inventory.OpenStash = function(source, id, options)
    return Inventory:OpenStash(source, id, options)
end
]]
