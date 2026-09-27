
local thinkmonkeythink = Instance.new("ScreenGui")
thinkmonkeythink.Name = "thinkmonkeythink"
thinkmonkeythink.ResetOnSpawn = false
thinkmonkeythink.Parent = game.CoreGui

local topbar = Instance.new("Frame")
topbar.Name = "topbar"
topbar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
topbar.Position = UDim2.new(0.2665, 0, 0.2682, 0)
topbar.Size = UDim2.new(0.6365, 0, 0.1368, 0)
topbar.ZIndex = 0
topbar.Parent = thinkmonkeythink

local welcome = Instance.new("TextLabel")
welcome.Name = "welcome"
welcome.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
welcome.BackgroundTransparency = 1
welcome.Position = UDim2.new(-0.0797, 0, 0.0493, 0)
welcome.Size = UDim2.new(0.4483, 0, 0.2759, 0)
welcome.Text = "Welcome " .. game.Players.LocalPlayer.DisplayName .. "!"
welcome.TextColor3 = Color3.fromRGB(10, 135, 0)
welcome.TextSize = 18
welcome.Font = Enum.Font.Oswald
welcome.FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
welcome.Parent = topbar

local UIDragDetector = Instance.new("UIDragDetector")
UIDragDetector.Parent = topbar

local _i = Instance.new("TextLabel")
_i.Name = " i"
_i.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
_i.BackgroundTransparency = 1
_i.Position = UDim2.new(0.3458, 0, 0.0443, 0)
_i.Size = UDim2.new(0.3, 0, 0.266, 0)
_i.Text = "Kohls Admin House"
_i.TextColor3 = Color3.fromRGB(221, 221, 221)
_i.TextSize = 25
_i.Font = Enum.Font.Roboto
_i.FontFace = Font.new("rbxasset://fonts/families/Roboto.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
_i.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
_i.TextStrokeTransparency = 0
_i.Parent = topbar

local X = Instance.new("TextLabel")
X.Name = "X"
X.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
X.BackgroundTransparency = 1
X.Position = UDim2.new(0.6203, 0, 0.0049, 0)
X.Size = UDim2.new(0.1136, 0, 0.2217, 0)
X.Text = "X"
X.TextColor3 = Color3.fromRGB(255, 0, 0)
X.TextSize = 20
X.Font = Enum.Font.ArialBold
X.FontFace = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
X.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
X.TextStrokeTransparency = 0
X.Parent = topbar

local TextLabelslls = Instance.new("TextLabel")
TextLabelslls.Name = "TextLabelslls"
TextLabelslls.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
TextLabelslls.BackgroundTransparency = 1
TextLabelslls.Position = UDim2.new(0.2754, 0, 0.4039, 0)
TextLabelslls.Size = UDim2.new(0.4483, 0, 0.2759, 0)
TextLabelslls.Text = "by @iwiwk91812"
TextLabelslls.TextColor3 = Color3.fromRGB(36, 189, 255)
TextLabelslls.TextSize = 14
TextLabelslls.Font = Enum.Font.Fantasy
TextLabelslls.FontFace = Font.new("rbxasset://fonts/families/Balthazar.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
TextLabelslls.Parent = topbar

local divider_ = Instance.new("Frame")
divider_.Name = "divider "
divider_.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
divider_.BorderColor3 = Color3.fromRGB(71, 71, 71)
divider_.Position = UDim2.new(0.0008, 0, 1, 0)
divider_.Size = UDim2.new(0.9992, 0, 0.0197, 0)
divider_.ZIndex = 1000
divider_.Parent = topbar

local bottom_bar = Instance.new("Frame")
bottom_bar.Name = "bottom bar"
bottom_bar.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
bottom_bar.Position = UDim2.new(-0.0025, 0, 1.0049, 0)
bottom_bar.Size = UDim2.new(1.0025, 0, 3.1823, 0)
bottom_bar.ZIndex = 0
bottom_bar.Parent = topbar

local Auto = Instance.new("TextButton")
Auto.Name = "Auto"
Auto.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
Auto.BackgroundTransparency = 1
Auto.Position = UDim2.new(0.5672, 0, 0.4876, 0)
Auto.Size = UDim2.new(0.4218, 0, 0.2198, 0)
Auto.Text = "Auto Admin"
Auto.TextColor3 = Color3.fromRGB(0, 255, 0)
Auto.TextSize = 24
Auto.Font = Enum.Font.GothamBlack
Auto.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
Auto.Parent = bottom_bar
Auto.MouseButton1Click:Connect(function(anaa)

	local pad = workspace.Terrain._Game.Admin.Pads:GetChildren()[5]
local isadmin = false
while true do
if pad.Head.BrickColor == BrickColor.new("Dark green") and isadmin == false then
while true do
firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, pad.Head, 0)
task.wait(0.4)
end
elseif pad.Head.BrickColor == BrickColor.new("Bright Red") then
isadmin = true
end
task.wait(0.3)
end
end)
local dov = Instance.new("Frame")
dov.Name = "dov"
dov.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
dov.BorderColor3 = Color3.fromRGB(77, 77, 77)
dov.BorderSizePixel = 3
dov.Position = UDim2.new(0.2189, 0, 0.0062, 0)
dov.Size = UDim2.new(-0.0178, 0, 0.9892, 0)
dov.ZIndex = 999
dov.Parent = bottom_bar

local Frame = Instance.new("Frame")
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BorderColor3 = Color3.fromRGB(127, 127, 127)
Frame.Position = UDim2.new(0.0008, 0, 0.1424, 0)
Frame.Size = UDim2.new(0.1953, 0, 0.0464, 0)
Frame.ZIndex = 999
Frame.Parent = bottom_bar

local basep = Instance.new("TextButton")
basep.Name = "basep"
basep.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
basep.BackgroundTransparency = 1
basep.Position = UDim2.new(0.574, 0, 0.1533, 0)
basep.Size = UDim2.new(0.4184, 0, 0.2291, 0)
basep.Text = "No Obby Kill"
basep.TextColor3 = Color3.fromRGB(255, 0, 0)
basep.TextSize = 24
basep.Font = Enum.Font.GothamBlack
basep.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
basep.Parent = bottom_bar
basep.MouseButton1Click:Connect(function(ana)
	for i, v in pairs(workspace.Tabby.Admin_House.Obby:GetChildren()) do
		v.CanTouch = false
	end
end)
local basess = Instance.new("TextButton")
basess.Name = "basess"
basess.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
basess.BackgroundTransparency = 1
basess.Position = UDim2.new(0.5714, 0, 0.3251, 0)
basess.Size = UDim2.new(0.4218, 0, 0.2198, 0)
basess.Text = "Regen"
basess.TextColor3 = Color3.fromRGB(255, 255, 0)
basess.TextSize = 24
basess.Font = Enum.Font.GothamBlack
basess.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
basess.Parent = bottom_bar
basess.MouseButton1Click:Connect(function(shah)
	fireclickdetector(workspace.Terrain._Game.Admin.Regen.ClickDetector)
end)
local home = Instance.new("TextLabel")
home.Name = "home"
home.BackgroundColor3 = Color3.fromRGB(33, 73, 255)
home.BackgroundTransparency = 1
home.Position = UDim2.new(0, 0, -0.017, 0)
home.Size = UDim2.new(0.2071, 0, 0.1889, 0)
home.Text = "Home"
home.TextColor3 = Color3.fromRGB(255, 0, 0)
home.TextSize = 28
home.Font = Enum.Font.Jura
home.FontFace = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
home.Parent = bottom_bar

local base = Instance.new("TextButton")
base.Name = "base"
base.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
base.BackgroundTransparency = 1
base.Position = UDim2.new(0.5647, 0, -0.0015, 0)
base.Size = UDim2.new(0.4218, 0, 0.2198, 0)
base.Text = "TP To House"
base.TextColor3 = Color3.fromRGB(1, 170, 27)
base.TextSize = 24
base.Font = Enum.Font.GothamBlack
base.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
base.Parent = bottom_bar
base.MouseButton1Click:Connect(function(hut)
	game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = workspace.Terrain._Game.Admin.Regen.CFrame
end)
local scropt = Instance.new("TextLabel")
scropt.Name = "scropt"
scropt.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
scropt.BackgroundTransparency = 1
scropt.Position = UDim2.new(0.322, 0, 0.2611, 0)
scropt.Size = UDim2.new(0.3364, 0, 0.2167, 0)
scropt.Text = "script"
scropt.TextColor3 = Color3.fromRGB(255, 255, 255)
scropt.TextSize = 10
scropt.Parent = topbar
