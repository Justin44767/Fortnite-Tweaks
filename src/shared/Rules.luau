-- Pure domain rules, shared with the offline Luau tests. No client can write a profile.
local Rules = {}
function Rules.Copy(value)
    if type(value)~="table" then return value end
    local result={} for k,v in value do result[k]=Rules.Copy(v) end return result
end
function Rules.NewProfile()
    return {Schema=1,Coins=0,Wins=0,XP=0,GamesPlayed=0,Survived=0,Playtime=0,
        Owned={Dance=true},Equipped={},Favorites={},Achievements={},QuestClaims={},
        Settings={Music=true,Effects=true,ReducedMotion=false,Quality="High"},
        DailyDay=-1,DailyStreak=0,SpinDay=-1,Receipts={},LevelRewards={}}
end
function Rules.Level(xp) return math.floor(math.sqrt(math.max(0,xp)/80))+1 end
function Rules.LevelXP(level) return (level-1)^2*80 end
function Rules.Day(timestamp) return math.floor(timestamp/86400) end
function Rules.Finite(n) return type(n)=="number" and n==n and math.abs(n)<1e12 end
function Rules.ValidProfile(data)
    if type(data)~="table" or data.Schema~=1 then return false end
    for _,k in {"Coins","Wins","XP","GamesPlayed","Survived","Playtime"} do
        if not Rules.Finite(data[k]) or data[k]<0 or data[k]%1~=0 then return false end
    end
    for _,k in {"Owned","Equipped","Favorites","Achievements","QuestClaims","Settings","Receipts","LevelRewards"} do
        if type(data[k])~="table" then return false end
    end
    for _,k in {"DailyDay","DailyStreak","SpinDay"} do if not Rules.Finite(data[k]) then return false end end
    return true
end
function Rules.Buy(data,product)
    if not product then return false,"Unbekannter Artikel." end
    if data.Owned[product.Id] then return false,"Bereits in deiner Sammlung." end
    if data.Coins<product.Price then return false,"Noch nicht genug Chaos Coins." end
    data.Coins-=product.Price data.Owned[product.Id]=true
    return true,"Gekauft: "..product.Name
end
function Rules.Daily(data,day,coins)
    if day<=data.DailyDay then return false,"Heute schon abgeholt (Reset 00:00 UTC)." end
    local streak=if day==data.DailyDay+1 then data.DailyStreak%7+1 else 1
    data.DailyDay=day data.DailyStreak=streak
    local amount=coins[streak]
    if streak==7 then
        if data.Owned.Crown then amount=150 else data.Owned.Crown=true end
    end
    data.Coins+=amount
    return true,if streak==7 and amount==0 then "Tag 7: Giant Crown!" else "Tag "..streak..": +"..amount.." Coins"
end
function Rules.Spin(data,day,roll)
    if day<=data.SpinDay then return false,"Heute schon gedreht (Reset 00:00 UTC)." end
    data.SpinDay=day
    local reward=if roll<=45 then 25 elseif roll<=75 then 50 elseif roll<=85 then "RainbowTrail" elseif roll<=93 then "Spin" else "DuckPet"
    if type(reward)=="number" then data.Coins+=reward
    elseif data.Owned[reward] then reward=75 data.Coins+=75
    else data.Owned[reward]=true end
    return true,reward
end
function Rules.RoundReward(data,receipt,survived,won)
    if table.find(data.Receipts,receipt) then return false end
    table.insert(data.Receipts,receipt)
    if #data.Receipts>64 then table.remove(data.Receipts,1) end
    data.GamesPlayed+=1 data.Coins+=5+(if survived then 15 else 0)+(if won then 30 else 0)
    data.XP+=20+(if survived then 15 else 0)+(if won then 40 else 0)
    if survived then data.Survived+=1 end
    if won then data.Wins+=1 end
    return true
end
function Rules.ProgressRewards(data,achievements)
    for _,a in achievements do
        if data[a.Field]>=a.Goal and not data.Achievements[a.Id] then
            data.Achievements[a.Id]=true data.Coins+=a.Coins
        end
    end
    for level,reward in {[5]=100,[10]="RainbowTrail",[20]="VictoryPose",[30]="DragonPet",[50]="Disco"} do
        local key=tostring(level)
        if Rules.Level(data.XP)>=level and not data.LevelRewards[key] then
            data.LevelRewards[key]=true
            if type(reward)=="number" then data.Coins+=reward else data.Owned[reward]=true end
        end
    end
end
function Rules.Quest(data,quest)
    if not quest then return false,"Unbekannte Quest." end
    if data.QuestClaims[quest.Id] then return false,"Schon abgeholt." end
    if data[quest.Field]<quest.Goal then return false,"Quest noch nicht geschafft." end
    data.QuestClaims[quest.Id]=true data.Coins+=quest.Coins return true,"+"..quest.Coins.." Coins"
end
function Rules.VoteWinner(choices,votes,tieIndex)
    local counts={} for _,id in choices do counts[id]=0 end
    for _,id in votes do if counts[id] then counts[id]+=1 end end
    local best=-1 local ties={}
    for _,id in choices do
        if counts[id]>best then best=counts[id] ties={id} elseif counts[id]==best then table.insert(ties,id) end
    end
    return ties[(tieIndex-1)%#ties+1],counts
end
function Rules.Winners(kind,alive,finished,scores,eligible)
    local result={}
    local function allowed(id) return eligible==nil or eligible[id]==true end
    if kind=="Race" then
        local best=math.huge for id,time in finished do if allowed(id) then best=math.min(best,time) end end
        for id,time in finished do if allowed(id) and time==best then result[id]=true end end
    elseif kind=="Score" then
        local best=0 for id,score in scores do if allowed(id) then best=math.max(best,score) end end
        for id,score in scores do if allowed(id) and score==best and best>0 then result[id]=true end end
    else for id,isAlive in alive do if allowed(id) and isAlive then result[id]=true end end end
    return result
end
return Rules
