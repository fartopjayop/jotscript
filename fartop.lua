-- [[ FARTOP v4.1 - Compat ]] --

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local guiParent
pcall(function() guiParent = gethui() end)
if not guiParent then
    pcall(function() guiParent = game:GetService("CoreGui") end)
end
if not guiParent then
    guiParent = player:WaitForChild("PlayerGui")
end

local old = guiParent:FindFirstChild("FartopUI")
if old then old:Destroy() end

-- STATE
local SnapperEnabled = false
local SnapperKey = Enum.KeyCode.Q
local FOVEnabled = true
local FOVRadius = 300
local LockedHead = nil
local LockedPlayer = nil

local ESPEnabled = false
local ESPTeamCheck = false
local ESPBoxes = true
local ESPTracers = true
local ESPStore = {}

local FlyEnabled = false
local FlyKey = Enum.KeyCode.F
local FlySpeed = 60
local FlyConnection = nil
local FlyBV = nil
local FlyBG = nil
local lastFlyToggle = 0

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FartopUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = guiParent

local FOVGui = Instance.new("Frame")
FOVGui.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
FOVGui.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
FOVGui.BackgroundTransparency = 1
FOVGui.BorderSizePixel = 0
FOVGui.Parent = ScreenGui

local FOVCircle = Instance.new("Frame")
FOVCircle.Size = UDim2.new(1, 0, 1, 0)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Parent = FOVGui
local FC = Instance.new("UICorner")
FC.CornerRadius = UDim.new(1, 0)
FC.Parent = FOVCircle
local FS = Instance.new("UIStroke")
FS.Color = Color3.fromRGB(255, 255, 255)
FS.Thickness = 1.5
FS.Transparency = 0.35
FS.Parent = FOVCircle

local ESPContainer = Instance.new("Folder")
ESPContainer.Parent = ScreenGui
local TracerContainer = Instance.new("Folder")
TracerContainer.Parent = ScreenGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 400)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
local MC = Instance.new("UICorner")
MC.CornerRadius = UDim.new(0, 12)
MC.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 45)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
local TC = Instance.new("UICorner")
TC.CornerRadius = UDim.new(0, 12)
TC.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "FARTOP"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 20
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 8)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
local CC = Instance.new("UICorner")
CC.CornerRadius = UDim.new(0, 6)
CC.Parent = CloseBtn

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 34)
TabBar.Position = UDim2.new(0, 10, 0, 55)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame
local TL = Instance.new("UIListLayout")
TL.FillDirection = Enum.FillDirection.Horizontal
TL.Padding = UDim.new(0, 6)
TL.SortOrder = Enum.SortOrder.LayoutOrder
TL.Parent = TabBar

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -20, 1, -105)
ContentFrame.Position = UDim2.new(0, 10, 0, 95)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local pages = {}
local activePage = nil

local function makePage(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.Visible = false
    sf.Parent = ContentFrame
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 8)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Parent = sf
    ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, ll.AbsoluteContentSize.Y + 10)
    end)
    pages[name] = sf
    return sf
end

local function switchPage(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    activePage = name
    for _, tab in ipairs(TabBar:GetChildren()) do
        if tab:IsA("TextButton") then
            if tab.Name == name .. "Tab" then
                tab.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            else
                tab.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            end
        end
    end
end

local function makeTab(name, order)
    local btn = Instance.new("TextButton")
    btn.Name = name .. "Tab"
    btn.Size = UDim2.new(0, 125, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = TabBar
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    btn.MouseButton1Click:Connect(function() switchPage(name) end)
end

local function smoothClick(btn)
    local s = btn.Size
    TweenService:Create(btn, TweenInfo.new(0.08), {
        Size = UDim2.new(s.X.Scale, s.X.Offset - 6, s.Y.Scale, s.Y.Offset - 4)
    }):Play()
    task.wait(0.08)
    TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = s }):Play()
end

local function makeBtn(parent, text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -5, 0, 42)
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 15
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(50, 50, 50) }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }):Play()
    end)
    return b
end

local function createButton(parent, text, cb)
    local b = makeBtn(parent, text)
    b.MouseButton1Click:Connect(function()
        smoothClick(b)
        task.wait(0.1)
        if cb then pcall(cb) end
    end)
end

local function createToggle(parent, text, default, onChange)
    local state = default or false
    local b = makeBtn(parent, "")
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = b
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(0, 70, 1, 0)
    status.Position = UDim2.new(1, -80, 0, 0)
    status.BackgroundTransparency = 1
    status.Text = state and "On" or "Off"
    status.TextColor3 = state and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 14
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.Parent = b
    local function set(v)
        state = v
        status.Text = state and "On" or "Off"
        status.TextColor3 = state and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150)
        if onChange then pcall(onChange, state) end
    end
    b.MouseButton1Click:Connect(function()
        smoothClick(b)
        task.wait(0.1)
        set(not state)
    end)
    return { get = function() return state end, set = set }
end

local function createKeybind(parent, text, defaultKey, onBind)
    local current = defaultKey
    local listening = false
    local b = makeBtn(parent, "")
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -120, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 15
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = b
    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size = UDim2.new(0, 90, 1, 0)
    keyLbl.Position = UDim2.new(1, -100, 0, 0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text = "[" .. current.Name .. "]"
    keyLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyLbl.Font = Enum.Font.GothamBold
    keyLbl.TextSize = 14
    keyLbl.TextXAlignment = Enum.TextXAlignment.Right
    keyLbl.Parent = b
    b.MouseButton1Click:Connect(function()
        if listening then return end
        smoothClick(b)
        listening = true
        keyLbl.Text = "[...]"
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode
                keyLbl.Text = "[" .. current.Name .. "]"
                listening = false
                conn:Disconnect()
                if onBind then pcall(onBind, current) end
            end
        end)
    end)
    return { get = function() return current end }
end

local function createSlider(parent, text, min, max, default, onChange)
    local b = makeBtn(parent, "")
    b.Size = UDim2.new(1, -5, 0, 60)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -100, 0, 24)
    lbl.Position = UDim2.new(0, 14, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = b
    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 80, 0, 24)
    valLbl.Position = UDim2.new(1, -94, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 14
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = b
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -28, 0, 6)
    bar.Position = UDim2.new(0, 14, 0, 40)
    bar.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bar.BorderSizePixel = 0
    bar.Parent = b
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = bar
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fill
    local value = default
    local dragging = false
    local function updateFromX(x)
        local absX = bar.AbsolutePosition.X
        local absW = bar.AbsoluteSize.X
        local pct = math.clamp((x - absX) / absW, 0, 1)
        value = math.floor(min + (max - min) * pct)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valLbl.Text = tostring(value)
        if onChange then pcall(onChange, value) end
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return { get = function() return value end }
end

-- FOV / TARGET
local function isInFOV(screenPos)
    local center = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    return (screenPos - center).Magnitude <= FOVRadius
end

local function getFOVTarget()
    local bestHead, bestPlayer, bestDist = nil, nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen and screenPos.Z > 0 then
                    if isInFOV(Vector2.new(screenPos.X, screenPos.Y)) then
                        if screenPos.Z < bestDist then
                            bestDist = screenPos.Z
                            bestHead = head
                            bestPlayer = p
                        end
                    end
                end
            end
        end
    end
    return bestHead, bestPlayer
end

local function getClosestTarget()
    local bestHead, bestPlayer, bestDist = nil, nil, math.huge
    local myChar = player.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local origin = camera.CFrame.Position
    if myHRP then origin = myHRP.Position end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local head = p.Character:FindFirstChild("Head")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local d = (origin - head.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestHead = head
                    bestPlayer = p
                end
            end
        end
    end
    return bestHead, bestPlayer
end

RunService.RenderStepped:Connect(function()
    if LockedHead and LockedHead.Parent then
        local hum = LockedHead.Parent:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            LockedHead = nil
            LockedPlayer = nil
        else
            camera.CFrame = CFrame.new(camera.CFrame.Position, LockedHead.Position)
        end
    end
    FOVGui.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
    FOVGui.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
end)

-- ESP
local function createESPFor(plr)
    if plr == player then return end
    if ESPStore[plr] then ESPStore[plr]:Destroy() end
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = ESPContainer
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Parent = box
    local tracer = Instance.new("Frame")
    tracer.AnchorPoint = Vector2.new(0.5, 0)
    tracer.BorderSizePixel = 0
    tracer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tracer.Visible = false
    tracer.Parent = TracerContainer
    ESPStore[plr] = { box = box, tracer = tracer }
end

local function clearESPFor(plr)
    local e = ESPStore[plr]
    if e then
        if e.box then e.box:Destroy() end
        if e.tracer then e.tracer:Destroy() end
        ESPStore[plr] = nil
    end
end

local function isSameTeam(plr)
    if not plr.Team or not player.Team then return false end
    return plr.Team == player.Team
end

local function updateESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            if not ESPStore[p] then createESPFor(p) end
            local e = ESPStore[p]
            if e then
                local box = e.box
                local tracer = e.tracer
                local show = ESPEnabled
                if show and ESPTeamCheck and isSameTeam(p) then show = false end
                local char = p.Character
                local head = char and char:FindFirstChild("Head")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not show or not head or not hrp or not hum or hum.Health <= 0 then
                    box.Visible = false
                    if tracer then tracer.Visible = false end
                else
                    local headPos, headOn = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local footPos, footOn = camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    if not headOn or not footOn then
                        box.Visible = false
                        if tracer then tracer.Visible = false end
                    else
                        if ESPBoxes then
                            local height = math.abs(footPos.Y - headPos.Y)
                            local width = height * 0.55
                            box.Visible = true
                            box.Size = UDim2.new(0, width, 0, height)
                            box.Position = UDim2.new(0, headPos.X - width / 2, 0, headPos.Y)
                        else
                            box.Visible = false
                        end
                        if ESPTracers and tracer then
                            tracer.Visible = true
                            local startX = camera.ViewportSize.X / 2
                            local startY = camera.ViewportSize.Y
                            local endX = headPos.X
                            local endY = headPos.Y
                            local dx = endX - startX
                            local dy = endY - startY
                            local length = math.sqrt(dx * dx + dy * dy)
                            local angle = math.deg(math.atan2(dy, dx))
                            tracer.Size = UDim2.new(0, 1, 0, length)
                            tracer.Position = UDim2.new(0, startX, 0, startY)
                            tracer.Rotation = angle + 90
                        else
                            if tracer then tracer.Visible = false end
                        end
                    end
                end
            end
        end
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        createESPFor(p)
    end)
end)
Players.PlayerRemoving:Connect(function(p) clearESPFor(p) end)

RunService.RenderStepped:Connect(function()
    if ESPEnabled then updateESP() end
end)

-- FLY
local function enableFly()
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    FlyBV = Instance.new("BodyVelocity")
    FlyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    FlyBV.Velocity = Vector3.new(0, 0, 0)
    FlyBV.Parent = hrp
    FlyBG = Instance.new("BodyGyro")
    FlyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    FlyBG.P = 1000
    FlyBG.D = 50
    FlyBG.CFrame = hrp.CFrame
    FlyBG.Parent = hrp
    FlyConnection = RunService.RenderStepped:Connect(function()
        if not hrp or not hrp.Parent then return end
        local moveDir = Vector3.new(0, 0, 0)
        local cf = camera.CFrame
        local right = cf.RightVector
        local look = cf.LookVector
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + look end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - look end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit * FlySpeed
        end
        FlyBV.Velocity = moveDir
        FlyBG.CFrame = cf
    end)
end

local function disableFly()
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if FlyBV then FlyBV:Destroy(); FlyBV = nil end
    if FlyBG then FlyBG:Destroy(); FlyBG = nil end
end

-- KEYBINDS
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode == SnapperKey then
        if not SnapperEnabled then return end
        if LockedHead then
            LockedHead = nil
            LockedPlayer = nil
        else
            local head, plr
            if FOVEnabled then
                head, plr = getFOVTarget()
            else
                head, plr = getClosestTarget()
            end
            if head then
                LockedHead = head
                LockedPlayer = plr
            end
        end
    elseif input.KeyCode == FlyKey then
        if tick() - lastFlyToggle < 0.3 then return end
        lastFlyToggle = tick()
        if FlyEnabled then
            FlyEnabled = false
            disableFly()
        else
            FlyEnabled = true
            enableFly()
        end
    end
end)

-- BUILD
makeTab("Combat", 1)
makeTab("Visuals", 2)
makeTab("Movement", 3)

local combatPage = makePage("Combat")
local visualsPage = makePage("Visuals")
local movementPage = makePage("Movement")

createToggle(combatPage, "Snapper", false, function(on)
    SnapperEnabled = on
    if not on then LockedHead = nil; LockedPlayer = nil end
end)
createKeybind(combatPage, "Snapper Keybind", SnapperKey, function(key) SnapperKey = key end)
createToggle(combatPage, "Use FOV Check", true, function(on) FOVEnabled = on end)
createToggle(combatPage, "Show FOV Circle", true, function(on)
    FOVGui.Visible = on
end)
createSlider(combatPage, "FOV Radius", 50, 800, FOVRadius, function(v) FOVRadius = v end)
createButton(combatPage, "Unlock Camera", function()
    LockedHead = nil
    LockedPlayer = nil
end)

createToggle(visualsPage, "ESP", false, function(on)
    ESPEnabled = on
    if not on then
        for _, p in ipairs(Players:GetPlayers()) do clearESPFor(p) end
    else
        for _, p in ipairs(Players:GetPlayers()) do createESPFor(p) end
    end
end)
createToggle(visualsPage, "Team Check", false, function(on) ESPTeamCheck = on end)
createToggle(visualsPage, "ESP Boxes", true, function(on) ESPBoxes = on end)
createToggle(visualsPage, "ESP Tracers", true, function(on) ESPTracers = on end)
createButton(visualsPage, "Toggle Fullbright", function()
    if Lighting.Brightness ~= 2 then
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 100000
    else
        Lighting.Brightness = 1
    end
end)

createSlider(movementPage, "WalkSpeed", 16, 200, 16, function(v)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = v end
end)
createSlider(movementPage, "JumpPower", 50, 500, 50, function(v)
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = v
    end
end)
createToggle(movementPage, "Noclip", false, function(on)
    if on then
        RunService.Stepped:Connect(function()
            local char = player.Character
            if char then
                for _, v in ipairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    end
end)
createToggle(movementPage, "Fly", false, function(on)
    FlyEnabled = on
    if on then enableFly() else disableFly() end
end)
createKeybind(movementPage, "Fly Keybind", FlyKey, function(key) FlyKey = key end)
createSlider(movementPage, "Fly Speed", 10, 300, FlySpeed, function(v) FlySpeed = v end)
createButton(movementPage, "Reset Character", function()
    local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)

-- DRAG
local dragging, dragInput, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local d = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    LockedHead = nil
    disableFly()
    ESPEnabled = false
    ScreenGui:Destroy()
end)

switchPage("Combat")
print("[Fartop] v4.1 loaded")
