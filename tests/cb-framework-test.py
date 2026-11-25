import pathlib
from lupa.lua54 import LuaRuntime
root=pathlib.Path(__file__).resolve().parents[1] / 'cb-libs'
lua=LuaRuntime()
lua.execute("""
local cash, bank, tpCash, tpGold = 100, 40, 50, 5
local redem = {
 CitizenId=function() return 'redem-1' end, GetFirstName=function() return 'Ada' end,
 GetLastName=function() return 'Smith' end, GetJob=function() return 'doctor' end,
 GetJobGrade=function() return 2 end, GetMoney=function() return cash end,
 GetBankMoney=function() return bank end, GetGroup=function() return 'user' end,
 GetMetaData=function() return {} end, AddMoney=function(n) cash=cash+n end,
 RemoveMoney=function(n) cash=cash-n end, AddBankMoney=function(n) bank=bank+n end,
 RemoveBankMoney=function(n) bank=bank-n end,
}
local tpz = {
 loaded=function() return true end, getCharacterIdentifier=function() return 12 end,
 getFirstName=function() return 'Jane' end, getLastName=function() return 'Doe' end,
 getJob=function() return 'law' end, getJobGrade=function() return 3 end,
 getGroup=function() return 'user' end,
 getAccount=function(i) return i==0 and tpCash or i==1 and tpGold or 0 end,
 addAccount=function(i,n) if i==0 then tpCash=tpCash+n elseif i==1 then tpGold=tpGold+n end end,
 removeAccount=function(i,n) if i==0 then tpCash=tpCash-n elseif i==1 then tpGold=tpGold-n end end,
}
exports={
 redem_roleplay={RedEM=function() return {GetPlayer=function(src) if src==1 then return redem end end} end},
 tpz_core={getCoreAPI=function() return {GetPlayer=function(src) if src==1 then return tpz end end} end},
}
function IsPlayerAceAllowed(src,p) return false end
""")
lua.execute((root/'server/adapters/redem_tpz.lua').read_text(encoding='utf-8-sig'))
lua.execute("""
assert(CBLibsRedEM.GetIdentifier(1)=='redem-1')
assert(CBLibsRedEM.GetPlayer(1).PlayerData.job.grade.level==2)
assert(CBLibsRedEM.GetPlayer(2)==nil)
assert(CBLibsRedEM.RemoveMoney(1,'cash',101)==false)
assert(CBLibsRedEM.AddMoney(1,'cash',-10)==false)
assert(CBLibsRedEM.RemoveMoney(1,'cash',25)==true)
assert(CBLibsRedEM.GetMoney(1,'cash')==75)
assert(CBLibsRedEM.AddMoney(1,'bank',5)==true)
assert(CBLibsRedEM.GetMoney(1,'bank')==45)
assert(CBLibsRedEM.HasPermission(1,'admin')==false)
assert(CBLibsTPZ.GetIdentifier(1)=='12')
assert(CBLibsTPZ.GetPlayer(1).PlayerData.job.grade.level==3)
assert(CBLibsTPZ.GetPlayer(2)==nil)
assert(CBLibsTPZ.RemoveMoney(1,'cash',51)==false)
assert(CBLibsTPZ.AddMoney(1,'gold',2)==true)
assert(CBLibsTPZ.GetMoney(1,'gold')==7)
assert(CBLibsTPZ.RemoveMoney(1,'cash',15)==true)
assert(CBLibsTPZ.GetMoney(1,'cash')==35)
assert(CBLibsTPZ.AddMoney(1,'bank',5)==false)
assert(CBLibsTPZ.HasPermission(1,'admin')==false)
""")
print('PASS: 20 mocked RedEM and TPZ framework assertions')
