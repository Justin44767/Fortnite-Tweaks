local Run=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local RS=game:GetService("ReplicatedStorage")
local Scope=require(RS.Shared.Scope)
local Catalog=require(RS.Shared.Catalog)
local Ragdoll=require(script.Parent.Ragdoll)
local Events={}
local function every(scope,interval,callback)
    local elapsed=interval
    scope:Add(Run.Heartbeat:Connect(function(dt)
        elapsed+=dt if elapsed>=interval then elapsed=0 callback(dt) end
    end))
end
Events.Every=every
local function model(ctx,scope,name,pos,scale)
    local m=scope:Add(RS.Assets[name]:Clone()) m.Parent=ctx.Map m:ScaleTo(scale or 1) m:PivotTo(CFrame.new(pos))
    for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=false p.CanTouch=false end end
    return m
end
function Events.Drop(ctx,scope,name,target,radius,power)
    if not scope.Alive then return end
    local warning=scope:Add(ctx:Part("Warning",Vector3.new(target.X,target.Y-3,target.Z),Vector3.new(radius*2,.15,radius*2),Color3.fromRGB(255,75,100)))
    warning.CanCollide=false warning.Material=Enum.Material.Neon warning.Transparency=.4
    scope:Delay(.8,function()
        local object=model(ctx,scope,name,target+Vector3.new(0,55,0),3)
        local t=0 local conn
        conn=Run.Heartbeat:Connect(function(dt)
            if not scope.Alive then return end
            t+=dt object:PivotTo(CFrame.new(target+Vector3.new(0,55*(1-t/.7),0))*CFrame.Angles(t*3,t,0))
            if t>=.7 then
                conn:Disconnect() warning:Destroy() object:Destroy() ctx:Effect("Explosion",target)
                ctx:Each(function(p,_,root)
                    local delta=root.Position-target
                    if delta.Magnitude<radius+3 then
                        local direction=if delta.Magnitude>.1 then delta.Unit else Vector3.xAxis
                        Ragdoll.Start(p.Character,1.3,direction*power+Vector3.new(0,25,0))
                    end
                end)
            end
        end)
        scope:Add(conn)
    end)
end
function Events.Rain(ctx,scope,name,interval,power)
    every(scope,interval,function()
        local choices={} ctx:Each(function(_,_,root) table.insert(choices,root.Position) end)
        if #choices>0 then
            local target=choices[ctx.Random:NextInteger(1,#choices)]+Vector3.new(ctx.Random:NextNumber(-6,6),0,ctx.Random:NextNumber(-6,6))
            Events.Drop(ctx,scope,name,target,6,power or 35)
        end
    end)
end
function Events.Chaser(ctx,scope,name,start,speed)
    local npc=model(ctx,scope,name,start,4)
    local pos=start local waypoints={} local index=1 local nextPath=0 local computing=false
    every(scope,.1,function()
        local target,distance=nil,math.huge
        ctx:Each(function(_,_,root)
            local d=(root.Position-pos).Magnitude if d<distance then distance=d target=root.Position end
        end)
        if not target then return end
        if os.clock()>nextPath and not computing then
            computing=true nextPath=os.clock()+1.5
            local goal=target
            task.spawn(function()
                local path=game:GetService("PathfindingService"):CreatePath({AgentRadius=3,AgentHeight=6,AgentCanJump=false,WaypointSpacing=5})
                local ok=pcall(function() path:ComputeAsync(pos,goal) end)
                if scope.Alive and ok and path.Status==Enum.PathStatus.Success then waypoints=path:GetWaypoints() index=2 end
                computing=false path:Destroy()
            end)
        end
        local goal=if waypoints[index] then waypoints[index].Position else target
        local delta=Vector3.new(goal.X-pos.X,0,goal.Z-pos.Z)
        if delta.Magnitude<3 and waypoints[index] then index+=1 end
        if delta.Magnitude>.1 then
            local step=delta.Unit*math.min(speed*.1,delta.Magnitude)
            local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.FilterDescendantsInstances={npc}
            local obstruction=workspace:Raycast(pos,step+delta.Unit*2,params)
            if not obstruction or obstruction.Instance:IsDescendantOf(npc) or not obstruction.Instance.CanCollide then pos+=step end
            npc:PivotTo(CFrame.lookAt(pos+Vector3.new(0,math.sin(os.clock()*7)*.3,0),pos+delta.Unit))
        end
        ctx:Each(function(p,_,root) if (root.Position-pos).Magnitude<6 then ctx:Effect("Duck",root.Position) ctx:Eliminate(p) end end)
    end)
    return npc
end
local handlers={}
handlers.GiantHead=function(ctx,s)
    ctx:Each(function(p)
        local hum=p.Character:FindFirstChildOfClass("Humanoid") local scale=hum:FindFirstChild("HeadScale")
        if scale then s:Property(scale,"Value",scale.Value*2)
        else local head=p.Character:FindFirstChild("Head") if head then s:Property(head,"Size",head.Size*1.7) end end
    end)
end
handlers.Tiny=function(ctx,s)
    ctx:Each(function(p)
        local c=p.Character local old=c:GetScale() c:ScaleTo(old*.55)
        s:Add(function() if c.Parent then c:ScaleTo(old) end end)
    end)
end
handlers.Gravity=function(_,s) s:Property(workspace,"Gravity",65) end
handlers.Speed=function(ctx,s) ctx:Each(function(_,h) s:Property(h,"WalkSpeed",28) end) end
handlers.BananaRain=function(c,s) Events.Rain(c,s,"Banana",1.3,40) end
handlers.DuckRain=function(c,s) Events.Rain(c,s,"Duck",1.5,40) end
handlers.Tornado=function(ctx,s)
    local center=Vector3.new(0,8,400) local rings={}
    for i=1,7 do local p=s:Add(ctx:Part("Twister",center,Vector3.new(i*3,2,i*3),Color3.fromRGB(170,150,230))) p.CanCollide=false p.Transparency=.6 table.insert(rings,p) end
    every(s,.1,function()
        local t=os.clock() center=Vector3.new(math.sin(t*.3)*28,3,400+math.cos(t*.3)*28)
        for i,p in rings do p.CFrame=CFrame.new(center+Vector3.new(0,i*3,0))*CFrame.Angles(0,t*3+i,0) end
        ctx:Each(function(p,_,r)
            local d=center-r.Position local horizontal=Vector3.new(d.X,0,d.Z)
            if horizontal.Magnitude<24 and horizontal.Magnitude>.5 then
                local force=horizontal.Unit*12+Vector3.new(-horizontal.Z,0,horizontal.X).Unit*10+Vector3.new(0,13,0)
                r:ApplyImpulse(force*r.AssemblyMass)
                if horizontal.Magnitude<5 then Ragdoll.Start(p.Character,.5) end
            end
        end)
    end)
end
handlers.Ragdoll=function(ctx,s)
    ctx:Each(function(p) local c=p.Character Ragdoll.Start(c,2) s:Add(function() Ragdoll.Stop(c) end) end)
end
handlers.Slippery=function(ctx,s)
    for _,p in ctx.Map:GetDescendants() do
        if p:IsA("BasePart") and p.CanCollide then s:Property(p,"CustomPhysicalProperties",PhysicalProperties.new(.7,0,.2,100,1)) end
    end
    every(s,.15,function() ctx:Each(function(_,h,r) if h.FloorMaterial~=Enum.Material.Air then r:ApplyImpulse(h.MoveDirection*6*r.AssemblyMass) end end) end)
end
handlers.BeachBall=function(ctx,s)
    local ball=s:Add(ctx:Part("BeachBall",Vector3.new(0,15,400),Vector3.new(16,16,16),Color3.fromRGB(255,130,190))) ball.Shape=Enum.PartType.Ball
    every(s,.1,function()
        ball.Position=Vector3.new(math.sin(os.clock()*1.3)*28,10,400+math.cos(os.clock())*25)
        ctx:Each(function(p,_,r)
            local d=r.Position-ball.Position if d.Magnitude<11 then Ragdoll.Start(p.Character,.7,(if d.Magnitude>.1 then d.Unit else Vector3.xAxis)*35+Vector3.new(0,14,0)) end
        end)
    end)
end
local function attribute(ctx,s,key)
    ctx:Each(function(p) local old=p:GetAttribute(key) p:SetAttribute(key,true) s:Add(function() if p.Parent then p:SetAttribute(key,old) end end) end)
end
handlers.Reverse=function(c,s) attribute(c,s,"Reverse") end
handlers.Bounce=function(ctx,s) every(s,1.2,function() ctx:Each(function(_,_,r) r:ApplyImpulse(Vector3.new(0,45,0)*r.AssemblyMass) end) end) end
handlers.Teleport=function(ctx)
    local list={} local positions={} ctx:Each(function(p,_,r) table.insert(list,p) table.insert(positions,r.CFrame) end)
    for i,p in list do p.Character:PivotTo(positions[i%#positions+1]) end
end
handlers.Invisible=function(ctx,s)
    for _,p in ctx.Map:GetDescendants() do if p:IsA("BasePart") and p.CanCollide and p.Name~="MazeWall" then s:Property(p,"Transparency",.85) end end
end
handlers.Rainbow=function(_,s)
    local a=Lighting:FindFirstChildOfClass("Atmosphere")
    if a then
        s:Property(a,"Density",.48) s:Property(a,"Color",Color3.fromHSV(0,.4,1))
        every(s,.25,function() a.Color=Color3.fromHSV(os.clock()*.12%1,.4,1) end)
    end
end
handlers.GiantNPC=function(c,s) Events.Chaser(c,s,"Robot",Vector3.new(-30,5,370),12) end
handlers.Meteors=function(c,s) Events.Rain(c,s,"Ball",1,48) end
handlers.Jump=function(ctx,s) every(s,1.5,function() ctx:Each(function(_,h) h.Jump=true end) end) end
handlers.Camera=function(c,s) attribute(c,s,"ChaosCamera") end
handlers.Furniture=function(ctx,s)
    for i=1,4 do
        local p=s:Add(ctx:Part("FlyingSofa",Vector3.new(0,8,400),Vector3.new(12,3,5),Color3.fromRGB(160,110,220)))
        local back=s:Add(ctx:Part("SofaBack",p.Position,Vector3.new(12,5,1),p.Color)) back.CanCollide=false
        every(s,.1,function()
            local t=os.clock()+i*1.5 p.CFrame=CFrame.new(math.sin(t)*30,6,400+math.cos(t)*30)*CFrame.Angles(0,t,0)
            back.CFrame=p.CFrame*CFrame.new(0,3,2)
            ctx:Each(function(pl,_,r) if (r.Position-p.Position).Magnitude<7 then Ragdoll.Start(pl.Character,1,(r.Position-p.Position).Unit*25+Vector3.new(0,15,0)) end end)
        end)
    end
end
handlers.Chickens=function(c,s) Events.Chaser(c,s,"Chicken",Vector3.new(30,5,425),10) Events.Chaser(c,s,"Chicken",Vector3.new(-30,5,375),10) end
handlers.Confetti=function(ctx,s) every(s,1,function() ctx:Each(function(_,_,r) ctx:Effect("Confetti",r.Position,Color3.fromHSV(ctx.Random:NextNumber(),.7,1)) end) end) end
handlers.Walls=function(ctx,s)
    local wall=s:Add(ctx:Part("MovingWall",Vector3.new(0,5,400),Vector3.new(3,10,55),Color3.fromRGB(255,130,160)))
    every(s,.1,function() wall.Position=Vector3.new(math.sin(os.clock()*.8)*35,5,400) end)
end
handlers.Rocket=function(ctx)
    ctx:Each(function(p,_,r) ctx:Effect("Rocket",r.Position) Ragdoll.Start(p.Character,1.3,Vector3.new(0,80,0)) end)
end
handlers.DoubleJump=function(c,s) attribute(c,s,"DoubleJump") end
Events.Handlers=handlers
function Events.Start(ctx,id,duration)
    if ctx.ActiveEvent or not ctx.Scope.Alive then return false end
    local handler=handlers[id] if not handler then return false end
    local scope=Scope.new() ctx.ActiveEvent=scope ctx.Scope:Add(function() scope:Clean() end)
    scope:Add(function() if ctx.ActiveEvent==scope then ctx.ActiveEvent=nil end end)
    local ok,err=xpcall(function() handler(ctx,scope) end,debug.traceback)
    if not ok then warn("NERO event:",id,err) scope:Clean() return false end
    ctx:Message("CHAOS: "..Catalog.EventById[id].Name)
    scope:Delay(duration or 8,function() scope:Clean() end)
    return true
end
function Events.Random(ctx)
    -- Teleport swaps can skip race checkpoints; moving walls can seal narrow obstacle paths.
    local list={}
    for _,e in Catalog.Events do
        if not (ctx.Info.Kind=="Race" and (e.Id=="Teleport" or e.Id=="Walls" or e.Id=="GiantNPC" or e.Id=="Chickens")) then table.insert(list,e.Id) end
    end
    return Events.Start(ctx,list[ctx.Random:NextInteger(1,#list)])
end
return Events
