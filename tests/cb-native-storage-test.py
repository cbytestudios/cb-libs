"""Test native storage patches with pinned upstream source checkouts."""
from pathlib import Path
from lupa.lua54 import LuaRuntime
import runpy, sys
root=Path(__file__).resolve().parents[2]
p=root/'cb-libs/cb-libs/install/native-storage/apply-native-storage.py'
patch=runpy.run_path(str(p))
upstream=Path(sys.argv[1])
sources={'redem':upstream/'redem-inventory/server/main.lua','tpz':upstream/'tpz-inventory/tpz_inventory/server/tp-server_second_inventory.lua'}
out={k:patch[k](v.read_text(encoding='utf-8-sig')) for k,v in sources.items()}
lua=LuaRuntime()
compile_only=lua.eval('function(s,n) local f,e=load(s,n); return f~=nil,e end')
for k,s in out.items():
    ok,err=compile_only(s,k)
    assert ok,err
lua.execute("""
local allowed=true
function cbGrant(src,name) if allowed and src==1 then return {weight=20,slots=5} end end
function deny() allowed=false end
function allow() allowed=true end
function copy(v) if type(v)~='table' then return v end local n={} for k,x in pairs(v) do n[k]=copy(x) end return n end
json={encode=copy,decode=copy}
PlayerInventory={[1]={inventory={
 {item='knife',itemId='serial-123',type='weapon',quantity=1,metadata={durability=54,ammo=3,components={a='b'}}},
 {item='watch',itemId='watch-99',type='item',quantity=1,metadata={itemId='watch-99',serial='abc',durability=40}},
 {item='wood',itemId=0,type='item',quantity=8,metadata={durability=100}},
}}}
SharedWeapons={Weapons={KNIFE={weight=2}}}
SharedItems={watch={weight=1,stackable=0},wood={weight=1,stackable=1}}
local c={id=1,name='cb-secure:test:stash',inventory={}}
function getContainerWeight() return 0 end
function canCarryWeapon()return true end
function canCarryItem()return true end
function normalizeItemId(id)return id end
TPZ={GetPlayer=function()return {loaded=function()return true end,getDefaultUsedWeaponIds=function()return {} end}end}
exports={ghmattimysql={execute=function()end}}
function saveInventoryContents()end
function TriggerClientEvent()end
function stored()return c.inventory end
function carried()return PlayerInventory[1].inventory end
function container()return c end
""")
src=out['tpz']; start=src.index('local function cbEqual'); end=src.index('-----------------------------------------------------------',start)
lua.execute(src[start:end]+'\n testMove=cbMove')
lua.execute("""
local c=container()
deny();testMove(1,c,'main',{item='knife',itemId='serial-123'},1);assert(#stored()==0);allow()
testMove(1,c,'main',{item='knife',itemId='fake'},1);assert(#stored()==0)
testMove(1,c,'main',{item='knife',itemId='serial-123'},2);assert(#stored()==0)
testMove(1,c,'main',{item='knife',itemId='serial-123',metadata={durability=999}},1,true);assert(#stored()==0)
testMove(1,c,'main',{item='knife',itemId='serial-123',metadata={durability=999}},1)
assert(stored()[1].itemId=='serial-123' and stored()[1].metadata.durability==54)
assert(stored()[1].metadata.ammo==3 and stored()[1].metadata.components.a=='b')
testMove(1,c,'main',{item='watch',itemId='watch-99'},1)
assert(stored()[2].itemId=='watch-99' and stored()[2].metadata.serial=='abc')
testMove(1,c,'main',{item='wood',itemId=0},3)
assert(stored()[3].quantity==3 and carried()[1].quantity==5)
testMove(1,c,'container',{item='wood',itemId=0},2)
assert(stored()[3].quantity==1 and carried()[1].quantity==7)
testMove(1,c,'container',{item='knife',itemId='serial-123'},1)
assert(carried()[2].itemId=='serial-123' and carried()[2].metadata.components.a=='b')
testMove(1,c,'container',{item='watch',itemId='watch-99'},1)
assert(carried()[3].itemId=='watch-99' and carried()[3].metadata.itemId=='watch-99')
stored()[1].metadata.durability=20
testMove(1,c,'container',{item='wood',itemId=0},1)
assert(stored()[1].quantity==1 and carried()[1].quantity==7)
""")
print('PASS: 11 TPZ native storage assertions, exact IDs and metadata retained')
lua=LuaRuntime()
lua.execute("""
source=1; local allowed=true
function cbProtected(id)return id=='cb-secure:test:stash' end
function cbGrant(src,id)if allowed then return {weight=10,slots=2}end end
function deny()allowed=false end
function allow()allowed=true end
local weapon={getName=function()return 'knife'end,getAmount=function()return 1 end,getMeta=function()return {uid='redem-77',quality=50}end}
Config={Items={knife={type='item_weapon',weight=2}},MaxWeight=20}
RedEM={GetPlayer=function()return {GetIdentifier=function()return 'u'end,GetActiveCharacter=function()return 1 end}end}
Inventory={u_1={weapon}};InventoryWeight={u_1=2};Stash={['cb-secure:test:stash']={}};StashMaxWeights={}
function deep_compare(a,b)for k,v in pairs(a)do if b[k]~=v then return false end end for k in pairs(b)do if a[k]==nil then return false end end return true end
function getMetaOutput(v)return v or {} end
function getInventoryItemFromName(n,rows,m)for _,v in ipairs(rows)do if v.getName()==n and deep_compare(v.getMeta(),m)then return v end end end
function GetStashWeight()return 0 end
""")
src=out['redem']; start=src.index('        if cbProtected(stashId) then'); end=src.index('        local _source = source',start)
lua.execute('function testGuard(_type,data,target,LockerID,stashId)\n'+src[start:end]+'\n return data end')
lua.execute("""
local id='cb-secure:test:stash'
local data={name='knife',amount=1,meta={uid='redem-77',quality=50}}
deny(); assert(not testGuard('delete',data,0,nil,id)); allow()
assert(not testGuard('delete',data,2,nil,id))
assert(not testGuard('delete',{name='knife',amount=2,meta=data.meta},0,nil,id))
assert(not testGuard('delete',{name='knife',amount=1,meta={uid='redem-77',quality=99}},0,nil,id))
local v=testGuard('delete',data,0,nil,id)
assert(v and v.meta.uid=='redem-77' and v.meta.quality==50)
""")
print('PASS: 5 RedEM protected transfer validation assertions')
