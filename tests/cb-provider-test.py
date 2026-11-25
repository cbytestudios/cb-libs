import pathlib
from lupa.lua54 import LuaRuntime
p=pathlib.Path(__file__).resolve().parents[1] / 'cb-libs'
lua=LuaRuntime()
lua.execute("""
states={MULTIcore='started',MULTIinventory='started',ox_lib='started'}
function GetResourceState(name) return states[name] or 'missing' end
""")
lua.execute((p/'bridge/providers.lua').read_text(encoding='utf-8-sig'))
lua.execute("""
assert(CBLibsProviders.Detect('framework')[1]=='rsg')
assert(CBLibsProviders.Detect('inventory')[1]=='rsg')
assert(CBLibsProviders.Resource('framework','rsg')=='rsg-core')
assert(CBLibsProviders.Resource('inventory','rsg')=='rsg-inventory')
states={redem_roleplay='started',redemrp_inventory='started'}
assert(CBLibsProviders.Detect('framework')[1]=='redem')
assert(CBLibsProviders.Detect('inventory')[1]=='redem')
states={tpz_core='started',tpz_inventory='started'}
assert(CBLibsProviders.Detect('framework')[1]=='tpz')
assert(CBLibsProviders.Detect('inventory')[1]=='tpz')
states={['rsg-core']='started',['rsg-inventory']='started'}
assert(CBLibsProviders.Detect('framework')[1]=='rsg')
assert(CBLibsProviders.Detect('inventory')[1]=='rsg')
states={vorp_core='started',vorp_inventory='started'}
assert(CBLibsProviders.Detect('framework')[1]=='vorp')
assert(CBLibsProviders.Detect('inventory')[1]=='vorp')
CBLibsConfig={framework='custom',inventory='custom',customBridge='my-bridge'}
exportsMap={}; handlers={}; owner='untrusted'
function exports(name,fn) exportsMap[name]=fn end
function GetInvokingResource() return owner end
function AddEventHandler(name,fn) handlers[name]=handlers[name] or {}; table.insert(handlers[name],fn) end
function RegisterNetEvent(name,fn) end
""")
lua.execute((p/'server/main.lua').read_text(encoding='utf-8-sig'))
lua.execute("""
local framework={apiVersion=1,name='test',GetPlayerData=function(src) return {citizenid='test-1'} end,
GetIdentifier=function(src)return 'test-1' end, GetJob=function()return {name='law'} end,
GetMoney=function()return 100 end,AddMoney=function()return true end,RemoveMoney=function()return true end,HasPermission=function()return false end}
local inventory={apiVersion=1}
for _,name in ipairs({'HasItemDefinitions','GetItemDefinition','GetInventory','GetItem','GetItemCount','CanAddItem','AddItem','RemoveItem','RegisterUsableItem','OpenStash'}) do inventory[name]=function() return true end end
inventory.GetItemCount=function()return 4 end
assert(exportsMap.RegisterFrameworkAdapter(framework)==false)
assert(exportsMap.RegisterInventoryAdapter(inventory)==false)
owner='my-bridge'
assert(exportsMap.RegisterFrameworkAdapter({apiVersion=1,name='incomplete'})==false)
assert(exportsMap.RegisterInventoryAdapter({apiVersion=1})==false)
assert(exportsMap.RegisterFrameworkAdapter(framework)==true)
assert(exportsMap.RegisterInventoryAdapter(inventory)==true)
assert(exportsMap.GetPlayerData(1).citizenid=='test-1')
assert(exportsMap.GetItemCount(1,'test')==4)
for _,fn in ipairs(handlers.onResourceStop) do fn('my-bridge') end
assert(exportsMap.GetPlayerData(1)==nil)
assert(exportsMap.GetItemCount(1,'test')==nil)
""")
print('PASS: 22 provider detection and custom adapter assertions')
