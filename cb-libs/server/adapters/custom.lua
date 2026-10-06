CBLibsCustom = {}
local Custom = CBLibsCustom

for _, method in ipairs({ 'GetPlayer', 'GetIdentifier', 'GetJob', 'GetMoney', 'AddMoney', 'RemoveMoney', 'HasPermission' }) do
    Custom[method] = function(...)
        local handler = CBLibsCustomConfig.framework[method]
        if type(handler) ~= 'function' then return nil end
        return handler(...)
    end
end

function Custom.NormalizePlayer(player, source)
    local handler = CBLibsCustomConfig.framework.NormalizePlayer
    if type(handler) == 'function' then return handler(player, source) end
    return player
end
