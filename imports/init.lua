-- Preferred import for dependent resources:
-- shared_script '@cb-libs/imports/init.lua'
CBLibs = CBLibs or {}

function CBLibs.GetFramework()
    return exports['cb-libs']:GetFramework()
end

function CBLibs.GetDetectedFrameworks()
    return exports['cb-libs']:GetDetectedFrameworks()
end

if IsDuplicityVersion() then
    function CBLibs.GetPlayer(source) return exports['cb-libs']:GetPlayer(source) end
    function CBLibs.GetPlayerData(source) return exports['cb-libs']:GetPlayerData(source) end
    function CBLibs.GetIdentifier(source) return exports['cb-libs']:GetIdentifier(source) end
    function CBLibs.GetJob(source) return exports['cb-libs']:GetJob(source) end
    function CBLibs.GetMoney(source, account) return exports['cb-libs']:GetMoney(source, account) end
    function CBLibs.AddMoney(source, account, amount, reason) return exports['cb-libs']:AddMoney(source, account, amount, reason) end
    function CBLibs.RemoveMoney(source, account, amount, reason) return exports['cb-libs']:RemoveMoney(source, account, amount, reason) end
    function CBLibs.HasPermission(source, permission) return exports['cb-libs']:HasPermission(source, permission) end
    function CBLibs.CanAfford(source, amount, account, remove, reason) return exports['cb-libs']:CanAfford(source, amount, account, remove, reason) end
    function CBLibs.GetInventoryProvider() return exports['cb-libs']:GetInventoryProvider() end
    function CBLibs.GetDetectedInventories() return exports['cb-libs']:GetDetectedInventories() end
    function CBLibs.HasItemDefinitions() return exports['cb-libs']:HasItemDefinitions() end
    function CBLibs.GetItemDefinition(item) return exports['cb-libs']:GetItemDefinition(item) end
    function CBLibs.GetInventory(source) return exports['cb-libs']:GetInventory(source) end
    function CBLibs.GetItem(source, item, metadata) return exports['cb-libs']:GetItem(source, item, metadata) end
    function CBLibs.GetItemCount(source, item, metadata) return exports['cb-libs']:GetItemCount(source, item, metadata) end
    function CBLibs.HasItem(source, item, amount, metadata) return exports['cb-libs']:HasItem(source, item, amount, metadata) end
    function CBLibs.CanAddItem(source, item, amount, metadata) return exports['cb-libs']:CanAddItem(source, item, amount, metadata) end
    function CBLibs.AddItem(source, item, amount, metadata, reason) return exports['cb-libs']:AddItem(source, item, amount, metadata, reason) end
    function CBLibs.RemoveItem(source, item, amount, metadata, reason) return exports['cb-libs']:RemoveItem(source, item, amount, metadata, reason) end
    function CBLibs.RegisterUsableItem(item, callback) return exports['cb-libs']:RegisterUsableItem(item, callback) end
    function CBLibs.OpenStash(source, id, options) return exports['cb-libs']:OpenStash(source, id, options) end
    function CBLibs.CanUseItem(source, item, amount, metadata, remove, reason) return exports['cb-libs']:CanUseItem(source, item, amount, metadata, remove, reason) end
else
    function CBLibs.GetPlayerData() return exports['cb-libs']:GetPlayerData() end
    function CBLibs.Notify(data) return exports['cb-libs']:Notify(data) end
    function CBLibs.Progress(data) return exports['cb-libs']:Progress(data) end
    function CBLibs.GetKeybind(name) return exports['cb-libs']:GetKeybind(name) end
    function CBLibs.CreatePrompt(id, coords, control, label, options) return exports['cb-libs']:CreatePrompt(id, coords, control, label, options) end
    function CBLibs.DeletePrompt(handle) return exports['cb-libs']:DeletePrompt(handle) end
end
