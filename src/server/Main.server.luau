local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local DSS=game:GetService("DataStoreService")
local Shared=RS:WaitForChild("Shared")
local Config=require(Shared.Config)
local Catalog=require(Shared.Catalog)
local Rules=require(Shared.Rules)
local DataService=require(script.Parent.DataService)
local Cosmetics=require(script.Parent.Cosmetics)
local Items=require(script.Parent.Items)
local Party=require(script.Parent.Party)
local RoundManager=require(script.Parent.RoundManager)
local Events=require(script.Parent.ChaosEvents)
local Ragdoll=require(script.Parent.Ragdoll)
local folder=Instance.new("Folder") folder.Name="Remotes" folder.Parent=RS
local remotes={}
for _,name in {"Request","State","Effect"} do local r=Instance.new("RemoteEvent") r.Name=name r.Parent=folder remotes[name]=r end
local data=DataService.new(function(p,profile,ephemeral) remotes.State:FireClient(p,"Profile",{Data=profile,SessionOnly=ephemeral}) end)
local rounds=RoundManager.new(data,remotes)
local party=Party.new(remotes.State)
local rates={} local emoteTimes={}
local function owner(p)
    return table.find(Config.OwnerUserIds,p.UserId)~=nil or (game.CreatorType==Enum.CreatorType.User and game.CreatorId==p.UserId)
end
local function notice(p,text) remotes.State:FireClient(p,"Notice",text) end
local function commit(p,callback)
    local ok,message=data:Mutate(p,callback)
    if message then notice(p,tostring(message)) end
    if ok then task.spawn(function() data:Save(p,false) end) end
    return ok
end
local function settings(p,payload)
    if type(payload)~="table" then return end
    local key,value=payload.Key,payload.Value
    if ((key=="Music" or key=="Effects" or key=="ReducedMotion") and type(value)=="boolean") or (key=="Quality" and (value=="High" or value=="Low")) then
        data:Mutate(p,function(d) d.Settings[key]=value return true end)
    end
end
local function admin(p,payload)
    if not owner(p) or type(payload)~="table" then return end
    local action=payload.Action local id=payload.Id
    if action=="SelectGame" and Catalog.GameById[id] then rounds.ForcedGame=id notice(p,"Nächstes Spiel: "..id)
    elseif action=="Start" then rounds.Skip=true notice(p,"Countdown übersprungen.")
    elseif action=="End" then rounds.Stop=true
    elseif action=="Event" and Catalog.EventById[id] and rounds.Context then
        if not Events.Start(rounds.Context,id) then notice(p,"Ein Chaos-Event läuft bereits.") end
    elseif action=="Status" then notice(p,string.format("Phase: %s · Spieler: %d · Profile: %d · Privatserver: %s",rounds.Phase,#Players:GetPlayers(),(function() local n=0 for _ in data.Profiles do n+=1 end return n end)(),tostring(game.PrivateServerId~="")))
    elseif action=="Coins" or action=="Wins" or action=="Teleport" or action=="Kick" then
        local target=if Rules.Finite(payload.UserId) then Players:GetPlayerByUserId(payload.UserId) else nil
        if not target then notice(p,"Spieler nicht auf diesem Server.") return end
        if action=="Coins" or action=="Wins" then
            if not Rules.Finite(payload.Amount) or payload.Amount%1~=0 or math.abs(payload.Amount)>10000 then return end
            commit(target,function(d) d[action]=math.max(0,d[action]+payload.Amount) return true,"Owner-Test: "..action.." "..payload.Amount end)
        elseif action=="Teleport" then
            if target:GetAttribute("InRound") and rounds.Context then rounds.Context:Eliminate(target) end
            if target.Character then target.Character:PivotTo(workspace.Lobby.LobbySpawn.CFrame+Vector3.new(0,6,0)) end
        elseif action=="Kick" and target~=p then
            target:Kick("Du wurdest vom Owner aus diesem Server entfernt.")
        end
    end
end
remotes.Request.OnServerEvent:Connect(function(p,action,payload)
    if type(action)~="string" or #action>32 then return end
    local now=os.clock() local rate=rates[p] or {At=now,Tokens=12} rates[p]=rate
    rate.Tokens=math.min(12,rate.Tokens+(now-rate.At)*5) rate.At=now
    if rate.Tokens<1 then return end rate.Tokens-=1
    if type(payload)=="string" and #payload>80 then return end
    local ok,err=xpcall(function()
        if action=="Hello" then
            data:Changed(p) remotes.State:FireClient(p,"Round",rounds.Last)
            remotes.State:FireClient(p,"Owner",owner(p)) party:Update() return
        end
        local profile=data:Get(p) if not profile then return end
        if action=="Vote" then if type(payload)=="string" then rounds:Vote(p,payload) end
        elseif action=="Play" then p:SetAttribute("AFK",false) notice(p,"Du spielst in der nächsten Runde mit.")
        elseif action=="AFK" then
            p:SetAttribute("AFK",not p:GetAttribute("AFK"))
            if p:GetAttribute("AFK") and rounds.Context then rounds.Context:Eliminate(p) end
            notice(p,if p:GetAttribute("AFK") then "AFK an – du setzt aus." else "AFK aus – nächste Runde geht's los!")
        elseif action=="Buy" then commit(p,function(d) return Rules.Buy(d,Catalog.ById[payload]) end)
        elseif action=="Equip" then
            local product=Catalog.ById[payload]
            if product and profile.Owned[payload] and product.Category~="Emotes" then
                data:Mutate(p,function(d) d.Equipped[product.Category]=if d.Equipped[product.Category]==payload then nil else payload return true end)
                Cosmetics.Apply(p,profile)
            end
        elseif action=="Favorite" then
            local product=Catalog.ById[payload]
            if product and product.Category=="Pets" and profile.Owned[payload] then data:Mutate(p,function(d) d.Favorites[payload]=if d.Favorites[payload] then nil else true return true end) end
        elseif action=="Daily" then commit(p,function(d) return Rules.Daily(d,Rules.Day(os.time()),Catalog.DailyCoins) end)
        elseif action=="Spin" then
            local roll=rounds.Random:NextInteger(1,100)
            local success,reward=data:Mutate(p,function(d) return Rules.Spin(d,Rules.Day(os.time()),roll) end)
            if success then remotes.State:FireClient(p,"Spin",reward) task.spawn(function() data:Save(p,false) end) else notice(p,reward) end
        elseif action=="Quest" then
            local quest for _,q in Catalog.Quests do if q.Id==payload then quest=q break end end
            commit(p,function(d) return Rules.Quest(d,quest) end)
        elseif action=="Settings" then settings(p,payload)
        elseif action=="SelectItem" then if Items.Select(p,payload) then notice(p,"Item gewählt: "..Catalog.ItemById[payload].Name) end
        elseif action=="UseItem" then Items.Use(p,remotes)
        elseif action=="Push" then if rounds.Context then rounds.Context:Push(p) end
        elseif action=="DoubleJump" then if rounds.Context then rounds.Context:DoubleJump(p) end
        elseif action=="Emote" then
            local product=Catalog.ById[payload]
            if product and product.Category=="Emotes" and profile.Owned[payload] and not p:GetAttribute("InRound") and now-(emoteTimes[p] or 0)>2 then
                emoteTimes[p]=now remotes.Effect:FireAllClients("Emote",p.UserId,payload)
            end
        elseif action=="InviteParty" or action=="AcceptParty" or action=="LeaveParty" then local _,message=party:Request(p,action,payload) notice(p,message)
        elseif action=="Admin" then admin(p,payload) end
    end,debug.traceback)
    if not ok then warn("NERO request rejected:",action,err) end
end)
local function characterAdded(p,c)
    local h=c:WaitForChild("Humanoid",10) local root=c:WaitForChild("HumanoidRootPart",10) if not h or not root then return end
    h.BreakJointsOnDeath=false h.UseJumpPower=true
    p:SetAttribute("InRound",false) p:SetAttribute("Reverse",false) p:SetAttribute("DoubleJump",false) p:SetAttribute("ChaosCamera",false)
    if rounds.Context and rounds.Context.Alive[p.UserId] then rounds.Context:Eliminate(p,false) end
    c:PivotTo(workspace.Lobby.LobbySpawn.CFrame+Vector3.new(0,5,0))
    task.delay(1,function() local profile=data:Get(p) if profile and c.Parent then Cosmetics.Apply(p,profile) end end)
    local lastVelocity=0 local lastFall=0 local conn
    conn=Run.Heartbeat:Connect(function()
        if not c.Parent or h.Health<=0 then conn:Disconnect() Ragdoll.Stop(c) return end
        if h.FloorMaterial==Enum.Material.Air then lastVelocity=root.AssemblyLinearVelocity.Y
        elseif lastVelocity< -70 and os.clock()-lastFall>3 then lastFall=os.clock() lastVelocity=0 Ragdoll.Start(c,.8)
        else lastVelocity=0 end
        if not p:GetAttribute("InRound") and root.Position.Y< -25 then Ragdoll.Stop(c) c:PivotTo(workspace.Lobby.LobbySpawn.CFrame+Vector3.new(0,5,0)) root.AssemblyLinearVelocity=Vector3.zero end
    end)
end
local function joined(p)
    p:SetAttribute("AFK",false) Items.Select(p,"Confetti")
    p.CharacterAdded:Connect(function(c) characterAdded(p,c) end)
    p.CharacterAppearanceLoaded:Connect(function() local profile=data:Get(p) if profile then Cosmetics.Apply(p,profile) end end)
    if p.Character then task.spawn(characterAdded,p,p.Character) end
    data:Load(p)
end
Players.PlayerAdded:Connect(joined)
for _,p in Players:GetPlayers() do task.spawn(joined,p) end
Players.PlayerRemoving:Connect(function(p)
    if rounds.Context then rounds.Context:Eliminate(p,false) rounds.Votes[p.UserId]=nil end
    Items.Remove(p) party:Remove(p) rates[p]=nil emoteTimes[p]=nil data:Remove(p)
end)
game:BindToClose(function() data:Shutdown() end)
-- All lobby prompts verify proximity again on the server.
for _,object in workspace.Lobby:GetDescendants() do
    if object:IsA("ProximityPrompt") then
        object.Triggered:Connect(function(p)
            local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if not r or p:GetAttribute("InRound") or not data:Get(p) or (r.Position-object.Parent.Position).Magnitude>18 then return end
            local name=object.Parent.Name
            if name=="AFK" then p:SetAttribute("AFK",not p:GetAttribute("AFK")) notice(p,if p:GetAttribute("AFK") then "AFK aktiviert." else "AFK deaktiviert.")
            elseif name=="VIP" then
                if owner(p) or table.find(Config.VipUserIds,p.UserId) then p.Character:PivotTo(workspace.Lobby.VipSpawn.CFrame) notice(p,"Willkommen in der VIP-Lounge!")
                else notice(p,"Diese Lounge ist für vom Owner eingetragene Gäste. Keine Spielvorteile.") end
            elseif name=="Photo" then remotes.Effect:FireClient(p,"Photo",object.Parent.Position) remotes.Effect:FireAllClients("Emote",p.UserId,"VictoryPose")
            else remotes.State:FireClient(p,"Open",if name=="SpinWheel" then "Rewards" else name) end
        end)
    elseif object:IsA("BasePart") and object.Name=="Trampoline" then
        local last={}
        object.Touched:Connect(function(hit)
            local c=hit:FindFirstAncestorOfClass("Model") local p=c and Players:GetPlayerFromCharacter(c)
            local r=c and c:FindFirstChild("HumanoidRootPart")
            if p and r and not p:GetAttribute("InRound") and os.clock()-(last[p] or 0)>1 then last[p]=os.clock() r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X,90,r.AssemblyLinearVelocity.Z) remotes.Effect:FireAllClients("Bounce",r.Position) end
        end)
    end
end
-- Only persisted profiles feed global boards. Studio session scores are labeled separately.
local boardSpecs={{Name="Wins",Board="WinsBoard",Title="MOST WINS"},{Name="Level",Board="LevelBoard",Title="HIGHEST LEVEL"},{Name="Playtime",Board="TimeBoard",Title="MOST PLAYTIME"}}
local names={}
local function displayName(id)
    if not names[id] then local ok,name=pcall(Players.GetNameFromUserIdAsync,Players,id) names[id]=if ok then name else tostring(id) end return names[id]
end
task.spawn(function()
    while true do
        for _,spec in boardSpecs do
            local values={}
            if data.Ephemeral then
                for p,record in data.Profiles do table.insert(values,{key=tostring(p.UserId),value=if spec.Name=="Level" then Rules.Level(record.Data.XP) else record.Data[spec.Name]}) end
                table.sort(values,function(a,b) return a.value>b.value end)
            else
                local store=DSS:GetOrderedDataStore(Config.DataStoreName..(if Run:IsStudio() then "_Studio" else "").."_"..spec.Name)
                for p,record in data.Profiles do
                    if record.SavedSnapshot then
                        local snapshot=record.SavedSnapshot
                        local value=if spec.Name=="Level" then Rules.Level(snapshot.XP) else snapshot[spec.Name]
                        local ok,err=pcall(function() store:SetAsync(tostring(p.UserId),value) end) if not ok then warn("NERO leaderboard save:",err) end
                    end
                end
                local ok,pages=pcall(function() return store:GetSortedAsync(false,5) end)
                if ok then values=pages:GetCurrentPage() end
            end
            local lines={spec.Title..(if data.Ephemeral then " · STUDIO" else "")}
            for i=1,math.min(5,#values) do
                local v=values[i] local value=if spec.Name=="Playtime" then tostring(math.floor(v.value/60)).." min" else tostring(v.value)
                table.insert(lines,i..". "..displayName(tonumber(v.key)).." · "..value)
            end
            if #values==0 then table.insert(lines,"Noch keine gespeicherten Einträge") end
            workspace.Lobby[spec.Board].Sign.Text.Text=table.concat(lines,"\n")
        end
        task.wait(120)
    end
end)
rounds:Start()
print("NERO CHAOS PARTY "..Config.Version.." ready · "..#Catalog.Games.." minigames · "..#Catalog.Events.." chaos events")
