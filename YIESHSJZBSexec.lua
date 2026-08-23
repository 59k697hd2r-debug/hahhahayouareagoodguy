--[[
  Roblox Executor Emulator v23.0 – FINAL
  ======================================
  - TextBox fills the ScrollingFrame exactly (Size = UDim2.new(1, 0, 1, 0))
  - Removed syntax highlighting and autocorrect completely.
  - Font size range 4–30.
  - Line numbers fixed (no overlap).
  - Dehash renames ALL tracked instances.
  - Script name is NOT obfuscated.
  - Infinite Jump tutorial removed.
--]]

local function generateObfuscatedString()
    local length = 66
    local chars = {
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz",
        "@#$&*()\"%-+=/;:'€£¥_^[]{}§|~…\\<>!?",
        "😀😁😂🤣😃😄😅😆😉😊😋😎😍🥰😘😗😙😚☺️🙂🤗🤩🤔🤨😐😑😶🙄😏😣😥😮🤐😯😪😫😴😌😛😜😝🤤😒😓😔😕🙃🤑😲☹️🙁😖😞😟😤😢😭😦😧😨😩🤯😬😰😱🥵🥶😳🤪😵😡😠🤬",
        "ابتثجحخدذرزسشصضطظعغفقكلمنهوي",
        "的一是了不在有人和我这中大为上个国我以要他时来用们生到作地于出就分对成会可主发年动同工也能下过子说产种面而方后多定行学法所民得经十三之进着等部度家电力里如水化高自二理起小物现实加量都两体制机当使点从业本去把性好应开它合还因由其些然前外天政四日那社义事平形相全表间样与关各重新线内数正心反你明看原又么利比或但质气第向道命此变条只没结解问意建月公无系军很情者最立代想已通并提直题党程展五果料象员革位入常文总次品式活设及管特件长求老头基资边流路级少图山统接知较将组见计别她手角期根论运农指几九区强放决西被干做必战先回则任取据处队南给色光门即保治北造百规热领七海口东导器压志世金增争济阶油思术极交受联什认六共权收证改清己美再采转更单风切打白教速花带安场身车例真务具万每目至达走积示议声报斗完类八离华名确才科张信马节话米整空元况今集温传土许步群广石记需段研界拉林律叫且究观越织装影算低持音众书布复容儿须际商非验连断深难近矿千周委素技备半办青省列习响约支般史感劳便团往酸历市克何除消构府称太准精值号率族维划选标写存候毛亲快效斯院查江型眼王按格养易置派层片始却专状育厂京识适属圆包火住调满县局照参红细引听该铁价严",
        "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをんアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン",
        "абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ",
        "αβγδεζηθικλμνξοπρστυφχψωΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ",
    }
    local allChars = table.concat(chars)
    local result = ""
    for i = 1, length do
        local idx = math.random(1, #allChars)
        result = result .. allChars:sub(idx, idx)
    end
    return result
end

-- Store original names for Dehash
local obfuscatedInstances = {}
local function registerObfuscatedInstance(instance, originalName)
    obfuscatedInstances[instance] = originalName
end

local player = game.Players.LocalPlayer
local coreGui = game:GetService("CoreGui")
local starterGui = game:GetService("StarterGui")

local folder = Instance.new("Folder")
folder.Name = generateObfuscatedString()
folder.Parent = coreGui
registerObfuscatedInstance(folder, "CoreGui_Folder")

script.Name = "ExecutorEmulator_LocalScript"

local mainGui = Instance.new("ScreenGui")
mainGui.Name = generateObfuscatedString()
mainGui.ResetOnSpawn = false
mainGui.Parent = folder
registerObfuscatedInstance(mainGui, "ExecutorEmulator_MainGUI")

local mainFrame = Instance.new("Frame")
mainFrame.Name = generateObfuscatedString()
mainFrame.Size = UDim2.new(0, 750, 0, 700)
mainFrame.Position = UDim2.new(0.5, -375, 0.5, -350)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = mainGui
registerObfuscatedInstance(mainFrame, "MainFrame")

local headerDecal = Instance.new("ImageLabel")
headerDecal.Size = UDim2.new(1, 0, 0, 60)
headerDecal.Position = UDim2.new(0, 0, 0, 0)
headerDecal.Image = "rbxassetid://109251559"
headerDecal.BackgroundTransparency = 1
headerDecal.Parent = mainFrame

local logoDecal = Instance.new("ImageLabel")
logoDecal.Size = UDim2.new(0, 40, 0, 40)
logoDecal.Position = UDim2.new(0, 10, 0, 10)
logoDecal.Image = "rbxassetid://109251559"
logoDecal.BackgroundTransparency = 1
logoDecal.Parent = mainFrame

local dragDetector = Instance.new("UIDragDetector")
dragDetector.Name = generateObfuscatedString()
dragDetector.Parent = mainFrame

local titleBar = Instance.new("Frame")
titleBar.Name = generateObfuscatedString()
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Position = UDim2.new(0, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
titleBar.BackgroundTransparency = 0.8
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = generateObfuscatedString()
titleLabel.Size = UDim2.new(1, -340, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Executor Emulator v23.0"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local function createTitleButton(text, posX)
    local btn = Instance.new("TextButton")
    btn.Name = generateObfuscatedString()
    btn.Size = UDim2.new(0, 80, 0, 30)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = titleBar
    return btn
end

local settingsBtn = createTitleButton("Settings", 0)
local tutorialsBtn = createTitleButton("Tutorials", 85)

local minBtn = Instance.new("TextButton")
minBtn.Name = generateObfuscatedString()
minBtn.Size = UDim2.new(0, 30, 0, 30)
minBtn.Position = UDim2.new(1, -60, 0, 0)
minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
minBtn.BorderSizePixel = 0
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 18
minBtn.Font = Enum.Font.SourceSansBold
minBtn.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Name = generateObfuscatedString()
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = titleBar

-- Code container
local codeContainer = Instance.new("Frame")
codeContainer.Name = generateObfuscatedString()
codeContainer.Size = UDim2.new(1, -20, 0, 270)
codeContainer.Position = UDim2.new(0, 10, 0, 70)
codeContainer.BackgroundTransparency = 1
codeContainer.Parent = mainFrame

-- Line Numbers
local lineNumbers = Instance.new("TextLabel")
lineNumbers.Name = generateObfuscatedString()
lineNumbers.Size = UDim2.new(0, 30, 1, 0)
lineNumbers.Position = UDim2.new(0, 0, 0, 0)
lineNumbers.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
lineNumbers.BorderSizePixel = 1
lineNumbers.BorderColor3 = Color3.fromRGB(50, 50, 50)
lineNumbers.TextColor3 = Color3.fromRGB(150, 150, 150)
lineNumbers.TextSize = 12
lineNumbers.Font = Enum.Font.SourceSans
lineNumbers.Text = "1"
lineNumbers.TextXAlignment = Enum.TextXAlignment.Right
lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
lineNumbers.TextWrapped = false
lineNumbers.Parent = codeContainer

-- ScrollingFrame for Code Box (leaves space for line numbers)
local codeScrollingFrame = Instance.new("ScrollingFrame")
codeScrollingFrame.Name = generateObfuscatedString()
codeScrollingFrame.Size = UDim2.new(1, -35, 1, 0)
codeScrollingFrame.Position = UDim2.new(0, 35, 0, 0)
codeScrollingFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
codeScrollingFrame.BorderSizePixel = 1
codeScrollingFrame.BorderColor3 = Color3.fromRGB(60, 60, 60)
codeScrollingFrame.ScrollBarThickness = 8
codeScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
codeScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
codeScrollingFrame.Parent = codeContainer

-- TextBox - now fills the ScrollingFrame completely (Size = UDim2.new(1, 0, 1, 0))
local codeBox = Instance.new("TextBox")
codeBox.Name = generateObfuscatedString()
codeBox.Size = UDim2.new(1, 0, 1, 0)  -- matches parent exactly
codeBox.Position = UDim2.new(0, 0, 0, 0)
codeBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
codeBox.BorderSizePixel = 0
codeBox.TextColor3 = Color3.fromRGB(220, 220, 220)
codeBox.TextSize = 13
codeBox.Font = Enum.Font.SourceSans
codeBox.Text = ""
codeBox.TextWrapped = true
codeBox.TextXAlignment = Enum.TextXAlignment.Left
codeBox.TextYAlignment = Enum.TextYAlignment.Top
codeBox.MultiLine = true
codeBox.ClearTextOnFocus = false
codeBox.AutomaticSize = Enum.AutomaticSize.Y  -- still grows vertically
codeBox.Parent = codeScrollingFrame

-- Settings (simple)
local executorSettings = {
    fontSize = 13,
    showLineNumbers = true,
    autoResizeFont = true,
}

local function autoResizeFont()
    if not executorSettings.autoResizeFont then return end
    local text = codeBox.Text
    local length = #text
    local baseSize = executorSettings.fontSize
    if length > 500 then
        codeBox.TextSize = math.max(4, baseSize - 6)
    elseif length > 200 then
        codeBox.TextSize = math.max(4, baseSize - 4)
    elseif length > 100 then
        codeBox.TextSize = math.max(4, baseSize - 2)
    else
        codeBox.TextSize = baseSize
    end
    lineNumbers.TextSize = codeBox.TextSize - 1
end

local function updateLineNumbers()
    if not executorSettings.showLineNumbers then
        lineNumbers.Visible = false
        return
    end
    lineNumbers.Visible = true
    local text = codeBox.Text
    local lines = {}
    if text == "" then
        lines = {1}
    else
        local count = 1
        for _ in text:gmatch("\n") do count = count + 1 end
        for i = 1, count do lines[i] = tostring(i) end
    end
    lineNumbers.Text = table.concat(lines, "\n")
end

local function updateCanvasSize()
    task.wait(0.05)
    local height = codeBox.AbsoluteSize.Y + 10
    codeScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, height)
    codeScrollingFrame.CanvasPosition = Vector2.new(0, height)
end

codeBox:GetPropertyChangedSignal("Text"):Connect(function()
    updateLineNumbers()
    autoResizeFont()
    updateCanvasSize()
end)
codeBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateCanvasSize)

task.wait(0.1)
updateLineNumbers()
autoResizeFont()
updateCanvasSize()

local function applyFontSize()
    codeBox.TextSize = executorSettings.fontSize
    lineNumbers.TextSize = executorSettings.fontSize - 1
    autoResizeFont()
    updateCanvasSize()
end

local errorLabel = Instance.new("TextLabel")
errorLabel.Name = generateObfuscatedString()
errorLabel.Size = UDim2.new(1, -20, 0, 50)
errorLabel.Position = UDim2.new(0, 10, 0, 350)
errorLabel.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
errorLabel.BackgroundTransparency = 0.8
errorLabel.BorderSizePixel = 1
errorLabel.BorderColor3 = Color3.fromRGB(150, 30, 30)
errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
errorLabel.TextSize = 12
errorLabel.Font = Enum.Font.SourceSans
errorLabel.Text = "No errors."
errorLabel.TextWrapped = true
errorLabel.TextXAlignment = Enum.TextXAlignment.Left
errorLabel.TextYAlignment = Enum.TextYAlignment.Top
errorLabel.Parent = mainFrame

local btnContainer = Instance.new("Frame")
btnContainer.Name = generateObfuscatedString()
btnContainer.Size = UDim2.new(1, -20, 0, 30)
btnContainer.Position = UDim2.new(0, 10, 0, 410)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = mainFrame

local function createButton(text, posX, width, color)
    width = width or 110
    local btn = Instance.new("TextButton")
    btn.Name = generateObfuscatedString()
    btn.Size = UDim2.new(0, width, 0, 28)
    btn.Position = UDim2.new(0, posX, 0, 0)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 13
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = btnContainer
    return btn
end

local execBtn = createButton("Execute", 0, 110, Color3.fromRGB(30, 130, 30))
local clearBtn = createButton("Clear", 115, 90, Color3.fromRGB(130, 80, 30))
local newLineBtn = createButton("New Line", 210, 100, Color3.fromRGB(30, 80, 130))
local copyBtn = createButton("Copy", 315, 90, Color3.fromRGB(80, 30, 130))
local dehashBtn = createButton("Dehash Names", 410, 120, Color3.fromRGB(130, 130, 30))

-- Dehash
local dehashActive = false
dehashBtn.MouseButton1Click:Connect(function()
    dehashActive = not dehashActive
    if dehashActive then
        for instance, originalName in pairs(obfuscatedInstances) do
            if instance and instance.Parent then
                instance.Name = originalName
            end
        end
        dehashBtn.Text = "Re-obfuscate"
        dehashBtn.BackgroundColor3 = Color3.fromRGB(130, 130, 30)
        errorLabel.Text = "Dehashed all names."
        errorLabel.BackgroundColor3 = Color3.fromRGB(10, 40, 10)
        errorLabel.BorderColor3 = Color3.fromRGB(30, 150, 30)
        errorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    else
        for instance, _ in pairs(obfuscatedInstances) do
            if instance and instance.Parent then
                instance.Name = generateObfuscatedString()
            end
        end
        dehashBtn.Text = "Dehash Names"
        dehashBtn.BackgroundColor3 = Color3.fromRGB(130, 130, 30)
        errorLabel.Text = "Re-obfuscated all names."
        errorLabel.BackgroundColor3 = Color3.fromRGB(10, 40, 10)
        errorLabel.BorderColor3 = Color3.fromRGB(30, 150, 30)
        errorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    end
end)

local function sendRobloxNotification(title, message, duration, icon)
    duration = duration or 5
    icon = icon or "rbxassetid://109251559"
    pcall(function()
        starterGui:SetCore("SendNotification", {
            Title = title or "Notification",
            Text = message or "",
            Icon = icon,
            Duration = duration,
        })
    end)
end

execBtn.MouseButton1Click:Connect(function()
    local rawText = codeBox.Text
    if rawText == nil or rawText:match("^%s*$") then
        errorLabel.Text = "Error: Empty script."
        return
    end

    errorLabel.Text = "Executing..."
    errorLabel.BackgroundColor3 = Color3.fromRGB(10, 40, 10)
    errorLabel.BorderColor3 = Color3.fromRGB(30, 150, 30)
    errorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

    local outputLines = {}
    local originalPrint = print
    local function capturePrint(...)
        local args = {...}
        local strings = {}
        for _, v in ipairs(args) do
            table.insert(strings, tostring(v))
        end
        local line = table.concat(strings, "\t")
        table.insert(outputLines, line)
        originalPrint(line)
    end

    local env = getfenv(0)
    if getgenv then env.getgenv = getgenv end
    if getrenv then env.getrenv = getrenv end
    if getsenv then env.getsenv = getsenv end
    env.game = game
    env.workspace = workspace
    env.players = game:GetService("Players")
    env.ReplicatedStorage = game:GetService("ReplicatedStorage")
    env.CoreGui = coreGui
    env.PlayerGui = player:WaitForChild("PlayerGui")
    env.StarterGui = starterGui
    env.print = capturePrint
    env.warn = function(...) capturePrint("[WARN]", ...) end
    env.error = function(...) capturePrint("[ERROR]", ...) end

    if KRNL_LOADED then
        env.KRNL_LOADED = true
        env.KrnlApi = KrnlApi
    end

    local func, compileErr = loadstring(rawText)
    if not func then
        local errMsg = compileErr or "Unknown compilation error"
        local lineNum = errMsg:match(":(%d+):") or "?"
        errorLabel.Text = "(" .. script.Name .. " : Line " .. lineNum .. ", " .. errMsg .. ")"
        errorLabel.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
        errorLabel.BorderColor3 = Color3.fromRGB(150, 30, 30)
        errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end

    local success, err = pcall(function()
        setfenv(func, env)
        func()
    end)

    if not success then
        local errMsg = err or "Unknown runtime error"
        local lineNum = errMsg:match(":(%d+):") or "?"
        errorLabel.Text = "(" .. script.Name .. " : Line " .. lineNum .. ", " .. errMsg .. ")"
        errorLabel.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
        errorLabel.BorderColor3 = Color3.fromRGB(150, 30, 30)
        errorLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    else
        if #outputLines > 0 then
            local output = "Output: " .. table.concat(outputLines, "\n")
            errorLabel.Text = output
            sendRobloxNotification("Script Executed!", "Output: " .. table.concat(outputLines, " "))
        else
            errorLabel.Text = "Script executed successfully (no output)."
            sendRobloxNotification("Script Executed!", "No output produced.")
        end
        print("works")
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    codeBox.Text = ""
    errorLabel.Text = "No errors."
    updateCanvasSize()
end)

newLineBtn.MouseButton1Click:Connect(function()
    local cursorPos = codeBox.CursorPosition
    if cursorPos and cursorPos >= 0 then
        local text = codeBox.Text
        local before = text:sub(1, cursorPos)
        local after = text:sub(cursorPos + 1)
        codeBox.Text = before .. "\n" .. after
        codeBox.CursorPosition = cursorPos + 1
    else
        codeBox.Text = codeBox.Text .. "\n"
    end
    updateCanvasSize()
end)

copyBtn.MouseButton1Click:Connect(function()
    local text = codeBox.Text
    if text and text ~= "" then
        if setclipboard then
            setclipboard(text)
            errorLabel.Text = "Copied."
            task.wait(1.5)
            errorLabel.Text = "No errors."
        else
            errorLabel.Text = "Clipboard unavailable."
        end
    else
        errorLabel.Text = "Nothing to copy."
    end
end)

local minimized = false
local originalSize = mainFrame.Size
local originalPos = mainFrame.Position

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        mainFrame.Size = UDim2.new(0, 750, 0, 30)
        mainFrame.Position = UDim2.new(0.5, -375, 0.5, -200)
        for _, child in ipairs(mainFrame:GetChildren()) do
            if child ~= titleBar and child ~= dragDetector then
                child.Visible = false
            end
        end
        minBtn.Text = "+"
    else
        mainFrame.Size = originalSize
        mainFrame.Position = originalPos
        for _, child in ipairs(mainFrame:GetChildren()) do
            if child ~= titleBar and child ~= dragDetector then
                child.Visible = true
            end
        end
        minBtn.Text = "-"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    mainGui:Destroy()
    if settingsGui then settingsGui:Destroy() end
    if tutorialsGui then tutorialsGui:Destroy() end
end)

-- Settings GUI
local settingsGui = nil
local function createSettingsGui()
    if settingsGui then
        settingsGui.Enabled = true
        settingsGui.Parent = folder
        return
    end

    settingsGui = Instance.new("ScreenGui")
    settingsGui.Name = generateObfuscatedString()
    settingsGui.ResetOnSpawn = false
    settingsGui.Parent = folder
    registerObfuscatedInstance(settingsGui, "SettingsGUI")

    local frame = Instance.new("Frame")
    frame.Name = generateObfuscatedString()
    frame.Size = UDim2.new(0, 300, 0, 180)
    frame.Position = UDim2.new(0.5, -150, 0.5, -90)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    frame.Parent = settingsGui

    local settingsDrag = Instance.new("UIDragDetector")
    settingsDrag.Name = generateObfuscatedString()
    settingsDrag.Parent = frame

    local title = Instance.new("Frame")
    title.Name = generateObfuscatedString()
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    title.BorderSizePixel = 0
    title.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = generateObfuscatedString()
    titleLabel.Size = UDim2.new(1, -30, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Settings"
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = title

    local close = Instance.new("TextButton")
    close.Name = generateObfuscatedString()
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -30, 0, 0)
    close.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    close.BorderSizePixel = 0
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 16
    close.Font = Enum.Font.SourceSansBold
    close.Parent = title

    local content = Instance.new("Frame")
    content.Name = generateObfuscatedString()
    content.Size = UDim2.new(1, -20, 1, -40)
    content.Position = UDim2.new(0, 10, 0, 35)
    content.BackgroundTransparency = 1
    content.Parent = frame

    local fontSizeLabel = Instance.new("TextLabel")
    fontSizeLabel.Name = generateObfuscatedString()
    fontSizeLabel.Size = UDim2.new(0, 80, 0, 28)
    fontSizeLabel.Position = UDim2.new(0, 0, 0, 0)
    fontSizeLabel.BackgroundTransparency = 1
    fontSizeLabel.Text = "Font Size (4-30):"
    fontSizeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    fontSizeLabel.TextSize = 14
    fontSizeLabel.Font = Enum.Font.SourceSans
    fontSizeLabel.TextXAlignment = Enum.TextXAlignment.Left
    fontSizeLabel.Parent = content

    local fontSizeBox = Instance.new("TextBox")
    fontSizeBox.Name = generateObfuscatedString()
    fontSizeBox.Size = UDim2.new(0, 50, 0, 28)
    fontSizeBox.Position = UDim2.new(0, 110, 0, 0)
    fontSizeBox.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    fontSizeBox.BorderSizePixel = 1
    fontSizeBox.BorderColor3 = Color3.fromRGB(60, 60, 60)
    fontSizeBox.TextColor3 = Color3.fromRGB(220, 220, 220)
    fontSizeBox.TextSize = 13
    fontSizeBox.Font = Enum.Font.SourceSans
    fontSizeBox.Text = tostring(executorSettings.fontSize)
    fontSizeBox.TextXAlignment = Enum.TextXAlignment.Center
    fontSizeBox.Parent = content

    fontSizeBox.FocusLost:Connect(function()
        local num = tonumber(fontSizeBox.Text)
        if num and num >= 4 and num <= 30 then
            executorSettings.fontSize = num
            applyFontSize()
        else
            fontSizeBox.Text = tostring(executorSettings.fontSize)
        end
    end)

    local lineNumbersSetting = Instance.new("TextButton")
    lineNumbersSetting.Name = generateObfuscatedString()
    lineNumbersSetting.Size = UDim2.new(0, 200, 0, 28)
    lineNumbersSetting.Position = UDim2.new(0, 0, 0, 40)
    lineNumbersSetting.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    lineNumbersSetting.BorderSizePixel = 0
    lineNumbersSetting.Text = "Show Line Numbers: ON"
    lineNumbersSetting.TextColor3 = Color3.fromRGB(255, 255, 255)
    lineNumbersSetting.TextSize = 13
    lineNumbersSetting.Font = Enum.Font.SourceSansBold
    lineNumbersSetting.Parent = content

    local autoResizeSetting = Instance.new("TextButton")
    autoResizeSetting.Name = generateObfuscatedString()
    autoResizeSetting.Size = UDim2.new(0, 200, 0, 28)
    autoResizeSetting.Position = UDim2.new(0, 0, 0, 80)
    autoResizeSetting.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    autoResizeSetting.BorderSizePixel = 0
    autoResizeSetting.Text = "Auto-Resize Font: ON"
    autoResizeSetting.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoResizeSetting.TextSize = 13
    autoResizeSetting.Font = Enum.Font.SourceSansBold
    autoResizeSetting.Parent = content

    local function updateSettingsUI()
        lineNumbersSetting.Text = executorSettings.showLineNumbers and "Show Line Numbers: ON" or "Show Line Numbers: OFF"
        autoResizeSetting.Text = executorSettings.autoResizeFont and "Auto-Resize Font: ON" or "Auto-Resize Font: OFF"
        fontSizeBox.Text = tostring(executorSettings.fontSize)
    end

    lineNumbersSetting.MouseButton1Click:Connect(function()
        executorSettings.showLineNumbers = not executorSettings.showLineNumbers
        updateLineNumbers()
        updateSettingsUI()
    end)

    autoResizeSetting.MouseButton1Click:Connect(function()
        executorSettings.autoResizeFont = not executorSettings.autoResizeFont
        if executorSettings.autoResizeFont then
            autoResizeFont()
        else
            codeBox.TextSize = executorSettings.fontSize
            lineNumbers.TextSize = executorSettings.fontSize - 1
        end
        updateSettingsUI()
    end)

    close.MouseButton1Click:Connect(function()
        settingsGui.Enabled = false
    end)

    updateSettingsUI()
end

settingsBtn.MouseButton1Click:Connect(function()
    if settingsGui then
        settingsGui.Enabled = not settingsGui.Enabled
        if settingsGui.Enabled then settingsGui.Parent = folder end
    else
        createSettingsGui()
    end
end)

-- Tutorials GUI (no Infinite Jump)
local tutorialsGui = nil
local function createTutorialsGui()
    if tutorialsGui then
        tutorialsGui.Enabled = true
        tutorialsGui.Parent = folder
        return
    end

    tutorialsGui = Instance.new("ScreenGui")
    tutorialsGui.Name = generateObfuscatedString()
    tutorialsGui.ResetOnSpawn = false
    tutorialsGui.Parent = folder
    registerObfuscatedInstance(tutorialsGui, "TutorialsGUI")

    local frame = Instance.new("Frame")
    frame.Name = generateObfuscatedString()
    frame.Size = UDim2.new(0, 350, 0, 450)
    frame.Position = UDim2.new(0.5, -175, 0.5, -225)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    frame.Parent = tutorialsGui

    local tutorialsDrag = Instance.new("UIDragDetector")
    tutorialsDrag.Name = generateObfuscatedString()
    tutorialsDrag.Parent = frame

    local title = Instance.new("Frame")
    title.Name = generateObfuscatedString()
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    title.BorderSizePixel = 0
    title.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = generateObfuscatedString()
    titleLabel.Size = UDim2.new(1, -30, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Tutorials"
    titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = title

    local close = Instance.new("TextButton")
    close.Name = generateObfuscatedString()
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -30, 0, 0)
    close.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    close.BorderSizePixel = 0
    close.Text = "X"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 16
    close.Font = Enum.Font.SourceSansBold
    close.Parent = title

    local content = Instance.new("ScrollingFrame")
    content.Name = generateObfuscatedString()
    content.Size = UDim2.new(1, -10, 1, -40)
    content.Position = UDim2.new(0, 5, 0, 35)
    content.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.ScrollBarThickness = 6
    content.Parent = frame

    local tutorials = {
        {
            name = "Walkspeed Changer",
            code = [[
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
humanoid.WalkSpeed = 50
print("Walkspeed set to 50!")
            ]],
            explanation = "Sets walkspeed to 50."
        },
        {
            name = "Roblox Notification",
            code = [[
local starterGui = game:GetService("StarterGui")
starterGui:SetCore("SendNotification", {
    Title = "Hello!",
    Text = "Roblox notification!",
    Duration = 5
})
print("Notification sent!")
            ]],
            explanation = "Sends a Roblox notification."
        },
        {
            name = "Anti-AFK",
            code = [[
local player = game.Players.LocalPlayer
local vu = game:GetService("VirtualUser")
game:GetService("RunService").Heartbeat:Connect(function()
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)
print("Anti-AFK active.")
            ]],
            explanation = "Prevents AFK kick."
        },
        {
            name = "Tween Service",
            code = [[
local part = Instance.new("Part")
part.Size = Vector3.new(5,5,5)
part.Position = Vector3.new(0,10,0)
part.Anchored = true
part.Parent = workspace
local ts = game:GetService("TweenService")
local tween = ts:Create(part, TweenInfo.new(2, Enum.EasingStyle.Bounce), {Position = Vector3.new(20,10,0)})
tween:Play()
print("Tween started!")
            ]],
            explanation = "Animates a part."
        },
        {
            name = "Custom Notification",
            code = [[
local player = game.Players.LocalPlayer
local function notify(title, msg)
    local gui = Instance.new("ScreenGui")
    gui.ResetOnSpawn = false
    gui.Parent = player.PlayerGui
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0,350,0,80)
    f.Position = UDim2.new(0.5,-175,0.5,-40)
    f.BackgroundColor3 = Color3.fromRGB(25,25,25)
    f.BackgroundTransparency = 0.1
    f.BorderSizePixel = 0
    f.ClipsDescendants = true
    f.Parent = gui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,12)
    c.Parent = f
    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1,-20,0,30)
    tl.Position = UDim2.new(0,10,0,5)
    tl.BackgroundTransparency = 1
    tl.Text = title or "Notification"
    tl.TextColor3 = Color3.fromRGB(255,255,255)
    tl.TextSize = 18
    tl.Font = Enum.Font.SourceSansBold
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Parent = f
    local ml = Instance.new("TextLabel")
    ml.Size = UDim2.new(1,-20,0,30)
    ml.Position = UDim2.new(0,10,0,40)
    ml.BackgroundTransparency = 1
    ml.Text = msg or ""
    ml.TextColor3 = Color3.fromRGB(200,200,200)
    ml.TextSize = 14
    ml.Font = Enum.Font.SourceSans
    ml.TextXAlignment = Enum.TextXAlignment.Left
    ml.TextWrapped = true
    ml.Parent = f
    f.Position = UDim2.new(0.5,-175,0.5,-100)
    f.BackgroundTransparency = 1
    local tween = game:GetService("TweenService"):Create(f, TweenInfo.new(0.4), {Position = UDim2.new(0.5,-175,0.5,-40), BackgroundTransparency = 0.1})
    tween:Play()
    task.wait(3)
    local tweenOut = game:GetService("TweenService"):Create(f, TweenInfo.new(0.3), {Position = UDim2.new(0.5,-175,0.5,30), BackgroundTransparency = 1})
    tweenOut:Play()
    tweenOut.Completed:Wait()
    gui:Destroy()
end
notify("Hello!", "Custom notification!")
print("Custom notification shown!")
            ]],
            explanation = "Creates a custom GUI notification."
        }
    }

    local function buildTutorials()
        for _, child in ipairs(content:GetChildren()) do child:Destroy() end
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        local yPos = 5
        for _, tut in ipairs(tutorials) do
            local btn = Instance.new("TextButton")
            btn.Name = generateObfuscatedString()
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Position = UDim2.new(0, 5, 0, yPos)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(70, 70, 70)
            btn.Text = tut.name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 14
            btn.Font = Enum.Font.SourceSansBold
            btn.Parent = content
            btn.MouseButton1Click:Connect(function()
                local fullText = "-- Tutorial: " .. tut.name .. "\n-- " .. tut.explanation .. "\n\n" .. tut.code
                codeBox.Text = fullText
                errorLabel.Text = "Loaded tutorial: " .. tut.name
                tutorialsGui.Enabled = false
                updateCanvasSize()
                updateLineNumbers()
            end)
            yPos = yPos + 35
        end
        content.CanvasSize = UDim2.new(0, 0, 0, yPos + 10)
    end

    buildTutorials()

    close.MouseButton1Click:Connect(function()
        tutorialsGui.Enabled = false
    end)
end

tutorialsBtn.MouseButton1Click:Connect(function()
    if tutorialsGui then
        tutorialsGui.Enabled = not tutorialsGui.Enabled
        if tutorialsGui.Enabled then tutorialsGui.Parent = folder end
    else
        createTutorialsGui()
    end
end)

applyFontSize()
updateLineNumbers()

print("Executor Emulator v23.0 loaded successfully!")
print("- TextBox now matches ScrollingFrame size exactly")
print("- Font size range: 4-30")
print("- Line numbers fixed (no overlap)")
print("- Dehash renames ALL tracked instances")
print("- Script name is NOT obfuscated")
