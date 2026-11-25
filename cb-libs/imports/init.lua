-- Preferred import for dependent resources:
-- shared_script '@cb-libs/imports/init.lua'
CBLibs = CBLibs or {}

function CBLibs.GetFramework()
    return exports['cb-libs']:GetFramework()
end

function CBLibs.GetDetectedFrameworks()
    return exports['cb-libs']:GetDetectedFrameworks()
end

if IsDuplicityVersion() then
    function CBLibs.GetPlayer(source) return exports['cb-libs']:GetPlayer(source) end
    function CBLibs.GetPlayerData(source) return exports['cb-libs']:GetPlayerData(source) end
    function CBLibs.GetIdentifier(source) return exports['cb-libs']:GetIdentifier(source) end
    function CBLibs.GetJob(source) return exports['cb-libs']:GetJob(source) end
    function CBLibs.GetMoney(source, account) return exports['cb-libs']:GetMoney(source, account) end
    function CBLibs.AddMoney(source, account, amount, reason) return exports['cb-libs']:AddMoney(source, account, amount, reason) end
    function CBLibs.RemoveMoney(source, account, amount, reason) return exports['cb-libs']:RemoveMoney(source, account, amount, reason) end
    function CBLibs.HasPermission(source, permission) return exports['cb-libs']:HasPermission(source, permission) end
    function CBLibs.CanAfford(source, amount, account, remove, reason) return exports['cb-libs']:CanAfford(source, amount, account, remove, reason) end
    function CBLibs.GetInventoryProvider() return exports['cb-libs']:GetInventoryProvider() end
    function CBLibs.GetDetectedInventories() return exports['cb-libs']:GetDetectedInventories() end
    function CBLibs.HasItemDefinitions() return exports['cb-libs']:HasItemDefinitions() end
    function CBLibs.GetItemDefinition(item) return exports['cb-libs']:GetItemDefinition(item) end
    function CBLibs.GetInventory(source) return exports['cb-libs']:GetInventory(source) end
    function CBLibs.GetItem(source, item, metadata) return exports['cb-libs']:GetItem(source, item, metadata) end
    function CBLibs.GetItemCount(source, item, metadata) return exports['cb-libs']:GetItemCount(source, item, metadata) end
    function CBLibs.HasItem(source, item, amount, metadata) return exports['cb-libs']:HasItem(source, item, amount, metadata) end
    function CBLibs.CanAddItem(source, item, amount, metadata) return exports['cb-libs']:CanAddItem(source, item, amount, metadata) end
    function CBLibs.AddItem(source, item, amount, metadata, reason) return exports['cb-libs']:AddItem(source, item, amount, metadata, reason) end
    function CBLibs.RemoveItem(source, item, amount, metadata, reason) return exports['cb-libs']:RemoveItem(source, item, amount, metadata, reason) end
    function CBLibs.RegisterUsableItem(item, callback) return exports['cb-libs']:RegisterUsableItem(item, callback) end
    function CBLibs.HasNativeStash() return exports['cb-libs']:HasNativeStash() end
    function CBLibs.OpenStash(source, id, options) return exports['cb-libs']:OpenStash(source, id, options) end
    function CBLibs.CanUseItem(source, item, amount, metadata, remove, reason) return exports['cb-libs']:CanUseItem(source, item, amount, metadata, remove, reason) end
    function CBLibs.RegisterPrisonAdapter(callback) return exports['cb-libs']:RegisterPrisonAdapter(callback) end
    function CBLibs.HasPrisonAdapter() return exports['cb-libs']:HasPrisonAdapter() end
    function CBLibs.JailPlayer(officer, target, minutes, reason) return exports['cb-libs']:JailPlayer(officer, target, minutes, reason) end
else
    function CBLibs.GetPlayerData() return exports['cb-libs']:GetPlayerData() end
    function CBLibs.Notify(data) return exports['cb-libs']:Notify(data) end
    function CBLibs.Progress(data) return exports['cb-libs']:Progress(data) end
    function CBLibs.GetKeybind(name) return exports['cb-libs']:GetKeybind(name) end
    function CBLibs.CreatePrompt(id, coords, control, label, options) return exports['cb-libs']:CreatePrompt(id, coords, control, label, options) end
    function CBLibs.DeletePrompt(handle) return exports['cb-libs']:DeletePrompt(handle) end
    function CBLibs.GetInteractionProvider() return exports['cb-libs']:GetInteractionProvider() end
    function CBLibs.GetInteractionKeys() return exports['cb-libs']:GetInteractionKeys() end
    function CBLibs.AddPointInteraction(id, data) return exports['cb-libs']:AddPointInteraction(id, data) end
    function CBLibs.AddEntityInteraction(id, entity, options) return exports['cb-libs']:AddEntityInteraction(id, entity, options) end
    function CBLibs.AddGlobalPedInteraction(id, options) return exports['cb-libs']:AddGlobalPedInteraction(id, options) end
    function CBLibs.RemoveInteraction(id) return exports['cb-libs']:RemoveInteraction(id) end
    function CBLibs.HasInteraction(id) return exports['cb-libs']:HasInteraction(id) end
end

-- Framework-neutral runtime. Optional ox_lib is loaded in this resource only.
CBLibs.Callback = {}
local function ox()
    if GetResourceState('ox_lib') ~= 'started' then return nil end
    if not lib then
        local code = LoadResourceFile('ox_lib', 'init.lua')
        if code then
            local chunk = load(code, '@ox_lib/init.lua', 't', _ENV)
            if chunk then local ok = pcall(chunk); if not ok then return nil end end
        end
    end
    return lib
end
local resource = GetCurrentResourceName()
local req = 'cb-libs:rpc:' .. resource .. ':request'
local res = 'cb-libs:rpc:' .. resource .. ':response'
function CBLibs.GetRuntimeProvider() return ox() and 'ox_lib' or 'cb-libs' end
if IsDuplicityVersion() then
    local handlers, limits = {}, {}
    function CBLibs.Callback.register(name, handler)
        assert(type(name)=='string' and type(handler)=='function', 'Invalid callback')
        handlers[name] = handler
    end
    RegisterNetEvent(req, function(id, name, ...)
        local src = source
        if type(id) ~= 'number' or type(name) ~= 'string' or not handlers[name] then return end
        local now = GetGameTimer()
        local state = limits[src]
        if not state or now-state.time >= 1000 then state={time=now,count=0,active=state and state.active or 0}; limits[src]=state end
        if state.count >= 30 or state.active >= 8 then TriggerClientEvent(res,src,id,false); return end
        state.count=state.count+1; state.active=state.active+1
        local result=table.pack(pcall(handlers[name],src,...))
        local current=limits[src]; if current then current.active=math.max(0,current.active-1) end
        if not result[1] then print(('[%s] callback %s failed: %s'):format(resource,name,tostring(result[2]))); TriggerClientEvent(res,src,id,false); return end
        TriggerClientEvent(res,src,id,true,table.unpack(result,2,result.n))
    end)
    AddEventHandler('playerDropped',function() limits[source]=nil end)
else
    local pending, nextId, lastCall = {},0,{}
    RegisterNetEvent(res,function(id,ok,...)
        if source ~= 65535 then return end
        local p=pending[id]; if not p then return end
        pending[id]=nil; p:resolve(ok and table.pack(...) or table.pack(nil))
    end)
    function CBLibs.Callback.await(name,delay,...)
        local now=GetGameTimer()
        if type(delay)=='number' and lastCall[name] and now-lastCall[name]<delay then return nil end
        lastCall[name]=now
        nextId=nextId+1; local id=nextId; local p=promise.new(); pending[id]=p
        SetTimeout(15000,function() if pending[id] then pending[id]=nil; p:resolve(table.pack(nil)) end end)
        TriggerServerEvent(req,id,name,...)
        local result=Citizen.Await(p); return table.unpack(result,1,result.n)
    end
    local textUI, menus, active, selected = nil,{},nil,1
    local function draw(text,x,y,scale)
        SetTextScale(scale,scale)
        SetTextColor(255,255,255,255)
        DisplayText(CreateVarString(10,'LITERAL_STRING',tostring(text)),x,y)
    end
    function CBLibs.ShowTextUI(text,options)
        local o=ox(); if o then return o.showTextUI(text,options) end
        textUI=text
    end
    function CBLibs.HideTextUI()
        local o=ox(); if o then o.hideTextUI() end
        textUI=nil
    end
    function CBLibs.RegisterContext(data)
        menus[data.id]=data
        local o=ox(); if o then return o.registerContext(data) end
    end
    function CBLibs.ShowContext(id)
        local o=ox(); if o then return o.showContext(id) end
        if menus[id] then active=menus[id]; selected=1 end
    end
    RegisterCommand(resource..'_cbmenuup',function() if active then selected=math.max(1,selected-1) end end,false)
    RegisterCommand(resource..'_cbmenudown',function() if active then selected=math.min(#active.options,selected+1) end end,false)
    RegisterCommand(resource..'_cbmenuselect',function()
        if not active then return end
        local option=active.options[selected]; if not option or option.disabled or option.readOnly then return end
        active=nil
        if option.onSelect then option.onSelect(option.args)
        elseif option.menu then CBLibs.ShowContext(option.menu)
        elseif option.event then TriggerEvent(option.event,option.args)
        elseif option.serverEvent then TriggerServerEvent(option.serverEvent,option.args) end
    end,false)
    RegisterCommand(resource..'_cbmenuclose',function() if active then local m=active; active=nil; if m.onExit then m.onExit() end end end,false)
    RegisterKeyMapping(resource..'_cbmenuup','Codebyte menu up','keyboard','UP')
    RegisterKeyMapping(resource..'_cbmenudown','Codebyte menu down','keyboard','DOWN')
    RegisterKeyMapping(resource..'_cbmenuselect','Codebyte menu select','keyboard','RETURN')
    RegisterKeyMapping(resource..'_cbmenuclose','Codebyte menu close','keyboard','BACK')
    CreateThread(function()
        while true do
            if textUI then draw(textUI,0.42,0.85,0.35) end
            if active then
                draw(active.title or '',0.73,0.18,0.42)
                local first=math.max(1,selected-5)
                for i=first,math.min(#active.options,first+10) do
                    local option=active.options[i]
                    draw((i==selected and '> ' or '  ')..(option.title or ''),0.73,0.22+(i-first)*0.035,0.32)
                end
                local opt=active.options[selected]; if opt and opt.description then draw(opt.description,0.65,0.65,0.28) end
                draw('Arrows / Enter / Backspace',0.73,0.7,0.28)
            end
            Wait((textUI or active) and 0 or 200)
        end
    end)
    local busy=false
    function CBLibs.ProgressBar(data)
        local o=ox(); if o then return o.progressBar(data) end
        if busy then return false end
        busy=true; local ped=PlayerPedId(); local start=GetGameTimer(); local duration=math.max(0,tonumber(data.duration) or 0)
        local success=true
        while GetGameTimer()-start<duration do
            if IsEntityDead(ped) and not data.useWhileDead then success=false; break end
            if data.canCancel and IsControlJustPressed(0,0x156F7119) then success=false; break end
            local disabled=data.disable or {}
            if disabled.move then DisableControlAction(0,0x4D8FB4C1,true); DisableControlAction(0,0xFDA83190,true) end
            if disabled.combat then DisablePlayerFiring(PlayerId(),true) end
            draw(('%s %d%%'):format(data.label or 'Working',math.floor((GetGameTimer()-start)/math.max(1,duration)*100)),0.44,0.86,0.35)
            Wait(0)
        end
        busy=false; return success
    end
end
