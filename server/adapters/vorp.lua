CBLibsVORP = {}
local VORP = CBLibsVORP

function VORP.GetCore() return exports.vorp_core:GetCore() end
function VORP.GetUser(source) return VORP.GetCore().getUser(source) end
function VORP.GetPlayer(source)
    local user = VORP.GetUser(source)
    return user and user.getUsedCharacter or nil
end
function VORP.GetIdentifier(source)
    local character = VORP.GetPlayer(source)
    return character and character.identifier or nil
end
function VORP.GetJob(source)
    local character = VORP.GetPlayer(source)
    return character and { name = character.job, grade = character.jobGrade } or nil
end
function VORP.GetMoney(source, account)
    local character = VORP.GetPlayer(source)
    if not character then return 0 end
    if account == 'gold' then return character.gold or 0 end
    if account == 'rol' then return character.rol or 0 end
    return character.money or 0
end
function VORP.AddMoney(source, account, amount)
    local character = VORP.GetPlayer(source)
    return character and character.addCurrency(account == 'gold' and 1 or account == 'rol' and 2 or 0, amount) or false
end
function VORP.RemoveMoney(source, account, amount)
    local character = VORP.GetPlayer(source)
    return character and character.removeCurrency(account == 'gold' and 1 or account == 'rol' and 2 or 0, amount) or false
end
function VORP.HasPermission(source, permission) return VORP.GetCore().IsAdmin(source, permission) end
