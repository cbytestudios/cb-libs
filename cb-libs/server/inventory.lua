-- Inventory bridge for the supported RSG, VORP, and TPZ inventory APIs.
CBLibsInventory = {}
local Inventory = CBLibsInventory

function Inventory.GetResource(provider)
    return CBLibsProviders.Resource('inventory', provider)
end

local function custom(method, ...)
    local handler = CBLibsCustomConfig.inventory[method]
    if type(handler) ~= 'function' then return nil end
    return handler(...)
end

local function isQBStyle(provider)
    return provider == 'rsg'
end

local function tpzInventory()
    return exports.tpz_inventory:getInventoryAPI()
end

function Inventory.HasItemDefinitions(provider)
    return isQBStyle(provider) or provider == 'tpz'
end

function Inventory.GetItemDefinition(provider, item)
    if provider == 'custom' then return custom('GetItemDefinition', item) end
    if provider == 'tpz' then return tpzInventory().getItemData(item) end
    if not isQBStyle(provider) then return nil end
    local coreResource = 'rsg-core'
    local core = exports[coreResource]:GetCoreObject()
    return core and core.Shared and core.Shared.Items and core.Shared.Items[item] or nil
end

function Inventory.GetInventory(provider, source)
    if provider == 'custom' then return custom('GetInventory', source) end
    if provider == 'tpz' then return tpzInventory().getInventoryContents(source) end
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:getUserInventoryItems(source) end
    if isQBStyle(provider) then return exports[resource]:GetInventory(source) end
end

function Inventory.GetItem(provider, source, item, metadata)
    if provider == 'custom' then return custom('GetItem', source, item, metadata) end
    if provider == 'tpz' then
        for _, stack in pairs(tpzInventory().getInventoryContents(source) or {}) do
            if stack.item == item then return stack end
        end
        return nil
    end
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:getItem(source, item, metadata) end
    if isQBStyle(provider) then
        return exports[resource]:GetItemByName(source, item)
    end
end

function Inventory.GetItemCount(provider, source, item, metadata)
    if provider == 'custom' then return custom('GetItemCount', source, item, metadata) or 0 end
    if provider == 'tpz' then return tpzInventory().getItemQuantity(source, item) or 0 end
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:getItemCount(source, nil, item, metadata) or 0 end
    if isQBStyle(provider) then return exports[resource]:GetItemCount(source, item) or 0 end
    return 0
end

function Inventory.CanAddItem(provider, source, item, amount, metadata)
    if provider == 'custom' then return custom('CanAddItem', source, item, amount, metadata) and true or false end
    if provider == 'tpz' then return tpzInventory().canCarryItem(source, item, amount) and true or false end
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:canCarryItem(source, item, amount) and true or false end
    if isQBStyle(provider) then return exports[resource]:CanAddItem(source, item, amount) and true or false end
    return false
end

function Inventory.AddItem(provider, source, item, amount, metadata, reason)
    if provider == 'custom' then return custom('AddItem', source, item, amount, metadata, reason) and true or false end
    if provider == 'tpz' then
        if not tpzInventory().canCarryItem(source, item, amount) then return false end
        tpzInventory().addItem(source, item, amount, metadata)
        return true
    end
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:addItem(source, item, amount, metadata) and true or false end
    if isQBStyle(provider) then return exports[resource]:AddItem(source, item, amount, metadata, nil, reason or 'cb-libs') and true or false end
    return false
end

function Inventory.RemoveItem(provider, source, item, amount, metadata, reason)
    if provider == 'custom' then return custom('RemoveItem', source, item, amount, metadata, reason) and true or false end
    if provider == 'tpz' then
        if (tpzInventory().getItemQuantity(source, item) or 0) < amount then return false end
        tpzInventory().removeItem(source, item, amount)
        return true
    end
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then return exports[resource]:subItem(source, item, amount, metadata) and true or false end
    if isQBStyle(provider) then return exports[resource]:RemoveItem(source, item, amount, nil, reason or 'cb-libs') and true or false end
    return false
end

function Inventory.RegisterUsableItem(provider, item, callback)
    if provider == 'custom' then return custom('RegisterUsableItem', item, callback) end
    if provider == 'tpz' then
        return tpzInventory().registerUsableItem(item, GetCurrentResourceName(), function(data)
            callback(data.source, data)
        end)
    end
    local resource = Inventory.GetResource(provider)
    if provider == 'vorp' then
        return exports[resource]:registerUsableItem(item, function(data)
            return callback(data.source, data.item)
        end)
    end
    if isQBStyle(provider) then
        local coreResource = 'rsg-core'
        local core = exports[coreResource]:GetCoreObject()
        return core.Functions.CreateUseableItem(item, function(source, itemData) callback(source, itemData) end)
    end
end

function Inventory.OpenStash(provider, source, id, options)
    if provider == 'custom' then return custom('OpenStash', source, id, options or {}) end
    -- TPZ exposes container read/write APIs but no supported create/open-stash API.
    -- A server can add that UI flow through server/custom.lua.
    if provider == 'tpz' then return custom('OpenStash', source, id, options or {}) end
    local resource, cfg = Inventory.GetResource(provider), options or {}
    if provider == 'vorp' then return exports[resource]:openInventory(source, id) end
    if isQBStyle(provider) then
        local data = { label = cfg.label, maxweight = cfg.weight, slots = cfg.slots }
        exports[resource]:CreateInventory(id, data)
        return exports[resource]:OpenInventory(source, id, data)
    end
end
