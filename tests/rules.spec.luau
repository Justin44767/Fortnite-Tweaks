local Rules=require("../src/shared/Rules")
local Catalog=require("../src/shared/Catalog")
local count=0
local function test(name,fn) fn() count+=1 print("PASS "..name) end
local function equal(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
test("new profile schema and independent collections",function()
    local a,b=Rules.NewProfile(),Rules.NewProfile() assert(Rules.ValidProfile(a)) a.Owned.DuckPet=true assert(not b.Owned.DuckPet)
end)
test("corrupt profiles are refused",function()
    for _,field in {"Coins","Wins","XP","GamesPlayed","Survived","Playtime"} do
        for _,bad in {-1,.5,math.huge,0/0,"42"} do local p=Rules.NewProfile() p[field]=bad assert(not Rules.ValidProfile(p)) end
    end
    assert(not Rules.ValidProfile({Schema=2})) assert(not Rules.ValidProfile(nil))
end)
test("shop rejects unaffordable, unknown and duplicate purchases",function()
    local p=Rules.NewProfile() assert(not Rules.Buy(p,Catalog.ById.DuckPet)) equal(p.Coins,0)
    p.Coins=100 assert(Rules.Buy(p,Catalog.ById.DuckPet)) equal(p.Coins,0) assert(p.Owned.DuckPet)
    assert(not Rules.Buy(p,Catalog.ById.DuckPet)) assert(not Rules.Buy(p,nil)) equal(p.Coins,0)
end)
test("seven daily days, streak reset, duplicate and backwards clock",function()
    local p=Rules.NewProfile()
    for day=100,106 do assert(Rules.Daily(p,day,Catalog.DailyCoins)) assert(not Rules.Daily(p,day,Catalog.DailyCoins)) end
    equal(p.Coins,600) equal(p.DailyStreak,7) assert(p.Owned.Crown)
    assert(not Rules.Daily(p,105,Catalog.DailyCoins)) assert(Rules.Daily(p,107,Catalog.DailyCoins)) equal(p.DailyStreak,1)
    assert(Rules.Daily(p,110,Catalog.DailyCoins)) equal(p.DailyStreak,1)
end)
test("daily duplicate cosmetic compensates once",function()
    local p=Rules.NewProfile() p.Owned.Crown=true p.DailyDay=5 p.DailyStreak=6
    assert(Rules.Daily(p,6,Catalog.DailyCoins)) equal(p.Coins,150) assert(not Rules.Daily(p,6,Catalog.DailyCoins))
end)
test("wheel distribution, duplicate compensation and idempotence",function()
    local counts={}
    for roll=1,100 do
        local p=Rules.NewProfile() local ok,reward=Rules.Spin(p,1,roll) assert(ok)
        counts[reward]=(counts[reward] or 0)+1 assert(not Rules.Spin(p,1,roll)) assert(not Rules.Spin(p,0,roll))
    end
    equal(counts[25],45) equal(counts[50],30) equal(counts.RainbowTrail,10) equal(counts.Spin,8) equal(counts.DuckPet,7)
    local p=Rules.NewProfile() p.Owned.DuckPet=true local _,reward=Rules.Spin(p,1,100) equal(reward,75) equal(p.Coins,75)
end)
test("round grants participation, survival and win rewards only once",function()
    local p=Rules.NewProfile() assert(Rules.RoundReward(p,"a",false,false)) equal(p.Coins,5) equal(p.XP,20)
    assert(Rules.RoundReward(p,"b",true,false)) equal(p.Coins,25) equal(p.Survived,1)
    assert(Rules.RoundReward(p,"c",true,true)) equal(p.Coins,75) equal(p.Wins,1) equal(p.GamesPlayed,3)
    assert(not Rules.RoundReward(p,"c",true,true)) equal(p.Coins,75)
end)
test("bounded receipt history avoids unbounded profile growth",function()
    local p=Rules.NewProfile() for i=1,1000 do Rules.RoundReward(p,tostring(i),false,false) end
    equal(#p.Receipts,64) equal(p.GamesPlayed,1000) assert(not Rules.RoundReward(p,"1000",true,true))
end)
test("quest prerequisites and duplicate rejection",function()
    local p=Rules.NewProfile() local q=Catalog.Quests[1]
    assert(not Rules.Quest(p,q)) p.GamesPlayed=3 assert(Rules.Quest(p,q)) equal(p.Coins,50)
    assert(not Rules.Quest(p,q)) assert(not Rules.Quest(p,nil))
end)
test("achievements and milestone rewards are idempotent",function()
    local p=Rules.NewProfile() p.Wins=20 p.GamesPlayed=25 p.XP=Rules.LevelXP(50)
    Rules.ProgressRewards(p,Catalog.Achievements) equal(p.Coins,420)
    assert(p.Owned.RainbowTrail and p.Owned.VictoryPose and p.Owned.DragonPet and p.Owned.Disco)
    Rules.ProgressRewards(p,Catalog.Achievements) equal(p.Coins,420)
end)
test("XP thresholds",function() for level=1,100 do equal(Rules.Level(Rules.LevelXP(level)),level) equal(Rules.Level(Rules.LevelXP(level+1)-1),level) end end)
test("voting counts only offered choices; changing votes and ties",function()
    local choices={"Lava","Color","TNT"} local votes={[1]="Lava",[2]="Lava",[3]="unknown"}
    local winner,counts=Rules.VoteWinner(choices,votes,1) equal(winner,"Lava") equal(counts.Lava,2)
    votes[2]="Color" equal(Rules.VoteWinner(choices,votes,2),"Color")
    equal(Rules.VoteWinner(choices,{},3),"TNT")
end)
test("survival excludes eliminated and disconnected players",function()
    local winners=Rules.Winners("Survival",{[1]=true,[2]=false,[3]=false},{},{}) assert(winners[1] and not winners[2] and not winners[3])
end)
test("race rewards first finisher, explicit tie, no phantom winners",function()
    local a=Rules.Winners("Race",{},{[1]=5000,[2]=6000,[3]=5000},{}) assert(a[1] and a[3] and not a[2]) assert(next(Rules.Winners("Race",{},{},{}))==nil)
end)
test("ring scores support ties and zero-score rounds",function()
    local a=Rules.Winners("Score",{},{},{[1]=4,[2]=4,[3]=2}) assert(a[1] and a[2] and not a[3]) assert(next(Rules.Winners("Score",{},{},{[1]=0}))==nil)
end)
test("disconnected leaders cannot block present race or score winners",function()
    local present={[2]=true}
    local scores=Rules.Winners("Score",{},{},{[1]=9,[2]=3},present) assert(scores[2] and not scores[1])
    local race=Rules.Winners("Race",{},{[1]=1000,[2]=2000},{},present) assert(race[2] and not race[1])
end)
test("catalog completeness and no duplicate product IDs",function()
    equal(#Catalog.Games,15) equal(#Catalog.Events,25) equal(#Catalog.Items,10)
    local seen={} local pets,emotes=0,0
    for _,p in Catalog.Products do assert(not seen[p.Id]) seen[p.Id]=true assert(p.Price>=0 and p.Price%1==0)
        if p.Category=="Pets" then pets+=1 elseif p.Category=="Emotes" then emotes+=1 end
    end
    equal(pets,9) equal(emotes,10)
    for _,g in Catalog.Games do assert(g.Duration>=60 and g.Duration<=150) end
end)
test("copying snapshots does not alias mutable data",function()
    local p=Rules.NewProfile() local copy=Rules.Copy(p) copy.Settings.Music=false copy.Owned.GhostPet=true
    assert(p.Settings.Music and not p.Owned.GhostPet)
end)
test("long reward/purchase sequence preserves nonnegative integer balances",function()
    local p=Rules.NewProfile()
    for i=1,2000 do
        Rules.RoundReward(p,tostring(i),i%2==0,i%5==0)
        Rules.Buy(p,Catalog.Products[(i-1)%#Catalog.Products+1])
        Rules.ProgressRewards(p,Catalog.Achievements)
        assert(Rules.ValidProfile(p))
    end
end)
print("Rules tests:",count)
