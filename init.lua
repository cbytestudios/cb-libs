-- Preferred import for dependent resources:
-- shared_script '@cb-libs/init.lua'
CBLibs = CBLibs or {}

function CBLibs.GetFramework()
    return exports['cb-libs']:GetFramework()
end

function CBLibs.GetDetectedFrameworks()
    return exports['cb-libs']:GetDetectedFrameworks()
end

if IsDuplicityVersion() then
    function CBLibs.GetPlayer(source) return exports['cb-libs']:GetPlayer(source) end
    function CBLibs.GetIdentifier(source) return exports['cb-libs']:GetIdentifier(source) end
    function CBLibs.GetJob(source) return exports['cb-libs']:GetJob(source) end
    function CBLibs.GetMoney(source, account) return exports['cb-libs']:GetMoney(source, account) end
    function CBLibs.AddMoney(source, account, amount, reason) return exports['cb-libs']:AddMoney(source, account, amount, reason) end
    function CBLibs.RemoveMoney(source, account, amount, reason) return exports['cb-libs']:RemoveMoney(source, account, amount, reason) end
    function CBLibs.HasPermission(source, permission) return exports['cb-libs']:HasPermission(source, permission) end
else
    function CBLibs.Notify(data) return exports['cb-libs']:Notify(data) end
    function CBLibs.Progress(data) return exports['cb-libs']:Progress(data) end
end
