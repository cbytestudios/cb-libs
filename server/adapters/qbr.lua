CBLibsQBR = {}
local QBR = CBLibsQBR

function QBR.GetCore() return exports['qbr-core']:GetCoreObject() end
function QBR.GetPlayer(source) return QBR.GetCore().Functions.GetPlayer(source) end
function QBR.GetIdentifier(source)
    local player = QBR.GetPlayer(source)
    return player and player.PlayerData.citizenid or nil
end
function QBR.GetJob(source)
    local player = QBR.GetPlayer(source)
    return player and player.PlayerData.job or nil
end
function QBR.GetMoney(source, account)
    local player = QBR.GetPlayer(source)
    return player and player.PlayerData.money[account or 'cash'] or 0
end
function QBR.AddMoney(source, account, amount, reason)
    local player = QBR.GetPlayer(source)
    return player and player.Functions.AddMoney(account or 'cash', amount, reason or 'cb-libs') or false
end
function QBR.RemoveMoney(source, account, amount, reason)
    local player = QBR.GetPlayer(source)
    return player and player.Functions.RemoveMoney(account or 'cash', amount, reason or 'cb-libs') or false
end
function QBR.HasPermission(source, permission) return QBR.GetCore().Functions.HasPermission(source, permission) end
