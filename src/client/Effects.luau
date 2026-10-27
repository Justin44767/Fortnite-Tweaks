local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local SoundService=game:GetService("SoundService")
local Config=require(RS.Shared.Config)
local Catalog=require(RS.Shared.Catalog)
local Effects={Settings={Music=true,Effects=true,ReducedMotion=false,Quality="High"},Pets={},Emotes={}}
local player=Players.LocalPlayer
local localFolder=Instance.new("Folder") localFolder.Name="NeroLocalVisuals" localFolder.Parent=workspace
local music=Instance.new("Sound") music.Name="NeroMusic" music.SoundId=Config.Audio.Music music.Volume=.18 music.Looped=true music.Parent=SoundService
local musicPlaying=false
function Effects.Sound(name,pos)
    if not Effects.Settings.Effects then return end
    local id=Config.Audio[name] if not id or id=="" then return end
    local sound=Instance.new("Sound") sound.SoundId=id sound.Volume=.4 sound.RollOffMaxDistance=100
    if pos then
        local anchor=Instance.new("Part") anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Transparency=1 anchor.Size=Vector3.one*.1 anchor.Position=pos anchor.Parent=localFolder
        sound.Parent=anchor Debris:AddItem(anchor,5)
    else sound.Parent=SoundService Debris:AddItem(sound,5) end
    sound:Play()
end
function Effects.Music(active)
    musicPlaying=active
    if active and Effects.Settings.Music and Config.Audio.Music~="" then if not music.IsPlaying then music:Play() end music.Volume=.18 else music:Stop() end
end
function Effects.Configure(settings) Effects.Settings=settings Effects.Music(musicPlaying) end
local function particles(pos,color,count)
    if not Effects.Settings.Effects then return end
    local anchor=Instance.new("Part") anchor.Anchored=true anchor.CanCollide=false anchor.CanTouch=false anchor.CanQuery=false anchor.Transparency=1 anchor.Size=Vector3.one*.1 anchor.Position=pos anchor.Parent=localFolder
    local emitter=Instance.new("ParticleEmitter") emitter.Texture="rbxasset://textures/particles/sparkles_main.dds" emitter.Color=ColorSequence.new(color or Color3.fromRGB(255,160,220))
    emitter.Lifetime=NumberRange.new(.5,1.2) emitter.Speed=NumberRange.new(8,18) emitter.SpreadAngle=Vector2.new(180,180) emitter.Acceleration=Vector3.new(0,-20,0)
    emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.6),NumberSequenceKeypoint.new(1,0)}) emitter.Rate=0 emitter.Parent=anchor
    emitter:Emit(if Effects.Settings.Quality=="Low" then math.min(count,8) else count) Debris:AddItem(anchor,2)
end
local function bubble(pos,color)
    if not Effects.Settings.Effects then return end
    local p=Instance.new("Part") p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Shape=Enum.PartType.Ball p.Material=Enum.Material.Neon
    p.Size=Vector3.one p.Color=color or Color3.fromRGB(115,225,255) p.Transparency=.4 p.Position=pos p.Parent=localFolder
    Tween:Create(p,TweenInfo.new(.5),{Size=Vector3.one*9,Transparency=1}):Play() Debris:AddItem(p,.6)
end
local function stopEmote(id)
    local animation=Effects.Emotes[id] if not animation then return end
    for motor,c0 in animation.Joints do if motor.Parent then motor.C0=c0 end end
    Effects.Emotes[id]=nil
end
function Effects.Emote(id,name)
    local p=Players:GetPlayerByUserId(id) local c=p and p.Character if not c then return end
    stopEmote(id)
    local joints={}
    for _,v in c:GetDescendants() do if v:IsA("Motor6D") then joints[v]=v.C0 end end
    Effects.Emotes[id]={Character=c,Name=name,Start=os.clock(),Joints=joints}
end
local targetMarker
function Effects.Target(pos)
    if targetMarker then targetMarker:Destroy() targetMarker=nil end
    if typeof(pos)~="Vector3" then return end
    local p=Instance.new("Part") p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Transparency=1 p.Size=Vector3.one p.Position=pos p.Parent=localFolder targetMarker=p
    local g=Instance.new("BillboardGui") g.Size=UDim2.fromOffset(100,50) g.AlwaysOnTop=true g.StudsOffset=Vector3.new(0,6,0) g.Parent=p
    local text=Instance.new("TextLabel") text.Size=UDim2.fromScale(1,1) text.BackgroundTransparency=1 text.Text="▼ DEIN RING" text.TextColor3=Color3.fromRGB(255,225,75) text.Font=Enum.Font.GothamBold text.TextSize=16 text.Parent=g
end
function Effects.Handle(name,a,b)
    if name=="Emote" then Effects.Emote(a,b) return end
    if name=="ItemSwing" then Effects.Emote(a,"ItemSwing") return end
    if name=="Photo" then
        if Effects.Settings.ReducedMotion then return end
        local camera=workspace.CurrentCamera local c=player.Character local r=c and c:FindFirstChild("HumanoidRootPart")
        if not r then return end
        camera.CameraType=Enum.CameraType.Scriptable
        camera.CFrame=CFrame.lookAt(r.Position+Vector3.new(0,3,-12),r.Position+Vector3.new(0,1,0))
        task.delay(4,function() camera.CameraType=Enum.CameraType.Custom end) return
    end
    if typeof(a)~="Vector3" then return end
    if name=="Confetti" then particles(a,b,30)
    elseif name=="Water" or name=="Bubble" then bubble(a,Color3.fromRGB(100,215,255))
    elseif name=="Rocket" then particles(a,Color3.fromRGB(255,185,65),24) Effects.Sound("Horn",a)
    elseif name=="Push" then bubble(a,Color3.fromRGB(215,160,255))
    else Effects.Sound(name,a) if name=="Victory" or name=="Explosion" then particles(a,b,20) end end
end
local accumulator=0
Run.RenderStepped:Connect(function(dt)
    accumulator+=dt
    local time=os.clock()
    -- Cosmetic pets render locally for every player; never participate in physics or scores.
    if accumulator>(if Effects.Settings.Quality=="Low" then .08 else .03) then
        accumulator=0
        for _,p in Players:GetPlayers() do
            local product=Catalog.ById[p:GetAttribute("EquippedPets")]
            local c=p.Character local root=c and c:FindFirstChild("HumanoidRootPart") local pet=Effects.Pets[p]
            if pet and (not product or pet.Id~=product.Id or not root) then pet.Model:Destroy() Effects.Pets[p]=nil pet=nil end
            if product and root then
                if not pet then
                    local m=RS.Assets[product.Model]:Clone() m:ScaleTo(.6) m.Parent=localFolder
                    pet={Model=m,Id=product.Id} Effects.Pets[p]=pet m:PivotTo(root.CFrame*CFrame.new(3,-.6,3))
                end
                local desired=root.CFrame*CFrame.new(3,-.5+math.sin(time*3+p.UserId)*.35,3)
                pet.Model:PivotTo(pet.Model:GetPivot():Lerp(desired,.22))
            end
        end
        for p,pet in Effects.Pets do if not p.Parent then pet.Model:Destroy() Effects.Pets[p]=nil end end
        if musicPlaying and Effects.Settings.Music and Config.Audio.Music=="" and math.floor(time*2)~=Effects.LastBeat then
            Effects.LastBeat=math.floor(time*2)
            local sound=Instance.new("Sound") sound.SoundId=Config.Audio.Countdown sound.Volume=.13 sound.PlaybackSpeed=({1,1.25,1.5,1.25})[Effects.LastBeat%4+1] sound.Parent=SoundService sound:Play() Debris:AddItem(sound,2)
        end
    end
    for id,animation in Effects.Emotes do
        local c=animation.Character local h=c:FindFirstChildOfClass("Humanoid") local t=time-animation.Start
        if not c.Parent or not h or h.Health<=0 or h.MoveDirection.Magnitude>.1 or c:GetAttribute("Ragdolled") or t>(if animation.Name=="ItemSwing" then .8 else 5) then stopEmote(id)
        else
            local name=animation.Name local wave=math.sin(t*7)
            for joint,original in animation.Joints do
                if joint.Parent then
                    local n=joint.Name local transform=CFrame.identity
                    if n:find("Shoulder") then
                        local sign=if n:find("Right") then 1 else -1
                        if name=="Cry" then transform=CFrame.Angles(-1.5,0,sign*.4)
                        elseif name=="RobotDance" then transform=CFrame.Angles(math.floor(wave*2)*.4,0,sign*1.1)
                        elseif name=="VictoryPose" then transform=CFrame.Angles(0,0,sign*2.3)
                        elseif name=="ItemSwing" then transform=CFrame.Angles(-math.sin(t*math.pi/.8)*1.8,0,0)
                        else transform=CFrame.Angles(wave*.7,0,sign*(.9+wave*.3)) end
                    elseif n=="RootJoint" or n=="Root" or n=="Waist" then
                        if name=="Spin" then transform=CFrame.Angles(0,t*4,0)
                        elseif name=="Backflip" then transform=CFrame.new(0,math.sin(t*math.pi%math.pi)*1.2,0)*CFrame.Angles(-t*math.pi*2,0,0)
                        elseif name=="CrazyJump" then transform=CFrame.new(0,math.abs(wave)*1.5,0)
                        elseif name=="ChickenDance" then transform=CFrame.Angles(wave*.2,0,0)
                        elseif name=="BananaDance" then transform=CFrame.Angles(0,0,wave*.3)
                        elseif name=="Laugh" then transform=CFrame.Angles(.2+wave*.1,0,0)
                        else transform=CFrame.Angles(0,wave*.15,wave*.1) end
                    elseif n=="Neck" then transform=CFrame.Angles(wave*.1,0,0) end
                    joint.C0=original*transform
                end
            end
        end
    end
end)
Run:BindToRenderStep("NeroCamera",Enum.RenderPriority.Camera.Value+1,function()
    if player:GetAttribute("ChaosCamera") and not Effects.Settings.ReducedMotion then workspace.CurrentCamera.CFrame*=CFrame.Angles(0,0,math.sin(os.clock()*5)*.035) end
end)
local function watch(p)
    local function character(c)
        c:GetAttributeChangedSignal("Ragdolled"):Connect(function()
            if c:GetAttribute("Ragdolled") and p:GetAttribute("EquippedRagdoll")=="Stars" then local r=c:FindFirstChild("HumanoidRootPart") if r then particles(r.Position,Color3.fromRGB(255,225,80),18) end end
        end)
    end
    p.CharacterAdded:Connect(character)
    if p.Character then character(p.Character) end
end
Players.PlayerAdded:Connect(watch) for _,p in Players:GetPlayers() do watch(p) end
return Effects
