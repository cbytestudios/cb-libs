local adapters = {
    rsg = CBLibsRSG,
    vorp = CBLibsVORP,
    tpz = CBLibsTPZ,
    custom = CBLibsCustom,
}

local detected = CBLibsProviders.Detect('framework')
local framework = CBLibsConfig.framework ~= 'auto' and CBLibsConfig.framework or detected[1] or (CBLibsCustomConfig.enabled and 'custom' or nil)
local adapter = framework and adapters[framework] or nil

if not adapter then
    print(('[cb-libs] No framework loaded. Check shared/config.lua.'):format(tostring(framework or 'none')))
else
    if #detected > 1 then
        print(('[cb-libs] Multiple frameworks detected (%s); using %s by built-in priority.'):format(table.concat(detected, ', '), framework))
    end
    print(('[cb-libs] %s framework loaded.'):format(framework))
end

local function call(method, ...)
    if not adapter then return nil, 'No cb-libs framework adapter is available.' end
    return adapter[method](...)
end

local function getPlayer(source)
    if not adapter then return nil end
    local player = adapter.GetPlayer(source)
    return adapter.NormalizePlayer and adapter.NormalizePlayer(player, source) or player
end

local detectedInventory = CBLibsProviders.Detect('inventory')
local inventoryProvider = CBLibsConfig.inventory ~= 'auto' and CBLibsConfig.inventory or detectedInventory[1] or (CBLibsCustomConfig.enabled and 'custom' or nil)

if not inventoryProvider then
    print('[cb-libs] No inventory loaded. Inventory exports will return nil/false.')
elseif #detectedInventory > 1 then
    print(('[cb-libs] Multiple inventories detected (%s); using %s by built-in priority.'):format(table.concat(detectedInventory, ', '), inventoryProvider))
else
    print(('[cb-libs] %s inventory loaded.'):format(inventoryProvider))
end

local function callInventory(method, ...)
    if not inventoryProvider then return nil, 'No cb-libs inventory provider is available.' end
    return CBLibsInventory[method](inventoryProvider, ...)
end

exports('GetFramework', function() return framework end)
exports('GetDetectedFrameworks', function() return detected end)
exports('GetInventoryProvider', function() return inventoryProvider end)
exports('GetDetectedInventories', function() return detectedInventory end)
exports('HasItemDefinitions', function() return CBLibsInventory.HasItemDefinitions(inventoryProvider) end)
exports('GetItemDefinition', function(item) return CBLibsInventory.GetItemDefinition(inventoryProvider, item) end)
exports('GetInventory', function(source) return callInventory('GetInventory', source) end)
exports('GetItem', function(source, item, metadata) return callInventory('GetItem', source, item, metadata) end)
exports('GetItemCount', function(source, item, metadata) return callInventory('GetItemCount', source, item, metadata) end)
exports('HasItem', function(source, item, amount, metadata) return (callInventory('GetItemCount', source, item, metadata) or 0) >= (amount or 1) end)
exports('CanAddItem', function(source, item, amount, metadata) return callInventory('CanAddItem', source, item, amount, metadata) end)
exports('AddItem', function(source, item, amount, metadata, reason) return callInventory('AddItem', source, item, amount, metadata, reason) end)
exports('RemoveItem', function(source, item, amount, metadata, reason) return callInventory('RemoveItem', source, item, amount, metadata, reason) end)
exports('RegisterUsableItem', function(item, callback) return callInventory('RegisterUsableItem', item, callback) end)
exports('OpenStash', function(source, id, options) return callInventory('OpenStash', source, id, options) end)
exports('CanUseItem', function(source, item, amount, metadata, remove, reason)
    if not ((callInventory('GetItemCount', source, item, metadata) or 0) >= (amount or 1)) then return false end
    if not remove then return true end
    return callInventory('RemoveItem', source, item, amount or 1, metadata, reason or 'cb-libs') and true or false
end)
exports('GetPlayer', getPlayer)
exports('GetPlayerData', function(source)
    local player = getPlayer(source)
    return player and player.PlayerData or nil
end)
exports('GetIdentifier', function(source) return call('GetIdentifier', source) end)
exports('GetJob', function(source) return call('GetJob', source) end)
exports('GetMoney', function(source, account) return call('GetMoney', source, account) end)
exports('AddMoney', function(source, account, amount, reason) return call('AddMoney', source, account, amount, reason) end)
exports('RemoveMoney', function(source, account, amount, reason) return call('RemoveMoney', source, account, amount, reason) end)
exports('HasPermission', function(source, permission) return call('HasPermission', source, permission) end)
exports('CanAfford', function(source, amount, account, remove, reason)
    amount = tonumber(amount) or 0
    if (tonumber(call('GetMoney', source, account)) or 0) < amount then return false end
    if not remove then return true end
    return call('RemoveMoney', source, account, amount, reason or 'cb-libs') and true or false
end)

RegisterNetEvent('cb-libs:server:requestPlayerData', function()
    local source = source
    local player = getPlayer(source)
    TriggerClientEvent('cb-libs:client:playerData', source, player and player.PlayerData or nil)
end)
