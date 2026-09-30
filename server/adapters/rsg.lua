CBLibsRSG = {}
local RSG = CBLibsRSG

function RSG.GetCore()
    return exports['rsg-core']:GetCoreObject()
end

function RSG.GetPlayer(source)
    return RSG.GetCore().Functions.GetPlayer(source)
end

function RSG.GetIdentifier(source)
    local player = RSG.GetPlayer(source)
    return player and player.PlayerData.citizenid or nil
end

function RSG.GetJob(source)
    local player = RSG.GetPlayer(source)
    return player and player.PlayerData.job or nil
end

function RSG.GetMoney(source, account)
    local player = RSG.GetPlayer(source)
    return player and player.PlayerData.money[account or 'cash'] or 0
end

function RSG.AddMoney(source, account, amount, reason)
    local player = RSG.GetPlayer(source)
    return player and player.Functions.AddMoney(account or 'cash', amount, reason or 'cb-libs') or false
end

function RSG.RemoveMoney(source, account, amount, reason)
    local player = RSG.GetPlayer(source)
    return player and player.Functions.RemoveMoney(account or 'cash', amount, reason or 'cb-libs') or false
end

function RSG.HasPermission(source, permission)
    return RSG.GetCore().Functions.HasPermission(source, permission)
end

return RSG
