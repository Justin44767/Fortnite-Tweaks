local Ragdoll={Active={}}
function Ragdoll.Stop(character)
    local state=Ragdoll.Active[character] if not state then return end
    Ragdoll.Active[character]=nil
    for _,joint in state.Joints do if joint.Parent then joint.Enabled=true end end
    for _,part in state.Parts do if part.Parent then part.CanCollide=state.Collision[part] end end
    for _,v in state.Created do v:Destroy() end
    local humanoid=character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health>0 then
        humanoid.PlatformStand=false humanoid.AutoRotate=state.AutoRotate
        humanoid.RequiresNeck=state.RequiresNeck
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    character:SetAttribute("Ragdolled",false)
end
function Ragdoll.Start(character,duration,impulse)
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local hum=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health<=0 then return end
    if impulse then root:ApplyImpulse(impulse*root.AssemblyMass) end
    local existing=Ragdoll.Active[character]
    if existing then existing.Until=math.max(existing.Until,os.clock()+duration) return end
    local state={Until=os.clock()+duration,Joints={},Parts={},Collision={},Created={},AutoRotate=hum.AutoRotate,RequiresNeck=hum.RequiresNeck}
    Ragdoll.Active[character]=state
    hum.RequiresNeck=false hum.AutoRotate=false hum.PlatformStand=true
    for _,v in character:GetDescendants() do
        if v:IsA("Motor6D") and v.Part0 and v.Part1 and v.Name~="RootJoint" and v.Name~="Root" then
            local a=Instance.new("Attachment") a.CFrame=v.C0 a.Parent=v.Part0
            local b=Instance.new("Attachment") b.CFrame=v.C1 b.Parent=v.Part1
            local socket=Instance.new("BallSocketConstraint") socket.Attachment0=a socket.Attachment1=b
            socket.LimitsEnabled=true socket.UpperAngle=45 socket.TwistLimitsEnabled=true socket.TwistLowerAngle=-35 socket.TwistUpperAngle=35 socket.Parent=v.Part0
            local no=Instance.new("NoCollisionConstraint") no.Part0=v.Part0 no.Part1=v.Part1 no.Parent=v.Part0
            table.insert(state.Created,a) table.insert(state.Created,b) table.insert(state.Created,socket) table.insert(state.Created,no)
            table.insert(state.Joints,v) v.Enabled=false
        elseif v:IsA("BasePart") and v~=root and v.Parent==character then
            table.insert(state.Parts,v) state.Collision[v]=v.CanCollide v.CanCollide=true
        end
    end
    character:SetAttribute("Ragdolled",true)
    task.spawn(function()
        while character.Parent and Ragdoll.Active[character]==state and os.clock()<state.Until do task.wait(.15) end
        if Ragdoll.Active[character]==state then Ragdoll.Stop(character) end
    end)
end
return Ragdoll
