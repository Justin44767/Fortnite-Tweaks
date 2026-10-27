-- Appended to source modules by tools/test.py. Test doubles, NOT Roblox engine simulation.
local count=0
local function test(name,fn) fn() count+=1 print("PASS "..name) end
local Rules=require("../src/shared/Rules")
local records={} local failWrites=false local writes=0
local services={}
local objectMethods={}
local mt={__index=function(o,k)
    return objectMethods[k] or o._props[k] or o._children[k]
end,__newindex=function(o,k,v)
    if k=="Parent" then
        local old=o._props.Parent if old and old._children then old._children[o.Name]=nil end
        if v and v._children then v._children[o.Name]=o end
    end
    o._props[k]=v
end}
local function object(class,name)
    return setmetatable({_props={ClassName=class,Name=name or class},_children={},_type="Instance"},mt)
end
function objectMethods:FindFirstChild(name) return self._children[name] end
function objectMethods:SetAttribute(key,value) self._props[key]=value end
function objectMethods:Kick(message) self.Kicked=message self.Parent=nil end
function objectMethods:Destroy() self.Parent=nil self.Destroyed=true end
function objectMethods:WaitForChild(name) return assert(self._children[name],name) end
local function player(id) local p=object("Player","P"..id) p.UserId=id p.Parent=object("Players") return p end
services.Players={}
services.DataStoreService={GetDataStore=function()
    return {UpdateAsync=function(_,key,callback)
        writes+=1 if failWrites then error("temporary write failure") end
        local old=Rules.Copy(records[key]) local new=callback(old)
        if new then records[key]=Rules.Copy(new) return Rules.Copy(new) end
        return nil
    end}
end}
local guid=0
services.HttpService={GenerateGUID=function() guid+=1 return tostring(guid) end}
services.RunService={IsStudio=function() return false end}
local rs=object("ReplicatedStorage") local shared=object("Folder","Shared") shared.Parent=rs
shared.Rules="Rules" shared.Config="Config" services.ReplicatedStorage=rs
local config={DataStoreName="Test",StudioPersistence=false,SessionLeaseSeconds=180,AutoSaveSeconds=45}
local delayed={}
local fakeTask={spawn=function() end,wait=function() return 0 end,delay=function(_,fn) table.insert(delayed,fn) end}
local env=setmetatable({game={GetService=function(_,name) return services[name] end},Instance={new=object},task=fakeTask,
    require=function(name) if name=="Rules" then return Rules elseif name=="Config" then return config else error(name) end end,
    typeof=function(v) return if type(v)=="table" and v._type then v._type else typeof(v) end,
    warn=function() end},{__index=getfenv()})
local function loadModule(name) local f=assert(loadstring(SOURCES[name])) setfenv(f,env) return f() end
local Data=loadModule("DataService") local Scope=loadModule("Scope")
test("profile load, release and reconnect restore saved state",function()
    local first=Data.new() local a=player(1) first:Load(a) assert(first:Get(a))
    first:Mutate(a,function(d) d.Coins=123 d.Owned.DuckPet=true return true end)
    first:Remove(a) assert(records['1'].Session==nil)
    local second=Data.new() local b=player(1) second:Load(b) assert(second:Get(b).Coins==123 and second:Get(b).Owned.DuckPet)
    second:Remove(b)
end)
test("live session lease prevents two servers owning a profile",function()
    local a,b=Data.new(),Data.new() local pa,pb=player(2),player(2)
    a:Load(pa) b:Load(pb) assert(a:Get(pa)) assert(not b:Get(pb) and pb.Kicked)
    assert(records['2'].Session.Id==a.Session) a:Remove(pa)
end)
test("expired lease can be recovered; stale owner cannot overwrite",function()
    local a,b=Data.new(),Data.new() local pa,pb=player(3),player(3)
    a:Load(pa) records['3'].Session.Expires=0 b:Load(pb) assert(b:Get(pb))
    a:Mutate(pa,function(d) d.Coins=999 return true end)
    assert(not a:Save(pa,false)) assert(records['3'].Data.Coins==0 and records['3'].Session.Id==b.Session)
    b:Remove(pb)
end)
test("corrupt record is rejected and preserved",function()
    records['4']={Data={Schema=999,Coins=500}}
    local d=Data.new() local p=player(4) d:Load(p) assert(p.Kicked and not d:Get(p)) assert(records['4'].Data.Coins==500 and records['4'].Data.Schema==999)
end)
test("load outage never creates a fallback writable profile",function()
    failWrites=true local before=writes local d=Data.new() local p=player(5) d:Load(p)
    assert(p.Kicked and not d:Get(p) and records['5']==nil) assert(writes-before==4) failWrites=false
end)
test("save retries and only successful snapshots feed leaderboards",function()
    local d=Data.new() local p=player(6) d:Load(p)
    d:Mutate(p,function(v) v.Coins=50 return true end)
    failWrites=true local before=writes assert(not d:Save(p,false)) assert(writes-before==4 and p.SaveWarning)
    assert(records['6'].Data.Coins==0 and not d.Profiles[p].SavedSnapshot)
    failWrites=false assert(d:Save(p,false)) assert(records['6'].Data.Coins==50 and not p.SaveWarning)
    assert(d.Profiles[p].SavedSnapshot.Coins==50) d:Remove(p)
end)
test("repeated failed lease refresh stops profile mutations",function()
    local d=Data.new() local p=player(7) d:Load(p) failWrites=true
    assert(not d:Save(p,false)) assert(not d:Save(p,false)) assert(p.Kicked and not d:Get(p))
    local ok=d:Mutate(p,function(v) v.Coins=999 return true end) assert(not ok) failWrites=false
end)
test("scope restores properties, disconnects and destroys in reverse order",function()
    local s=Scope.new() local o=object("Part") o.Parent=object("Workspace") o.Transparency=0 local order={}
    s:Property(o,"Transparency",.85) assert(o.Transparency==.85)
    s:Add(function() table.insert(order,1) end) s:Add(function() table.insert(order,2) end)
    local conn={_type="RBXScriptConnection",Disconnect=function(self) self.Disconnected=true end}
    local tmp=object("Part") s:Add(tmp) s:Add(conn) s:Clean()
    assert(o.Transparency==0 and tmp.Destroyed and conn.Disconnected) assert(order[1]==2 and order[2]==1)
    s:Clean() assert(#order==2)
end)
test("delayed event callbacks are cancelled after cleanup",function()
    table.clear(delayed) local s=Scope.new() local called=false s:Delay(1,function() called=true end) s:Clean()
    for _,callback in delayed do callback() end assert(not called)
    local o=object("Part") s:Add(o) assert(o.Destroyed)
end)
print("Runtime double tests:",count)
