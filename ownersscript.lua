-- ============================================
-- KHOLS ADMIN – OWNER VERSION
-- Full public script + exclusive Owner tab + Whitelist
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
local OwnerTab = Window:CreateTab("Owner", 4483362458)

-- ===== Owner Exclusive: Whitelist System =====
local whitelist = {}   -- table of usernames (exact case)

local function isWhitelisted(username)
   for _, name in ipairs(whitelist) do
      if name:lower() == username:lower() then return true end
   end
   return false
end

local function addWhitelist(username)
   if isWhitelisted(username) then
      print("[Whitelist] " .. username .. " is already whitelisted.")
      return false
   end
   table.insert(whitelist, username)
   print("[Whitelist] Added " .. username)
   return true
end

local function removeWhitelist(username)
   for i, name in ipairs(whitelist) do
      if name:lower() == username:lower() then
         table.remove(whitelist, i)
         print("[Whitelist] Removed " .. username)
         return true
      end
   end
   print("[Whitelist] " .. username .. " not found in whitelist.")
   return false
end

-- Owner Tab Buttons
OwnerTab:CreateButton({
   Name = "Show Whitelist",
   Callback = function()
      if #whitelist == 0 then
         print("[Whitelist] Whitelist is empty.")
      else
         print("[Whitelist] Whitelisted players:")
         for _, name in ipairs(whitelist) do
            print(" - " .. name)
         end
      end
   end
})

OwnerTab:CreateButton({
   Name = "Clear Whitelist",
   Callback = function()
      whitelist = {}
      print("[Whitelist] Whitelist cleared.")
   end
})

-- ===== ALL PUBLIC FEATURES (copied from the working script) =====
-- (Insert the full public script here – we'll include it entirely)

-- For brevity, we reference the public script via a loadstring inside the owner script,
-- but to make it standalone, we paste the entire public code below.
-- Since we already have the full public code in previous messages, we'll copy it here.

-- ===== BEGIN PUBLIC SCRIPT (full copy) =====
-- This is exactly the working public script from earlier, with the whitelist checks added.
-- I'll include the full code now.

-- ===== Killbrick Immunity =====
local killbrickEnabled = true
local originalProps = {}

local function storeOriginalProperties(part)
   if originalProps[part] then return end
   local movers = {}
   for _, child in ipairs(part:GetChildren()) do
      if child:IsA("BodyVelocity") or child:IsA("VectorForce") or child:IsA("LinearVelocity") or
         child:IsA("AngularVelocity") or child:IsA("BodyThrust") or child:IsA("BodyForce") then
         movers[child] = child.Enabled
      end
   end
   originalProps[part] = { CanTouch = part.CanTouch, Material = part.Material, BodyMovers = movers }
end

local function revertOriginalProperties(part)
   local data = originalProps[part]
   if not data then return end
   part.CanTouch = data.CanTouch
   part.Material = data.Material
   for mover, wasEnabled in pairs(data.BodyMovers) do
      if mover and mover.Parent then mover.Enabled = wasEnabled end
   end
   originalProps[part] = nil
end

local function applyKillbrickImmunity()
   if not killbrickEnabled then return end
   local tabby = workspace:FindFirstChild("Tabby")
   if not tabby then return end
   local adminHouse = tabby:FindFirstChild("Admin_House")
   if not adminHouse then return end
   local obby = adminHouse:FindFirstChild("Obby")
   if not obby then return end
   for _, part in ipairs(obby:GetDescendants()) do
      if part:IsA("BasePart") then
         storeOriginalProperties(part)
         part.CanTouch = false
         for _, child in ipairs(part:GetChildren()) do
            if child:IsA("TouchInterest") then child:Destroy() end
         end
         part.Material = Enum.Material.Plastic
         for _, child in ipairs(part:GetChildren()) do
            if child:IsA("BodyVelocity") or child:IsA("VectorForce") or child:IsA("LinearVelocity") or
               child:IsA("AngularVelocity") or child:IsA("BodyThrust") or child:IsA("BodyForce") then
               child.Enabled = false
            end
         end
      end
   end
end

local function revertKillbrickImmunity()
   for part in pairs(originalProps) do revertOriginalProperties(part) end
   originalProps = {}
end

MiscTab:CreateToggle({
   Name = "Killbrick Immunity",
   CurrentValue = true,
   Flag = "KillbrickImmunity",
   Callback = function(v)
      killbrickEnabled = v
      if v then applyKillbrickImmunity() else revertKillbrickImmunity() end
   end
})
applyKillbrickImmunity()
task.spawn(function()
   while true do
      task.wait(5)
      if killbrickEnabled then applyKillbrickImmunity() end
   end
end)

-- ===== Self‑Unjail =====
local selfJailEnabled = true
MiscTab:CreateToggle({
   Name = "Unjail (self)",
   CurrentValue = true,
   Flag = "SelfJail",
   Callback = function(v) selfJailEnabled = v end
})

-- ===== Auto Time Fix =====
local autoTimeFixEnabled = false
local lastTimeFixSent = false
MiscTab:CreateToggle({
   Name = "Auto Time Fix",
   CurrentValue = false,
   Flag = "AutoTimeFix",
   Callback = function(v)
      autoTimeFixEnabled = v
      if not v then lastTimeFixSent = false end
   end
})

-- ===== Misc Buttons =====
MiscTab:CreateButton({
   Name = "Reshow Notifications",
   Callback = function()
      local function notify(title, text)
         pcall(function()
            StarterGui:SetCore("SendNotification", {
               Title = title,
               Text = text,
               Duration = 3,
            })
         end)
      end
      notify("Khols Admin", "All features reloaded")
      task.wait(0.1)
      notify(".afk", ".afk loaded")
      task.wait(0.1)
      notify(".kick", ".kick loaded")
      task.wait(0.1)
      notify(".clr", ".clr loaded")
      task.wait(0.1)
      notify("Anti-Crash", "Anti-Crash active")
      task.wait(0.1)
      notify("Anti-Death", "Anti-Death active")
      task.wait(0.1)
      notify("Anti-Punish", "Anti-Punish active")
      task.wait(0.1)
      notify("Jail Monitor", "Self-Unjail active")
      task.wait(0.1)
      notify("Ban System", ".ban / .unban loaded")
      task.wait(0.1)
      notify("Monitor Commands", "Use 'all' to monitor everyone")
      task.wait(0.1)
      notify("Killbrick Immunity", "Active")
   end
})

MiscTab:CreateButton({
   Name = "Show Commands (console)",
   Callback = function()
      print("===== KHOLS ADMIN COMMANDS =====")
      print(".afk <user> – freeze, god, ff")
      print(".unafk <user> – reset")
      print(".kick <user> – gear me potato (3x), give me potato (4x), bring, freeze, size nan")
      print(".clr – delete all Part, Truss, Seat, and models named 'Model'")
      print(".stopclr – stop ongoing .clr")
      print(".anticrash <user> – monitor anchored (use 'all' for everyone)")
      print(".unanticrash <user> – stop monitoring")
      print(".antideath <user> – monitor death (health ≤ 0)")
      print(".unantideath <user> – stop monitoring")
      print(".antipunish <user> – monitor model removal (auto unpunish + reset)")
      print(".unantipunish <user> – stop monitoring")
      print(".antiall <user> – monitor crash, death, punish, and jail")
      print(".unantiall <user> – stop all monitoring")
      print(".antijail <user> – monitor jail model in workspace")
      print(".unantijail <user> – stop jail monitoring")
      print(".ban <user> – kick + monitor rejoin (sends .kick)")
      print(".unban <user> – stop ban monitoring")
      print("Self toggles: .antipunish (self), .ppunish (self)")
      print("Press K to toggle GUI")
      print("=================================")
   end
})

-- ===== Services =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local ChatEvent = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local afkRunning = false
local MY_MODEL_NAME = "gamprogamer99"

-- Toggle states (self)
local afkEnabled = true
local kickEnabled = true
local antiPunishSelfEnabled = true
local antiDeathSelfEnabled = true
local antiCrashSelfEnabled = true
local clrEnabled = true

-- Monitoring lists
local crashMonitored = {}
local deathMonitored = {}
local punishMonitored = {}
local jailMonitored = {}
local banMonitored = {}
local banWasAbsent = {}

local lastActionTime = {}
local punishDisappearTime = {}
local punishUnpunishSent = {}
local punishResetSent = {}

local clrStop = false
local clrRunning = false

local modelExists = false
local punishSent = false
local lastPunishSelfTime = 0
local punishSelfCooldown = 2.0
local lastDeathSelfTime = 0
local deathSelfCooldown = 1.5
local lastThawSelfTime = 0
local thawSelfCooldown = 1.0

local jailAllCooldown = 0
local jailAllCooldownTime = 1.0

-- ===== Helper: find player =====
local function findPlayer(username)
   for _, plr in ipairs(Players:GetPlayers()) do
      if plr.Name:lower() == username:lower() then
         return plr
      end
   end
   return nil
end

-- ===== Self Anti‑Crash =====
task.spawn(function()
   while true do
      task.wait(0.05)
      if antiCrashSelfEnabled then
         local char = LocalPlayer.Character
         if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root.Anchored then
               local now = tick()
               if now - lastThawSelfTime >= thawSelfCooldown then
                  lastThawSelfTime = now
                  ChatEvent:FireServer("thaw me", "System")
               end
            end
         end
      end
   end
end)

-- ===== Self Anti‑Punish =====
task.spawn(function()
   while true do
      task.wait(0.2)
      local found = false
      for _, obj in ipairs(workspace:GetChildren()) do
         if obj:IsA("Model") and obj.Name == MY_MODEL_NAME then
            found = true
            break
         end
      end
      if found then
         modelExists = true
         punishSent = false
      else
         if modelExists and not punishSent then
            modelExists = false
            punishSent = true
            if antiPunishSelfEnabled then
               local now = tick()
               if now - lastPunishSelfTime >= punishSelfCooldown then
                  lastPunishSelfTime = now
                  ChatEvent:FireServer("re", "System")
               end
            end
         else
            modelExists = false
         end
      end
   end
end)

-- ===== Self Anti‑Death =====
local function sendSelfAntiDeath()
   if not antiDeathSelfEnabled then return end
   local now = tick()
   if now - lastDeathSelfTime < deathSelfCooldown then return end
   lastDeathSelfTime = now
   ChatEvent:FireServer("re", "System")
end

local function attachDeathWatcher(char)
   if not char then return end
   local humanoid = char:FindFirstChildOfClass("Humanoid")
   if not humanoid then return end
   humanoid.Died:Connect(sendSelfAntiDeath)
   humanoid:GetPropertyChangedSignal("Health"):Connect(function()
      if humanoid.Health <= 0 then sendSelfAntiDeath() end
   end)
end

local function onCharacterAdded(char)
   task.wait(0.2)
   attachDeathWatcher(char)
end

local currentChar = LocalPlayer.Character
if currentChar then onCharacterAdded(currentChar) end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- ===== .afk (with whitelist check) =====
local function SetAFK(target)
   if isWhitelisted(target) then
      print("[Whitelist] " .. target .. " is whitelisted – .afk blocked.")
      return
   end
   if not afkEnabled or afkRunning then return end
   afkRunning = true
   ChatEvent:FireServer("freeze " .. target, "System")
   task.wait(0.05)
   ChatEvent:FireServer("god " .. target, "System")
   task.wait(0.05)
   ChatEvent:FireServer("ff " .. target, "System")
   afkRunning = false
end

-- ===== .unafk (with whitelist check) =====
local function SetUnAFK(target)
   if isWhitelisted(target) then
      print("[Whitelist] " .. target .. " is whitelisted – .unafk blocked.")
      return
   end
   if not afkEnabled or afkRunning then return end
   afkRunning = true
   ChatEvent:FireServer("reset " .. target, "System")
   afkRunning = false
end

-- ===== .kick (with whitelist check) =====
local function KickPlayer(target)
   if isWhitelisted(target) then
      print("[Whitelist] " .. target .. " is whitelisted – .kick blocked.")
      return
   end
   if not kickEnabled or afkRunning then return end
   afkRunning = true
   for i = 1, 3 do
      ChatEvent:FireServer("gear me potato", "System")
      task.wait(0.05)
   end
   for i = 1, 4 do
      ChatEvent:FireServer("give me potato", "System")
      task.wait(0.05)
   end
   ChatEvent:FireServer("bring " .. target, "System")
   task.wait(0.05)
   ChatEvent:FireServer("freeze " .. target, "System")
   task.wait(0.05)
   ChatEvent:FireServer("size " .. target .. " nan", "System")
   afkRunning = false
end

-- ===== .clr (no whitelist, unaffected) =====
local function getSyncAPI()
   local char = LocalPlayer.Character
   if char then
      local bt = char:FindFirstChild("Building Tools")
      if bt then
         local sync = bt:FindFirstChild("SyncAPI")
         if sync then
            local ep = sync:FindFirstChild("ServerEndpoint")
            if ep then return ep end
         end
      end
   end
   local bp = LocalPlayer.Backpack
   if bp then
      local bt = bp:FindFirstChild("Building Tools")
      if bt then
         local humanoid = char and char:FindFirstChildOfClass("Humanoid")
         if humanoid then
            humanoid:EquipTool(bt)
            task.wait(0.1)
         end
         local sync = bt:FindFirstChild("SyncAPI")
         if sync then
            local ep = sync:FindFirstChild("ServerEndpoint")
            if ep then return ep end
         end
      end
   end
   return nil
end

local function removeByName(names)
   if not clrEnabled then
      print("[.clr] Command disabled.")
      return
   end
   clrStop = false
   local endpoint = getSyncAPI()
   if not endpoint then
      print("[.clr] Building Tools not found.")
      return
   end

   local instances = {}
   for _, v in pairs(workspace:GetDescendants()) do
      if v:IsA("BasePart") then
         for _, name in ipairs(names) do
            if v.Name:lower() == name:lower() then
               table.insert(instances, v)
               break
            end
         end
      end
      if v:IsA("Model") and v.Name == "Model" then
         table.insert(instances, v)
      end
   end

   if #instances == 0 then
      print("[.clr] No instances found with names: " .. table.concat(names, ", ") .. " or models named 'Model'.")
      return
   end

   print("[.clr] Found " .. #instances .. " instances. Deleting in batches of 1000...")
   local total = 0
   local batchSize = 1000

   for i = 1, #instances, batchSize do
      if clrStop then
         print("[.clr] Stopped by .stopclr.")
         break
      end
      local batch = {}
      for j = i, math.min(i + batchSize - 1, #instances) do
         table.insert(batch, instances[j])
      end
      local success = pcall(function()
         endpoint:InvokeServer("Remove", batch)
      end)
      if success then
         total = total + #batch
      end
      task.wait(0.01)
   end

   if clrStop then
      print("[.clr] Deletion halted. Removed " .. total .. " so far.")
   else
      print("[.clr] Removed " .. total .. " instances.")
   end
end

-- ===== Auto Time Fix =====
task.spawn(function()
   while true do
      task.wait(5)
      if autoTimeFixEnabled then
         local timeOfDay = Lighting.TimeOfDay
         local hour = tonumber(string.sub(timeOfDay, 1, 2))
         if hour then
            local isNight = (hour >= 20 or hour < 6)
            if isNight and not lastTimeFixSent then
               ChatEvent:FireServer("time 12", "System")
               lastTimeFixSent = true
            elseif not isNight then
               lastTimeFixSent = false
            end
         end
      else
         lastTimeFixSent = false
      end
   end
end)

-- ===== Ban monitoring (with whitelist check) =====
-- .ban command itself uses KickPlayer, which already checks whitelist.
-- The monitoring part: when a banned player rejoins, we check whitelist before kicking.
task.spawn(function()
   while true do
      task.wait(1.5)
      for _, username in ipairs(banMonitored) do
         if isWhitelisted(username) then
            -- Skip monitoring for whitelisted players
            continue
         end
         local plr = findPlayer(username)
         local present = plr and plr.Character and plr.Character.Parent == workspace
         if present then
            if banWasAbsent[username] then
               pcall(function()
                  StarterGui:SetCore("SendNotification", {
                     Title = "Ban Monitor",
                     Text = username .. " is active!",
                     Duration = 3,
                  })
               end)
               task.delay(1, function()
                  if findPlayer(username) then
                     ChatEvent:FireServer(".kick " .. username, "System")
                  end
               end)
               banWasAbsent[username] = false
            end
         else
            banWasAbsent[username] = true
         end
      end
   end
end)

-- ===== Monitoring others (crash, death, punish, jail) – these are protective, so whitelist does not block them =====
task.spawn(function()
   while true do
      task.wait(0.05)

      -- Clean up lists
      for i = #crashMonitored, 1, -1 do
         if not findPlayer(crashMonitored[i]) then table.remove(crashMonitored, i) end
      end
      for i = #deathMonitored, 1, -1 do
         if not findPlayer(deathMonitored[i]) then table.remove(deathMonitored, i) end
      end
      for i = #punishMonitored, 1, -1 do
         if not findPlayer(punishMonitored[i]) then
            local removed = punishMonitored[i]
            table.remove(punishMonitored, i)
            if removed then
               local lower = removed:lower()
               punishDisappearTime[lower] = nil
               punishUnpunishSent[lower] = nil
               punishResetSent[lower] = nil
            end
         end
      end
      for i = #jailMonitored, 1, -1 do
         if not findPlayer(jailMonitored[i]) then table.remove(jailMonitored, i) end
      end

      -- Crash (protective)
      for _, storedName in ipairs(crashMonitored) do
         local plr = findPlayer(storedName)
         if plr and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and root.Anchored then
               local now = tick()
               local key = plr.Name .. "_thaw"
               if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
                  lastActionTime[key] = now
                  ChatEvent:FireServer("thaw " .. plr.Name, "System")
               end
            end
         end
      end

      -- Death (protective)
      for _, storedName in ipairs(deathMonitored) do
         local plr = findPlayer(storedName)
         if plr and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then
               local now = tick()
               local key = plr.Name .. "_reset"
               if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
                  lastActionTime[key] = now
                  ChatEvent:FireServer("reset " .. plr.Name, "System")
               end
            end
         end
      end

      -- Punish (protective)
      for _, storedName in ipairs(punishMonitored) do
         local plr = findPlayer(storedName)
         if plr then
            local char = plr.Character
            local present = char and char.Parent == workspace
            local keyLower = plr.Name:lower()

            if not present then
               if not punishDisappearTime[keyLower] then
                  punishDisappearTime[keyLower] = tick()
                  punishUnpunishSent[keyLower] = false
                  punishResetSent[keyLower] = false
                  ChatEvent:FireServer("unpunish " .. plr.Name, "System")
                  punishUnpunishSent[keyLower] = true
               else
                  if not punishResetSent[keyLower] and tick() - punishDisappearTime[keyLower] >= 0.5 then
                     ChatEvent:FireServer("reset " .. plr.Name, "System")
                     punishResetSent[keyLower] = true
                  end
               end
            else
               if punishDisappearTime[keyLower] then
                  punishDisappearTime[keyLower] = nil
                  punishUnpunishSent[keyLower] = nil
                  punishResetSent[keyLower] = nil
               end
            end
         end
      end

      -- Jail (self)
      if selfJailEnabled then
         local jailModel = workspace:FindFirstChild(MY_MODEL_NAME .. "'s jail")
         if jailModel then
            local now = tick()
            local key = "self_jail"
            if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
               lastActionTime[key] = now
               ChatEvent:FireServer("unjail me", "System")
            end
         end
      end

      -- Jail (others) – protective
      local jailedCount = 0
      local totalMonitored = #jailMonitored
      for _, storedName in ipairs(jailMonitored) do
         local plr = findPlayer(storedName)
         if plr then
            local jailModel = workspace:FindFirstChild(plr.Name .. "'s jail")
            if jailModel then
               jailedCount = jailedCount + 1
               local now = tick()
               local key = plr.Name .. "_jail"
               if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
                  lastActionTime[key] = now
                  ChatEvent:FireServer("unjail " .. plr.Name, "System")
               end
            end
         end
      end

      if totalMonitored > 0 and jailedCount == totalMonitored then
         local now = tick()
         if now - jailAllCooldown >= jailAllCooldownTime then
            jailAllCooldown = now
            ChatEvent:FireServer("unjail others", "System")
            print("[Jail] All monitored players jailed – sent 'unjail others'")
         end
      else
         jailAllCooldown = 0
      end
   end
end)

-- ===== Add/remove helpers =====
local function addToMonitor(list, username)
   username = username:gsub("^%s+", ""):gsub("%s+$", "")
   if username == "" then return false end
   if username:lower() == "all" then
      for _, plr in ipairs(Players:GetPlayers()) do
         if plr ~= LocalPlayer then
            local found = false
            for _, name in ipairs(list) do
               if name:lower() == plr.Name:lower() then found = true break end
            end
            if not found then
               table.insert(list, plr.Name)
            end
         end
      end
      return true
   end
   for _, name in ipairs(list) do
      if name:lower() == username:lower() then return false end
   end
   table.insert(list, username)
   return true
end

local function removeFromMonitor(list, username)
   username = username:gsub("^%s+", ""):gsub("%s+$", "")
   if username == "" then return false end
   if username:lower() == "all" then
      local removed = false
      for _, plr in ipairs(Players:GetPlayers()) do
         if plr ~= LocalPlayer then
            for i, name in ipairs(list) do
               if name:lower() == plr.Name:lower() then
                  table.remove(list, i)
                  removed = true
                  break
               end
            end
         end
      end
      return removed
   end
   for i, name in ipairs(list) do
      if name:lower() == username:lower() then
         table.remove(list, i)
         return true
      end
   end
   return false
end

local function addToAllMonitors(username)
   local a = addToMonitor(crashMonitored, username)
   local b = addToMonitor(deathMonitored, username)
   local c = addToMonitor(punishMonitored, username)
   local d = addToMonitor(jailMonitored, username)
   if a or b or c or d then
      print("[AntiAll] Now monitoring " .. username .. " for crash, death, punish, and jail.")
   else
      print("[AntiAll] " .. username .. " already monitored for all.")
   end
end

local function removeFromAllMonitors(username)
   local a = removeFromMonitor(crashMonitored, username)
   local b = removeFromMonitor(deathMonitored, username)
   local c = removeFromMonitor(punishMonitored, username)
   local d = removeFromMonitor(jailMonitored, username)
   if a or b or c or d then
      print("[AntiAll] Stopped monitoring all for " .. username)
   else
      print("[AntiAll] " .. username .. " not being monitored.")
   end
end

local function addJailMonitor(username) return addToMonitor(jailMonitored, username) end
local function removeJailMonitor(username) return removeFromMonitor(jailMonitored, username) end

local function addBanMonitor(username)
   local added = addToMonitor(banMonitored, username)
   if added then
      local plr = findPlayer(username)
      local present = plr and plr.Character and plr.Character.Parent == workspace
      banWasAbsent[username] = not present
   end
   return added
end

local function removeBanMonitor(username)
   local removed = removeFromMonitor(banMonitored, username)
   if removed then
      banWasAbsent[username] = nil
   end
   return removed
end

-- ===== UI =====
local afkToggle = CommandsTab:CreateToggle({
   Name = "AFK Commands (.afk / .unafk)", CurrentValue = true, Flag = "AFK_Enabled",
   Callback = function(v) afkEnabled = v end
})

local kickToggle = CommandsTab:CreateToggle({
   Name = "Kick Command (.kick)", CurrentValue = true, Flag = "Kick_Enabled",
   Callback = function(v) kickEnabled = v end
})

local antiPunishSelfToggle = CommandsTab:CreateToggle({
   Name = "Self Anti‑Punish (sends 're' on removal)", CurrentValue = true, Flag = "AntiPunishSelf",
   Callback = function(v)
      antiPunishSelfEnabled = v
      if not v then punishSent = true modelExists = false end
   end
})

local antiDeathSelfToggle = CommandsTab:CreateToggle({
   Name = "Self Anti‑Death (sends 're' on death)", CurrentValue = true, Flag = "AntiDeathSelf",
   Callback = function(v) antiDeathSelfEnabled = v end
})

local antiCrashSelfToggle = CommandsTab:CreateToggle({
   Name = "Self Anti‑Crash (thaw me when anchored)", CurrentValue = true, Flag = "AntiCrashSelf",
   Callback = function(v) antiCrashSelfEnabled = v end
})

local clrToggle = CommandsTab:CreateToggle({
   Name = "Clear Parts (.clr)", CurrentValue = true, Flag = "ClearParts",
   Callback = function(v) clrEnabled = v end
})

CommandsTab:CreateButton({ Name = "Hide GUI", Callback = function() Rayfield:SetVisibility(false) end })
CommandsTab:CreateButton({ Name = "Show GUI", Callback = function() Rayfield:SetVisibility(true) end })
CommandsTab:CreateButton({ Name = "Destroy GUI", Callback = function() Rayfield:Destroy() end })

-- ===== Chat hooks (with whitelist handling for owner commands) =====
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
   local args = {...}
   if self == ChatEvent and getnamecallmethod() == "FireServer" and typeof(args[1]) == "string" then
      local msg = string.lower(args[1])
      local target

      -- Owner-only: .whitelist / .unwhitelist
      if string.sub(msg, 1, 10) == ".whitelist " then
         local username = string.sub(args[1], 11)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addWhitelist(username)
         else
            print("[Whitelist] Please specify a username.")
         end
         return old(self, ...)  -- let the command go to chat (optional)
      elseif string.sub(msg, 1, 12) == ".unwhitelist " then
         local username = string.sub(args[1], 13)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            removeWhitelist(username)
         else
            print("[Whitelist] Please specify a username.")
         end
         return old(self, ...)
      end

      -- Self toggles
      if msg == ".antipunish" then
         antiPunishSelfEnabled = true
         antiPunishSelfToggle:Set(true)
      elseif msg == ".ppunish" then
         antiPunishSelfEnabled = false
         antiPunishSelfToggle:Set(false)
      elseif msg == ".stopclr" then
         clrStop = true
         print("[.clr] Stop requested.")
      -- .afk (with whitelist check inside SetAFK)
      elseif string.sub(msg, 1, 4) == ".afk" then
         local rest = string.sub(msg, 5)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(SetAFK, target)
      -- .unafk (with whitelist check inside SetUnAFK)
      elseif string.sub(msg, 1, 6) == ".unafk" then
         local rest = string.sub(msg, 7)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(SetUnAFK, target)
      -- .kick (with whitelist check inside KickPlayer)
      elseif string.sub(msg, 1, 5) == ".kick" then
         local rest = string.sub(msg, 6)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(KickPlayer, target)
      -- .clr (no target)
      elseif msg == ".clr" then
         task.spawn(function()
            if clrRunning then return end
            clrRunning = true
            removeByName({"Part", "Truss", "Seat"})
            clrRunning = false
         end)
      -- Monitor commands (protective, no whitelist check)
      elseif string.sub(msg, 1, 11) == ".anticrash " then
         local username = string.sub(args[1], 12)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addToMonitor(crashMonitored, username)
            print("[AntiCrash] Now monitoring " .. username)
         else
            print("[AntiCrash] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 13) == ".unanticrash " then
         local username = string.sub(args[1], 14)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if removeFromMonitor(crashMonitored, username) then
               print("[AntiCrash] Stopped monitoring " .. username)
            else
               print("[AntiCrash] " .. username .. " not being monitored.")
            end
         else
            print("[AntiCrash] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 11) == ".antideath " then
         local username = string.sub(args[1], 12)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addToMonitor(deathMonitored, username)
            print("[AntiDeath] Now monitoring " .. username)
         else
            print("[AntiDeath] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 13) == ".unantideath " then
         local username = string.sub(args[1], 14)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if removeFromMonitor(deathMonitored, username) then
               print("[AntiDeath] Stopped monitoring " .. username)
            else
               print("[AntiDeath] " .. username .. " not being monitored.")
            end
         else
            print("[AntiDeath] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 12) == ".antipunish " then
         local username = string.sub(args[1], 13)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addToMonitor(punishMonitored, username)
            print("[AntiPunish] Now monitoring " .. username)
         else
            print("[AntiPunish] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 14) == ".unantipunish " then
         local username = string.sub(args[1], 15)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if removeFromMonitor(punishMonitored, username) then
               print("[AntiPunish] Stopped monitoring " .. username)
            else
               print("[AntiPunish] " .. username .. " not being monitored.")
            end
         else
            print("[AntiPunish] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 9) == ".antiall " then
         local username = string.sub(args[1], 10)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addToAllMonitors(username)
            print("[AntiAll] Now monitoring all for " .. username)
         else
            print("[AntiAll] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 11) == ".unantiall " then
         local username = string.sub(args[1], 12)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if removeFromAllMonitors(username) then
               print("[AntiAll] Stopped monitoring all for " .. username)
            else
               print("[AntiAll] " .. username .. " not being monitored.")
            end
         else
            print("[AntiAll] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 10) == ".antijail " then
         local username = string.sub(args[1], 11)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if addJailMonitor(username) then
               print("[AntiJail] Now monitoring " .. username .. " for jail.")
            else
               print("[AntiJail] " .. username .. " already monitored.")
            end
         else
            print("[AntiJail] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 12) == ".unantijail " then
         local username = string.sub(args[1], 13)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if removeJailMonitor(username) then
               print("[AntiJail] Stopped monitoring " .. username)
            else
               print("[AntiJail] " .. username .. " not being monitored.")
            end
         else
            print("[AntiJail] Please specify a username or 'all'.")
         end
      elseif string.sub(msg, 1, 5) == ".ban " then
         local username = string.sub(args[1], 6)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if isWhitelisted(username) then
               print("[Whitelist] " .. username .. " is whitelisted – .ban blocked.")
            else
               if findPlayer(username) then
                  task.spawn(KickPlayer, username)
               else
                  print("[Ban] Player not found to kick initially, but will monitor.")
               end
               if addBanMonitor(username) then
                  print("[Ban] Now monitoring " .. username .. " (will .kick if they reappear).")
               else
                  print("[Ban] Already monitoring " .. username)
               end
            end
         else
            print("[Ban] Please specify a username.")
         end
      elseif string.sub(msg, 1, 7) == ".unban " then
         local username = string.sub(args[1], 8)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if removeBanMonitor(username) then
               print("[Ban] Stopped monitoring " .. username)
            else
               print("[Ban] " .. username .. " not being monitored.")
            end
         else
            print("[Ban] Please specify a username.")
         end
      end
   end
   return old(self, ...)
end)

-- ===== Auto‑send "startergive self" =====
task.spawn(function()
   task.wait(1)
   local success, err = pcall(function()
      ChatEvent:FireServer("startergive self", "System")
   end)
   if success then
      print("[Auto] Sent 'startergive self' to chat.")
   else
      warn("[Auto] Failed to send startergive self: " .. tostring(err))
   end
end)

-- ===== Notification helper =====
local function notify(title, text)
   pcall(function()
      StarterGui:SetCore("SendNotification", {
         Title = title,
         Text = text,
         Duration = 4,
      })
   end)
end

task.spawn(function()
   task.wait(1.5)
   local notifications = {
      {"Khols Admin", "Owner version loaded with whitelist!"},
      {".afk", ".afk loaded"},
      {".kick", ".kick loaded"},
      {".clr", ".clr loaded"},
      {"Anti-Crash", "Anti-Crash (self) active"},
      {"Anti-Death", "Anti-Death (self) active"},
      {"Anti-Punish", "Anti-Punish (self) active"},
      {"Jail Monitor", "Self-Unjail is active"},
      {"Ban System", ".ban / .unban loaded"},
      {"Monitor Commands", "Use 'all' to monitor everyone"},
      {"Killbrick Immunity", "Active"},
      {"Whitelist", "Use .whitelist <user> to protect players"}
   }
   for _, notif in ipairs(notifications) do
      notify(notif[1], notif[2])
      task.wait(0.1)
   end
end)

print("Khols Admin Owner GUI loaded. Whitelist active.")
print("Commands: .whitelist <user>, .unwhitelist <user>")
print("Press K to toggle GUI.")
