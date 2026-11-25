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
    if isQBStyle(provider) then
        local player = CBLibsRSG.GetPlayer(source)
        if player and player.PlayerData and player.PlayerData.items then return player.PlayerData.items end
        local ok, inventory = pcall(function() return exports[resource]:GetInventory(source) end)
        return ok and inventory and (inventory.items or inventory) or nil
    end
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
    if isQBStyle(provider) then return exports[resource]:AddItem(source, item, amount, nil, metadata, reason or 'cb-libs', true) and true or false end
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

-- Inventory adapters for the inspected upstream revisions.
local function redemAPI()
    local api; TriggerEvent('redemrp_inventory:getData',function(v) api=v end); return api
end
local function tpzAPI() return exports.tpz_inventory:getInventoryAPI() end
local function valid(n) return type(n)=='number' and n>0 and n%1==0 and n<math.huge end
local function matches(actual,wanted)
    if wanted==nil then return true end
    if type(wanted)~='table' then return actual==wanted end
    if type(actual)~='table' then return false end
    for k,v in pairs(wanted) do if not matches(actual[k],v) then return false end end
    return true
end
local function itemRows(provider,src)
    local raw=provider=='tpz' and tpzAPI().getInventoryContents(src) or redemAPI().getPlayerInventory(src)
    local out={}
    for _,v in pairs(raw or {}) do
        if type(v)=='table' then
            local item=v.item or v.name; local n=tonumber(v.quantity or v.amount or v.count) or 0
            if item and n>0 then out[#out+1]={name=item,item=item,amount=n,count=n,metadata=v.metadata or v.meta or {},info=v.metadata or v.meta or {},slot=v.itemId or v.id} end
        end
    end
    return out
end
local function count(provider,src,item,meta)
    if provider=='tpz' and meta==nil then return tonumber(tpzAPI().getItemQuantity(src,item)) or 0 end
    if provider=='redem' then local v=redemAPI().getItem(src,item,meta); return tonumber(v and v.ItemAmount) or 0 end
    local n=0; for _,v in ipairs(itemRows(provider,src)) do if v.name==item and matches(v.metadata,meta) then n=n+v.amount end end; return n
end
CBLibsExtraInventory={}
local X=CBLibsExtraInventory
function X.HasItemDefinitions() return true end
function X.GetItemDefinition(p,item) if p=='tpz' then return tpzAPI().getItemData(item) end; return redemAPI().getItemData(item) end
function X.GetInventory(p,src) return itemRows(p,src) end
function X.GetItem(p,src,item,meta) for _,v in ipairs(itemRows(p,src)) do if v.name==item and matches(v.metadata,meta) then return v end end end
function X.GetItemCount(p,src,item,meta) return count(p,src,item,meta) end
function X.CanAddItem(p,src,item,n,meta)
    local def=X.GetItemDefinition(p,item)
    if not valid(n) or not def then return false end
    if p=='tpz' then return tpzAPI().canCarryItem(src,item,n)==true end
    if def.type~='item_standard' or type(def.weight)~='number' or type(def.limit)~='number' then return false end
    local cfg=LoadResourceFile('redemrp_inventory','config.lua') or ''
    local max=tonumber(cfg:match('Config%.MaxWeight%s*=%s*([%d%.]+)'))
    if not max then return false end
    local weight=0
    for _,v in pairs(redemAPI().getPlayerInventory(src) or {}) do
        local w=tonumber(v.weight); local q=tonumber(v.amount)
        if not w or not q then return false end
        weight=weight+w*(v.type=='item_weapon' and 1 or q)
    end
    return weight+def.weight*n<=max and count(p,src,item,meta)+n<=def.limit
end
function X.AddItem(p,src,item,n,meta)
    if not X.CanAddItem(p,src,item,n,meta) then return false end
    local before=count(p,src,item,meta)
    if p=='tpz' then tpzAPI().addItem(src,item,n,meta)
    else
        local v=redemAPI().getItem(src,item,meta)
        if not v or not v.AddItem then return false end
        v.AddItem(n,false)
    end
    return count(p,src,item,meta)==before+n
end

function X.RemoveItem(p,src,item,n,meta)
    if not valid(n) then return false end
    local before=count(p,src,item,meta); if before<n then return false end
    if p=='redem' then local v=redemAPI().getItem(src,item,meta); if not v or not v.RemoveItem then return false end; v.RemoveItem(n)
    else
        local row=X.GetItem(p,src,item,meta); if not row or row.amount<n or not row.slot then return false end
        tpzAPI().removeItem(src,item,n,row.slot)
    end
    return count(p,src,item,meta)==before-n
end
local registeredUsables={}
function X.RegisterUsableItem(p,item,cb)
    if type(item)~='string' or type(cb)~='function' then return false end
    if registeredUsables[item] then return false,'Already registered' end
    if p=='tpz' then
        tpzAPI().registerUsableItem(item,GetCurrentResourceName(),function(args)
            local src=tonumber(args and args.source)
            if not src or not args.itemId then return end
            for _,v in ipairs(itemRows(p,src)) do
                if v.name==item and tostring(v.slot)==tostring(args.itemId) and v.amount>0 then
                    return cb(src,item,v)
                end
            end
        end)
    else
        AddEventHandler('RegisterUsableItem:'..item,function(src,args)
            if GetInvokingResource()~='redemrp_inventory' then return end
            local row=X.GetItem(p,src,item,nil)
            if row and row.amount>0 then return cb(src,item,row) end
        end)
    end
    registeredUsables[item]=true
    return true
end

function X.OpenStash() return false,'Storage provider not yet validated' end
