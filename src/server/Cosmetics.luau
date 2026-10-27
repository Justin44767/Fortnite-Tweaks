local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.Shared.Catalog)
local Cosmetics={}
local function color(p) local c=p.Color or {255,210,100} return Color3.fromRGB(c[1],c[2],c[3]) end
function Cosmetics.Apply(player,data)
    local character=player.Character
    for _,category in {"Pets","Trails","Hats","Wings","Costumes","Auras","Ragdoll","Victory"} do player:SetAttribute("Equipped"..category,data.Equipped[category]) end
    if not character then return end
    local old=character:FindFirstChild("NeroCosmetics") if old then old:Destroy() end
    for _,v in character:GetDescendants() do if v:IsA("Attachment") and v.Name=="NeroTrailAttachment" then v:Destroy() end end
    local folder=Instance.new("Folder") folder.Name="NeroCosmetics" folder.Parent=character
    local root=character:FindFirstChild("HumanoidRootPart") local head=character:FindFirstChild("Head") if not root or not head then return end
    for category,id in data.Equipped do
        local product=Catalog.ById[id]
        if product and data.Owned[id] then
            if category=="Trails" then
                local a=Instance.new("Attachment") a.Name="NeroTrailAttachment" a.Position=Vector3.new(-.7,0,.4) a.Parent=root
                local b=a:Clone() b.Position=Vector3.new(.7,0,.4) b.Parent=root
                local trail=Instance.new("Trail") trail.Attachment0=a trail.Attachment1=b trail.Lifetime=.65 trail.MinLength=.1 trail.FaceCamera=true
                trail.Color=if id=="RainbowTrail" then ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,100,160)),ColorSequenceKeypoint.new(.5,Color3.fromRGB(255,220,80)),ColorSequenceKeypoint.new(1,Color3.fromRGB(90,225,240))}) else ColorSequence.new(color(product))
                trail.Parent=folder
            elseif category=="Auras" then
                local highlight=Instance.new("Highlight") highlight.Adornee=character highlight.FillColor=color(product) highlight.FillTransparency=.8 highlight.OutlineTransparency=.3 highlight.DepthMode=Enum.HighlightDepthMode.Occluded highlight.Parent=folder
            elseif category=="Hats" or category=="Wings" or category=="Costumes" then
                local model=RS.Assets[product.Model]:Clone() model.Parent=folder
                local target=if category=="Hats" then head else root
                local offset=if category=="Hats" then CFrame.new(0,1.1,0) elseif category=="Wings" then CFrame.new(0,.5,1) else CFrame.new(0,-.2,-1)
                model:ScaleTo(if category=="Costumes" then 1.4 else 1)
                model:PivotTo(target.CFrame*offset)
                for _,p in model:GetDescendants() do
                    if p:IsA("BasePart") then
                        p.Anchored=false p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Massless=true
                        local weld=Instance.new("WeldConstraint") weld.Part0=target weld.Part1=p weld.Parent=p
                    end
                end
            end
        end
    end
end
return Cosmetics
