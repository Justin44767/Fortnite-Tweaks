local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Social=game:GetService("SocialService")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local Shared=RS:WaitForChild("Shared")
local Catalog=require(Shared.Catalog)
local Rules=require(Shared.Rules)
local Config=require(Shared.Config)
local Effects=require(script.Parent.Effects)
local remotes=RS:WaitForChild("Remotes")
local request,state=remotes:WaitForChild("Request"),remotes:WaitForChild("State")
local profile=Rules.NewProfile() local sessionOnly=false local isOwner=false local lastLevel=1
local round={} local party={Members={}} local invitation=nil local current=nil local selected=nil local shopCategory="Alle"
local voteButtons={} local noticeSerial=0 local musicActive=false
local palette={Background=Color3.fromRGB(22,25,46),Panel=Color3.fromRGB(36,41,68),Card=Color3.fromRGB(53,59,90),Accent=Color3.fromRGB(122,101,255),Pink=Color3.fromRGB(255,112,170),Gold=Color3.fromRGB(255,218,94),Mint=Color3.fromRGB(100,235,195),Text=Color3.fromRGB(246,247,255),Muted=Color3.fromRGB(190,197,220)}
local gui=Instance.new("ScreenGui") gui.Name="NeroInterface" gui.ResetOnSpawn=false gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.DisplayOrder=10 gui.Parent=player:WaitForChild("PlayerGui")
local loading=player.PlayerGui:FindFirstChild("Loading") if loading then loading:Destroy() end
local function make(class,props,parent)
    local obj=Instance.new(class) for k,v in props do obj[k]=v end obj.Parent=parent return obj
end
local function roundCorners(obj,radius) make("UICorner",{CornerRadius=UDim.new(0,radius or 12)},obj) end
local function stroke(obj,color) make("UIStroke",{Color=color or Color3.fromRGB(77,84,122),Thickness=1,Transparency=.25},obj) end
local function text(parent,message,size,color)
    return make("TextLabel",{Text=message,Font=Enum.Font.GothamMedium,TextSize=size or 16,TextColor3=color or palette.Text,BackgroundTransparency=1,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.new(1,0,0,40)},parent)
end
local function button(parent,title,callback,color)
    local b=make("TextButton",{Text=title,Font=Enum.Font.GothamBold,TextSize=15,TextColor3=palette.Text,BackgroundColor3=color or palette.Accent,AutoButtonColor=false,Size=UDim2.new(1,0,0,48),Selectable=true},parent)
    roundCorners(b,10)
    b.Activated:Connect(function() Effects.Sound("Countdown") callback() end)
    b.MouseEnter:Connect(function() Tween:Create(b,TweenInfo.new(.12),{BackgroundTransparency=.18}):Play() end)
    b.MouseLeave:Connect(function() Tween:Create(b,TweenInfo.new(.12),{BackgroundTransparency=0}):Play() end)
    return b
end
local function list(parent,padding,horizontal)
    return make("UIListLayout",{Padding=UDim.new(0,padding or 10),SortOrder=Enum.SortOrder.LayoutOrder,FillDirection=if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical},parent)
end
local function pad(parent,size) make("UIPadding",{PaddingLeft=UDim.new(0,size),PaddingRight=UDim.new(0,size),PaddingTop=UDim.new(0,size),PaddingBottom=UDim.new(0,size)},parent) end
local hud=make("Frame",{Name="HUD",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,8),Size=UDim2.new(.94,0,0,112),BackgroundColor3=palette.Background,BackgroundTransparency=.08},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(850,112)},hud) roundCorners(hud,16) stroke(hud) pad(hud,12)
local brand=text(hud,"NERO  /  CHAOS PARTY",17,palette.Pink) brand.Size=UDim2.new(.62,0,0,24)
local timer=text(hud,"00:00",23,palette.Gold) timer.Size=UDim2.new(.3,0,0,28) timer.Position=UDim2.new(.7,0,0,0) timer.TextXAlignment=Enum.TextXAlignment.Right
local phase=text(hud,"Willkommen auf der Party!",16) phase.Position=UDim2.fromOffset(0,31) phase.Size=UDim2.new(1,0,0,26)
local stats=text(hud,"CHAOS COINS 0  ·  WINS 0  ·  LVL 1",13,palette.Muted) stats.Position=UDim2.fromOffset(0,64) stats.Size=UDim2.new(1,0,0,24)
local toast=make("TextLabel",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,128),Size=UDim2.new(.9,0,0,48),BackgroundColor3=palette.Panel,BackgroundTransparency=.06,Text="",TextColor3=palette.Text,Font=Enum.Font.GothamBold,TextSize=16,TextWrapped=true,Visible=false},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(820,70)},toast) roundCorners(toast)
local function notify(message)
    noticeSerial+=1 local token=noticeSerial toast.Text=message toast.Visible=true
    task.delay(5,function() if token==noticeSerial then toast.Visible=false end end)
end
local menu=make("ScrollingFrame",{Name="Menu",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-8),Size=UDim2.new(.96,0,0,62),BackgroundColor3=palette.Background,BackgroundTransparency=.08,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollBarThickness=2,ScrollingDirection=Enum.ScrollingDirection.X},gui)
roundCorners(menu) pad(menu,7) list(menu,8,true) make("UISizeConstraint",{MaxSize=Vector2.new(1020,62)},menu)
local overlay=make("Frame",{Name="Window",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.52),Size=UDim2.new(.94,0,.72,0),BackgroundColor3=palette.Background,Visible=false,ZIndex=5},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(780,580),MinSize=Vector2.new(260,220)},overlay) roundCorners(overlay,18) stroke(overlay,palette.Accent)
local heading=text(overlay,"PARTY",23) heading.Position=UDim2.fromOffset(18,8) heading.Size=UDim2.new(1,-85,0,44)
local close=button(overlay,"×",function() overlay.Visible=false current=nil GuiService.SelectedObject=nil end,palette.Card) close.Size=UDim2.fromOffset(44,44) close.Position=UDim2.new(1,-52,0,8)
local body=make("ScrollingFrame",{Position=UDim2.fromOffset(0,62),Size=UDim2.new(1,0,1,-70),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=palette.Accent,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()},overlay)
pad(body,14) list(body,10)
local function clear()
    for _,child in body:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
    body.CanvasPosition=Vector2.zero voteButtons={}
end
local function info(message,height)
    local t=text(body,message,15,palette.Muted) t.Size=UDim2.new(1,-8,0,height or 54) return t
end
local function row(title,subtitle,callback,buttonLabel)
    local frame=make("Frame",{Size=UDim2.new(1,-8,0,82),BackgroundColor3=palette.Card},body) roundCorners(frame)
    local label=text(frame,title,16) label.Position=UDim2.fromOffset(12,8) label.Size=UDim2.new(1,-125,0,30)
    local sub=text(frame,subtitle or "",12,palette.Muted) sub.Position=UDim2.fromOffset(12,40) sub.Size=UDim2.new(1,-125,0,30)
    if callback then local b=button(frame,buttonLabel or "Öffnen",callback) b.Size=UDim2.fromOffset(105,52) b.AnchorPoint=Vector2.new(1,.5) b.Position=UDim2.new(1,-10,.5,0) return b end
    label.Size=UDim2.new(1,-24,0,30) sub.Size=UDim2.new(1,-24,0,30)
end
local open
local function preview(product)
    local view=make("ViewportFrame",{Size=UDim2.new(1,-8,0,185),BackgroundColor3=palette.Panel,Ambient=Color3.fromRGB(180,180,200),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-1,-1,-1)},body) roundCorners(view)
    local world=Instance.new("WorldModel") world.Parent=view
    local model
    if product.Model and RS.Assets:FindFirstChild(product.Model) then model=RS.Assets[product.Model]:Clone()
    else
        model=Instance.new("Model")
        local p=Instance.new("Part") p.Shape=Enum.PartType.Ball p.Size=Vector3.one*3 p.Material=Enum.Material.Neon
        local c=product.Color or {160,120,255} p.Color=Color3.fromRGB(c[1],c[2],c[3]) p.Anchored=true p.Parent=model
        if product.Category=="Emotes" then p:Destroy() model=RS.Assets.Robot:Clone() end
    end
    model.Parent=world model:PivotTo(CFrame.new())
    local camera=Instance.new("Camera") camera.CFrame=CFrame.lookAt(Vector3.new(5,3.5,-7),Vector3.new(0,.5,0)) camera.Parent=view view.CurrentCamera=camera
    local conn
    conn=Run.RenderStepped:Connect(function(dt)
        if not view.Parent then conn:Disconnect() return end
        if not profile.Settings.ReducedMotion then model:PivotTo(model:GetPivot()*CFrame.Angles(0,dt*.6,0)) end
    end)
end
local titles={Shop="CHAOS SHOP",Pets="PET CLUB",Rewards="REWARDS",Profile="DEIN PROFIL",Settings="EINSTELLUNGEN",Emotes="EMOTE WHEEL",Party="FREUNDE & PARTY",Items="FUNNY ITEMS",Voting="DEINE STIMME ZÄHLT",Admin="OWNER PANEL",Detail="VORSCHAU"}
local function render()
    clear() heading.Text=titles[current] or "NERO CHAOS PARTY"
    if current=="Shop" or current=="Pets" then
        info(if current=="Pets" then "Deine Begleiter sind kosmetisch. Ausrüsten, sammeln und Favoriten markieren." else "Alle Preise in erspielten Chaos Coins. Vorschau öffnen, kaufen und ausrüsten.",52)
        if current=="Shop" then
            local filters=make("ScrollingFrame",{Size=UDim2.new(1,-8,0,52),BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.X,CanvasSize=UDim2.new(),ScrollBarThickness=2},body) list(filters,6,true)
            for _,category in {"Alle","Trails","Hats","Wings","Costumes","Auras","Ragdoll","Victory","Emotes"} do
                local b=button(filters,category,function() shopCategory=category render() end,if shopCategory==category then palette.Accent else palette.Card) b.Size=UDim2.fromOffset(110,46)
            end
        end
        local products=table.clone(Catalog.Products)
        table.sort(products,function(a,b)
            local af,bf=profile.Favorites[a.Id] or false,profile.Favorites[b.Id] or false
            if af~=bf then return af end return a.Price<b.Price or (a.Price==b.Price and a.Id<b.Id)
        end)
        for _,p in products do
            if (current=="Pets" and p.Category=="Pets") or (current=="Shop" and p.Category~="Pets" and (shopCategory=="Alle" or p.Category==shopCategory)) then
                row((if profile.Favorites[p.Id] then "★ " else "")..p.Name,p.Category.." · "..(if profile.Owned[p.Id] then "In deiner Sammlung" else tostring(p.Price).." Coins"),function() selected=p.Id open("Detail") end,"Vorschau")
            end
        end
    elseif current=="Detail" then
        local p=Catalog.ById[selected] if not p then return end
        heading.Text=p.Name preview(p)
        info(p.Category.." · "..(if profile.Owned[p.Id] then "Gehört dir" else p.Price.." Chaos Coins"),32)
        if not profile.Owned[p.Id] then button(body,"KAUFEN · "..p.Price.." COINS",function() request:FireServer("Buy",p.Id) end)
        elseif p.Category=="Emotes" then button(body,"EMOTE SPIELEN",function() request:FireServer("Emote",p.Id) end)
        else button(body,if profile.Equipped[p.Category]==p.Id then "ABLEGEN" else "AUSRÜSTEN",function() request:FireServer("Equip",p.Id) end) end
        if p.Category=="Pets" and profile.Owned[p.Id] then button(body,if profile.Favorites[p.Id] then "★ FAVORIT ENTFERNEN" else "☆ ALS FAVORIT MARKIEREN",function() request:FireServer("Favorite",p.Id) end,palette.Card) end
        button(body,"ZURÜCK",function() open(if p.Category=="Pets" then "Pets" else "Shop") end,palette.Card)
    elseif current=="Items" then
        info("Kostenlose Party-Requisiten für die Lobby. In gewerteten Minispielen sind Items gesperrt; Sumo hat seinen eigenen Schubs.",64)
        for _,item in Catalog.Items do
            row(item.Name,item.Cooldown.."s Cooldown · "..(if player:GetAttribute("PartyItem")==item.Id then "Ausgewählt" else "Gratis"),function() selected=item.Id open("ItemDetail") end,"Vorschau")
        end
    elseif current=="ItemDetail" then
        local item=Catalog.ItemById[selected] if not item then return end heading.Text=item.Name preview(item)
        info(item.Cooldown.." Sekunden Cooldown · Verwendung in der Lobby",38)
        button(body,"ITEM AUSWÄHLEN",function() request:FireServer("SelectItem",item.Id) end)
        button(body,"BENUTZEN",function() request:FireServer("UseItem") end,palette.Pink)
        button(body,"ZURÜCK ZU ITEMS",function() open("Items") end,palette.Card)
    elseif current=="Rewards" then
        local day=Rules.Day(os.time())
        info("Kostenloses Glücksrad und tägliche Geschenke. Tageswechsel: 00:00 UTC. Keine Robux-Einsätze.",52)
        row("DAILY REWARD", "Serie: "..profile.DailyStreak.." / 7 · Tag 7: Krone (bei Besitz 150 Coins)",function() request:FireServer("Daily") end,if profile.DailyDay>=day then "Abgeholt" else "Abholen")
        local wheel=make("Frame",{Size=UDim2.new(1,-8,0,160),BackgroundColor3=palette.Panel},body) roundCorners(wheel)
        local disc=make("Frame",{Name="Disc",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(138,138),BackgroundColor3=palette.Accent},wheel) roundCorners(disc,100)
        for i=1,8 do
            local a=i*math.pi/4
            local dot=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,math.cos(a)*51,.5,math.sin(a)*51),Size=UDim2.fromOffset(20,20),BackgroundColor3=Color3.fromHSV(i/8,.55,1)},disc) roundCorners(dot,10)
        end
        local center=text(disc,"NERO\nSPIN",19) center.TextXAlignment=Enum.TextXAlignment.Center center.Size=UDim2.fromScale(1,1)
        button(body,if profile.SpinDay>=day then "HEUTE SCHON GEDREHT" else "KOSTENLOS DREHEN",function() request:FireServer("Spin") end,palette.Accent)
        info("Chancen: 25 Coins 45% · 50 Coins 30% · Rainbow Trail 10% · Spin-Emote 8% · Duck Pet 7%. Doppelte Cosmetics ergeben 75 Coins.",68)
        for _,q in Catalog.Quests do row(q.Name,math.min(q.Goal,profile[q.Field]).." / "..q.Goal.." · "..q.Coins.." Coins",function() request:FireServer("Quest",q.Id) end,if profile.QuestClaims[q.Id] then "Erledigt" else "Abholen") end
    elseif current=="Profile" then
        local level=Rules.Level(profile.XP) local nextXP=Rules.LevelXP(level+1)
        info(player.DisplayName.."  ·  LEVEL "..level.."  ·  "..profile.XP.." / "..nextXP.." XP",40)
        local track=make("Frame",{Size=UDim2.new(1,-8,0,18),BackgroundColor3=palette.Card},body) roundCorners(track,9)
        local progress=(profile.XP-Rules.LevelXP(level))/(nextXP-Rules.LevelXP(level))
        local fill=make("Frame",{Size=UDim2.fromScale(math.clamp(progress,0,1),1),BackgroundColor3=palette.Mint},track) roundCorners(fill,9)
        local pets,cosmetics=0,0 for id in profile.Owned do local p=Catalog.ById[id] if p then if p.Category=="Pets" then pets+=1 else cosmetics+=1 end end end
        for _,v in {{"CHAOS COINS",profile.Coins},{"WINS / GAMES WON",profile.Wins},{"GAMES PLAYED",profile.GamesPlayed},{"ÜBERLEBT",profile.Survived},{"SPIELZEIT",math.floor(profile.Playtime/60).." Minuten"},{"SAMMLUNG",pets.." Pets · "..cosmetics.." Cosmetics"}} do row(v[1],tostring(v[2])) end
        for _,a in Catalog.Achievements do row(a.Name,if profile.Achievements[a.Id] then "✓ Freigeschaltet · "..a.Coins.." Bonus-Coins" else tostring(profile[a.Field]).." / "..a.Goal) end
        info("Level-Boni: 5 → 100 Coins · 10 → Rainbow Trail · 20 → Victory Pose · 30 → Dragon Pet · 50 → Disco Aura",60)
        if sessionOnly then info("STUDIO-TEST: Diese Sitzung wird nicht dauerhaft gespeichert. Siehe Installationsanleitung für DataStore-Tests.",68) end
    elseif current=="Settings" then
        for _,setting in {{"Music","Musik"},{"Effects","Sound & Effekte"},{"ReducedMotion","Weniger Bewegung"}} do
            row(setting[2],if profile.Settings[setting[1]] then "An" else "Aus",function() request:FireServer("Settings",{Key=setting[1],Value=not profile.Settings[setting[1]]}) end,"Umschalten")
        end
        row("Grafikqualität",profile.Settings.Quality,function() request:FireServer("Settings",{Key="Quality",Value=if profile.Settings.Quality=="High" then "Low" else "High"}) end,"Umschalten")
        row("AFK",if player:GetAttribute("AFK") then "Du setzt aus" else "Du spielst mit",function() request:FireServer("AFK") task.delay(.3,render) end,"Umschalten")
        info("PC: E schubsen · Q Item · B Emotes · M Menü. Gamepad: X Aktion · R2 Item · Y Emotes. Mobile: Standard-Joystick + Sprung, zusätzliche Buttons rechts.",90)
    elseif current=="Emotes" then
        info("Emotes spielen in der Lobby. Bewegung beendet sie. Gesperrte Emotes öffnen den Shop.",48)
        local wheel=make("Frame",{Size=UDim2.new(1,-8,0,330),BackgroundTransparency=1},body)
        local emotes={} for _,p in Catalog.Products do if p.Category=="Emotes" then table.insert(emotes,p) end end
        for i,p in emotes do
            local a=(i-1)/#emotes*math.pi*2-math.pi/2
            local b=button(wheel,(if profile.Owned[p.Id] then "" else "🔒 ")..p.Name,function()
                if profile.Owned[p.Id] then request:FireServer("Emote",p.Id) overlay.Visible=false current=nil else selected=p.Id open("Detail") end
            end,if profile.Owned[p.Id] then palette.Accent else palette.Card)
            b.AnchorPoint=Vector2.new(.5,.5) b.Position=UDim2.new(.5+math.cos(a)*.34,0,.5+math.sin(a)*.4,0) b.Size=UDim2.new(.29,0,0,48) b.TextSize=12
        end
    elseif current=="Party" then
        info("Alle aktiven Spieler dieses Servers spielen dieselben Runden. Freunde können über Roblox beitreten; private Server werden unterstützt.",70)
        button(body,"ROBLOX-FREUNDE EINLADEN",function()
            local ok,can=pcall(Social.CanSendGameInviteAsync,Social,player)
            if ok and can then local worked=pcall(Social.PromptGameInvite,Social,player) if not worked then notify("Einladen ist hier gerade nicht verfügbar.") end
            else notify("Roblox-Einladungen sind in dieser Sitzung nicht verfügbar (z. B. Studio).") end
        end)
        if invitation then row("Einladung von "..invitation.Name,"30 Sekunden gültig",function() request:FireServer("AcceptParty",invitation.Id) invitation=nil end,"Annehmen") end
        for _,member in party.Members do row(member.Name,if party.Leader==member.Id then "Gruppenleiter" else "Party-Mitglied") end
        button(body,"GRUPPE VERLASSEN",function() request:FireServer("LeaveParty") end,palette.Card)
        for _,p in Players:GetPlayers() do if p~=player then row(p.DisplayName,"Auf diesem Server",function() request:FireServer("InviteParty",p.UserId) end,"Einladen") end end
    elseif current=="Voting" then
        info("Drei Spiele stehen zur Wahl. Du kannst deine Stimme bis zum Countdown-Ende ändern.",52)
        for _,id in round.Choices or {} do
            local gameInfo=Catalog.GameById[id]
            if gameInfo then voteButtons[id]=row(gameInfo.Name,gameInfo.Rules,function() request:FireServer("Vote",id) end,tostring((round.Votes or {})[id] or 0).." Stimmen") end
        end
    elseif current=="Admin" and isOwner then
        info("Servergeprüfte Owner-Aktionen. Test-Coins/Wins ändern echte Profile; Beträge können negativ sein. Maximal ±10.000 pro Aktion.",72)
        button(body,"RUNDE / COUNTDOWN STARTEN",function() request:FireServer("Admin",{Action="Start"}) end)
        button(body,"RUNDE OHNE WERTUNG BEENDEN",function() request:FireServer("Admin",{Action="End"}) end,palette.Pink)
        button(body,"SERVERSTATUS",function() request:FireServer("Admin",{Action="Status"}) end,palette.Card)
        local target=make("TextBox",{Size=UDim2.new(1,-8,0,48),Text=tostring(player.UserId),PlaceholderText="Roblox UserId des Zielspielers",ClearTextOnFocus=false,TextColor3=palette.Text,TextSize=16,BackgroundColor3=palette.Card,Font=Enum.Font.Gotham},body) roundCorners(target)
        local amount=make("TextBox",{Size=UDim2.new(1,-8,0,48),Text="100",PlaceholderText="Betrag",ClearTextOnFocus=false,TextColor3=palette.Text,TextSize=16,BackgroundColor3=palette.Card,Font=Enum.Font.Gotham},body) roundCorners(amount)
        for _,action in {"Coins","Wins","Teleport","Kick"} do button(body,action,function() request:FireServer("Admin",{Action=action,UserId=tonumber(target.Text),Amount=tonumber(amount.Text)}) end,palette.Card) end
        info("NÄCHSTES MINISPIEL",30)
        for _,g in Catalog.Games do button(body,g.Name,function() request:FireServer("Admin",{Action="SelectGame",Id=g.Id}) end,palette.Card) end
        info("CHAOS-EVENT IN AKTIVER RUNDE",30)
        for _,e in Catalog.Events do button(body,e.Name,function() request:FireServer("Admin",{Action="Event",Id=e.Id}) end,palette.Card) end
    end
end
open=function(name)
    current=name overlay.Visible=true render()
    if UIS.GamepadEnabled then GuiService.SelectedObject=close end
end
for _,entry in {{"▶ PLAY","Play"},{"PETS","Pets"},{"SHOP","Shop"},{"EMOTES","Emotes"},{"REWARDS","Rewards"},{"PROFILE","Profile"},{"ITEMS","Items"},{"PARTY","Party"},{"⚙","Settings"}} do
    local b=button(menu,entry[1],function() if entry[2]=="Play" then request:FireServer("Play") overlay.Visible=false current=nil else open(entry[2]) end end,if entry[2]=="Play" then palette.Accent else palette.Card)
    b.Size=UDim2.fromOffset(if entry[2]=="Settings" then 52 else 100,48)
end
local actionButton=button(gui,"SCHUBS",function() request:FireServer("Push") end,palette.Pink)
actionButton.AnchorPoint=Vector2.new(1,1) actionButton.Position=UDim2.new(1,-110,1,-95) actionButton.Size=UDim2.fromOffset(88,56)
local itemButton=button(gui,"ITEM",function() request:FireServer("UseItem") end,palette.Accent)
itemButton.AnchorPoint=Vector2.new(1,1) itemButton.Position=UDim2.new(1,-16,1,-190) itemButton.Size=UDim2.fromOffset(80,56)
local function bind(name,keys,callback)
    CAS:BindAction(name,function(_,inputState) if inputState==Enum.UserInputState.Begin and not UIS:GetFocusedTextBox() then callback() end return Enum.ContextActionResult.Pass end,false,table.unpack(keys))
end
bind("NeroPush",{Enum.KeyCode.E,Enum.KeyCode.ButtonX},function() request:FireServer("Push") end)
bind("NeroItem",{Enum.KeyCode.Q,Enum.KeyCode.ButtonR2},function() request:FireServer("UseItem") end)
bind("NeroEmotes",{Enum.KeyCode.B,Enum.KeyCode.ButtonY},function() open("Emotes") end)
bind("NeroMenu",{Enum.KeyCode.M},function() open("Settings") end)
UIS.JumpRequest:Connect(function() if player:GetAttribute("DoubleJump") then request:FireServer("DoubleJump") end end)
task.spawn(function()
    local module=player.PlayerScripts:WaitForChild("PlayerModule",15)
    if not module then return end
    local ok,controls=pcall(function() return require(module):GetControls() end)
    if not ok then return end
    Run:BindToRenderStep("NeroReverse",Enum.RenderPriority.Input.Value+1,function()
        if player:GetAttribute("Reverse") then
            local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            if h then h:Move(-controls:GetMoveVector(),true) end
        end
    end)
end)
state.OnClientEvent:Connect(function(kind,payload)
    if kind=="Profile" then
        profile=payload.Data sessionOnly=payload.SessionOnly
        local level=Rules.Level(profile.XP)
        stats.Text=string.format("COINS %d  ·  WINS %d  ·  LVL %d%s",profile.Coins,profile.Wins,level,if sessionOnly then " · STUDIO" else "")
        if level>lastLevel then notify("LEVEL UP! Du bist jetzt Level "..level) Effects.Sound("LevelUp") end lastLevel=level
        Effects.Configure(profile.Settings)
        if current and current~="Voting" and current~="Admin" then render() end
    elseif kind=="Round" then
        local oldPhase=round.Phase round=payload
        if round.Game~="Music" then Effects.Music(round.Phase~="Playing") end
        local seconds=round.Seconds or 0 timer.Text=string.format("%02d:%02d",math.floor(seconds/60),seconds%60)
        local g=Catalog.GameById[round.Game]
        phase.Text=(if g then g.Name else ({Waiting="WARTE AUF SPIELER",Intermission="NÄCHSTE RUNDE",Voting="ABSTIMMUNG",Results="ERGEBNIS"})[round.Phase] or "PARTY").." · "..tostring(round.Alive or 0).." aktiv"
        actionButton.Visible=round.Game=="Sumo" and player:GetAttribute("InRound")==true
        itemButton.Visible=not player:GetAttribute("InRound")
        if round.Phase=="Voting" and oldPhase~="Voting" then open("Voting")
        elseif oldPhase=="Voting" and round.Phase~="Voting" and current=="Voting" then overlay.Visible=false current=nil end
        for id,b in voteButtons do if b.Parent then b.Text=tostring((round.Votes or {})[id] or 0).." Stimmen" end end
        if oldPhase~=round.Phase and round.Message and round.Message~="" then notify(round.Message) end
        if seconds<=3 and seconds>0 then Effects.Sound("Countdown") end
    elseif kind=="Notice" then notify(payload)
    elseif kind=="Open" then open(payload)
    elseif kind=="Owner" then
        if payload and not isOwner then local b=button(menu,"OWNER",function() open("Admin") end,palette.Pink) b.Size=UDim2.fromOffset(100,48) end isOwner=payload
    elseif kind=="Party" then party=payload if current=="Party" then render() end
    elseif kind=="PartyInvite" then invitation=payload notify(payload.Name.." lädt dich in eine Gruppe ein. Öffne PARTY.") if current=="Party" then render() end
    elseif kind=="Spin" then
        local wheel=body:FindFirstChild("Disc",true)
        if wheel then Tween:Create(wheel,TweenInfo.new(2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Rotation=wheel.Rotation+1440+math.random(0,359)}):Play() end
        task.delay(2,function() notify("GLÜCKSRAD: "..(if type(payload)=="number" then payload.." COINS" else Catalog.ById[payload].Name)) Effects.Sound("Victory") end)
    elseif kind=="Music" then musicActive=payload Effects.Music(payload)
    elseif kind=="Target" then Effects.Target(payload)
    elseif kind=="Color" then
        local colors={Color3.fromRGB(255,91,129),Color3.fromRGB(62,216,224),Color3.fromRGB(255,210,80),Color3.fromRGB(155,112,255),Color3.fromRGB(103,231,151),Color3.fromRGB(255,153,79)}
        toast.BackgroundColor3=colors[payload] toast.TextColor3=palette.Background
        task.delay(5,function() toast.BackgroundColor3=palette.Panel toast.TextColor3=palette.Text end)
    end
end)
remotes.Effect.OnClientEvent:Connect(Effects.Handle)
player:GetAttributeChangedSignal("SaveWarning"):Connect(function() if player:GetAttribute("SaveWarning") then notify("Speichern verzögert. Der Server versucht es erneut.") end end)
request:FireServer("Hello")
