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

-- ===== Self‑Unjail (ON by default) =====
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

-- ===== Services =====
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local ChatEvent = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local afkRunning = false
local afkMode = false
local MY_NAME = LocalPlayer.Name

local afkEnabled = true
local kickEnabled = true
local antiPunishSelfEnabled = true
local antiDeathSelfEnabled = true
local antiCrashSelfEnabled = true
local clrEnabled = true

local crashMonitored = {}
local deathMonitored = {}
local punishMonitored = {}
local jailMonitored = {}
local banMonitored = {}
local banWasAbsent = {}

local lastActionTime = {}
local punishTasks = {}

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

-- ===== Helpers =====
local function findPlayer(username)
   for _, plr in ipairs(Players:GetPlayers()) do
      if plr.Name:lower() == username:lower() then return plr end
   end
   return nil
end

local function sendWithCooldown(target, action, cooldown, channel)
   channel = channel or "System"
   local key = target .. "_" .. action
   local now = tick()
   if not lastActionTime[key] or now - lastActionTime[key] >= cooldown then
      lastActionTime[key] = now
      ChatEvent:FireServer(action .. " " .. target, channel)
      return true
   end
   return false
end

local function sendGod(target)
   sendWithCooldown(target, "god", 1.0)
end

-- ===== Self Anti‑Crash =====
task.spawn(function()
   while true do
      task.wait(0.05)
      if not afkMode and antiCrashSelfEnabled then
         local char = LocalPlayer.Character
         if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root and root.Anchored then
               sendWithCooldown("me", "thaw", 1.0)
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
         if obj:IsA("Model") and obj.Name == MY_NAME then
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
               if sendWithCooldown("me", "re", punishSelfCooldown) then
                  task.delay(0.1, function() sendGod("me") end)
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
   if sendWithCooldown("me", "re", deathSelfCooldown) then
      task.delay(0.1, function() sendGod("me") end)
   end
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

-- ===== .afk =====
local function SetAFK(target)
   if not afkEnabled or afkRunning then return end
   afkRunning = true
   afkMode = true
   ChatEvent:FireServer("freeze " .. target, "System")
   task.wait(0.05)
   ChatEvent:FireServer("god " .. target, "System")
   task.wait(0.05)
   ChatEvent:FireServer("ff " .. target, "System")
   afkRunning = false
end

-- ===== .unafk =====
local function SetUnAFK(target)
   if not afkEnabled or afkRunning then return end
   afkRunning = true
   afkMode = false
   ChatEvent:FireServer("reset " .. target, "System")
   afkRunning = false
end

-- ===== .kick =====
local function KickPlayer(target)
   if not kickEnabled or afkRunning then return end
   afkRunning = true
   for i = 1, 3 do ChatEvent:FireServer("gear me potato", "System") task.wait(0.05) end
   for i = 1, 4 do ChatEvent:FireServer("give me potato", "System") task.wait(0.05) end
   ChatEvent:FireServer("bring " .. target, "System")
   task.wait(0.05)
   ChatEvent:FireServer("freeze " .. target, "System")
   task.wait(0.05)
   ChatEvent:FireServer("size " .. target .. " nan", "System")
   afkRunning = false
end

-- ===== .clr =====
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

   print("[.clr] Found " .. #instances .. " instances. Deleting in batches of 5000...")
   local total = 0
   local batchSize = 5000

   for i = 1, #instances, batchSize do
      if clrStop then
         print("[.clr] Stopped by .stopclr.")
         break
      end
      local batch = {}
      for j = i, math.min(i + batchSize - 1, #instances) do
         table.insert(batch, instances[j])
      end
      local success, err = pcall(function()
         endpoint:InvokeServer("Remove", batch)
      end)
      if success then
         total = total + #batch
      else
         print("[.clr] Batch failed, falling back to single deletion: " .. tostring(err))
         for _, part in ipairs(batch) do
            local ok = pcall(function()
               endpoint:InvokeServer("Remove", {part})
            end)
            if ok then total = total + 1 end
            task.wait(0.01)
         end
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
               ChatEvent:FireServer("time 12", "All")
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

-- ===== Ban monitoring (every 4s) =====
task.spawn(function()
   while true do
      task.wait(4)
      for _, username in ipairs(banMonitored) do
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
                     ChatEvent:FireServer(".kick " .. username, "All")
                     print("[Ban] Sent '.kick " .. username .. "' to All.")
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

-- ===== Monitoring others (crash, death, punish, jail) =====
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
         local plr = findPlayer(punishMonitored[i])
         if not plr then
            local removed = punishMonitored[i]
            table.remove(punishMonitored, i)
            if punishTasks[removed] then
               if punishTasks[removed].unpunishThread then task.cancel(punishTasks[removed].unpunishThread) end
               if punishTasks[removed].resetThread then task.cancel(punishTasks[removed].resetThread) end
               punishTasks[removed] = nil
            end
         end
      end
      for i = #jailMonitored, 1, -1 do
         if not findPlayer(jailMonitored[i]) then table.remove(jailMonitored, i) end
      end

      -- Crash
      for _, storedName in ipairs(crashMonitored) do
         local plr = findPlayer(storedName)
         if plr and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and root.Anchored then
               sendWithCooldown(plr.Name, "thaw", 1.0)
            end
         end
      end

      -- Death
      for _, storedName in ipairs(deathMonitored) do
         local plr = findPlayer(storedName)
         if plr and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then
               if sendWithCooldown(plr.Name, "reset", 1.0) then
                  task.delay(0.1, function() sendGod(plr.Name) end)
               end
            end
         end
      end

      -- Punish
      for _, storedName in ipairs(punishMonitored) do
         local plr = findPlayer(storedName)
         if plr then
            local char = plr.Character
            local present = char and char.Parent == workspace
            local key = plr.Name

            if not present then
               if not punishTasks[key] then
                  local tasks = {}
                  local disappearTime = tick()
                  local unpunishThread = task.delay(0.3, function()
                     if punishTasks[key] and punishTasks[key].disappearTime == disappearTime then
                        if sendWithCooldown(key, "unpunish", 1.0) then
                           task.delay(0.1, function() sendGod(key) end)
                        end
                     end
                  end)
                  local resetThread = task.delay(1.0, function()
                     if punishTasks[key] and punishTasks[key].disappearTime == disappearTime then
                        if sendWithCooldown(key, "reset", 1.0) then
                           task.delay(0.1, function() sendGod(key) end)
                        end
                     end
                  end)
                  tasks.unpunishThread = unpunishThread
                  tasks.resetThread = resetThread
                  tasks.disappearTime = disappearTime
                  punishTasks[key] = tasks
               end
            else
               if punishTasks[key] then
                  if punishTasks[key].unpunishThread then task.cancel(punishTasks[key].unpunishThread) end
                  if punishTasks[key].resetThread then task.cancel(punishTasks[key].resetThread) end
                  punishTasks[key] = nil
               end
            end
         end
      end

      -- Jail (self)
      if selfJailEnabled then
         local jailModel = workspace:FindFirstChild(MY_NAME .. "'s jail")
         if jailModel then
            sendWithCooldown("me", "unjail", 1.0)
         end
      end

      -- Jail (others)
      for _, storedName in ipairs(jailMonitored) do
         local plr = findPlayer(storedName)
         if plr then
            local jailModel = workspace:FindFirstChild(plr.Name .. "'s jail")
            if jailModel then
               sendWithCooldown(plr.Name, "unjail", 1.0)
            end
         end
      end
   end
end)

-- ===== Add/remove helpers =====
local function addToMonitor(list, username)
   username = username:gsub("^%s+", ""):gsub("%s+$", "")
   for _, name in ipairs(list) do
      if name:lower() == username:lower() then return false end
   end
   table.insert(list, username)
   return true
end

local function removeFromMonitor(list, username)
   username = username:gsub("^%s+", ""):gsub("%s+$", "")
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
   Name = "Self Anti‑Punish (sends 're' + 'god me')", CurrentValue = true, Flag = "AntiPunishSelf",
   Callback = function(v)
      antiPunishSelfEnabled = v
      if not v then punishSent = true modelExists = false end
   end
})

local antiDeathSelfToggle = CommandsTab:CreateToggle({
   Name = "Self Anti‑Death (sends 're' + 'god me')", CurrentValue = true, Flag = "AntiDeathSelf",
   Callback = function(v) antiDeathSelfEnabled = v end
})

local antiCrashSelfToggle = CommandsTab:CreateToggle({
   Name = "Self Anti‑Crash (thaw me when anchored)", CurrentValue = true, Flag = "AntiCrashSelf",
   Callback = function(v) antiCrashSelfEnabled = v end
})

local clrToggle = CommandsTab:CreateToggle({
   Name = "Clear Parts (.clr – deletes Part, Truss, Seat, and models named 'Model')",
   CurrentValue = true, Flag = "ClearParts",
   Callback = function(v) clrEnabled = v end
})

CommandsTab:CreateButton({ Name = "Hide GUI", Callback = function() Rayfield:SetVisibility(false) end })
CommandsTab:CreateButton({ Name = "Show GUI", Callback = function() Rayfield:SetVisibility(true) end })
CommandsTab:CreateButton({ Name = "Destroy GUI", Callback = function() Rayfield:Destroy() end })

-- ===== Chat command handling =====
local function handleChatCommand(msg)
   msg = string.lower(msg)
   local target

   if msg == ".antipunish" then
      antiPunishSelfEnabled = true
      antiPunishSelfToggle:Set(true)
      return
   elseif msg == ".ppunish" then
      antiPunishSelfEnabled = false
      antiPunishSelfToggle:Set(false)
      return
   elseif msg == ".stopclr" then
      clrStop = true
      print("[.clr] Stop requested.")
      return
   elseif string.sub(msg, 1, 4) == ".afk" then
      local rest = string.sub(msg, 5)
      target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
      if target == "" then target = "me" end
      task.spawn(SetAFK, target)
      return
   elseif string.sub(msg, 1, 6) == ".unafk" then
      local rest = string.sub(msg, 7)
      target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
      if target == "" then target = "me" end
      task.spawn(SetUnAFK, target)
      return
   elseif string.sub(msg, 1, 5) == ".kick" then
      local rest = string.sub(msg, 6)
      target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
      if target == "" then target = "me" end
      task.spawn(KickPlayer, target)
      return
   elseif msg == ".clr" then
      task.spawn(function()
         if clrRunning then return end
         clrRunning = true
         removeByName({"Part", "Truss", "Seat"})
         clrRunning = false
      end)
      return
   elseif string.sub(msg, 1, 11) == ".anticrash " then
      local username = string.sub(msg, 12)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         addToMonitor(crashMonitored, username)
         print("[AntiCrash] Now monitoring " .. username)
      else
         print("[AntiCrash] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 13) == ".unanticrash " then
      local username = string.sub(msg, 14)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         if removeFromMonitor(crashMonitored, username) then
            print("[AntiCrash] Stopped monitoring " .. username)
         else
            print("[AntiCrash] " .. username .. " not being monitored.")
         end
      else
         print("[AntiCrash] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 11) == ".antideath " then
      local username = string.sub(msg, 12)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         addToMonitor(deathMonitored, username)
         print("[AntiDeath] Now monitoring " .. username)
      else
         print("[AntiDeath] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 13) == ".unantideath " then
      local username = string.sub(msg, 14)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         if removeFromMonitor(deathMonitored, username) then
            print("[AntiDeath] Stopped monitoring " .. username)
         else
            print("[AntiDeath] " .. username .. " not being monitored.")
         end
      else
         print("[AntiDeath] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 12) == ".antipunish " then
      local username = string.sub(msg, 13)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         if punishTasks[username] then
            if punishTasks[username].unpunishThread then task.cancel(punishTasks[username].unpunishThread) end
            if punishTasks[username].resetThread then task.cancel(punishTasks[username].resetThread) end
            punishTasks[username] = nil
         end
         addToMonitor(punishMonitored, username)
         print("[AntiPunish] Now monitoring " .. username)
      else
         print("[AntiPunish] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 14) == ".unantipunish " then
      local username = string.sub(msg, 15)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         if removeFromMonitor(punishMonitored, username) then
            if punishTasks[username] then
               if punishTasks[username].unpunishThread then task.cancel(punishTasks[username].unpunishThread) end
               if punishTasks[username].resetThread then task.cancel(punishTasks[username].resetThread) end
               punishTasks[username] = nil
            end
            print("[AntiPunish] Stopped monitoring " .. username)
         else
            print("[AntiPunish] " .. username .. " not being monitored.")
         end
      else
         print("[AntiPunish] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 9) == ".antiall " then
      local username = string.sub(msg, 10)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         if punishTasks[username] then
            if punishTasks[username].unpunishThread then task.cancel(punishTasks[username].unpunishThread) end
            if punishTasks[username].resetThread then task.cancel(punishTasks[username].resetThread) end
            punishTasks[username] = nil
         end
         addToAllMonitors(username)
      else
         print("[AntiAll] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 11) == ".unantiall " then
      local username = string.sub(msg, 12)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         if removeFromAllMonitors(username) then
            if punishTasks[username] then
               if punishTasks[username].unpunishThread then task.cancel(punishTasks[username].unpunishThread) end
               if punishTasks[username].resetThread then task.cancel(punishTasks[username].resetThread) end
               punishTasks[username] = nil
            end
            print("[AntiAll] Stopped monitoring all for " .. username)
         else
            print("[AntiAll] " .. username .. " not being monitored.")
         end
      else
         print("[AntiAll] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 10) == ".antijail " then
      local username = string.sub(msg, 11)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         if addJailMonitor(username) then
            print("[AntiJail] Now monitoring " .. username .. " for jail.")
         else
            print("[AntiJail] " .. username .. " already monitored.")
         end
      else
         print("[AntiJail] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 12) == ".unantijail " then
      local username = string.sub(msg, 13)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
         if removeJailMonitor(username) then
            print("[AntiJail] Stopped monitoring " .. username)
         else
            print("[AntiJail] " .. username .. " not being monitored.")
         end
      else
         print("[AntiJail] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 5) == ".ban " then
      local username = string.sub(msg, 6)
      username = username:gsub("^%s+", ""):gsub("%s+$", "")
      if username ~= "" then
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
      else
         print("[Ban] Please specify a username.")
      end
      return
   elseif string.sub(msg, 1, 7) == ".unban " then
      local username = string.sub(msg, 8)
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
      return
   end
end

LocalPlayer.Chatted:Connect(handleChatCommand)

-- ===== Auto‑send "startergive self" =====
task.spawn(function()
   task.wait(1)
   local success, err = pcall(function()
      ChatEvent:FireServer("startergive self", "All")
   end)
   if success then
      print("[Auto] Sent 'startergive self' to chat.")
   else
      warn("[Auto] Failed to send startergive self: " .. tostring(err))
   end
end)

-- ===== Notification =====
task.spawn(function()
   task.wait(1.5)
   pcall(function()
      StarterGui:SetCore("SendNotification", {
         Title = "Khols Admin",
         Text = "Everything in Rayfield is loaded!",
         Duration = 5,
      })
   end)
end)

print("Khols Admin GUI loaded. Self‑Unjail ON by default.")
print("Commands: .afk, .unafk, .kick, .clr, .stopclr, .antipunish (self), .ppunish (self)")
print("Monitor: .anticrash, .unanticrash, .antideath, .unantideath, .antipunish, .unantipunish, .antiall, .unantiall")
print("Jail: .antijail, .unantijail")
print("Ban: .ban <user> (kicks + monitors), .unban <user>")
print("Press K to toggle GUI.")
