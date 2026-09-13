--[[
    Executor Pro v8 — Table-based architecture
    + ScriptBlox Script Hub integration with game labels & 20 char preview
    + Fixed syntax error at line 3290
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local u, s, f = {}, {}, {}

--==================== JSON ====================
local function jsonEncode(val)
    local function encStr(str)
        str = str:gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t")
        str = str:gsub("[%z\1-\8\11\12\14-\31]", function(c) return string.format("\\u%04x",string.byte(c)) end)
        return '"'..str..'"'
    end
    local function enc(v, d)
        d = d or 0
        if d > 100 then return "null" end
        local t = type(v)
        if t == "string" then return encStr(v)
        elseif t == "number" then
            if v ~= v or v == math.huge or v == -math.huge then return "null" end
            return tostring(v)
        elseif t == "boolean" then return v and "true" or "false"
        elseif t == "nil" then return "null"
        elseif t == "table" then
            local n = #v
            local cnt = 0
            local isArr = true
            for k in pairs(v) do
                cnt = cnt + 1
                if type(k) ~= "number" or k ~= math.floor(k) or k < 1 or k > n then isArr = false end
            end
            if cnt == 0 then return "[]" end
            if isArr and cnt == n then
                local p = {}
                for i = 1, n do p[#p+1] = enc(v[i], d+1) end
                return "["..table.concat(p, ",").."]"
            else
                local keys = {}
                for k in pairs(v) do keys[#keys+1] = k end
                table.sort(keys, function(a,b) return tostring(a) < tostring(b) end)
                local p = {}
                for _, k in ipairs(keys) do
                    p[#p+1] = enc(tostring(k), d+1)..":"..enc(v[k], d+1)
                end
                return "{"..table.concat(p, ",").."}"
            end
        end
        return "null"
    end
    return enc(val)
end

local function jsonDecode(str)
    if not str or #str == 0 then return nil end
    local pos = 1
    local len = #str
    local function skip() while pos <= len and str:sub(pos,pos):match("[ \t\n\r]") do pos = pos + 1 end end
    local function parseStr()
        pos = pos + 1
        local parts = {}
        while pos <= len do
            local c = str:sub(pos, pos)
            if c == '"' then pos = pos + 1; return table.concat(parts) end
            if c == "\\" then
                pos = pos + 1
                local nc = str:sub(pos, pos)
                if nc == "n" then parts[#parts+1] = "\n"
                elseif nc == "t" then parts[#parts+1] = "\t"
                elseif nc == "r" then parts[#parts+1] = "\r"
                elseif nc == "\\" then parts[#parts+1] = "\\"
                elseif nc == '"' then parts[#parts+1] = '"'
                elseif nc == "u" then
                    parts[#parts+1] = string.char(tonumber(str:sub(pos+1, pos+4), 16) or 0)
                    pos = pos + 4
                else parts[#parts+1] = nc end
                pos = pos + 1
            else
                parts[#parts+1] = c
                pos = pos + 1
            end
        end
        return table.concat(parts)
    end
    local function parseVal()
        skip()
        local c = str:sub(pos, pos)
        if c == '"' then return parseStr()
        elseif c == "{" then
            pos = pos + 1; local obj = {}
            skip()
            if str:sub(pos, pos) == "}" then pos = pos + 1; return obj end
            while pos <= len do
                skip(); local key = parseStr(); skip()
                if str:sub(pos, pos) == ":" then pos = pos + 1 end
                obj[key] = parseVal()
                skip(); c = str:sub(pos, pos)
                if c == "," then pos = pos + 1
                elseif c == "}" then pos = pos + 1; break end
            end
            return obj
        elseif c == "[" then
            pos = pos + 1; local arr = {}
            skip()
            if str:sub(pos, pos) == "]" then pos = pos + 1; return arr end
            while pos <= len do
                arr[#arr+1] = parseVal()
                skip(); c = str:sub(pos, pos)
                if c == "," then pos = pos + 1
                elseif c == "]" then pos = pos + 1; break end
            end
            return arr
        elseif str:sub(pos, pos+3) == "true" then pos = pos + 4; return true
        elseif str:sub(pos, pos+4) == "false" then pos = pos + 5; return false
        elseif str:sub(pos, pos+3) == "null" then pos = pos + 4; return nil
        else
            local start = pos
            while pos <= len and str:sub(pos, pos):match("[%d%.eE%-%+]") do pos = pos + 1 end
            return tonumber(str:sub(start, pos-1)) or 0
        end
    end
    return parseVal()
end

--==================== HTTP ====================
local function getHttpFunc()
    if type(request) == "function" then return request end
    if type(http_request) == "function" then return http_request end
    if type(syn) == "table" and type(syn.request) == "function" then return syn.request end
    return nil
end

--==================== EXECUTOR DETECTION ====================
local function detectExecutor()
    local name = "Unknown"
    local version = ""
    if type(identifyexecutor) == "function" then
        local ok, n, v = pcall(identifyexecutor)
        if ok then name = tostring(n or "Unknown"); version = tostring(v or "") end
    end
    local known = {
        "synapse","krnl","fluxus","hydrogen","delta","codex","electron",
        "scriptware","valyse","wave","awp","nihon","swift","abyss","celery",
        "argon","constancy","velocity","cryptic","tempest","luna","eclipse",
        "darkness","trigon","jjsploit","sentinel","xeno",
    }
    local lowerName = name:lower()
    local isKnown = false
    for _, execName in ipairs(known) do
        if lowerName:find(execName, 1, true) then isKnown = true; break end
    end
    local hasFileOps = type(writefile) == "function" and type(readfile) == "function"
    local hasWorkspace = false
    if hasFileOps then
        if type(makefolder) == "function" then pcall(makefolder, "executor_data") end
        local wok = pcall(writefile, "executor_data/__test.tmp", "ok")
        if wok then
            local rok, content = pcall(readfile, "executor_data/__test.tmp")
            if rok and content == "ok" then hasWorkspace = true end
            if type(delfile) == "function" then pcall(delfile, "executor_data/__test.tmp") end
        end
    end
    return name, version, isKnown, hasFileOps, hasWorkspace
end

s.execName, s.execVersion, s.execKnown, s.execHasFileOps, s.execHasWorkspace = detectExecutor()

--==================== FILE I/O ====================
local SAVE_DIR = "executor_data"
local SAVE_FILE = SAVE_DIR .. "/state_v8.json"

local function fileWrite(path, content)
    if type(makefolder) == "function" then pcall(makefolder, SAVE_DIR) end
    if type(writefile) == "function" then return pcall(writefile, path, content) end
    return false
end

local function fileRead(path)
    if type(readfile) == "function" then
        local ok, content = pcall(readfile, path)
        if ok and content then return content end
    end
    return nil
end

--==================== THEME ====================
local baseTheme = {
    mainBg = Color3.fromRGB(22, 24, 33), titleBg = Color3.fromRGB(16, 18, 26),
    toolbarBg = Color3.fromRGB(26, 28, 38), editorBg = Color3.fromRGB(18, 20, 28),
    tabBg = Color3.fromRGB(28, 30, 40), tabActiveBg = Color3.fromRGB(45, 48, 62),
    tabHoverBg = Color3.fromRGB(38, 41, 54), tabText = Color3.fromRGB(150, 155, 170),
    tabActiveText = Color3.fromRGB(240, 240, 250), text = Color3.fromRGB(220, 225, 240),
    lineNums = Color3.fromRGB(90, 95, 110), lineNumBg = Color3.fromRGB(14, 16, 22),
    divider = Color3.fromRGB(40, 42, 54), accent = Color3.fromRGB(100, 180, 255),
    keyword = Color3.fromRGB(255, 121, 198), builtin = Color3.fromRGB(189, 147, 249),
    stringVal = Color3.fromRGB(255, 184, 108), numberVal = Color3.fromRGB(255, 215, 130),
    comment = Color3.fromRGB(98, 114, 164), operator = Color3.fromRGB(200, 210, 230),
    identifier = Color3.fromRGB(220, 225, 240), errBg = Color3.fromRGB(30, 18, 22),
    errSuccess = Color3.fromRGB(120, 200, 120), errFail = Color3.fromRGB(255, 100, 100),
    stroke = Color3.fromRGB(50, 55, 70), scrollbar = Color3.fromRGB(60, 65, 80),
    transparency = 0, bgStyle = "solid",
}

local function makeTheme(o)
    local t = {}
    for k, v in pairs(baseTheme) do t[k] = v end
    for k, v in pairs(o) do t[k] = v end
    return t
end

local themes = {
    Midnight = makeTheme({}),
    Glass = makeTheme({
        mainBg = Color3.fromRGB(28, 33, 48), titleBg = Color3.fromRGB(20, 25, 38),
        toolbarBg = Color3.fromRGB(24, 30, 44), editorBg = Color3.fromRGB(22, 27, 40),
        tabBg = Color3.fromRGB(30, 36, 52), tabActiveBg = Color3.fromRGB(48, 55, 75),
        stroke = Color3.fromRGB(70, 80, 110), accent = Color3.fromRGB(120, 200, 255),
        transparency = 0.15, bgStyle = "glass",
    }),
    Dracula = makeTheme({
        mainBg = Color3.fromRGB(30, 31, 41), titleBg = Color3.fromRGB(24, 25, 33),
        editorBg = Color3.fromRGB(24, 25, 33), accent = Color3.fromRGB(80, 200, 120),
        stroke = Color3.fromRGB(60, 63, 75),
    }),
    Monokai = makeTheme({
        mainBg = Color3.fromRGB(39, 40, 34), titleBg = Color3.fromRGB(32, 33, 28),
        editorBg = Color3.fromRGB(33, 34, 29), accent = Color3.fromRGB(166, 226, 46),
        keyword = Color3.fromRGB(249, 38, 114), builtin = Color3.fromRGB(166, 226, 46),
        stringVal = Color3.fromRGB(230, 219, 116), comment = Color3.fromRGB(117, 113, 94),
        stroke = Color3.fromRGB(60, 62, 50), lineNumBg = Color3.fromRGB(28, 29, 24),
    }),
    Solarized = makeTheme({
        mainBg = Color3.fromRGB(0, 36, 46), titleBg = Color3.fromRGB(0, 29, 38),
        editorBg = Color3.fromRGB(0, 33, 42), accent = Color3.fromRGB(38, 139, 210),
        keyword = Color3.fromRGB(133, 153, 0), builtin = Color3.fromRGB(42, 161, 152),
        stringVal = Color3.fromRGB(203, 75, 22), comment = Color3.fromRGB(101, 123, 131),
        stroke = Color3.fromRGB(7, 54, 66), lineNumBg = Color3.fromRGB(0, 27, 35),
    }),
    Light = makeTheme({
        mainBg = Color3.fromRGB(245, 245, 248), titleBg = Color3.fromRGB(235, 236, 240),
        toolbarBg = Color3.fromRGB(245, 245, 248), editorBg = Color3.fromRGB(255, 255, 255),
        tabBg = Color3.fromRGB(230, 232, 238), tabActiveBg = Color3.fromRGB(255, 255, 255),
        tabText = Color3.fromRGB(90, 95, 110), tabActiveText = Color3.fromRGB(40, 45, 60),
        text = Color3.fromRGB(50, 55, 70), lineNums = Color3.fromRGB(160, 165, 180),
        lineNumBg = Color3.fromRGB(240, 242, 248), divider = Color3.fromRGB(200, 205, 215),
        accent = Color3.fromRGB(0, 120, 215), keyword = Color3.fromRGB(175, 50, 120),
        builtin = Color3.fromRGB(100, 80, 180), stringVal = Color3.fromRGB(200, 120, 30),
        comment = Color3.fromRGB(130, 140, 150), identifier = Color3.fromRGB(50, 55, 70),
        errBg = Color3.fromRGB(255, 240, 240), stroke = Color3.fromRGB(200, 205, 215),
    }),
    Synapse = makeTheme({
        mainBg = Color3.fromRGB(20, 22, 27), titleBg = Color3.fromRGB(14, 16, 20),
        toolbarBg = Color3.fromRGB(24, 26, 32), editorBg = Color3.fromRGB(16, 18, 24),
        accent = Color3.fromRGB(88, 101, 242), keyword = Color3.fromRGB(88, 101, 242),
        builtin = Color3.fromRGB(235, 69, 158), stringVal = Color3.fromRGB(32, 200, 150),
        stroke = Color3.fromRGB(48, 52, 64),
    }),
}

s.customThemes = {}
s.currentThemeName = "Midnight"
s.currentTheme = themes[s.currentThemeName]
s.fontSize = 13
s.lineHeight = s.fontSize + 4
s.wordWrap = false
s.autoIndent = true
s.teBaseThemeName = "Midnight"
s.teBgStyle = "solid"
s.teColorBoxes = {}

--==================== SYNTAX HIGHLIGHTING ====================
local kw = {
    ["local"]=true,["function"]=true,["end"]=true,["if"]=true,["then"]=true,
    ["else"]=true,["elseif"]=true,["for"]=true,["while"]=true,["do"]=true,
    ["return"]=true,["break"]=true,["and"]=true,["or"]=true,["not"]=true,
    ["nil"]=true,["true"]=true,["false"]=true,["in"]=true,["repeat"]=true,
    ["until"]=true,["goto"]=true,["continue"]=true,
}

local builtin = {
    ["print"]=true,["warn"]=true,["error"]=true,["pairs"]=true,["ipairs"]=true,
    ["require"]=true,["tostring"]=true,["tonumber"]=true,["type"]=true,
    ["typeof"]=true,["pcall"]=true,["xpcall"]=true,["select"]=true,["next"]=true,
    ["rawget"]=true,["rawset"]=true,["setmetatable"]=true,["getmetatable"]=true,
    ["game"]=true,["workspace"]=true,["script"]=true,["task"]=true,["wait"]=true,
    ["spawn"]=true,["delay"]=true,["tick"]=true,["time"]=true,["Instance"]=true,
    ["Vector3"]=true,["CFrame"]=true,["Color3"]=true,["UDim2"]=true,["Enum"]=true,
    ["string"]=true,["table"]=true,["math"]=true,["os"]=true,["coroutine"]=true,
    ["debug"]=true,["bit32"]=true,["utf8"]=true,["loadstring"]=true,["getgenv"]=true,
    ["setclipboard"]=true,["Drawing"]=true,["hookfunction"]=true,["getrawmetatable"]=true,
    ["setreadonly"]=true,["getconnections"]=true,["getsenv"]=true,["getrenv"]=true,
    ["writefile"]=true,["readfile"]=true,["appendfile"]=true,["listfiles"]=true,
    ["makefolder"]=true,["delfile"]=true,["isfile"]=true,["isfolder"]=true,
    ["identifyexecutor"]=true,["syn"]=true,["assert"]=true,["collectgarbage"]=true,
}

local function tokenize(code)
    local tokens = {}
    local i, len = 1, #code
    while i <= len do
        local c = code:sub(i, i)
        if c == " " or c == "\t" then
            local st = i
            while i <= len and (code:sub(i,i) == " " or code:sub(i,i) == "\t") do i = i + 1 end
            tokens[#tokens+1] = {type="ws", text=code:sub(st, i-1)}
        elseif c == "\n" then
            tokens[#tokens+1] = {type="nl", text="\n"}; i = i + 1
        elseif c == "\r" then
            i = i + 1
        elseif c == "-" and code:sub(i+1, i+1) == "-" then
            local st = i
            if code:sub(i+2, i+2) == "[" then
                local eqs, j = 0, i + 2
                while code:sub(j,j) == "=" do eqs = eqs+1; j = j+1 end
                if code:sub(j,j) == "[" then
                    local close = "]"..string.rep("=",eqs).."]"
                    local ep = code:find(close, j+1, true)
                    i = ep and ep+#close or len+1
                else
                    while i <= len and code:sub(i,i) ~= "\n" do i = i+1 end
                end
            else
                while i <= len and code:sub(i,i) ~= "\n" do i = i+1 end
            end
            tokens[#tokens+1] = {type="comment", text=code:sub(st, i-1)}
        elseif c == '"' or c == "'" then
            local q = c; local st = i; i = i + 1
            while i <= len and code:sub(i,i) ~= q do
                if code:sub(i,i) == "\\" then i = i+1 end
                i = i+1
            end
            i = i+1
            tokens[#tokens+1] = {type="string", text=code:sub(st, math.min(i-1, len))}
        elseif c == "[" and (code:sub(i+1, i+1) == "[" or code:sub(i+1, i+1) == "=") then
            local st = i; local eqs, j = 0, i+1
            while code:sub(j,j) == "=" do eqs=eqs+1; j=j+1 end
            if code:sub(j,j) == "[" then
                local close = "]"..string.rep("=",eqs).."]"
                local ep = code:find(close, j+1, true)
                i = ep and ep+#close or len+1
                tokens[#tokens+1] = {type="string", text=code:sub(st, math.min(i-1, len))}
            else
                tokens[#tokens+1] = {type="op", text=c}; i = i+1
            end
        elseif c:match("[%d]") then
            local st = i
            while i <= len and code:sub(i,i):match("[%d%.xXa-fA-F]") do i=i+1 end
            tokens[#tokens+1] = {type="number", text=code:sub(st, i-1)}
        elseif c:match("[%a_]") then
            local st = i
            while i <= len and code:sub(i,i):match("[%w_]") do i=i+1 end
            local word = code:sub(st, i-1)
            local tp = "identifier"
            if kw[word] then tp = "keyword"
            elseif builtin[word] then tp = "builtin" end
            tokens[#tokens+1] = {type=tp, text=word}
        else
            tokens[#tokens+1] = {type="op", text=c}; i = i+1
        end
    end
    return tokens
end

local function escapeRT(text)
    return text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function colorHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end

local function buildHighlight(code)
    if #code > 12000 then return escapeRT(code) end
    local t = s.currentTheme
    local colors = {
        keyword = t.keyword, builtin = t.builtin, string = t.stringVal,
        number = t.numberVal, comment = t.comment, operator = t.operator,
        identifier = t.identifier, ws = t.identifier, nl = t.identifier,
    }
    local tokens = tokenize(code)
    local parts = {}
    for _, token in ipairs(tokens) do
        local color = colors[token.type] or t.identifier
        parts[#parts+1] = '<font color="'..colorHex(color)..'">'..escapeRT(token.text)..'</font>'
    end
    return table.concat(parts, "")
end

--==================== TEXT UTILS ====================
local function getVisibleLines(text, startLine, endLine)
    if startLine > endLine or startLine < 1 then return "" end
    local lines = {}
    local currentLine, pos = 1, 1
    local len = #text
    while pos <= len and currentLine <= endLine do
        local nextNL = text:find("\n", pos, true)
        local lineEnd = nextNL and (nextNL - 1) or len
        if currentLine >= startLine then lines[#lines+1] = text:sub(pos, lineEnd) end
        if nextNL then pos = nextNL + 1 else break end
        currentLine = currentLine + 1
    end
    return table.concat(lines, "\n")
end

local function calcLineCount(text)
    local count = 1
    for _ in text:gmatch("\n") do count = count + 1 end
    return count
end

local function getCursorLineCol(text, cursorPos)
    if not cursorPos or cursorPos < 1 then return 1, 1 end
    local line, col = 1, 1
    for i = 1, math.min(cursorPos - 1, #text) do
        if text:sub(i, i) == "\n" then line = line + 1; col = 1
        else col = col + 1 end
    end
    return line, col
end

local function getLineStart(text, lineNum)
    if lineNum <= 1 then return 1 end
    local current, pos = 1, 1
    while pos <= #text do
        if text:sub(pos, pos) == "\n" then
            current = current + 1
            if current == lineNum then return pos + 1 end
        end
        pos = pos + 1
    end
    return #text + 1
end

--==================== STATE ====================
s.tabs = {}
s.tabIdCounter = 0
s.activeTabId = 0
s.tabButtons = {}
s.snippets = {}
s.isCollapsed = false
s.lastSaveData = ""
s.fullText = ""
s.totalLineCount = 1
s.editingSnippetIndex = nil
s.editingThemeName = nil
s.themeEditorColors = {}
s.consoleMessages = {}
s.contextTabId = nil
s.contextItems = {}
s.themeCards = {}
s.hubResults = {}
s.hubPage = 1
s.hubMode = "free"
s.hubLoading = false
s.hubQuery = ""

local startingSnippets = {
    {name = "Print Debug", description = "Print a debug message", code = 'print("Debug:", var)'},
    {name = "Wait", description = "Wait 1 second", code = "task.wait(1)"},
    {name = "Local Player", description = "Get local player", code = 'local Players = game:GetService("Players")\nlocal player = Players.LocalPlayer'},
    {name = "Create Part", description = "Create a basic part", code = 'local part = Instance.new("Part")\npart.Size = Vector3.new(4, 1, 2)\npart.Position = Vector3.new(0, 10, 0)\npart.Parent = workspace'},
    {name = "For Loop", description = "Basic for loop", code = "for i = 1, 10 do\n    print(i)\nend"},
    {name = "Pcall Wrapper", description = "Error handling wrapper", code = "local ok, err = pcall(function()\n    -- Your code here\nend)\nif not ok then\n    warn('Error: ' .. err)\nend"},
    {name = "Fire Remote", description = "Fire a remote event", code = 'local remote = game.ReplicatedStorage:WaitForChild("RemoteName")\nremote:FireServer()'},
    {name = "Connect Event", description = "Connect to an event", code = 'local part = workspace.Part\npart.Touched:Connect(function(hit)\n    print(hit.Name)\nend)'},
}

local scriptTemplates = {
    {name = "Empty Script", code = ""},
    {name = "Server Script", code = "-- Server Script\nlocal Players = game:GetService(\"Players\")\n\nPlayers.PlayerAdded:Connect(function(player)\n    print(player.Name .. \" joined\")\nend)"},
    {name = "LocalScript", code = "-- LocalScript\nlocal Players = game:GetService(\"Players\")\nlocal player = Players.LocalPlayer\n\nprint(\"Hello, \" .. player.Name)"},
    {name = "Remote Event Setup", code = "-- Remote Event Setup\nlocal RS = game:GetService(\"ReplicatedStorage\")\nlocal remote = Instance.new(\"RemoteEvent\")\nremote.Name = \"MyRemote\"\nremote.Parent = RS\n\nremote.OnServerEvent:Connect(function(player, ...)\n    print(player.Name, \"fired remote\")\nend)"},
    {name = "GUI Template", code = "-- GUI Template\nlocal player = game.Players.LocalPlayer\nlocal gui = Instance.new(\"ScreenGui\")\ngui.Name = \"MyGui\"\ngui.ResetOnSpawn = false\ngui.Parent = player:WaitForChild(\"PlayerGui\")\n\nlocal frame = Instance.new(\"Frame\")\nframe.Size = UDim2.new(0, 200, 0, 100)\nframe.Position = UDim2.new(0.5, -100, 0.5, -50)\nframe.Parent = gui"},
}

--==================== COREGUI SETUP ====================
local existing = CoreGui:FindFirstChild("ExecutorPro")
if existing then existing:Destroy() end

s.guiFolder = Instance.new("Folder")
s.guiFolder.Name = "ExecutorPro"
s.guiFolder.Parent = CoreGui

u.mainScreen = Instance.new("ScreenGui")
u.mainScreen.Name = "MainUI"
u.mainScreen.ResetOnSpawn = false
u.mainScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
u.mainScreen.Parent = s.guiFolder

u.settingsScreen = Instance.new("ScreenGui")
u.settingsScreen.Name = "SettingsUI"
u.settingsScreen.ResetOnSpawn = false
u.settingsScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
u.settingsScreen.Enabled = false
u.settingsScreen.Parent = s.guiFolder

--==================== UI HELPER ====================
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local st = Instance.new("UIStroke")
    st.Color = color or s.currentTheme.stroke
    st.Thickness = thickness or 1
    st.Parent = parent
    return st
end

local function pad(parent, t, r, b, l)
    local p = Instance.new("UIPadding")
    if t then p.PaddingTop = UDim.new(0, t) end
    if r then p.PaddingRight = UDim.new(0, r) end
    if b then p.PaddingBottom = UDim.new(0, b) end
    if l then p.PaddingLeft = UDim.new(0, l) end
    p.Parent = parent
    return p
end

--==================== BUILD MAIN UI ====================
u.MainFrame = Instance.new("Frame")
u.MainFrame.Size = UDim2.new(0, 700, 0, 540)
u.MainFrame.Position = UDim2.new(0.5, -350, 0.5, -270)
u.MainFrame.BackgroundColor3 = s.currentTheme.mainBg
u.MainFrame.BorderSizePixel = 0
u.MainFrame.Active = true
u.MainFrame.Draggable = true
u.MainFrame.Parent = u.mainScreen
corner(u.MainFrame, 10)
u.MainStroke = stroke(u.MainFrame)
u.MainGradient = Instance.new("UIGradient")
u.MainGradient.Rotation = 90
u.MainGradient.Parent = u.MainFrame

-- Title Bar
u.TitleBar = Instance.new("Frame")
u.TitleBar.Size = UDim2.new(1, 0, 0, 38)
u.TitleBar.BackgroundColor3 = s.currentTheme.titleBg
u.TitleBar.BorderSizePixel = 0
u.TitleBar.Parent = u.MainFrame
corner(u.TitleBar, 10)
u.titleFix = Instance.new("Frame")
u.titleFix.Size = UDim2.new(1, 0, 0, 10)
u.titleFix.Position = UDim2.new(0, 0, 1, -10)
u.titleFix.BackgroundColor3 = s.currentTheme.titleBg
u.titleFix.BorderSizePixel = 0
u.titleFix.Parent = u.TitleBar

u.TitleLabel = Instance.new("TextLabel")
u.TitleLabel.Size = UDim2.new(0, 200, 1, 0)
u.TitleLabel.Position = UDim2.new(0, 14, 0, 0)
u.TitleLabel.BackgroundTransparency = 1
u.TitleLabel.Font = Enum.Font.GothamSemibold
u.TitleLabel.Text = "⚡ Executor Pro"
u.TitleLabel.TextColor3 = s.currentTheme.text
u.TitleLabel.TextSize = 14
u.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
u.TitleLabel.Parent = u.TitleBar

u.SaveIndicator = Instance.new("TextLabel")
u.SaveIndicator.Size = UDim2.new(0, 70, 1, 0)
u.SaveIndicator.Position = UDim2.new(1, -370, 0, 0)
u.SaveIndicator.BackgroundTransparency = 1
u.SaveIndicator.Font = Enum.Font.Gotham
u.SaveIndicator.Text = "● Saved"
u.SaveIndicator.TextColor3 = s.currentTheme.errSuccess
u.SaveIndicator.TextSize = 11
u.SaveIndicator.TextXAlignment = Enum.TextXAlignment.Right
u.SaveIndicator.Parent = u.TitleBar

u.ExecBadge = Instance.new("TextLabel")
u.ExecBadge.Size = UDim2.new(0, 100, 0, 22)
u.ExecBadge.Position = UDim2.new(1, -280, 0.5, -11)
u.ExecBadge.BackgroundColor3 = s.currentTheme.tabBg
u.ExecBadge.BorderSizePixel = 0
u.ExecBadge.Font = Enum.Font.GothamMedium
u.ExecBadge.Text = s.execName
u.ExecBadge.TextColor3 = s.currentTheme.text
u.ExecBadge.TextSize = 10
u.ExecBadge.Parent = u.TitleBar
corner(u.ExecBadge, 5)

-- Title buttons
local function makeTitleBtn(icon, x, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 28, 0, 28)
    btn.Position = UDim2.new(1, x, 0.5, -14)
    btn.BackgroundColor3 = s.currentTheme.tabBg
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.Text = text or icon
    btn.TextColor3 = s.currentTheme.text
    btn.TextSize = 12
    btn.Parent = u.TitleBar
    corner(btn, 6)
    return btn
end

u.TemplatesBtn = makeTitleBtn("📄", -168, "📄")
u.FindBtn = makeTitleBtn("🔍", -138, "🔍")
u.SettingsBtn = makeTitleBtn("⚙", -108, "⚙")
u.CollapseBtn = makeTitleBtn("—", -72, "—")
u.CollapseBtn.Font = Enum.Font.GothamBold
u.CollapseBtn.TextSize = 14

u.CloseBtn = Instance.new("TextButton")
u.CloseBtn.Size = UDim2.new(0, 28, 0, 28)
u.CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
u.CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
u.CloseBtn.BorderSizePixel = 0
u.CloseBtn.Font = Enum.Font.GothamBold
u.CloseBtn.Text = "✕"
u.CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.CloseBtn.TextSize = 12
u.CloseBtn.Parent = u.TitleBar
corner(u.CloseBtn, 6)

-- Tab Bar
u.TabBar = Instance.new("ScrollingFrame")
u.TabBar.Size = UDim2.new(1, -24, 0, 30)
u.TabBar.Position = UDim2.new(0, 12, 0, 42)
u.TabBar.BackgroundColor3 = s.currentTheme.editorBg
u.TabBar.BorderSizePixel = 0
u.TabBar.ScrollBarThickness = 0
u.TabBar.ScrollingDirection = Enum.ScrollingDirection.X
u.TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
u.TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
u.TabBar.Parent = u.MainFrame
corner(u.TabBar, 6)

u.tabLayout = Instance.new("UIListLayout")
u.tabLayout.FillDirection = Enum.FillDirection.Horizontal
u.tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.tabLayout.Padding = UDim.new(0, 2)
u.tabLayout.Parent = u.TabBar
pad(u.TabBar, 3, 0, 0, 4)

-- Toolbar
u.Toolbar = Instance.new("Frame")
u.Toolbar.Size = UDim2.new(1, -24, 0, 34)
u.Toolbar.Position = UDim2.new(0, 12, 0, 76)
u.Toolbar.BackgroundColor3 = s.currentTheme.toolbarBg
u.Toolbar.BorderSizePixel = 0
u.Toolbar.Parent = u.MainFrame
corner(u.Toolbar, 6)

local function makeToolbarBtn(name, text, x, bg)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 80, 0, 24)
    btn.Position = UDim2.new(0, x, 0.5, -12)
    btn.BackgroundColor3 = bg
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = s.currentTheme.text
    btn.TextSize = 12
    btn.Parent = u.Toolbar
    corner(btn, 5)
    return btn
end

u.ExecuteBtn = makeToolbarBtn("ExecuteBtn", "▶ Execute", 10, s.currentTheme.accent)
u.ExecuteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.ExecuteBtn.Font = Enum.Font.GothamBold
u.ClearBtn = makeToolbarBtn("ClearBtn", "Clear", 100, s.currentTheme.tabBg)
u.CopyBtn = makeToolbarBtn("CopyBtn", "Copy", 180, s.currentTheme.tabBg)
u.NewLineBtn = makeToolbarBtn("NewLineBtn", "New Line", 260, s.currentTheme.tabBg)
u.SnippetsBtn = makeToolbarBtn("SnippetsBtn", "Snippets", 350, s.currentTheme.tabBg)
u.SnippetsBtn.Size = UDim2.new(0, 90, 0, 24)
u.FormatBtn = makeToolbarBtn("FormatBtn", "Format", 450, s.currentTheme.tabBg)
u.FormatBtn.Size = UDim2.new(0, 70, 0, 24)
u.HubBtn = makeToolbarBtn("HubBtn", "Script Hub", 530, s.currentTheme.accentSecondary or s.currentTheme.accent)
u.HubBtn.Size = UDim2.new(0, 90, 0, 24)
u.HubBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.HubBtn.Font = Enum.Font.GothamBold

-- Dropdowns (Templates, Snippets)
u.TemplatesDropdown = Instance.new("Frame")
u.TemplatesDropdown.Size = UDim2.new(0, 260, 0, 0)
u.TemplatesDropdown.BackgroundColor3 = s.currentTheme.titleBg
u.TemplatesDropdown.BorderSizePixel = 0
u.TemplatesDropdown.Visible = false
u.TemplatesDropdown.ZIndex = 20
u.TemplatesDropdown.Parent = u.MainFrame
corner(u.TemplatesDropdown, 8)
stroke(u.TemplatesDropdown)

u.tdScroll = Instance.new("ScrollingFrame")
u.tdScroll.Size = UDim2.new(1, -8, 1, -8)
u.tdScroll.Position = UDim2.new(0, 4, 0, 4)
u.tdScroll.BackgroundTransparency = 1
u.tdScroll.BorderSizePixel = 0
u.tdScroll.ScrollBarThickness = 4
u.tdScroll.ScrollBarImageColor3 = s.currentTheme.scrollbar
u.tdScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
u.tdScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
u.tdScroll.ZIndex = 21
u.tdScroll.Parent = u.TemplatesDropdown

u.tdLayout = Instance.new("UIListLayout")
u.tdLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.tdLayout.Padding = UDim.new(0, 2)
u.tdLayout.Parent = u.tdScroll

u.SnippetsDropdown = Instance.new("Frame")
u.SnippetsDropdown.Size = UDim2.new(0, 260, 0, 0)
u.SnippetsDropdown.BackgroundColor3 = s.currentTheme.titleBg
u.SnippetsDropdown.BorderSizePixel = 0
u.SnippetsDropdown.Visible = false
u.SnippetsDropdown.ZIndex = 20
u.SnippetsDropdown.Parent = u.MainFrame
corner(u.SnippetsDropdown, 8)
stroke(u.SnippetsDropdown)

u.sdScroll = Instance.new("ScrollingFrame")
u.sdScroll.Size = UDim2.new(1, -8, 1, -48)
u.sdScroll.Position = UDim2.new(0, 4, 0, 4)
u.sdScroll.BackgroundTransparency = 1
u.sdScroll.BorderSizePixel = 0
u.sdScroll.ScrollBarThickness = 4
u.sdScroll.ScrollBarImageColor3 = s.currentTheme.scrollbar
u.sdScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
u.sdScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
u.sdScroll.ZIndex = 21
u.sdScroll.Parent = u.SnippetsDropdown

u.sdLayout = Instance.new("UIListLayout")
u.sdLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.sdLayout.Padding = UDim.new(0, 2)
u.sdLayout.Parent = u.sdScroll

u.sdAddBtn = Instance.new("TextButton")
u.sdAddBtn.Size = UDim2.new(1, -8, 0, 30)
u.sdAddBtn.Position = UDim2.new(0, 4, 1, -36)
u.sdAddBtn.BackgroundColor3 = s.currentTheme.accent
u.sdAddBtn.BorderSizePixel = 0
u.sdAddBtn.Font = Enum.Font.GothamBold
u.sdAddBtn.Text = "+ Save Current as Snippet"
u.sdAddBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.sdAddBtn.TextSize = 11
u.sdAddBtn.ZIndex = 21
u.sdAddBtn.Parent = u.SnippetsDropdown
corner(u.sdAddBtn, 6)

-- Find Bar
u.FindBar = Instance.new("Frame")
u.FindBar.Size = UDim2.new(0, 400, 0, 70)
u.FindBar.Position = UDim2.new(1, -414, 0, 42)
u.FindBar.BackgroundColor3 = s.currentTheme.titleBg
u.FindBar.BorderSizePixel = 0
u.FindBar.Visible = false
u.FindBar.ZIndex = 25
u.FindBar.Parent = u.MainFrame
corner(u.FindBar, 8)
stroke(u.FindBar)

local function makeTextBox(parent, x, y, w, h, placeholder, isCode)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, w, 0, h)
    box.Position = UDim2.new(0, x, 0, y)
    box.BackgroundColor3 = s.currentTheme.editorBg
    box.BorderSizePixel = 0
    box.Font = isCode and Enum.Font.Code or Enum.Font.GothamMedium
    box.Text = ""
    box.PlaceholderText = placeholder
    box.TextColor3 = s.currentTheme.text
    box.PlaceholderColor3 = s.currentTheme.lineNums
    box.TextSize = 12
    box.ZIndex = 26
    box.Parent = parent
    corner(box, 5)
    return box
end

u.FindBox = makeTextBox(u.FindBar, 10, 8, 150, 24, "Find...", true)
u.ReplaceBox = makeTextBox(u.FindBar, 10, 38, 150, 24, "Replace...", true)

local function makeSmallBtn(parent, x, y, w, text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, w, 0, 22)
    btn.Position = UDim2.new(0, x, 0, y)
    btn.BackgroundColor3 = s.currentTheme.tabBg
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = s.currentTheme.text
    btn.TextSize = 11
    btn.ZIndex = 26
    btn.Parent = parent
    corner(btn, 5)
    return btn
end

u.FindNextBtn = makeSmallBtn(u.FindBar, 168, 8, 60, "Next")
u.ReplaceBtn = makeSmallBtn(u.FindBar, 168, 38, 60, "Replace")
u.ReplaceAllBtn = makeSmallBtn(u.FindBar, 232, 38, 70, "Replace All")
u.ReplaceAllBtn.TextSize = 10

u.FindCloseBtn = Instance.new("TextButton")
u.FindCloseBtn.Size = UDim2.new(0, 22, 0, 22)
u.FindCloseBtn.Position = UDim2.new(1, -28, 0, 8)
u.FindCloseBtn.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
u.FindCloseBtn.BorderSizePixel = 0
u.FindCloseBtn.Font = Enum.Font.GothamBold
u.FindCloseBtn.Text = "✕"
u.FindCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.FindCloseBtn.TextSize = 10
u.FindCloseBtn.ZIndex = 26
u.FindCloseBtn.Parent = u.FindBar
corner(u.FindCloseBtn, 5)

u.FindMatchLabel = Instance.new("TextLabel")
u.FindMatchLabel.Size = UDim2.new(0, 100, 0, 16)
u.FindMatchLabel.Position = UDim2.new(1, -110, 0, 12)
u.FindMatchLabel.BackgroundTransparency = 1
u.FindMatchLabel.Font = Enum.Font.Gotham
u.FindMatchLabel.Text = ""
u.FindMatchLabel.TextColor3 = s.currentTheme.lineNums
u.FindMatchLabel.TextSize = 10
u.FindMatchLabel.TextXAlignment = Enum.TextXAlignment.Right
u.FindMatchLabel.ZIndex = 26
u.FindMatchLabel.Parent = u.FindBar

-- Goto Dialog
u.GotoFrame = Instance.new("Frame")
u.GotoFrame.Size = UDim2.new(0, 220, 0, 80)
u.GotoFrame.Position = UDim2.new(0.5, -110, 0.5, -40)
u.GotoFrame.BackgroundColor3 = s.currentTheme.mainBg
u.GotoFrame.BorderSizePixel = 0
u.GotoFrame.Visible = false
u.GotoFrame.ZIndex = 30
u.GotoFrame.Parent = u.mainScreen
corner(u.GotoFrame, 8)
stroke(u.GotoFrame)

u.GotoLabel = Instance.new("TextLabel")
u.GotoLabel.Size = UDim2.new(1, -20, 0, 20)
u.GotoLabel.Position = UDim2.new(0, 10, 0, 8)
u.GotoLabel.BackgroundTransparency = 1
u.GotoLabel.Font = Enum.Font.GothamMedium
u.GotoLabel.Text = "Go to line:"
u.GotoLabel.TextColor3 = s.currentTheme.text
u.GotoLabel.TextSize = 12
u.GotoLabel.TextXAlignment = Enum.TextXAlignment.Left
u.GotoLabel.ZIndex = 31
u.GotoLabel.Parent = u.GotoFrame

u.GotoBox = makeTextBox(u.GotoFrame, 10, 32, 200, 28, "Line number...", true)
u.GotoBox.ZIndex = 31

u.GotoGoBtn = Instance.new("TextButton")
u.GotoGoBtn.Size = UDim2.new(0, 60, 0, 20)
u.GotoGoBtn.Position = UDim2.new(1, -68, 1, -26)
u.GotoGoBtn.BackgroundColor3 = s.currentTheme.accent
u.GotoGoBtn.BorderSizePixel = 0
u.GotoGoBtn.Font = Enum.Font.GothamBold
u.GotoGoBtn.Text = "Go"
u.GotoGoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.GotoGoBtn.TextSize = 11
u.GotoGoBtn.ZIndex = 31
u.GotoGoBtn.Parent = u.GotoFrame
corner(u.GotoGoBtn, 5)

-- Game ID Dialog
u.GameIdFrame = Instance.new("Frame")
u.GameIdFrame.Size = UDim2.new(0, 240, 0, 90)
u.GameIdFrame.Position = UDim2.new(0.5, -120, 0.5, -45)
u.GameIdFrame.BackgroundColor3 = s.currentTheme.mainBg
u.GameIdFrame.BorderSizePixel = 0
u.GameIdFrame.Visible = false
u.GameIdFrame.ZIndex = 30
u.GameIdFrame.Parent = u.mainScreen
corner(u.GameIdFrame, 8)
stroke(u.GameIdFrame)

u.GameIdLabel = Instance.new("TextLabel")
u.GameIdLabel.Size = UDim2.new(1, -20, 0, 20)
u.GameIdLabel.Position = UDim2.new(0, 10, 0, 8)
u.GameIdLabel.BackgroundTransparency = 1
u.GameIdLabel.Font = Enum.Font.GothamMedium
u.GameIdLabel.Text = "Enter Place ID (blank = all games):"
u.GameIdLabel.TextColor3 = s.currentTheme.text
u.GameIdLabel.TextSize = 11
u.GameIdLabel.TextXAlignment = Enum.TextXAlignment.Left
u.GameIdLabel.ZIndex = 31
u.GameIdLabel.Parent = u.GameIdFrame

u.GameIdBox = makeTextBox(u.GameIdFrame, 10, 30, 220, 28, "Place ID...", true)
u.GameIdBox.ZIndex = 31

u.GameIdSaveBtn = Instance.new("TextButton")
u.GameIdSaveBtn.Size = UDim2.new(0, 60, 0, 20)
u.GameIdSaveBtn.Position = UDim2.new(1, -68, 1, -26)
u.GameIdSaveBtn.BackgroundColor3 = s.currentTheme.accent
u.GameIdSaveBtn.BorderSizePixel = 0
u.GameIdSaveBtn.Font = Enum.Font.GothamBold
u.GameIdSaveBtn.Text = "Save"
u.GameIdSaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.GameIdSaveBtn.TextSize = 11
u.GameIdSaveBtn.ZIndex = 31
u.GameIdSaveBtn.Parent = u.GameIdFrame
corner(u.GameIdSaveBtn, 5)

-- Command Palette
u.CmdPalette = Instance.new("Frame")
u.CmdPalette.Size = UDim2.new(0, 400, 0, 36)
u.CmdPalette.Position = UDim2.new(0.5, -200, 0, 20)
u.CmdPalette.BackgroundColor3 = s.currentTheme.titleBg
u.CmdPalette.BorderSizePixel = 0
u.CmdPalette.Visible = false
u.CmdPalette.ZIndex = 40
u.CmdPalette.Parent = u.mainScreen
corner(u.CmdPalette, 8)
stroke(u.CmdPalette)

u.CmdBox = Instance.new("TextBox")
u.CmdBox.Size = UDim2.new(1, -20, 1, -8)
u.CmdBox.Position = UDim2.new(0, 10, 0, 4)
u.CmdBox.BackgroundTransparency = 1
u.CmdBox.Font = Enum.Font.GothamMedium
u.CmdBox.Text = ""
u.CmdBox.PlaceholderText = "Type a command..."
u.CmdBox.TextColor3 = s.currentTheme.text
u.CmdBox.PlaceholderColor3 = s.currentTheme.lineNums
u.CmdBox.TextSize = 13
u.CmdBox.TextXAlignment = Enum.TextXAlignment.Left
u.CmdBox.ZIndex = 41
u.CmdBox.Parent = u.CmdPalette

u.CmdResults = Instance.new("ScrollingFrame")
u.CmdResults.Size = UDim2.new(1, 0, 0, 0)
u.CmdResults.Position = UDim2.new(0, 0, 1, 4)
u.CmdResults.BackgroundColor3 = s.currentTheme.titleBg
u.CmdResults.BorderSizePixel = 0
u.CmdResults.ScrollBarThickness = 4
u.CmdResults.Visible = false
u.CmdResults.ZIndex = 40
u.CmdResults.Parent = u.CmdPalette
corner(u.CmdResults, 8)
stroke(u.CmdResults)

u.crLayout = Instance.new("UIListLayout")
u.crLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.crLayout.Padding = UDim.new(0, 1)
u.crLayout.Parent = u.CmdResults

-- Script Hub Panel
u.HubPanel = Instance.new("Frame")
u.HubPanel.Size = UDim2.new(0, 520, 0, 420)
u.HubPanel.Position = UDim2.new(0.5, -260, 0.5, -210)
u.HubPanel.BackgroundColor3 = s.currentTheme.mainBg
u.HubPanel.BorderSizePixel = 0
u.HubPanel.Visible = false
u.HubPanel.ZIndex = 35
u.HubPanel.Parent = u.mainScreen
corner(u.HubPanel, 10)
stroke(u.HubPanel)

u.HubTitle = Instance.new("TextLabel")
u.HubTitle.Size = UDim2.new(1, -20, 0, 36)
u.HubTitle.Position = UDim2.new(0, 14, 0, 0)
u.HubTitle.BackgroundTransparency = 1
u.HubTitle.Font = Enum.Font.GothamSemibold
u.HubTitle.Text = "📦 Script Hub (ScriptBlox)"
u.HubTitle.TextColor3 = s.currentTheme.text
u.HubTitle.TextSize = 14
u.HubTitle.TextXAlignment = Enum.TextXAlignment.Left
u.HubTitle.ZIndex = 36
u.HubTitle.Parent = u.HubPanel

u.HubClose = Instance.new("TextButton")
u.HubClose.Size = UDim2.new(0, 26, 0, 26)
u.HubClose.Position = UDim2.new(1, -34, 0, 6)
u.HubClose.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
u.HubClose.BorderSizePixel = 0
u.HubClose.Font = Enum.Font.GothamBold
u.HubClose.Text = "✕"
u.HubClose.TextColor3 = Color3.fromRGB(255, 255, 255)
u.HubClose.TextSize = 12
u.HubClose.ZIndex = 36
u.HubClose.Parent = u.HubPanel
corner(u.HubClose, 6)

u.HubSearchBox = makeTextBox(u.HubPanel, 14, 42, 250, 28, "Search scripts...", false)
u.HubSearchBox.ZIndex = 36

u.HubFilterBtn = Instance.new("TextButton")
u.HubFilterBtn.Size = UDim2.new(0, 80, 0, 28)
u.HubFilterBtn.Position = UDim2.new(0, 272, 0, 42)
u.HubFilterBtn.BackgroundColor3 = s.currentTheme.tabBg
u.HubFilterBtn.BorderSizePixel = 0
u.HubFilterBtn.Font = Enum.Font.GothamSemibold
u.HubFilterBtn.Text = "Keyless ▾"
u.HubFilterBtn.TextColor3 = s.currentTheme.text
u.HubFilterBtn.TextSize = 11
u.HubFilterBtn.ZIndex = 36
u.HubFilterBtn.Parent = u.HubPanel
corner(u.HubFilterBtn, 5)

u.HubSearchBtn = Instance.new("TextButton")
u.HubSearchBtn.Size = UDim2.new(0, 60, 0, 28)
u.HubSearchBtn.Position = UDim2.new(0, 360, 0, 42)
u.HubSearchBtn.BackgroundColor3 = s.currentTheme.accent
u.HubSearchBtn.BorderSizePixel = 0
u.HubSearchBtn.Font = Enum.Font.GothamBold
u.HubSearchBtn.Text = "Search"
u.HubSearchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.HubSearchBtn.TextSize = 11
u.HubSearchBtn.ZIndex = 36
u.HubSearchBtn.Parent = u.HubPanel
corner(u.HubSearchBtn, 5)

u.HubScroll = Instance.new("ScrollingFrame")
u.HubScroll.Size = UDim2.new(1, -28, 1, -100)
u.HubScroll.Position = UDim2.new(0, 14, 0, 80)
u.HubScroll.BackgroundTransparency = 1
u.HubScroll.BorderSizePixel = 0
u.HubScroll.ScrollBarThickness = 4
u.HubScroll.ScrollBarImageColor3 = s.currentTheme.scrollbar
u.HubScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
u.HubScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
u.HubScroll.ZIndex = 36
u.HubScroll.Parent = u.HubPanel

u.HubListLayout = Instance.new("UIListLayout")
u.HubListLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.HubListLayout.Padding = UDim.new(0, 4)
u.HubListLayout.Parent = u.HubScroll

u.HubStatus = Instance.new("TextLabel")
u.HubStatus.Size = UDim2.new(1, -28, 0, 20)
u.HubStatus.Position = UDim2.new(0, 14, 1, -28)
u.HubStatus.BackgroundTransparency = 1
u.HubStatus.Font = Enum.Font.Gotham
u.HubStatus.Text = ""
u.HubStatus.TextColor3 = s.currentTheme.lineNums
u.HubStatus.TextSize = 10
u.HubStatus.TextXAlignment = Enum.TextXAlignment.Left
u.HubStatus.ZIndex = 36
u.HubStatus.Parent = u.HubPanel

u.HubLoadMoreBtn = Instance.new("TextButton")
u.HubLoadMoreBtn.Size = UDim2.new(1, -8, 0, 30)
u.HubLoadMoreBtn.BackgroundColor3 = s.currentTheme.tabBg
u.HubLoadMoreBtn.BorderSizePixel = 0
u.HubLoadMoreBtn.Font = Enum.Font.GothamSemibold
u.HubLoadMoreBtn.Text = "Load More"
u.HubLoadMoreBtn.TextColor3 = s.currentTheme.text
u.HubLoadMoreBtn.TextSize = 11
u.HubLoadMoreBtn.ZIndex = 36
u.HubLoadMoreBtn.Visible = false
u.HubLoadMoreBtn.Parent = u.HubScroll
corner(u.HubLoadMoreBtn, 5)

-- Editor
u.EditorContainer = Instance.new("Frame")
u.EditorContainer.Size = UDim2.new(1, -24, 1, -210)
u.EditorContainer.Position = UDim2.new(0, 12, 0, 116)
u.EditorContainer.BackgroundColor3 = s.currentTheme.editorBg
u.EditorContainer.BorderSizePixel = 0
u.EditorContainer.Parent = u.MainFrame
corner(u.EditorContainer, 8)
u.ecStroke = stroke(u.EditorContainer, s.currentTheme.divider)

u.EditorScroll = Instance.new("ScrollingFrame")
u.EditorScroll.Size = UDim2.new(1, -4, 1, -4)
u.EditorScroll.Position = UDim2.new(0, 2, 0, 2)
u.EditorScroll.BackgroundTransparency = 1
u.EditorScroll.BorderSizePixel = 0
u.EditorScroll.ScrollBarThickness = 6
u.EditorScroll.ScrollBarImageColor3 = s.currentTheme.scrollbar
u.EditorScroll.ScrollingDirection = Enum.ScrollingDirection.Y
u.EditorScroll.CanvasSize = UDim2.new(0, 0, 0, 200)
u.EditorScroll.ClipsDescendants = true
u.EditorScroll.Parent = u.EditorContainer
corner(u.EditorScroll, 7)

u.EditorContent = Instance.new("Frame")
u.EditorContent.Size = UDim2.new(1, 0, 0, 200)
u.EditorContent.BackgroundTransparency = 1
u.EditorContent.BorderSizePixel = 0
u.EditorContent.Parent = u.EditorScroll

u.LineNumbers = Instance.new("TextLabel")
u.LineNumbers.Size = UDim2.new(0, 40, 0, 200)
u.LineNumbers.BackgroundColor3 = s.currentTheme.lineNumBg
u.LineNumbers.BorderSizePixel = 0
u.LineNumbers.Font = Enum.Font.Code
u.LineNumbers.Text = "1"
u.LineNumbers.TextColor3 = s.currentTheme.lineNums
u.LineNumbers.TextSize = s.fontSize
u.LineNumbers.TextXAlignment = Enum.TextXAlignment.Right
u.LineNumbers.TextYAlignment = Enum.TextYAlignment.Top
u.LineNumbers.Parent = u.EditorContent
pad(u.LineNumbers, 6, 6)

u.lnDivider = Instance.new("Frame")
u.lnDivider.Size = UDim2.new(0, 1, 0, 200)
u.lnDivider.Position = UDim2.new(0, 40, 0, 0)
u.lnDivider.BackgroundColor3 = s.currentTheme.divider
u.lnDivider.BorderSizePixel = 0
u.lnDivider.Parent = u.EditorContent

u.HighlightedCode = Instance.new("TextLabel")
u.HighlightedCode.Size = UDim2.new(1, -44, 0, 200)
u.HighlightedCode.Position = UDim2.new(0, 42, 0, 0)
u.HighlightedCode.BackgroundTransparency = 1
u.HighlightedCode.Font = Enum.Font.Code
u.HighlightedCode.Text = ""
u.HighlightedCode.RichText = true
u.HighlightedCode.TextColor3 = s.currentTheme.identifier
u.HighlightedCode.TextSize = s.fontSize
u.HighlightedCode.TextXAlignment = Enum.TextXAlignment.Left
u.HighlightedCode.TextYAlignment = Enum.TextYAlignment.Top
u.HighlightedCode.Parent = u.EditorContent
pad(u.HighlightedCode, 6)

u.EditorTextBox = Instance.new("TextBox")
u.EditorTextBox.Size = UDim2.new(1, -44, 0, 200)
u.EditorTextBox.Position = UDim2.new(0, 42, 0, 0)
u.EditorTextBox.BackgroundTransparency = 1
u.EditorTextBox.Font = Enum.Font.Code
u.EditorTextBox.Text = "-- Welcome to Executor Pro\nprint('Hello World')"
u.EditorTextBox.TextColor3 = s.currentTheme.text
u.EditorTextBox.TextSize = s.fontSize
u.EditorTextBox.TextXAlignment = Enum.TextXAlignment.Left
u.EditorTextBox.TextYAlignment = Enum.TextYAlignment.Top
u.EditorTextBox.ClearTextOnFocus = false
u.EditorTextBox.MultiLine = true
u.EditorTextBox.TextTransparency = 1
u.EditorTextBox.Parent = u.EditorContent
pad(u.EditorTextBox, 6)

-- Console
u.ConsoleFrame = Instance.new("Frame")
u.ConsoleFrame.Size = UDim2.new(1, -24, 0, 0)
u.ConsoleFrame.Position = UDim2.new(0, 12, 1, -4)
u.ConsoleFrame.BackgroundColor3 = s.currentTheme.titleBg
u.ConsoleFrame.BorderSizePixel = 0
u.ConsoleFrame.Visible = false
u.ConsoleFrame.Parent = u.MainFrame
corner(u.ConsoleFrame, 8)

u.ConsoleHeader = Instance.new("Frame")
u.ConsoleHeader.Size = UDim2.new(1, 0, 0, 24)
u.ConsoleHeader.BackgroundColor3 = s.currentTheme.titleBg
u.ConsoleHeader.BorderSizePixel = 0
u.ConsoleHeader.Parent = u.ConsoleFrame
corner(u.ConsoleHeader, 8)

u.ConsoleTitle = Instance.new("TextLabel")
u.ConsoleTitle.Size = UDim2.new(0, 100, 1, 0)
u.ConsoleTitle.Position = UDim2.new(0, 10, 0, 0)
u.ConsoleTitle.BackgroundTransparency = 1
u.ConsoleTitle.Font = Enum.Font.GothamSemibold
u.ConsoleTitle.Text = "Console"
u.ConsoleTitle.TextColor3 = s.currentTheme.text
u.ConsoleTitle.TextSize = 12
u.ConsoleTitle.TextXAlignment = Enum.TextXAlignment.Left
u.ConsoleTitle.Parent = u.ConsoleHeader

u.ConsoleClearBtn = Instance.new("TextButton")
u.ConsoleClearBtn.Size = UDim2.new(0, 50, 0, 20)
u.ConsoleClearBtn.Position = UDim2.new(1, -58, 0.5, -10)
u.ConsoleClearBtn.BackgroundColor3 = s.currentTheme.tabBg
u.ConsoleClearBtn.BorderSizePixel = 0
u.ConsoleClearBtn.Font = Enum.Font.GothamSemibold
u.ConsoleClearBtn.Text = "Clear"
u.ConsoleClearBtn.TextColor3 = s.currentTheme.text
u.ConsoleClearBtn.TextSize = 10
u.ConsoleClearBtn.Parent = u.ConsoleHeader
corner(u.ConsoleClearBtn, 4)

u.ConsoleScroll = Instance.new("ScrollingFrame")
u.ConsoleScroll.Size = UDim2.new(1, -8, 1, -32)
u.ConsoleScroll.Position = UDim2.new(0, 4, 0, 28)
u.ConsoleScroll.BackgroundTransparency = 1
u.ConsoleScroll.BorderSizePixel = 0
u.ConsoleScroll.ScrollBarThickness = 4
u.ConsoleScroll.ScrollBarImageColor3 = s.currentTheme.scrollbar
u.ConsoleScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
u.ConsoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
u.ConsoleScroll.Parent = u.ConsoleFrame

u.csLayout = Instance.new("UIListLayout")
u.csLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.csLayout.Padding = UDim.new(0, 1)
u.csLayout.Parent = u.ConsoleScroll

-- Status Bar
u.StatusBar = Instance.new("Frame")
u.StatusBar.Size = UDim2.new(1, -24, 0, 22)
u.StatusBar.Position = UDim2.new(0, 12, 1, -26)
u.StatusBar.BackgroundColor3 = s.currentTheme.titleBg
u.StatusBar.BorderSizePixel = 0
u.StatusBar.Parent = u.MainFrame
corner(u.StatusBar, 6)

u.StatusLeft = Instance.new("TextLabel")
u.StatusLeft.Size = UDim2.new(0.5, 0, 1, 0)
u.StatusLeft.BackgroundTransparency = 1
u.StatusLeft.Font = Enum.Font.Code
u.StatusLeft.Text = "Ln 1, Col 1"
u.StatusLeft.TextColor3 = s.currentTheme.lineNums
u.StatusLeft.TextSize = 10
u.StatusLeft.TextXAlignment = Enum.TextXAlignment.Left
u.StatusLeft.Parent = u.StatusBar
pad(u.StatusLeft, 0, 0, 0, 8)

u.StatusRight = Instance.new("TextLabel")
u.StatusRight.Size = UDim2.new(0.5, 0, 1, 0)
u.StatusRight.Position = UDim2.new(0.5, 0, 0, 0)
u.StatusRight.BackgroundTransparency = 1
u.StatusRight.Font = Enum.Font.Code
u.StatusRight.Text = "2 lines | 0 chars | Midnight"
u.StatusRight.TextColor3 = s.currentTheme.lineNums
u.StatusRight.TextSize = 10
u.StatusRight.TextXAlignment = Enum.TextXAlignment.Right
u.StatusRight.Parent = u.StatusBar
pad(u.StatusRight, 0, 8)

-- Error Frame
u.ErrorFrame = Instance.new("Frame")
u.ErrorFrame.Size = UDim2.new(1, -24, 0, 48)
u.ErrorFrame.Position = UDim2.new(0, 12, 1, -74)
u.ErrorFrame.BackgroundColor3 = s.currentTheme.errBg
u.ErrorFrame.BorderSizePixel = 0
u.ErrorFrame.Parent = u.MainFrame
corner(u.ErrorFrame, 8)
stroke(u.ErrorFrame, s.currentTheme.divider)

u.ErrorLabel = Instance.new("TextLabel")
u.ErrorLabel.Size = UDim2.new(1, -24, 1, -12)
u.ErrorLabel.Position = UDim2.new(0, 12, 0, 6)
u.ErrorLabel.BackgroundTransparency = 1
u.ErrorLabel.Font = Enum.Font.Code
u.ErrorLabel.Text = "No errors."
u.ErrorLabel.TextColor3 = s.currentTheme.errSuccess
u.ErrorLabel.TextSize = 12
u.ErrorLabel.TextXAlignment = Enum.TextXAlignment.Left
u.ErrorLabel.TextYAlignment = Enum.TextYAlignment.Top
u.ErrorLabel.TextWrapped = true
u.ErrorLabel.Parent = u.ErrorFrame

-- Context Menu
u.ContextMenu = Instance.new("Frame")
u.ContextMenu.Size = UDim2.new(0, 180, 0, 0)
u.ContextMenu.BackgroundColor3 = s.currentTheme.titleBg
u.ContextMenu.BorderSizePixel = 0
u.ContextMenu.Visible = false
u.ContextMenu.ZIndex = 50
u.ContextMenu.Parent = u.mainScreen
corner(u.ContextMenu, 6)
stroke(u.ContextMenu)

u.cmLayout = Instance.new("UIListLayout")
u.cmLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.cmLayout.Padding = UDim.new(0, 1)
u.cmLayout.Parent = u.ContextMenu
pad(u.ContextMenu, 4, 4, 4, 4)

--==================== SETTINGS UI ====================
u.SettingsFrame = Instance.new("Frame")
u.SettingsFrame.Size = UDim2.new(0, 560, 0, 460)
u.SettingsFrame.Position = UDim2.new(0.5, -280, 0.5, -230)
u.SettingsFrame.BackgroundColor3 = s.currentTheme.mainBg
u.SettingsFrame.BorderSizePixel = 0
u.SettingsFrame.Visible = false
u.SettingsFrame.Parent = u.settingsScreen
corner(u.SettingsFrame, 10)
stroke(u.SettingsFrame)

u.sfTitle = Instance.new("TextLabel")
u.sfTitle.Size = UDim2.new(1, -20, 0, 38)
u.sfTitle.Position = UDim2.new(0, 14, 0, 0)
u.sfTitle.BackgroundTransparency = 1
u.sfTitle.Font = Enum.Font.GothamSemibold
u.sfTitle.Text = "Settings"
u.sfTitle.TextColor3 = s.currentTheme.text
u.sfTitle.TextSize = 15
u.sfTitle.TextXAlignment = Enum.TextXAlignment.Left
u.sfTitle.Parent = u.SettingsFrame

u.sfClose = Instance.new("TextButton")
u.sfClose.Size = UDim2.new(0, 28, 0, 28)
u.sfClose.Position = UDim2.new(1, -38, 0, 6)
u.sfClose.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
u.sfClose.BorderSizePixel = 0
u.sfClose.Font = Enum.Font.GothamBold
u.sfClose.Text = "✕"
u.sfClose.TextColor3 = Color3.fromRGB(255, 255, 255)
u.sfClose.TextSize = 12
u.sfClose.Parent = u.SettingsFrame
corner(u.sfClose, 6)

u.Sidebar = Instance.new("Frame")
u.Sidebar.Size = UDim2.new(0, 130, 1, -50)
u.Sidebar.Position = UDim2.new(0, 0, 0, 44)
u.Sidebar.BackgroundColor3 = s.currentTheme.titleBg
u.Sidebar.BorderSizePixel = 0
u.Sidebar.Parent = u.SettingsFrame
corner(u.Sidebar, 8)

u.sbLayout = Instance.new("UIListLayout")
u.sbLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.sbLayout.Padding = UDim.new(0, 2)
u.sbLayout.Parent = u.Sidebar
pad(u.Sidebar, 8)

u.ContentArea = Instance.new("Frame")
u.ContentArea.Size = UDim2.new(1, -140, 1, -58)
u.ContentArea.Position = UDim2.new(0, 134, 0, 44)
u.ContentArea.BackgroundTransparency = 1
u.ContentArea.BorderSizePixel = 0
u.ContentArea.Parent = u.SettingsFrame

-- Sections
for _, secData in ipairs({
    {"ThemeSection", true},
    {"SnippetsSection", false},
    {"EditorSection", false},
}) do
    local name, visible = secData[1], secData[2]
    local isScroll = name ~= "EditorSection"
    local sec = isScroll and Instance.new("ScrollingFrame") or Instance.new("Frame")
    sec.Size = UDim2.new(1, 0, 1, 0)
    sec.BackgroundTransparency = 1
    sec.BorderSizePixel = 0
    sec.Visible = visible
    sec.Parent = u.ContentArea
    if isScroll then
        sec.ScrollBarThickness = 4
        sec.ScrollBarImageColor3 = s.currentTheme.scrollbar
        sec.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sec.CanvasSize = UDim2.new(0, 0, 0, 0)
    end
    u[name] = sec
    
    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Padding = UDim.new(0, 4)
    lay.Parent = sec
    
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, name == "EditorSection" and 12 or 8)
    p.PaddingLeft = UDim.new(0, 8)
    p.PaddingRight = UDim.new(0, 8)
    p.Parent = sec
end

u.esLayout2 = Instance.new("UIListLayout")
u.esLayout2.SortOrder = Enum.SortOrder.LayoutOrder
u.esLayout2.Padding = UDim.new(0, 6)
u.esLayout2.Parent = u.EditorSection

-- Editor section content
u.fsLabel = Instance.new("TextLabel")
u.fsLabel.Size = UDim2.new(1, 0, 0, 20)
u.fsLabel.BackgroundTransparency = 1
u.fsLabel.Font = Enum.Font.GothamMedium
u.fsLabel.Text = "Font Size: " .. s.fontSize
u.fsLabel.TextColor3 = s.currentTheme.text
u.fsLabel.TextSize = 13
u.fsLabel.TextXAlignment = Enum.TextXAlignment.Left
u.fsLabel.Parent = u.EditorSection

u.fsSlider = makeTextBox(u.EditorSection, 0, 0, 60, 28, "", true)
u.fsSlider.LayoutOrder = 2
u.fsSlider.Text = tostring(s.fontSize)

u.wrapLabel = Instance.new("TextLabel")
u.wrapLabel.Size = UDim2.new(1, 0, 0, 20)
u.wrapLabel.LayoutOrder = 3
u.wrapLabel.BackgroundTransparency = 1
u.wrapLabel.Font = Enum.Font.GothamMedium
u.wrapLabel.Text = "Word Wrap: " .. (s.wordWrap and "On" or "Off")
u.wrapLabel.TextColor3 = s.currentTheme.text
u.wrapLabel.TextSize = 13
u.wrapLabel.TextXAlignment = Enum.TextXAlignment.Left
u.wrapLabel.Parent = u.EditorSection

u.wrapBtn = Instance.new("TextButton")
u.wrapBtn.Size = UDim2.new(0, 80, 0, 24)
u.wrapBtn.LayoutOrder = 4
u.wrapBtn.BackgroundColor3 = s.currentTheme.tabBg
u.wrapBtn.BorderSizePixel = 0
u.wrapBtn.Font = Enum.Font.GothamSemibold
u.wrapBtn.Text = s.wordWrap and "ON" or "OFF"
u.wrapBtn.TextColor3 = s.currentTheme.text
u.wrapBtn.TextSize = 11
u.wrapBtn.Parent = u.EditorSection
corner(u.wrapBtn, 5)

u.indentLabel = Instance.new("TextLabel")
u.indentLabel.Size = UDim2.new(1, 0, 0, 20)
u.indentLabel.LayoutOrder = 5
u.indentLabel.BackgroundTransparency = 1
u.indentLabel.Font = Enum.Font.GothamMedium
u.indentLabel.Text = "Auto Indent: " .. (s.autoIndent and "On" or "Off")
u.indentLabel.TextColor3 = s.currentTheme.text
u.indentLabel.TextSize = 13
u.indentLabel.TextXAlignment = Enum.TextXAlignment.Left
u.indentLabel.Parent = u.EditorSection

u.indentBtn = Instance.new("TextButton")
u.indentBtn.Size = UDim2.new(0, 80, 0, 24)
u.indentBtn.LayoutOrder = 6
u.indentBtn.BackgroundColor3 = s.currentTheme.tabBg
u.indentBtn.BorderSizePixel = 0
u.indentBtn.Font = Enum.Font.GothamSemibold
u.indentBtn.Text = s.autoIndent and "ON" or "OFF"
u.indentBtn.TextColor3 = s.currentTheme.text
u.indentBtn.TextSize = 11
u.indentBtn.Parent = u.EditorSection
corner(u.indentBtn, 5)

local kbTitle = Instance.new("TextLabel")
kbTitle.Size = UDim2.new(1, 0, 0, 24)
kbTitle.LayoutOrder = 7
kbTitle.BackgroundTransparency = 1
kbTitle.Font = Enum.Font.GothamSemibold
kbTitle.Text = "Keyboard Shortcuts"
kbTitle.TextColor3 = s.currentTheme.text
kbTitle.TextSize = 14
kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Parent = u.EditorSection

local shortcuts = {
    "Ctrl+Enter — Execute", "Ctrl+S — Save", "Ctrl+N — New tab",
    "Ctrl+F — Find & Replace", "Ctrl+G — Go to line", "Ctrl+/ — Toggle comment",
    "Ctrl+D — Duplicate line", "Ctrl+Shift+P — Command palette", "F11 — Fullscreen",
}
for i, sc in ipairs(shortcuts) do
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.LayoutOrder = 7 + i
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Code
    lbl.Text = "  " .. sc
    lbl.TextColor3 = s.currentTheme.lineNums
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = u.EditorSection
end

-- Sidebar buttons
local sidebarButtons = {}
local function makeSidebarBtn(text, section)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 32)
    btn.BackgroundColor3 = s.currentTheme.tabBg
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "  " .. text
    btn.TextColor3 = s.currentTheme.text
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = u.Sidebar
    corner(btn, 6)
    sidebarButtons[#sidebarButtons+1] = {btn = btn, section = section}
    btn.MouseButton1Click:Connect(function()
        for _, data in ipairs(sidebarButtons) do
            data.section.Visible = false
            TweenService:Create(data.btn, TweenInfo.new(0.1), {BackgroundColor3 = s.currentTheme.tabBg}):Play()
        end
        section.Visible = true
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = s.currentTheme.tabActiveBg}):Play()
    end)
    return btn
end

makeSidebarBtn("Themes", u.ThemeSection)
makeSidebarBtn("Snippets", u.SnippetsSection)
makeSidebarBtn("Editor", u.EditorSection)

--==================== SNIPPET & THEME EDITORS ====================
u.SnippetEditorFrame = Instance.new("Frame")
u.SnippetEditorFrame.Size = UDim2.new(0, 440, 0, 400)
u.SnippetEditorFrame.Position = UDim2.new(0.5, -220, 0.5, -200)
u.SnippetEditorFrame.BackgroundColor3 = s.currentTheme.mainBg
u.SnippetEditorFrame.BorderSizePixel = 0
u.SnippetEditorFrame.Visible = false
u.SnippetEditorFrame.ZIndex = 30
u.SnippetEditorFrame.Parent = u.settingsScreen
corner(u.SnippetEditorFrame, 10)
stroke(u.SnippetEditorFrame)

u.seTitle = Instance.new("TextLabel")
u.seTitle.Size = UDim2.new(1, -20, 0, 36)
u.seTitle.Position = UDim2.new(0, 14, 0, 0)
u.seTitle.BackgroundTransparency = 1
u.seTitle.Font = Enum.Font.GothamSemibold
u.seTitle.Text = "Edit Snippet"
u.seTitle.TextColor3 = s.currentTheme.text
u.seTitle.TextSize = 14
u.seTitle.TextXAlignment = Enum.TextXAlignment.Left
u.seTitle.ZIndex = 31
u.seTitle.Parent = u.SnippetEditorFrame

u.seClose = Instance.new("TextButton")
u.seClose.Size = UDim2.new(0, 26, 0, 26)
u.seClose.Position = UDim2.new(1, -34, 0, 6)
u.seClose.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
u.seClose.BorderSizePixel = 0
u.seClose.Font = Enum.Font.GothamBold
u.seClose.Text = "✕"
u.seClose.TextColor3 = Color3.fromRGB(255, 255, 255)
u.seClose.TextSize = 12
u.seClose.ZIndex = 31
u.seClose.Parent = u.SnippetEditorFrame
corner(u.seClose, 6)

u.seNameBox = makeTextBox(u.SnippetEditorFrame, 14, 64, 412, 28, "Snippet name...", false)
u.seNameBox.ZIndex = 31
u.seDescBox = makeTextBox(u.SnippetEditorFrame, 14, 120, 412, 28, "Description...", false)
u.seDescBox.ZIndex = 31
u.seCodeBox = makeTextBox(u.SnippetEditorFrame, 14, 176, 412, 150, "Enter code here...", true)
u.seCodeBox.ZIndex = 31
u.seCodeBox.MultiLine = true
u.seCodeBox.TextYAlignment = Enum.TextYAlignment.Top

u.seSaveBtn = Instance.new("TextButton")
u.seSaveBtn.Size = UDim2.new(0, 100, 0, 30)
u.seSaveBtn.Position = UDim2.new(1, -118, 1, -38)
u.seSaveBtn.BackgroundColor3 = s.currentTheme.accent
u.seSaveBtn.BorderSizePixel = 0
u.seSaveBtn.Font = Enum.Font.GothamBold
u.seSaveBtn.Text = "Save"
u.seSaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.seSaveBtn.TextSize = 12
u.seSaveBtn.ZIndex = 31
u.seSaveBtn.Parent = u.SnippetEditorFrame
corner(u.seSaveBtn, 6)

-- Theme Editor
u.ThemeEditorFrame = Instance.new("Frame")
u.ThemeEditorFrame.Size = UDim2.new(0, 480, 0, 520)
u.ThemeEditorFrame.Position = UDim2.new(0.5, -240, 0.5, -260)
u.ThemeEditorFrame.BackgroundColor3 = s.currentTheme.mainBg
u.ThemeEditorFrame.BorderSizePixel = 0
u.ThemeEditorFrame.Visible = false
u.ThemeEditorFrame.ZIndex = 30
u.ThemeEditorFrame.Parent = u.settingsScreen
corner(u.ThemeEditorFrame, 10)
stroke(u.ThemeEditorFrame)

u.teTitle = Instance.new("TextLabel")
u.teTitle.Size = UDim2.new(1, -20, 0, 36)
u.teTitle.Position = UDim2.new(0, 14, 0, 0)
u.teTitle.BackgroundTransparency = 1
u.teTitle.Font = Enum.Font.GothamSemibold
u.teTitle.Text = "Custom Theme Editor"
u.teTitle.TextColor3 = s.currentTheme.text
u.teTitle.TextSize = 14
u.teTitle.TextXAlignment = Enum.TextXAlignment.Left
u.teTitle.ZIndex = 31
u.teTitle.Parent = u.ThemeEditorFrame

u.teClose = Instance.new("TextButton")
u.teClose.Size = UDim2.new(0, 26, 0, 26)
u.teClose.Position = UDim2.new(1, -34, 0, 6)
u.teClose.BackgroundColor3 = Color3.fromRGB(255, 85, 85)
u.teClose.BorderSizePixel = 0
u.teClose.Font = Enum.Font.GothamBold
u.teClose.Text = "✕"
u.teClose.TextColor3 = Color3.fromRGB(255, 255, 255)
u.teClose.TextSize = 12
u.teClose.ZIndex = 31
u.teClose.Parent = u.ThemeEditorFrame
corner(u.teClose, 6)

u.teNameBox = makeTextBox(u.ThemeEditorFrame, 14, 42, 452, 28, "Theme Name...", false)
u.teNameBox.ZIndex = 31

u.teBaseBtn = Instance.new("TextButton")
u.teBaseBtn.Size = UDim2.new(0, 150, 0, 24)
u.teBaseBtn.Position = UDim2.new(0, 90, 0, 76)
u.teBaseBtn.BackgroundColor3 = s.currentTheme.tabBg
u.teBaseBtn.BorderSizePixel = 0
u.teBaseBtn.Font = Enum.Font.GothamMedium
u.teBaseBtn.Text = "Midnight ▾"
u.teBaseBtn.TextColor3 = s.currentTheme.text
u.teBaseBtn.TextSize = 11
u.teBaseBtn.ZIndex = 31
u.teBaseBtn.Parent = u.ThemeEditorFrame
corner(u.teBaseBtn, 5)

u.teBgStyleBtn = Instance.new("TextButton")
u.teBgStyleBtn.Size = UDim2.new(0, 150, 0, 24)
u.teBgStyleBtn.Position = UDim2.new(0, 90, 0, 106)
u.teBgStyleBtn.BackgroundColor3 = s.currentTheme.tabBg
u.teBgStyleBtn.BorderSizePixel = 0
u.teBgStyleBtn.Font = Enum.Font.GothamMedium
u.teBgStyleBtn.Text = "Solid ▾"
u.teBgStyleBtn.TextColor3 = s.currentTheme.text
u.teBgStyleBtn.TextSize = 11
u.teBgStyleBtn.ZIndex = 31
u.teBgStyleBtn.Parent = u.ThemeEditorFrame
corner(u.teBgStyleBtn, 5)

u.teScroll = Instance.new("ScrollingFrame")
u.teScroll.Size = UDim2.new(1, -28, 1, -220)
u.teScroll.Position = UDim2.new(0, 14, 0, 140)
u.teScroll.BackgroundTransparency = 1
u.teScroll.BorderSizePixel = 0
u.teScroll.ScrollBarThickness = 4
u.teScroll.ScrollBarImageColor3 = s.currentTheme.scrollbar
u.teScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
u.teScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
u.teScroll.ZIndex = 31
u.teScroll.Parent = u.ThemeEditorFrame

u.teLayout = Instance.new("UIListLayout")
u.teLayout.SortOrder = Enum.SortOrder.LayoutOrder
u.teLayout.Padding = UDim.new(0, 4)
u.teLayout.Parent = u.teScroll
pad(u.teScroll, 4)

u.teTransBox = makeTextBox(u.ThemeEditorFrame, 110, -2, 50, 24, "", true)
u.teTransBox.ZIndex = 31
u.teTransBox.Text = "0"

u.teSaveBtn = Instance.new("TextButton")
u.teSaveBtn.Size = UDim2.new(0, 100, 0, 30)
u.teSaveBtn.Position = UDim2.new(1, -118, 1, -38)
u.teSaveBtn.BackgroundColor3 = s.currentTheme.accent
u.teSaveBtn.BorderSizePixel = 0
u.teSaveBtn.Font = Enum.Font.GothamBold
u.teSaveBtn.Text = "Save Theme"
u.teSaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
u.teSaveBtn.TextSize = 12
u.teSaveBtn.ZIndex = 31
u.teSaveBtn.Parent = u.ThemeEditorFrame
corner(u.teSaveBtn, 6)

local editableProps = {
    {key="mainBg", label="Main BG"}, {key="titleBg", label="Title BG"},
    {key="toolbarBg", label="Toolbar BG"}, {key="editorBg", label="Editor BG"},
    {key="tabBg", label="Tab BG"}, {key="tabActiveBg", label="Tab Active BG"},
    {key="text", label="Text Color"}, {key="lineNums", label="Line Nums"},
    {key="lineNumBg", label="Line Num BG"}, {key="accent", label="Execute Btn"},
    {key="keyword", label="Keyword"}, {key="builtin", label="Builtin"},
    {key="stringVal", label="String"}, {key="numberVal", label="Number"},
    {key="comment", label="Comment"}, {key="operator", label="Operator"},
    {key="identifier", label="Identifier"}, {key="errBg", label="Error BG"},
    {key="errSuccess", label="Success Text"}, {key="errFail", label="Error Text"},
    {key="stroke", label="Stroke"}, {key="divider", label="Divider"},
}

local function buildThemeEditorRows()
    for _, child in ipairs(u.teScroll:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    s.teColorBoxes = {}
    for i, prop in ipairs(editableProps) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.LayoutOrder = i
        row.ZIndex = 31
        row.Parent = u.teScroll

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 100, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.Text = prop.label
        lbl.TextColor3 = s.currentTheme.text
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 31
        lbl.Parent = row

        local val = s.themeEditorColors[prop.key]
        if typeof(val) == "Color3" then
            val = {math.floor(val.R * 255), math.floor(val.G * 255), math.floor(val.B * 255)}
        elseif type(val) ~= "table" then val = {0, 0, 0} end
        s.themeEditorColors[prop.key] = val

        local boxes = {}
        for order = 1, 3 do
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 42, 1, -4)
            box.Position = UDim2.new(0, 100 + (order - 1) * 46, 0, 2)
            box.BackgroundColor3 = s.currentTheme.editorBg
            box.BorderSizePixel = 0
            box.Font = Enum.Font.Code
            box.Text = tostring(val[order] or 0)
            box.TextColor3 = s.currentTheme.text
            box.TextSize = 11
            box.ZIndex = 31
            box.Parent = row
            corner(box, 4)
            boxes[order] = box
            box.FocusLost:Connect(function()
                local num = tonumber(box.Text)
                if num then
                    num = math.clamp(math.floor(num), 0, 255)
                    box.Text = tostring(num)
                    s.themeEditorColors[prop.key][order] = num
                else
                    box.Text = tostring(s.themeEditorColors[prop.key][order])
                end
            end)
        end
        s.teColorBoxes[prop.key] = boxes

        local swatch = Instance.new("Frame")
        swatch.Size = UDim2.new(0, 24, 1, -6)
        swatch.Position = UDim2.new(1, -28, 0, 3)
        swatch.BackgroundColor3 = Color3.fromRGB(val[1] or 0, val[2] or 0, val[3] or 0)
        swatch.BorderSizePixel = 0
        swatch.ZIndex = 31
        swatch.Parent = row
        corner(swatch, 4)

        for _, box in ipairs(boxes) do
            box.FocusLost:Connect(function()
                local c = s.themeEditorColors[prop.key]
                swatch.BackgroundColor3 = Color3.fromRGB(c[1] or 0, c[2] or 0, c[3] or 0)
            end)
        end
    end
end

--==================== FUNCTIONS ====================
function f.getActiveTab()
    for _, tab in ipairs(s.tabs) do
        if tab.id == s.activeTabId then return tab end
    end
    return nil
end

function f.createTab(name, content)
    s.tabIdCounter = s.tabIdCounter + 1
    local tab = {id = s.tabIdCounter, name = name or "Untitled", content = content or "", isAutoExec = false, gameId = ""}
    s.tabs[#s.tabs+1] = tab
    return tab
end

function f.saveCurrentTabContent()
    local tab = f.getActiveTab()
    if tab then tab.content = s.fullText end
end

function f.updateLineNumbers(code)
    local count = 1
    for _ in code:gmatch("\n") do count = count + 1 end
    local lines = {}
    for i = 1, count do lines[#lines+1] = tostring(i) end
    u.LineNumbers.Text = table.concat(lines, "\n")
end

function f.updateContentHeight()
    local minHeight = u.EditorScroll.AbsoluteSize.Y
    if minHeight == 0 then minHeight = 300 end
    local contentHeight = math.max(minHeight, s.totalLineCount * s.lineHeight + 20)
    u.EditorContent.Size = UDim2.new(1, 0, 0, contentHeight)
    u.LineNumbers.Size = UDim2.new(0, 40, 0, contentHeight)
    u.lnDivider.Size = UDim2.new(0, 1, 0, contentHeight)
    u.EditorTextBox.Size = UDim2.new(1, -44, 0, contentHeight)
    u.EditorScroll.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

function f.updateVisibleHighlight()
    if u.EditorTextBox:IsFocused() then
        u.HighlightedCode.Visible = false
        return
    end
    u.HighlightedCode.Visible = true
    local scrollY = u.EditorScroll.CanvasPosition.Y
    local viewportH = u.EditorScroll.AbsoluteSize.Y
    if viewportH == 0 then viewportH = 300 end
    local padLines = 5
    local startLine = math.max(1, math.floor(scrollY / s.lineHeight) - padLines + 1)
    local endLine = math.min(s.totalLineCount, math.ceil((scrollY + viewportH) / s.lineHeight) + padLines + 1)
    if startLine > s.totalLineCount then u.HighlightedCode.Text = "" return end
    local visibleText = getVisibleLines(s.fullText, startLine, endLine)
    u.HighlightedCode.Position = UDim2.new(0, 42, 0, (startLine - 1) * s.lineHeight)
    u.HighlightedCode.Size = UDim2.new(1, -44, 0, (endLine - startLine + 2) * s.lineHeight)
    u.HighlightedCode.Text = buildHighlight(visibleText)
end

function f.updateStatusBar()
    local cursorPos = u.EditorTextBox.CursorPosition or 1
    local line, col = getCursorLineCol(s.fullText, cursorPos)
    local tab = f.getActiveTab()
    u.StatusLeft.Text = "Ln " .. line .. ", Col " .. col .. "  |  Tab: " .. (tab and tab.name or "Unknown")
    u.StatusRight.Text = s.totalLineCount .. " lines | " .. #s.fullText .. " chars | " .. s.currentThemeName .. " | " .. s.execName
end

function f.showNotification(title, message, accentColor)
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 380, 0, 0)
    notif.Position = UDim2.new(0.5, -190, 0, -60)
    notif.BackgroundColor3 = s.currentTheme.mainBg
    notif.BorderSizePixel = 0
    notif.ZIndex = 100
    notif.Parent = u.mainScreen
    corner(notif, 8)
    stroke(notif)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, -12)
    accent.Position = UDim2.new(0, 6, 0, 6)
    accent.BackgroundColor3 = accentColor
    accent.BorderSizePixel = 0
    accent.Parent = notif
    corner(accent, 2)

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -30, 0, 20)
    tl.Position = UDim2.new(0, 16, 0, 10)
    tl.BackgroundTransparency = 1
    tl.Font = Enum.Font.GothamBold
    tl.Text = title
    tl.TextColor3 = s.currentTheme.text
    tl.TextSize = 13
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Parent = notif

    local ml = Instance.new("TextLabel")
    ml.Size = UDim2.new(1, -30, 0, 16)
    ml.Position = UDim2.new(0, 16, 0, 32)
    ml.BackgroundTransparency = 1
    ml.Font = Enum.Font.Gotham
    ml.Text = message
    ml.TextColor3 = s.currentTheme.lineNums
    ml.TextSize = 11
    ml.TextXAlignment = Enum.TextXAlignment.Left
    ml.TextWrapped = true
    ml.Parent = notif

    TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(0.5, -190, 0, 20), Size = UDim2.new(0, 380, 0, 58)}):Play()
    task.delay(5, function()
        if notif.Parent then
            local tw = TweenService:Create(notif, TweenInfo.new(0.4),
                {Position = UDim2.new(0.5, -190, 0, -60), Size = UDim2.new(0, 380, 0, 0)})
            tw:Play()
            tw.Completed:Connect(function() notif:Destroy() end)
        end
    end)
end

function f.addConsoleMessage(msg, msgType)
    s.consoleMessages[#s.consoleMessages+1] = {text = msg, type = msgType or "info", time = os.time()}
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -8, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Code
    lbl.Text = "[" .. os.date("%H:%M:%S") .. "] " .. msg
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextSize = 11
    lbl.TextWrapped = true
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    if msgType == "error" then lbl.TextColor3 = s.currentTheme.errFail
    elseif msgType == "warn" then lbl.TextColor3 = Color3.fromRGB(255, 200, 80)
    elseif msgType == "success" then lbl.TextColor3 = s.currentTheme.errSuccess
    else lbl.TextColor3 = s.currentTheme.text end
    lbl.Parent = u.ConsoleScroll
    if u.ConsoleScroll.CanvasSize.Y.Offset < #s.consoleMessages * 19 then
        u.ConsoleScroll.CanvasSize = UDim2.new(0, 0, 0, #s.consoleMessages * 19)
    end
    task.defer(function()
        u.ConsoleScroll.CanvasPosition = Vector2.new(0, u.ConsoleScroll.CanvasSize.Y.Offset)
    end)
end

function f.applyTheme(name)
    local theme = themes[name] or s.customThemes[name]
    if not theme then name = "Midnight"; theme = themes[name] end
    s.currentTheme = theme
    s.currentThemeName = name

    u.MainFrame.BackgroundColor3 = theme.mainBg
    u.MainStroke.Color = theme.stroke
    if theme.bgStyle == "gradient" then
        u.MainGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.mainBg),
            ColorSequenceKeypoint.new(1, theme.mainBg:Lerp(Color3.new(0,0,0), 0.25)),
        })
        u.MainGradient.Parent = u.MainFrame
        u.MainFrame.BackgroundTransparency = 0
    elseif theme.bgStyle == "glass" then
        u.MainGradient.Parent = nil
        u.MainFrame.BackgroundTransparency = theme.transparency or 0.15
    else
        u.MainGradient.Parent = nil
        u.MainFrame.BackgroundTransparency = 0
    end

    u.TitleBar.BackgroundColor3 = theme.titleBg
    u.titleFix.BackgroundColor3 = theme.titleBg
    u.TitleLabel.TextColor3 = theme.text
    u.ExecBadge.BackgroundColor3 = theme.tabBg
    u.ExecBadge.TextColor3 = theme.text
    for _, btnName in ipairs({"TemplatesBtn","FindBtn","SettingsBtn","CollapseBtn"}) do
        u[btnName].BackgroundColor3 = theme.tabBg
        u[btnName].TextColor3 = theme.text
    end
    u.TabBar.BackgroundColor3 = theme.editorBg
    u.Toolbar.BackgroundColor3 = theme.toolbarBg
    u.ExecuteBtn.BackgroundColor3 = theme.accent
    for _, btnName in ipairs({"ClearBtn","CopyBtn","NewLineBtn","SnippetsBtn","FormatBtn"}) do
        u[btnName].BackgroundColor3 = theme.tabBg
        u[btnName].TextColor3 = theme.text
    end
    u.HubBtn.BackgroundColor3 = theme.accentSecondary or theme.accent
    u.EditorContainer.BackgroundColor3 = theme.editorBg
    u.ecStroke.Color = theme.divider
    u.EditorScroll.ScrollBarImageColor3 = theme.scrollbar
    u.LineNumbers.BackgroundColor3 = theme.lineNumBg
    u.LineNumbers.TextColor3 = theme.lineNums
    u.lnDivider.BackgroundColor3 = theme.divider
    u.HighlightedCode.TextColor3 = theme.identifier
    u.EditorTextBox.TextColor3 = theme.text
    u.StatusBar.BackgroundColor3 = theme.titleBg
    u.StatusLeft.TextColor3 = theme.lineNums
    u.StatusRight.TextColor3 = theme.lineNums
    u.ErrorFrame.BackgroundColor3 = theme.errBg
    if u.ErrorLabel.Text == "No errors." or u.ErrorLabel.Text:find("Copied") or u.ErrorLabel.Text:find("✓") then
        u.ErrorLabel.TextColor3 = theme.errSuccess
    else
        u.ErrorLabel.TextColor3 = theme.errFail
    end
    f.updateVisibleHighlight()
    f.updateStatusBar()
end

function f.rebuildThemeSection()
    for _, card in ipairs(s.themeCards) do
        if card.Parent then card:Destroy() end
    end
    s.themeCards = {}

    local function addCard(name, isCustom)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 40)
        card.BackgroundColor3 = (name == s.currentThemeName) and s.currentTheme.tabActiveBg or s.currentTheme.tabBg
        card.BorderSizePixel = 0
        card.Parent = u.ThemeSection
        corner(card, 6)

        local applyBtn = Instance.new("TextButton")
        applyBtn.Size = UDim2.new(1, -90, 1, 0)
        applyBtn.BackgroundTransparency = 1
        applyBtn.Font = Enum.Font.GothamMedium
        applyBtn.Text = "  " .. name .. (isCustom and "  ★" or "")
        applyBtn.TextColor3 = s.currentTheme.text
        applyBtn.TextSize = 12
        applyBtn.TextXAlignment = Enum.TextXAlignment.Left
        applyBtn.Parent = card
        applyBtn.MouseButton1Click:Connect(function() f.applyTheme(name); f.rebuildThemeSection() end)

        if isCustom then
            local editBtn = Instance.new("TextButton")
            editBtn.Size = UDim2.new(0, 50, 0, 28)
            editBtn.Position = UDim2.new(1, -110, 0.5, -14)
            editBtn.BackgroundColor3 = s.currentTheme.tabBg
            editBtn.BorderSizePixel = 0
            editBtn.Font = Enum.Font.GothamBold
            editBtn.Text = "Edit"
            editBtn.TextColor3 = s.currentTheme.accent
            editBtn.TextSize = 11
            editBtn.Parent = card
            corner(editBtn, 5)
            editBtn.MouseButton1Click:Connect(function()
                s.editingThemeName = name
                local baseT = s.customThemes[name] or themes[s.teBaseThemeName] or themes.Midnight
                u.teNameBox.Text = name
                s.themeEditorColors = {}
                for _, prop in ipairs(editableProps) do
                    local c = baseT[prop.key]
                    if typeof(c) == "Color3" then
                        s.themeEditorColors[prop.key] = {math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)}
                    end
                end
                u.teTransBox.Text = tostring(math.floor((baseT.transparency or 0) * 100))
                s.teBgStyle = baseT.bgStyle or "solid"
                u.teBgStyleBtn.Text = s.teBgStyle:sub(1,1):upper()..s.teBgStyle:sub(2) .. " ▾"
                buildThemeEditorRows()
                u.ThemeEditorFrame.Visible = true
            end)

            local delBtn = Instance.new("TextButton")
            delBtn.Size = UDim2.new(0, 40, 0, 28)
            delBtn.Position = UDim2.new(1, -54, 0.5, -14)
            delBtn.BackgroundColor3 = s.currentTheme.tabBg
            delBtn.BorderSizePixel = 0
            delBtn.Font = Enum.Font.GothamBold
            delBtn.Text = "Del"
            delBtn.TextColor3 = s.currentTheme.errFail
            delBtn.TextSize = 11
            delBtn.Parent = card
            corner(delBtn, 5)
            delBtn.MouseButton1Click:Connect(function()
                s.customThemes[name] = nil
                if s.currentThemeName == name then f.applyTheme("Midnight") end
                f.rebuildThemeSection()
            end)
        end
        s.themeCards[#s.themeCards+1] = card
    end

    for _, name in ipairs({"Midnight", "Glass", "Dracula", "Monokai", "Solarized", "Light", "Synapse"}) do
        addCard(name, false)
    end
    for name in pairs(s.customThemes) do addCard(name, true) end

    local createBtn = Instance.new("TextButton")
    createBtn.Size = UDim2.new(1, 0, 0, 36)
    createBtn.BackgroundColor3 = s.currentTheme.accent
    createBtn.BorderSizePixel = 0
    createBtn.Font = Enum.Font.GothamBold
    createBtn.Text = "+ Create Custom Theme"
    createBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    createBtn.TextSize = 12
    createBtn.Parent = u.ThemeSection
    corner(createBtn, 6)
    createBtn.MouseButton1Click:Connect(function()
        s.editingThemeName = nil
        local baseT = themes[s.teBaseThemeName] or themes.Midnight
        u.teNameBox.Text = "Custom_" .. os.date("%H%M%S")
        s.themeEditorColors = {}
        for _, prop in ipairs(editableProps) do
            local c = baseT[prop.key]
            if typeof(c) == "Color3" then
                s.themeEditorColors[prop.key] = {math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)}
            end
        end
        u.teTransBox.Text = tostring(math.floor((baseT.transparency or 0) * 100))
        s.teBgStyle = baseT.bgStyle or "solid"
        u.teBgStyleBtn.Text = s.teBgStyle:sub(1,1):upper()..s.teBgStyle:sub(2) .. " ▾"
        buildThemeEditorRows()
        u.ThemeEditorFrame.Visible = true
    end)
end

function f.loadTab(tabId)
    for _, tab in ipairs(s.tabs) do
        if tab.id == tabId then
            s.activeTabId = tabId
            s.fullText = tab.content or ""
            u.EditorTextBox.Text = s.fullText
            s.totalLineCount = calcLineCount(s.fullText)
            f.updateLineNumbers(s.fullText)
            f.updateContentHeight()
            f.updateVisibleHighlight()
            f.updateStatusBar()
            return
        end
    end
end

function f.switchTab(tabId)
    f.saveCurrentTabContent()
    f.loadTab(tabId)
    f.rebuildTabBar()
end

function f.startRename(tabId)
    local btnData = s.tabButtons[tabId]
    if not btnData then return end
    local container = btnData.container
    local nameBtn = btnData.nameBtn

    local renameBox = Instance.new("TextBox")
    renameBox.Size = UDim2.new(1, -30, 1, 0)
    renameBox.Position = UDim2.new(0, 6, 0, 0)
    renameBox.BackgroundTransparency = 1
    renameBox.Font = Enum.Font.GothamMedium
    renameBox.Text = nameBtn.Text
    renameBox.TextColor3 = s.currentTheme.tabActiveText
    renameBox.TextSize = 12
    renameBox.TextXAlignment = Enum.TextXAlignment.Left
    renameBox.ClearTextOnFocus = false
    renameBox.ZIndex = 15
    renameBox.Parent = container

    nameBtn.Visible = false
    renameBox:CaptureFocus()
    renameBox.CursorPosition = 1

    local committed = false
    local function commit(enter)
        if committed then return end
        committed = true
        local newText = renameBox.Text
        if #newText > 0 then
            for _, tab in ipairs(s.tabs) do
                if tab.id == tabId then tab.name = newText break end
            end
        end
        if renameBox.Parent then renameBox:Destroy() end
        nameBtn.Visible = true
    end
    renameBox.FocusLost:Connect(commit)
end

function f.makeContextItem(text, action)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 26)
    btn.BackgroundColor3 = s.currentTheme.tabBg
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "  " .. text
    btn.TextColor3 = s.currentTheme.text
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.ZIndex = 51
    btn.Parent = u.ContextMenu
    corner(btn, 4)
    btn.MouseButton1Click:Connect(function()
        u.ContextMenu.Visible = false
        action()
    end)
    s.contextItems[#s.contextItems+1] = btn
    return btn
end

function f.rebuildTabBar()
    for _, data in pairs(s.tabButtons) do
        if data.container and data.container.Parent then data.container:Destroy() end
    end
    s.tabButtons = {}

    for i, tab in ipairs(s.tabs) do
        local isActive = (tab.id == s.activeTabId)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(0, 130, 1, -6)
        container.BackgroundColor3 = isActive and s.currentTheme.tabActiveBg or s.currentTheme.tabBg
        container.BorderSizePixel = 0
        container.LayoutOrder = i
        container.Parent = u.TabBar
        corner(container, 5)

        local nameBtn = Instance.new("TextButton")
        nameBtn.Size = UDim2.new(1, -30, 1, 0)
        nameBtn.Position = UDim2.new(0, 6, 0, 0)
        nameBtn.BackgroundTransparency = 1
        nameBtn.Font = Enum.Font.GothamMedium
        nameBtn.Text = tab.name
        nameBtn.TextColor3 = isActive and s.currentTheme.tabActiveText or s.currentTheme.tabText
        nameBtn.TextSize = 12
        nameBtn.TextXAlignment = Enum.TextXAlignment.Left
        nameBtn.Parent = container

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 18, 0, 18)
        closeBtn.Position = UDim2.new(1, -24, 0.5, -9)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = s.currentTheme.tabText
        closeBtn.TextSize = 10
        closeBtn.Parent = container

        if tab.isAutoExec then
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 6, 0, 6)
            dot.Position = UDim2.new(0, 4, 0.5, -3)
            dot.BackgroundColor3 = s.currentTheme.accent
            dot.BorderSizePixel = 0
            dot.ZIndex = 12
            dot.Parent = container
            corner(dot, 1, 0)
            nameBtn.Position = UDim2.new(0, 14, 0, 0)
            nameBtn.Size = UDim2.new(1, -38, 1, 0)
        end

        nameBtn.MouseButton1Click:Connect(function()
            if isActive then f.startRename(tab.id) else f.switchTab(tab.id) end
        end)

        nameBtn.MouseButton2Click:Connect(function()
            local mousePos = UserInputService:GetMouseLocation()
            s.contextTabId = tab.id
            for _, item in ipairs(s.contextItems) do
                if item.Parent then item:Destroy() end
            end
            s.contextItems = {}

            f.makeContextItem("Rename", function()
                if s.contextTabId then f.startRename(s.contextTabId) end
            end)
            f.makeContextItem(tab.isAutoExec and "Auto-Execute: ON" or "Auto-Execute: OFF", function()
                tab.isAutoExec = not tab.isAutoExec
                if not tab.isAutoExec then tab.gameId = "" end
                f.rebuildTabBar()
            end)
            f.makeContextItem("Set Game ID (" .. (tab.gameId and #tab.gameId > 0 and tab.gameId or "Any") .. ")", function()
                u.GameIdBox.Text = tab.gameId or ""
                u.GameIdFrame.Visible = true
                u.GameIdBox:CaptureFocus()
            end)
            f.makeContextItem("Close Tab", function()
                if s.contextTabId then
                    f.saveCurrentTabContent()
                    local idx = 0
                    for i2, t2 in ipairs(s.tabs) do
                        if t2.id == s.contextTabId then idx = i2 break end
                    end
                    if idx > 0 then
                        table.remove(s.tabs, idx)
                        if s.activeTabId == s.contextTabId then
                            if s.tabs[idx] then f.loadTab(s.tabs[idx].id)
                            elseif s.tabs[idx-1] then f.loadTab(s.tabs[idx-1].id)
                            elseif #s.tabs > 0 then f.loadTab(s.tabs[1].id)
                            else f.loadTab(f.createTab("Tab 1", "").id) end
                        end
                        f.rebuildTabBar()
                    end
                end
            end)
            f.makeContextItem("New Tab", function()
                f.switchTab(f.createTab("Tab " .. (#s.tabs + 1), "").id)
            end)

            u.ContextMenu.Position = UDim2.new(0, mousePos.X, 0, mousePos.Y)
            u.ContextMenu.Size = UDim2.new(0, 180, 0, #s.contextItems * 27 + 8)
            u.ContextMenu.Visible = true
        end)

        closeBtn.MouseButton1Click:Connect(function()
            f.saveCurrentTabContent()
            local idx = 0
            for j, t in ipairs(s.tabs) do
                if t.id == tab.id then idx = j break end
            end
            if idx > 0 then
                table.remove(s.tabs, idx)
                if s.activeTabId == tab.id then
                    if s.tabs[idx] then f.loadTab(s.tabs[idx].id)
                    elseif s.tabs[idx-1] then f.loadTab(s.tabs[idx-1].id)
                    elseif #s.tabs > 0 then f.loadTab(s.tabs[1].id)
                    else f.loadTab(f.createTab("Tab 1", "").id) end
                end
                f.rebuildTabBar()
            end
        end)

        nameBtn.MouseEnter:Connect(function()
            if tab.id ~= s.activeTabId then
                TweenService:Create(container, TweenInfo.new(0.1), {BackgroundColor3 = s.currentTheme.tabHoverBg}):Play()
            end
        end)
        nameBtn.MouseLeave:Connect(function()
            if tab.id ~= s.activeTabId then
                TweenService:Create(container, TweenInfo.new(0.1), {BackgroundColor3 = s.currentTheme.tabBg}):Play()
            end
        end)

        s.tabButtons[tab.id] = {container = container, nameBtn = nameBtn, closeBtn = closeBtn}
    end

    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0, 28, 1, -6)
    addBtn.BackgroundColor3 = s.currentTheme.tabBg
    addBtn.BorderSizePixel = 0
    addBtn.Font = Enum.Font.GothamBold
    addBtn.Text = "+"
    addBtn.TextColor3 = s.currentTheme.text
    addBtn.TextSize = 14
    addBtn.LayoutOrder = #s.tabs + 1
    addBtn.Parent = u.TabBar
    corner(addBtn, 5)
    addBtn.MouseButton1Click:Connect(function()
        f.switchTab(f.createTab("Tab " .. (#s.tabs + 1), "").id)
    end)
end

function f.rebuildSnippetsPanel()
    for _, child in ipairs(u.SnippetsDropdown:GetChildren()) do
        if child:IsA("Frame") and child.Name == "SnippetItem" then child:Destroy() end
    end
    for _, child in ipairs(u.SnippetsSection:GetChildren()) do
        if child.Name == "SettingSnippet" then child:Destroy() end
    end

    for i, snippet in ipairs(s.snippets) do
        local item = Instance.new("Frame")
        item.Name = "SnippetItem"
        item.Size = UDim2.new(1, -8, 0, 40)
        item.BackgroundColor3 = s.currentTheme.tabBg
        item.BorderSizePixel = 0
        item.ZIndex = 21
        item.Parent = u.sdScroll
        corner(item, 5)

        local insertBtn = Instance.new("TextButton")
        insertBtn.Size = UDim2.new(1, -30, 1, 0)
        insertBtn.BackgroundTransparency = 1
        insertBtn.Font = Enum.Font.GothamSemibold
        insertBtn.Text = "  " .. snippet.name
        insertBtn.TextColor3 = s.currentTheme.text
        insertBtn.TextSize = 11
        insertBtn.TextXAlignment = Enum.TextXAlignment.Left
        insertBtn.TextYAlignment = Enum.TextYAlignment.Top
        insertBtn.ZIndex = 22
        insertBtn.Parent = item

        local descLabel = Instance.new("TextLabel")
        descLabel.Size = UDim2.new(1, -30, 0, 14)
        descLabel.Position = UDim2.new(0, 8, 0, 22)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.Text = snippet.description or ""
        descLabel.TextColor3 = s.currentTheme.lineNums
        descLabel.TextSize = 9
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.ZIndex = 22
        descLabel.Parent = item

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 22, 0, 22)
        delBtn.Position = UDim2.new(1, -26, 0, 4)
        delBtn.BackgroundTransparency = 1
        delBtn.Font = Enum.Font.GothamBold
        delBtn.Text = "✕"
        delBtn.TextColor3 = s.currentTheme.errFail
        delBtn.TextSize = 10
        delBtn.ZIndex = 22
        delBtn.Parent = item

        local function doInsert()
            local pos = u.EditorTextBox.CursorPosition or (#s.fullText + 1)
            local newText = s.fullText:sub(1, pos - 1) .. snippet.code .. s.fullText:sub(pos)
            s.fullText = newText
            u.EditorTextBox.Text = newText
            u.EditorTextBox.CursorPosition = pos + #snippet.code
            u.SnippetsDropdown.Visible = false
            s.totalLineCount = calcLineCount(s.fullText)
            f.updateLineNumbers(s.fullText)
            f.updateContentHeight()
            f.updateVisibleHighlight()
            f.saveCurrentTabContent()
        end
        insertBtn.MouseButton1Click:Connect(doInsert)
        delBtn.MouseButton1Click:Connect(function()
            table.remove(s.snippets, i)
            f.rebuildSnippetsPanel()
        end)

        local sItem = Instance.new("Frame")
        sItem.Name = "SettingSnippet"
        sItem.Size = UDim2.new(1, 0, 0, 52)
        sItem.BackgroundColor3 = s.currentTheme.tabBg
        sItem.BorderSizePixel = 0
        sItem.Parent = u.SnippetsSection
        corner(sItem, 6)

        local sName = Instance.new("TextLabel")
        sName.Size = UDim2.new(1, -180, 0, 18)
        sName.Position = UDim2.new(0, 8, 0, 4)
        sName.BackgroundTransparency = 1
        sName.Font = Enum.Font.GothamSemibold
        sName.Text = snippet.name
        sName.TextColor3 = s.currentTheme.text
        sName.TextSize = 12
        sName.TextXAlignment = Enum.TextXAlignment.Left
        sName.Parent = sItem

        local sDesc = Instance.new("TextLabel")
        sDesc.Size = UDim2.new(1, -180, 0, 14)
        sDesc.Position = UDim2.new(0, 8, 0, 22)
        sDesc.BackgroundTransparency = 1
        sDesc.Font = Enum.Font.Gotham
        sDesc.Text = snippet.description or "No description"
        sDesc.TextColor3 = s.currentTheme.lineNums
        sDesc.TextSize = 10
        sDesc.TextXAlignment = Enum.TextXAlignment.Left
        sDesc.Parent = sItem

        local sPreview = Instance.new("TextLabel")
        sPreview.Size = UDim2.new(1, -180, 0, 14)
        sPreview.Position = UDim2.new(0, 8, 0, 36)
        sPreview.BackgroundTransparency = 1
        sPreview.Font = Enum.Font.Code
        sPreview.Text = (snippet.code:sub(1, 60) .. (#snippet.code > 60 and "..." or ""))
        sPreview.TextColor3 = s.currentTheme.lineNums
        sPreview.TextSize = 9
        sPreview.TextXAlignment = Enum.TextXAlignment.Left
        sPreview.Parent = sItem

        local sInsert = Instance.new("TextButton")
        sInsert.Size = UDim2.new(0, 44, 0, 24)
        sInsert.Position = UDim2.new(1, -172, 0.5, -12)
        sInsert.BackgroundColor3 = s.currentTheme.accent
        sInsert.BorderSizePixel = 0
        sInsert.Font = Enum.Font.GothamBold
        sInsert.Text = "Insert"
        sInsert.TextColor3 = Color3.fromRGB(255, 255, 255)
        sInsert.TextSize = 10
        sInsert.Parent = sItem
        corner(sInsert, 5)

        local sEdit = Instance.new("TextButton")
        sEdit.Size = UDim2.new(0, 44, 0, 24)
        sEdit.Position = UDim2.new(1, -124, 0.5, -12)
        sEdit.BackgroundColor3 = s.currentTheme.tabBg
        sEdit.BorderSizePixel = 0
        sEdit.Font = Enum.Font.GothamBold
        sEdit.Text = "Edit"
        sEdit.TextColor3 = s.currentTheme.accent
        sEdit.TextSize = 10
        sEdit.Parent = sItem
        corner(sEdit, 5)

        local sDel = Instance.new("TextButton")
        sDel.Size = UDim2.new(0, 44, 0, 24)
        sDel.Position = UDim2.new(1, -76, 0.5, -12)
        sDel.BackgroundColor3 = s.currentTheme.tabBg
        sDel.BorderSizePixel = 0
        sDel.Font = Enum.Font.GothamBold
        sDel.Text = "Delete"
        sDel.TextColor3 = s.currentTheme.errFail
        sDel.TextSize = 10
        sDel.Parent = sItem
        corner(sDel, 5)

        sInsert.MouseButton1Click:Connect(doInsert)
        sEdit.MouseButton1Click:Connect(function()
            s.editingSnippetIndex = i
            u.seNameBox.Text = snippet.name
            u.seDescBox.Text = snippet.description or ""
            u.seCodeBox.Text = snippet.code
            u.seTitle.Text = "Edit Snippet"
            u.SnippetEditorFrame.Visible = true
        end)
        sDel.MouseButton1Click:Connect(function()
            table.remove(s.snippets, i)
            f.rebuildSnippetsPanel()
        end)
    end

    local count = #s.snippets
    u.SnippetsDropdown.Size = UDim2.new(0, 260, 0, math.min(count * 44 + 44, 280))
    u.sdScroll.CanvasSize = UDim2.new(0, 0, 0, count * 44)
end

function f.rebuildTemplatesDropdown()
    for _, child in ipairs(u.tdScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, template in ipairs(scriptTemplates) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, 36)
        btn.BackgroundColor3 = s.currentTheme.tabBg
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = "  " .. template.name
        btn.TextColor3 = s.currentTheme.text
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.TextYAlignment = Enum.TextYAlignment.Top
        btn.ZIndex = 21
        btn.Parent = u.tdScroll
        corner(btn, 5)
        btn.MouseButton1Click:Connect(function()
            s.fullText = template.code
            u.EditorTextBox.Text = s.fullText
            u.EditorTextBox.CursorPosition = #s.fullText + 1
            s.totalLineCount = calcLineCount(s.fullText)
            f.updateLineNumbers(s.fullText)
            f.updateContentHeight()
            f.updateVisibleHighlight()
            f.saveCurrentTabContent()
            u.TemplatesDropdown.Visible = false
        end)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = s.currentTheme.tabHoverBg}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = s.currentTheme.tabBg}):Play()
        end)
    end
    u.TemplatesDropdown.Size = UDim2.new(0, 260, 0, #scriptTemplates * 38 + 8)
    u.tdScroll.CanvasSize = UDim2.new(0, 0, 0, #scriptTemplates * 38)
end

function f.toggleSettings()
    u.settingsScreen.Enabled = not u.settingsScreen.Enabled
    u.SettingsFrame.Visible = u.settingsScreen.Enabled
    if u.settingsScreen.Enabled then
        u.SettingsFrame.Position = UDim2.new(0.5, -280, 0.5, -230)
        f.rebuildThemeSection()
        f.rebuildSnippetsPanel()
    end
end

--==================== SCRIPTBlox HUB ====================
function f.searchScriptBlox(query, page, mode, append)
    if s.hubLoading then return end
    s.hubLoading = true
    u.HubStatus.Text = "Searching..."
    
    local httpFunc = getHttpFunc()
    if not httpFunc then
        u.HubStatus.Text = "HTTP not supported by executor"
        s.hubLoading = false
        return
    end

    local url = "https://scriptblox.com/api/script/search?q=" .. HttpService:UrlEncode(query or "") .. "&page=" .. (page or 1)
    if mode == "free" then url = url .. "&mode=free"
    elseif mode == "paid" then url = url .. "&mode=paid" end

    task.spawn(function()
        local ok, response = pcall(httpFunc, {
            url = url,
            method = "GET",
            headers = {["Content-Type"] = "application/json"}
        })
        
        s.hubLoading = false
        
        if not ok or not response then
            u.HubStatus.Text = "Failed to fetch scripts"
            return
        end
        
        local body = response.Body or response
        if type(body) == "string" then
            body = jsonDecode(body)
        end
        
        if not body or not body.scripts then
            u.HubStatus.Text = "No results found"
            return
        end
        
        if not append then
            for _, child in ipairs(u.HubScroll:GetChildren()) do
                if child ~= u.HubLoadMoreBtn then child:Destroy() end
            end
            s.hubResults = {}
        end
        
        local newCount = 0
        for _, script in ipairs(body.scripts) do
            s.hubResults[#s.hubResults+1] = script
            newCount = newCount + 1
            
            local item = Instance.new("Frame")
            item.Size = UDim2.new(1, -8, 0, 60)
            item.BackgroundColor3 = s.currentTheme.tabBg
            item.BorderSizePixel = 0
            item.ZIndex = 36
            item.Parent = u.HubScroll
            corner(item, 6)
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, -120, 0, 18)
            title.Position = UDim2.new(0, 8, 0, 4)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamSemibold
            title.Text = script.title or "Untitled"
            title.TextColor3 = s.currentTheme.text
            title.TextSize = 12
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.ZIndex = 37
            title.Parent = item
            
            local gameLabel = Instance.new("TextLabel")
            gameLabel.Size = UDim2.new(1, -120, 0, 14)
            gameLabel.Position = UDim2.new(0, 8, 0, 22)
            gameLabel.BackgroundTransparency = 1
            gameLabel.Font = Enum.Font.Gotham
            gameLabel.Text = "Game: " .. (script.game and script.game.name or "Unknown")
            gameLabel.TextColor3 = s.currentTheme.lineNums
            gameLabel.TextSize = 10
            gameLabel.TextXAlignment = Enum.TextXAlignment.Left
            gameLabel.ZIndex = 37
            gameLabel.Parent = item
            
            local keyBadge = Instance.new("TextLabel")
            keyBadge.Size = UDim2.new(0, 50, 0, 16)
            keyBadge.Position = UDim2.new(1, -110, 0, 5)
            keyBadge.BackgroundColor3 = script.key and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 200, 100)
            keyBadge.BorderSizePixel = 0
            keyBadge.Font = Enum.Font.GothamBold
            keyBadge.Text = script.key and "🔑 Key" or "✓ Keyless"
            keyBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
            keyBadge.TextSize = 9
            keyBadge.ZIndex = 37
            keyBadge.Parent = item
            corner(keyBadge, 4)
            
            local preview = Instance.new("TextLabel")
            preview.Size = UDim2.new(1, -120, 0, 16)
            preview.Position = UDim2.new(0, 8, 0, 38)
            preview.BackgroundTransparency = 1
            preview.Font = Enum.Font.Code
            preview.Text = (script.script or ""):sub(1, 20) .. (#(script.script or "") > 20 and "..." or "")
            preview.TextColor3 = s.currentTheme.lineNums
            preview.TextSize = 9
            preview.TextXAlignment = Enum.TextXAlignment.Left
            preview.ZIndex = 37
            preview.Parent = item
            
            local execBtn = Instance.new("TextButton")
            execBtn.Size = UDim2.new(0, 50, 0, 24)
            execBtn.Position = UDim2.new(1, -58, 0.5, -12)
            execBtn.BackgroundColor3 = s.currentTheme.accent
            execBtn.BorderSizePixel = 0
            execBtn.Font = Enum.Font.GothamBold
            execBtn.Text = "Exec"
            execBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            execBtn.TextSize = 10
            execBtn.ZIndex = 37
            execBtn.Parent = item
            corner(execBtn, 5)
            
            execBtn.MouseButton1Click:Connect(function()
                local code = script.script or ""
                if #code > 0 then
                    s.fullText = code
                    u.EditorTextBox.Text = code
                    s.totalLineCount = calcLineCount(code)
                    f.updateLineNumbers(code)
                    f.updateContentHeight()
                    f.updateVisibleHighlight()
                    f.saveCurrentTabContent()
                    u.HubPanel.Visible = false
                    f.showNotification("Script Hub", "Loaded: " .. (script.title or "Unknown"), s.currentTheme.accent)
                end
            end)
        end
        
        u.HubStatus.Text = "Showing " .. #s.hubResults .. " scripts"
        u.HubLoadMoreBtn.Visible = newCount > 0
        u.HubLoadMoreBtn.LayoutOrder = #s.hubResults + 1
    end)
end

--==================== EXECUTE ====================
function f.executeCode(code, isAuto)
    if not code or #code == 0 then return true end
    local fn, err = loadstring(code)
    if fn then
        local startTime = tick()
        local ok, runtimeErr = pcall(fn)
        local execTime = tick() - startTime
        if ok then
            if not isAuto then
                u.ErrorLabel.Text = "✓ Execution successful (" .. string.format("%.3f", execTime) .. "s)"
                u.ErrorLabel.TextColor3 = s.currentTheme.errSuccess
            end
            f.addConsoleMessage("Executed in " .. string.format("%.3f", execTime) .. "s", "success")
            return true
        else
            if not isAuto then
                u.ErrorLabel.Text = "Runtime: " .. tostring(runtimeErr)
                u.ErrorLabel.TextColor3 = s.currentTheme.errFail
            end
            f.addConsoleMessage("Runtime error: " .. tostring(runtimeErr), "error")
            return false
        end
    else
        if not isAuto then
            u.ErrorLabel.Text = err or "Unknown error."
            u.ErrorLabel.TextColor3 = s.currentTheme.errFail
        end
        f.addConsoleMessage("Syntax error: " .. tostring(err), "error")
        return false
    end
end

--==================== AUTO-SAVE ====================
local function serializeColor(c)
    return {math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255)}
end

function f.serializeState()
    f.saveCurrentTabContent()
    local data = {
        tabs = {}, snippets = {}, themes = {},
        settings = {
            theme = s.currentThemeName, fontSize = s.fontSize,
            wordWrap = s.wordWrap, autoIndent = s.autoIndent,
        },
        activeTab = s.activeTabId,
    }
    for _, tab in ipairs(s.tabs) do
        data.tabs[#data.tabs+1] = {id = tab.id, name = tab.name, content = tab.content, isAutoExec = tab.isAutoExec, gameId = tab.gameId}
    end
    for _, snip in ipairs(s.snippets) do
        data.snippets[#data.snippets+1] = {name = snip.name, description = snip.description, code = snip.code}
    end
    for name, theme in pairs(s.customThemes) do
        local serialized = {}
        for k, v in pairs(theme) do
            if typeof(v) == "Color3" then serialized[k] = serializeColor(v)
            else serialized[k] = v end
        end
        data.themes[name] = serialized
    end
    return jsonEncode(data)
end

function f.autoSaveLoop()
    while true do
        task.wait(0.1)
        local data = f.serializeState()
        if data ~= s.lastSaveData then
            s.lastSaveData = data
            u.SaveIndicator.Text = "● Saving..."
            u.SaveIndicator.TextColor3 = Color3.fromRGB(255, 200, 80)
            local ok = fileWrite(SAVE_FILE, data)
            if ok then
                u.SaveIndicator.Text = "● Saved"
                u.SaveIndicator.TextColor3 = s.currentTheme.errSuccess
            else
                u.SaveIndicator.Text = "● Save Failed"
                u.SaveIndicator.TextColor3 = s.currentTheme.errFail
            end
        end
    end
end

--==================== COMMAND PALETTE ====================
local cmdActions = {
    {name = "Execute", action = function() u.ExecuteBtn.MouseButton1Click:Fire() end},
    {name = "Clear Editor", action = function() u.ClearBtn.MouseButton1Click:Fire() end},
    {name = "Copy", action = function() u.CopyBtn.MouseButton1Click:Fire() end},
    {name = "New Tab", action = function() f.switchTab(f.createTab("Tab " .. (#s.tabs + 1), "").id) end},
    {name = "Find & Replace", action = function() u.FindBar.Visible = true end},
    {name = "Go to Line", action = function() u.GotoFrame.Visible = true; u.GotoBox:CaptureFocus() end},
    {name = "Toggle Console", action = function()
        if u.ConsoleFrame.Visible then
            u.ConsoleFrame.Size = UDim2.new(1, -24, 0, 0)
            u.ConsoleFrame.Visible = false
        else
            u.ConsoleFrame.Visible = true
            TweenService:Create(u.ConsoleFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -24, 0, 120)}):Play()
        end
    end},
    {name = "Toggle Comment", action = function()
        local pos = u.EditorTextBox.CursorPosition or 1
        local lineStart = getLineStart(s.fullText, select(1, getCursorLineCol(s.fullText, pos)))
        s.fullText = s.fullText:sub(1, lineStart - 1) .. "-- " .. s.fullText:sub(lineStart)
        u.EditorTextBox.Text = s.fullText
        u.EditorTextBox.CursorPosition = pos + 3
        s.totalLineCount = calcLineCount(s.fullText)
        f.updateLineNumbers(s.fullText)
        f.updateContentHeight()
        f.updateVisibleHighlight()
        f.saveCurrentTabContent()
    end},
    {name = "Format Code", action = function() u.FormatBtn.MouseButton1Click:Fire() end},
    {name = "Open Settings", action = function() f.toggleSettings() end},
    {name = "Script Hub", action = function() u.HubPanel.Visible = true end},
}

local function showCmdResults(filter)
    for _, child in ipairs(u.CmdResults:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local matches = {}
    for _, cmd in ipairs(cmdActions) do
        if #filter == 0 or cmd.name:lower():find(filter:lower()) then matches[#matches+1] = cmd end
    end
    for i, cmd in ipairs(matches) do
        if i > 8 then break end
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = s.currentTheme.tabBg
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamMedium
        btn.Text = "  " .. cmd.name
        btn.TextColor3 = s.currentTheme.text
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 41
        btn.Parent = u.CmdResults
        corner(btn, 4)
        btn.MouseButton1Click:Connect(function()
            u.CmdPalette.Visible = false
            u.CmdResults.Visible = false
            cmd.action()
        end)
    end
    if #matches > 0 then
        u.CmdResults.Size = UDim2.new(1, 0, 0, math.min(#matches, 8) * 29 + 4)
        u.CmdResults.Visible = true
    else
        u.CmdResults.Visible = false
    end
end

--==================== EVENT WIRING ====================
u.CloseBtn.MouseButton1Click:Connect(function()
    f.saveCurrentTabContent()
    local data = f.serializeState()
    if data ~= s.lastSaveData then fileWrite(SAVE_FILE, data) end
    s.guiFolder:Destroy()
end)

u.CollapseBtn.MouseButton1Click:Connect(function()
    s.isCollapsed = not s.isCollapsed
    local tw = TweenInfo.new(0.2)
    if s.isCollapsed then
        TweenService:Create(u.TabBar, tw, {Size = UDim2.new(1, -24, 0, 0)}):Play()
        TweenService:Create(u.Toolbar, tw, {Size = UDim2.new(1, -24, 0, 0)}):Play()
        TweenService:Create(u.EditorContainer, tw, {Size = UDim2.new(1, -24, 0, 0)}):Play()
        TweenService:Create(u.ErrorFrame, tw, {Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 1, -8)}):Play()
        TweenService:Create(u.StatusBar, tw, {Size = UDim2.new(1, -24, 0, 0)}):Play()
        u.CollapseBtn.Text = "+"
    else
        TweenService:Create(u.TabBar, tw, {Size = UDim2.new(1, -24, 0, 30)}):Play()
        TweenService:Create(u.Toolbar, tw, {Size = UDim2.new(1, -24, 0, 34)}):Play()
        TweenService:Create(u.EditorContainer, tw, {Size = UDim2.new(1, -24, 1, -210), Position = UDim2.new(0, 12, 0, 116)}):Play()
        TweenService:Create(u.ErrorFrame, tw, {Size = UDim2.new(1, -24, 0, 48), Position = UDim2.new(0, 12, 1, -74)}):Play()
        TweenService:Create(u.StatusBar, tw, {Size = UDim2.new(1, -24, 0, 22)}):Play()
        u.CollapseBtn.Text = "—"
    end
end)

u.SettingsBtn.MouseButton1Click:Connect(f.toggleSettings)
u.sfClose.MouseButton1Click:Connect(f.toggleSettings)
u.seClose.MouseButton1Click:Connect(function() u.SnippetEditorFrame.Visible = false end)
u.teClose.MouseButton1Click:Connect(function() u.ThemeEditorFrame.Visible = false end)
u.FindCloseBtn.MouseButton1Click:Connect(function() u.FindBar.Visible = false end)
u.HubClose.MouseButton1Click:Connect(function() u.HubPanel.Visible = false end)

u.seSaveBtn.MouseButton1Click:Connect(function()
    local name, desc, code = u.seNameBox.Text, u.seDescBox.Text, u.seCodeBox.Text
    if not name or #name < 1 then return end
    if s.editingSnippetIndex then
        s.snippets[s.editingSnippetIndex] = {name = name, description = desc, code = code}
    else
        s.snippets[#s.snippets+1] = {name = name, description = desc, code = code}
    end
    u.SnippetEditorFrame.Visible = false
    f.rebuildSnippetsPanel()
end)

u.teSaveBtn.MouseButton1Click:Connect(function()
    local name = u.teNameBox.Text
    if not name or #name < 1 then return end
    local themeData = {}
    for _, prop in ipairs(editableProps) do
        local c = s.themeEditorColors[prop.key]
        if c and type(c) == "table" then
            themeData[prop.key] = Color3.fromRGB(c[1] or 0, c[2] or 0, c[3] or 0)
        end
    end
    local trans = tonumber(u.teTransBox.Text) or 0
    themeData.transparency = math.clamp(trans, 0, 100) / 100
    themeData.bgStyle = s.teBgStyle
    if s.editingThemeName and s.customThemes[s.editingThemeName] then
        s.customThemes[s.editingThemeName] = nil
    end
    s.customThemes[name] = themeData
    u.ThemeEditorFrame.Visible = false
    f.applyTheme(name)
    f.rebuildThemeSection()
end)

u.teBaseBtn.MouseButton1Click:Connect(function()
    local presetNames = {"Midnight", "Glass", "Dracula", "Monokai", "Solarized", "Light", "Synapse"}
    local currentIdx = 1
    for i, name in ipairs(presetNames) do
        if name == s.teBaseThemeName then currentIdx = i break end
    end
    currentIdx = currentIdx % #presetNames + 1
    s.teBaseThemeName = presetNames[currentIdx]
    u.teBaseBtn.Text = s.teBaseThemeName .. " ▾"
    local baseT = themes[s.teBaseThemeName]
    if baseT then
        for _, prop in ipairs(editableProps) do
            local c = baseT[prop.key]
            if typeof(c) == "Color3" then
                s.themeEditorColors[prop.key] = {math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)}
            end
        end
        s.teBgStyle = baseT.bgStyle or "solid"
        u.teBgStyleBtn.Text = s.teBgStyle:sub(1,1):upper()..s.teBgStyle:sub(2) .. " ▾"
        u.teTransBox.Text = tostring(math.floor((baseT.transparency or 0) * 100))
        buildThemeEditorRows()
    end
end)

u.teBgStyleBtn.MouseButton1Click:Connect(function()
    local styles = {"solid", "gradient", "glass"}
    local currentIdx = 1
    for i, st in ipairs(styles) do
        if st == s.teBgStyle then currentIdx = i break end
    end
    currentIdx = currentIdx % #styles + 1
    s.teBgStyle = styles[currentIdx]
    u.teBgStyleBtn.Text = s.teBgStyle:sub(1,1):upper()..s.teBgStyle:sub(2) .. " ▾"
end)

u.ExecuteBtn.MouseButton1Click:Connect(function()
    for _, tab in ipairs(s.tabs) do
        if tab.isAutoExec and tab.id ~= s.activeTabId then
            if tab.gameId and #tab.gameId > 0 then
                if game.PlaceId == tonumber(tab.gameId) then f.executeCode(tab.content, true) end
            else
                f.executeCode(tab.content, true)
            end
        end
    end
    f.executeCode(s.fullText, false)
end)

u.ClearBtn.MouseButton1Click:Connect(function()
    s.fullText = ""
    u.EditorTextBox.Text = ""
    u.HighlightedCode.Text = ""
    u.LineNumbers.Text = "1"
    s.totalLineCount = 1
    u.ErrorLabel.Text = "No errors."
    u.ErrorLabel.TextColor3 = s.currentTheme.errSuccess
    f.updateContentHeight()
    f.updateVisibleHighlight()
    f.updateStatusBar()
    f.saveCurrentTabContent()
end)

u.CopyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(s.fullText)
        u.ErrorLabel.Text = "✓ Copied to clipboard."
        u.ErrorLabel.TextColor3 = s.currentTheme.errSuccess
    end
end)

u.NewLineBtn.MouseButton1Click:Connect(function()
    local pos = u.EditorTextBox.CursorPosition or (#s.fullText + 1)
    s.fullText = s.fullText:sub(1, pos - 1) .. "\n" .. s.fullText:sub(pos)
    u.EditorTextBox.Text = s.fullText
    u.EditorTextBox.CursorPosition = pos + 1
    s.totalLineCount = calcLineCount(s.fullText)
    f.updateLineNumbers(s.fullText)
    f.updateContentHeight()
    f.updateVisibleHighlight()
    f.saveCurrentTabContent()
end)

u.SnippetsBtn.MouseButton1Click:Connect(function()
    local snipPos = u.SnippetsBtn.AbsolutePosition
    local mainPos = u.MainFrame.AbsolutePosition
    u.SnippetsDropdown.Position = UDim2.new(0, snipPos.X - mainPos.X, 0, snipPos.Y - mainPos.Y + 24)
    u.SnippetsDropdown.Visible = not u.SnippetsDropdown.Visible
    if u.SnippetsDropdown.Visible then f.rebuildSnippetsPanel() end
end)

u.sdAddBtn.MouseButton1Click:Connect(function()
    if s.fullText and #s.fullText > 0 then
        s.editingSnippetIndex = nil
        u.seNameBox.Text = ""
        u.seDescBox.Text = ""
        u.seCodeBox.Text = s.fullText
        u.seTitle.Text = "New Snippet"
        u.SnippetEditorFrame.Visible = true
    end
end)

u.TemplatesBtn.MouseButton1Click:Connect(function()
    local tempPos = u.TemplatesBtn.AbsolutePosition
    local mainPos = u.MainFrame.AbsolutePosition
    u.TemplatesDropdown.Position = UDim2.new(0, tempPos.X - mainPos.X, 0, tempPos.Y - mainPos.Y + 24)
    u.TemplatesDropdown.Visible = not u.TemplatesDropdown.Visible
    if u.TemplatesDropdown.Visible then f.rebuildTemplatesDropdown() end
end)

u.FindBtn.MouseButton1Click:Connect(function()
    u.FindBar.Visible = not u.FindBar.Visible
    if u.FindBar.Visible then u.FindBox:CaptureFocus() end
end)

u.FindNextBtn.MouseButton1Click:Connect(function()
    local search = u.FindBox.Text
    if not search or #search == 0 then return end
    local pos = u.EditorTextBox.CursorPosition or 1
    local found = s.fullText:find(search, pos + 1, true) or s.fullText:find(search, 1, true)
    if found then
        u.EditorTextBox.CursorPosition = found
        u.EditorTextBox.SelectionStart = found
        u.EditorTextBox.CursorPosition = found + #search
        local line = select(1, getCursorLineCol(s.fullText, found))
        u.EditorScroll.CanvasPosition = Vector2.new(0, math.max(0, (line - 5) * s.lineHeight))
        u.FindMatchLabel.Text = "Match at line " .. line
    else
        u.FindMatchLabel.Text = "No matches"
    end
end)

u.ReplaceBtn.MouseButton1Click:Connect(function()
    local search, replacement = u.FindBox.Text, u.ReplaceBox.Text
    if not search or #search == 0 then return end
    local pos = u.EditorTextBox.CursorPosition or 1
    local found = s.fullText:find(search, pos, true) or s.fullText:find(search, 1, true)
    if found then
        s.fullText = s.fullText:sub(1, found - 1) .. replacement .. s.fullText:sub(found + #search)
        u.EditorTextBox.Text = s.fullText
        u.EditorTextBox.CursorPosition = found + #replacement
        s.totalLineCount = calcLineCount(s.fullText)
        f.updateLineNumbers(s.fullText)
        f.updateContentHeight()
        f.updateVisibleHighlight()
    end
end)

u.ReplaceAllBtn.MouseButton1Click:Connect(function()
    local search, replacement = u.FindBox.Text, u.ReplaceBox.Text
    if not search or #search == 0 then return end
    local count = 0
    local result = s.fullText:gsub(search:gsub("%%", "%%%%"), function() count = count + 1; return replacement end, math.huge)
    s.fullText = result
    u.EditorTextBox.Text = s.fullText
    s.totalLineCount = calcLineCount(s.fullText)
    f.updateLineNumbers(s.fullText)
    f.updateContentHeight()
    f.updateVisibleHighlight()
    f.saveCurrentTabContent()
    u.FindMatchLabel.Text = "Replaced " .. count .. " matches"
end)

u.GotoGoBtn.MouseButton1Click:Connect(function()
    local lineNum = tonumber(u.GotoBox.Text)
    if lineNum and lineNum > 0 then
        local lineStart = getLineStart(s.fullText, math.min(lineNum, s.totalLineCount))
        u.EditorTextBox.CursorPosition = lineStart
        u.EditorScroll.CanvasPosition = Vector2.new(0, math.max(0, (lineNum - 5) * s.lineHeight))
        u.GotoFrame.Visible = false
        u.GotoBox.Text = ""
    end
end)
u.GotoBox.FocusLost:Connect(function(enter) if enter then u.GotoGoBtn.MouseButton1Click:Fire() end end)

u.GameIdSaveBtn.MouseButton1Click:Connect(function()
    local id = u.GameIdBox.Text
    for _, tab in ipairs(s.tabs) do
        if tab.id == s.contextTabId then
            tab.gameId = id or ""
            if #tab.gameId == 0 then tab.isAutoExec = false else tab.isAutoExec = true end
            f.rebuildTabBar()
            break
        end
    end
    u.GameIdFrame.Visible = false
end)
u.GameIdBox.FocusLost:Connect(function(enter) if enter then u.GameIdSaveBtn.MouseButton1Click:Fire() end end)

u.FormatBtn.MouseButton1Click:Connect(function()
    local lines = {}
    for line in s.fullText:gmatch("[^\n]*") do lines[#lines+1] = line end
    local indentLevel = 0
    local formatted = {}
    for _, line in ipairs(lines) do
        local trimmed = line:match("^%s*(.*)") or ""
        if trimmed:match("^%s*end") or trimmed:match("^%s*else") or trimmed:match("^%s*elseif") or trimmed:match("^%s*until") or trimmed:match("^%s*%}") then
            indentLevel = math.max(0, indentLevel - 1)
        end
        formatted[#formatted+1] = #trimmed > 0 and string.rep("    ", indentLevel) .. trimmed or ""
        if trimmed:match("%bdo$") or trimmed:match("%bthen$") or trimmed:match("%bfunction.*%(") or trimmed:match("^%s*else") or trimmed:match("^%s*for") or trimmed:match("^%s*while") or trimmed:match("^%s*repeat") then
            indentLevel = indentLevel + 1
        end
    end
    s.fullText = table.concat(formatted, "\n")
    u.EditorTextBox.Text = s.fullText
    s.totalLineCount = calcLineCount(s.fullText)
    f.updateLineNumbers(s.fullText)
    f.updateContentHeight()
    f.updateVisibleHighlight()
    f.saveCurrentTabContent()
    u.ErrorLabel.Text = "✓ Code formatted."
    u.ErrorLabel.TextColor3 = s.currentTheme.errSuccess
end)

u.ConsoleClearBtn.MouseButton1Click:Connect(function()
    s.consoleMessages = {}
    for _, child in ipairs(u.ConsoleScroll:GetChildren()) do
        if child:IsA("TextLabel") then child:Destroy() end
    end
    u.ConsoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
end)

u.wrapBtn.MouseButton1Click:Connect(function()
    s.wordWrap = not s.wordWrap
    u.wrapBtn.Text = s.wordWrap and "ON" or "OFF"
    u.wrapLabel.Text = "Word Wrap: " .. (s.wordWrap and "On" or "Off")
    u.EditorTextBox.TextWrapped = s.wordWrap
end)

u.indentBtn.MouseButton1Click:Connect(function()
    s.autoIndent = not s.autoIndent
    u.indentBtn.Text = s.autoIndent and "ON" or "OFF"
    u.indentLabel.Text = "Auto Indent: " .. (s.autoIndent and "On" or "Off")
end)

-- Script Hub events
u.HubBtn.MouseButton1Click:Connect(function()
    u.HubPanel.Visible = not u.HubPanel.Visible
    if u.HubPanel.Visible and #s.hubResults == 0 then
        f.searchScriptBlox("", 1, s.hubMode, false)
    end
end)

u.HubSearchBtn.MouseButton1Click:Connect(function()
    s.hubQuery = u.HubSearchBox.Text
    s.hubPage = 1
    f.searchScriptBlox(s.hubQuery, s.hubPage, s.hubMode, false)
end)

u.HubSearchBox.FocusLost:Connect(function(enter)
    if enter then u.HubSearchBtn.MouseButton1Click:Fire() end
end)

u.HubFilterBtn.MouseButton1Click:Connect(function()
    local modes = {"free", "paid", "all"}
    local labels = {"Keyless ▾", "Key Required ▾", "All ▾"}
    local currentIdx = 1
    for i, m in ipairs(modes) do
        if m == s.hubMode then currentIdx = i break end
    end
    currentIdx = currentIdx % #modes + 1
    s.hubMode = modes[currentIdx]
    u.HubFilterBtn.Text = labels[currentIdx]
    s.hubPage = 1
    f.searchScriptBlox(s.hubQuery, s.hubPage, s.hubMode, false)
end)

u.HubLoadMoreBtn.MouseButton1Click:Connect(function()
    s.hubPage = s.hubPage + 1
    f.searchScriptBlox(s.hubQuery, s.hubPage, s.hubMode, true)
end)

-- Editor events
u.EditorTextBox.Focused:Connect(function()
    u.HighlightedCode.Visible = false
    u.EditorTextBox.TextTransparency = 0
end)

u.EditorTextBox.FocusLost:Connect(function()
    u.EditorTextBox.TextTransparency = 1
    s.fullText = u.EditorTextBox.Text
    s.totalLineCount = calcLineCount(s.fullText)
    f.updateVisibleHighlight()
    f.saveCurrentTabContent()
    f.updateStatusBar()
end)

u.EditorTextBox:GetPropertyChangedSignal("Text"):Connect(function()
    s.fullText = u.EditorTextBox.Text
    s.totalLineCount = calcLineCount(s.fullText)
    f.updateLineNumbers(s.fullText)
    f.updateContentHeight()
    if not u.EditorTextBox:IsFocused() then f.updateVisibleHighlight() end
    local tab = f.getActiveTab()
    if tab then tab.content = s.fullText end
    f.updateStatusBar()
end)

u.EditorTextBox:GetPropertyChangedSignal("CursorPosition"):Connect(f.updateStatusBar)
u.EditorScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(f.updateVisibleHighlight)
u.EditorScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    f.updateContentHeight()
    f.updateVisibleHighlight()
end)

u.fsSlider.FocusLost:Connect(function()
    local num = tonumber(u.fsSlider.Text)
    if num then
        s.fontSize = math.clamp(math.floor(num), 8, 24)
        u.fsSlider.Text = tostring(s.fontSize)
        u.fsLabel.Text = "Font Size: " .. s.fontSize
        u.EditorTextBox.TextSize = s.fontSize
        u.HighlightedCode.TextSize = s.fontSize
        u.LineNumbers.TextSize = s.fontSize
        s.lineHeight = s.fontSize + 4
        f.updateContentHeight()
        f.updateVisibleHighlight()
    else
        u.fsSlider.Text = tostring(s.fontSize)
    end
end)

u.CmdBox:GetPropertyChangedSignal("Text"):Connect(function() showCmdResults(u.CmdBox.Text) end)
u.CmdBox.FocusLost:Connect(function()
    task.delay(0.1, function()
        u.CmdPalette.Visible = false
        u.CmdResults.Visible = false
    end)
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if u.ContextMenu.Visible then u.ContextMenu.Visible = false end
        for _, ddData in ipairs({
            {dropdown = u.SnippetsDropdown, btn = u.SnippetsBtn},
            {dropdown = u.TemplatesDropdown, btn = u.TemplatesBtn},
        }) do
            if ddData.dropdown.Visible then
                local m = UserInputService:GetMouseLocation()
                local dp = ddData.dropdown.AbsolutePosition
                local ds = ddData.dropdown.AbsoluteSize
                local bp = ddData.btn.AbsolutePosition
                local bs = ddData.btn.AbsoluteSize
                if not ((m.X >= dp.X and m.X <= dp.X + ds.X and m.Y >= dp.Y and m.Y <= dp.Y + ds.Y) or
                        (m.X >= bp.X and m.X <= bp.X + bs.X and m.Y >= bp.Y and m.Y <= bp.Y + bs.Y)) then
                    ddData.dropdown.Visible = false
                end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
    local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

    if ctrl and input.KeyCode == Enum.KeyCode.Return then
        u.ExecuteBtn.MouseButton1Click:Fire()
    elseif ctrl and input.KeyCode == Enum.KeyCode.S then
        local data = f.serializeState()
        fileWrite(SAVE_FILE, data)
        s.lastSaveData = data
        u.SaveIndicator.Text = "● Saved"
        u.SaveIndicator.TextColor3 = s.currentTheme.errSuccess
    elseif ctrl and input.KeyCode == Enum.KeyCode.N then
        f.switchTab(f.createTab("Tab " .. (#s.tabs + 1), "").id)
    elseif ctrl and input.KeyCode == Enum.KeyCode.F then
        u.FindBar.Visible = not u.FindBar.Visible
        if u.FindBar.Visible then u.FindBox:CaptureFocus() end
    elseif ctrl and input.KeyCode == Enum.KeyCode.G then
        u.GotoFrame.Visible = true
        u.GotoBox:CaptureFocus()
    elseif ctrl and input.KeyCode == Enum.KeyCode.Slash then
        local pos = u.EditorTextBox.CursorPosition or 1
        local lineStart = getLineStart(s.fullText, select(1, getCursorLineCol(s.fullText, pos)))
        s.fullText = s.fullText:sub(1, lineStart - 1) .. "-- " .. s.fullText:sub(lineStart)
        u.EditorTextBox.Text = s.fullText
        u.EditorTextBox.CursorPosition = pos + 3
        s.totalLineCount = calcLineCount(s.fullText)
        f.updateLineNumbers(s.fullText)
        f.updateContentHeight()
        f.updateVisibleHighlight()
        f.saveCurrentTabContent()
    elseif ctrl and input.KeyCode == Enum.KeyCode.D then
        local pos = u.EditorTextBox.CursorPosition or 1
        local lineNum = select(1, getCursorLineCol(s.fullText, pos))
        local lineStart = getLineStart(s.fullText, lineNum)
        local nextNL = s.fullText:find("\n", lineStart, true)
        local lineEnd = nextNL and nextNL or #s.fullText + 1
        local lineText = s.fullText:sub(lineStart, lineEnd - 1)
        s.fullText = s.fullText:sub(1, lineEnd - 1) .. "\n" .. lineText .. s.fullText:sub(lineEnd)
        u.EditorTextBox.Text = s.fullText
        u.EditorTextBox.CursorPosition = lineEnd + #lineText + 1
        s.totalLineCount = calcLineCount(s.fullText)
        f.updateLineNumbers(s.fullText)
        f.updateContentHeight()
        f.updateVisibleHighlight()
        f.saveCurrentTabContent()
    elseif ctrl and shift and input.KeyCode == Enum.KeyCode.P then
        u.CmdPalette.Visible = true
        u.CmdResults.Visible = false
        u.CmdBox.Text = ""
        u.CmdBox:CaptureFocus()
    elseif input.KeyCode == Enum.KeyCode.F11 then
        if u.MainFrame.Size == UDim2.new(1, 0, 1, 0) then
            u.MainFrame.Size = UDim2.new(0, 700, 0, 540)
            u.MainFrame.Position = UDim2.new(0.5, -350, 0.5, -270)
        else
            u.MainFrame.Size = UDim2.new(1, 0, 1, 0)
            u.MainFrame.Position = UDim2.new(0, 0, 0, 0)
        end
    end
end)

local function addHover(btn, defaultColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = s.currentTheme.tabHoverBg}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = defaultColor}):Play()
    end)
end
for _, btnName in ipairs({"CollapseBtn","SettingsBtn","ClearBtn","CopyBtn","NewLineBtn","SnippetsBtn","FormatBtn","TemplatesBtn","FindBtn"}) do
    addHover(u[btnName], s.currentTheme.tabBg)
end

--==================== INIT ====================
local savedState = (function()
    local content = fileRead(SAVE_FILE)
    if not content then return nil end
    return jsonDecode(content)
end)()

if savedState then
    if savedState.tabs and #savedState.tabs > 0 then
        for _, tab in ipairs(savedState.tabs) do
            s.tabIdCounter = math.max(s.tabIdCounter, tab.id)
            s.tabs[#s.tabs+1] = {id = tab.id, name = tab.name, content = tab.content or "", isAutoExec = tab.isAutoExec or false, gameId = tab.gameId or ""}
        end
    end
    if savedState.snippets and #savedState.snippets > 0 then
        s.snippets = savedState.snippets
    else
        for _, snip in ipairs(startingSnippets) do
            s.snippets[#s.snippets+1] = {name = snip.name, description = snip.description, code = snip.code}
        end
    end
    if savedState.themes then
        for name, themeData in pairs(savedState.themes) do
            local theme = {}
            for k, v in pairs(themeData) do
                if type(v) == "table" and #v == 3 then theme[k] = Color3.fromRGB(v[1], v[2], v[3])
                else theme[k] = v end
            end
            s.customThemes[name] = theme
        end
    end
    if savedState.settings then
        if savedState.settings.theme then s.currentThemeName = savedState.settings.theme end
        if savedState.settings.fontSize then
            s.fontSize = savedState.settings.fontSize
            u.EditorTextBox.TextSize = s.fontSize
            u.HighlightedCode.TextSize = s.fontSize
            u.LineNumbers.TextSize = s.fontSize
            s.lineHeight = s.fontSize + 4
            u.fsSlider.Text = tostring(s.fontSize)
            u.fsLabel.Text = "Font Size: " .. s.fontSize
        end
        if savedState.settings.wordWrap ~= nil then
            s.wordWrap = savedState.settings.wordWrap
            u.wrapBtn.Text = s.wordWrap and "ON" or "OFF"
            u.wrapLabel.Text = "Word Wrap: " .. (s.wordWrap and "On" or "Off")
            u.EditorTextBox.TextWrapped = s.wordWrap
        end
        if savedState.settings.autoIndent ~= nil then
            s.autoIndent = savedState.settings.autoIndent
            u.indentBtn.Text = s.autoIndent and "ON" or "OFF"
            u.indentLabel.Text = "Auto Indent: " .. (s.autoIndent and "On" or "Off")
        end
    end
else
    for _, snip in ipairs(startingSnippets) do
        s.snippets[#s.snippets+1] = {name = snip.name, description = snip.description, code = snip.code}
    end
    f.createTab("Tab 1", "-- Welcome to Executor Pro\nprint('Hello World')")
end

if #s.tabs == 0 then f.createTab("Tab 1", "") end
s.activeTabId = s.tabs[1].id

f.applyTheme(s.currentThemeName)
f.loadTab(s.activeTabId)
f.rebuildTabBar()
f.rebuildSnippetsPanel()
f.rebuildThemeSection()
f.rebuildTemplatesDropdown()
f.updateContentHeight()
f.updateVisibleHighlight()
f.updateStatusBar()

u.HighlightedCode.Visible = true
u.EditorTextBox.TextTransparency = 1

task.delay(0.5, function()
    local msg, color
    if s.execName ~= "Unknown" and s.execKnown and s.execHasWorkspace then
        msg = s.execName .. " is supported. Workspace folder active."
        color = Color3.fromRGB(80, 200, 120)
    elseif s.execName ~= "Unknown" and s.execKnown and not s.execHasWorkspace then
        msg = s.execName .. " is known but workspace folder was not found."
        color = Color3.fromRGB(255, 200, 80)
    elseif s.execName ~= "Unknown" and not s.execKnown then
        msg = s.execName .. " is unknown if supported. Please check the workspace folder."
        color = Color3.fromRGB(255, 200, 80)
    else
        msg = "Could not identify executor. Some features may be limited."
        color = Color3.fromRGB(255, 150, 80)
    end
    f.showNotification("Executor: " .. s.execName, msg, color)
end)

task.spawn(f.autoSaveLoop)
