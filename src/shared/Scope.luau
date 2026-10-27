local Scope={} Scope.__index=Scope
function Scope.new() return setmetatable({Alive=true,Tasks={}},Scope) end
function Scope:Add(value)
    if not self.Alive then
        if typeof(value)=="RBXScriptConnection" then value:Disconnect()
        elseif typeof(value)=="Instance" then value:Destroy()
        elseif type(value)=="function" then value() end
    else table.insert(self.Tasks,value) end
    return value
end
function Scope:Delay(seconds,callback)
    task.delay(seconds,function() if self.Alive then callback() end end)
end
function Scope:Property(object,key,value)
    local previous=object[key] object[key]=value
    self:Add(function() if object.Parent then object[key]=previous end end)
end
function Scope:Clean()
    if not self.Alive then return end self.Alive=false
    for i=#self.Tasks,1,-1 do
        local v=self.Tasks[i]
        local ok,err=pcall(function()
            if typeof(v)=="RBXScriptConnection" then v:Disconnect()
            elseif typeof(v)=="Instance" then v:Destroy()
            elseif type(v)=="function" then v() end
        end)
        if not ok then warn("NERO cleanup:",err) end
    end
    table.clear(self.Tasks)
end
return Scope
