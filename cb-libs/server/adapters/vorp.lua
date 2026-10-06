CBLibsVORP = {}
local VORP = CBLibsVORP

function VORP.GetCore() return exports.vorp_core:GetCore() end
function VORP.GetUser(source) return VORP.GetCore().getUser(source) end
function VORP.GetPlayer(source)
    local user = VORP.GetUser(source)
    return user and user.getUsedCharacter or nil
end

function VORP.NormalizePlayer(character)
    if not character then return nil end
    local firstname = character.firstname or character.firstName or ''
    local lastname = character.lastname or character.lastName or ''
    local job = {
        name = character.job or 'unemployed',
        label = character.jobLabel or character.job or 'Unemployed',
        grade = { level = tonumber(character.jobGrade) or 0, label = character.jobGradeLabel },
        onduty = true,
    }
    local data = {
        citizenid = character.charIdentifier or character.identifier,
        charinfo = { firstname = firstname, lastname = lastname, birthdate = character.birthdate, gender = character.gender },
        job = job,
        money = { cash = tonumber(character.money) or 0, gold = tonumber(character.gold) or 0, rol = tonumber(character.rol) or 0 },
    }
    return {
        PlayerData = data,
        Functions = {
            GetMoney = function(account)
                return account == 'gold' and data.money.gold or account == 'rol' and data.money.rol or data.money.cash
            end,
            AddMoney = function(account, amount)
                character.addCurrency(account == 'gold' and 1 or account == 'rol' and 2 or 0, amount)
                return true
            end,
            RemoveMoney = function(account, amount)
                character.removeCurrency(account == 'gold' and 1 or account == 'rol' and 2 or 0, amount)
                return true
            end,
        },
        raw = character,
    }
end
function VORP.GetIdentifier(source)
    local character = VORP.GetPlayer(source)
    return character and (character.charIdentifier or character.identifier) or nil
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
    if not character then return false end
    character.addCurrency(account == 'gold' and 1 or account == 'rol' and 2 or 0, amount)
    return true
end
function VORP.RemoveMoney(source, account, amount)
    local character = VORP.GetPlayer(source)
    if not character then return false end
    character.removeCurrency(account == 'gold' and 1 or account == 'rol' and 2 or 0, amount)
    return true
end
function VORP.HasPermission(source, permission)
    if IsPlayerAceAllowed(source, permission) then return true end
    local user = VORP.GetUser(source)
    local group = user and user.getGroup
    if type(permission) == 'table' then
        for _, allowed in pairs(permission) do
            if group == allowed then return true end
        end
        return false
    end
    return group == permission
end
