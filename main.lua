-- [[ ⚽ BOLSONARO HUB V8.0 - REACH REAL ]] --
-- Reach via firetouchinterest (funciona de verdade)
-- 5 nomes de bola: TPS, ESA, MRS, PRS, MPS

print("[BOLSONARO] V8.0 — REACH REAL carregando...")

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local Workspace        = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════
--  CONFIG
-- ═══════════════════════════════════════════════
local Config = {
    Debug = false,
    Bypass = { Enabled = true, SpoofWalkSpeed = true, SpoofJumpPower = true },
    Humanization = { Enabled = true, SpeedVariation = 0.05 },
    ESP = { Enabled = false, Color = Color3.fromRGB(255, 220, 0), Pulse = true, ShowBox = true, ShowTag = true },
    Speed = { Enabled = false, WalkSpeed = 28, JumpPower = 55, BaseSpeed = 16, BaseJump = 50 },
    FOV = { Value = 70, Base = 70 },
    Brightness = { Enabled = false, Value = 1.8 },

    -- 🎯 REACH REAL
    Reach = {
        Enabled       = false,
        Range         = 10,
        MagPower      = 1,
        ShowCircle    = false,
        CircleColor   = Color3.fromRGB(255, 215, 0),
        CircleTransp  = 0.85,
        AutoTouch     = true,   -- firetouchinterest automático
    },

    -- 🔒 FOLLOW TRAVADO
    FollowBall = {
        Enabled = false, GlueRadius = 2.5, GlueSpeed = 2,
        MaxBallSpeed = 4, Prediction = 0, Smoothness = 30,
        PauseOnInput = true, PauseDuration = 1.5,
    },

    AutoSprint = { Enabled = false, TriggerDist = 15 },
}

-- ═══════════════════════════════════════════════
--  ESTADO
-- ═══════════════════════════════════════════════
local Connections = {}
local UI_Elements = {}
local originalLighting = { Brightness = Lighting.Brightness, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
local destroyed = false
local espHighlight, espSelection, espBillboard, espBall = nil, nil, nil, nil
local followDir, manualPauseUntil, bypassActive, sprintActive = Vector3.zero, 0, false, false
local circlePart = nil
local mainFrame = nil
local cachedBalls = {}
local lastBallScan = 0

-- ═══════════════════════════════════════════════
--  HELPERS
-- ═══════════════════════════════════════════════
local function safeCall(f, ...) local ok, err = pcall(f, ...); if not ok then warn("[BOLSONARO]", err) end; return ok end
local function getSafeCharacter()
    local char = LocalPlayer.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp and hum.Health > 0 then return char end
    return nil
end

-- ═══════════════════════════════════════════════
--  DETECTOR DE BOLAS (5 NOMES!)
-- ═══════════════════════════════════════════════
local BALL_NAMES = { "TPS", "ESA", "MRS", "PRS", "MPS" }

local function isBallName(name)
    for _, n in ipairs(BALL_NAMES) do
        if name == n then return true end
    end
    return false
end

local function refreshBalls(force)
    local now = tick()
    if not force and now - lastBallScan < 2 then return end
    lastBallScan = now
    table.clear(cachedBalls)
    for _, v in ipairs(Workspace:GetDescendants()) do
        if isBallName(v.Name) and v:IsA("BasePart") and not v.Anchored then
            table.insert(cachedBalls, v)
        end
    end
    if Config.Debug then
        print("[BOLSONARO] 🎯 Bolas detectadas:", #cachedBalls)
        for _, b in ipairs(cachedBalls) do
            print("  →", b:GetFullName())
        end
    end
end

local function getClosestBall()
    refreshBalls(false)
    local char = getSafeCharacter(); if not char then return nil end
    local myPos = char.HumanoidRootPart.Position
    local best, bestDist = nil, math.huge
    for _, b in ipairs(cachedBalls) do
        if b and b.Parent then
            local d = (b.Position - myPos).Magnitude
            if d < bestDist then best, bestDist = b, d end
        end
    end
    return best
end

-- ═══════════════════════════════════════════════
--  🎯 REACH REAL — firetouchinterest
-- ═══════════════════════════════════════════════
-- Técnica: pega o TouchInterest da perna direita e força o evento
-- de toque entre a bola e a perna, mesmo de longe.

local function getLegTouchInterest()
    local char = getSafeCharacter(); if not char then return nil end
    -- R6 = "Right Leg" | R15 = "RightFoot" ou "RightLowerLeg"
    local leg = char:FindFirstChild("Right Leg")
        or char:FindFirstChild("RightFoot")
        or char:FindFirstChild("RightLowerLeg")
    if not leg then return nil end
    -- Acha o TouchInterest (criado pelo Roblox quando tem .Touched)
    for _, v in ipairs(leg:GetDescendants()) do
        if v.Name == "TouchInterest" then
            return v, leg
        end
    end
    return nil, leg
end

local function applyReach()
    if not Config.Reach.Enabled then return end
    if not Config.Reach.AutoTouch then return end

    local ti, leg = getLegTouchInterest()
    if not ti or not leg then return end

    local char = getSafeCharacter(); if not char then return end
    local myPos = char.HumanoidRootPart.Position
    local reach = Config.Reach.Range

    refreshBalls(false)

    for _, ball in ipairs(cachedBalls) do
        if ball and ball.Parent and ball:IsA("BasePart") then
            local dist = (ball.Position - leg.Position).Magnitude
            if dist < reach then
                -- 🔑 FORÇA O TOQUE
                pcall(function()
                    firetouchinterest(ball, ti.Parent, 0)  -- touch begin
                    firetouchinterest(ball, ti.Parent, 1)  -- touch end
                end)
                -- Impulso extra (magPower)
                if Config.Reach.MagPower > 0 then
                    pcall(function()
                        local dir = (myPos - ball.Position).Unit
                        ball.AssemblyLinearVelocity = ball.AssemblyLinearVelocity + dir * Config.Reach.MagPower
                    end)
                end
                break
            end
        end
    end
end

-- ═══════════════════════════════════════════════
--  CIRCLE VISUAL DO REACH
-- ═══════════════════════════════════════════════
local function updateReachCircle()
    if not Config.Reach.ShowCircle then
        if circlePart then circlePart:Destroy(); circlePart = nil end
        return
    end
    local char = getSafeCharacter()
    if not char then return end
    local hrp = char.HumanoidRootPart

    if not circlePart or not circlePart.Parent then
        circlePart = Instance.new("Part")
        circlePart.Shape = Enum.PartType.Ball
        circlePart.Anchored = true
        circlePart.CanCollide = false
        circlePart.Material = Enum.Material.Neon
        circlePart.Parent = Workspace
    end
    circlePart.Size = Vector3.new(Config.Reach.Range * 2, Config.Reach.Range * 2, Config.Reach.Range * 2)
    circlePart.Color = Config.Reach.CircleColor
    circlePart.Transparency = Config.Reach.CircleTransp
    circlePart.CFrame = CFrame.new(hrp.Position)
end

-- ═══════════════════════════════════════════════
--  ESP
-- ═══════════════════════════════════════════════
local function cleanupESP()
    if espHighlight then espHighlight:Destroy(); espHighlight = nil end
    if espSelection then espSelection:Destroy(); espSelection = nil end
    if espBillboard then espBillboard:Destroy(); espBillboard = nil end
    espBall = nil
end

local function updateESP()
    if not Config.ESP.Enabled then if espBall then cleanupESP() end return end
    local ball = getClosestBall()
    if not ball then if espBall then cleanupESP() end return end
    if espBall ~= ball then
        cleanupESP(); espBall = ball
        local hl = Instance.new("Highlight")
        hl.Adornee = ball
        hl.FillColor = Config.ESP.Color; hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.35; hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = ball; espHighlight = hl
        if Config.ESP.ShowBox then
            local sb = Instance.new("SelectionBox")
            sb.Adornee = ball; sb.Color3 = Config.ESP.Color
            sb.LineThickness = 0.15; sb.SurfaceTransparency = 0.7
            sb.SurfaceColor3 = Config.ESP.Color; sb.Parent = ball; espSelection = sb
        end
        if Config.ESP.ShowTag then
            local bb = Instance.new("BillboardGui")
            bb.Adornee = ball; bb.Size = UDim2.new(0, 100, 0, 30)
            bb.StudsOffset = Vector3.new(0, 3, 0); bb.AlwaysOnTop = true
            bb.Parent = ball
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1,0,1,0); label.BackgroundTransparency = 1
            label.Text = "⚽ " .. ball.Name; label.TextColor3 = Config.ESP.Color
            label.TextStrokeTransparency = 0; label.TextStrokeColor3 = Color3.new(0,0,0)
            label.TextScaled = true; label.Font = Enum.Font.GothamBold
            label.Parent = bb; espBillboard = bb
        end
    end
    if Config.ESP.Pulse and espHighlight then
        espHighlight.FillTransparency = 0.35 + math.sin(tick() * 4) * 0.2
    end
end

-- ═══════════════════════════════════════════════
--  SPEED / FOV / BRILHO
-- ═══════════════════════════════════════════════
local function getHumanSpeed()
    if not Config.Humanization.Enabled then return Config.Speed.WalkSpeed end
    local base = Config.Speed.WalkSpeed
    local v = base * Config.Humanization.SpeedVariation
    return base + (math.random() * v * 2) - v
end

local function applySpeed()
    local char = getSafeCharacter(); if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    if Config.Speed.Enabled then
        hum.WalkSpeed = getHumanSpeed(); hum.UseJumpPower = true; hum.JumpPower = Config.Speed.JumpPower
    else
        hum.WalkSpeed = Config.Speed.BaseSpeed; hum.UseJumpPower = true; hum.JumpPower = Config.Speed.BaseJump
    end
end
local function applyFOV()
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = Config.FOV.Value end
end
local function applyBrightness()
    if Config.Brightness.Enabled then
        Lighting.Brightness = Config.Brightness.Value
        Lighting.Ambient = Color3.fromRGB(120,120,120)
        Lighting.OutdoorAmbient = Color3.fromRGB(120,120,120)
    else
        Lighting.Brightness = originalLighting.Brightness
        Lighting.Ambient = originalLighting.Ambient
        Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    end
end

-- ═══════════════════════════════════════════════
--  AUTO FOLLOW (TRAVADO)
-- ═══════════════════════════════════════════════
local function updateFollowBall(dt)
    if not Config.FollowBall.Enabled then followDir = Vector3.zero; manualPauseUntil = 0; return end
    local char = getSafeCharacter(); if not char then return end
    local ball = getClosestBall(); if not ball then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not (hum and hrp) then return end

    if Config.FollowBall.PauseOnInput then
        local userInput = UserInputService:IsKeyDown(Enum.KeyCode.W)
            or UserInputService:IsKeyDown(Enum.KeyCode.A)
            or UserInputService:IsKeyDown(Enum.KeyCode.S)
            or UserInputService:IsKeyDown(Enum.KeyCode.D)
        if userInput then manualPauseUntil = tick() + Config.FollowBall.PauseDuration end
    end
    if tick() < manualPauseUntil then
        hum:Move(Vector3.zero); followDir = Vector3.zero; return
    end

    local ballPos = ball.Position
    local ballVel = ball.AssemblyLinearVelocity
    local myPos = hrp.Position
    local flatMe = Vector3.new(myPos.X, 0, myPos.Z)
    local flatBall = Vector3.new(ballPos.X, 0, ballPos.Z)
    local distReal = (flatMe - flatBall).Magnitude

    if distReal <= Config.FollowBall.GlueRadius then
        hum:Move(Vector3.zero); followDir = Vector3.zero
        if ballVel.Magnitude <= Config.FollowBall.MaxBallSpeed then
            local glueY = myPos.Y
            if ballPos.Y > myPos.Y + 2 then glueY = myPos.Y + math.min((ballPos.Y - myPos.Y) * 0.5, 3) end
            local newPos = Vector3.new(ballPos.X, glueY, ballPos.Z)
            local goalCF = CFrame.new(newPos, newPos + hrp.CFrame.LookVector)
            local alpha = math.clamp(dt * Config.FollowBall.GlueSpeed, 0, 1)
            hrp.CFrame = hrp.CFrame:Lerp(goalCF, alpha)
        end
        return
    end

    local predictedPos = ballPos
    if Config.FollowBall.Prediction > 0 and ballVel.Magnitude > 5 then
        predictedPos = ballPos + (ballVel.Unit * math.min(ballVel.Magnitude * Config.FollowBall.Prediction, 6))
    end
    local flatT = Vector3.new(predictedPos.X, 0, predictedPos.Z)
    local dirRaw = flatT - flatMe
    if dirRaw.Magnitude < 0.05 then hum:Move(Vector3.zero); followDir = Vector3.zero; return end
    local targetDir = dirRaw.Unit
    local smooth = math.clamp(dt * Config.FollowBall.Smoothness, 0, 1)
    followDir = followDir:Lerp(targetDir, smooth)
    hum:Move(followDir, false)
end

-- ═══════════════════════════════════════════════
--  AUTO-SPRINT / BYPASS
-- ═══════════════════════════════════════════════
local function updateAutoSprint()
    if not Config.AutoSprint.Enabled then if sprintActive then sprintActive = false end return end
    local char = getSafeCharacter(); if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local ball = getClosestBall(); if not ball then return end
    local dist = (char.HumanoidRootPart.Position - ball.Position).Magnitude
    local should = dist > Config.AutoSprint.TriggerDist and hum.MoveDirection.Magnitude > 0.1
    if should and not sprintActive then
        sprintActive = true; hum.WalkSpeed = Config.Speed.WalkSpeed * 1.5
    elseif not should and sprintActive then
        sprintActive = false; hum.WalkSpeed = getHumanSpeed()
    end
end

local function initBypass()
    if not Config.Bypass.Enabled or bypassActive then return end
    bypassActive = true
    if Config.Bypass.SpoofWalkSpeed then
        pcall(function()
            local mt = getrawmetatable(game)
            local oldIndex = mt.__index
            setreadonly(mt, false)
            mt.__index = newcclosure(function(self, key)
                if not checkcaller() and typeof(self) == "Instance"
                    and self:IsA("Humanoid") and LocalPlayer.Character
                    and self:IsDescendantOf(LocalPlayer.Character) then
                    if key == "WalkSpeed" and Config.Speed.Enabled and not sprintActive then return Config.Speed.BaseSpeed end
                    if key == "JumpPower" and Config.Bypass.SpoofJumpPower and Config.Speed.Enabled then return Config.Speed.BaseJump end
                end
                return oldIndex(self, key)
            end)
            setreadonly(mt, true)
        end)
    end
end

-- ═══════════════════════════════════════════════
--  UI
-- ═══════════════════════════════════════════════
local refreshUIRefs = {}

local function createUI()
    local parentGui
    local ok = pcall(function() parentGui = game:GetService("CoreGui") end)
    if not ok or not parentGui then parentGui = LocalPlayer:WaitForChild("PlayerGui") end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BolsonaroHub"; ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true; ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = parentGui
    table.insert(UI_Elements, ScreenGui)

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 620, 0, 400)
    Main.Position = UDim2.new(0.5, -310, 0.5, -200)
    Main.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
    Main.BorderSizePixel = 0; Main.Active = true; Main.Parent = ScreenGui
    mainFrame = Main
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = Main
    local ms = Instance.new("UIStroke"); ms.Color = Color3.fromRGB(60, 60, 70)
    ms.Thickness = 1; ms.Transparency = 0.3; ms.Parent = Main

    local ov = Instance.new("Frame")
    ov.Size = UDim2.new(1,0,1,0); ov.BackgroundColor3 = Color3.fromRGB(0,0,0)
    ov.BackgroundTransparency = 0.5; ov.BorderSizePixel = 0; ov.Parent = Main
    local ovc = Instance.new("UICorner"); ovc.CornerRadius = UDim.new(0,14); ovc.Parent = ov

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1,0,0,42); header.BackgroundColor3 = Color3.fromRGB(0,0,0)
    header.BackgroundTransparency = 0.4; header.BorderSizePixel = 0; header.Parent = Main
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0,14); hc.Parent = header
    local hm = Instance.new("Frame")
    hm.Size = UDim2.new(1,0,0,14); hm.Position = UDim2.new(0,0,1,-14)
    hm.BackgroundColor3 = Color3.fromRGB(0,0,0); hm.BackgroundTransparency = 0.4
    hm.BorderSizePixel = 0; hm.Parent = header

    local ll = Instance.new("TextLabel")
    ll.Size = UDim2.new(0,26,1,0); ll.Position = UDim2.new(0,12,0,0)
    ll.BackgroundTransparency = 1; ll.Text = "👑"; ll.TextSize = 18
    ll.Font = Enum.Font.GothamBold; ll.TextColor3 = Color3.fromRGB(255,255,255); ll.Parent = header

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(0,140,1,0); nl.Position = UDim2.new(0,38,0,0)
    nl.BackgroundTransparency = 1; nl.Text = "Bolsonaro.gg"
    nl.TextSize = 14; nl.Font = Enum.Font.GothamBold
    nl.TextColor3 = Color3.fromRGB(255,255,255); nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Parent = header

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0,60,0,22); badge.Position = UDim2.new(0,180,0,10)
    badge.BackgroundColor3 = Color3.fromRGB(40,40,45); badge.BackgroundTransparency = 0.3
    badge.BorderSizePixel = 0; badge.Parent = header
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,6); bc.Parent = badge
    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(1,0,1,0); vl.BackgroundTransparency = 1
    vl.Text = "v8.0"; vl.TextSize = 11
    vl.Font = Enum.Font.GothamBold; vl.TextColor3 = Color3.fromRGB(220,220,220); vl.Parent = badge

    local function makeWinBtn(text, xPos, onClick)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0,24,0,24); b.Position = UDim2.new(1,xPos,0,9)
        b.BackgroundTransparency = 1; b.Text = text; b.TextSize = 16
        b.Font = Enum.Font.GothamBold; b.TextColor3 = Color3.fromRGB(200,200,200)
        b.Parent = header
        if onClick then b.MouseButton1Click:Connect(onClick) end
        return b
    end
    makeWinBtn("−", -80, function() Main.Visible = false end)
    makeWinBtn("⛶", -52, function() end)
    makeWinBtn("×", -26, function() Main.Visible = false; print("[BOLSONARO] UI escondida. RSHIFT pra reabrir.") end)

    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0,140,1,-54); sidebar.Position = UDim2.new(0,8,0,46)
    sidebar.BackgroundTransparency = 1; sidebar.BorderSizePixel = 0; sidebar.Parent = Main
    local sl = Instance.new("UIListLayout")
    sl.Padding = UDim.new(0,4); sl.SortOrder = Enum.SortOrder.LayoutOrder; sl.Parent = sidebar

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1,-160,1,-54); content.Position = UDim2.new(0,152,0,46)
    content.BackgroundTransparency = 1; content.BorderSizePixel = 0; content.Parent = Main

    local pages = {}; local navButtons = {}

    local function addNav(name, icon, label, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,32); btn.BackgroundColor3 = Color3.fromRGB(0,0,0)
        btn.BackgroundTransparency = 1; btn.BorderSizePixel = 0; btn.Text = ""
        btn.AutoButtonColor = false; btn.LayoutOrder = order; btn.Parent = sidebar
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,6); c.Parent = btn
        local ic = Instance.new("TextLabel")
        ic.Size = UDim2.new(0,24,1,0); ic.Position = UDim2.new(0,8,0,0)
        ic.BackgroundTransparency = 1; ic.Text = icon; ic.TextSize = 14; ic.Parent = btn
        local lb = Instance.new("TextLabel")
        lb.Name = "Label"; lb.Size = UDim2.new(1,-34,1,0); lb.Position = UDim2.new(0,34,0,0)
        lb.BackgroundTransparency = 1; lb.Text = label; lb.TextSize = 12
        lb.Font = Enum.Font.GothamSemibold; lb.TextColor3 = Color3.fromRGB(180,180,180)
        lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = btn
        navButtons[name] = btn
    end

    local function setPage(name)
        for n, page in pairs(pages) do page.Visible = (n == name) end
        for n, btn in pairs(navButtons) do
            local lb = btn:FindFirstChild("Label")
            if n == name then
                btn.BackgroundColor3 = Color3.fromRGB(35,35,40); btn.BackgroundTransparency = 0.2
                if lb then lb.TextColor3 = Color3.fromRGB(255,255,255) end
            else
                btn.BackgroundColor3 = Color3.fromRGB(0,0,0); btn.BackgroundTransparency = 1
                if lb then lb.TextColor3 = Color3.fromRGB(180,180,180) end
            end
        end
    end

    addNav("Player", "👤", "Player", 1)
    addNav("Ball", "⚽", "Ball", 2)
    addNav("Reach", "🎯", "Reach", 3)
    addNav("Visual", "👁", "Visual", 4)
    addNav("Protect", "🛡", "Protect", 5)
    addNav("Others", "📋", "Others", 6)
    for n, btn in pairs(navButtons) do
        btn.MouseButton1Click:Connect(function() setPage(n) end)
    end

    local function newPage(name)
        local p = Instance.new("ScrollingFrame")
        p.Name = name .. "Page"; p.Size = UDim2.new(1,0,1,0)
        p.BackgroundTransparency = 1; p.BorderSizePixel = 0
        p.ScrollBarThickness = 2; p.ScrollBarImageColor3 = Color3.fromRGB(80,80,90)
        p.AutomaticCanvasSize = Enum.AutomaticSize.Y; p.CanvasSize = UDim2.new(0,0,0,0)
        p.Visible = false; p.Parent = content
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0,6); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = p
        pages[name] = p; return p
    end

    local function makeCard(parent, order)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1,-10,0,52); card.BackgroundColor3 = Color3.fromRGB(20,20,24)
        card.BackgroundTransparency = 0.35; card.BorderSizePixel = 0
        card.LayoutOrder = order; card.Parent = parent
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = card
        return card
    end

    local function makeToggle(parent, order, title, subtitle, cfg, key, onChange)
        local card = makeCard(parent, order)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1,-70,0,18); t.Position = UDim2.new(0,12,0,6)
        t.BackgroundTransparency = 1; t.Text = title; t.TextSize = 13
        t.Font = Enum.Font.GothamBold; t.TextColor3 = Color3.fromRGB(255,255,255)
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = card
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1,-70,0,14); s.Position = UDim2.new(0,12,0,26)
        s.BackgroundTransparency = 1; s.Text = subtitle or ""; s.TextSize = 10
        s.Font = Enum.Font.Gotham; s.TextColor3 = Color3.fromRGB(160,160,170)
        s.TextXAlignment = Enum.TextXAlignment.Left; s.Parent = card
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0,42,0,22); sw.Position = UDim2.new(1,-54,0.5,-11)
        sw.BackgroundColor3 = Color3.fromRGB(210,210,210); sw.BorderSizePixel = 0
        sw.Text = ""; sw.AutoButtonColor = false; sw.Parent = card
        local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(1,0); sc.Parent = sw
        local kn = Instance.new("Frame")
        kn.Size = UDim2.new(0,16,0,16); kn.Position = UDim2.new(0,3,0.5,-8)
        kn.BackgroundColor3 = Color3.fromRGB(255,255,255); kn.BorderSizePixel = 0; kn.Parent = sw
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = kn
        local function refresh()
            local on = cfg[key]
            if on then sw.BackgroundColor3 = Color3.fromRGB(75,145,230); kn.Position = UDim2.new(1,-19,0.5,-8)
            else sw.BackgroundColor3 = Color3.fromRGB(200,200,200); kn.Position = UDim2.new(0,3,0.5,-8) end
        end
        sw.MouseButton1Click:Connect(function()
            cfg[key] = not cfg[key]
            if onChange then safeCall(onChange, cfg[key]) end
            refresh()
        end)
        refresh(); table.insert(refreshUIRefs, refresh)
    end

    local function makeSlider(parent, order, title, subtitle, cfg, key, min, max, step, onChange)
        local card = makeCard(parent, order)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(0,160,0,18); t.Position = UDim2.new(0,12,0,6)
        t.BackgroundTransparency = 1; t.Text = title; t.TextSize = 13
        t.Font = Enum.Font.GothamBold; t.TextColor3 = Color3.fromRGB(255,255,255)
        t.TextXAlignment = Enum.TextXAlignment.Left; t.Parent = card
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(0,160,0,14); s.Position = UDim2.new(0,12,0,26)
        s.BackgroundTransparency = 1; s.Text = subtitle or ""; s.TextSize = 10
        s.Font = Enum.Font.Gotham; s.TextColor3 = Color3.fromRGB(160,160,170)
        s.TextXAlignment = Enum.TextXAlignment.Left; s.Parent = card
        local vL = Instance.new("TextLabel")
        vL.Size = UDim2.new(0,40,1,0); vL.Position = UDim2.new(1,-130,0,0)
        vL.BackgroundTransparency = 1; vL.Text = tostring(cfg[key])
        vL.TextSize = 12; vL.Font = Enum.Font.GothamBold
        vL.TextColor3 = Color3.fromRGB(220,220,220); vL.Parent = card
        local tr = Instance.new("Frame")
        tr.Size = UDim2.new(0,80,0,4); tr.Position = UDim2.new(1,-85,0.5,-2)
        tr.BackgroundColor3 = Color3.fromRGB(70,70,80); tr.BorderSizePixel = 0; tr.Parent = card
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(1,0); tc.Parent = tr
        local fl = Instance.new("Frame")
        local pct = math.clamp((cfg[key]-min)/(max-min), 0, 1)
        fl.Size = UDim2.new(pct,0,1,0); fl.BackgroundColor3 = Color3.fromRGB(75,145,230)
        fl.BorderSizePixel = 0; fl.Parent = tr
        local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1,0); fc.Parent = fl
        local kno = Instance.new("Frame")
        kno.Size = UDim2.new(0,12,0,12); kno.Position = UDim2.new(pct,-6,0.5,-6)
        kno.BackgroundColor3 = Color3.fromRGB(255,255,255); kno.BorderSizePixel = 0
        kno.ZIndex = 2; kno.Parent = tr
        local kc = Instance.new("UICorner"); kc.CornerRadius = UDim.new(1,0); kc.Parent = kno
        local function refresh()
            local rel = math.clamp((cfg[key]-min)/(max-min), 0, 1)
            fl.Size = UDim2.new(rel,0,1,0); kno.Position = UDim2.new(rel,-6,0.5,-6)
            vL.Text = tostring(cfg[key])
        end
        table.insert(refreshUIRefs, refresh)
        local dragging = false
        local function upd(inp)
            local rel = math.clamp((inp.Position.X - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1)
            local v = math.floor((min + (max-min) * rel) / step + 0.5) * step
            cfg[key] = v; refresh()
            if onChange then safeCall(onChange, v) end
        end
        tr.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; upd(i) end
        end)
        tr.InputChanged:Connect(function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i) end
        end)
        UserInputService.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    local function makeLabel(parent, order, text)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1,-10,0,20); l.BackgroundTransparency = 1
        l.Text = text; l.TextSize = 10; l.Font = Enum.Font.GothamBold
        l.TextColor3 = Color3.fromRGB(120,200,140)
        l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = order; l.Parent = parent
    end

    local pP = newPage("Player")
    makeLabel(pP, 1, "― MOVIMENTO")
    makeToggle(pP, 2, "Speed Boost", "WalkSpeed + JumpPower", Config.Speed, "Enabled", applySpeed)
    makeSlider(pP, 3, "Speed", "16-60", Config.Speed, "WalkSpeed", 16, 60, 1, applySpeed)
    makeSlider(pP, 4, "Jump Power", "50-150", Config.Speed, "JumpPower", 50, 150, 5, applySpeed)
    makeLabel(pP, 5, "― CÂMERA")
    makeSlider(pP, 6, "FOV Changer", "40-120", Config.FOV, "Value", 40, 120, 1, applyFOV)

    local pB = newPage("Ball")
    makeLabel(pB, 1, "― ESP")
    makeToggle(pB, 2, "ESP da Bola", "Highlight + caixa + texto", Config.ESP, "Enabled")
    makeToggle(pB, 3, "Piscar ESP", "Efeito pulsante", Config.ESP, "Pulse")
    makeToggle(pB, 4, "Mostrar Caixa", "SelectionBox", Config.ESP, "ShowBox")
    makeToggle(pB, 5, "Mostrar Texto", "Billboard", Config.ESP, "ShowTag")
    makeLabel(pB, 6, "― AUTO FOLLOW (TRAVADO)")
    makeToggle(pB, 7, "Auto Follow", "Segue a bola (grude)", Config.FollowBall, "Enabled")
    makeToggle(pB, 8, "Pausar em Input", "Pausa ao WASD", Config.FollowBall, "PauseOnInput")
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-5,0,60); info.BackgroundColor3 = Color3.fromRGB(20,30,20)
    info.BackgroundTransparency = 0.5; info.TextSize = 10
    info.Font = Enum.Font.Gotham; info.TextColor3 = Color3.fromRGB(120,200,140)
    info.Text = "✓ Raio: 2.5  •  Veloc: 2  •  Max: 4\n✓ Predição: 0  •  Suavidade: 30"
    info.TextXAlignment = Enum.TextXAlignment.Left; info.TextYAlignment = Enum.TextYAlignment.Top
    info.LayoutOrder = 9; info.Parent = pB
    local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,6); ic.Parent = info

    local pR = newPage("Reach")
    makeLabel(pR, 1, "― 🎯 REACH REAL (firetouchinterest)")
    makeToggle(pR, 2, "Reach", "Toca a bola de longe", Config.Reach, "Enabled")
    makeToggle(pR, 3, "Auto Touch", "Dispara firetouchinterest automático", Config.Reach, "AutoTouch")
    makeToggle(pR, 4, "Mostrar Circle", "Círculo visual do alcance", Config.Reach, "ShowCircle")
    makeSlider(pR, 5, "Alcance", "1-30 studs", Config.Reach, "Range", 1, 30, 1)
    makeSlider(pR, 6, "Força Magnética", "0-10 (empurra a bola)", Config.Reach, "MagPower", 0, 10, 0.5)
    makeSlider(pR, 7, "Transparência Circle", "0-1", Config.Reach, "CircleTransp", 0.3, 1, 0.05)

    local pV = newPage("Visual")
    makeLabel(pV, 1, "― ILUMINAÇÃO")
    makeToggle(pV, 2, "Luminosidade", "Brilho customizado", Config.Brightness, "Enabled", applyBrightness)
    makeSlider(pV, 3, "Brilho", "0-4", Config.Brightness, "Value", 0, 4, 0.1, applyBrightness)
    makeLabel(pV, 4, "― AUTO-SPRINT")
    makeToggle(pV, 5, "Auto Sprint", "Sprint quando longe", Config.AutoSprint, "Enabled")
    makeSlider(pV, 6, "Dist. Sprint", "5-40", Config.AutoSprint, "TriggerDist", 5, 40, 1)

    local pPr = newPage("Protect")
    makeLabel(pPr, 1, "― BYPASS")
    makeToggle(pPr, 2, "Bypass (Spoof)", "Engana WalkSpeed", Config.Bypass, "Enabled", function(state)
        if state then pcall(initBypass) end
    end)
    makeToggle(pPr, 3, "Humanização", "Variação natural", Config.Humanization, "Enabled")

    local pO = newPage("Others")
    makeLabel(pO, 1, "― SISTEMA")
    makeToggle(pO, 2, "Debug (Console)", "Logs no console (F9)", Config, "Debug")
    makeLabel(pO, 3, "― INFO")
    local infoL = Instance.new("TextLabel")
    infoL.Size = UDim2.new(1,-5,0,60); infoL.BackgroundColor3 = Color3.fromRGB(30,20,20)
    infoL.BackgroundTransparency = 0.5; infoL.TextSize = 10
    infoL.Font = Enum.Font.Gotham; infoL.TextColor3 = Color3.fromRGB(200,150,150)
    infoL.Text = "🎯 Reach usa firetouchinterest\nSe não funcionar: executor sem suporte\nTestado no Delta ✅"
    infoL.TextXAlignment = Enum.TextXAlignment.Left; infoL.TextYAlignment = Enum.TextYAlignment.Top
    infoL.LayoutOrder = 4; infoL.Parent = pO
    local icl = Instance.new("UICorner"); icl.CornerRadius = UDim.new(0,6); icl.Parent = infoL

    setPage("Reach")

    do
        local drag, ds, sp
        header.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                drag, ds, sp = true, i.Position, Main.Position
            end
        end)
        header.InputChanged:Connect(function(i)
            if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = i.Position - ds
                Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end)
        header.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then drag = false end
        end)
    end

    table.insert(Connections, UserInputService.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            Main.Visible = not Main.Visible
        elseif i.KeyCode == Enum.KeyCode.G then
            Config.Reach.Enabled = not Config.Reach.Enabled
            for _, r in ipairs(refreshUIRefs) do pcall(r) end
            print("[BOLSONARO] Reach:", Config.Reach.Enabled and "ON" or "OFF")
        elseif i.KeyCode == Enum.KeyCode.R then
            Config.FollowBall.Enabled = not Config.FollowBall.Enabled
            for _, r in ipairs(refreshUIRefs) do pcall(r) end
        elseif i.KeyCode == Enum.KeyCode.T then
            Config.ESP.Enabled = not Config.ESP.Enabled
            for _, r in ipairs(refreshUIRefs) do pcall(r) end
        end
    end))

    _G.BOLSONARO = _G.BOLSONARO or {}
    _G.BOLSONARO.showUI = function() if mainFrame then mainFrame.Visible = true end end
end

-- ═══════════════════════════════════════════════
--  LIMPEZA
-- ═══════════════════════════════════════════════
function destroyAll()
    if destroyed then return end
    destroyed = true
    cleanupESP(); applyBrightness()
    if circlePart then circlePart:Destroy(); circlePart = nil end
    local char = getSafeCharacter()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = Config.Speed.BaseSpeed end
    end
    if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = Config.FOV.Base end
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    Connections = {}
    for _, u in ipairs(UI_Elements) do pcall(function() u:Destroy() end) end
    UI_Elements = {}
    warn("[BOLSONARO] Hub desligado.")
end

-- ═══════════════════════════════════════════════
--  INIT
-- ═══════════════════════════════════════════════
pcall(createUI)
pcall(initBypass)

table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    pcall(updateESP)
    pcall(updateFollowBall, dt)
    pcall(applyReach)
    pcall(updateReachCircle)
end))

table.insert(Connections, RunService.Heartbeat:Connect(function()
    pcall(updateAutoSprint)
end))

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    pcall(applySpeed)
    pcall(applyFOV)
end))

print("[BOLSONARO] ═══════════════════════════════")
print("[BOLSONARO]  ✅ V8.0 — REACH REAL (firetouchinterest)")
print("[BOLSONARO]  RSHIFT=menu | G=reach | R=follow | T=esp")
print("[BOLSONARO] ═══════════════════════════════")
