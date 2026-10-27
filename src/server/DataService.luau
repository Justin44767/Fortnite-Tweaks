local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Http=game:GetService("HttpService")
local Run=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Rules=require(Shared.Rules)
local Config=require(Shared.Config)
local Data={} Data.__index=Data
local function retry(callback)
    local last
    for attempt=1,4 do
        local ok,result=pcall(callback)
        if ok then return true,result end
        last=result
        if attempt<4 then task.wait(math.min(2^(attempt-1),4)+math.random()*.3) end
    end
    return false,last
end
function Data.new(onChanged)
    local self=setmetatable({Profiles={},OnChanged=onChanged,Session=Http:GenerateGUID(false),Closing=false},Data)
    self.Ephemeral=Run:IsStudio() and not Config.StudioPersistence
    self.Store=if self.Ephemeral then nil else DSS:GetDataStore(Config.DataStoreName..(if Run:IsStudio() then "_Studio" else ""))
    task.spawn(function()
        while not self.Closing do
            task.wait(Config.AutoSaveSeconds)
            for player in self.Profiles do task.spawn(function() self:Save(player,false) end) end
        end
    end)
    return self
end
function Data:Load(player)
    local data,problem
    if self.Ephemeral then data=Rules.NewProfile()
    else
        local ok,record=retry(function()
            return self.Store:UpdateAsync(tostring(player.UserId),function(old)
                if old~=nil and (type(old)~="table" or not Rules.ValidProfile(old.Data)) then
                    problem="Beschädigtes oder neueres Profil. Es wurde nichts überschrieben." return nil
                end
                if old and old.Session and old.Session.Id~=self.Session and old.Session.Expires>os.time() then
                    problem="Dein Profil ist noch auf einem anderen Server aktiv. Bitte kurz warten." return nil
                end
                problem=nil
                return {Data=if old then old.Data else Rules.NewProfile(),Session={Id=self.Session,Expires=os.time()+Config.SessionLeaseSeconds}}
            end)
        end)
        if not ok then problem="Speicherdienst nicht erreichbar. Bitte später erneut beitreten." warn("NERO load:",record)
        elseif record and record.Session and record.Session.Id==self.Session then data=record.Data end
    end
    if not data then if player.Parent then player:Kick(problem or "Profil konnte nicht geladen werden.") end return end
    self.Profiles[player]={Data=data,Revision=0,Saving=false,Closing=false,Joined=os.clock(),LastPlaytime=os.clock(),Failures=0}
    if not player.Parent or self.Closing then self:Remove(player) return end
    local stats=Instance.new("Folder") stats.Name="leaderstats" stats.Parent=player
    for _,name in {"Coins","Wins","Level"} do local n=Instance.new("IntValue") n.Name=name n.Parent=stats end
    self:Changed(player)
end
function Data:Get(player) local p=self.Profiles[player] return p and not p.Closing and p.Data end
function Data:Changed(player)
    local p=self.Profiles[player] if not p then return end
    local stats=player:FindFirstChild("leaderstats")
    if stats then stats.Coins.Value=p.Data.Coins stats.Wins.Value=p.Data.Wins stats.Level.Value=Rules.Level(p.Data.XP) end
    if self.OnChanged and player.Parent then self.OnChanged(player,Rules.Copy(p.Data),self.Ephemeral) end
end
function Data:Mutate(player,callback)
    local p=self.Profiles[player] if not p or p.Closing then return false,"Profil lädt noch." end
    -- No yielding inside callbacks; each mutation is atomic within this server's profile lease.
    local changed,message=callback(p.Data)
    if changed then p.Revision+=1 self:Changed(player) end
    return changed,message
end
function Data:Save(player,release)
    local p=self.Profiles[player] if not p then return true end
    if p.Saving then
        if not release then return false end
        local deadline=os.clock()+20 repeat task.wait(.1) until not p.Saving or os.clock()>deadline
        if p.Saving then return false end
    end
    p.Saving=true
    local now=os.clock() local elapsed=math.floor(now-p.LastPlaytime)
    p.Data.Playtime+=elapsed p.LastPlaytime+=elapsed
    local snapshot=Rules.Copy(p.Data)
    local ok,result=true,nil
    if self.Store then
        ok,result=retry(function()
            local wrote=false
            local record=self.Store:UpdateAsync(tostring(player.UserId),function(old)
                if not old or not old.Session or old.Session.Id~=self.Session then return nil end
                wrote=true
                return {Data=snapshot,Session=if release then nil else {Id=self.Session,Expires=os.time()+Config.SessionLeaseSeconds}}
            end)
            if not wrote or not record then error("Profile lease was lost; refusing to overwrite") end
            return record
        end)
    end
    p.Saving=false
    if not ok then
        p.Failures+=1 warn("NERO save failed for",player.UserId,result)
        if player.Parent then
            player:SetAttribute("SaveWarning",true)
            -- Stop new rewards before the lease can expire and another server can load it.
            if p.Failures>=2 and not release then p.Closing=true player:Kick("Speicherverbindung unterbrochen. Bitte erneut verbinden.") end
        end
    else
        p.Failures=0 p.SavedSnapshot=snapshot
        if player.Parent then player:SetAttribute("SaveWarning",false) end
    end
    return ok
end
function Data:Remove(player)
    local p=self.Profiles[player] if not p then return end p.Closing=true
    self:Save(player,true) self.Profiles[player]=nil
end
function Data:Shutdown()
    self.Closing=true local remaining=0
    for player in self.Profiles do remaining+=1 task.spawn(function() self:Remove(player) remaining-=1 end) end
    local deadline=os.clock()+25 repeat task.wait(.1) until remaining==0 or os.clock()>deadline
end
return Data
