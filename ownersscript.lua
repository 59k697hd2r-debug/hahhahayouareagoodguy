-- ============================================
-- KOHLS ADMIN HOUSE X – FINAL PUBLIC VERSION
-- Partial name matching (by display name) for ALL commands
-- + Fixed multi‑player commands (.anticrash all etc.)
-- + Color‑based Admin Pad Claimer (claims ONE pad)
-- + Troll tab: Fire Click Detector (no cooldown)
-- + .workspaceclr – deletes EVERYTHING in workspace (via SyncAPI)
-- + .trollclr – unanchor & disable collision for all Parts/Trusses/Seats
-- + .clr – now deletes ALL BaseParts (except Baseplate) plus Tools (except Building Tools) and Models named "Model"
-- + Loaders tab: Novoline, Infinite Yield, Explorer++, Cobalt Spy
-- ============================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "KOHLS ADMIN HOUSE X",
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
local TrollTab = Window:CreateTab("Troll", 4483362458)
local LoadersTab = Window:CreateTab("Loaders (novo etc)", 4483362458)

-- ===== Silent Commands Toggle =====
local silentMode = false
MiscTab:CreateToggle({
   Name = "Silent Commands",
   CurrentValue = false,
   Flag = "SilentMode",
   Callback = function(v)
      silentMode = v
      print("[Silent] " .. (v and "ON (commands hidden)" or "OFF"))
   end
})

-- ===== Manual Gearban Toggle (.gearbanme) =====
local gearbanEnabled = true
CommandsTab:CreateToggle({
   Name = "Manual Gearban (.gearbanme)",
   CurrentValue = true,
   Flag = "GearbanEnabled",
   Callback = function(v)
      gearbanEnabled = v
      print("[Gearban] Manual command " .. (v and "ENABLED" or "DISABLED"))
   end
})

-- ===== Gearban Monitor Toggle (.gearban / .ungearban) =====
local gearbanMonitorEnabled = true
CommandsTab:CreateToggle({
   Name = "Gearban Monitor (.gearban / .ungearban)",
   CurrentValue = true,
   Flag = "GearbanMonitor",
   Callback = function(v)
      gearbanMonitorEnabled = v
      print("[Gearban Monitor] " .. (v and "ENABLED" or "DISABLED"))
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
local EXECUTOR_NAME = LocalPlayer.Name

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

-- Gearban monitor lists
local gearbanMonitored = {}
local gearbanLastSent = {}

local lastActionTime = {}
local punishDisappearTime = {}
local punishUnpunishSent = {}
local punishResetSent = {}

local clrStop = false
local clrRunning = false

-- Self anti‑punish/death coordination
local modelExists = false
local punishSent = false
local lastPunishSelfTime = 0
local punishSelfCooldown = 2.0
local lastDeathSelfTime = 0
local deathSelfCooldown = 1.5
local lastThawSelfTime = 0
local thawSelfCooldown = 1.0
local deathRecently = false

local jailAllCooldown = 0
local jailAllCooldownTime = 1.0

-- ===== Helper: send message =====
local function sendMessage(msg, channel)
   if silentMode then
      channel = "System"
   else
      channel = channel or "All"
   end
   ChatEvent:FireServer(msg, channel)
   print("[Chat] (" .. channel .. ") " .. msg)
end

-- ===== NEW: Partial matcher by display name =====
-- Returns: player object, or "all" marker, or nil if not found.
local function resolveTarget(partial)
   if not partial or partial == "" then return nil end
   partial = string.lower(partial)
   if partial == "me" then return LocalPlayer end
   if partial == "all" then return "all" end

   local matches = {}
   for _, plr in ipairs(Players:GetPlayers()) do
      local display = string.lower(plr.DisplayName)
      if string.sub(display, 1, #partial) == partial then
         table.insert(matches, plr)
      end
   end
   if #matches == 1 then
      return matches[1]
   elseif #matches > 1 then
      print("[PartialMatcher] Multiple matches for '" .. partial .. "', using first: " .. matches[1].Name)
      return matches[1]
   end
   -- Fallback: exact username match (case-insensitive)
   for _, plr in ipairs(Players:GetPlayers()) do
      if string.lower(plr.Name) == partial then
         return plr
      end
   end
   return nil
end

-- ===== getSyncAPI =====
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

-- ===== Gearban monitor functions =====
local function gearbanCheckBackpack(username)
   local plr = resolveTarget(username)
   if not plr or plr == "all" then return end
   local backpack = plr:FindFirstChildOfClass("Backpack")
   if not backpack then return end
   local hasItems = false
   for _, child in ipairs(backpack:GetChildren()) do
      if child:IsA("Tool") then
         hasItems = true
         break
      end
   end
   if hasItems then
      local now = tick()
      if not gearbanLastSent[username] or now - gearbanLastSent[username] >= 5 then
         gearbanLastSent[username] = now
         sendMessage(".ungear " .. plr.Name, "System")
         print("[Gearban Monitor] Sent .ungear for " .. plr.Name)
      end
   end
end

-- Gearban monitor loop (runs every 1s)
task.spawn(function()
   while true do
      task.wait(1)
      if gearbanMonitorEnabled then
         for _, name in ipairs(gearbanMonitored) do
            gearbanCheckBackpack(name)
         end
      end
   end
end)

-- Add/remove gearban monitor helpers
local function addGearbanMonitor(username)
   local target = resolveTarget(username)
   if not target or target == "all" then
      print("[Gearban Monitor] Invalid target.")
      return false
   end
   local name = target.Name
   for _, n in ipairs(gearbanMonitored) do
      if n:lower() == name:lower() then
         print("[Gearban Monitor] Already monitoring " .. name)
         return false
      end
   end
   table.insert(gearbanMonitored, name)
   print("[Gearban Monitor] Now monitoring " .. name)
   return true
end

local function removeGearbanMonitor(username)
   local target = resolveTarget(username)
   if not target or target == "all" then
      print("[Gearban Monitor] Invalid target.")
      return false
   end
   local name = target.Name
   for i, n in ipairs(gearbanMonitored) do
      if n:lower() == name:lower() then
         table.remove(gearbanMonitored, i)
         gearbanLastSent[name] = nil
         print("[Gearban Monitor] Stopped monitoring " .. name)
         return true
      end
   end
   print("[Gearban Monitor] " .. name .. " not being monitored.")
   return false
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
                  sendMessage("thaw me", "System")
               end
            end
         end
      end
   end
end)

-- ===== Self Anti‑Punish (skip if death recently) =====
task.spawn(function()
   while true do
      task.wait(0.2)
      if deathRecently then
         if tick() - lastDeathSelfTime > 1.0 then
            deathRecently = false
         else
            continue
         end
      end
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
                  sendMessage("re", "System")
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
   deathRecently = true
   sendMessage("re", "System")
end

local function attachDeathWatcher(char)
   if not char then return end
   local humanoid = char:FindFirstChildOfClass("Humanoid")
   if not humanoid then return end
   humanoid.Died:Connect(sendSelfAntiDeath)
   humanoid:GetPropertyChangedSignal("Health"):Connect(function()
      if humanoid.Health <= 0 then
         sendSelfAntiDeath()
      end
   end)
end

local function onCharacterAdded(char)
   task.wait(0.2)
   attachDeathWatcher(char)
end

local currentChar = LocalPlayer.Character
if currentChar then
   onCharacterAdded(currentChar)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- ===== .afk =====
local function SetAFK(target)
   if not afkEnabled or afkRunning then return end
   local plr = resolveTarget(target)
   if not plr or plr == "all" then
      print("[AFK] Invalid target.")
      return
   end
   afkRunning = true
   sendMessage("freeze " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("god " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("ff " .. plr.Name, "System")
   afkRunning = false
end

-- ===== .unafk =====
local function SetUnAFK(target)
   if not afkEnabled or afkRunning then return end
   local plr = resolveTarget(target)
   if not plr or plr == "all" then
      print("[UNAFK] Invalid target.")
      return
   end
   afkRunning = true
   sendMessage("reset " .. plr.Name, "System")
   afkRunning = false
end

-- ===== .kick =====
local function KickPlayer(target)
   if not kickEnabled or afkRunning then return end
   local plr = resolveTarget(target)
   if not plr or plr == "all" then
      print("[Kick] Invalid target.")
      return
   end
   afkRunning = true
   for i = 1, 3 do
      sendMessage("gear " .. EXECUTOR_NAME .. " potato", "System")
      task.wait(0.05)
   end
   for i = 1, 4 do
      sendMessage("give " .. EXECUTOR_NAME .. " potato", "System")
      task.wait(0.05)
   end
   sendMessage("bring " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("freeze " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("size " .. plr.Name .. " nan", "System")
   afkRunning = false
end

-- ===== Manual .gearbanme (with notification) =====
local function GearbanManual(target)
   if not gearbanEnabled then
      print("[Gearban] Manual command disabled.")
      return
   end
   if afkRunning then return end
   local plr = resolveTarget(target)
   if not plr or plr == "all" then
      print("[Gearban] Invalid target.")
      return
   end
   afkRunning = true

   pcall(function()
      StarterGui:SetCore("SendNotification", {
         Title = "Gearban",
         Text = "Click on victim to use portable!",
         Duration = 3,
      })
   end)

   sendMessage("gear me portable", "System")
   task.wait(0.05)
   sendMessage("give me portable", "System")
   task.wait(0.05)
   sendMessage("bring " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("unff " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("ungod " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("speed " .. plr.Name .. " 0", "System")

   afkRunning = false
end

-- ===== .clr – now deletes ALL BaseParts (except Baseplate) plus Tools (except Building Tools) and Models named "Model" =====
local function clearAll()
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
   -- Collect all BaseParts, skip those named "Baseplate" (case-insensitive)
   for _, v in pairs(workspace:GetDescendants()) do
      if v:IsA("BasePart") then
         local name = v.Name:lower()
         if name ~= "baseplate" then
            table.insert(instances, v)
         end
      end
      -- Also collect Tools (except Building Tools)
      if v:IsA("Tool") and v.Name ~= "Building Tools" then
         table.insert(instances, v)
      end
      -- Also collect Models named "Model"
      if v:IsA("Model") and v.Name == "Model" then
         table.insert(instances, v)
      end
   end

   if #instances == 0 then
      print("[.clr] No matching instances found.")
      return
   end

   print("[.clr] Found " .. #instances .. " instances. Deleting in batches of 5000...")
   local total = 0
   local batchSize = 5000

   for i = 1, #instances, batchSize do
      if clrStop then break end
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
      print("[.clr] Halted. Removed " .. total .. " so far.")
   else
      print("[.clr] Removed " .. total .. " instances.")
   end
end

-- ===== .adminclr (deletes House, Obby Box, Obby, Baseplate, Grids, Regen) =====
local function adminClear()
   local endpoint = getSyncAPI()
   if not endpoint then
      print("[.adminclr] Building Tools not found.")
      return
   end

   local targetNames = {"House", "Obby Box", "Obby", "Baseplate", "Grids", "Regen"}
   local instances = {}
   for _, v in pairs(workspace:GetDescendants()) do
      if v:IsA("Model") or v:IsA("BasePart") then
         for _, name in ipairs(targetNames) do
            if v.Name == name then
               table.insert(instances, v)
               break
            end
         end
      end
   end

   if #instances == 0 then
      print("[.adminclr] No matching instances found.")
      return
   end

   print("[.adminclr] Found " .. #instances .. " instances. Deleting...")
   local total = 0
   local batchSize = 5000
   for i = 1, #instances, batchSize do
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
   print("[.adminclr] Removed " .. total .. " instances.")
end

-- ===== .workspaceclr – deletes EVERYTHING in workspace =====
local function workspaceClear()
   local endpoint = getSyncAPI()
   if not endpoint then
      print("[.workspaceclr] Building Tools not found.")
      return
   end

   local instances = {}
   for _, child in ipairs(workspace:GetChildren()) do
      if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Tool") or child:IsA("Folder") then
         table.insert(instances, child)
      end
   end

   if #instances == 0 then
      print("[.workspaceclr] No instances to remove.")
      return
   end

   print("[.workspaceclr] Found " .. #instances .. " instances in workspace. Deleting in batches...")
   local total = 0
   local batchSize = 5000
   for i = 1, #instances, batchSize do
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
   print("[.workspaceclr] Removed " .. total .. " instances from workspace.")
end

-- ===== .trollclr – unanchor & disable collision for all Parts, Trusses, Seats =====
local function trollClear()
   local endpoint = getSyncAPI()
   if not endpoint then
      print("[.trollclr] Building Tools not found.")
      pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = "Troll Clear",
            Text = "Building Tools not found!",
            Duration = 3
         })
      end)
      return
   end

   local anchorList = {}
   local collisionList = {}

   for _, v in ipairs(workspace:GetDescendants()) do
      if v:IsA("BasePart") then
         local name = string.lower(v.Name)
         if name == "part" or name == "truss" or name == "seat" then
            table.insert(anchorList, {
               Part = v,
               CFrame = v.CFrame,
               Anchored = false
            })
            table.insert(collisionList, {
               Part = v,
               CanCollide = false
            })
         end
      end
   end

   if #anchorList == 0 then
      print("[.trollclr] No matching parts (Part, Truss, Seat) found.")
      pcall(function()
         StarterGui:SetCore("SendNotification", {
            Title = "Troll Clear",
            Text = "No matching parts found.",
            Duration = 3
         })
      end)
      return
   end

   print("[.trollclr] Found " .. #anchorList .. " parts to unanchor and disable collision.")

   local success, err = pcall(function()
      endpoint:InvokeServer("SyncAnchor", anchorList)
   end)
   if not success then
      warn("[.trollclr] SyncAnchor failed: " .. tostring(err))
   end

   success, err = pcall(function()
      endpoint:InvokeServer("SyncCollision", collisionList)
   end)
   if not success then
      warn("[.trollclr] SyncCollision failed: " .. tostring(err))
   end

   pcall(function()
      StarterGui:SetCore("SendNotification", {
         Title = "Troll Clear",
         Text = "Unanchored & disabled collision for " .. #anchorList .. " parts.",
         Duration = 3
      })
   end)
   print("[.trollclr] Done.")
end

-- ===== Auto Time Fix =====
local autoTimeFixEnabled = false
local lastTimeFixSent = false
task.spawn(function()
   while true do
      task.wait(5)
      if autoTimeFixEnabled then
         local timeOfDay = Lighting.TimeOfDay
         local hour = tonumber(string.sub(timeOfDay, 1, 2))
         if hour then
            local isNight = (hour >= 20 or hour < 6)
            if isNight and not lastTimeFixSent then
               sendMessage("time 12", "System")
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

-- ===== Ban monitoring (every 1.5s) =====
task.spawn(function()
   while true do
      task.wait(1.5)
      for _, username in ipairs(banMonitored) do
         local plr = resolveTarget(username)
         if plr and plr ~= "all" then
            local present = plr.Character and plr.Character.Parent == workspace
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
                     if resolveTarget(username) then
                        task.spawn(KickPlayer, username)
                     end
                  end)
                  banWasAbsent[username] = false
               end
            else
               banWasAbsent[username] = true
            end
         end
      end
   end
end)

-- ===== Monitoring others (protective) – with resolveTarget for each stored name =====
task.spawn(function()
   while true do
      task.wait(0.05)
      -- Clean up lists using resolveTarget to check if player still exists
      for i = #crashMonitored, 1, -1 do
         local plr = resolveTarget(crashMonitored[i])
         if not plr or plr == "all" then
            table.remove(crashMonitored, i)
         end
      end
      for i = #deathMonitored, 1, -1 do
         local plr = resolveTarget(deathMonitored[i])
         if not plr or plr == "all" then
            table.remove(deathMonitored, i)
         end
      end
      for i = #punishMonitored, 1, -1 do
         local plr = resolveTarget(punishMonitored[i])
         if not plr or plr == "all" then
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
         local plr = resolveTarget(jailMonitored[i])
         if not plr or plr == "all" then
            table.remove(jailMonitored, i)
         end
      end

      -- Crash
      for _, storedName in ipairs(crashMonitored) do
         local plr = resolveTarget(storedName)
         if plr and plr ~= "all" and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root and root.Anchored then
               local now = tick()
               local key = plr.Name .. "_thaw"
               if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
                  lastActionTime[key] = now
                  sendMessage("thaw " .. plr.Name, "System")
               end
            end
         end
      end

      -- Death
      for _, storedName in ipairs(deathMonitored) do
         local plr = resolveTarget(storedName)
         if plr and plr ~= "all" and plr.Character then
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health <= 0 then
               local now = tick()
               local key = plr.Name .. "_reset"
               if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
                  lastActionTime[key] = now
                  sendMessage("reset " .. plr.Name, "System")
               end
            end
         end
      end

      -- Punish
      for _, storedName in ipairs(punishMonitored) do
         local plr = resolveTarget(storedName)
         if plr and plr ~= "all" then
            local char = plr.Character
            local present = char and char.Parent == workspace
            local keyLower = plr.Name:lower()
            if not present then
               if not punishDisappearTime[keyLower] then
                  punishDisappearTime[keyLower] = tick()
                  punishUnpunishSent[keyLower] = false
                  punishResetSent[keyLower] = false
                  sendMessage("unpunish " .. plr.Name, "System")
                  punishUnpunishSent[keyLower] = true
               else
                  if not punishResetSent[keyLower] and tick() - punishDisappearTime[keyLower] >= 0.5 then
                     sendMessage("reset " .. plr.Name, "System")
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
               sendMessage("unjail me", "System")
            end
         end
      end

      -- Jail (others)
      local jailedCount = 0
      local totalMonitored = #jailMonitored
      for _, storedName in ipairs(jailMonitored) do
         local plr = resolveTarget(storedName)
         if plr and plr ~= "all" then
            local jailModel = workspace:FindFirstChild(plr.Name .. "'s jail")
            if jailModel then
               jailedCount = jailedCount + 1
               local now = tick()
               local key = plr.Name .. "_jail"
               if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
                  lastActionTime[key] = now
                  sendMessage("unjail " .. plr.Name, "System")
               end
            end
         end
      end
      if totalMonitored > 0 and jailedCount == totalMonitored then
         local now = tick()
         if now - jailAllCooldown >= jailAllCooldownTime then
            jailAllCooldown = now
            sendMessage("unjail others", "System")
         end
      else
         jailAllCooldown = 0
      end
   end
end)

-- ===== Add/remove helpers (these now accept partials and resolve) =====
local function addToMonitor(list, partial)
   local target = resolveTarget(partial)
   if not target then return false end
   if target == "all" then
      for _, plr in ipairs(Players:GetPlayers()) do
         if plr ~= LocalPlayer then
            local found = false
            for _, name in ipairs(list) do
               if name:lower() == plr.Name:lower() then
                  found = true
                  break
               end
            end
            if not found then
               table.insert(list, plr.Name)
            end
         end
      end
      return true
   else
      local name = target.Name
      for _, n in ipairs(list) do
         if n:lower() == name:lower() then
            return false
         end
      end
      table.insert(list, name)
      return true
   end
end

local function removeFromMonitor(list, partial)
   local target = resolveTarget(partial)
   if not target then return false end
   if target == "all" then
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
   else
      local name = target.Name
      for i, n in ipairs(list) do
         if n:lower() == name:lower() then
            table.remove(list, i)
            return true
         end
      end
      return false
   end
end

local function addToAllMonitors(partial)
   local a = addToMonitor(crashMonitored, partial)
   local b = addToMonitor(deathMonitored, partial)
   local c = addToMonitor(punishMonitored, partial)
   local d = addToMonitor(jailMonitored, partial)
   if a or b or c or d then
      print("[AntiAll] Now monitoring " .. partial .. " for all.")
   else
      print("[AntiAll] Already monitored.")
   end
end

local function removeFromAllMonitors(partial)
   local a = removeFromMonitor(crashMonitored, partial)
   local b = removeFromMonitor(deathMonitored, partial)
   local c = removeFromMonitor(punishMonitored, partial)
   local d = removeFromMonitor(jailMonitored, partial)
   if a or b or c or d then
      print("[AntiAll] Stopped monitoring all for " .. partial)
   else
      print("[AntiAll] Not monitored.")
   end
end

local function addJailMonitor(partial) return addToMonitor(jailMonitored, partial) end
local function removeJailMonitor(partial) return removeFromMonitor(jailMonitored, partial) end

local function addBanMonitor(partial)
   local target = resolveTarget(partial)
   if not target or target == "all" then return false end
   local name = target.Name
   local added = addToMonitor(banMonitored, partial)
   if added then
      local present = target.Character and target.Character.Parent == workspace
      banWasAbsent[name] = not present
   end
   return added
end

local function removeBanMonitor(partial)
   local target = resolveTarget(partial)
   if not target or target == "all" then return false end
   local name = target.Name
   local removed = removeFromMonitor(banMonitored, partial)
   if removed then
      banWasAbsent[name] = nil
   end
   return removed
end

-- ===== Misc toggles =====
local selfJailEnabled = true
MiscTab:CreateToggle({
   Name = "Unjail (self)",
   CurrentValue = true,
   Flag = "SelfJail",
   Callback = function(v) selfJailEnabled = v end
})

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
      notify("KOHLS ADMIN HOUSE X", "All features reloaded")
      task.wait(0.1)
      notify(".afk", ".afk loaded (partial support)")
      task.wait(0.1)
      notify(".kick", ".kick loaded (partial support)")
      task.wait(0.1)
      notify(".gearbanme", ".gearbanme manual loaded")
      task.wait(0.1)
      notify(".gearban monitor", ".gearban/.ungearban monitor loaded (ON by default)")
      task.wait(0.1)
      notify(".clr", ".clr now deletes ALL BaseParts (except Baseplate) + Tools + Models named 'Model'")
      task.wait(0.1)
      notify(".adminclr", ".adminclr now deletes Regen too")
      task.wait(0.1)
      notify(".workspaceclr", "NEW – deletes EVERYTHING in workspace")
      task.wait(0.1)
      notify(".trollclr", "NEW – unanchor & disable collision for Parts/Trusses/Seats")
      task.wait(0.1)
      notify("Troll Tab", "Fire Click Detector button (no cooldown)")
      task.wait(0.1)
      notify("Anti-Crash", "Anti-Crash active")
      task.wait(0.1)
      notify("Anti-Death", "Anti-Death active")
      task.wait(0.1)
      notify("Anti-Punish", "Anti-Punish active")
      task.wait(0.1)
      notify("Jail Monitor", "Self-Unjail active")
      task.wait(0.1)
      notify("Ban System", ".ban / .unban loaded (partial support)")
      task.wait(0.1)
      notify("Monitor Commands", "Use 'all' to monitor everyone")
      task.wait(0.1)
      notify("Killbrick Immunity", "Active – covers all parts in obby")
      if silentMode then
         notify("Silent Mode", "Commands are hidden from chat")
      end
   end
})

MiscTab:CreateButton({
   Name = "Show Commands (console)",
   Callback = function()
      print("===== KHOLS ADMIN COMMANDS (partial name support) =====")
      print(".afk <partial> – freeze, god, ff")
      print(".unafk <partial> – reset")
      print(".kick <partial> – gear, give, bring, freeze, size nan")
      print(".gearbanme <partial> – manual gearban")
      print("Gearban Monitor: .gearban <partial> (start), .ungearban <partial> (stop), .listgear")
      print(".clr – DELETE ALL BASEPARTS (except Baseplate) + Tools (except Building Tools) + Models named 'Model'")
      print(".adminclr – delete House, Obby Box, Obby, Baseplate, Grids, Regen")
      print(".workspaceclr – DELETE EVERYTHING IN WORKSPACE (via SyncAPI)")
      print(".trollclr – unanchor & disable collision for all Parts, Trusses, Seats")
      print(".stopclr – stop ongoing .clr")
      print(".anticrash <partial> – monitor anchored (use 'all' for everyone)")
      print(".unanticrash <partial> – stop monitoring")
      print(".antideath <partial> – monitor death (health ≤ 0)")
      print(".unantideath <partial> – stop monitoring")
      print(".antipunish <partial> – monitor model removal (auto unpunish + reset)")
      print(".unantipunish <partial> – stop monitoring")
      print(".antiall <partial> – monitor crash, death, punish, and jail")
      print(".unantiall <partial> – stop all monitoring")
      print(".antijail <partial> – monitor jail model in workspace")
      print(".unantijail <partial> – stop jail monitoring")
      print(".ban <partial> – kick + monitor rejoin (sends .kick)")
      print(".unban <partial> – stop ban monitoring")
      print("Self toggles: .antipunish (self), .ppunish (self)")
      print("Silent mode: toggles hiding all commands from chat")
      print("Press K to toggle GUI")
      print("=================================")
   end
})

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
      if mover and mover.Parent then
         mover.Enabled = wasEnabled
      end
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
            if child:IsA("TouchInterest") then
               child:Destroy()
            end
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
   for part in pairs(originalProps) do
      revertOriginalProperties(part)
   end
   originalProps = {}
end

MiscTab:CreateToggle({
   Name = "Killbrick Immunity",
   CurrentValue = true,
   Flag = "KillbrickImmunity",
   Callback = function(v)
      killbrickEnabled = v
      if v then
         applyKillbrickImmunity()
      else
         revertKillbrickImmunity()
      end
   end
})
applyKillbrickImmunity()
task.spawn(function()
   while true do
      task.wait(5)
      if killbrickEnabled then
         applyKillbrickImmunity()
      end
   end
end)

-- ===== UI =====
local afkToggle = CommandsTab:CreateToggle({
   Name = "AFK Commands (.afk / .unafk)",
   CurrentValue = true,
   Flag = "AFK_Enabled",
   Callback = function(v) afkEnabled = v end
})

local kickToggle = CommandsTab:CreateToggle({
   Name = "Kick Command (.kick)",
   CurrentValue = true,
   Flag = "Kick_Enabled",
   Callback = function(v) kickEnabled = v end
})

local antiPunishSelfToggle = CommandsTab:CreateToggle({
   Name = "Self Anti‑Punish (sends 're' on removal)",
   CurrentValue = true,
   Flag = "AntiPunishSelf",
   Callback = function(v)
      antiPunishSelfEnabled = v
      if not v then
         punishSent = true
         modelExists = false
      end
   end
})

local antiDeathSelfToggle = CommandsTab:CreateToggle({
   Name = "Self Anti‑Death (sends 're' on death)",
   CurrentValue = true,
   Flag = "AntiDeathSelf",
   Callback = function(v) antiDeathSelfEnabled = v end
})

local antiCrashSelfToggle = CommandsTab:CreateToggle({
   Name = "Self Anti‑Crash (thaw me when anchored)",
   CurrentValue = true,
   Flag = "AntiCrashSelf",
   Callback = function(v) antiCrashSelfEnabled = v end
})

local clrToggle = CommandsTab:CreateToggle({
   Name = "Clear Parts (.clr)",
   CurrentValue = true,
   Flag = "ClearParts",
   Callback = function(v) clrEnabled = v end
})

CommandsTab:CreateButton({ Name = "Hide GUI", Callback = function() Rayfield:SetVisibility(false) end })
CommandsTab:CreateButton({ Name = "Show GUI", Callback = function() Rayfield:SetVisibility(true) end })
CommandsTab:CreateButton({ Name = "Destroy GUI", Callback = function() Rayfield:Destroy() end })

-- ============================================================
-- ===== LOADERS TAB – Novoline, Infinite Yield, Explorer++, Cobalt Spy =====
-- ============================================================

LoadersTab:CreateButton({
   Name = "Novoline",
   Callback = function()
      loadstring(game:HttpGet("https://novoline.pro/"))()
   end
})

LoadersTab:CreateButton({
   Name = "Infinite Yield",
   Callback = function()
      loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
   end
})

LoadersTab:CreateButton({
   Name = "Explorer ++",
   Callback = function()
      loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))()
   end
})

LoadersTab:CreateButton({
   Name = "Cobalt Spy",
   Callback = function()
      loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))()
   end
})

-- ============================================================
-- ===== COLOR‑BASED ADMIN PAD CLAIMER & MONITOR =====
-- Claims ONE pad, monitors it, and reclaims only when lost.
-- ============================================================

local playerName = LocalPlayer.Name
local padMonitorRunning = true
local claimedPad = nil

-- Path to pads
local terrain = workspace:FindFirstChild("Terrain")
if terrain then
   local gameFolder = terrain:FindFirstChild("_Game")
   if gameFolder then
      local adminFolder = gameFolder:FindFirstChild("Admin")
      if adminFolder then
         local pads = adminFolder:FindFirstChild("Pads")
         if pads then
            local padChildren = pads:GetChildren()
            if #padChildren >= 9 then
               local clickDetector = adminFolder:FindFirstChild("Regen") and adminFolder.Regen:FindFirstChild("ClickDetector")

               local function getHRP()
                  local char = LocalPlayer.Character
                  if char then
                     return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
                  end
                  return nil
               end

               local function fireTouchOnPad(pad)
                  local head = pad:FindFirstChild("Head")
                  if not head then return false end
                  local hrp = getHRP()
                  if not hrp then return false end
                  pcall(function()
                     firetouchinterest(head, hrp, 0)
                     task.wait(0.1)
                     firetouchinterest(head, hrp, 1)
                  end)
                  return true
               end

               local function renamePad(pad)
                  if pad and pad:IsA("Model") then
                     pad.Name = playerName .. "'s admin"
                     return true
                  end
                  return false
               end

               local function isGreenPad(pad)
                  local head = pad:FindFirstChild("Head")
                  if head and head:IsA("BasePart") then
                     return head.BrickColor == BrickColor.Green()
                  end
                  for _, part in ipairs(pad:GetDescendants()) do
                     if part:IsA("BasePart") and part.BrickColor == BrickColor.Green() then
                        return true
                     end
                  end
                  return false
               end

               local function isRedPad(pad)
                  local head = pad:FindFirstChild("Head")
                  if head and head:IsA("BasePart") then
                     return head.BrickColor == BrickColor.Red()
                  end
                  for _, part in ipairs(pad:GetDescendants()) do
                     if part:IsA("BasePart") and part.BrickColor == BrickColor.Red() then
                        return true
                     end
                  end
                  return false
               end

               local function isOurPad(pad)
                  return pad and pad.Name == playerName .. "'s admin"
               end

               local function findGreenPad(skipPad)
                  for i, pad in ipairs(padChildren) do
                     if pad ~= skipPad and isGreenPad(pad) and not isOurPad(pad) then
                        return i, pad
                     end
                  end
                  return nil, nil
               end

               local function fireClickDetector()
                  if not clickDetector then
                     print("[PadClaim] ClickDetector not found")
                     return false
                  end
                  clickDetector.MaxActivationDistance = 99999
                  pcall(function()
                     fireclickdetector(clickDetector)
                  end)
                  print("[PadClaim] ClickDetector fired.")
                  return true
               end

               local function claimPad(pad)
                  if not pad then return false end
                  if fireTouchOnPad(pad) then
                     if renamePad(pad) then
                        print("[PadClaim] Claimed pad: " .. pad.Name)
                        return true
                     end
                  end
                  return false
               end

               -- Claim one green pad; if none, fire detector and retry (with timeout)
               local function claimGreenPad(skipPad)
                  local idx, pad = findGreenPad(skipPad)
                  if idx then
                     if claimPad(pad) then
                        return pad
                     end
                  else
                     print("[PadClaim] No green pad. Firing ClickDetector and waiting.")
                     if fireClickDetector() then
                        local start = tick()
                        while tick() - start < 4 do
                           task.wait(0.3)
                           local idx2, pad2 = findGreenPad(skipPad)
                           if idx2 then
                              if claimPad(pad2) then
                                 return pad2
                              end
                           end
                        end
                        print("[PadClaim] Timeout waiting for green pad.")
                     end
                  end
                  return nil
               end

               -- Monitor loop – only reclaim if the pad is no longer ours
               task.spawn(function()
                  claimedPad = claimGreenPad(nil)
                  if claimedPad then
                     print("[PadClaim] Initial claim successful.")
                     pcall(function()
                        StarterGui:SetCore("SendNotification", {
                           Title = "Admin Pad",
                           Text = "Pad claimed! Monitoring started.",
                           Duration = 3
                        })
                     end)
                  else
                     print("[PadClaim] Initial claim failed; will retry.")
                  end

                  while padMonitorRunning do
                     task.wait(0.3)

                     if claimedPad and claimedPad.Parent == pads then
                        if isOurPad(claimedPad) then
                           continue
                        else
                           print("[PadClaim] Our pad lost (name changed). Reclaiming.")
                           local newPad = claimGreenPad(claimedPad)
                           if newPad then
                              claimedPad = newPad
                              print("[PadClaim] Reclaimed a new pad.")
                              pcall(function()
                                 StarterGui:SetCore("SendNotification", {
                                    Title = "Admin Pad",
                                    Text = "Reclaimed a new pad!",
                                    Duration = 3
                                 })
                              end)
                           else
                              claimedPad = nil
                           end
                        end
                     else
                        print("[PadClaim] No claimed pad; looking for green pad.")
                        local newPad = claimGreenPad(nil)
                        if newPad then
                           claimedPad = newPad
                           print("[PadClaim] Claimed a new pad.")
                           pcall(function()
                              StarterGui:SetCore("SendNotification", {
                                 Title = "Admin Pad",
                                 Text = "Claimed a new pad!",
                                 Duration = 3
                              })
                           end)
                        end
                     end
                  end
               end)

               print("[PadClaim] Monitor started – will claim ONE pad and keep it.")
            else
               print("[PadClaim] Less than 9 pads found, feature disabled.")
            end
         else
            print("[PadClaim] Pads folder not found.")
         end
      else
         print("[PadClaim] Admin folder not found.")
      end
   else
      print("[PadClaim] _Game not found.")
   end
else
   print("[PadClaim] Terrain not found.")
end

-- ===== Troll Tab – Fire Click Detector ONLY (no cooldown) =====
TrollTab:CreateButton({
   Name = "Fire Click Detector",
   Callback = function()
      local terrain = workspace:FindFirstChild("Terrain")
      if terrain then
         local gameFolder = terrain:FindFirstChild("_Game")
         if gameFolder then
            local adminFolder = gameFolder:FindFirstChild("Admin")
            if adminFolder then
               local regen = adminFolder:FindFirstChild("Regen")
               if regen then
                  local cd = regen:FindFirstChild("ClickDetector")
                  if cd and cd:IsA("ClickDetector") then
                     cd.MaxActivationDistance = 99999
                     pcall(function()
                        fireclickdetector(cd)
                     end)
                     print("[Troll] Regen ClickDetector fired.")
                  else
                     print("[Troll] ClickDetector not found.")
                  end
               else
                  print("[Troll] Regen not found.")
               end
            else
               print("[Troll] Admin not found.")
            end
         else
            print("[Troll] _Game not found.")
         end
      else
         print("[Troll] Terrain not found.")
      end
   end
})

-- ===== Chat hooks (all commands) with partial matching =====
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
   local args = {...}
   if self == ChatEvent and getnamecallmethod() == "FireServer" and typeof(args[1]) == "string" then
      local msg = string.lower(args[1])
      local target

      -- Self toggles
      if msg == ".antipunish" then
         antiPunishSelfEnabled = true
         antiPunishSelfToggle:Set(true)
         if silentMode then return nil end
      elseif msg == ".ppunish" then
         antiPunishSelfEnabled = false
         antiPunishSelfToggle:Set(false)
         if silentMode then return nil end
      elseif msg == ".stopclr" then
         clrStop = true
         print("[.clr] Stop requested.")
         if silentMode then return nil end

      -- .workspaceclr
      elseif msg == ".workspaceclr" then
         task.spawn(workspaceClear)
         if silentMode then return nil end

      -- .trollclr
      elseif msg == ".trollclr" then
         task.spawn(trollClear)
         if silentMode then return nil end

      -- .afk
      elseif string.sub(msg, 1, 4) == ".afk" then
         local rest = string.sub(msg, 5)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(SetAFK, target)
         if silentMode then return nil end

      -- .unafk
      elseif string.sub(msg, 1, 6) == ".unafk" then
         local rest = string.sub(msg, 7)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(SetUnAFK, target)
         if silentMode then return nil end

      -- .kick
      elseif string.sub(msg, 1, 5) == ".kick" then
         local rest = string.sub(msg, 6)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(KickPlayer, target)
         if silentMode then return nil end

      -- .gearbanme (manual gearban)
      elseif string.sub(msg, 1, 10) == ".gearbanme " then
         local rest = string.sub(msg, 11)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or rest
         if target == "" then target = "me" end
         task.spawn(GearbanManual, target)
         if silentMode then return nil end

      -- .gearban (monitor start)
      elseif string.sub(msg, 1, 9) == ".gearban " then
         if gearbanMonitorEnabled then
            target = string.sub(args[1], 10)
            target = target:gsub("^%s+", ""):gsub("%s+$", "")
            if target ~= "" then
               addGearbanMonitor(target)
            else
               print("[Gearban Monitor] Please specify a username.")
            end
         else
            print("[Gearban Monitor] Disabled. Enable the toggle first.")
         end
         if silentMode then return nil end

      -- .ungearban (stop monitoring)
      elseif string.sub(msg, 1, 11) == ".ungearban " then
         if gearbanMonitorEnabled then
            target = string.sub(args[1], 12)
            target = target:gsub("^%s+", ""):gsub("%s+$", "")
            if target ~= "" then
               removeGearbanMonitor(target)
            else
               print("[Gearban Monitor] Please specify a username.")
            end
         else
            print("[Gearban Monitor] Disabled. Enable the toggle first.")
         end
         if silentMode then return nil end

      -- .listgear
      elseif msg == ".listgear" then
         if gearbanMonitorEnabled then
            if #gearbanMonitored == 0 then
               print("[Gearban Monitor] No users being monitored.")
            else
               print("[Gearban Monitor] Monitored users:")
               for _, name in ipairs(gearbanMonitored) do
                  print(" - " .. name)
               end
            end
         else
            print("[Gearban Monitor] Disabled. Enable the toggle first.")
         end
         if silentMode then return nil end

      -- .clr (now uses clearAll)
      elseif msg == ".clr" then
         task.spawn(function()
            if clrRunning then return end
            clrRunning = true
            clearAll()
            clrRunning = false
         end)
         if silentMode then return nil end

      -- .adminclr
      elseif msg == ".adminclr" then
         task.spawn(adminClear)
         if silentMode then return nil end

      -- Monitor commands (partial support)
      elseif string.sub(msg, 1, 11) == ".anticrash " then
         local username = string.sub(args[1], 12)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addToMonitor(crashMonitored, username)
            print("[AntiCrash] Now monitoring " .. username)
         else
            print("[AntiCrash] Please specify a username or 'all'.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 13) == ".unanticrash " then
         local username = string.sub(args[1], 14)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            removeFromMonitor(crashMonitored, username)
            print("[AntiCrash] Stopped monitoring " .. username)
         else
            print("[AntiCrash] Please specify a username.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 11) == ".antideath " then
         local username = string.sub(args[1], 12)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addToMonitor(deathMonitored, username)
            print("[AntiDeath] Now monitoring " .. username)
         else
            print("[AntiDeath] Please specify a username or 'all'.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 13) == ".unantideath " then
         local username = string.sub(args[1], 14)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            removeFromMonitor(deathMonitored, username)
            print("[AntiDeath] Stopped monitoring " .. username)
         else
            print("[AntiDeath] Please specify a username.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 12) == ".antipunish " then
         local username = string.sub(args[1], 13)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addToMonitor(punishMonitored, username)
            print("[AntiPunish] Now monitoring " .. username)
         else
            print("[AntiPunish] Please specify a username or 'all'.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 14) == ".unantipunish " then
         local username = string.sub(args[1], 15)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            removeFromMonitor(punishMonitored, username)
            print("[AntiPunish] Stopped monitoring " .. username)
         else
            print("[AntiPunish] Please specify a username.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 9) == ".antiall " then
         local username = string.sub(args[1], 10)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addToAllMonitors(username)
         else
            print("[AntiAll] Please specify a username or 'all'.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 11) == ".unantiall " then
         local username = string.sub(args[1], 12)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            removeFromAllMonitors(username)
         else
            print("[AntiAll] Please specify a username.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 10) == ".antijail " then
         local username = string.sub(args[1], 11)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            addJailMonitor(username)
            print("[AntiJail] Now monitoring " .. username)
         else
            print("[AntiJail] Please specify a username or 'all'.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 12) == ".unantijail " then
         local username = string.sub(args[1], 13)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            removeJailMonitor(username)
            print("[AntiJail] Stopped monitoring " .. username)
         else
            print("[AntiJail] Please specify a username.")
         end
         if silentMode then return nil end

      -- .ban / .unban
      elseif string.sub(msg, 1, 5) == ".ban " then
         local username = string.sub(args[1], 6)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            local plr = resolveTarget(username)
            if plr and plr ~= "all" then
               task.spawn(KickPlayer, plr.Name)
            else
               print("[Ban] Player not found or 'all', will monitor anyway.")
            end
            if addBanMonitor(username) then
               print("[Ban] Now monitoring " .. username)
            else
               print("[Ban] Already monitoring " .. username)
            end
         else
            print("[Ban] Please specify a username.")
         end
         if silentMode then return nil end

      elseif string.sub(msg, 1, 7) == ".unban " then
         local username = string.sub(args[1], 8)
         username = username:gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if removeBanMonitor(username) then
               print("[Ban] Stopped monitoring " .. username)
            else
               print("[Ban] Not monitored.")
            end
         else
            print("[Ban] Please specify a username.")
         end
         if silentMode then return nil end
      end
   end
   return old and old(self, ...)
end)

-- ===== Auto‑send "startergive self" =====
task.spawn(function()
   task.wait(1)
   sendMessage("startergive self", "System")
end)

-- ===== Notification =====
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
      {"KOHLS ADMIN HOUSE X", "Public version loaded!"},
      {".afk", ".afk loaded (partial support)"},
      {".kick", ".kick loaded (partial support)"},
      {".gearbanme", ".gearbanme manual loaded"},
      {"Gearban Monitor", ".gearban/.ungearban monitor loaded (ON by default)"},
      {".clr", ".clr now deletes ALL BaseParts (except Baseplate) + Tools + Models named 'Model'"},
      {".adminclr", ".adminclr now deletes Regen too"},
      {".workspaceclr", "NEW – deletes EVERYTHING in workspace"},
      {".trollclr", "NEW – unanchor & disable collision for Parts/Trusses/Seats"},
      {"Troll Tab", "Fire Click Detector button (no cooldown)"},
      {"Anti-Crash", "Anti-Crash active"},
      {"Anti-Death", "Anti-Death active"},
      {"Anti-Punish", "Anti-Punish active"},
      {"Jail Monitor", "Self-Unjail active"},
      {"Ban System", ".ban / .unban loaded (partial support)"},
      {"Monitor Commands", "Use 'all' to monitor everyone"},
      {"Killbrick Immunity", "Active – covers all parts in obby"},
      {"Silent Mode", "Toggle in Misc to hide commands"},
      {"Admin Pad", "Claims ONE pad and monitors it"},
      {"Loaders Tab", "Novoline, Infinite Yield, Explorer++, Cobalt Spy added"}
   }
   for _, notif in ipairs(notifications) do
      notify(notif[1], notif[2])
      task.wait(0.1)
   end
end)

print("KOHLS ADMIN HOUSE X loaded. Troll tab: 'Fire Click Detector' (instant)")
print("Type .workspaceclr to delete everything in workspace.")
print("Type .trollclr to unanchor & disable collision for Parts/Trusses/Seats.")
print(".clr now deletes ALL BaseParts except Baseplate, plus Tools and Models named 'Model'.")
print("All commands support partial display name matching.")
print("Loaders tab: Novoline, Infinite Yield, Explorer++, Cobalt Spy.")
print("Press K to toggle GUI.")
