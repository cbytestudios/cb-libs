-- Inventory bridge for the supported RSG and VORP inventory APIs.
CBLibsInventory = {}
local Inventory = CBLibsInventory
local vorpStashes = {}

function Inventory.GetResource(provider)
    return CBLibsProviders.Resource('inventory', provider)
end

local function isQBStyle(provider)
    return provider == 'rsg'
end

function Inventory.HasItemDefinitions(provider)
    return isQBStyle(provider) or provider == 'vorp'
end

function Inventory.GetItemDefinition(provider, item)
    if provider == 'vorp' then
        local resource = Inventory.GetResource(provider)
        return resource and exports[resource]:getItemDB(item) or nil
    end
    if not isQBStyle(provider) then return nil end
    local coreResource = 'rsg-core'
    local core = exports[coreResource]:GetCoreObject()
    return core and core.Shared and core.Shared.Items and core.Shared.Items[item] or nil
end

function Inventory.GetInventory(provider, source)
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:getUserInventoryItems(source) end
    if isQBStyle(provider) then return exports[resource]:GetInventory(source) end
end

function Inventory.GetItem(provider, source, item, metadata)
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:getItem(source, item, metadata) end
    if isQBStyle(provider) then
        return exports[resource]:GetItemByName(source, item)
    end
end

function Inventory.GetItemCount(provider, source, item, metadata)
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:getItemCount(source, nil, item, metadata) or 0 end
    if isQBStyle(provider) then return exports[resource]:GetItemCount(source, item) or 0 end
    return 0
end

function Inventory.CanAddItem(provider, source, item, amount, metadata)
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:canCarryItem(source, item, amount) and true or false end
    if isQBStyle(provider) then return exports[resource]:CanAddItem(source, item, amount) and true or false end
    return false
end

function Inventory.AddItem(provider, source, item, amount, metadata, reason)
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then
        if not exports[resource]:canCarryItem(source, item, amount) then return false end
        return exports[resource]:addItem(source, item, amount, metadata) ~= false
    end
    if isQBStyle(provider) then return exports[resource]:AddItem(source, item, amount, metadata, nil, reason or 'cb-libs') and true or false end
    return false
end

function Inventory.RemoveItem(provider, source, item, amount, metadata, reason)
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then
        if (exports[resource]:getItemCount(source, nil, item, metadata) or 0) < amount then return false end
        return exports[resource]:subItem(source, item, amount, metadata) ~= false
    end
    if isQBStyle(provider) then return exports[resource]:RemoveItem(source, item, amount, nil, reason or 'cb-libs') and true or false end
    return false
end

function Inventory.RegisterUsableItem(provider, item, callback)
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then
        return exports[resource]:registerUsableItem(item, function(data)
            local name = type(data.item) == 'table' and data.item.name or item
            return callback(data.source, name, data)
        end)
    end
    if isQBStyle(provider) then
        local coreResource = 'rsg-core'
        local core = exports[coreResource]:GetCoreObject()
        return core.Functions.CreateUseableItem(item, function(source, itemData)
            callback(source, itemData and itemData.name or item, itemData)
        end)
    end
end

function Inventory.OpenStash(provider, source, id, options)
    local resource, cfg = Inventory.GetResource(provider), options or {}
    if provider == 'vorp' then
        if not vorpStashes[id] then
            exports[resource]:registerInventory({
                id = id,
                name = cfg.label or id,
                limit = cfg.weight or 100000,
                acceptWeapons = cfg.acceptWeapons == true,
                shared = cfg.shared ~= false,
                ignoreItemStackLimit = false,
                whitelistItems = false,
                UsePermissions = false,
                UseBlackList = false,
                whitelistWeapons = false,
            })
            vorpStashes[id] = true
        end
        exports[resource]:openInventory(source, id)
        return true
    end
    if isQBStyle(provider) then
        local data = { label = cfg.label, maxweight = cfg.weight, slots = cfg.slots }
        exports[resource]:CreateInventory(id, data)
        return exports[resource]:OpenInventory(source, id, data)
    end
end
