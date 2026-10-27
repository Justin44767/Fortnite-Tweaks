local RS=game:GetService("ReplicatedStorage")
local Events=require(script.Parent.ChaosEvents)
local Scope=require(RS.Shared.Scope)
local Ragdoll=require(script.Parent.Ragdoll)
local Games={}
local function loop(ctx,seconds,fn) Events.Every(ctx.Scope,seconds,fn) end
local function touch(ctx,part,fn)
    ctx.Scope:Add(part.Touched:Connect(function(hit) local p=ctx:PlayerFromHit(hit) if p then fn(p,hit) end end))
end
local function finish(ctx)
    touch(ctx,ctx.Map.Finish,function(p) ctx:Finish(p) end)
end
local function sizedHeads(ctx)
    Events.Handlers.GiantHead(ctx,ctx.Scope)
    ctx:Each(function(_,h) ctx.Scope:Property(h,"WalkSpeed",14) end)
end
Games.Lava=function(ctx)
    local lava=ctx.Map.Lava local disappearing={}
    loop(ctx,.1,function()
        local age=os.clock()-ctx.Started lava.Position=Vector3.new(0,-3+age*.43,400)
        ctx:Each(function(p,_,r) if r.Position.Y<lava.Position.Y+2 then ctx:Eliminate(p) end end)
    end)
    loop(ctx,7,function()
        local choices={}
        for _,v in ctx.Map:GetChildren() do if v.Name=="Platform" and v.Position.Y<28 and not disappearing[v] then table.insert(choices,v) end end
        if #choices>0 then
            local p=choices[ctx.Random:NextInteger(1,#choices)] disappearing[p]=true p.Color=Color3.fromRGB(255,245,60)
            ctx.Scope:Delay(1.5,function() p.CanCollide=false p.Transparency=1 end)
        end
    end)
end
Games.Bananas=function(ctx) Events.Rain(ctx,ctx.Scope,"Banana",.8,52) end
Games.Button=function(ctx)
    local last=0
    ctx.Scope:Add(ctx.Map.ChaosButton.Prompt.Triggered:Connect(function(p)
        local _,r=ctx:Character(p)
        if ctx.Alive[p.UserId] and r and (r.Position-ctx.Map.ChaosButton.Position).Magnitude<14 and os.clock()-last>3 then
            if Events.Random(ctx) then last=os.clock() end
        end
    end))
    Events.Rain(ctx,ctx.Scope,"Ball",8,30)
end
Games.Duck=function(ctx) finish(ctx) Events.Chaser(ctx,ctx.Scope,"Duck",Vector3.new(0,5,316),13) end
Games.Ice=function(ctx)
    Events.Handlers.Slippery(ctx,ctx.Scope)
    loop(ctx,4,function()
        local direction=Vector3.new(ctx.Random:NextNumber(-1,1),0,ctx.Random:NextNumber(-1,1))
        ctx:Message("WINDSTOSS!") ctx:Each(function(_,_,r) r:ApplyImpulse(direction*25*r.AssemblyMass) end)
    end)
    Events.Rain(ctx,ctx.Scope,"Ball",3,35)
end
Games.Disasters=function(ctx)
    local cycle=0
    loop(ctx,12,function()
        cycle+=1
        if ctx.ActiveEvent then ctx.ActiveEvent:Clean() end
        if cycle%3==0 then
            local scope=Scope.new() ctx.Scope:Add(function() scope:Clean() end)
            local water=scope:Add(ctx:Part("Flood",Vector3.new(0,-2,400),Vector3.new(100,1,100),Color3.fromRGB(70,175,255))) water.CanCollide=false water.Transparency=.35
            local start=os.clock() ctx:Message("FLUT! Klettere auf die Türme!")
            Events.Every(scope,.1,function()
                water.Position=Vector3.new(0,math.min(7,(os.clock()-start)*1.4)-2,400)
                ctx:Each(function(p,_,r) if r.Position.Y<water.Position.Y then ctx:Eliminate(p) end end)
            end)
            scope:Delay(9,function() scope:Clean() end)
        elseif cycle%3==1 then Events.Start(ctx,"Tornado",9)
        else Events.Start(ctx,"Meteors",9) end
    end)
end
Games.Music=function(ctx)
    local tiles=ctx.Map.Tiles:GetChildren() local colors={} for _,p in tiles do colors[p]=p.Color end
    local cycle=0
    loop(ctx,10,function()
        cycle+=1 local safe={}
        for _,p in tiles do p.CanCollide=true p.Transparency=0 p.Color=colors[p] end
        local count=math.max(7,30-cycle*2)
        local shuffled=table.clone(tiles)
        for i=#shuffled,2,-1 do local j=ctx.Random:NextInteger(1,i) shuffled[i],shuffled[j]=shuffled[j],shuffled[i] end
        for i=1,count do safe[shuffled[i]]=true end
        ctx.Remotes.State:FireAllClients("Music",true) ctx:Message("Tanzen! Gleich stoppt die Musik …")
        ctx.Scope:Delay(5,function()
            ctx.Remotes.State:FireAllClients("Music",false) ctx:Message("STOPP! Auf die GRÜNEN Plattformen!")
            for _,p in tiles do p.Color=if safe[p] then Color3.fromRGB(90,255,145) else Color3.fromRGB(255,90,110) end
        end)
        ctx.Scope:Delay(7,function() for _,p in tiles do if not safe[p] then p.CanCollide=false p.Transparency=1 end end end)
    end)
end
local function obstacleRace(ctx,heads)
    finish(ctx) if heads then sizedHeads(ctx) end
    for _,v in ctx.Map:GetChildren() do
        if v.Name=="Spinner" then
            local base=v.CFrame
            loop(ctx,.05,function() v.CFrame=base*CFrame.Angles(0,(os.clock()-ctx.Started)*1.5,0) end)
            local cooldown={}
            touch(ctx,v,function(p)
                if os.clock()-(cooldown[p] or 0)>1 then cooldown[p]=os.clock() Ragdoll.Start(p.Character,.6,Vector3.new(18,15,10)) end
            end)
        elseif v.Name=="Moving" then
            local base=v.Position
            loop(ctx,.05,function() v.Position=base+Vector3.new(math.sin((os.clock()-ctx.Started)*.8)*7,0,0) end)
        elseif v.Name=="Spring" then
            local last={}
            touch(ctx,v,function(p)
                local _,r=ctx:Character(p)
                if r and os.clock()-(last[p] or 0)>.7 then last[p]=os.clock() r.AssemblyLinearVelocity=Vector3.new(r.AssemblyLinearVelocity.X,65,23) ctx:Effect("Bounce",r.Position) end
            end)
        end
    end
    if not heads then Events.Rain(ctx,ctx.Scope,"Banana",7,20) end
end
Games.Race=function(ctx) obstacleRace(ctx,false) end
Games.Heads=function(ctx) obstacleRace(ctx,true) end
Games.Potato=function(ctx)
    local carrier,deadline,lastPass=nil,os.clock()+12,0
    local potato=ctx.Scope:Add(ctx:Part("HotPotato",Vector3.new(0,8,400),Vector3.new(3,3,3),Color3.fromRGB(255,135,60))) potato.Shape=Enum.PartType.Ball potato.CanCollide=false potato.Material=Enum.Material.Neon
    local function choose()
        local list={} ctx:Each(function(p) table.insert(list,p) end)
        carrier=if #list>0 then list[ctx.Random:NextInteger(1,#list)] else nil
        deadline=os.clock()+12 lastPass=os.clock()
    end
    choose()
    local lastSecond=-1
    loop(ctx,.1,function()
        if not carrier or not ctx.Alive[carrier.UserId] then choose() end
        if not carrier then return end
        local _,r=ctx:Character(carrier) if not r then choose() return end
        potato.Position=r.Position+Vector3.new(0,4,0)
        local now=os.clock() local seconds=math.ceil(deadline-now)
        if seconds~=lastSecond then lastSecond=seconds ctx:Message("KARTOFFEL: "..carrier.DisplayName.." · "..seconds.."s") end
        if now>=deadline then
            if #ctx.Players==1 then
                -- Solo variant: drop the potato at the blue bumper before each fuse expires.
                ctx:Eliminate(carrier)
            else ctx:Effect("Explosion",r.Position) ctx:Eliminate(carrier) end
            choose()
        elseif #ctx.Players==1 then
            if (r.Position-Vector3.new(25,3,400)).Magnitude<9 then
                ctx.Scores[carrier.UserId]+=1 deadline=now+12
                ctx:Message("Kartoffel abgekühlt! +1")
                carrier.Character:PivotTo(CFrame.new(-25,5,400))
            end
        elseif now-lastPass>1 then
            ctx:Each(function(p,_,other)
                if p~=carrier and now-lastPass>1 and (other.Position-r.Position).Magnitude<5 then
                    carrier=p lastPass=now lastSecond=-1
                end
            end)
        end
    end)
    if #ctx.Players==1 then ctx:Message("SOLO: Bring die Kartoffel alle 12s zum rechten Bumper!") end
end
Games.Color=function(ctx)
    local tiles=ctx.Map.Tiles:GetChildren() local names={"PINK","TÜRKIS","GELB","LILA","GRÜN","ORANGE"}
    loop(ctx,9,function()
        for _,p in tiles do p.CanCollide=true p.Transparency=0 end
        local color=ctx.Random:NextInteger(1,6) ctx:Message("FARBE: "..names[color].." — 5 SEKUNDEN!")
        ctx.Remotes.State:FireAllClients("Color",color)
        ctx.Scope:Delay(5,function()
            for _,p in tiles do if tonumber(p.Name:match("_(%d+)$"))~=color then p.CanCollide=false p.Transparency=1 end end
        end)
    end)
end
Games.TNT=function(ctx)
    local triggered={}
    loop(ctx,.08,function()
        ctx:Each(function(p)
            local hit=ctx:Ground(p)
            if hit and hit.Instance.Parent==ctx.Map.Tiles and not triggered[hit.Instance] then
                local tile=hit.Instance triggered[tile]=true tile.Color=Color3.fromRGB(255,90,70)
                ctx.Scope:Delay(.65,function() tile.CanCollide=false tile.Transparency=1 end)
            end
        end)
    end)
end
Games.Flying=function(ctx)
    ctx.Scope:Property(workspace,"Gravity",48)
    ctx:Each(function(_,h) ctx.Scope:Property(h,"JumpPower",48) end)
    local targets={} local rings=ctx.Map.Rings:GetChildren()
    table.sort(rings,function(a,b) return tonumber(a.Name:match('%d+'))<tonumber(b.Name:match('%d+')) end)
    loop(ctx,.1,function()
        ctx:Each(function(p,_,r)
            local nextIndex=(ctx.Scores[p.UserId] or 0)%#rings+1
            local target=rings[nextIndex].Center
            if targets[p]~=nextIndex then targets[p]=nextIndex ctx.Remotes.State:FireClient(p,"Target",target.Position) end
            if (r.Position-target.Position).Magnitude<6 then
                ctx.Scores[p.UserId]+=1 p:SetAttribute("RoundScore",ctx.Scores[p.UserId]) ctx:Effect("Bounce",target.Position)
                if ctx.Scores[p.UserId]>=10 then ctx.Finished[p.UserId]=os.clock()-ctx.Started ctx:Eliminate(p) end
            end
        end)
    end)
    loop(ctx,6,function()
        local wind=Vector3.new(ctx.Random:NextNumber(-12,12),5,ctx.Random:NextNumber(-12,12))
        ctx:Each(function(_,_,r) r:ApplyImpulse(wind*r.AssemblyMass) end) ctx:Message("WIND! Folge deinem goldenen Zielmarker.")
    end)
end
Games.Sumo=function(ctx)
    loop(ctx,12,function()
        local f=ctx.Map.Floor f.Size=Vector3.new(2,math.max(26,f.Size.Y-6),math.max(26,f.Size.Z-6)) ctx:Message("Der Ring schrumpft!")
    end)
end
Games.Doors=function(ctx)
    local safe={} local stage={} local cooldown={}
    for row=1,4 do safe[row]=ctx.Random:NextInteger(1,3) end
    for _,door in ctx.Map.Doors:GetChildren() do
        local row,col=door.Name:match('Door_(%d+)_(%d+)') row=tonumber(row) col=tonumber(col)
        touch(ctx,door,function(p)
            local now=os.clock() if now-(cooldown[p] or 0)<1 then return end cooldown[p]=now
            local current=stage[p] or 1
            if row~=current then return end
            if col==safe[row] then
                stage[p]=row+1 p.Character:PivotTo(CFrame.new(door.Position+Vector3.new(0,1,8))) ctx:Effect("Victory",door.Position)
            else
                local choice=ctx.Random:NextInteger(1,3) local _,r=ctx:Character(p)
                if choice==1 then Ragdoll.Start(p.Character,1,Vector3.new(0,40,-38))
                elseif choice==2 then p.Character:PivotTo(CFrame.new(0,5,door.Position.Z-15)) ctx:Effect("Confetti",door.Position)
                else r.AssemblyLinearVelocity=Vector3.new(ctx.Random:NextNumber(-28,28),18,-45) ctx:Effect("Bounce",door.Position) end
            end
        end)
    end
    touch(ctx,ctx.Map.Finish,function(p) if stage[p]==5 then ctx:Finish(p) else p.Character:PivotTo(CFrame.new(0,5,340+((stage[p] or 1)-1)*40)) end end)
    -- Enforce checkpoint order even if a player jumps around a door frame.
    loop(ctx,.2,function()
        ctx:Each(function(p,_,r)
            local nextRow=stage[p] or 1
            if nextRow<=4 and r.Position.Z>355+(nextRow-1)*40+5 then p.Character:PivotTo(CFrame.new(0,5,340+(nextRow-1)*40)) end
        end)
    end)
end
function Games.Start(ctx)
    local start=Games[ctx.Info.Id] assert(start,"Missing minigame: "..ctx.Info.Id) start(ctx)
end
return Games
