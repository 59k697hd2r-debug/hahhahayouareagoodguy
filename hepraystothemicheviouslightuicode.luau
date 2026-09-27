
local Players          = game:GetService("Players")
local CoreGui          = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local MAX_DISPLAY_CHARS = 30000

local LuaKeywords = {
    ["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
    ["end"]=true,["false"]=true,["for"]=true,["function"]=true,["if"]=true,
    ["in"]=true,["local"]=true,["nil"]=true,["not"]=true,["or"]=true,
    ["repeat"]=true,["return"]=true,["then"]=true,["true"]=true,["until"]=true,
    ["while"]=true,["continue"]=true,
}

local KnownReadOnly = {
    ["AbsolutePosition"]=true,["AbsoluteSize"]=true,["AbsoluteRotation"]=true,
    ["AbsoluteContentSize"]=true,["ScreenSize"]=true,["ViewportSize"]=true,
    ["CursorPosition"]=true,["SelectionStart"]=true,["CanvasPosition"]=true,
    ["IsLoaded"]=true,["DataCost"]=true,["SourceAssetId"]=true,["Source"]=true,
    ["CurrentCamera"]=true,["SelectionImageObject"]=true,["Adornee"]=true,
    ["RootLocalizationTable"]=true,["NextSelectionDown"]=true,
    ["NextSelectionUp"]=true,["NextSelectionLeft"]=true,["NextSelectionRight"]=true,
    ["HistoryId"]=true,["WebCommandId"]=true,["Tags"]=true,
    ["SecurityContext"]=true,["Creator"]=true,["ClassName"]=true,
    ["Archivable"]=true,["TextBounds"]=true,["TextFits"]=true,
    ["ContentTextScale"]=true,["OnScreenKeyboardOpened"]=true,
    ["TextBoundsScale"]=true,["Parent"]=true,
}

local SkipProps = {
    ["Parent"]=true,["ClassName"]=true,["Name"]=true,["Archivable"]=true,
    ["AbsolutePosition"]=true,["AbsoluteSize"]=true,["AbsoluteRotation"]=true,
    ["AbsoluteContentSize"]=true,["ScreenSize"]=true,["ViewportSize"]=true,
    ["CursorPosition"]=true,["SelectionStart"]=true,["CanvasPosition"]=true,
    ["IsLoaded"]=true,["DataCost"]=true,["SourceAssetId"]=true,["Source"]=true,
    ["CurrentCamera"]=true,["SelectionImageObject"]=true,["Adornee"]=true,
    ["RootLocalizationTable"]=true,["NextSelectionDown"]=true,
    ["NextSelectionUp"]=true,["NextSelectionLeft"]=true,["NextSelectionRight"]=true,
    ["HistoryId"]=true,["WebCommandId"]=true,["Tags"]=true,
    ["SecurityContext"]=true,["Creator"]=true,
}

local FallbackProperties = {
    "Position","Size","AnchorPoint","BackgroundColor3","BackgroundTransparency",
    "BorderColor3","BorderSizePixel","Visible","ZIndex","Rotation",
    "ClipsDescendants","LayoutOrder","Selectable","Active","BorderMode",
    "AutoLocalize","SelectionOrder","BorderScaleMode",
    "TargetDesiredAspectRatio","SafeAreaCompatibility",
    "Text","TextColor3","TextSize","FontFace","Font","TextTransparency",
    "TextStrokeColor3","TextStrokeTransparency","TextScaled","TextWrapped",
    "TextXAlignment","TextYAlignment","RichText","TextTruncate","LineHeight",
    "MaxVisibleGraphemes","TextDirection",
    "PlaceholderText","PlaceholderColor3","ClearTextOnFocus","MultiLine",
    "ShowNativeInput","TextInputType","TextEditable",
    "OnScreenKeyboardAnimateTime","SelectionBehavior",
    "AutoButtonColor","Modal","ClickableWhenDisabled",
    "Image","ImageColor3","ImageTransparency","ScaleType","TileSize",
    "SliceCenter","SliceScale","ImageRectOffset","ImageRectSize","ResampleMode",
    "ScrollBarThickness","ScrollBarImageColor3","ScrollBarImageTransparency",
    "ScrollBarImage","CanvasSize","AutomaticCanvasSize","ScrollDirection",
    "ScrollingEnabled","ScrollBarInset","ElasticBehavior",
    "MaxCanvasSize","AlwaysRespectAutosize",
    "DisplayOrder","IgnoreGuiInset","ResetOnSpawn","ScreenOrientation",
    "AutoResetOnSpawn","Enabled","RespectsScreenSafeArea",
    "FillDirection","Padding","SortOrder","HorizontalAlignment",
    "VerticalAlignment","Wraps","CellSize","CellPadding",
    "StartingCorner","MajorAxis","Circular",
    "Color","Thickness","Transparency","ApplyStrokeMode","LineJoinMode",
    "CornerRadius","Offset","Scale",
    "PaddingLeft","PaddingRight","PaddingTop","PaddingBottom",
    "AspectRatio","DominantAxis","AspectRatioType","MaxSize","MinSize",
    "MaxTextSize","MinTextSize",
    "Style",
    "GroupTransparency","GroupColor3",
    "AlwaysOnTop","ExtentsOffset","ExtentsOffsetWorldSpace",
    "LightInfluence","MaxDistance","SizeOffset","StudsOffset",
    "StudsOffsetWorldSpace",
    "ToolPunchThroughMouseEvents","ZOffset","SizingMode","Face",
    "Video","Looped","Playing","Volume","Speed",
    "Value",
    "FlexMode","GrowFactor","ShrinkFactor","ItemLineAlignment","FlexItemMode",
    "StreamingTargetMode","Streamable","AlwaysRespectTextBounds",
    "RelativeSize","TickScrollDistance",
}

do
    local seen = {}
    local deduped = {}
    for _, p in ipairs(FallbackProperties) do
        if not seen[p] then seen[p] = true; deduped[#deduped + 1] = p end
    end
    FallbackProperties = deduped
end

local Themes = {
    Dark = {
        BG=Color3.fromRGB(24,24,32),TitleBar=Color3.fromRGB(32,32,44),
        Input=Color3.fromRGB(32,32,44),InputDark=Color3.fromRGB(28,28,40),
        Output=Color3.fromRGB(18,18,26),Accent=Color3.fromRGB(88,101,242),
        Text=Color3.fromRGB(235,235,245),Subtle=Color3.fromRGB(130,130,150),
        Copy=Color3.fromRGB(67,181,129),Clear=Color3.fromRGB(240,71,71),
        Scroll=Color3.fromRGB(80,80,100),Hover=Color3.fromRGB(108,121,242),
        OutText=Color3.fromRGB(200,200,220),Stroke=Color3.fromRGB(50,50,70),
        Sep=Color3.fromRGB(45,45,60),Warn=Color3.fromRGB(240,180,50),
        WarnBg=Color3.fromRGB(50,30,15),Exec=Color3.fromRGB(220,170,50),
    },
    Light = {
        BG=Color3.fromRGB(238,238,242),TitleBar=Color3.fromRGB(225,225,232),
        Input=Color3.fromRGB(225,225,232),InputDark=Color3.fromRGB(215,215,222),
        Output=Color3.fromRGB(248,248,252),Accent=Color3.fromRGB(88,101,242),
        Text=Color3.fromRGB(30,30,40),Subtle=Color3.fromRGB(100,100,120),
        Copy=Color3.fromRGB(67,181,129),Clear=Color3.fromRGB(240,71,71),
        Scroll=Color3.fromRGB(150,150,170),Hover=Color3.fromRGB(108,121,242),
        OutText=Color3.fromRGB(50,50,60),Stroke=Color3.fromRGB(180,180,195),
        Sep=Color3.fromRGB(200,200,215),Warn=Color3.fromRGB(200,140,20),
        WarnBg=Color3.fromRGB(255,245,225),Exec=Color3.fromRGB(190,140,20),
    }
}

local currentTheme = "Dark"
local MIN_W, MIN_H = 500, 480
local DEFAULT_W, DEFAULT_H = 680, 700

local function setClipboard(text)
    local ok = false
    pcall(function() setclipboard(text) ok = true end)
    if not ok then pcall(function() to_clipboard(text) ok = true end) end
    if not ok then pcall(function() writeclipboard(text) ok = true end) end
    if not ok and type(_G.setclipboard)=="function" then pcall(_G.setclipboard,text) ok=true end
    if not ok and type(_G.to_clipboard)=="function" then pcall(_G.to_clipboard,text) ok=true end
    if not ok and type(_G.writeclipboard)=="function" then pcall(_G.writeclipboard,text) ok=true end
    if not ok and type(Clipboard)=="table" and type(Clipboard.set)=="function" then pcall(Clipboard.set,text) ok=true end
    return ok
end

local function hasWritefile() return type(writefile)=="function" end
local function hasLoadstring() return type(loadstring)=="function" or type(load)=="function" end
local function getLoadFn()
    if type(loadstring)=="function" then return loadstring end
    if type(load)=="function" then return load end
    return nil
end

local function fmtNum(n)
    if n~=n then return "0/0" end
    if n==math.huge then return "math.huge" end
    if n==-math.huge then return "-math.huge" end
    if math.abs(n)<1e-10 then return "0" end
    if math.abs(n-math.round(n))<1e-6 then return tostring(math.round(n)) end
    return string.format("%.6f",n):gsub("0+$",""):gsub("%.$","")
end

-- UNICODE-SAFE string escaping: converts ALL non-ASCII bytes to \ddd decimal escapes
-- Guarantees output is pure ASCII that any Lua 5.1 / Luau executor can parse
local function fmtStr(s)
    s = tostring(s)
    local result = {'"'}
    for i = 1, #s do
        local byte = string.byte(s, i)
        if byte == 34 then
            result[#result+1] = '\\"'
        elseif byte == 92 then
            result[#result+1] = '\\\\'
        elseif byte == 10 then
            result[#result+1] = '\\n'
        elseif byte == 13 then
            result[#result+1] = '\\r'
        elseif byte == 0 then
            result[#result+1] = '\\0'
        elseif byte < 32 or byte > 126 then
            result[#result+1] = string.format('\\%d', byte)
        else
            result[#result+1] = string.char(byte)
        end
    end
    result[#result+1] = '"'
    return table.concat(result)
end

local function sanitizeName(name)
    if not name or name=="" then return "" end
    local clean = name:gsub("[^%a%d_]","_")
    if clean:match("^%d") then clean = "_" .. clean end
    if LuaKeywords[clean] then clean = "_" .. clean end
    if clean=="" then clean = "unnamed" end
    return clean
end

local function valuesEqual(a, b)
    if a==nil or b==nil then return a==b end
    local ta, tb = typeof(a), typeof(b)
    if ta~=tb then return false end
    if ta=="number" then return math.abs(a-b)<0.001
    elseif ta=="string" or ta=="boolean" then return a==b
    elseif ta=="Color3" then return math.abs(a.R-b.R)<0.002 and math.abs(a.G-b.G)<0.002 and math.abs(a.B-b.B)<0.002
    elseif ta=="UDim" then return math.abs(a.Scale-b.Scale)<0.002 and math.abs(a.Offset-b.Offset)<0.002
    elseif ta=="UDim2" then
        return math.abs(a.X.Scale-b.X.Scale)<0.002 and math.abs(a.X.Offset-b.X.Offset)<0.002
           and math.abs(a.Y.Scale-b.Y.Scale)<0.002 and math.abs(a.Y.Offset-b.Y.Offset)<0.002
    elseif ta=="Vector2" then return math.abs(a.X-b.X)<0.002 and math.abs(a.Y-b.Y)<0.002
    elseif ta=="Vector3" then return math.abs(a.X-b.X)<0.002 and math.abs(a.Y-b.Y)<0.002 and math.abs(a.Z-b.Z)<0.002
    elseif ta=="Rect" then
        return math.abs(a.Min.X-b.Min.X)<0.002 and math.abs(a.Min.Y-b.Min.Y)<0.002
           and math.abs(a.Max.X-b.Max.X)<0.002 and math.abs(a.Max.Y-b.Max.Y)<0.002
    elseif ta=="CFrame" then return a==b
    elseif ta=="EnumItem" then return a==b
    elseif ta=="BrickColor" then return a.Number==b.Number
    elseif ta=="NumberRange" then return math.abs(a.Min-b.Min)<0.002 and math.abs(a.Max-b.Max)<0.002
    elseif ta=="Font" then return (a.Family or "")==(b.Family or "")
    elseif ta=="TweenInfo" then
        return math.abs(a.Time-b.Time)<0.002 and a.EasingStyle==b.EasingStyle
           and a.EasingDirection==b.EasingDirection and a.RepeatCount==b.RepeatCount
           and math.abs(a.DelayTime-b.DelayTime)<0.002 and a.Reverses==b.Reverses
    elseif ta=="ColorSequence" then
        if #a.Keypoints~=#b.Keypoints then return false end
        for i=1,#a.Keypoints do
            local ka,kb=a.Keypoints[i],b.Keypoints[i]
            if math.abs(ka.Time-kb.Time)>0.002 then return false end
            if math.abs(ka.Value.R-kb.Value.R)>0.002 then return false end
            if math.abs(ka.Value.G-kb.Value.G)>0.002 then return false end
            if math.abs(ka.Value.B-kb.Value.B)>0.002 then return false end
        end
        return true
    elseif ta=="NumberSequence" then
        if #a.Keypoints~=#b.Keypoints then return false end
        for i=1,#a.Keypoints do
            local ka,kb=a.Keypoints[i],b.Keypoints[i]
            if math.abs(ka.Time-kb.Time)>0.002 then return false end
            if math.abs(ka.Value-kb.Value)>0.002 then return false end
        end
        return true
    end
    return a==b
end

local function isDangerousPath(target)
    if not target or typeof(target) ~= "Instance" then return nil end
    if target == game:GetService("CoreGui") then return "CoreGui" end
    if target == game:GetService("StarterGui") then return "StarterGui" end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if target == pg then return "PlayerGui" end
    return nil
end

local classPropsCache = {}
local function tryGetProps(inst)
    local className = inst.ClassName
    if classPropsCache[className] ~= nil then
        return classPropsCache[className]
    end
    local result = nil
    pcall(function() if type(getprops)=="function" then result = getprops(inst) end end)
    if not result then
        pcall(function()
            if debug and type(debug.getproperties)=="function" then
                result = debug.getproperties(inst)
            end
        end)
    end
    if not result then
        pcall(function() if type(get_properties)=="function" then result = get_properties(inst) end end)
    end
    if not result then
        pcall(function() if type(getproperties)=="function" then result = getproperties(inst) end end)
    end
    if result and type(result)=="table" then
        local names = {}
        if #result > 0 then
            for _, v in ipairs(result) do
                if type(v)=="string" then names[#names+1]=v end
            end
        end
        if #names == 0 then
            for k, v in pairs(result) do
                if type(k)=="string" then names[#names+1]=k
                elseif type(v)=="string" then names[#names+1]=v end
            end
        end
        if #names>0 then
            classPropsCache[className] = names
            return names
        end
    end
    classPropsCache[className] = false
    return nil
end

local defaultCache = {}

local function getDefaults(className)
    if defaultCache[className] then return defaultCache[className] end
    local defaults = {}
    local readOnly = {}
    local ok, test = pcall(Instance.new, className)
    if not ok or not test then
        defaultCache[className] = {defaults=defaults, readOnly=readOnly}
        return defaults, readOnly
    end
    local tempFolder = Instance.new("Folder")
    tempFolder.Name = "_uir_temp_" .. math.random(100000, 999999)
    tempFolder.Parent = workspace
    test.Parent = tempFolder

    local propNames = tryGetProps(test) or {}
    local allProps = {}
    local seen = {}
    for _, p in ipairs(propNames) do
        if not seen[p] then seen[p]=true; allProps[#allProps+1]=p end
    end
    for _, p in ipairs(FallbackProperties) do
        if not seen[p] then seen[p]=true; allProps[#allProps+1]=p end
    end

    for _, propName in ipairs(allProps) do
        if not SkipProps[propName] and propName~="Name" then
            local okRead, val = pcall(function() return test[propName] end)
            if okRead and val~=nil then
                defaults[propName] = val
                if not KnownReadOnly[propName] then
                    local okWrite = pcall(function() test[propName] = val end)
                    if not okWrite then
                        local tv = typeof(val)
                        local safeVal = nil
                        if tv=="number" then safeVal = 0
                        elseif tv=="string" then safeVal = ""
                        elseif tv=="boolean" then safeVal = false
                        elseif tv=="Color3" then safeVal = Color3.new(0,0,0)
                        elseif tv=="UDim" then safeVal = UDim.new(0,0)
                        elseif tv=="UDim2" then safeVal = UDim2.new(0,0,0,0)
                        elseif tv=="Vector2" then safeVal = Vector2.new(0,0)
                        elseif tv=="Vector3" then safeVal = Vector3.new(0,0,0)
                        elseif tv=="EnumItem" then safeVal = val
                        elseif tv=="Font" then safeVal = val
                        elseif tv=="BrickColor" then safeVal = BrickColor.new(1)
                        elseif tv=="NumberRange" then safeVal = NumberRange.new(0,0)
                        end
                        if safeVal then
                            local okWrite2 = pcall(function() test[propName] = safeVal end)
                            if not okWrite2 then readOnly[propName] = true end
                        else
                            readOnly[propName] = true
                        end
                    end
                else
                    readOnly[propName] = true
                end
            end
        end
    end
    tempFolder:Destroy()
    defaultCache[className] = {defaults=defaults, readOnly=readOnly}
    return defaults, readOnly
end

local function serializeValue(val)
    local t = typeof(val)
    if t=="Instance" then return nil end
    if t=="Color3" then
        return string.format("Color3.fromRGB(%d,%d,%d)", math.floor(val.R*255+0.5), math.floor(val.G*255+0.5), math.floor(val.B*255+0.5))
    elseif t=="UDim" then return string.format("UDim.new(%s,%s)", fmtNum(val.Scale), fmtNum(val.Offset))
    elseif t=="UDim2" then
        return string.format("UDim2.new(%s,%s,%s,%s)", fmtNum(val.X.Scale), fmtNum(val.X.Offset), fmtNum(val.Y.Scale), fmtNum(val.Y.Offset))
    elseif t=="Vector2" then return string.format("Vector2.new(%s,%s)", fmtNum(val.X), fmtNum(val.Y))
    elseif t=="Vector3" then return string.format("Vector3.new(%s,%s,%s)", fmtNum(val.X), fmtNum(val.Y), fmtNum(val.Z))
    elseif t=="Rect" then return string.format("Rect.new(%s,%s,%s,%s)", fmtNum(val.Min.X), fmtNum(val.Min.Y), fmtNum(val.Max.X), fmtNum(val.Max.Y))
    elseif t=="CFrame" then
        local x,y,z=val:components()
        local rx,ry,rz=val:ToEulerAnglesXYZ()
        if math.abs(rx)<0.001 and math.abs(ry)<0.001 and math.abs(rz)<0.001 then
            return string.format("CFrame.new(%s,%s,%s)", fmtNum(x), fmtNum(y), fmtNum(z))
        else
            return string.format("CFrame.new(%s,%s,%s)*CFrame.Angles(%s,%s,%s)", fmtNum(x), fmtNum(y), fmtNum(z), fmtNum(rx), fmtNum(ry), fmtNum(rz))
        end
    elseif t=="EnumItem" then return tostring(val)
    elseif t=="boolean" then return tostring(val)
    elseif t=="number" then return fmtNum(val)
    elseif t=="string" then return fmtStr(val)
    elseif t=="Font" then
        local f = val.Family or ""
        local w = tostring(val.Weight or Enum.FontWeight.Regular)
        local s = tostring(val.Style or Enum.FontStyle.Normal)
        return string.format('Font.new(%s,%s,%s)', fmtStr(f), w, s)
    elseif t=="BrickColor" then return string.format("BrickColor.new(%d)", val.Number)
    elseif t=="NumberRange" then return string.format("NumberRange.new(%s,%s)", fmtNum(val.Min), fmtNum(val.Max))
    elseif t=="TweenInfo" then
        return string.format("TweenInfo.new(%s,%s,%s,%d,%s,%s)", fmtNum(val.Time), tostring(val.EasingStyle), tostring(val.EasingDirection), val.RepeatCount, fmtNum(val.DelayTime), tostring(val.Reverses))
    elseif t=="ColorSequence" then
        local kps = {}
        for _, kp in ipairs(val.Keypoints) do
            local c = kp.Value
            kps[#kps+1] = string.format("ColorSequenceKeypoint.new(%s,Color3.fromRGB(%d,%d,%d))", fmtNum(kp.Time), math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
        end
        return "ColorSequence.new({" .. table.concat(kps, ",") .. "})"
    elseif t=="NumberSequence" then
        local kps = {}
        for _, kp in ipairs(val.Keypoints) do
            kps[#kps+1] = string.format("NumberSequenceKeypoint.new(%s,%s,%s)", fmtNum(kp.Time), fmtNum(kp.Value), fmtNum(kp.Envelope))
        end
        return "NumberSequence.new({" .. table.concat(kps, ",") .. "})"
    elseif t=="nil" then return "nil"
    else return nil end
end

local function generateVarMaps(targets, skipScripts)
    local varMap = {}
    local usedNames = {}
    for _, target in ipairs(targets) do
        local function assign(inst)
            local baseName = sanitizeName(inst.Name)
            if baseName=="" or baseName=="unnamed" then baseName = inst.ClassName end
            local varName = baseName
            if usedNames[varName] then
                usedNames[varName] = usedNames[varName] + 1
                varName = baseName .. "_" .. usedNames[varName]
            else
                usedNames[varName] = 1
            end
            varMap[inst] = varName
            for _, child in ipairs(inst:GetChildren()) do
                local shouldSkip = skipScripts and (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript"))
                if not shouldSkip then assign(child) end
            end
        end
        assign(target.instance)
    end
    return varMap
end

local function countDescendants(inst, skipScripts)
    local count = 1
    for _, child in ipairs(inst:GetChildren()) do
        local shouldSkip = skipScripts and (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript"))
        if not shouldSkip then count = count + countDescendants(child, skipScripts) end
    end
    return count
end

local function generateCode(targets, options, onProgress, onComplete)
    task.spawn(function()
        local success, err = pcall(function()
            local varMap = generateVarMaps(targets, options.skipScripts)
            local code = {}
            local instanceCount = 0
            local propertyCount = 0
            local skippedReadOnly = 0
            local classCounts = {}

            local totalCount = 0
            for _, t in ipairs(targets) do
                totalCount = totalCount + countDescendants(t.instance, options.skipScripts)
            end

            local compact = options.compact
            local includeDefaults = options.includeDefaults

            local needsWrapping
            if #targets > 1 then
                needsWrapping = true
            else
                local root = targets[1].instance
                needsWrapping = not root:IsA("ScreenGui") and not root:IsA("Folder")
            end

            local wrapperFolderVar = "_uiWrapperFolder"
            local wrapperScreenGuiVar = "_uiWrapperScreenGui"

            if needsWrapping then
                totalCount = totalCount + 2
            end

            local returnVar = needsWrapping and wrapperFolderVar or varMap[targets[1].instance]

            if not compact then
                code[#code+1] = "-- ============================================================"
                code[#code+1] = "-- UI Replication Code"
                if #targets == 1 then
                    code[#code+1] = "-- Source: " .. targets[1].path
                else
                    code[#code+1] = "-- Sources:"
                    for i, t in ipairs(targets) do
                        code[#code+1] = string.format("--   %d. %s", i, t.path)
                    end
                end
                code[#code+1] = "-- Generated: " .. os.date("%Y-%m-%d %H:%M:%S")
                code[#code+1] = "--"
                if needsWrapping then
                    code[#code+1] = "-- Wrapped in: Folder > ScreenGui > content"
                    if #targets > 1 then
                        code[#code+1] = "-- (Multiple paths combined under one ScreenGui)"
                    end
                end
                if options.autoParent then
                    code[#code+1] = "-- Auto-parented to PlayerGui."
                end
                if includeDefaults then
                    code[#code+1] = "-- All properties included (even defaults)."
                end
                code[#code+1] = "-- ============================================================"
                code[#code+1] = ""
            end

            if needsWrapping then
                instanceCount = instanceCount + 2
                classCounts["Folder"] = (classCounts["Folder"] or 0) + 1
                classCounts["ScreenGui"] = (classCounts["ScreenGui"] or 0) + 1
                if onProgress then pcall(onProgress, instanceCount, totalCount) end
                code[#code+1] = string.format('local %s = Instance.new("Folder")', wrapperFolderVar)
                code[#code+1] = string.format('%s.Name = "UIReplication_Wrapper"', wrapperFolderVar)
                if not compact then code[#code+1] = "" end
                code[#code+1] = string.format('local %s = Instance.new("ScreenGui")', wrapperScreenGuiVar)
                code[#code+1] = string.format('%s.Name = "UIReplication_ScreenGui"', wrapperScreenGuiVar)
                code[#code+1] = string.format('%s.ResetOnSpawn = false', wrapperScreenGuiVar)
                code[#code+1] = string.format('%s.IgnoreGuiInset = true', wrapperScreenGuiVar)
                code[#code+1] = string.format('%s.DisplayOrder = 9999', wrapperScreenGuiVar)
                code[#code+1] = string.format('%s.Parent = %s', wrapperScreenGuiVar, wrapperFolderVar)
                if not compact then code[#code+1] = "" end
            end

            local lastYield = tick()

            local function process(inst, parentVar, instPath)
                instanceCount = instanceCount + 1
                classCounts[inst.ClassName] = (classCounts[inst.ClassName] or 0) + 1

                if tick() - lastYield > 0.05 then
                    if onProgress then pcall(onProgress, instanceCount, totalCount) end
                    task.wait()
                    lastYield = tick()
                end

                local varName = varMap[inst] or ("inst_" .. instanceCount)
                local className = inst.ClassName
                local instName = inst.Name

                local hasFontFace = false
                do
                    local okFF, val = pcall(function() return inst.FontFace end)
                    if okFF and typeof(val)=="Font" then hasFontFace = true end
                end

                if not compact then code[#code+1] = "-- " .. instPath end
                code[#code+1] = string.format('local %s = Instance.new("%s")', varName, className)
                code[#code+1] = string.format('%s.Name = %s', varName, fmtStr(instName))

                local cached = defaultCache[className]
                if not cached then
                    getDefaults(className)
                    cached = defaultCache[className]
                end
                local defaults = cached and cached.defaults or {}
                local readOnly = cached and cached.readOnly or {}

                local actualProps = classPropsCache[className] or {}
                local seen = {}

                local function processProperty(propName)
                    if SkipProps[propName] or propName=="Name" or seen[propName] then return end
                    seen[propName] = true
                    if propName=="Font" and hasFontFace then return end
                    if readOnly[propName] then
                        skippedReadOnly = skippedReadOnly + 1
                        return
                    end
                    local ok, val = pcall(function() return inst[propName] end)
                    if not ok or val==nil then return end
                    if typeof(val)=="Instance" then return end
                    if not includeDefaults then
                        local def = defaults[propName]
                        if def~=nil and valuesEqual(val, def) then return end
                    end
                    local serialized = serializeValue(val)
                    if not serialized or serialized=="nil" then return end
                    propertyCount = propertyCount + 1
                    code[#code+1] = string.format('%s.%s = %s', varName, propName, serialized)
                end

                for _, propName in ipairs(actualProps) do processProperty(propName) end
                for _, propName in ipairs(FallbackProperties) do processProperty(propName) end

                local attrs
                pcall(function() attrs = inst:GetAttributes() end)
                if attrs then
                    for attrName, attrVal in pairs(attrs) do
                        local serialized = serializeValue(attrVal)
                        if serialized and serialized~="nil" then
                            code[#code+1] = string.format('%s:SetAttribute(%s,%s)', varName, fmtStr(attrName), serialized)
                        end
                    end
                end

                if not compact then
                    local tags
                    pcall(function() tags = inst:GetTags() end)
                    if tags then
                        for _, tag in ipairs(tags) do
                            code[#code+1] = string.format('-- game:GetService("CollectionService"):AddTag(%s,%s)', varName, fmtStr(tag))
                        end
                    end
                end

                if parentVar then
                    code[#code+1] = string.format('%s.Parent = %s', varName, parentVar)
                end
                if not compact then code[#code+1] = "" end

                for _, child in ipairs(inst:GetChildren()) do
                    local shouldSkip = options.skipScripts and (child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ModuleScript"))
                    if not shouldSkip then
                        process(child, varName, instPath .. "." .. child.Name)
                    end
                end
            end

            for _, target in ipairs(targets) do
                local rootParentVar = needsWrapping and wrapperScreenGuiVar or nil
                if not compact and #targets > 1 then
                    code[#code+1] = "-- ====== Path: " .. target.path .. " ======"
                end
                process(target.instance, rootParentVar, target.instance.Name)
            end

            local parentTargetVar = needsWrapping and wrapperFolderVar or varMap[targets[1].instance]
            if options.autoParent then
                code[#code+1] = ""
                code[#code+1] = string.format('%s.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")', parentTargetVar)
            elseif not compact then
                code[#code+1] = ""
                code[#code+1] = string.format('-- %s.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")', parentTargetVar)
            end

            if not compact then
                code[#code+1] = ""
                code[#code+1] = "-- ============================================================"
                code[#code+1] = "-- Total instances: " .. instanceCount
                code[#code+1] = "-- Total properties: " .. propertyCount
                if skippedReadOnly > 0 then
                    code[#code+1] = "-- Skipped read-only: " .. skippedReadOnly
                end
                if needsWrapping then
                    code[#code+1] = "-- Wrapped in: " .. wrapperFolderVar .. " > " .. wrapperScreenGuiVar
                end
                if #targets > 1 then
                    code[#code+1] = "-- Paths combined: " .. #targets
                end
                local classList = {}
                for cn, count in pairs(classCounts) do
                    classList[#classList+1] = {name=cn, count=count}
                end
                table.sort(classList, function(a,b) return a.count > b.count end)
                if #classList > 0 then
                    code[#code+1] = "--"
                    code[#code+1] = "-- Class breakdown:"
                    for _, c in ipairs(classList) do
                        code[#code+1] = string.format("--   %s: %d", c.name, c.count)
                    end
                end
                code[#code+1] = "-- ============================================================"
            end

            local finalCode = table.concat(code, "\n")
            onComplete(finalCode, instanceCount, propertyCount, skippedReadOnly, returnVar, classCounts)
        end)

        if not success then
            print("[UIR] GENERATE ERROR: " .. tostring(err))
            onComplete("-- [GENERATION ERROR]\n-- " .. tostring(err), 0, 0, 0, nil, {})
        end
    end)
end

local function resolvePath(pathStr)
    pathStr = pathStr:gsub("^%s+",""):gsub("%s+$","")
    local loadFn = getLoadFn()
    if loadFn then
        local fn = loadFn("return " .. pathStr)
        if fn then
            local ok, result = pcall(fn)
            if ok and typeof(result)=="Instance" then return result end
        end
    end
    local current
    local remaining = pathStr
    if remaining:match("^game%.") then current=game; remaining=remaining:sub(6)
    elseif remaining:match("^workspace%.") then current=workspace; remaining=remaining:sub(11)
    elseif remaining=="game" then return game
    elseif remaining=="workspace" then return workspace
    else return nil end
    for part in remaining:gmatch("[^%.]+") do
        if not current then return nil end
        part = part:gsub('^%["(.-)"%]$','%1'):gsub("^%['(.-)'%]$","%1")
        local child = current:FindFirstChild(part)
        if child then current = child
        else
            local ok, prop = pcall(function() return current[part] end)
            if ok and typeof(prop)=="Instance" then current=prop else return nil end
        end
    end
    return current
end

local function getGuiParent()
    local parent = nil
    pcall(function()
        if type(gethui)=="function" then
            local hui = gethui()
            if hui and typeof(hui)=="Instance" then
                local t = Instance.new("Folder")
                t.Name = "UIR_Test_" .. math.random(100000,999999)
                t.Parent = hui
                t:Destroy()
                parent = hui
            end
        end
    end)
    if not parent then
        pcall(function()
            local t = Instance.new("Folder")
            t.Name = "UIR_Test_" .. math.random(100000,999999)
            t.Parent = CoreGui
            t:Destroy()
            parent = CoreGui
        end)
    end
    if not parent then
        parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    return parent
end

local function make(className, props, parent)
    local inst = Instance.new(className)
    for k,v in pairs(props) do
        if k~="Parent" then inst[k]=v end
    end
    if parent then inst.Parent=parent end
    return inst
end

local function addHover(btn, normalColor, hoverColor)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3=hoverColor end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=normalColor end)
end

local function safeSetText(guiObject, text)
    local ok = pcall(function() guiObject.Text = text end)
    if not ok then
        pcall(function() guiObject.Text = string.sub(text, 1, 10000) .. "\n\n-- [TRUNCATED — TextBox limit reached. Use Copy or Export.]" end)
    end
    return ok
end

local guiParent = getGuiParent()
local existing = guiParent:FindFirstChild("UIReplicator")
if existing then existing:Destroy() end

local screenGui = make("ScreenGui", {
    Name = "UIReplicator_" .. math.random(10000,99999),
    DisplayOrder = 9999, ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = true,
}, guiParent)

local mainFrame = make("Frame", {
    Name="MainFrame", Size=UDim2.new(0,DEFAULT_W,0,DEFAULT_H),
    Position=UDim2.new(0.5,-DEFAULT_W/2,0.5,-DEFAULT_H/2),
    BackgroundColor3=Themes.Dark.BG, BorderSizePixel=0,
    ClipsDescendants=true, Active=true,
}, screenGui)
make("UICorner", {CornerRadius=UDim.new(0,8)}, mainFrame)
make("UIStroke", {Color=Themes.Dark.Stroke,Thickness=1,Transparency=0.5}, mainFrame)

local titleBar = make("Frame", {
    Name="TitleBar", Size=UDim2.new(1,0,0,38),
    BackgroundColor3=Themes.Dark.TitleBar, BorderSizePixel=0,
}, mainFrame)

local collapseBtn = make("TextButton", {
    Size=UDim2.new(0,24,0,24),Position=UDim2.new(0,8,0.5,-12),
    BackgroundTransparency=1,Text="\u{25BC}",TextColor3=Themes.Dark.Subtle,
    Font=Enum.Font.GothamBold,TextSize=10,AutoButtonColor=false,
}, titleBar)

local titleLabel = make("TextLabel", {
    Size=UDim2.new(1,-160,1,0),Position=UDim2.new(0,40,0,0),
    BackgroundTransparency=1,Text="UI Replicator v8.1",TextColor3=Themes.Dark.Text,
    Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,
}, titleBar)

local countBadge = make("TextLabel", {
    Size=UDim2.new(0,0,0,20),Position=UDim2.new(0,175,0.5,-10),
    BackgroundColor3=Themes.Dark.Accent,BorderSizePixel=0,Text="",
    TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
    TextSize=10,Visible=false,AutomaticSize=Enum.AutomaticSize.X,
}, titleBar)
make("UICorner", {CornerRadius=UDim.new(0,10)}, countBadge)
make("UIPadding", {PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)}, countBadge)

local previewBadge = make("TextLabel", {
    Size=UDim2.new(0,0,0,20),Position=UDim2.new(0,175,0.5,-10),
    BackgroundColor3=Themes.Dark.Exec,BorderSizePixel=0,Text="",
    TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
    TextSize=9,Visible=false,AutomaticSize=Enum.AutomaticSize.X,ZIndex=3,
}, titleBar)
make("UICorner", {CornerRadius=UDim.new(0,10)}, previewBadge)
make("UIPadding", {PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)}, previewBadge)

local themeBtn = make("TextButton", {
    Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-96,0.5,-12),
    BackgroundTransparency=1,Text="\u{263D}",TextColor3=Themes.Dark.Subtle,
    Font=Enum.Font.GothamBold,TextSize=14,AutoButtonColor=false,
}, titleBar)

local maximizeBtn = make("TextButton", {
    Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-64,0.5,-12),
    BackgroundTransparency=1,Text="\u{25A1}",TextColor3=Themes.Dark.Subtle,
    Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=false,
}, titleBar)

local closeBtn = make("TextButton", {
    Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-32,0.5,-12),
    BackgroundColor3=Themes.Dark.Clear,BorderSizePixel=0,Text="X",
    TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
    TextSize=12,AutoButtonColor=true,
}, titleBar)
make("UICorner", {CornerRadius=UDim.new(0,4)}, closeBtn)

make("Frame", {
    Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,0),
    BackgroundColor3=Themes.Dark.Sep,BorderSizePixel=0,
}, titleBar)

local inputFrame = make("Frame", {
    Size=UDim2.new(1,-24,0,36),Position=UDim2.new(0,12,0,46),
    BackgroundColor3=Themes.Dark.Input,BorderSizePixel=0,
}, mainFrame)
make("UICorner", {CornerRadius=UDim.new(0,6)}, inputFrame)

local pathBox = make("TextBox", {
    Size=UDim2.new(1,-192,1,-8),Position=UDim2.new(0,8,0,4),
    BackgroundColor3=Themes.Dark.InputDark,BorderSizePixel=0,
    PlaceholderText="put path  (e.g. game.CoreGui.UiFolder)",
    PlaceholderColor3=Themes.Dark.Subtle,Text="",TextColor3=Themes.Dark.Text,
    Font=Enum.Font.Code,TextSize=13,ClearTextOnFocus=false,
    TextXAlignment=Enum.TextXAlignment.Left,
}, inputFrame)
make("UICorner", {CornerRadius=UDim.new(0,4)}, pathBox)

local addPathBtn = make("TextButton", {
    Size=UDim2.new(0,32,1,-8),Position=UDim2.new(1,-180,0,4),
    BackgroundColor3=Themes.Dark.InputDark,BorderSizePixel=0,Text="+",
    TextColor3=Themes.Dark.Text,Font=Enum.Font.GothamBold,TextSize=16,AutoButtonColor=true,
}, inputFrame)
make("UICorner", {CornerRadius=UDim.new(0,4)}, addPathBtn)

local queueBadge = make("TextLabel", {
    Size=UDim2.new(0,16,0,16),Position=UDim2.new(1,-8,0,-8),
    BackgroundColor3=Themes.Dark.Accent,BorderSizePixel=0,Text="",
    TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
    TextSize=9,Visible=false,ZIndex=3,
}, addPathBtn)
make("UICorner", {CornerRadius=UDim.new(0,8)}, queueBadge)

local recentBtn = make("TextButton", {
    Size=UDim2.new(0,32,1,-8),Position=UDim2.new(1,-144,0,4),
    BackgroundColor3=Themes.Dark.InputDark,BorderSizePixel=0,Text="\u{25BE}",
    TextColor3=Themes.Dark.Subtle,Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=true,
}, inputFrame)
make("UICorner", {CornerRadius=UDim.new(0,4)}, recentBtn)

local generateBtn = make("TextButton", {
    Size=UDim2.new(0,100,1,-8),Position=UDim2.new(1,-108,0,4),
    BackgroundColor3=Themes.Dark.Accent,BorderSizePixel=0,Text="Generate",
    TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
    TextSize=13,AutoButtonColor=true,
}, inputFrame)
make("UICorner", {CornerRadius=UDim.new(0,4)}, generateBtn)

local warningLabel = make("TextLabel", {
    Size=UDim2.new(1,-24,0,0),Position=UDim2.new(0,12,0,84),
    BackgroundColor3=Themes.Dark.WarnBg,BorderSizePixel=0,Text="",
    TextColor3=Themes.Dark.Warn,Font=Enum.Font.Gotham,TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left,Visible=false,ZIndex=10,
}, mainFrame)
make("UICorner", {CornerRadius=UDim.new(0,4)}, warningLabel)
make("UIPadding", {PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8)}, warningLabel)

local quickPathsRow = make("Frame", {
    Size=UDim2.new(1,-24,0,24),Position=UDim2.new(0,12,0,88),BackgroundTransparency=1,
}, mainFrame)

local quickPathButtons = {}
local quickPaths = {
    {label="PlayerGui", path="game.Players.LocalPlayer.PlayerGui"},
    {label="CoreGui", path="game.CoreGui"},
    {label="StarterGui", path="game:GetService(\"StarterGui\")"},
}

for i, qp in ipairs(quickPaths) do
    local btn = make("TextButton", {
        Size=UDim2.new(0,80,0,22),Position=UDim2.new(0,(i-1)*84,0,1),
        BackgroundColor3=Themes.Dark.Input,BorderSizePixel=0,Text=qp.label,
        TextColor3=Themes.Dark.Subtle,Font=Enum.Font.Gotham,TextSize=11,AutoButtonColor=true,
    }, quickPathsRow)
    make("UICorner", {CornerRadius=UDim.new(0,4)}, btn)
    btn.MouseButton1Click:Connect(function() pathBox.Text = qp.path end)
    quickPathButtons[#quickPathButtons+1] = btn
end

local copyPathBtn = make("TextButton", {
    Size=UDim2.new(0,80,0,22),Position=UDim2.new(0,3*84,0,1),
    BackgroundColor3=Themes.Dark.Input,BorderSizePixel=0,Text="Copy Path",
    TextColor3=Themes.Dark.Subtle,Font=Enum.Font.Gotham,TextSize=11,AutoButtonColor=true,
}, quickPathsRow)
make("UICorner", {CornerRadius=UDim.new(0,4)}, copyPathBtn)
quickPathButtons[#quickPathButtons+1] = copyPathBtn

local optionsRow = make("Frame", {
    Size=UDim2.new(1,-24,0,22),Position=UDim2.new(0,12,0,118),BackgroundTransparency=1,
}, mainFrame)

local toggleCheckboxes = {}

local function makeToggle(parent, position, labelText, defaultOn)
    local container = make("Frame", {
        Size=UDim2.new(0,120,0,22),Position=position,BackgroundTransparency=1,
    }, parent)
    local box = make("TextButton", {
        Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,0,0.5,-8),
        BackgroundColor3=Themes.Dark.Input,BorderSizePixel=0,Text="",
        Font=Enum.Font.GothamBold,TextSize=11,TextColor3=Color3.fromRGB(255,255,255),AutoButtonColor=true,
    }, container)
    make("UICorner", {CornerRadius=UDim.new(0,3)}, box)
    local label = make("TextLabel", {
        Size=UDim2.new(1,-22,1,0),Position=UDim2.new(0,22,0,0),BackgroundTransparency=1,
        Text=labelText,TextColor3=Themes.Dark.Text,Font=Enum.Font.Gotham,
        TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,
    }, container)
    local state = defaultOn or false
    if state then
        box.BackgroundColor3 = Themes.Dark.Accent
        box.Text = "\u{2713}"
    end
    box.MouseButton1Click:Connect(function()
        state = not state
        if state then
            box.BackgroundColor3 = Themes[currentTheme].Accent
            box.Text = "\u{2713}"
        else
            box.BackgroundColor3 = Themes[currentTheme].Input
            box.Text = ""
        end
    end)
    box.MouseEnter:Connect(function()
        if not state then box.BackgroundColor3 = Themes[currentTheme].Hover end
    end)
    box.MouseLeave:Connect(function()
        if not state then box.BackgroundColor3 = Themes[currentTheme].Input end
    end)
    local getState = function() return state end
    toggleCheckboxes[#toggleCheckboxes+1] = {box=box, label=label, getState=getState}
    return getState
end

local getAutoParent     = makeToggle(optionsRow, UDim2.new(0,0,0,0),    "Auto-parent", true)
local getSkipScripts    = makeToggle(optionsRow, UDim2.new(0,125,0,0), "Skip Scripts", false)
local getCompact        = makeToggle(optionsRow, UDim2.new(0,250,0,0), "Compact", false)
local getIncludeDefaults = makeToggle(optionsRow, UDim2.new(0,375,0,0), "All Props", false)

local searchBox = make("TextBox", {
    Size=UDim2.new(1,-24,0,26),Position=UDim2.new(0,12,0,146),
    BackgroundColor3=Themes.Dark.Input,BorderSizePixel=0,
    PlaceholderText="Search output...",PlaceholderColor3=Themes.Dark.Subtle,
    Text="",TextColor3=Themes.Dark.Text,Font=Enum.Font.Code,TextSize=12,
    ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,
}, mainFrame)
make("UICorner", {CornerRadius=UDim.new(0,4)}, searchBox)
make("UIPadding", {PaddingLeft=UDim.new(0,8)}, searchBox)

local outputFrame = make("Frame", {
    Size=UDim2.new(1,-24,1,-238),Position=UDim2.new(0,12,0,178),
    BackgroundColor3=Themes.Dark.Output,BorderSizePixel=0,
}, mainFrame)
make("UICorner", {CornerRadius=UDim.new(0,6)}, outputFrame)

local outputScroll = make("ScrollingFrame", {
    Size=UDim2.new(1,-12,1,-12),Position=UDim2.new(0,6,0,6),BackgroundTransparency=1,
    BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=Themes.Dark.Scroll,
    ScrollBarImageTransparency=0.3,AutomaticCanvasSize=Enum.AutomaticSize.Y,
    CanvasSize=UDim2.new(0,0,0,0),ScrollingDirection=Enum.ScrollingDirection.Y,
}, outputFrame)

local outputBox = make("TextBox", {
    Size=UDim2.new(1,-4,0,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,
    Text="",TextColor3=Themes.Dark.OutText,Font=Enum.Font.Code,TextSize=12,
    MultiLine=true,ClearTextOnFocus=false,TextWrapped=true,RichText=false,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,
    AutomaticSize=Enum.AutomaticSize.Y,
}, outputScroll)

local progressBg = make("Frame", {
    Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,1,-3),
    BackgroundColor3=Color3.fromRGB(30,30,40),BorderSizePixel=0,Visible=false,ZIndex=5,
}, outputFrame)

local progressBar = make("Frame", {
    Size=UDim2.new(0,0,1,0),BackgroundColor3=Themes.Dark.Accent,BorderSizePixel=0,
}, progressBg)

local buttonFrame = make("Frame", {
    Size=UDim2.new(1,-24,0,32),Position=UDim2.new(0,12,1,-54),BackgroundTransparency=1,
}, mainFrame)

local copyBtn = make("TextButton", {
    Size=UDim2.new(0,84,0,28),Position=UDim2.new(1,-90,0,2),
    BackgroundColor3=Themes.Dark.Copy,BorderSizePixel=0,Text="Copy",
    TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
    TextSize=13,AutoButtonColor=true,
}, buttonFrame)
make("UICorner", {CornerRadius=UDim.new(0,4)}, copyBtn)

local clearBtn = make("TextButton", {
    Size=UDim2.new(0,84,0,28),Position=UDim2.new(1,-180,0,2),
    BackgroundColor3=Themes.Dark.Clear,BorderSizePixel=0,Text="Clear",
    TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
    TextSize=13,AutoButtonColor=true,
}, buttonFrame)
make("UICorner", {CornerRadius=UDim.new(0,4)}, clearBtn)

local exportBtn = nil
if hasWritefile() then
    exportBtn = make("TextButton", {
        Size=UDim2.new(0,84,0,28),Position=UDim2.new(1,-270,0,2),
        BackgroundColor3=Themes.Dark.Accent,BorderSizePixel=0,Text="Export",
        TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
        TextSize=13,AutoButtonColor=true,
    }, buttonFrame)
    make("UICorner", {CornerRadius=UDim.new(0,4)}, exportBtn)
end

local executeBtn = nil
if hasLoadstring() then
    executeBtn = make("TextButton", {
        Size=UDim2.new(0,84,0,28),Position=UDim2.new(1,-360,0,2),
        BackgroundColor3=Themes.Dark.Exec,BorderSizePixel=0,Text="Execute",
        TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
        TextSize=13,AutoButtonColor=true,
    }, buttonFrame)
    make("UICorner", {CornerRadius=UDim.new(0,4)}, executeBtn)
end

local statusLabel = make("TextLabel", {
    Size=UDim2.new(1,-24,0,16),Position=UDim2.new(0,12,1,-20),BackgroundTransparency=1,
    Text="Ready — enter a path and click Generate  (Ctrl+Enter)  |  + to queue paths",
    TextColor3=Themes.Dark.Subtle,Font=Enum.Font.Gotham,TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left,
}, mainFrame)

local resizeHandle = make("TextButton", {
    Size=UDim2.new(0,14,0,14),Position=UDim2.new(1,-14,1,-14),
    BackgroundColor3=Themes.Dark.Sep,BorderSizePixel=0,Text="",AutoButtonColor=true,
}, mainFrame)
make("UICorner", {CornerRadius=UDim.new(0,3)}, resizeHandle)
make("Frame", {Size=UDim2.new(0,6,0,2),Position=UDim2.new(0.5,-3,0.3,0),BackgroundColor3=Themes.Dark.Subtle,BorderSizePixel=0}, resizeHandle)
make("Frame", {Size=UDim2.new(0,6,0,2),Position=UDim2.new(0.5,-3,0.6,0),BackgroundColor3=Themes.Dark.Subtle,BorderSizePixel=0}, resizeHandle)

local recentDropdown = make("Frame", {
    Size=UDim2.new(0,320,0,0),Position=UDim2.new(0,12,0,84),
    BackgroundColor3=Themes.Dark.BG,BorderSizePixel=0,Visible=false,ZIndex=20,
}, mainFrame)
make("UICorner", {CornerRadius=UDim.new(0,6)}, recentDropdown)
make("UIStroke", {Color=Themes.Dark.Subtle,Thickness=1,Transparency=0.3}, recentDropdown)
make("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)}, recentDropdown)

local queuedDropdown = make("Frame", {
    Size=UDim2.new(0,340,0,0),Position=UDim2.new(0,12,0,84),
    BackgroundColor3=Themes.Dark.BG,BorderSizePixel=0,Visible=false,ZIndex=20,
}, mainFrame)
make("UICorner", {CornerRadius=UDim.new(0,6)}, queuedDropdown)
make("UIStroke", {Color=Themes.Dark.Accent,Thickness=1,Transparency=0.3}, queuedDropdown)
make("UIListLayout", {SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,2)}, queuedDropdown)

local function applyTheme(themeName)
    currentTheme = themeName
    local t = Themes[themeName]
    mainFrame.BackgroundColor3 = t.BG
    titleBar.BackgroundColor3 = t.TitleBar
    titleLabel.TextColor3 = t.Text
    collapseBtn.TextColor3 = t.Subtle
    maximizeBtn.TextColor3 = t.Subtle
    themeBtn.TextColor3 = t.Subtle
    countBadge.BackgroundColor3 = t.Accent
    previewBadge.BackgroundColor3 = t.Exec
    queueBadge.BackgroundColor3 = t.Accent
    inputFrame.BackgroundColor3 = t.Input
    pathBox.BackgroundColor3 = t.InputDark
    pathBox.TextColor3 = t.Text
    pathBox.PlaceholderColor3 = t.Subtle
    addPathBtn.BackgroundColor3 = t.InputDark
    addPathBtn.TextColor3 = t.Text
    recentBtn.BackgroundColor3 = t.InputDark
    recentBtn.TextColor3 = t.Subtle
    warningLabel.BackgroundColor3 = t.WarnBg
    warningLabel.TextColor3 = t.Warn
    searchBox.BackgroundColor3 = t.Input
    searchBox.TextColor3 = t.Text
    searchBox.PlaceholderColor3 = t.Subtle
    outputFrame.BackgroundColor3 = t.Output
    outputBox.TextColor3 = t.OutText
    outputScroll.ScrollBarImageColor3 = t.Scroll
    statusLabel.TextColor3 = t.Subtle
    resizeHandle.BackgroundColor3 = t.Sep
    recentDropdown.BackgroundColor3 = t.BG
    queuedDropdown.BackgroundColor3 = t.BG
    for _, btn in ipairs(quickPathButtons) do
        btn.BackgroundColor3 = t.Input
        btn.TextColor3 = t.Subtle
    end
    for _, tc in ipairs(toggleCheckboxes) do
        tc.label.TextColor3 = t.Text
        if not tc.getState() then tc.box.BackgroundColor3 = t.Input end
    end
    if executeBtn then executeBtn.BackgroundColor3 = t.Exec end
    themeBtn.Text = (themeName=="Dark") and "\u{263D}" or "\u{2600}"
end

themeBtn.MouseButton1Click:Connect(function()
    applyTheme(currentTheme=="Dark" and "Light" or "Dark")
end)

addHover(generateBtn, Themes.Dark.Accent, Themes.Dark.Hover)
addHover(copyBtn, Themes.Dark.Copy, Color3.fromRGB(87,201,149))
addHover(clearBtn, Themes.Dark.Clear, Color3.fromRGB(255,91,91))
addHover(closeBtn, Themes.Dark.Clear, Color3.fromRGB(255,91,91))
addHover(recentBtn, Themes.Dark.InputDark, Themes.Dark.Hover)
addHover(addPathBtn, Themes.Dark.InputDark, Themes.Dark.Hover)
if exportBtn then addHover(exportBtn, Themes.Dark.Accent, Themes.Dark.Hover) end
if executeBtn then addHover(executeBtn, Themes.Dark.Exec, Color3.fromRGB(240,190,60)) end
for _, btn in ipairs(quickPathButtons) do
    btn.MouseEnter:Connect(function() btn.BackgroundColor3=Themes[currentTheme].Hover end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=Themes[currentTheme].Input end)
end

local isCollapsed = false
local isMaximized = false
local normalSize = UDim2.new(0,DEFAULT_W,0,DEFAULT_H)
local normalPos = UDim2.new(0.5,-DEFAULT_W/2,0.5,-DEFAULT_H/2)
local contentElements = {inputFrame, quickPathsRow, optionsRow, searchBox, outputFrame, buttonFrame, statusLabel, resizeHandle}

local dragging = false
local dragStart = nil
local startPos = nil
titleBar.InputBegan:Connect(function(input)
    if (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) and not isMaximized then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        if not isCollapsed and not isMaximized then normalPos = mainFrame.Position end
    end
end)

local resizing = false
local resizeStart = nil
local resizeStartSize = nil
resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        resizing = true
        resizeStart = input.Position
        resizeStartSize = mainFrame.Size
        input.Changed:Connect(function()
            if input.UserInputState==Enum.UserInputState.End then resizing=false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing and input.UserInputType==Enum.UserInputType.MouseMovement then
        local delta = input.Position - resizeStart
        local newW = math.max(MIN_W, resizeStartSize.X.Offset+delta.X)
        local newH = math.max(MIN_H, resizeStartSize.Y.Offset+delta.Y)
        mainFrame.Size = UDim2.new(0,newW,0,newH)
        if not isCollapsed and not isMaximized then normalSize = mainFrame.Size end
    end
end)

collapseBtn.MouseButton1Click:Connect(function()
    isCollapsed = not isCollapsed
    if isCollapsed then
        if not isMaximized then normalSize = mainFrame.Size end
        local tween = TweenService:Create(mainFrame,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size=UDim2.new(mainFrame.Size.X.Scale, mainFrame.Size.X.Offset, 0, 38)})
        tween:Play()
        for _, elem in ipairs(contentElements) do elem.Visible = false end
        collapseBtn.Text = "\u{25B6}"
    else
        local targetSize = isMaximized and UDim2.new(1,-20,1,-20) or normalSize
        local tween = TweenService:Create(mainFrame,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Size=targetSize})
        tween:Play()
        for _, elem in ipairs(contentElements) do elem.Visible = true end
        collapseBtn.Text = "\u{25BC}"
    end
end)

maximizeBtn.MouseButton1Click:Connect(function()
    isMaximized = not isMaximized
    if isMaximized then
        mainFrame.Size = UDim2.new(1,-20,1,-20)
        mainFrame.Position = UDim2.new(0,10,0,10)
        resizeHandle.Visible = false
        maximizeBtn.Text = "\u{25A3}"
    else
        if isCollapsed then
            mainFrame.Size = UDim2.new(normalSize.X.Scale, normalSize.X.Offset, 0, 38)
        else
            mainFrame.Size = normalSize
            resizeHandle.Visible = true
        end
        mainFrame.Position = normalPos
        maximizeBtn.Text = "\u{25A1}"
    end
end)

local queuedPaths = {}
local needsConfirm = false

local function updateQueueBadge()
    if #queuedPaths > 0 then
        queueBadge.Text = tostring(#queuedPaths)
        queueBadge.Visible = true
    else
        queueBadge.Visible = false
    end
end

local function updateQueuedDropdown()
    for _, child in ipairs(queuedDropdown:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UICorner") and not child:IsA("UIStroke") then
            child:Destroy()
        end
    end
    make("TextLabel", {
        Size=UDim2.new(1,-12,0,24),BackgroundTransparency=1,
        Text="  Queued Paths (" .. #queuedPaths .. ")",
        TextColor3=Themes[currentTheme].Accent,Font=Enum.Font.GothamBold,
        TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=0,
    }, queuedDropdown)
    if #queuedPaths==0 then
        make("TextLabel", {
            Size=UDim2.new(1,-12,0,24),BackgroundTransparency=1,
            Text="  No paths queued. Type a path and click + to add.",
            TextColor3=Themes[currentTheme].Subtle,Font=Enum.Font.Gotham,
            TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1,TextWrapped=true,
        }, queuedDropdown)
        queuedDropdown.Size = UDim2.new(0,340,0,56)
        return
    end
    for i, path in ipairs(queuedPaths) do
        local entryFrame = make("Frame", {
            Size=UDim2.new(1,-8,0,26),BackgroundColor3=Themes[currentTheme].Input,
            BorderSizePixel=0,LayoutOrder=i+1,
        }, queuedDropdown)
        make("UICorner", {CornerRadius=UDim.new(0,4)}, entryFrame)
        make("TextLabel", {
            Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,6,0,0),
            BackgroundTransparency=1,Text="  " .. path,
            TextColor3=Themes[currentTheme].Text,Font=Enum.Font.Code,
            TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,
        }, entryFrame)
        local removeBtn = make("TextButton", {
            Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-26,0,2),
            BackgroundColor3=Themes[currentTheme].Clear,BorderSizePixel=0,
            Text="X",TextColor3=Color3.fromRGB(255,255,255),Font=Enum.Font.GothamBold,
            TextSize=10,AutoButtonColor=true,
        }, entryFrame)
        make("UICorner", {CornerRadius=UDim.new(0,4)}, removeBtn)
        local idx = i
        removeBtn.MouseButton1Click:Connect(function()
            table.remove(queuedPaths, idx)
            updateQueueBadge()
            updateQueuedDropdown()
        end)
    end
    local clearAllBtn = make("TextButton", {
        Size=UDim2.new(1,-8,0,24),BackgroundColor3=Themes[currentTheme].Clear,
        BorderSizePixel=0,Text="Clear All",TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.Gotham,TextSize=12,AutoButtonColor=true,LayoutOrder=1000,
    }, queuedDropdown)
    make("UICorner", {CornerRadius=UDim.new(0,4)}, clearAllBtn)
    clearAllBtn.MouseButton1Click:Connect(function()
        queuedPaths = {}
        updateQueueBadge()
        updateQueuedDropdown()
    end)
    queuedDropdown.Size = UDim2.new(0,340,0, #queuedPaths*28 + 28 + 28)
end

addPathBtn.MouseButton1Click:Connect(function()
    recentDropdown.Visible = false
    local pathStr = pathBox.Text:gsub("^%s+",""):gsub("%s+$","")
    if pathStr ~= "" and pathStr ~= pathBox.PlaceholderText then
        local alreadyQueued = false
        for _, p in ipairs(queuedPaths) do
            if p == pathStr then alreadyQueued = true break end
        end
        if not alreadyQueued then
            table.insert(queuedPaths, pathStr)
            pathBox.Text = ""
        end
    end
    updateQueueBadge()
    updateQueuedDropdown()
    queuedDropdown.Visible = not queuedDropdown.Visible
end)

local recentPaths = {}
local MAX_RECENT = 8

local function addRecentPath(path)
    for i = #recentPaths, 1, -1 do
        if recentPaths[i]==path then table.remove(recentPaths, i) end
    end
    table.insert(recentPaths, 1, path)
    while #recentPaths > MAX_RECENT then table.remove(recentPaths) end
end

local function updateRecentDropdown()
    for _, child in ipairs(recentDropdown:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UICorner") and not child:IsA("UIStroke") then
            child:Destroy()
        end
    end
    if #recentPaths==0 then
        make("TextLabel", {
            Size=UDim2.new(1,-12,0,28),BackgroundTransparency=1,
            Text="  No recent paths",TextColor3=Themes[currentTheme].Subtle,
            Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1,
        }, recentDropdown)
        recentDropdown.Size = UDim2.new(0,320,0,36)
        return
    end
    for i, path in ipairs(recentPaths) do
        local entry = make("TextButton", {
            Size=UDim2.new(1,-8,0,26),BackgroundColor3=Themes[currentTheme].Input,
            BorderSizePixel=0,Text="  " .. path,TextColor3=Themes[currentTheme].Text,
            Font=Enum.Font.Code,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,
            AutoButtonColor=true,LayoutOrder=i,
        }, recentDropdown)
        make("UICorner", {CornerRadius=UDim.new(0,4)}, entry)
        entry.MouseButton1Click:Connect(function()
            pathBox.Text = path
            recentDropdown.Visible = false
        end)
    end
    local clearRecent = make("TextButton", {
        Size=UDim2.new(1,-8,0,24),BackgroundColor3=Themes[currentTheme].Clear,
        BorderSizePixel=0,Text="Clear Recent",TextColor3=Color3.fromRGB(255,255,255),
        Font=Enum.Font.Gotham,TextSize=12,AutoButtonColor=true,LayoutOrder=100,
    }, recentDropdown)
    make("UICorner", {CornerRadius=UDim.new(0,4)}, clearRecent)
    clearRecent.MouseButton1Click:Connect(function()
        recentPaths = {}
        updateRecentDropdown()
    end)
    recentDropdown.Size = UDim2.new(0,320,0, #recentPaths*28 + 30)
end

recentBtn.MouseButton1Click:Connect(function()
    queuedDropdown.Visible = false
    recentDropdown.Visible = not recentDropdown.Visible
    if recentDropdown.Visible then updateRecentDropdown() end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        if recentDropdown.Visible then
            local mousePos = UserInputService:GetMouseLocation()
            local dp = recentDropdown.AbsolutePosition
            local ds = recentDropdown.AbsoluteSize
            if mousePos.X<dp.X or mousePos.X>dp.X+ds.X or mousePos.Y<dp.Y or mousePos.Y>dp.Y+ds.Y then
                recentDropdown.Visible = false
            end
        end
        if queuedDropdown.Visible then
            local mousePos = UserInputService:GetMouseLocation()
            local dp = queuedDropdown.AbsolutePosition
            local ds = queuedDropdown.AbsoluteSize
            if mousePos.X<dp.X or mousePos.X>dp.X+ds.X or mousePos.Y<dp.Y or mousePos.Y>dp.Y+ds.Y then
                queuedDropdown.Visible = false
            end
        end
    end
end)

local function showWarning(text)
    warningLabel.Text = "  \u{26A0} " .. text
    warningLabel.Size = UDim2.new(1,-24,0,20)
    warningLabel.Visible = true
    quickPathsRow.Position = UDim2.new(0,12,0,110)
    optionsRow.Position = UDim2.new(0,12,0,140)
    searchBox.Position = UDim2.new(0,12,0,168)
    outputFrame.Position = UDim2.new(0,12,0,200)
end

local function hideWarning()
    warningLabel.Visible = false
    warningLabel.Size = UDim2.new(1,-24,0,0)
    quickPathsRow.Position = UDim2.new(0,12,0,88)
    optionsRow.Position = UDim2.new(0,12,0,118)
    searchBox.Position = UDim2.new(0,12,0,146)
    outputFrame.Position = UDim2.new(0,12,0,178)
end

local generatedCode = ""
local isTextHidden = false
local lastReturnVar = nil
local lastClassCounts = nil
local searchTimer = nil

local function buildClassBreakdownStr(classCounts)
    if not classCounts then return "" end
    local classList = {}
    for cn, count in pairs(classCounts) do
        classList[#classList+1] = {name=cn, count=count}
    end
    table.sort(classList, function(a,b) return a.count > b.count end)
    local lines = {}
    for _, c in ipairs(classList) do
        lines[#lines+1] = string.format("  %s: %d", c.name, c.count)
    end
    return table.concat(lines, "\n")
end

local function applySearchFilter()
    local query = searchBox.Text
    if query=="" then
        if isTextHidden then
            local breakdown = buildClassBreakdownStr(lastClassCounts)
            safeSetText(outputBox, string.format(
                "[TEXT HIDDEN]\n\nThe text has been hidden since it's too long (%s characters).\nYou can Copy, Export, or Execute to get/use the full thing.\n\nClass Breakdown:\n%s",
                fmtNum(#generatedCode), breakdown
            ))
        else
            safeSetText(outputBox, generatedCode)
        end
    else
        local lines = {}
        for line in generatedCode:gmatch("[^\n]+") do
            if line:lower():find(query:lower(), 1, true) then
                lines[#lines+1] = line
            end
        end
        local result = table.concat(lines, "\n")
        if #result > MAX_DISPLAY_CHARS then
            safeSetText(outputBox, string.format(
                "[TEXT HIDDEN]\n\nSearch results exceed %s characters.\nYou can Copy or Export to get the full thing.",
                fmtNum(MAX_DISPLAY_CHARS)
            ))
        else
            safeSetText(outputBox, result)
        end
    end
    task.spawn(function()
        task.wait()
        outputScroll.CanvasPosition = Vector2.new(0, 0)
    end)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    if searchTimer then task.cancel(searchTimer) end
    searchTimer = task.delay(0.15, applySearchFilter)
end)

local previewInstance = nil

local function destroyPreview()
    if previewInstance then
        pcall(function() previewInstance:Destroy() end)
        previewInstance = nil
        previewBadge.Visible = false
    end
end

if executeBtn then
    executeBtn.MouseButton1Click:Connect(function()
        if generatedCode == "" then
            statusLabel.Text = "Nothing to execute"
            statusLabel.TextColor3 = Themes[currentTheme].Clear
            return
        end
        destroyPreview()
        local execCode = generatedCode .. "\n\nreturn " .. (lastReturnVar or "nil")
        local loadFn = getLoadFn()
        local fn = loadFn(execCode)
        if not fn then
            statusLabel.Text = "Failed to parse code for execution"
            statusLabel.TextColor3 = Themes[currentTheme].Clear
            return
        end
        local ok, result = pcall(fn)
        if not ok then
            statusLabel.Text = "Execution error: " .. tostring(result):sub(1, 60)
            statusLabel.TextColor3 = Themes[currentTheme].Clear
            return
        end
        if typeof(result) ~= "Instance" then
            statusLabel.Text = "Execution did not return an Instance"
            statusLabel.TextColor3 = Themes[currentTheme].Clear
            return
        end
        if not result.Parent then
            result.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
        previewInstance = result
        previewBadge.Text = "PREVIEW"
        previewBadge.Visible = true
        local origText = executeBtn.Text
        executeBtn.Text = "Re-run"
        statusLabel.Text = "Preview active — UI shown in PlayerGui. Click Re-run to refresh, Clear to stop."
        statusLabel.TextColor3 = Themes[currentTheme].Exec
        task.delay(1.5, function() executeBtn.Text = origText end)
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    destroyPreview()
    screenGui:Destroy()
end)

copyPathBtn.MouseButton1Click:Connect(function()
    local pathStr = pathBox.Text:gsub("^%s+",""):gsub("%s+$","")
    if pathStr=="" then
        statusLabel.Text = "Path is empty"
        statusLabel.TextColor3 = Themes[currentTheme].Clear
        return
    end
    local ok = setClipboard(pathStr)
    if ok then
        statusLabel.Text = "Path copied: " .. pathStr
        statusLabel.TextColor3 = Themes[currentTheme].Copy
    else
        statusLabel.Text = "Clipboard not supported"
        statusLabel.TextColor3 = Themes[currentTheme].Clear
    end
end)

local function doGenerate()
    local allPaths = {}
    for _, p in ipairs(queuedPaths) do allPaths[#allPaths+1] = p end
    local pathStr = pathBox.Text:gsub("^%s+",""):gsub("%s+$","")
    if pathStr ~= "" and pathStr ~= pathBox.PlaceholderText then
        local dup = false
        for _, p in ipairs(allPaths) do
            if p == pathStr then dup = true break end
        end
        if not dup then allPaths[#allPaths+1] = pathStr end
    end
    if #allPaths == 0 then
        statusLabel.Text = "Enter a path first"
        statusLabel.TextColor3 = Themes[currentTheme].Clear
        return
    end

    local targets = {}
    local failedPaths = {}
    for _, p in ipairs(allPaths) do
        local target = resolvePath(p)
        if target and typeof(target)=="Instance" then
            targets[#targets+1] = {instance=target, path=p}
        else
            failedPaths[#failedPaths+1] = p
        end
    end
    if #targets == 0 then
        statusLabel.Text = "No valid paths found"
        statusLabel.TextColor3 = Themes[currentTheme].Clear
        return
    end
    if #failedPaths > 0 then
        statusLabel.Text = string.format("Warning: %d path(s) failed, %d valid", #failedPaths, #targets)
        statusLabel.TextColor3 = Themes[currentTheme].Warn
    end

    local dangerousNames = {}
    for _, t in ipairs(targets) do
        local dangerName = isDangerousPath(t.instance)
        if dangerName then dangerousNames[#dangerousNames+1] = dangerName end
    end
    if #dangerousNames > 0 then
        if not needsConfirm then
            needsConfirm = true
            local names = table.concat(dangerousNames, ", ")
            showWarning(string.format("Grabbing entire %s may include system UIs and take a long time. Click Generate again to confirm.", names))
            statusLabel.Text = string.format("WARNING: Full %s detected. Click Generate again to confirm.", names)
            statusLabel.TextColor3 = Themes[currentTheme].Warn
            return
        else
            needsConfirm = false
            hideWarning()
        end
    end
    needsConfirm = false
    hideWarning()
    destroyPreview()

    for _, t in ipairs(targets) do addRecentPath(t.path) end

    local options = {
        skipScripts = getSkipScripts(),
        compact = getCompact(),
        autoParent = getAutoParent(),
        includeDefaults = getIncludeDefaults(),
    }

    progressBg.Visible = true
    progressBar.Size = UDim2.new(0,0,1,0)
    generateBtn.Text = "Working..."
    generateBtn.Active = false
    statusLabel.Text = "Generating from " .. #targets .. " path(s)..."
    statusLabel.TextColor3 = Themes[currentTheme].Subtle
    safeSetText(outputBox, "")
    searchBox.Text = ""
    isTextHidden = false

    generateCode(targets, options, function(current, total)
        local pct = total>0 and current/total or 0
        progressBar.Size = UDim2.new(pct, 0, 1, 0)
        statusLabel.Text = string.format("Processing %d / %d instances...", current, total)
    end, function(code, instCount, propCount, skippedRO, returnVar, classCounts)
        generatedCode = code
        lastReturnVar = returnVar
        lastClassCounts = classCounts
        local charCount = #code
        local lineCount = select(2, code:gsub("\n", "\n")) + 1

        progressBg.Visible = false
        generateBtn.Text = "Generate"
        generateBtn.Active = true
        countBadge.Text = tostring(instCount)
        countBadge.Visible = true

        if charCount > MAX_DISPLAY_CHARS then
            isTextHidden = true
            local breakdown = buildClassBreakdownStr(classCounts)
            safeSetText(outputBox, string.format(
                "[TEXT HIDDEN]\n\nThe text has been hidden since it's too long (%s characters).\nYou can Copy, Export, or Execute to get/use the full thing.\n\nInstances: %d\nProperties: %d\nSkipped read-only: %d\nLines: %s\nCharacters: %s\nPaths: %d\n\nClass Breakdown:\n%s",
                fmtNum(charCount), instCount, propCount, skippedRO or 0, fmtNum(lineCount), fmtNum(charCount), #targets, breakdown
            ))
            statusLabel.Text = string.format("Text hidden | %d instances | %s chars | Use Copy/Export/Execute", instCount, fmtNum(charCount))
            statusLabel.TextColor3 = Themes[currentTheme].Warn
        else
            isTextHidden = false
            local setOk = safeSetText(outputBox, code)
            if not setOk then
                isTextHidden = true
                safeSetText(outputBox, string.format(
                    "[TEXT HIDDEN]\n\nTextBox rejected the text (%s chars). This may exceed the internal TextBox limit.\nYou can Copy, Export, or Execute to get/use the full thing.\n\nInstances: %d\nProperties: %d",
                    fmtNum(charCount), instCount, propCount
                ))
                statusLabel.Text = string.format("Text hidden (TextBox limit) | %d instances | Use Copy/Export/Execute", instCount)
                statusLabel.TextColor3 = Themes[currentTheme].Warn
            else
                local skipStr = (skippedRO and skippedRO>0) and string.format(" | %d RO skipped", skippedRO) or ""
                local pathStr2 = #targets > 1 and string.format(" | %d paths", #targets) or ""
                statusLabel.Text = string.format("%d instances | %d properties%s%s | %s lines | %s chars", instCount, propCount, skipStr, pathStr2, fmtNum(lineCount), fmtNum(charCount))
                statusLabel.TextColor3 = Themes[currentTheme].Copy
            end
        end

        task.spawn(function()
            task.wait()
            outputScroll.CanvasPosition = Vector2.new(0, 0)
        end)
    end)
end

generateBtn.MouseButton1Click:Connect(doGenerate)

copyBtn.MouseButton1Click:Connect(function()
    if generatedCode=="" then
        statusLabel.Text = "Nothing to copy"
        statusLabel.TextColor3 = Themes[currentTheme].Clear
        return
    end
    local ok = setClipboard(generatedCode)
    if ok then
        local orig = copyBtn.Text
        copyBtn.Text = "Copied!"
        statusLabel.Text = "Copied to clipboard"
        statusLabel.TextColor3 = Themes[currentTheme].Copy
        task.delay(1.5, function() copyBtn.Text = orig end)
    else
        statusLabel.Text = "Clipboard not supported"
        statusLabel.TextColor3 = Themes[currentTheme].Clear
    end
end)

clearBtn.MouseButton1Click:Connect(function()
    generatedCode = ""
    safeSetText(outputBox, "")
    searchBox.Text = ""
    isTextHidden = false
    countBadge.Visible = false
    queuedPaths = {}
    updateQueueBadge()
    hideWarning()
    needsConfirm = false
    destroyPreview()
    statusLabel.Text = "Cleared"
    statusLabel.TextColor3 = Themes[currentTheme].Subtle
end)

if exportBtn then
    exportBtn.MouseButton1Click:Connect(function()
        if generatedCode=="" then
            statusLabel.Text = "Nothing to export"
            statusLabel.TextColor3 = Themes[currentTheme].Clear
            return
        end
        local filename = "UIReplication_" .. os.date("%Y%m%d_%H%M%S") .. ".txt"
        local ok = pcall(writefile, filename, generatedCode)
        if ok then
            statusLabel.Text = "Exported: " .. filename
            statusLabel.TextColor3 = Themes[currentTheme].Copy
            local orig = exportBtn.Text
            exportBtn.Text = "Saved!"
            task.delay(1.5, function() exportBtn.Text = orig end)
        else
            statusLabel.Text = "Export failed"
            statusLabel.TextColor3 = Themes[currentTheme].Clear
        end
    end)
end

pathBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local pathStr = pathBox.Text:gsub("^%s+",""):gsub("%s+$","")
            if pathStr ~= "" and pathStr ~= pathBox.PlaceholderText then
                local dup = false
                for _, p in ipairs(queuedPaths) do
                    if p == pathStr then dup = true break end
                end
                if not dup then
                    table.insert(queuedPaths, pathStr)
                    pathBox.Text = ""
                    updateQueueBadge()
                    statusLabel.Text = "Path queued (" .. #queuedPaths .. " total). Ctrl+Enter to add more, Enter to generate."
                    statusLabel.TextColor3 = Themes[currentTheme].Copy
                end
            end
        else
            doGenerate()
        end
    end
end)

searchBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then applySearchFilter() end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if input.KeyCode==Enum.KeyCode.Return then
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
            local focused = UserInputService:GetFocusedTextBox()
            if focused ~= outputBox and focused ~= searchBox then
                doGenerate()
            end
        end
    end
end)

applyTheme("Dark")
print("[UI Replicator v8.1] Loaded — Unicode-safe string escaping (pure ASCII output)")
print("[UI Replicator v8.1] Performance: class caching, time-based yielding, smart read-only detection")
print("[UI Replicator v8.1] Features: Multi-path, Execute/Preview, All Props toggle, themes, search, export")
