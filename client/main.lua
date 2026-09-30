local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

local function detectFramework()
    if CBLibsConfig.framework ~= 'auto' then return CBLibsConfig.framework end
    for _, name in ipairs(CBLibsConfig.detectionPriority or {}) do
        for _, resource in ipairs((CBLibsConfig.frameworkResources or {})[name] or {}) do
            if resourceStarted(resource) then return name end
        end
    end
    return nil
end

local framework = detectFramework()

local function detectedFrameworks()
    local found = {}
    for _, name in ipairs(CBLibsConfig.detectionPriority or {}) do
        for _, resource in ipairs((CBLibsConfig.frameworkResources or {})[name] or {}) do
            if resourceStarted(resource) then
                found[#found + 1] = name
                break
            end
        end
    end
    return found
end

local function notify(data)
    data = data or {}
    local provider = CBLibsConfig.notifications
    if provider == 'auto' then provider = resourceStarted('ox_lib') and 'ox_lib' or framework end

    if provider == 'ox_lib' and resourceStarted('ox_lib') then
        lib.notify(data)
        return true
    end

    if provider == 'rsg' and resourceStarted('rsg-core') then
        TriggerEvent('RSGCore:Notify', data.description or data.text or '', data.type or 'primary', data.duration)
        return true
    end

    if provider == 'qbr' and resourceStarted('qbr-core') then
        TriggerEvent('QBCore:Notify', data.description or data.text or '', data.type or 'primary', data.duration)
        return true
    end

    if provider == 'vorp' then
        TriggerEvent('vorp:TipRight', data.description or data.text or '', data.duration or 4000)
        return true
    end

    return false
end

local function progress(data)
    if resourceStarted('ox_lib') then return lib.progressCircle(data) end
    return false
end

exports('GetFramework', function() return framework end)
exports('GetDetectedFrameworks', detectedFrameworks)
exports('Notify', notify)
exports('Progress', progress)
