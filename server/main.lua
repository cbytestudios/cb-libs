local adapters = {
    rsg = CBLibsRSG,
    qbr = CBLibsQBR,
    vorp = CBLibsVORP,
    redem = CBLibsRedEM,
    redemreboot = CBLibsRedEM,
    gum = CBLibsGUM,
    custom = CBLibsCustom,
}

local function resourceStarted(name)
    return GetResourceState(name) == 'started'
end

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

local detected = detectedFrameworks()
local framework = CBLibsConfig.framework ~= 'auto' and CBLibsConfig.framework or detected[1]
local adapter = framework and adapters[framework] or nil

if not adapter then
    print(('[cb-libs] No adapter is available for framework "%s". Check shared/config.lua.'):format(tostring(framework or 'none')))
else
    if #detected > 1 and CBLibsConfig.framework == 'auto' then
        print(('[cb-libs] Multiple frameworks detected (%s); using %s. Set CBLibsConfig.framework to make this explicit.'):format(table.concat(detected, ', '), framework))
    end
    print(('[cb-libs] Loaded %s framework adapter.'):format(framework))
end

local function call(method, ...)
    if not adapter then return nil, 'No cb-libs framework adapter is available.' end
    return adapter[method](...)
end

exports('GetFramework', function() return framework end)
exports('GetDetectedFrameworks', function() return detected end)
exports('GetPlayer', function(source) return call('GetPlayer', source) end)
exports('GetIdentifier', function(source) return call('GetIdentifier', source) end)
exports('GetJob', function(source) return call('GetJob', source) end)
exports('GetMoney', function(source, account) return call('GetMoney', source, account) end)
exports('AddMoney', function(source, account, amount, reason) return call('AddMoney', source, account, amount, reason) end)
exports('RemoveMoney', function(source, account, amount, reason) return call('RemoveMoney', source, account, amount, reason) end)
exports('HasPermission', function(source, permission) return call('HasPermission', source, permission) end)
