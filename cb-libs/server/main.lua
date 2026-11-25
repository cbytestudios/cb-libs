local adapters = {
    rsg = CBLibsRSG,
    vorp = CBLibsVORP,
    redem = CBLibsRedEM,
    tpz = CBLibsTPZ,
}

local detected = CBLibsProviders.Detect('framework')
local framework = CBLibsConfig.framework ~= 'auto' and CBLibsConfig.framework or detected[1]
local adapter = framework and adapters[framework] or nil
local prisonAdapter

-- Server-side custom framework adapter contract, API version 1.
-- Only explicitly configured bridge resources can register.
local customMethods = {'GetPlayerData','GetIdentifier','GetJob','GetMoney','AddMoney','RemoveMoney','HasPermission'}
local customOwner
exports('RegisterFrameworkAdapter', function(def)
    local owner = GetInvokingResource()
    if type(def) ~= 'table' or def.apiVersion ~= 1 then return false, 'Unsupported adapter contract' end
    if CBLibsConfig.customBridge == nil or owner ~= CBLibsConfig.customBridge then return false, 'Bridge resource not authorised' end
    if CBLibsConfig.framework ~= 'custom' then return false, 'Custom framework not enabled' end
    if type(def.name) ~= 'string' or def.name == '' then return false, 'Missing adapter name' end
    for _, method in ipairs(customMethods) do
        if type(def[method]) ~= 'function' then return false, 'Missing method: '..method end
    end
    if customOwner and customOwner ~= owner then return false, 'Adapter already registered' end
    local registered = {}
    for _, method in ipairs(customMethods) do registered[method] = def[method] end
    registered.GetPlayer = function(src)
        local data = registered.GetPlayerData(src)
        if type(data) ~= 'table' then return nil end
        return {PlayerData = data, Functions = {
            GetMoney = function(account) return registered.GetMoney(src, account) end,
            AddMoney = function(account, amount, reason) return registered.AddMoney(src, account, amount, reason) end,
            RemoveMoney = function(account, amount, reason) return registered.RemoveMoney(src, account, amount, reason) end,
        }}
    end
    customOwner = owner
    adapter = registered
    return true
end)
AddEventHandler('onResourceStop', function(resource)
    if resource == customOwner then adapter = nil; customOwner = nil end
end)


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
local inventoryProvider = CBLibsConfig.inventory ~= 'auto' and CBLibsConfig.inventory or detectedInventory[1]

if not inventoryProvider then
    print('[cb-libs] No inventory loaded. Inventory exports will return nil/false.')
elseif #detectedInventory > 1 then
    print(('[cb-libs] Multiple inventories detected (%s); using %s by built-in priority.'):format(table.concat(detectedInventory, ', '), inventoryProvider))
else
    print(('[cb-libs] %s inventory loaded.'):format(inventoryProvider))
end

local customInventory, customInventoryOwner
local inventoryMethods = {'HasItemDefinitions','GetItemDefinition','GetInventory','GetItem','GetItemCount','CanAddItem','AddItem','RemoveItem','RegisterUsableItem','OpenStash'}
exports('RegisterInventoryAdapter', function(def)
    local owner=GetInvokingResource()
    if not owner or owner~=CBLibsConfig.customBridge or CBLibsConfig.inventory~='custom' then return false,'Bridge not authorised' end
    if type(def)~='table' or def.apiVersion~=1 then return false,'Unsupported adapter contract' end
    local copy={}
    for _,method in ipairs(inventoryMethods) do
        if type(def[method])~='function' then return false,'Missing method: '..method end
        copy[method]=def[method]
    end
    customInventory=copy; customInventoryOwner=owner
    return true
end)
AddEventHandler('onResourceStop',function(resource)
    if resource==customInventoryOwner then customInventory=nil; customInventoryOwner=nil end
end)

local function callInventory(method, ...)
    if inventoryProvider == 'redem' or inventoryProvider == 'tpz' then return CBLibsExtraInventory[method](inventoryProvider, ...) end
    if inventoryProvider == 'custom' then if not customInventory then return nil end; return customInventory[method](...) end
    if not inventoryProvider then return nil, 'No cb-libs inventory provider is available.' end
    return CBLibsInventory[method](inventoryProvider, ...)
end

exports('GetFramework', function() return framework end)
exports('GetDetectedFrameworks', function() return detected end)
exports('GetInventoryProvider', function() return inventoryProvider end)
exports('GetDetectedInventories', function() return detectedInventory end)
exports('HasItemDefinitions', function() return callInventory('HasItemDefinitions') end)
exports('GetItemDefinition', function(item) return callInventory('GetItemDefinition', item) end)
exports('GetInventory', function(source) return callInventory('GetInventory', source) end)
exports('GetItem', function(source, item, metadata) return callInventory('GetItem', source, item, metadata) end)
exports('GetItemCount', function(source, item, metadata) return callInventory('GetItemCount', source, item, metadata) end)
exports('HasItem', function(source, item, amount, metadata) return (callInventory('GetItemCount', source, item, metadata) or 0) >= (amount or 1) end)
exports('CanAddItem', function(source, item, amount, metadata) return callInventory('CanAddItem', source, item, amount, metadata) end)
exports('AddItem', function(source, item, amount, metadata, reason) return callInventory('AddItem', source, item, amount, metadata, reason) end)
exports('RemoveItem', function(source, item, amount, metadata, reason) return callInventory('RemoveItem', source, item, amount, metadata, reason) end)
exports('RegisterUsableItem', function(item, callback) return callInventory('RegisterUsableItem', item, callback) end)
-- Native stash grants are server-owned and scoped to the calling resource.
local nativeGrants = {}
local nativeProviders = {redem='redemrp_inventory',tpz='tpz_inventory'}
local function nativeGrant(source,id)
    local grants=nativeGrants[source]
    local grant=grants and grants[id]
    if not grant or grant.expires < os.time() or GetResourceState(grant.owner)~='started' then return nil end
    local cid=call('GetIdentifier',source)
    if not cid or tostring(cid)~=grant.character then return nil end
    local ok,allowed=pcall(grant.authorize,source,grant.logicalId)
    if not ok or allowed~=true then return nil end
    return {weight=grant.weight,slots=grant.slots}
end
exports('CanAccessNativeStash',function(source,id)
    if GetInvokingResource()~=nativeProviders[inventoryProvider] then return nil end
    return nativeGrant(source,id)
end)
exports('HasNativeStash',function()
    local res=nativeProviders[inventoryProvider]
    if not res then return false end
    local ok,version=pcall(function()return exports[res]:CBNativeStashVersion()end)
    return ok and version==1
end)
local function openNative(source,id,options)
    local res=nativeProviders[inventoryProvider]
    local owner=GetInvokingResource()
    local cid=call('GetIdentifier',source)
    if not res or not owner or not cid or type(id)~='string' or type(options)~='table' or type(options.authorize)~='function' then return false,'Native stash requires a server authorization callback.' end
    if #id>80 or not id:match('^[%w_:%-%.]+$') then return false,'Invalid stash identifier.' end
    local weight=tonumber(options.weight)
    local slots=tonumber(options.slots)
    if not weight or weight<=0 or weight>10000000 or not slots or slots%1~=0 or slots<1 or slots>1000 then return false,'Invalid storage capacity.' end
    local key='cb-secure:'..owner..':'..id
    local grants=nativeGrants[source] or {}
    nativeGrants[source]=grants
    grants[key]={owner=owner,character=tostring(cid),logicalId=id,authorize=options.authorize,weight=weight/1000,slots=slots,expires=os.time()+1800}
    if not nativeGrant(source,key) then grants[key]=nil; return false,'Access denied.' end
    local ok,result=pcall(function()return exports[res]:CBOpenStash(source,key,options.label or id)end)
    if not ok or result~=true then grants[key]=nil; return false,'Native stash patch unavailable or stash failed to open.' end
    return true
end
AddEventHandler('playerDropped',function()nativeGrants[source]=nil end)
AddEventHandler('onResourceStop',function(resource)
    for _,grants in pairs(nativeGrants) do for id,grant in pairs(grants) do if grant.owner==resource then grants[id]=nil end end end
end)

exports('OpenStash', function(source,id,options)
    if nativeProviders[inventoryProvider] then return openNative(source,id,options) end
    return callInventory('OpenStash',source,id,options)
end)
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
exports('RegisterPrisonAdapter', function(callback)
    if type(callback) ~= 'function' then return false end
    prisonAdapter = callback
    return true
end)
exports('HasPrisonAdapter', function()
    return prisonAdapter ~= nil or (framework == 'rsg' and GetResourceState('rsg-prison') == 'started')
end)
exports('JailPlayer', function(officer, target, minutes, reason)
    minutes = math.max(0, math.floor(tonumber(minutes) or 0))
    if minutes < 1 then return false, 'A valid jail sentence is required.' end
    if prisonAdapter then return prisonAdapter(officer, target, minutes, reason) end
    if framework == 'rsg' and GetResourceState('rsg-prison') == 'started' then
        local player = CBLibsRSG.GetPlayer(target)
        if not player then return false, 'The citizen is not available.' end
        player.Functions.SetMetaData('injail', minutes)
        TriggerClientEvent('rsg-prison:client:Enter', target, minutes)
        return true
    end
    return false, ('No prison adapter is registered for %s.'):format(framework or 'this framework')
end)

local playerDataRequests = {}
AddEventHandler('playerDropped', function() playerDataRequests[source] = nil end)
RegisterNetEvent('cb-libs:server:requestPlayerData', function()
    local source = source
    local now = GetGameTimer()
    if playerDataRequests[source] and now-playerDataRequests[source]<1000 then return end
    playerDataRequests[source] = now
    local player = getPlayer(source)
    TriggerClientEvent('cb-libs:client:playerData', source, player and player.PlayerData or nil)
end)
