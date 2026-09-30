CBLibsGUM = {}
local GUM = CBLibsGUM

-- GUM cores commonly expose an RSG/QBR-compatible core object. If yours does
-- not, select 'custom' and supply its methods in shared/config.lua.
function GUM.GetCore() return exports[CBLibsConfig.gumCoreResource]:GetCoreObject() end
function GUM.GetPlayer(source) return GUM.GetCore().Functions.GetPlayer(source) end
function GUM.GetIdentifier(source)
    local player = GUM.GetPlayer(source)
    return player and player.PlayerData.citizenid or nil
end
function GUM.GetJob(source)
    local player = GUM.GetPlayer(source)
    return player and player.PlayerData.job or nil
end
function GUM.GetMoney(source, account)
    local player = GUM.GetPlayer(source)
    return player and player.PlayerData.money[account or 'cash'] or 0
end
function GUM.AddMoney(source, account, amount, reason)
    local player = GUM.GetPlayer(source)
    return player and player.Functions.AddMoney(account or 'cash', amount, reason or 'cb-libs') or false
end
function GUM.RemoveMoney(source, account, amount, reason)
    local player = GUM.GetPlayer(source)
    return player and player.Functions.RemoveMoney(account or 'cash', amount, reason or 'cb-libs') or false
end
function GUM.HasPermission(source, permission) return GUM.GetCore().Functions.HasPermission(source, permission) end
