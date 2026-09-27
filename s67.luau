
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local window = Rayfield:CreateWindow({
    name = "thing i made",
    subtitle = "ok cool :)",
    sidebarLayout = true,
})

local tab = window:CreateTab({ name = "Main", icon = 93364949241311 })

local dick = tab:CreateToggle({
    name = "Auto Drink",
    flag = "AutoDrink",
    value = true,
    callback = function(value)
        while true do
        game.Players.LocalPlayer.Backpack.Drink.Parent = game.Players.LocalPlayer.Character
    task.wait(0.1)
        game:GetService("Players").LocalPlayer.Character:WaitForChild("Drink"):WaitForChild("Drink"):WaitForChild("Drink"):FireServer()
task.wait(0.3)
        end
    end,
})

dick:Set(true)

local j = tab:CreateToggle({
    name = "Auto Jump",
    flag = "AutoJump",
    value = false,
    callback = function(value)
        while true do 
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Jump"):FireServer()
task.wait(0.8)
        end
    end,
})

j:Set(true)
-- indow:Notify(%7B%0A%20%20%20%20title%20=%20%22Auto-saved%22,%0A%20%20%20%20content%20=%20%22Your%20configuration%20was%20saved.%22,
window:Notify({
    title = "Loaded",
    content = "offically loaded.",
    duration = 3,
})
-- game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Rebirth"):InvokeServer()
local eifk = tab:CreateToggle({
    name = "Auto Rebirth",
    flag = "AutoRebirth",
    value = true,
    callback = function(value)
while true do 
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Rebirth"):InvokeServer()
task.wait(2.5)
    end
    end,
})

eifk:Set(false)
local drinks = (
    Water, 0
    Bloxaide, 100
)