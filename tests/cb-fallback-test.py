from pathlib import Path
from lupa.lua54 import LuaRuntime
root=Path(__file__).resolve().parents[2]
lua=LuaRuntime()
lua.execute("""
local contents, pending = {}, nil
local inv, permission, near, cap = 10, true, true, 10000
local handlers={}
CBLibs={Callback={register=function(n,f) handlers[n]=f end},
GetInventoryProvider=function() return 'tpz' end,
GetItemDefinition=function(n) if n=='wood' then return {weight=1,label='Wood',stackable=1} end end,
GetInventory=function() return {{name='wood',amount=inv,metadata={}}} end,
GetItemCount=function()return inv end,
CanAddItem=function()return true end,
RemoveItem=function(s,n,a)inv=inv-a;return true end,
AddItem=function(s,n,a)inv=inv+a;return true end}
Validation={Gate=function()return true end,RateLimit=function()return true end}
Server={ItemLabel=function(n)return n end,CitizenId=function(s)return 'owner' end}
C={tiers={{storage={weight=cap,slots=2}}}}
Camping={Near=function()if near then return {owner='owner',tier=1} end end,StashId=function(o)return o end}
function canUse()return permission end
json={encode=function(v)return v end,decode=function(v)return v end}
MySQL={query={await=function()return {} end},single={await=function()return {contents=contents,pending=pending} end},
update={await=function(q,p)
if q:find('SET pending=?',1,true) then if pending then return 0 end; pending=p[1]
elseif q:find('SET contents=',1,true) then contents=p[1]; pending=nil
else pending=nil end; return 1 end}}
function invoke(action,name,amount)return handlers['cb-wilderness:managedStash'](1,1,action,name,amount) end
function deny()permission=false end
function allow()permission=true end
function far()near=false end
function close()near=true end
function balance()return inv end
""")
src=(root/'cb-wilderness/cb-wilderness/server/camping.lua').read_text(encoding='utf-8-sig')
lua.execute(src[src.index('-- Persistent camp storage'):src.index('CBLibs.Callback.register(Enums.Cb.CampStorage')])
lua.execute("""
assert(invoke('list').ok)
deny(); assert(not invoke('deposit','wood',1).ok); allow()
far(); assert(not invoke('deposit','wood',1).ok); close()
assert(not invoke('deposit','wood',-1).ok)
assert(not invoke('deposit','wood',11).ok)
assert(invoke('deposit','wood',5).ok)
assert(balance()==5)
assert(invoke('list').stored[1].amount==5)
assert(not invoke('withdraw','wood',6).ok)
assert(invoke('withdraw','wood',2).ok)
assert(balance()==7)
assert(invoke('list').stored[1].amount==3)
""")
print('PASS: 12 managed stash assertions')
lua=LuaRuntime()
lua.execute("""
local existing, moved, native = false, 0, false
Config={Sentencing={maximumJail=120,fallbackPrison={center={x=1,y=2,z=3},radius=180,release={x=0,y=0,z=0}}}}
CBLibs={HasPrisonAdapter=function()return native end,JailPlayer=function()return true,'native' end,GetIdentifier=function(src)if src==2 then return 'cid' end end}
function GetPlayerPed(src)return src==2 and 99 or 0 end
function DoesEntityExist()return true end
function SetEntityCoords()moved=moved+1 end
function CreateThread(fn)end
MySQL={query={await=function()end},update={await=function()if existing then return 0 end;existing=true;return 1 end}}
function enableNative()native=true end
function movements()return moved end
""")
lua.execute((root/'cb-lawarchives/cb-lawarchives/server/prison.lua').read_text(encoding='utf-8-sig'))
lua.execute("""
assert(not CBLawPrison.Jail(1,3,5))
assert(not CBLawPrison.Jail(1,2,0))
assert(not CBLawPrison.Jail(1,2,121))
assert(CBLawPrison.Jail(1,2,5))
assert(movements()==1)
assert(not CBLawPrison.Jail(1,2,5))
enableNative(); local ok,kind=CBLawPrison.Jail(1,2,5); assert(ok and kind=='native')
""")
print('PASS: 7 fallback prison assertions')
