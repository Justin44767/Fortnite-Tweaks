local Players=game:GetService("Players")
local Party={} Party.__index=Party
function Party.new(state) return setmetatable({Leaders={},Invites={},Remote=state},Party) end
function Party:Update()
    for _,p in Players:GetPlayers() do
        local leader=self.Leaders[p.UserId] or p.UserId local members={}
        for _,other in Players:GetPlayers() do
            if (self.Leaders[other.UserId] or other.UserId)==leader then table.insert(members,{Id=other.UserId,Name=other.DisplayName}) end
        end
        self.Remote:FireClient(p,"Party",{Leader=leader,Members=members})
    end
end
function Party:Request(player,action,targetId)
    if action=="LeaveParty" then
        if self.Leaders[player.UserId]==player.UserId then
            for id,leader in self.Leaders do if leader==player.UserId then self.Leaders[id]=nil end end
        else self.Leaders[player.UserId]=nil end
        self:Update() return true,"Gruppe verlassen."
    end
    if type(targetId)~="number" then return false,"Ungültiger Spieler." end
    local target=Players:GetPlayerByUserId(targetId) if not target or target==player then return false,"Spieler nicht verfügbar." end
    if action=="InviteParty" then
        local leader=self.Leaders[player.UserId] or player.UserId
        if leader~=player.UserId then return false,"Nur der Gruppenleiter lädt ein." end
        self.Invites[targetId]={Leader=leader,Until=os.clock()+30}
        self.Remote:FireClient(target,"PartyInvite",{Id=player.UserId,Name=player.DisplayName})
        return true,"Einladung gesendet."
    elseif action=="AcceptParty" then
        local invite=self.Invites[player.UserId]
        if not invite or invite.Leader~=targetId or invite.Until<os.clock() then return false,"Einladung abgelaufen." end
        if self.Leaders[player.UserId] and self.Leaders[player.UserId]~=player.UserId then return false,"Verlasse zuerst deine andere Gruppe." end
        for id,leader in self.Leaders do if leader==player.UserId then self.Leaders[id]=nil end end
        self.Leaders[targetId]=targetId self.Leaders[player.UserId]=targetId self.Invites[player.UserId]=nil
        self:Update() return true,"Gruppe beigetreten. Alle spielen auf diesem Server gemeinsam."
    end
    return false,"Unbekannte Gruppenaktion."
end
function Party:Remove(player)
    for id,leader in self.Leaders do if id==player.UserId or leader==player.UserId then self.Leaders[id]=nil end end
    self.Invites[player.UserId]=nil self:Update()
end
return Party
