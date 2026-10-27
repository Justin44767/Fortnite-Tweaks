local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Http=game:GetService("HttpService")
local Config=require(RS.Shared.Config)
local Catalog=require(RS.Shared.Catalog)
local Rules=require(RS.Shared.Rules)
local Context=require(script.Parent.Context)
local Minigames=require(script.Parent.Minigames)
local Events=require(script.Parent.ChaosEvents)
local Round={} Round.__index=Round
function Round.new(data,remotes)
    return setmetatable({Data=data,Remotes=remotes,Phase="Waiting",Choices={},Votes={},Context=nil,ForcedGame=nil,Skip=false,Stop=false,Last={},Random=Random.new()},Round)
end
function Round:Eligible()
    local result={}
    for _,p in Players:GetPlayers() do
        local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
        if self.Data:Get(p) and not p:GetAttribute("AFK") and h and h.Health>0 and p.Character:FindFirstChild("HumanoidRootPart") then table.insert(result,p) end
    end
    return result
end
function Round:Broadcast(seconds,extra)
    local ctx=self.Context local counts={}
    if #self.Choices>0 then local _;_,counts=Rules.VoteWinner(self.Choices,self.Votes,1) end
    self.Last={Phase=self.Phase,Seconds=seconds,Choices=self.Choices,Votes=counts,
        Game=ctx and ctx.Info.Id or nil,Alive=ctx and ctx:Count() or #self:Eligible(),Message=extra or "",Players=#Players:GetPlayers()}
    self.Remotes.State:FireAllClients("Round",self.Last)
end
function Round:Wait(seconds,extra)
    for remaining=seconds,1,-1 do
        self:Broadcast(remaining,extra) task.wait(1)
        if self.Skip then self.Skip=false return end
    end
end
function Round:Vote(player,id)
    if self.Phase~="Voting" or not table.find(self.Choices,id) or not self.Data:Get(player) or player:GetAttribute("AFK") then return end
    self.Votes[player.UserId]=id self:Broadcast(self.Last.Seconds or 0)
end
function Round:RunOne()
    self.Phase="Waiting" self.Choices={} self.Votes={}
    while #self:Eligible()<Config.MinimumPlayers do self:Broadcast(0,"Drücke PLAY, um mitzuspielen.") task.wait(1) end
    self.Phase="Intermission" self:Wait(Config.Intermission,"Die nächste Runde wartet!")
    local pool=table.clone(Catalog.Games)
    for i=#pool,2,-1 do local j=self.Random:NextInteger(1,i) pool[i],pool[j]=pool[j],pool[i] end
    self.Choices={pool[1].Id,pool[2].Id,pool[3].Id} self.Votes={} self.Phase="Voting"
    self:Wait(Config.VotingTime,"Wähle ein Minispiel.")
    local chosen=self.ForcedGame or Rules.VoteWinner(self.Choices,self.Votes,self.Random:NextInteger(1,1000)) self.ForcedGame=nil
    local players=self:Eligible() if #players==0 then return end
    local ctx=Context.new(Catalog.GameById[chosen],players,self.Remotes) self.Context=ctx self.Stop=false
    self.Phase="Playing" self.Choices={} ctx:Message(ctx.Info.Rules)
    Minigames.Start(ctx)
    local lastSecond=-1 local nextChaos=Config.ChaosInterval local firstFinish=nil
    while ctx.Scope.Alive do
        task.wait(.1) ctx:UpdateBounds()
        local elapsed=os.clock()-ctx.Started local remaining=math.max(0,math.ceil(ctx.Info.Duration-elapsed))
        if remaining~=lastSecond then lastSecond=remaining self:Broadcast(remaining,ctx.Info.Rules) end
        if elapsed>=nextChaos then
            nextChaos+=Config.ChaosInterval
            if chosen~="Disasters" then Events.Random(ctx) end
        end
        if next(ctx.Finished) and not firstFinish then firstFinish=elapsed end
        if self.Stop or remaining<=0 or ctx:Count()==0 then break end
        if #players>1 and ctx.Info.Kind=="Survival" and ctx:Count()<=1 and elapsed>6 then break end
        if firstFinish and ctx.Info.Kind=="Race" and elapsed-firstFinish>=15 then break end
    end
    local eligible={} for _,p in players do if p.Parent and self.Data:Get(p) then eligible[p.UserId]=true end end
    local winners=if self.Stop then {} else Rules.Winners(ctx.Info.Kind,ctx.Alive,ctx.Finished,ctx.Scores,eligible)
    local receipt=Http:GenerateGUID(false) local names={}
    if not self.Stop then
        for _,p in players do
            if p.Parent and self.Data:Get(p) then
                local survived=ctx.Alive[p.UserId] or ctx.Finished[p.UserId]~=nil
                self.Data:Mutate(p,function(d)
                    local changed=Rules.RoundReward(d,receipt,survived,winners[p.UserId]==true)
                    if changed then Rules.ProgressRewards(d,Catalog.Achievements) end return changed
                end)
                task.spawn(function() self.Data:Save(p,false) end)
                if winners[p.UserId] then table.insert(names,p.DisplayName) end
            end
        end
    end
    ctx.Scope:Clean()
    for _,p in players do
        if p.Parent and p.Character then
            local r=p.Character:FindFirstChild("HumanoidRootPart")
            if r then p.Character:PivotTo(workspace.Lobby.LobbySpawn.CFrame+Vector3.new(self.Random:NextNumber(-8,8),5,self.Random:NextNumber(-8,8))) r.AssemblyLinearVelocity=Vector3.zero end
            if winners[p.UserId] then
                self.Remotes.Effect:FireAllClients("Victory",p.Character:GetPivot().Position)
                self.Remotes.Effect:FireAllClients("Emote",p.UserId,"VictoryPose")
                if p:GetAttribute("EquippedVictory")=="ConfettiWin" then self.Remotes.Effect:FireAllClients("Confetti",p.Character:GetPivot().Position) end
            end
        end
    end
    self.Context=nil self.Phase="Results"
    self.Remotes.State:FireAllClients("Target",false) self.Remotes.State:FireAllClients("Music",false)
    self:Wait(Config.ResultsTime,if self.Stop then "Runde abgebrochen – keine Wertung." elseif #names>0 then "GEWONNEN: "..table.concat(names,", ") else "Das Chaos hat gewonnen. Nächster Versuch!")
end
function Round:Start()
    task.spawn(function()
        while true do
            local ok,err=xpcall(function() self:RunOne() end,debug.traceback)
            if not ok then
                warn("NERO round recovered:",err)
                if self.Context then
                    local ctx=self.Context ctx.Scope:Clean()
                    for _,p in ctx.Players do if p.Character then p.Character:PivotTo(workspace.Lobby.LobbySpawn.CFrame+Vector3.new(0,5,0)) end end
                    self.Context=nil
                end
                self.Phase="Waiting" self.Remotes.State:FireAllClients("Notice","Runde zurückgesetzt. Eine neue Runde startet gleich.") task.wait(3)
            end
        end
    end)
end
return Round
