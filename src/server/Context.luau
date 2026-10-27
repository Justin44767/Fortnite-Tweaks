local Players=game:GetService("Players")
local Shared=game:GetService("ReplicatedStorage").Shared
local Scope=require(Shared.Scope)
local Ragdoll=require(script.Parent.Ragdoll)
local Context={} Context.__index=Context
function Context.new(gameInfo,players,remotes)
    local self=setmetatable({Info=gameInfo,Scope=Scope.new(),Players=players,Alive={},Finished={},Scores={},Started=os.clock(),Remotes=remotes,Random=Random.new(),LastPush={},LastJump={}},Context)
    self.Map=self.Scope:Add(game:GetService("ServerStorage").Maps[gameInfo.Id]:Clone()) self.Map.Parent=workspace
    self.Spawns=self.Map.Spawns:GetChildren() table.sort(self.Spawns,function(a,b) return tonumber(a.Name)<tonumber(b.Name) end)
    self.Baseline={}
    for i,p in players do
        local hum,root=self:Character(p)
        if hum and root then
            self.Alive[p.UserId]=true self.Scores[p.UserId]=0
            self.Baseline[p]={Character=p.Character,Speed=hum.WalkSpeed,Jump=hum.JumpPower,Scale=p.Character:GetScale()}
            p:SetAttribute("InRound",true) p:SetAttribute("RoundScore",0)
            root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
            p.Character:PivotTo(self.Spawns[(i-1)%#self.Spawns+1].CFrame+Vector3.new(0,2,0))
            self.Scope:Add(hum.Died:Connect(function() self:Eliminate(p,false) end))
        end
    end
    self.Scope:Add(function()
        for p,base in self.Baseline do
            Ragdoll.Stop(base.Character)
            if base.Character.Parent then
                local h=base.Character:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed=base.Speed h.JumpPower=base.Jump end
                base.Character:ScaleTo(base.Scale)
            end
            p:SetAttribute("InRound",false) p:SetAttribute("DoubleJump",false)
            p:SetAttribute("Reverse",false) p:SetAttribute("ChaosCamera",false)
        end
    end)
    return self
end
function Context:Character(p)
    local c=p.Character local h=c and c:FindFirstChildOfClass("Humanoid") local r=c and c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health>0 then return h,r end return nil,nil
end
function Context:Each(callback)
    for _,p in self.Players do
        if p.Parent and self.Alive[p.UserId] then local h,r=self:Character(p) if h and r then callback(p,h,r) end end
    end
end
function Context:Count() local n=0 for _,p in self.Players do if p.Parent and self.Alive[p.UserId] then n+=1 end end return n end
function Context:Message(text) self.Remotes.State:FireAllClients("Notice",text) end
function Context:Effect(name,pos,color) self.Remotes.Effect:FireAllClients(name,pos,color) end
function Context:Eliminate(p,teleport)
    if not self.Alive[p.UserId] then return end
    self.Alive[p.UserId]=false p:SetAttribute("InRound",false) p:SetAttribute("DoubleJump",false) p:SetAttribute("Reverse",false) p:SetAttribute("ChaosCamera",false)
    local h,r=self:Character(p)
    if h and r and teleport~=false then
        Ragdoll.Stop(p.Character)
        local base=self.Baseline[p] if base then h.WalkSpeed=base.Speed h.JumpPower=base.Jump p.Character:ScaleTo(base.Scale) end
        p.Character:PivotTo(workspace.Lobby.LobbySpawn.CFrame+Vector3.new(0,5,0))
        r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
    end
end
function Context:Finish(p)
    if not self.Alive[p.UserId] or self.Finished[p.UserId] then return end
    self.Finished[p.UserId]=math.floor((os.clock()-self.Started)*1000)
    self:Effect("Victory",p.Character:GetPivot().Position)
    self:Message(p.DisplayName.." hat das Ziel erreicht!") self:Eliminate(p)
end
function Context:PlayerFromHit(hit)
    local model=hit:FindFirstAncestorOfClass("Model")
    local p=model and Players:GetPlayerFromCharacter(model)
    if p and self.Alive[p.UserId] then return p end
end
function Context:Part(name,pos,size,color,parent)
    local p=Instance.new("Part") p.Name=name p.Anchored=true p.Size=size p.Position=pos p.Color=color or Color3.fromRGB(255,120,180)
    p.Material=Enum.Material.SmoothPlastic p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent or self.Map return p
end
function Context:Ground(p)
    local _,r=self:Character(p) if not r then return end
    local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Include params.FilterDescendantsInstances={self.Map}
    return workspace:Raycast(r.Position,Vector3.new(0,-6,0),params)
end
function Context:UpdateBounds()
    for _,p in self.Players do
        if self.Alive[p.UserId] then
            local h,r=self:Character(p)
            if not p.Parent or not h or not r then self:Eliminate(p,false)
            elseif r.Position.Y< -18 or math.abs(r.Position.X)>130 or math.abs(r.Position.Z-400)>160 then self:Eliminate(p) end
        end
    end
end
function Context:Push(player)
    if self.Info.Id~="Sumo" or not self.Alive[player.UserId] then return end
    local _,root=self:Character(player) if not root then return end
    local now=os.clock() if now-(self.LastPush[player] or 0)<1.5 then return end self.LastPush[player]=now
    self:Effect("Push",root.Position)
    self:Each(function(p,_,r)
        local offset=r.Position-root.Position
        if p~=player and offset.Magnitude<10 and offset.Magnitude>.05 and root.CFrame.LookVector:Dot(offset.Unit)>-.1 then
            Ragdoll.Start(p.Character,.65,offset.Unit*42+Vector3.new(0,16,0))
        end
    end)
end
function Context:DoubleJump(player)
    if not player:GetAttribute("DoubleJump") or not self.Alive[player.UserId] then return end
    local h,r=self:Character(player) if not h then return end
    local now=os.clock() if now-(self.LastJump[player] or 0)<1 then return end
    if h.FloorMaterial~=Enum.Material.Air then return end
    self.LastJump[player]=now r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X,55,r.AssemblyLinearVelocity.Z)
end
return Context
