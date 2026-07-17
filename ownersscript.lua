-- ============================================
-- KOHLS ADMIN HOUSE X – CUSTOM KICK SEQUENCE
-- ============================================
-- Kick: blind victim → freeze victim → size victim nan → freeze me → sword (grant) → equip → drop → move to victim HRP → thaw me
-- All other features (monitors, clear, killbrick, loaders, pad claimer, troll, etc.) unchanged.
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

local CommandsTab = Window:CreateTab("Commands", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)
local TrollTab = Window:CreateTab("Troll", 4483362458)
local LoadersTab = Window:CreateTab("Loaders (novo etc)", 4483362458)

-- Silent Commands Toggle
local silentMode = false
MiscTab:CreateToggle({
   Name = "Silent Commands",
   CurrentValue = false,
   Flag = "SilentMode",
   Callback = function(v) silentMode = v end
})

-- Manual Gearban Toggle
local gearbanEnabled = true
CommandsTab:CreateToggle({
   Name = "Manual Gearban (.gearbanme)",
   CurrentValue = true,
   Flag = "GearbanEnabled",
   Callback = function(v) gearbanEnabled = v end
})

-- Gearban Monitor Toggle
local gearbanMonitorEnabled = true
CommandsTab:CreateToggle({
   Name = "Gearban Monitor (.gearban / .ungearban)",
   CurrentValue = true,
   Flag = "GearbanMonitor",
   Callback = function(v) gearbanMonitorEnabled = v end
})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local ChatEvent = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents"):WaitForChild("SayMessageRequest")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local afkRunning = false
local MY_MODEL_NAME = LocalPlayer.Name
local EXECUTOR_NAME = LocalPlayer.Name

-- Toggle states
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

-- "all" monitoring flags and PlayerAdded connections
local crashMonitorAll = false
local deathMonitorAll = false
local punishMonitorAll = false
local jailMonitorAll = false
local crashConn, deathConn, punishConn, jailConn = nil, nil, nil, nil

-- Gearban monitor
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

-- Helper: send message
local function sendMessage(msg, channel)
   if silentMode then channel = "System" else channel = channel or "All" end
   ChatEvent:FireServer(msg, channel)
end

-- ===== FIX: Repair Building Tools UI =====
local function repairBuildingTools()
   local char = LocalPlayer.Character
   if not char then return end
   local bt = char:FindFirstChild("Building Tools")
   if not bt then return end
   local humanoid = char:FindFirstChildOfClass("Humanoid")
   if not humanoid then return end
   humanoid:UnequipTool(bt)
   task.wait(0.05)
   humanoid:EquipTool(bt)
end

-- Partial matcher: matches display name, then username
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
   if #matches == 1 then return matches[1]
   elseif #matches > 1 then
      print("[PartialMatcher] Multiple display matches, using first: " .. matches[1].Name)
      return matches[1]
   end
   for _, plr in ipairs(Players:GetPlayers()) do
      if string.lower(plr.Name) == partial then return plr end
   end
   return nil
end

-- ===== getSyncAPI (auto‑equip Building Tools) =====
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

-- Helper: ensure tool has PrimaryPart (Handle or first BasePart)
local function ensurePrimaryPart(tool)
   if not tool then return nil end
   if tool.PrimaryPart then return tool.PrimaryPart end
   local primary = tool:FindFirstChild("Handle")
   if not primary or not primary:IsA("BasePart") then
      for _, child in ipairs(tool:GetChildren()) do
         if child:IsA("BasePart") then
            primary = child
            break
         end
      end
   end
   if primary then
      tool.PrimaryPart = primary
      return primary
   end
   return nil
end

-- Helper: unanchor all BaseParts in a model
local function unanchorAll(model)
   for _, part in ipairs(model:GetDescendants()) do
      if part:IsA("BasePart") then
         part.Anchored = false
      end
   end
end

-- Helper: break all Motor6D and Weld connections on a tool
local function breakWelds(tool)
   for _, child in ipairs(tool:GetDescendants()) do
      if child:IsA("Motor6D") or child:IsA("Weld") then
         child:Destroy()
      end
   end
end

-- Helper: get BasePart (Handle) from a tool
local function getBasePart(tool)
   if not tool then return nil end
   local part = tool:FindFirstChild("Handle")
   if part and part:IsA("BasePart") then
      return part
   end
   for _, child in ipairs(tool:GetChildren()) do
      if child:IsA("BasePart") then
         return child
      end
   end
   return nil
end

-- Helper: move tool using SyncMove (Cobalt format) with repair
local function moveToolWithSyncMove(tool, targetCFrame)
   if not tool then return false end
   local endpoint = getSyncAPI()
   if not endpoint then
      if tool.PrimaryPart then
         tool:SetPrimaryPartCFrame(targetCFrame)
      else
         for _, part in ipairs(tool:GetDescendants()) do
            if part:IsA("BasePart") then part.CFrame = targetCFrame end
         end
      end
      repairBuildingTools()
      return true
   end
   local handle = getBasePart(tool)
   if not handle then
      if tool.PrimaryPart then tool:SetPrimaryPartCFrame(targetCFrame) end
      repairBuildingTools()
      return true
   end
   local moveList = {
      { Part = handle, CFrame = targetCFrame },
      { Pivot = targetCFrame, Model = tool }
   }
   local success, err = pcall(function()
      endpoint:InvokeServer("SyncMove", moveList)
   end)
   repairBuildingTools()
   if not success then
      warn("[Kick] SyncMove failed: " .. tostring(err))
      if tool.PrimaryPart then tool:SetPrimaryPartCFrame(targetCFrame) end
      return false
   end
   return true
end

-- ===== GEARBAN MONITOR =====
local function gearbanCheckBackpack(username)
   local plr = resolveTarget(username)
   if not plr or plr == "all" then return end
   local backpack = plr:FindFirstChildOfClass("Backpack")
   if not backpack then return end
   local hasItems = false
   for _, child in ipairs(backpack:GetChildren()) do
      if child:IsA("Tool") then hasItems = true; break end
   end
   if hasItems then
      local now = tick()
      if not gearbanLastSent[username] or now - gearbanLastSent[username] >= 5 then
         gearbanLastSent[username] = now
         sendMessage(".ungear " .. plr.Name, "System")
      end
   end
end

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

local function addGearbanMonitor(username)
   local target = resolveTarget(username)
   if not target or target == "all" then return false end
   local name = target.Name
   for _, n in ipairs(gearbanMonitored) do
      if n:lower() == name:lower() then return false end
   end
   table.insert(gearbanMonitored, name)
   print("[Gearban] Monitoring " .. name)
   return true
end

local function removeGearbanMonitor(username)
   local target = resolveTarget(username)
   if not target or target == "all" then return false end
   local name = target.Name
   for i, n in ipairs(gearbanMonitored) do
      if n:lower() == name:lower() then
         table.remove(gearbanMonitored, i)
         gearbanLastSent[name] = nil
         print("[Gearban] Stopped " .. name)
         return true
      end
   end
   return false
end

-- ===== SELF ANTI‑CRASH =====
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

-- ===== SELF ANTI‑PUNISH =====
task.spawn(function()
   while true do
      task.wait(0.2)
      if deathRecently then
         if tick() - lastDeathSelfTime > 1.0 then deathRecently = false else continue end
      end
      local found = false
      for _, obj in ipairs(workspace:GetChildren()) do
         if obj:IsA("Model") and obj.Name == LocalPlayer.Name then
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

-- ===== SELF ANTI‑DEATH =====
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

-- ===== COMMANDS =====

-- .afk
local function SetAFK(target)
   if not afkEnabled or afkRunning then return end
   local plr = resolveTarget(target)
   if not plr or plr == "all" then print("[AFK] Invalid target.") return end
   afkRunning = true
   sendMessage("freeze " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("god " .. plr.Name, "System")
   task.wait(0.05)
   sendMessage("ff " .. plr.Name, "System")
   afkRunning = false
end

-- .unafk
local function SetUnAFK(target)
   if not afkEnabled or afkRunning then return end
   local plr = resolveTarget(target)
   if not plr or plr == "all" then print("[UNAFK] Invalid target.") return end
   afkRunning = true
   sendMessage("reset " .. plr.Name, "System")
   afkRunning = false
end

-- ===== CUSTOM KICK SEQUENCE =====
local function KickPlayer(target)
   if not kickEnabled or afkRunning then return end
   afkRunning = true

   local success, err = pcall(function()
      local plr = resolveTarget(target)
      if not plr or plr == "all" then
         error("Invalid target.")
      end

      -- 1. blind victim
      sendMessage("blind " .. plr.Name, "System")
      task.wait(0.02)

      -- 2. freeze victim
      sendMessage("freeze " .. plr.Name, "System")
      task.wait(0.02)

      -- 3. size victim nan
      sendMessage("size " .. plr.Name .. " nan", "System")
      task.wait(0.02)

      -- 4. freeze me (disable anti‑crash first)
      local oldAntiCrash = antiCrashSelfEnabled
      antiCrashSelfEnabled = false
      sendMessage("freeze me", "System")
      task.wait(0.02)

      -- 5. sword me (grant one LinkedSword)
      sendMessage("sword", "System")
      task.wait(0.1)

      -- Wait up to 3 seconds for sword to appear
      local backpack = LocalPlayer.Backpack
      local sword = nil
      for i = 1, 30 do
         sword = backpack:FindFirstChild("LinkedSword")
         if sword then break end
         task.wait(0.1)
      end
      if not sword then
         error("No LinkedSword found after waiting.")
      end

      -- 6. Equip, drop, move sword to victim's HRP
      local char = LocalPlayer.Character
      if not char then error("No character.") end
      local humanoid = char:FindFirstChildOfClass("Humanoid")
      if not humanoid then error("No Humanoid.") end

      humanoid:EquipTool(sword)
      task.wait(0.1)
      local equipped = char:FindFirstChild("LinkedSword")
      if not equipped then
         error("Failed to equip sword.")
      end

      equipped.Parent = Workspace
      task.wait(0.05)
      breakWelds(equipped)

      local victimHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
      if not victimHRP then
         error("Victim has no HRP.")
      end
      local targetCFrame = victimHRP.CFrame * CFrame.new(0, 0, 0)  -- exactly on HRP
      moveToolWithSyncMove(equipped, targetCFrame)
      unanchorAll(equipped)

      -- 7. Thaw me and re‑enable anti‑crash
      sendMessage("thaw me", "System")
      antiCrashSelfEnabled = oldAntiCrash
      repairBuildingTools()
   end)

   -- Always reset afkRunning
   afkRunning = false
   if not success then
      warn("[Kick] Error: " .. tostring(err))
      antiCrashSelfEnabled = true
      sendMessage("thaw me", "System")
      repairBuildingTools()
   end
end

-- .gearbanme
local function GearbanManual(target)
   if not gearbanEnabled then print("[Gearban] Disabled.") return end
   if afkRunning then return end
   local plr = resolveTarget(target)
   if not plr or plr == "all" then print("[Gearban] Invalid target.") return end
   afkRunning = true
   pcall(function()
      StarterGui:SetCore("SendNotification", { Title = "Gearban", Text = "Click on victim to use portable!", Duration = 3 })
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

-- ===== CLEAR FUNCTIONS (with repair) =====
local function clearAll()
   if not clrEnabled then print("[.clr] Disabled.") return end
   clrStop = false
   local endpoint = getSyncAPI()
   if not endpoint then
      print("[.clr] Building Tools not found.")
      repairBuildingTools()
      return
   end
   local targetNames = {"Part", "Truss", "Seat"}
   local instances = {}
   for _, v in pairs(workspace:GetDescendants()) do
      if v:IsA("BasePart") then
         local nameLower = string.lower(v.Name)
         for _, tName in ipairs(targetNames) do
            if nameLower == string.lower(tName) then
               table.insert(instances, v)
               break
            end
         end
      end
   end
   if #instances == 0 then
      print("[.clr] No matching parts found.")
      pcall(function()
         StarterGui:SetCore("SendNotification", { Title = ".clr", Text = "No matching parts found.", Duration = 3 })
      end)
      repairBuildingTools()
      return
   end
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
      if success then total = total + #batch end
      task.wait(0.01)
   end
   if clrStop then print("[.clr] Halted. Removed " .. total .. ".")
   else
      print("[.clr] Removed " .. total .. " instances.")
      pcall(function()
         StarterGui:SetCore("SendNotification", { Title = ".clr", Text = "Removed " .. total .. " Part/Truss/Seat parts.", Duration = 3 })
      end)
   end
   repairBuildingTools()
end

local function adminClear()
   local endpoint = getSyncAPI()
   if not endpoint then print("[.adminclr] Building Tools not found.") return end
   local targetNames = {"House", "Obby Box", "Obby", "Baseplate", "Grids", "Regen"}
   local instances = {}
   for _, v in pairs(workspace:GetDescendants()) do
      if v:IsA("Model") or v:IsA("BasePart") then
         for _, name in ipairs(targetNames) do
            if v.Name == name then table.insert(instances, v); break end
         end
      end
   end
   if #instances == 0 then print("[.adminclr] No matching instances found.") return end
   print("[.adminclr] Found " .. #instances .. " instances.")
   local total = 0
   local batchSize = 5000
   for i = 1, #instances, batchSize do
      local batch = {}
      for j = i, math.min(i + batchSize - 1, #instances) do table.insert(batch, instances[j]) end
      local success = pcall(function() endpoint:InvokeServer("Remove", batch) end)
      if success then total = total + #batch end
      task.wait(0.01)
   end
   print("[.adminclr] Removed " .. total .. " instances.")
   repairBuildingTools()
end

local function workspaceClear()
   local endpoint = getSyncAPI()
   if not endpoint then print("[.workspaceclr] Building Tools not found.") return end
   local instances = {}
   for _, child in ipairs(workspace:GetChildren()) do
      if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Tool") or child:IsA("Folder") then
         table.insert(instances, child)
      end
   end
   if #instances == 0 then print("[.workspaceclr] No instances to remove.") return end
   print("[.workspaceclr] Found " .. #instances .. " instances.")
   local total = 0
   local batchSize = 5000
   for i = 1, #instances, batchSize do
      local batch = {}
      for j = i, math.min(i + batchSize - 1, #instances) do table.insert(batch, instances[j]) end
      local success = pcall(function() endpoint:InvokeServer("Remove", batch) end)
      if success then total = total + #batch end
      task.wait(0.01)
   end
   print("[.workspaceclr] Removed " .. total .. " instances.")
   repairBuildingTools()
end

local function trollClear()
   local endpoint = getSyncAPI()
   if not endpoint then
      print("[.trollclr] Building Tools not found.")
      pcall(function()
         StarterGui:SetCore("SendNotification", { Title = "Troll Clear", Text = "Building Tools not found!", Duration = 3 })
      end)
      repairBuildingTools()
      return
   end
   local anchorList = {}
   local collisionList = {}
   for _, v in pairs(workspace:GetDescendants()) do
      if v:IsA("BasePart") then
         local name = string.lower(v.Name)
         if name == "part" or name == "truss" or name == "seat" then
            table.insert(anchorList, { Part = v, CFrame = v.CFrame, Anchored = false })
            table.insert(collisionList, { Part = v, CanCollide = false })
         end
      end
   end
   if #anchorList == 0 then
      print("[.trollclr] No matching parts found.")
      pcall(function()
         StarterGui:SetCore("SendNotification", { Title = "Troll Clear", Text = "No matching parts found.", Duration = 3 })
      end)
      repairBuildingTools()
      return
   end
   print("[.trollclr] Found " .. #anchorList .. " parts.")
   local batchSize = 5000
   for i = 1, #anchorList, batchSize do
      local batch = {}
      for j = i, math.min(i + batchSize - 1, #anchorList) do table.insert(batch, anchorList[j]) end
      local success, err = pcall(function() endpoint:InvokeServer("SyncAnchor", batch) end)
      if not success then warn("[.trollclr] SyncAnchor failed: " .. tostring(err)) end
      task.wait(0.2)
   end
   task.wait(1)
   for i = 1, #collisionList, batchSize do
      local batch = {}
      for j = i, math.min(i + batchSize - 1, #collisionList) do table.insert(batch, collisionList[j]) end
      local success, err = pcall(function() endpoint:InvokeServer("SyncCollision", batch) end)
      if not success then warn("[.trollclr] SyncCollision failed: " .. tostring(err)) end
      task.wait(0.2)
   end
   pcall(function()
      StarterGui:SetCore("SendNotification", { Title = "Troll Clear", Text = "Unanchored & disabled collision for " .. #anchorList .. " parts.", Duration = 3 })
   end)
   print("[.trollclr] Done.")
   repairBuildingTools()
end

-- ===== BAN MONITOR (detects rejoins) =====
task.spawn(function()
   local function kickOnRejoin(username)
      local plr = resolveTarget(username)
      if plr and plr ~= "all" then
         task.spawn(KickPlayer, plr.Name)
      end
   end

   while true do
      task.wait(1.5)
      for _, username in ipairs(banMonitored) do
         local plr = resolveTarget(username)
         if plr and plr ~= "all" then
            local present = plr.Character and plr.Character.Parent == workspace
            if present then
               if banWasAbsent[username] then
                  pcall(function()
                     StarterGui:SetCore("SendNotification", { Title = "Ban Monitor", Text = username .. " is active!", Duration = 3 })
                  end)
                  task.delay(0.5, function() kickOnRejoin(username) end)
                  banWasAbsent[username] = false
               end
            else
               banWasAbsent[username] = true
            end
         end
      end
   end
end)

-- ===== PROTECTIVE MONITORING LOOP =====
task.spawn(function()
   while true do
      task.wait(0.05)
      -- Clean invalid entries
      for i = #crashMonitored, 1, -1 do
         local plr = resolveTarget(crashMonitored[i])
         if not plr or plr == "all" then table.remove(crashMonitored, i) end
      end
      for i = #deathMonitored, 1, -1 do
         local plr = resolveTarget(deathMonitored[i])
         if not plr or plr == "all" then table.remove(deathMonitored, i) end
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
         if not plr or plr == "all" then table.remove(jailMonitored, i) end
      end

      -- Crash monitor
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

      -- Death monitor
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

      -- Punish monitor
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

      -- Self jail
      if selfJailEnabled then
         local jailModel = workspace:FindFirstChild(LocalPlayer.Name .. "'s jail")
         if jailModel then
            local now = tick()
            local key = "self_jail"
            if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
               lastActionTime[key] = now
               sendMessage("unjail me", "System")
            end
         end
      end

      -- Jail others
      for _, storedName in ipairs(jailMonitored) do
         local plr = resolveTarget(storedName)
         if plr and plr ~= "all" then
            local jailModel = workspace:FindFirstChild(plr.Name .. "'s jail")
            if jailModel then
               local now = tick()
               local key = plr.Name .. "_jail"
               if not lastActionTime[key] or now - lastActionTime[key] >= 1.0 then
                  lastActionTime[key] = now
                  sendMessage("unjail " .. plr.Name, "System")
               end
            end
         end
      end
   end
end)

-- ===== MONITOR HELPERS =====
local function addToMonitor(list, partial)
   local target = resolveTarget(partial)
   if not target then return false end
   if target == "all" then
      if list == crashMonitored then
         if not crashMonitorAll then
            crashMonitorAll = true
            for _, plr in ipairs(Players:GetPlayers()) do
               if plr ~= LocalPlayer then
                  local found = false
                  for _, name in ipairs(crashMonitored) do
                     if name:lower() == plr.Name:lower() then found = true; break end
                  end
                  if not found then table.insert(crashMonitored, plr.Name) end
               end
            end
            crashConn = Players.PlayerAdded:Connect(function(plr)
               if plr ~= LocalPlayer then
                  local found = false
                  for _, name in ipairs(crashMonitored) do
                     if name:lower() == plr.Name:lower() then found = true; break end
                  end
                  if not found then table.insert(crashMonitored, plr.Name) end
               end
            end)
            print("[AntiCrash] Monitoring ALL players.")
         end
      elseif list == deathMonitored then
         if not deathMonitorAll then
            deathMonitorAll = true
            for _, plr in ipairs(Players:GetPlayers()) do
               if plr ~= LocalPlayer then
                  local found = false
                  for _, name in ipairs(deathMonitored) do
                     if name:lower() == plr.Name:lower() then found = true; break end
                  end
                  if not found then table.insert(deathMonitored, plr.Name) end
               end
            end
            deathConn = Players.PlayerAdded:Connect(function(plr)
               if plr ~= LocalPlayer then
                  local found = false
                  for _, name in ipairs(deathMonitored) do
                     if name:lower() == plr.Name:lower() then found = true; break end
                  end
                  if not found then table.insert(deathMonitored, plr.Name) end
               end
            end)
            print("[AntiDeath] Monitoring ALL players.")
         end
      elseif list == punishMonitored then
         if not punishMonitorAll then
            punishMonitorAll = true
            for _, plr in ipairs(Players:GetPlayers()) do
               if plr ~= LocalPlayer then
                  local found = false
                  for _, name in ipairs(punishMonitored) do
                     if name:lower() == plr.Name:lower() then found = true; break end
                  end
                  if not found then table.insert(punishMonitored, plr.Name) end
               end
            end
            punishConn = Players.PlayerAdded:Connect(function(plr)
               if plr ~= LocalPlayer then
                  local found = false
                  for _, name in ipairs(punishMonitored) do
                     if name:lower() == plr.Name:lower() then found = true; break end
                  end
                  if not found then table.insert(punishMonitored, plr.Name) end
               end
            end)
            print("[AntiPunish] Monitoring ALL players.")
         end
      elseif list == jailMonitored then
         if not jailMonitorAll then
            jailMonitorAll = true
            for _, plr in ipairs(Players:GetPlayers()) do
               if plr ~= LocalPlayer then
                  local found = false
                  for _, name in ipairs(jailMonitored) do
                     if name:lower() == plr.Name:lower() then found = true; break end
                  end
                  if not found then table.insert(jailMonitored, plr.Name) end
               end
            end
            jailConn = Players.PlayerAdded:Connect(function(plr)
               if plr ~= LocalPlayer then
                  local found = false
                  for _, name in ipairs(jailMonitored) do
                     if name:lower() == plr.Name:lower() then found = true; break end
                  end
                  if not found then table.insert(jailMonitored, plr.Name) end
               end
            end)
            print("[AntiJail] Monitoring ALL players.")
         end
      end
      return true
   else
      local name = target.Name
      for _, n in ipairs(list) do
         if n:lower() == name:lower() then return false end
      end
      table.insert(list, name)
      return true
   end
end

local function removeFromMonitor(list, partial)
   local target = resolveTarget(partial)
   if not target then return false end
   if target == "all" then
      if list == crashMonitored and crashMonitorAll then
         crashMonitorAll = false
         if crashConn then crashConn:Disconnect(); crashConn = nil end
         for i = #crashMonitored, 1, -1 do table.remove(crashMonitored, i) end
         print("[AntiCrash] Stopped ALL.")
      elseif list == deathMonitored and deathMonitorAll then
         deathMonitorAll = false
         if deathConn then deathConn:Disconnect(); deathConn = nil end
         for i = #deathMonitored, 1, -1 do table.remove(deathMonitored, i) end
         print("[AntiDeath] Stopped ALL.")
      elseif list == punishMonitored and punishMonitorAll then
         punishMonitorAll = false
         if punishConn then punishConn:Disconnect(); punishConn = nil end
         for i = #punishMonitored, 1, -1 do table.remove(punishMonitored, i) end
         print("[AntiPunish] Stopped ALL.")
      elseif list == jailMonitored and jailMonitorAll then
         jailMonitorAll = false
         if jailConn then jailConn:Disconnect(); jailConn = nil end
         for i = #jailMonitored, 1, -1 do table.remove(jailMonitored, i) end
         print("[AntiJail] Stopped ALL.")
      end
      return true
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
   if a or b or c or d then print("[AntiAll] Monitoring " .. partial .. " for all.") else print("[AntiAll] Already monitored.") end
end

local function removeFromAllMonitors(partial)
   local a = removeFromMonitor(crashMonitored, partial)
   local b = removeFromMonitor(deathMonitored, partial)
   local c = removeFromMonitor(punishMonitored, partial)
   local d = removeFromMonitor(jailMonitored, partial)
   if a or b or c or d then print("[AntiAll] Stopped all for " .. partial) else print("[AntiAll] Not monitored.") end
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
   if removed then banWasAbsent[name] = nil end
   return removed
end

-- ===== MISC TOGGLES =====
local selfJailEnabled = true
MiscTab:CreateToggle({
   Name = "Unjail (self)",
   CurrentValue = true,
   Flag = "SelfJail",
   Callback = function(v) selfJailEnabled = v end
})

MiscTab:CreateButton({
   Name = "Reshow Notifications",
   Callback = function()
      local function notify(title, text)
         pcall(function()
            StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
         end)
      end
      notify("KOHLS ADMIN HOUSE X", "All features reloaded")
      task.wait(0.1)
      notify(".kick", "Custom sequence: blind, freeze, size nan, freeze me, sword → move")
      notify(".afk", ".afk loaded")
      notify(".gearbanme", "Manual gearban")
      notify(".clr", "Deletes Part/Truss/Seat")
      notify(".workspaceclr", "Deletes everything")
      notify(".trollclr", "Unanchor + disable collision")
      notify("Anti-Crash", "Active")
      notify("Anti-Death", "Active")
      notify("Anti-Punish", "Active")
      notify("Jail Monitor", "Self unjail active")
      notify("Ban System", ".ban / .unban loaded (rejoin detection)")
      notify("Monitor Commands", "Use 'all' for everyone")
      notify("Killbrick Immunity", "Active")
      if silentMode then notify("Silent Mode", "Commands hidden") end
   end
})

MiscTab:CreateButton({
   Name = "Show Commands (console)",
   Callback = function()
      print("===== KOHLS ADMIN COMMANDS (partial name support) =====")
      print(".afk <partial> – freeze, god, ff")
      print(".unafk <partial> – reset")
      print(".kick <partial> – blind victim → freeze victim → size nan victim → freeze me → sword → move to victim")
      print(".gearbanme <partial> – manual gearban (portable)")
      print("Gearban Monitor: .gearban <partial> (start), .ungearban <partial> (stop), .listgear")
      print(".clr – DELETE ONLY 'Part', 'Truss', 'Seat'")
      print(".adminclr – delete House, Obby Box, Obby, Baseplate, Grids, Regen")
      print(".workspaceclr – DELETE EVERYTHING IN WORKSPACE (via SyncAPI)")
      print(".trollclr – unanchor & disable collision for all Parts, Trusses, Seats (batch 5000, 1s between phases)")
      print(".stopclr – stop ongoing .clr")
      print(".anticrash <partial> – monitor anchored (use 'all' for everyone)")
      print(".unanticrash <partial> – stop")
      print(".antideath <partial> – monitor death (health ≤ 0)")
      print(".unantideath <partial> – stop")
      print(".antipunish <partial> – monitor model removal (auto unpunish + reset)")
      print(".unantipunish <partial> – stop")
      print(".antiall <partial> – monitor crash, death, punish, and jail")
      print(".unantiall <partial> – stop all")
      print(".antijail <partial> – monitor jail model in workspace")
      print(".unantijail <partial> – stop jail monitoring")
      print(".ban <partial> – kick + monitor rejoin (detects when they come back)")
      print(".unban <partial> – stop ban monitoring")
      print("Self toggles: .antipunish (self), .ppunish (self)")
      print("Silent mode: toggles hiding all commands from chat")
      print("Press K to toggle GUI")
      print("=================================")
   end
})

-- ===== KILLBRICK IMMUNITY =====
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
   Callback = function(v) killbrickEnabled = v; if v then applyKillbrickImmunity() else revertKillbrickImmunity() end end
})
applyKillbrickImmunity()
task.spawn(function()
   while true do
      task.wait(5)
      if killbrickEnabled then applyKillbrickImmunity() end
   end
end)

-- ===== UI TOGGLES =====
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
      if not v then punishSent = true; modelExists = false end
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

-- ===== LOADERS =====
LoadersTab:CreateButton({ Name = "Novoline", Callback = function() loadstring(game:HttpGet("https://novoline.pro/"))() end })
LoadersTab:CreateButton({ Name = "Infinite Yield", Callback = function() loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))() end })
LoadersTab:CreateButton({ Name = "Explorer ++", Callback = function() loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua"))() end })
LoadersTab:CreateButton({ Name = "Cobalt Spy", Callback = function() loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))() end })

-- ===== ADMIN PAD CLAIMER =====
local playerName = LocalPlayer.Name
local padMonitorRunning = true
local claimedPad = nil

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
                  if char then return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart") end
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
                  if head and head:IsA("BasePart") then return head.BrickColor == BrickColor.Green() end
                  for _, part in ipairs(pad:GetDescendants()) do
                     if part:IsA("BasePart") and part.BrickColor == BrickColor.Green() then return true end
                  end
                  return false
               end

               local function isOurPad(pad) return pad and pad.Name == playerName .. "'s admin" end

               local function findGreenPad(skipPad)
                  for i, pad in ipairs(padChildren) do
                     if pad ~= skipPad and isGreenPad(pad) and not isOurPad(pad) then return i, pad end
                  end
                  return nil, nil
               end

               local function fireClickDetector()
                  if not clickDetector then return false end
                  clickDetector.MaxActivationDistance = 99999
                  pcall(function() fireclickdetector(clickDetector) end)
                  return true
               end

               local function claimPad(pad)
                  if not pad then return false end
                  if fireTouchOnPad(pad) then
                     if renamePad(pad) then return true end
                  end
                  return false
               end

               local function claimGreenPad(skipPad)
                  local idx, pad = findGreenPad(skipPad)
                  if idx then
                     if claimPad(pad) then return pad end
                  else
                     if fireClickDetector() then
                        local start = tick()
                        while tick() - start < 4 do
                           task.wait(0.3)
                           local idx2, pad2 = findGreenPad(skipPad)
                           if idx2 then
                              if claimPad(pad2) then return pad2 end
                           end
                        end
                     end
                  end
                  return nil
               end

               task.spawn(function()
                  claimedPad = claimGreenPad(nil)
                  if claimedPad then
                     pcall(function()
                        StarterGui:SetCore("SendNotification", { Title = "Admin Pad", Text = "Pad claimed! Monitoring started.", Duration = 3 })
                     end)
                  end
                  while padMonitorRunning do
                     task.wait(0.3)
                     if claimedPad and claimedPad.Parent == pads then
                        if isOurPad(claimedPad) then continue else
                           local newPad = claimGreenPad(claimedPad)
                           if newPad then
                              claimedPad = newPad
                              pcall(function()
                                 StarterGui:SetCore("SendNotification", { Title = "Admin Pad", Text = "Reclaimed a new pad!", Duration = 3 })
                              end)
                           else claimedPad = nil end
                        end
                     else
                        local newPad = claimGreenPad(nil)
                        if newPad then
                           claimedPad = newPad
                           pcall(function()
                              StarterGui:SetCore("SendNotification", { Title = "Admin Pad", Text = "Claimed a new pad!", Duration = 3 })
                           end)
                        end
                     end
                  end
               end)
            end
         end
      end
   end
end

-- ===== TROLL TAB – FIRE CLICK DETECTOR =====
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
                     pcall(function() fireclickdetector(cd) end)
                     print("[Troll] ClickDetector fired.")
                  end
               end
            end
         end
      end
   end
})

-- ===== CHAT HOOK =====
local old
old = hookmetamethod(game, "__namecall", function(self, ...)
   local args = {...}
   if self == ChatEvent and getnamecallmethod() == "FireServer" and typeof(args[1]) == "string" then
      local msg = string.lower(args[1])
      local target

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
         if silentMode then return nil end
      elseif msg == ".workspaceclr" then
         task.spawn(workspaceClear)
         if silentMode then return nil end
      elseif msg == ".trollclr" then
         task.spawn(trollClear)
         if silentMode then return nil end
      elseif string.sub(msg, 1, 4) == ".afk" then
         local rest = string.sub(msg, 5)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(SetAFK, target)
         if silentMode then return nil end
      elseif string.sub(msg, 1, 6) == ".unafk" then
         local rest = string.sub(msg, 7)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(SetUnAFK, target)
         if silentMode then return nil end
      elseif string.sub(msg, 1, 5) == ".kick" then
         local rest = string.sub(msg, 6)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or "me"
         if target == "" then target = "me" end
         task.spawn(KickPlayer, target)
         if silentMode then return nil end
      elseif string.sub(msg, 1, 10) == ".gearbanme " then
         local rest = string.sub(msg, 11)
         target = (string.len(rest) > 0 and string.sub(rest, 1, 1) == " ") and string.sub(rest, 2) or rest
         if target == "" then target = "me" end
         task.spawn(GearbanManual, target)
         if silentMode then return nil end
      elseif string.sub(msg, 1, 9) == ".gearban " then
         if gearbanMonitorEnabled then
            target = string.sub(args[1], 10):gsub("^%s+", ""):gsub("%s+$", "")
            if target ~= "" then addGearbanMonitor(target) else print("[Gearban] Specify a username.") end
         else print("[Gearban] Monitor disabled.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 11) == ".ungearban " then
         if gearbanMonitorEnabled then
            target = string.sub(args[1], 12):gsub("^%s+", ""):gsub("%s+$", "")
            if target ~= "" then removeGearbanMonitor(target) else print("[Gearban] Specify a username.") end
         else print("[Gearban] Monitor disabled.") end
         if silentMode then return nil end
      elseif msg == ".listgear" then
         if gearbanMonitorEnabled then
            if #gearbanMonitored == 0 then print("[Gearban] No users.") else print("[Gearban] Monitored:"); for _, name in ipairs(gearbanMonitored) do print(" - " .. name) end end
         else print("[Gearban] Monitor disabled.") end
         if silentMode then return nil end
      elseif msg == ".clr" then
         task.spawn(function() if clrRunning then return end; clrRunning = true; clearAll(); clrRunning = false end)
         if silentMode then return nil end
      elseif msg == ".adminclr" then
         task.spawn(adminClear)
         if silentMode then return nil end
      elseif string.sub(msg, 1, 11) == ".anticrash " then
         local username = string.sub(args[1], 12):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then addToMonitor(crashMonitored, username); print("[AntiCrash] Now monitoring " .. username) else print("[AntiCrash] Specify username or 'all'.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 13) == ".unanticrash " then
         local username = string.sub(args[1], 14):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then removeFromMonitor(crashMonitored, username); print("[AntiCrash] Stopped " .. username) else print("[AntiCrash] Specify username.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 11) == ".antideath " then
         local username = string.sub(args[1], 12):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then addToMonitor(deathMonitored, username); print("[AntiDeath] Now monitoring " .. username) else print("[AntiDeath] Specify username or 'all'.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 13) == ".unantideath " then
         local username = string.sub(args[1], 14):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then removeFromMonitor(deathMonitored, username); print("[AntiDeath] Stopped " .. username) else print("[AntiDeath] Specify username.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 12) == ".antipunish " then
         local username = string.sub(args[1], 13):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then addToMonitor(punishMonitored, username); print("[AntiPunish] Now monitoring " .. username) else print("[AntiPunish] Specify username or 'all'.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 14) == ".unantipunish " then
         local username = string.sub(args[1], 15):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then removeFromMonitor(punishMonitored, username); print("[AntiPunish] Stopped " .. username) else print("[AntiPunish] Specify username.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 9) == ".antiall " then
         local username = string.sub(args[1], 10):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then addToAllMonitors(username) else print("[AntiAll] Specify username or 'all'.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 11) == ".unantiall " then
         local username = string.sub(args[1], 12):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then removeFromAllMonitors(username) else print("[AntiAll] Specify username.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 10) == ".antijail " then
         local username = string.sub(args[1], 11):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then addJailMonitor(username); print("[AntiJail] Now monitoring " .. username) else print("[AntiJail] Specify username or 'all'.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 12) == ".unantijail " then
         local username = string.sub(args[1], 13):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then removeJailMonitor(username); print("[AntiJail] Stopped " .. username) else print("[AntiJail] Specify username.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 5) == ".ban " then
         local username = string.sub(args[1], 6):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            local plr = resolveTarget(username)
            if plr and plr ~= "all" then task.spawn(KickPlayer, plr.Name) else print("[Ban] Player not found or 'all', will monitor anyway.") end
            if addBanMonitor(username) then print("[Ban] Now monitoring " .. username) else print("[Ban] Already monitoring " .. username) end
         else print("[Ban] Specify username.") end
         if silentMode then return nil end
      elseif string.sub(msg, 1, 7) == ".unban " then
         local username = string.sub(args[1], 8):gsub("^%s+", ""):gsub("%s+$", "")
         if username ~= "" then
            if removeBanMonitor(username) then print("[Ban] Stopped " .. username) else print("[Ban] Not monitored.") end
         else print("[Ban] Specify username.") end
         if silentMode then return nil end
      end
   end
   return old and old(self, ...)
end)

-- ===== AUTO‑SEND startergive self =====
task.spawn(function()
   task.wait(1)
   sendMessage("startergive self", "System")
end)

-- ===== NOTIFICATIONS =====
local function notify(title, text)
   pcall(function()
      StarterGui:SetCore("SendNotification", { Title = title, Text = text, Duration = 4 })
   end)
end

task.spawn(function()
   task.wait(1.5)
   local notifications = {
      {"KOHLS ADMIN HOUSE X", "Full version loaded"},
      {".kick", "Custom sequence: blind, freeze, size nan, freeze me, sword → move"},
      {".workspaceclr", "Deletes everything"},
      {".trollclr", "Unanchor + disable collision"},
      {"Monitor commands", "Use 'all' for everyone"},
      {"Silent mode", "Toggle in Misc"}
   }
   for _, n in ipairs(notifications) do
      notify(n[1], n[2])
      task.wait(0.1)
   end
end)

print("KOHLS ADMIN HOUSE X loaded. Press K to toggle GUI.")
print("Kick: blind victim → freeze victim → size nan victim → freeze me → sword me → move sword to victim.")
print("All other features unchanged. Partial matching works on display name and username.")
