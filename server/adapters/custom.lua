CBLibsCustom = {}
local Custom = CBLibsCustom

for _, method in ipairs({ 'GetPlayer', 'GetIdentifier', 'GetJob', 'GetMoney', 'AddMoney', 'RemoveMoney', 'HasPermission' }) do
    Custom[method] = function(...)
        local handler = CBLibsConfig.custom and CBLibsConfig.custom[method]
        if type(handler) ~= 'function' then return nil end
        return handler(...)
    end
end
