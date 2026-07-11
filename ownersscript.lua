-- ============================================
-- KHOLS ADMIN – OWNER VERSION
-- (Includes exclusive "Owner" tab)
-- ============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Khols Admin GUI",
   Icon = 0,
   LoadingTitle = "Khols Admin",
   LoadingSubtitle = "by gamprogamer99",
   Theme = "Default",
   ToggleUIKeybind = "K",
   ConfigurationSaving = { Enabled = true, FolderName = "KholsAdmin", FileName = "Settings" },
   KeySystem = true,
   KeySettings = { Title = "Khols Admin", Subtitle = "Enter Key", Note = "", FileName = "KholsKey", SaveKey = true, GrabKeyFromSite = false, Key = {"Myactive"} }
})

-- Tabs
local CommandsTab = Window:CreateTab("Commands", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local OwnerTab = Window:CreateTab("Owner", 4483362458)   -- exclusive owner tab

-- ===== Owner Exclusive Button =====
OwnerTab:CreateButton({
   Name = "Owner Only Command",
   Callback = function()
      local ChatEvent = game:GetService("ReplicatedStorage"):WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
      ChatEvent:FireServer("Owner command executed!", "System")
      print("[Owner] Executed owner-only command.")
   end
})

-- ===== Everything else is identical to the normal version =====
-- (Insert the full public script here – the one you already have)
-- For brevity, we link to the public version's logic.
-- But to avoid duplication, you can `loadstring` the public script inside the owner version,
-- or copy the entire public script below.

-- Since we want a single standalone owner script, copy all the code from the normal version
-- (the one that works) and paste it here, then add the Owner tab section above.

-- ===== COPY THE FULL PUBLIC SCRIPT BELOW THIS LINE =====
