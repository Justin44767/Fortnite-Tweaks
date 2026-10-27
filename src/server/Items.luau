local RS=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
local Players=game:GetService("Players")
local Catalog=require(RS.Shared.Catalog)
local Ragdoll=require(script.Parent.Ragdoll)
local Items={Last={},Selected={}}
function Items.Select(player,id)
    if not Catalog.ItemById[id] then return false end
    Items.Selected[player]=id player:SetAttribute("PartyItem",id) return true
end
local function burst(remotes,name,pos) remotes.Effect:FireAllClients(name,pos) end
function Items.Use(player,remotes)
    if player:GetAttribute("InRound") then return end
    local definition=Catalog.ItemById[Items.Selected[player] or "Confetti"]
    local character=player.Character local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 or math.abs(root.Position.Z)>150 then return end
    if os.clock()-(Items.Last[player] or 0)<definition.Cooldown then return end Items.Last[player]=os.clock()
    local hand=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or root
    local prop=RS.Assets[definition.Model]:Clone() prop:ScaleTo(.65) prop:PivotTo(hand.CFrame*CFrame.new(0,-.8,-.6)) prop.Parent=workspace
    for _,part in prop:GetDescendants() do
        if part:IsA("BasePart") then part.Anchored=false part.Massless=true part.CanCollide=false part.CanTouch=false
            local weld=Instance.new("WeldConstraint") weld.Part0=hand weld.Part1=part weld.Parent=part end
    end
    Debris:AddItem(prop,1.2) remotes.Effect:FireAllClients("ItemSwing",player.UserId)
    burst(remotes,definition.Sound,root.Position)
    local id=definition.Id local position=root.Position local look=root.CFrame.LookVector
    if id=="Boots" then root.AssemblyLinearVelocity=Vector3.new(root.AssemblyLinearVelocity.X,75,root.AssemblyLinearVelocity.Z)
    elseif id=="Rocket" then Ragdoll.Start(character,1,Vector3.new(0,65,0)) burst(remotes,"Rocket",position)
    elseif id=="Confetti" or id=="Horn" or id=="Chicken" then burst(remotes,"Confetti",position)
    elseif id=="Peel" then
        local peel=RS.Assets.Banana:Clone() peel:ScaleTo(.8) peel:PivotTo(CFrame.new(position+look*5-Vector3.new(0,2.5,0))) peel.Parent=workspace Debris:AddItem(peel,8)
        local touched={}
        for _,part in peel:GetChildren() do
            if part:IsA("BasePart") then
                part.Touched:Connect(function(hit)
                    local model=hit:FindFirstAncestorOfClass("Model") local other=model and Players:GetPlayerFromCharacter(model)
                    if other and not other:GetAttribute("InRound") and not touched[other] then touched[other]=true Ragdoll.Start(model,1,look*15+Vector3.new(0,12,0)) end
                end)
            end
        end
    else
        local effectName=if id=="Water" then "Water" elseif id=="Bubble" then "Bubble" else "Push"
        burst(remotes,effectName,position+look*5)
        for _,other in Players:GetPlayers() do
            local c=other.Character local r=c and c:FindFirstChild("HumanoidRootPart")
            if other~=player and r and not other:GetAttribute("InRound") then
                local delta=r.Position-position
                if delta.Magnitude<16 and delta.Magnitude>.1 and look:Dot(delta.Unit)>.55 then
                    if id=="Bubble" then r:ApplyImpulse(Vector3.new(0,35,0)*r.AssemblyMass) burst(remotes,"Bubble",r.Position)
                    else Ragdoll.Start(c,.8,delta.Unit*(if id=="Hammer" then 28 else 18)+Vector3.new(0,14,0)) end
                end
            end
        end
        if id=="Ball" then
            local ball=Instance.new("Part") ball.Name="ToyBeachBall" ball.Shape=Enum.PartType.Ball ball.Size=Vector3.new(5,5,5) ball.Color=Color3.fromRGB(255,135,190) ball.Position=position+look*7
            ball.CustomPhysicalProperties=PhysicalProperties.new(.3,.2,.8) ball.Parent=workspace ball:SetNetworkOwner(nil) ball.AssemblyLinearVelocity=look*32+Vector3.new(0,15,0) Debris:AddItem(ball,7)
        end
    end
end
function Items.Remove(player) Items.Last[player]=nil Items.Selected[player]=nil end
return Items
