CBLibsRedEM = {}
local RedEM = CBLibsRedEM

local sharedObject
local function getSharedObject()
    if sharedObject then return sharedObject end
    TriggerEvent('redemrp:getSharedObject', function(object) sharedObject = object end)
    return sharedObject
end

function RedEM.GetPlayer(source)
    local core = getSharedObject()
    return core and core.GetPlayerFromId(source) or nil
end
function RedEM.GetIdentifier(source)
    local player = RedEM.GetPlayer(source)
    return player and player.getIdentifier() or nil
end
function RedEM.GetJob(source)
    local player = RedEM.GetPlayer(source)
    return player and player.getJob() or nil
end
function RedEM.GetMoney(source)
    local player = RedEM.GetPlayer(source)
    return player and player.getMoney() or 0
end
function RedEM.AddMoney(source, _, amount)
    local player = RedEM.GetPlayer(source)
    return player and player.addMoney(amount) or false
end
function RedEM.RemoveMoney(source, _, amount)
    local player = RedEM.GetPlayer(source)
    return player and player.removeMoney(amount) or false
end
function RedEM.HasPermission(source, permission)
    local player = RedEM.GetPlayer(source)
    return player and player.getGroup and player.getGroup() == permission or false
end
