"""Apply scoped native storage compatibility patch to the exact upstream revision.
Run: python apply-native-storage.py redem|tpz PATH_TO_INVENTORY_RESOURCE
Back up and stop inventory before applying. No network access is used.
"""
from pathlib import Path
import sys, hashlib, shutil, re
REVISIONS={'redem':'ed5fb0a2cabfb780e2b4eefa239c68323a34a2fc','tpz':'2db8c5bb83b23e9d7784844fd264818edd4fd3d1'}
# Hashes filled from the pinned upstream files during packaging.
HASHES = {'redem': '167617fbee7f821d7df34dbcf48354be638017d7eef2503f850761c4a4c0218b', 'tpz': '95393e6c985f4f20b526130de8a61fcac31b1f1d6d0233ff3b25e21deb6cb12d'}
def replace(s,a,b):
    if s.count(a)!=1: raise ValueError('Patch anchor not unique: '+a[:100])
    return s.replace(a,b,1)
common="""-- Codebyte native storage v1: restricted namespace, server-owned access grants.
local function cbProtected(name)
    return type(name)=='string' and name:lower():sub(1,10)=='cb-secure:'
end
local function cbGrant(src,name)
    if not cbProtected(name) or GetResourceState('cb-libs')~='started' then return nil end
    local ok,grant=pcall(function() return exports['cb-libs']:CanAccessNativeStash(tonumber(src),name) end)
    return ok and grant or nil
end
exports('CBNativeStashVersion',function() return 1 end)
"""
def redem(s):
    a='local Stash = {}'
    s=replace(s,a,a+'\n'+common+"""
exports('CBOpenStash',function(src,id,label)
    if GetInvokingResource()~='cb-libs' then return false end
    local grant=cbGrant(src,id)
    if not grant then return false end
    TriggerClientEvent('redemrp_inventory:OpenStash',src,id,grant.weight)
    return true
end)
""")
    a='function(_type, data, target, LockerID, stashId)\n'
    s=replace(s,a,a+"""        if cbProtected(stashId) then
            local src=source
            local grant=cbGrant(src,stashId)
            if not grant or target~=0 or (_type~='add' and _type~='delete') or type(data)~='table' or type(data.name)~='string' then return end
            local qty=tonumber(data.amount)
            if not qty or qty<1 or qty%1~=0 or qty>100000 or (data.meta~=nil and type(data.meta)~='table') then return end
            local def=Config.Items[data.name]
            local player=RedEM.GetPlayer(src)
            if not def or not player or not Stash[stashId] then return end
            if def.type~='item_standard' and qty~=1 then return end
            local inv=Inventory[player.GetIdentifier()..'_'..player.GetActiveCharacter()]
            local origin=_type=='delete' and inv or Stash[stashId]
            local dest=_type=='delete' and Stash[stashId] or inv
            local item=getInventoryItemFromName(data.name,origin or {},getMetaOutput(data.meta))
            if not item or item.getAmount()<qty then return end
            local meta=item.getMeta() or {}
            if not deep_compare(meta,data.meta or {}) then return end
            local existing=getInventoryItemFromName(data.name,dest or {},getMetaOutput(meta))
            if def.type~='item_standard' and existing then return end
            if _type=='delete' then
                if not existing and #dest>=grant.slots then return end
                if GetStashWeight(stashId)+def.weight*(def.type=='item_standard' and qty or 1)>grant.weight then return end
            else
                local weight=InventoryWeight[player.GetIdentifier()..'_'..player.GetActiveCharacter()]
                if not weight or weight+def.weight*(def.type=='item_standard' and qty or 1)>Config.MaxWeight then return end
                if def.type=='item_standard' and qty+(existing and existing.getAmount() or 0)>def.limit then return end
            end
            StashMaxWeights[src]=grant.weight
            -- Use authoritative native metadata, never the client table.
            data={name=item.getName(),amount=qty,meta=meta}
        end
""")
    a='function(id, weight)\n        --print(weight)'
    s=replace(s,a,'''function(id, weight)
        if cbProtected(id) then
            local grant=cbGrant(source,id)
            if not grant then return end
            weight=grant.weight
        end
        --print(weight)''')
    return s
def tpz(s):
    a='Containers = {}'
    s=replace(s,a,a+'\n'+common+"""
local cbLoading={}
local function cbContainer(id)
    local c=Containers[tonumber(id)]
    return c and cbProtected(c.name) and c or nil
end
local function cbQuery(q,params)
    local p=promise.new()
    exports.ghmattimysql:execute(q,params,function(rows) p:resolve(rows or {}) end)
    return Citizen.Await(p)
end
exports('CBOpenStash',function(src,name,label)
    if GetInvokingResource()~='cb-libs' or not cbGrant(src,name) or cbLoading[name] then return false end
    cbLoading[name]=true
    local ok,result=pcall(function()
        local grant=cbGrant(src,name)
        if not grant then return false end
        local id=GetContainerIdByName(name)
        if not id then
            local rows=cbQuery('SELECT * FROM containers WHERE name=@name',{name=name})
            if #rows==0 then
                cbQuery('INSERT INTO containers (name,weight,items,data) VALUES (@name,@weight,@items,@data)',{name=name,weight=math.ceil(grant.weight),items='[]',data='{"allowlisted":true}'})
                rows=cbQuery('SELECT * FROM containers WHERE name=@name',{name=name})
            end
            if #rows~=1 then return false end
            local row=rows[1]
            id=tonumber(row.id)
            if not id then return false end
            if not Containers[id] then Containers[id]={id=id,name=name,inventory=json.decode(row.items or '[]'),data={allowlisted=true},busy=false,maxWeight=grant.weight} end
        end
        grant=cbGrant(src,name)
        local c=Containers[id]
        if not grant or not c or c.name~=name then return false end
        c.maxWeight=grant.weight
        c.data=c.data or {}; c.data.allowlisted=true
        TriggerClientEvent('tpz_inventory:openInventoryContainerById',src,id,label or name,false,false)
        return true
    end)
    cbLoading[name]=nil
    return ok and result==true
end)
local function cbEqual(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not cbEqual(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function cbCopy(v) return json.decode(json.encode(v)) end
local function cbMove(src,c,direction,item,quantity,clientCallback)
    local grant=cbGrant(src,c.name)
    local qty=tonumber(quantity)
    if not grant or clientCallback~=nil or (direction~='main' and direction~='container') or type(item)~='table' or type(item.item)~='string' or not qty or qty%1~=0 or qty<1 or qty>100000 then return end
    local player=PlayerInventory[src]
    if not player or type(player.inventory)~='table' then return end
    local from=direction=='main' and player.inventory or c.inventory
    local dest=direction=='main' and c.inventory or player.inventory
    local index,row
    for i,v in ipairs(from) do
        if v.item==item.item and tostring(v.itemId)==tostring(item.itemId) and (v.type=='item' or v.type=='weapon') then
            if row then return end
            index,row=i,v
        end
    end
    if not row or not row.itemId or (tonumber(row.quantity) or 0)<qty then return end
    local weapon=row.type=='weapon'
    local definition=weapon and SharedWeapons.Weapons[string.upper(row.item)] or SharedItems[row.item]
    if not definition then return end
    local stacked=not weapon and tonumber(definition.stackable)==1
    if not stacked and qty~=1 then return end
    local existing
    for _,v in ipairs(dest) do
        if v.item==row.item then
            if stacked then
                -- TPZ uses one stack per item name; never merge different metadata.
                if existing or not cbEqual(v.metadata or {},row.metadata or {}) then return end
                existing=v
            elseif tostring(v.itemId)==tostring(row.itemId) then return end
        end
    end
    local weight=tonumber(definition.weight)
    if not weight or weight<0 then return end
    if direction=='main' then
        if getContainerWeight(c.id)+weight*qty>grant.weight or (not existing and #dest>=grant.slots) then return end
    elseif weapon then
        if not canCarryWeapon(src,row.item) then return end
    elseif not canCarryItem(src,row.item,qty) then return end
    local moved=cbCopy(row)
    moved.quantity=qty; moved.amount=qty; moved.count=qty
    local left=row.quantity-qty
    if left==0 then table.remove(from,index) else row.quantity=left; row.amount=left; row.count=left end
    if existing then existing.quantity=existing.quantity+qty; existing.amount=existing.quantity; existing.count=existing.quantity
    else dest[#dest+1]=moved end
    if weapon and direction=='main' then
        local p=TPZ.GetPlayer(src)
        if p and p.loaded() then
            local defaults=p.getDefaultUsedWeaponIds()
            local id=moved.itemId
            local normalized=normalizeItemId(id)
            if defaults[id] then p.removeDefaultWeaponById(id); TriggerClientEvent('tpz_weapons:client:removeEquippedWeaponById',src,id) end
            if normalized~=id and defaults[normalized] then p.removeDefaultWeaponById(normalized); TriggerClientEvent('tpz_weapons:client:removeEquippedWeaponById',src,normalized) end
        end
    end
    -- Persist through the same native storage/player database paths.
    exports.ghmattimysql:execute('UPDATE containers SET items=@items,weight=@weight WHERE id=@id',{items=json.encode(c.inventory),weight=math.ceil(grant.weight),id=c.id})
    saveInventoryContents(src,false)
    TriggerClientEvent('tpz_inventory:updatePlayerInventoryContents',src,player,true,false)
    moved.transfer_quantity=qty
    TriggerClientEvent('tpz_inventory:onTransferItemUpdate',src,direction,moved)
end
""")
    # Block alternate network mutation paths into the protected namespace.
    s=replace(s,'function(name, weight, create, contents, data)\n','function(name, weight, create, contents, data)\n    if cbProtected(name) then return end\n')
    s=replace(s,'function(containerName)\n    local containerId = GetContainerIdByName(containerName)','function(containerName)\n    if cbProtected(containerName) then return end\n    local containerId = GetContainerIdByName(containerName)')
    for sig in ['unregisterCustomContainer','registerCustomContainerInventoryContents','upgradeContainerInventoryWeight','onContainerInventoryClose','saveContainerInventoryContents','setBusyState']:
        pattern=r'(AddEventHandler\("tpz_inventory:'+sig+r'", function\(containerId[^\n]*\)\n)'
        s,n=re.subn(pattern,r'\1    if cbContainer(containerId) then return end\n',s,count=1)
        if n!=1: raise ValueError('Missing guard: '+sig)
    a='function(containerId, inventory, item, quantity, cb)\n'
    s=replace(s,a,a+"""    local protected=cbContainer(containerId)
    if protected then return cbMove(source,protected,inventory,item,quantity,cb) end
""")
    # The ordinary handlers yield while waiting for data, so recheck at read time.
    a='local container = Containers[containerId]\n\n        return cb( { name ='
    s=replace(s,a,'local container = Containers[containerId]\n        if cbProtected(container.name) and not cbGrant(source,container.name) then return cb(nil) end\n\n        return cb( { name =')
    a='return cb( { containerId = containerId, name = container.name'
    s=replace(s,a,'if cbProtected(container.name) and not cbGrant(source,container.name) then return cb(nil) end\n            '+a)
    return s
def main():
    if len(sys.argv)!=3 or sys.argv[1] not in REVISIONS:
        raise SystemExit(__doc__)
    kind=sys.argv[1]; root=Path(sys.argv[2])
    path=root/('server/main.lua' if kind=='redem' else 'server/tp-server_second_inventory.lua')
    raw=path.read_bytes()
    digest=hashlib.sha256(raw).hexdigest()
    # Account for Git line-ending settings by checking normalized file content.
    s=raw.decode('utf-8-sig').replace('\r\n','\n')
    if hashlib.sha256(s.encode()).hexdigest()!=HASHES[kind]:
        raise SystemExit('Unsupported upstream file or already patched. Expected commit '+REVISIONS[kind]+'. No files changed.')
    out=(redem if kind=='redem' else tpz)(s)
    backup=path.with_suffix(path.suffix+'.codebyte-original')
    if backup.exists(): raise SystemExit('Existing backup; inspect manually.')
    shutil.copy2(path,backup)
    path.write_text(out,encoding='utf-8',newline='\n')
    print('Applied '+kind+' native storage patch; backup: '+str(backup))
if __name__=='__main__': main()
