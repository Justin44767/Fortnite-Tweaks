local InterfaceRoot={}

function InterfaceRoot.Create(playerGui)
    -- StarterGui may be cloned after StarterPlayerScripts starts, or on respawn.
    -- Keep the world visible even when updating scripts in an older place file.
    local previous=playerGui:FindFirstChild("NeroInterface")
    if previous and previous:IsA("ScreenGui") then previous:Destroy() end

    local gui=Instance.new("ScreenGui")
    gui.Name="NeroInterface"
    gui.ResetOnSpawn=false
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder=10

    local function removeLegacyLoading(child)
        if child.Name=="Loading" and child:IsA("ScreenGui") then
            child.Enabled=false
            child:Destroy()
        end
    end

    -- Subscribe before scanning: neither existing nor later copies can be missed.
    local added=playerGui.ChildAdded:Connect(removeLegacyLoading)
    gui.Destroying:Connect(function() added:Disconnect() end)
    for _,child in playerGui:GetChildren() do removeLegacyLoading(child) end
    gui.Parent=playerGui
    return gui
end

return InterfaceRoot
