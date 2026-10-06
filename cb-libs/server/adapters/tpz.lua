CBLibsTPZ = {}
local TPZ = CBLibsTPZ

function TPZ.GetCore()
    return exports.tpz_core:getCoreAPI()
end

function TPZ.GetPlayer(source)
    local player = TPZ.GetCore().GetPlayer(source)
    return player and player.loaded and player.loaded() and player or nil
end

local function accountType(account)
    if account == 'gold' then return 1 end
    if account == 'blackmoney' or account == 'black_money' then return 2 end
    return 0 -- TPZ: 0 cash, 1 gold, 2 black money
end

function TPZ.NormalizePlayer(player)
    if not player then return nil end
    local data = {
        citizenid = player.getCharacterIdentifier(),
        charinfo = {
            firstname = player.getFirstName() or '',
            lastname = player.getLastName() or '',
            birthdate = player.getDob(),
            gender = player.getGender(),
        },
        job = {
            name = player.getJob() or 'unemployed',
            label = player.getJob() or 'Unemployed',
            grade = { level = tonumber(player.getJobGrade()) or 0 },
            onduty = true,
        },
        money = {
            cash = tonumber(player.getAccount(0)) or 0,
            gold = tonumber(player.getAccount(1)) or 0,
            blackmoney = tonumber(player.getAccount(2)) or 0,
        },
    }
    return {
        PlayerData = data,
        Functions = {
            GetMoney = function(account) return player.getAccount(accountType(account)) or 0 end,
            AddMoney = function(account, amount)
                player.addAccount(accountType(account), tonumber(amount) or 0)
                return true
            end,
            RemoveMoney = function(account, amount)
                return player.removeAccount(accountType(account), tonumber(amount) or 0) and true or false
            end,
        },
        raw = player,
    }
end

function TPZ.GetIdentifier(source)
    local player = TPZ.GetPlayer(source)
    return player and player.getCharacterIdentifier() or nil
end

function TPZ.GetJob(source)
    local player = TPZ.GetPlayer(source)
    return player and { name = player.getJob(), grade = player.getJobGrade() } or nil
end

function TPZ.GetMoney(source, account)
    local player = TPZ.GetPlayer(source)
    return player and player.getAccount(accountType(account)) or 0
end

function TPZ.AddMoney(source, account, amount)
    local player = TPZ.GetPlayer(source)
    if not player then return false end
    player.addAccount(accountType(account), tonumber(amount) or 0)
    return true
end

function TPZ.RemoveMoney(source, account, amount)
    local player = TPZ.GetPlayer(source)
    return player and player.removeAccount(accountType(account), tonumber(amount) or 0) and true or false
end

function TPZ.HasPermission(source, permission)
    local player = TPZ.GetPlayer(source)
    return (player and player.hasPermissionsByAce(permission)) or IsPlayerAceAllowed(source, permission) or false
end
