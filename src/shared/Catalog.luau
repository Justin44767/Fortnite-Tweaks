local Catalog = {}
Catalog.Games = {
    {Id="Lava", Name="THE FLOOR IS LAVA", Rules="Steige höher! Die Lava steigt, gelbe Plattformen verschwinden.", Duration=90, Kind="Survival"},
    {Id="Bananas", Name="GIANT BANANA ATTACK", Rules="Weiche den gelben Warnkreisen und fallenden Bananen aus!", Duration=75, Kind="Survival"},
    {Id="Button", Name="DON'T PRESS THE BUTTON", Rules="Überlebe! Der rote Knopf löst Chaos aus. Drücken auf eigene Gefahr.", Duration=75, Kind="Survival"},
    {Id="Duck", Name="ESCAPE THE GIANT DUCK", Rules="Die Ente kommt! Laufe um die Mauern zum grünen Ausgang.", Duration=90, Kind="Race"},
    {Id="Ice", Name="SLIPPERY FLOOR", Rules="Bleibe auf dem Eis. Böen und Schneebälle schubsen dich herunter.", Duration=75, Kind="Survival"},
    {Id="Disasters", Name="RANDOM DISASTERS", Rules="Nutze die Türme als Schutz vor Flut, Meteoren und Tornados.", Duration=105, Kind="Survival"},
    {Id="Music", Name="MUSICAL PLATFORMS", Rules="Wenn die Musik stoppt: sofort auf ein grün leuchtendes Feld!", Duration=90, Kind="Survival"},
    {Id="Race", Name="CRAZY RACE", Rules="Überwinde Balken, Sprungfedern und bewegliche Plattformen. Erreiche das Ziel!", Duration=120, Kind="Race"},
    {Id="Potato", Name="HOT POTATO", Rules="Berühre andere, um die Kartoffel weiterzugeben. Bei 0 scheidet ihr Träger aus!", Duration=90, Kind="Survival"},
    {Id="Heads", Name="GIANT HEAD MODE", Rules="Balanciere mit Riesenkopf über den Parcours bis zum grünen Ziel.", Duration=120, Kind="Race"},
    {Id="Color", Name="COLOR PANIC", Rules="Merke dir die angesagte Farbe und laufe rechtzeitig auf ihr Feld!", Duration=90, Kind="Survival"},
    {Id="TNT", Name="TNT RUN", Rules="Bleib in Bewegung! Betretene Felder verschwinden nach kurzer Zeit.", Duration=90, Kind="Survival"},
    {Id="Flying", Name="FLYING CHAOS", Rules="Springe durch goldene Ringe! Zehn Ringe gewinnen, sonst zählt der höchste Punktestand.", Duration=90, Kind="Score"},
    {Id="Sumo", Name="SUMO PUSH", Rules="Schubse mit E / Aktion / X andere aus dem Ring. Jeder Schubs hat eine Pause!", Duration=75, Kind="Survival"},
    {Id="Doors", Name="THE WRONG DOOR", Rules="Finde in jeder Reihe eine sichere Tür. Falsche Türen werfen dich zurück!", Duration=120, Kind="Race"},
}
Catalog.Events = {
    {Id="GiantHead",Name="RIESENKÖPFE"}, {Id="Tiny",Name="MINI-PARTY"},
    {Id="Gravity",Name="MONDSPAZIERGANG"}, {Id="Speed",Name="TURBO"},
    {Id="BananaRain",Name="BANANENREGEN"}, {Id="DuckRain",Name="ENTENREGEN"},
    {Id="Tornado",Name="TORNADO"}, {Id="Ragdoll",Name="WACKELPUDDING"},
    {Id="Slippery",Name="GLATTEIS"}, {Id="BeachBall",Name="RIESEN-STRANDBALL"},
    {Id="Reverse",Name="RÜCKWÄRTSGANG"}, {Id="Bounce",Name="HÜPFPARTY"},
    {Id="Teleport",Name="PLATZTAUSCH"}, {Id="Invisible",Name="GEISTERBODEN"},
    {Id="Rainbow",Name="REGENBOGENNEBEL"}, {Id="GiantNPC",Name="RIESEN-ROBOTER"},
    {Id="Meteors",Name="METEORREGEN"}, {Id="Jump",Name="ALLE HÜPFEN"},
    {Id="Camera",Name="WACKELKAMERA"}, {Id="Furniture",Name="FLIEGENDE SOFAS"},
    {Id="Chickens",Name="HÜHNER-INVASION"}, {Id="Confetti",Name="FARBEXPLOSION"},
    {Id="Walls",Name="WANDALARM"}, {Id="Rocket",Name="RAKETENSTART"},
    {Id="DoubleJump",Name="DOPPELSPRUNG"},
}
Catalog.Products = {
    {Id="DuckPet",Name="Mini Duck",Category="Pets",Price=100,Model="Duck",Color={255,215,65}},
    {Id="BananaPet",Name="Banana Pet",Category="Pets",Price=140,Model="Banana",Color={255,228,50}},
    {Id="DragonPet",Name="Mini Dragon",Category="Pets",Price=250,Model="Dragon",Color={170,115,255}},
    {Id="CatPet",Name="Rainbow Cat",Category="Pets",Price=200,Model="Cat",Color={255,110,190}},
    {Id="ChickenPet",Name="Dancing Chicken",Category="Pets",Price=150,Model="Chicken",Color={255,245,215}},
    {Id="GhostPet",Name="Ghost",Category="Pets",Price=180,Model="Ghost",Color={200,235,255}},
    {Id="RobotPet",Name="Robot",Category="Pets",Price=220,Model="Robot",Color={100,220,235}},
    {Id="DonutPet",Name="Flying Donut",Category="Pets",Price=250,Model="Donut",Color={255,140,180}},
    {Id="DinoPet",Name="Mini Dinosaur",Category="Pets",Price=300,Model="Dino",Color={120,225,125}},
    {Id="RainbowTrail",Name="Rainbow Trail",Category="Trails",Price=120,Color={255,120,230}},
    {Id="StarTrail",Name="Sternenschweif",Category="Trails",Price=180,Color={255,220,100}},
    {Id="BananaHat",Name="Banana Hat",Category="Hats",Price=100,Model="Banana",Color={255,220,40}},
    {Id="Crown",Name="Giant Crown",Category="Hats",Price=300,Model="Crown",Color={255,195,55}},
    {Id="Wings",Name="Angel Wings",Category="Wings",Price=250,Model="Wings",Color={235,245,255}},
    {Id="ChickenSuit",Name="Chicken Costume",Category="Costumes",Price=250,Model="Chicken",Color={255,245,215}},
    {Id="Disco",Name="Disco Aura",Category="Auras",Price=150,Color={180,110,255}},
    {Id="Stars",Name="Sternen-Ragdoll",Category="Ragdoll",Price=100,Color={255,220,70}},
    {Id="ConfettiWin",Name="Confetti Victory",Category="Victory",Price=200,Color={255,110,200}},
    {Id="Dance",Name="Dance",Category="Emotes",Price=0},
    {Id="Backflip",Name="Backflip",Category="Emotes",Price=60},
    {Id="Spin",Name="Spin",Category="Emotes",Price=60},
    {Id="Laugh",Name="Laugh",Category="Emotes",Price=40},
    {Id="Cry",Name="Cry",Category="Emotes",Price=40},
    {Id="ChickenDance",Name="Chicken Dance",Category="Emotes",Price=80},
    {Id="RobotDance",Name="Robot Dance",Category="Emotes",Price=80},
    {Id="BananaDance",Name="Banana Dance",Category="Emotes",Price=80},
    {Id="VictoryPose",Name="Victory Pose",Category="Emotes",Price=80},
    {Id="CrazyJump",Name="Crazy Jump",Category="Emotes",Price=80},
}
Catalog.Items = {
    {Id="Peel",Name="Banana Peel",Model="Banana",Sound="Fall",Cooldown=4},
    {Id="Hammer",Name="Giant Hammer",Model="Hammer",Sound="Bounce",Cooldown=4},
    {Id="Chicken",Name="Rubber Chicken",Model="Chicken",Sound="Chicken",Cooldown=3},
    {Id="Water",Name="Water Blaster",Model="Blaster",Sound="Explosion",Cooldown=2},
    {Id="Confetti",Name="Confetti Cannon",Model="Cannon",Sound="Victory",Cooldown=3},
    {Id="Boots",Name="Spring Boots",Model="Boot",Sound="Bounce",Cooldown=4},
    {Id="Bubble",Name="Bubble Gun",Model="Blaster",Sound="Bounce",Cooldown=3},
    {Id="Rocket",Name="Toy Rocket",Model="Rocket",Sound="Horn",Cooldown=5},
    {Id="Horn",Name="Party Horn",Model="Horn",Sound="Horn",Cooldown=3},
    {Id="Ball",Name="Giant Beach Ball",Model="Ball",Sound="Bounce",Cooldown=5},
}
Catalog.ById, Catalog.GameById, Catalog.EventById, Catalog.ItemById = {}, {}, {}, {}
for _,v in Catalog.Products do Catalog.ById[v.Id]=v end
for _,v in Catalog.Games do Catalog.GameById[v.Id]=v end
for _,v in Catalog.Events do Catalog.EventById[v.Id]=v end
for _,v in Catalog.Items do Catalog.ItemById[v.Id]=v end
Catalog.DailyCoins = {25,50,75,100,150,200,0}
Catalog.Quests = {
    {Id="Play3",Name="Spiele 3 Runden",Field="GamesPlayed",Goal=3,Coins=50},
    {Id="Survive5",Name="Überlebe 5 Runden",Field="Survived",Goal=5,Coins=80},
    {Id="Win3",Name="Gewinne 3 Runden",Field="Wins",Goal=3,Coins=100},
}
Catalog.Achievements = {
    {Id="FirstWin",Name="Erster Sieg",Field="Wins",Goal=1,Coins=20},
    {Id="PartyRegular",Name="Partygast",Field="GamesPlayed",Goal=25,Coins=100},
    {Id="Champion",Name="Chaos-Champion",Field="Wins",Goal=20,Coins=200},
}
return Catalog
