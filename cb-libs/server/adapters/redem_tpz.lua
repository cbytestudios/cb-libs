-- Upstream APIs: RedEM Reboot 5f171fe; TPZ Core 0eacecf.
CBLibsRedEM, CBLibsTPZ = {}, {}
local function validAmount(n) return type(n)=='number' and n>0 and n<math.huge end
local function build(A, get, fields, accounts)
    function A.GetPlayer(src)
        local p=get(src); if not p then return nil end
        local data=fields(p)
        return {PlayerData=data,Functions={
            GetMoney=function(account) return A.GetMoney(src,account) end,
            AddMoney=function(account,n,reason) return A.AddMoney(src,account,n,reason) end,
            RemoveMoney=function(account,n,reason) return A.RemoveMoney(src,account,n,reason) end,
        }}
    end
    function A.GetIdentifier(src) local p=A.GetPlayer(src); return p and p.PlayerData.citizenid end
    function A.GetJob(src) local p=A.GetPlayer(src); return p and p.PlayerData.job end
    function A.GetMoney(src,account)
        local p=get(src); local a=accounts[account or 'cash']; return p and a and tonumber(a[1](p)) or 0
    end
    local function change(src,account,n,remove)
        local p=get(src); local a=accounts[account or 'cash']
        if not p or not a or not validAmount(n) then return false end
        local before=tonumber(a[1](p)); if not before or (remove and before<n) then return false end
        local f=remove and a[3] or a[2]; f(p,n)
        local after=tonumber(a[1](p)); return after~=nil and math.abs(after-(before+(remove and -n or n)))<0.00001
    end
    function A.AddMoney(src,account,n) return change(src,account,n,false) end
    function A.RemoveMoney(src,account,n) return change(src,account,n,true) end
    function A.HasPermission(src,permission)
        if type(permission)~='string' then return false end
        local p=get(src); if not p then return false end
        return IsPlayerAceAllowed(src,permission)==true or fields(p).group==permission
    end
end
local function redem(src) return exports.redem_roleplay:RedEM().GetPlayer(src) end
local function tpz(src) local p=exports.tpz_core:getCoreAPI().GetPlayer(src); return p and p.loaded() and p or nil end
local function rd(p)
    return {citizenid=tostring(p.CitizenId()),charinfo={firstname=p.GetFirstName(),lastname=p.GetLastName()},job={name=p.GetJob(),label=p.GetJob(),grade={level=tonumber(p.GetJobGrade()) or 0},onduty=true},money={cash=p.GetMoney(),bank=p.GetBankMoney()},group=p.GetGroup(),metadata=p.GetMetaData()}
end
local function td(p)
    return {citizenid=tostring(p.getCharacterIdentifier()),charinfo={firstname=p.getFirstName(),lastname=p.getLastName()},job={name=p.getJob(),label=p.getJob(),grade={level=tonumber(p.getJobGrade()) or 0},onduty=true},money={cash=p.getAccount(0),gold=p.getAccount(1),black_money=p.getAccount(2)},group=p.getGroup()}
end
local function tpzAccount(id) return {function(p) return p.getAccount(id) end,function(p,n) p.addAccount(id,n) end,function(p,n) p.removeAccount(id,n) end} end
build(CBLibsRedEM,redem,rd,{
    cash={function(p)return p.GetMoney()end,function(p,n)p.AddMoney(n)end,function(p,n)p.RemoveMoney(n)end},
    bank={function(p)return p.GetBankMoney()end,function(p,n)p.AddBankMoney(n)end,function(p,n)p.RemoveBankMoney(n)end},
})
build(CBLibsTPZ,tpz,td,{cash=tpzAccount(0),gold=tpzAccount(1),black_money=tpzAccount(2)})
