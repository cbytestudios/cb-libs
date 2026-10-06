-- Framework-independent interaction bridge. ox_target is used automatically
-- when it is running; otherwise CB Libs renders a small RedM proximity prompt.
local keys = {
    { label = 'E', control = 0xCEFD9220 },
    { label = 'R', control = 0xE30CD707 },
    { label = 'G', control = 0x760A9C6F },
}
local defaultDistance = 2.5
local entries, oxHandles = {}, {}

local function ownerKey(id)
    return ('%s:%s'):format(GetInvokingResource() or GetCurrentResourceName(), tostring(id))
end

local function provider()
    return GetResourceState('ox_target') == 'started' and 'ox_target' or 'fallback'
end

local function drawText(text, x, y, scale)
    local value = CreateVarString(10, 'LITERAL_STRING', text)
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextColor(235, 220, 180, 255)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextFontForCurrentCommand(1)
    DisplayText(value, x, y)
end

local function toOx(key, id, options)
    local converted = {}
    for index, option in ipairs(options or {}) do
        converted[index] = {
            name = ('%s:%s'):format(key, option.name or index),
            label = option.label,
            icon = option.icon and ('fa-solid fa-' .. option.icon) or nil,
            distance = option.distance or defaultDistance,
            canInteract = option.canInteract,
            onSelect = function(data)
                option.onSelect({ id = id, entity = data and data.entity, coords = data and data.coords })
            end,
        }
    end
    return converted
end


local function remove(key)
    local handle = oxHandles[key]
    if handle and GetResourceState('ox_target') == 'started' then
        if handle.kind == 'point' then
            exports.ox_target:removeZone(handle.zone)
        else
            exports.ox_target:removeLocalEntity(handle.entity, handle.names)
        end
    end
    oxHandles[key], entries[key] = nil, nil
    return handle ~= nil
end

exports('GetInteractionProvider', provider)
exports('GetInteractionKeys', function() return keys end)
exports('RemoveInteraction', function(id) return remove(ownerKey(id)) end)
exports('HasInteraction', function(id)
    local key = ownerKey(id)
    return entries[key] ~= nil or oxHandles[key] ~= nil
end)

exports('AddPointInteraction', function(id, data)
    local key = ownerKey(id)
    remove(key)
    if provider() == 'ox_target' then
        local zone = exports.ox_target:addSphereZone({
            coords = data.coords,
            radius = data.radius or defaultDistance,
            options = toOx(key, id, data.options),
        })
        oxHandles[key] = { kind = 'point', zone = zone }
    else
        entries[key] = { id = id, kind = 'point', coords = data.coords, radius = data.radius, options = data.options or {} }
    end
    return true
end)

exports('AddEntityInteraction', function(id, entity, options)
    local key = ownerKey(id)
    remove(key)
    if provider() == 'ox_target' then
        local converted, names = toOx(key, id, options), {}
        for index, option in ipairs(converted) do names[index] = option.name end
        exports.ox_target:addLocalEntity(entity, converted)
        oxHandles[key] = { kind = 'entity', entity = entity, names = names }
    else
        entries[key] = { id = id, kind = 'entity', entity = entity, options = options or {} }
    end
    return true
end)

local function visibleOptions(entry, entity, distance)
    local visible = {}
    for _, option in ipairs(entry.options) do
        if option.canInteract == nil or option.canInteract(entity, distance) then visible[#visible + 1] = option end
    end
    return visible
end

CreateThread(function()
    local current, lastScan = nil, 0
    while true do
        local sleep = 300
        if provider() == 'fallback' and next(entries) then
            local now = GetGameTimer()
            if now - lastScan >= 200 then
                lastScan, current = now, nil
                local playerCoords, bestDistance = GetEntityCoords(PlayerPedId()), nil
                for _, entry in pairs(entries) do
                    local coords, entity
                    if entry.kind == 'point' then
                        coords = entry.coords
                    elseif DoesEntityExist(entry.entity) then
                        entity, coords = entry.entity, GetEntityCoords(entry.entity)
                    end
                    if coords then
                        local distance = #(playerCoords - coords)
                        if distance <= (entry.radius or defaultDistance) and (not bestDistance or distance < bestDistance) then
                            local options = visibleOptions(entry, entity, distance)
                            if #options > 0 then
                                bestDistance = distance
                                current = { id = entry.id, entity = entity, coords = coords, options = options }
                            end
                        end
                    end
                end
            end

            if current then
                sleep = 0
                local count = math.min(#current.options, #keys)
                local y = 0.90 - (count - 1) * 0.032
                for index = 1, count do
                    drawText(('[%s] %s'):format(keys[index].label, current.options[index].label), 0.5, y, 0.35)
                    y = y + 0.032
                    if IsControlJustPressed(0, keys[index].control) then
                        local option = current.options[index]
                        local data = { id = current.id, entity = current.entity, coords = current.coords }
                        current, lastScan = nil, 0
                        CreateThread(function() option.onSelect(data) end)
                        break
                    end
                end
            end
        else
            current = nil
        end
        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    local prefix = resource .. ':'
    for key in pairs(entries) do
        if key:sub(1, #prefix) == prefix then entries[key] = nil end
    end
    for key in pairs(oxHandles) do
        if key:sub(1, #prefix) == prefix then remove(key) end
    end
end)
