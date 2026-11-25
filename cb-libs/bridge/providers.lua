-- Internal provider registry. Keep auto-detection details out of user config.
CBLibsProviders = {
    framework = {
        priority = { 'rsg', 'vorp', 'redem', 'tpz' },
        resources = {
            rsg = { 'rsg-core' },
            vorp = { 'vorp_core' },
            redem = { 'redem_roleplay' },
            tpz = { 'tpz_core' },
        },
    },
    inventory = {
        priority = { 'rsg', 'vorp', 'redem', 'tpz' },
        resources = {
            rsg = { 'rsg-inventory' },
            vorp = { 'vorp_inventory' },
            redem = { 'redemrp_inventory' },
            tpz = { 'tpz_inventory' },
        },
    },
}

-- MULTIcore supplies the RSG export aliases. Detect the provider, not a separate adapter.
function CBLibsProviders.IsStarted(resource)
    if GetResourceState(resource) == 'started' then return true end
    if resource == 'rsg-core' then return GetResourceState('MULTIcore') == 'started' end
    if resource == 'rsg-inventory' then return GetResourceState('MULTIinventory') == 'started' end
    return false
end

function CBLibsProviders.Detect(kind)
    local provider, found = CBLibsProviders[kind], {}
    for _, name in ipairs(provider.priority) do
        for _, resource in ipairs(provider.resources[name]) do
            if CBLibsProviders.IsStarted(resource) then
                found[#found + 1] = name
                break
            end
        end
    end
    return found
end

function CBLibsProviders.Resource(kind, name)
    for _, resource in ipairs(CBLibsProviders[kind].resources[name] or {}) do
        if CBLibsProviders.IsStarted(resource) then return resource end
    end
end
