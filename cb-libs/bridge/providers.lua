-- Internal provider registry. Keep auto-detection details out of user config.
CBLibsProviders = {
    framework = {
        priority = { 'rsg', 'vorp', 'tpz' },
        resources = {
            rsg = { 'rsg-core' },
            vorp = { 'vorp_core' },
            tpz = { 'tpz_core' },
        },
    },
    inventory = {
        priority = { 'rsg', 'vorp', 'tpz' },
        resources = {
            rsg = { 'rsg-inventory' },
            vorp = { 'vorp_inventory' },
            tpz = { 'tpz_inventory' },
        },
    },
}

function CBLibsProviders.Detect(kind)
    local provider, found = CBLibsProviders[kind], {}
    for _, name in ipairs(provider.priority) do
        for _, resource in ipairs(provider.resources[name]) do
            if GetResourceState(resource) == 'started' then
                found[#found + 1] = name
                break
            end
        end
    end
    return found
end

function CBLibsProviders.Resource(kind, name)
    for _, resource in ipairs(CBLibsProviders[kind].resources[name] or {}) do
        if GetResourceState(resource) == 'started' then return resource end
    end
end
