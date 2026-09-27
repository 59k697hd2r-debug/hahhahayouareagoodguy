local plr = game.Players.LocalPlayer
local sys = game.TextChatService.TextChannels.RBXSystem -- (you can also use RBXGeneral)
local t = game:GetService("TextChatService")
local w = workspace
t.SendingMessage:Connect(function(h)
    while true do
    if h.Text:lower() == ".perm" then
        while true do 
            firetouchinterest(plr.Character.HumanoidRootPart, workspace.Terrain._Game.Admin.Pads:WaitForChild("Touch to get admin").Head, 0)
            break 
            task.wait(0.01)
        end

    elseif h.Text:lower() == ".nokd" then
        for i, v in  pairs(w.Tabby.Admin_House.Obby:GetChildren()) do
            v.CanTouch = false
        end
    elseif h.Text:lower() == ".nolgs" then
        for i = 1, 300 do
sys:SendAsync("HAHHAHAHAHAHAHAHAHHAH")
task.wait(0.1)
        end
        task.wait(0.1)
    end
end)
print("executed")