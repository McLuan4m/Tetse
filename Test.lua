-- Main
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Criminality",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Ghost Store",
   LoadingSubtitle = "Thanks",
   ShowText = "Rayfield", -- for mobile users to unhide Rayfield, change if you'd like
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

   -- ScriptID = "sid_xxxxxxxxxxxx", -- Your Script ID from developer.sirius.menu — enables analytics, managed keys, and script hosting

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Big Hub"
   },

   Discord = {
      Enabled = false, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "noinvitelink", -- The Discord invite code, do not include Discord.gg/. E.g. Discord.gg/ABCD would be ABCD
      RememberJoins = true -- Set this to false to make them join the Discord every time they load it up
   },

   KeySystem = false, -- Set this to true to use our key system
   KeySettings = {
      Title = "Untitled",
      Subtitle = "Key System",
      Note = "No method of obtaining the key is provided", -- Use this to tell the user how to get a key
      FileName = "Key", -- It is recommended to use something unique, as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"Hello"} -- List of keys that the system will accept, can be RAW file links (pastebin, github, etc.) or simple strings ("hello", "key22")
   }
})

-- SCRIPTS
-- ESP
--[[
  ╔══════════════════════════════════════════════╗
  ║         E S P  M O D E R N O  v2.0          ║
  ║  Box • Corners • Bones • HP • Tracer • Dot  ║
  ╚══════════════════════════════════════════════╝
]]

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════════
--  ⚙  CONFIGURAÇÃO  —  edite aqui
-- ══════════════════════════════════════════════
local CFG = {
    -- [ FEATURES ] -----------------------------------------
    Box         = false,
    Bones       = false,
    Name        = false,
    Distance    = false,
    HealthBar   = false,
    HealthText  = false,   -- HP numérico ao lado da barra
    Tracer      = false,
    HeadDot     = false,
    TeamCheck   = false,    -- oculta aliados
    MaxDist     = 1000,    -- distância máxima (metros)

    -- [ ESTILO ] -------------------------------------------
    BoxMode     = "Corner", -- "Box" | "Corner"
    CornerRatio = 0.22,     -- comprimento dos cantos (0 – 0.5)
    TracerFrom  = "Top", -- "Bottom" | "Center" | "Top"

    -- [ CORES ] --------------------------------------------
    BoxColor    = Color3.fromRGB(255, 255, 255),
    BoneColor   = Color3.fromRGB(150, 190, 255),
    NameColor   = Color3.fromRGB(255, 255, 255),
    DistColor   = Color3.fromRGB(155, 155, 155),
    TracerColor = Color3.fromRGB(255, 255, 255),
    DotColor    = Color3.fromRGB(255,  60,  60),

    -- [ ESPESSURAS ] ---------------------------------------
    BoxThick    = 1.5,
    BoneThick   = 1.0,
    TracerThick = 1.0,
}

-- ══════════════════════════════════════════════
--  ESQUELETOS
-- ══════════════════════════════════════════════
local R6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},  {"Torso","Right Arm"},
    {"Torso","Left Leg"},  {"Torso","Right Leg"},
}
local R15 = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},   {"LeftUpperArm","LeftLowerArm"},   {"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},  {"RightUpperArm","RightLowerArm"}, {"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},   {"LeftUpperLeg","LeftLowerLeg"},   {"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},  {"RightUpperLeg","RightLowerLeg"}, {"RightLowerLeg","RightFoot"},
}

-- ══════════════════════════════════════════════
--  FÁBRICA DE DRAWINGS
-- ══════════════════════════════════════════════
local function Line(thick, col)
    local l        = Drawing.new("Line")
    l.Thickness    = thick or 1
    l.Color        = col   or Color3.new(1,1,1)
    l.Transparency = 1
    l.Visible      = false
    return l
end

local function Txt(size, col)
    local t        = Drawing.new("Text")
    t.Size         = size or 13
    t.Center       = true
    t.Outline      = true
    t.Font         = 2
    t.Color        = col or Color3.new(1,1,1)
    t.OutlineColor = Color3.new(0,0,0)
    t.Transparency = 1
    t.Visible      = false
    return t
end

local function Circle()
    local c        = Drawing.new("Circle")
    c.Thickness    = 0
    c.Filled       = true
    c.Transparency = 1
    c.Visible      = false
    return c
end

local function Sq()
    local s        = Drawing.new("Square")
    s.Thickness    = CFG.BoxThick
    s.Filled       = false
    s.Transparency = 1
    s.Visible      = false
    return s
end

local function CornerLines()
    local t = {}
    for i = 1, 8 do t[i] = Line(CFG.BoxThick) end
    return t
end

local function HPBar()
    local bg        = Line(4, Color3.new(0,0,0))
    bg.Transparency = 0.5   -- fundo semi-transparente
    return { BG = bg, Fill = Line(2) }
end

-- ══════════════════════════════════════════════
--  LIFECYCLE DOS OBJETOS ESP
-- ══════════════════════════════════════════════
local ESP = {}

local function Build(player)
    if ESP[player] then return end
    ESP[player] = {
        SQ     = Sq(),
        CB     = CornerLines(),
        Bones  = {},
        Name   = Txt(14, CFG.NameColor),
        Dist   = Txt(12, CFG.DistColor),
        HPTxt  = Txt(10),
        HP     = HPBar(),
        Tracer = Line(CFG.TracerThick, CFG.TracerColor),
        HDot   = Circle(),
    }
end

local function Destroy(player)
    local d = ESP[player]; if not d then return end
    d.SQ:Remove()
    for _, l in ipairs(d.CB)    do l:Remove() end
    for _, b in ipairs(d.Bones) do b:Remove() end
    d.Name:Remove(); d.Dist:Remove(); d.HPTxt:Remove()
    d.HP.BG:Remove(); d.HP.Fill:Remove()
    d.Tracer:Remove(); d.HDot:Remove()
    ESP[player] = nil
end

local function Hide(d)
    d.SQ.Visible = false
    for _, l in ipairs(d.CB)    do l.Visible = false end
    for _, b in ipairs(d.Bones) do b.Visible = false end
    d.Name.Visible   = false; d.Dist.Visible  = false; d.HPTxt.Visible = false
    d.HP.BG.Visible  = false; d.HP.Fill.Visible = false
    d.Tracer.Visible = false; d.HDot.Visible    = false
end

Players.PlayerAdded:Connect(Build)
Players.PlayerRemoving:Connect(Destroy)
for _, p in ipairs(Players:GetPlayers()) do Build(p) end

-- ══════════════════════════════════════════════
--  HELPERS VISUAIS
-- ══════════════════════════════════════════════

-- Gradiente verde → amarelo → vermelho
local function HpColor(r)
    if r > 0.5 then
        return Color3.fromRGB(math.floor(255 * (1 - r) * 2), 255, 0)
    else
        return Color3.fromRGB(255, math.floor(255 * r * 2), 0)
    end
end

-- Desenha as 8 linhas do corner box
local function DrawCornerBox(cb, x, y, w, h)
    local c = math.max(5, math.min(w, h) * CFG.CornerRatio)
    -- Top-Left
    cb[1].From = Vector2.new(x,   y);   cb[1].To = Vector2.new(x+c,   y)
    cb[2].From = Vector2.new(x,   y);   cb[2].To = Vector2.new(x,     y+c)
    -- Top-Right
    cb[3].From = Vector2.new(x+w, y);   cb[3].To = Vector2.new(x+w-c, y)
    cb[4].From = Vector2.new(x+w, y);   cb[4].To = Vector2.new(x+w,   y+c)
    -- Bottom-Left
    cb[5].From = Vector2.new(x,   y+h); cb[5].To = Vector2.new(x+c,   y+h)
    cb[6].From = Vector2.new(x,   y+h); cb[6].To = Vector2.new(x,     y+h-c)
    -- Bottom-Right
    cb[7].From = Vector2.new(x+w, y+h); cb[7].To = Vector2.new(x+w-c, y+h)
    cb[8].From = Vector2.new(x+w, y+h); cb[8].To = Vector2.new(x+w,   y+h-c)
    for _, l in ipairs(cb) do
        l.Color = CFG.BoxColor; l.Thickness = CFG.BoxThick; l.Visible = true
    end
end

-- ══════════════════════════════════════════════
--  RENDER LOOP
-- ══════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
    local camCF  = Camera.CFrame
    local vpSize = Camera.ViewportSize
    local midX   = vpSize.X * 0.5
    local tracY  = CFG.TracerFrom == "Bottom" and vpSize.Y
               or  CFG.TracerFrom == "Top"    and 0
               or  vpSize.Y * 0.5

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not ESP[player] then Build(player) end
        local d = ESP[player]

        -- ── Filtros de elegibilidade ──────────────
        if CFG.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
            Hide(d); continue
        end

        local char = player.Character
        if not char then Hide(d); continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not hrp then Hide(d); continue end

        local dist = (hrp.Position - camCF.Position).Magnitude
        if dist > CFG.MaxDist then Hide(d); continue end

        -- ── Projeção de tela ──────────────────────
        local cf, sz  = char:GetBoundingBox()
        local topV, onT = Camera:WorldToViewportPoint(cf.Position + Vector3.new(0, sz.Y*.5, 0))
        local botV, onB = Camera:WorldToViewportPoint(cf.Position - Vector3.new(0, sz.Y*.5, 0))

        -- Oculta se atrás da câmera ou completamente fora da tela
        if topV.Z <= 0 or (not onT and not onB) then Hide(d); continue end

        local sh = math.abs(topV.Y - botV.Y)
        if sh < 2 then Hide(d); continue end  -- personagem minúsculo, ignora

        local sw   = sh * (sz.X / sz.Y)
        local x, y = topV.X - sw*.5, topV.Y
        local w, h = sw, sh
        local hpR  = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

        -- ── Box ──────────────────────────────────
        if CFG.Box then
            if CFG.BoxMode == "Box" then
                d.SQ.Size     = Vector2.new(w, h)
                d.SQ.Position = Vector2.new(x, y)
                d.SQ.Color    = CFG.BoxColor
                d.SQ.Visible  = true
                for _, l in ipairs(d.CB) do l.Visible = false end
            else
                d.SQ.Visible = false
                DrawCornerBox(d.CB, x, y, w, h)
            end
        else
            d.SQ.Visible = false
            for _, l in ipairs(d.CB) do l.Visible = false end
        end

        -- ── Bones ────────────────────────────────
        if CFG.Bones then
            local list = hum.RigType == Enum.HumanoidRigType.R15 and R15 or R6
            while #d.Bones < #list do
                table.insert(d.Bones, Line(CFG.BoneThick, CFG.BoneColor))
            end
            for i, pair in ipairs(list) do
                local p1 = char:FindFirstChild(pair[1])
                local p2 = char:FindFirstChild(pair[2])
                local shown = false
                if p1 and p2 then
                    local s1, k1 = Camera:WorldToViewportPoint(p1.Position)
                    local s2, k2 = Camera:WorldToViewportPoint(p2.Position)
                    if k1 and k2 then
                        d.Bones[i].From    = Vector2.new(s1.X, s1.Y)
                        d.Bones[i].To      = Vector2.new(s2.X, s2.Y)
                        d.Bones[i].Color   = CFG.BoneColor
                        d.Bones[i].Visible = true
                        shown = true
                    end
                end
                if not shown then d.Bones[i].Visible = false end
            end
            -- oculta bones excedentes (ex: troca de R15 → R6)
            for i = #list + 1, #d.Bones do d.Bones[i].Visible = false end
        else
            for _, b in ipairs(d.Bones) do b.Visible = false end
        end

        -- ── Nome ─────────────────────────────────
        d.Name.Text     = player.DisplayName
        d.Name.Position = Vector2.new(x + w*.5, y - 18)
        d.Name.Color    = CFG.NameColor
        d.Name.Visible  = CFG.Name

        -- ── Distância ────────────────────────────
        d.Dist.Text     = string.format("[%d m]", math.floor(dist))
        d.Dist.Position = Vector2.new(x + w*.5, y + h + 3)
        d.Dist.Color    = CFG.DistColor
        d.Dist.Visible  = CFG.Distance

        -- ── Health Bar ───────────────────────────
        if CFG.HealthBar then
            local bx = x - 6
            -- fundo (largura 4 + transparência = borda visível)
            d.HP.BG.From    = Vector2.new(bx, y)
            d.HP.BG.To      = Vector2.new(bx, y + h)
            d.HP.BG.Visible = true
            -- preenchimento de baixo pra cima
            d.HP.Fill.Color   = HpColor(hpR)
            d.HP.Fill.From    = Vector2.new(bx, y + h)
            d.HP.Fill.To      = Vector2.new(bx, y + h - h * hpR)
            d.HP.Fill.Visible = true
            -- HP numérico (opcional)
            if CFG.HealthText then
                d.HPTxt.Text     = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                d.HPTxt.Position = Vector2.new(bx - 1, y + h*.5 - 5)
                d.HPTxt.Visible  = true
            else
                d.HPTxt.Visible = false
            end
        else
            d.HP.BG.Visible = false; d.HP.Fill.Visible = false; d.HPTxt.Visible = false
        end

        -- ── Tracer ───────────────────────────────
        if CFG.Tracer then
            d.Tracer.From    = Vector2.new(midX, tracY)
            d.Tracer.To      = Vector2.new(x + w*.5, y + h)
            d.Tracer.Color   = CFG.TracerColor
            d.Tracer.Visible = true
        else
            d.Tracer.Visible = false
        end

        -- ── Head Dot ─────────────────────────────
        if CFG.HeadDot then
            local head = char:FindFirstChild("Head")
            if head then
                local hs, ho = Camera:WorldToViewportPoint(head.Position)
                if ho then
                    d.HDot.Position = Vector2.new(hs.X, hs.Y)
                    d.HDot.Radius   = math.clamp(h / 16, 2, 6)
                    d.HDot.Color    = CFG.DotColor
                    d.HDot.Visible  = true
                else
                    d.HDot.Visible = false
                end
            else
                d.HDot.Visible = false
            end
        else
            d.HDot.Visible = false
        end
    end
end)

-- AIMBOT
--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// EXECUTOR FUNCTION
local mousemoverel = mousemoverel or mouse_move_relative or MouseMoveRelative
if not mousemoverel then
	warn("Executor não suporta mousemoverel")
end

--// VARIÁVEIS
local ToggleEnabled = false
local AimbotActive = false
local AimPartName = "Head"
local WallCheckEnabled = true
local SmoothValue = 6
local CircleRadius = 100

--// FOV CIRCLE
local AimCircle = Drawing.new("Circle")
AimCircle.Color = Color3.fromRGB(255,255,255)
AimCircle.Thickness = 2
AimCircle.Radius = CircleRadius
AimCircle.NumSides = 180
AimCircle.Filled = false
AimCircle.Transparency = 0.35
AimCircle.Visible = false

local AimCircleOutline = Drawing.new("Circle")
AimCircleOutline.Color = AimCircle.Color
AimCircleOutline.Thickness = 3
AimCircleOutline.Radius = CircleRadius + 1
AimCircleOutline.NumSides = AimCircle.NumSides
AimCircleOutline.Filled = false
AimCircleOutline.Transparency = 0.15
AimCircleOutline.Visible = false

local function UpdateCircle()
	AimCircleOutline.Position = AimCircle.Position
	AimCircleOutline.Radius = AimCircle.Radius + 1
	AimCircleOutline.Visible = AimCircle.Visible
end

----------------------------------------------------------------
-- WALLCHECK
----------------------------------------------------------------
local function HasLineOfSight(part)
	if not WallCheckEnabled then return true end

	local origin = Camera.CFrame.Position
	local direction = part.Position - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {LocalPlayer.Character}

	local result = workspace:Raycast(origin, direction, params)
	return result and result.Instance:IsDescendantOf(part.Parent)
end

----------------------------------------------------------------
-- GET CLOSEST TARGET
----------------------------------------------------------------
local function GetClosestTarget()
	local closestPart = nil
	local shortest = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer
			and player.Character
			and player.Character:FindFirstChild(AimPartName)
			and player.Character:FindFirstChild("Humanoid")
			and player.Character.Humanoid.Health > 0 then

			local part = player.Character[AimPartName]
			local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)

			if onScreen then
				local dist = (Vector2.new(screenPos.X, screenPos.Y) - AimCircle.Position).Magnitude
				if dist < AimCircle.Radius and dist < shortest then
					if HasLineOfSight(part) then
						shortest = dist
						closestPart = part
					end
				end
			end
		end
	end

	return closestPart
end

----------------------------------------------------------------
-- INPUT
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if ToggleEnabled and input.UserInputType == Enum.UserInputType.MouseButton2 then
		AimbotActive = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		AimbotActive = false
	end
end)

----------------------------------------------------------------
-- LOOP
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not ToggleEnabled then return end

	local center = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	AimCircle.Position = center
	UpdateCircle()

	if AimbotActive and mousemoverel then
		local targetPart = GetClosestTarget()
		if targetPart then
			local pos = Camera:WorldToViewportPoint(targetPart.Position)
			local delta = Vector2.new(pos.X, pos.Y) - center

			mousemoverel(
				delta.X / SmoothValue,
				delta.Y / SmoothValue
			)
		end
	end
end)

-- Pag1
local Tab = Window:CreateTab("Visuals", "users-round") -- Title, Image

local Section = Tab:CreateSection("Main")

local Toggle = Tab:CreateToggle({
   Name = "Box",
   CurrentValue = false,
   Flag = "Box",
   Callback = function(v)
    CFG.Box = v
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "Bones",
   CurrentValue = false,
   Flag = "Bones",
   Callback = function(v)
    CFG.Bones = v
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "Tracer",
   CurrentValue = false,
   Flag = "Tracer",
   Callback = function(v)
    CFG.Tracer = v
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "HeadDot",
   CurrentValue = false,
   Flag = "HeadDot",
   Callback = function(v)
    CFG.HeadDot = v
   end,
})

local Section = Tab:CreateSection("Others")

local Toggle = Tab:CreateToggle({
   Name = "Name",
   CurrentValue = false,
   Flag = "Name",
   Callback = function(v)
    CFG.Name = v
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "Distance",
   CurrentValue = false,
   Flag = "Distance",
   Callback = function(v)
    CFG.Distance = v
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "HealthBar",
   CurrentValue = false,
   Flag = "HealthBar",
   Callback = function(v)
    CFG.HealthBar = v
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "HealthText",
   CurrentValue = false,
   Flag = "HealthText",
   Callback = function(v)
    CFG.HealthText = v
   end,
})

local Section = Tab:CreateSection("Config")

local Slider = Tab:CreateSlider({
   Name = "MaxDistance",
   Range = {100, 1000},
   Increment = 10,
   Suffix = "Studs",
   CurrentValue = 500,
   Flag = "MaxDistance",
   Callback = function(v)
    CFG.MaxDist = v
   end,
})

local Toggle = Tab:CreateToggle({
   Name = "TeamCheck",
   CurrentValue = false,
   Flag = "TeamCheck",
   Callback = function(v)
    CFG.TeamCheck = v
   end,
})

local Dropdown = Tab:CreateDropdown({
   Name = "BoxMode",
   Options = {"Box", "Corner"},
   CurrentOption = {"Box"},
   MultipleOptions = false,
   Flag = "BoxMode",
   Callback = function(opt)
    CFG.BoxMode = opt[1]
   end,
})

local Dropdown = Tab:CreateDropdown({
   Name = "TracerFrom",
   Options = {"Bottom", "Center", "Top"},
   CurrentOption = {"Bottom"},
   MultipleOptions = false,
   Flag = "TracerFrom",
   Callback = function(opt)
    CFG.TracerFrom = opt[1]
   end,
})

-- Pag2
local Tab = Window:CreateTab("Aimbot", "crosshair") -- Title, Image

local Section = Tab:CreateSection("Main")

local Toggle = Tab:CreateToggle({
   Name = "Aimbot",
   CurrentValue = false,
   Flag = "Aimbot",
   Callback = function(v)
    ToggleEnabled = v

    AimCircle.Visible = v

    AimCircleOutline.Visible = v
   end,
})

local Slider = Tab:CreateSlider({
   Name = "FOV Size",
   Range = {50, 300},
   Increment = 10,
   Suffix = "px",
   CurrentValue = 100,
   Flag = "FOVSize",
   Callback = function(v)
    CircleRadius = v
    AimCircle.Radius = v
   end,
})

local Section = Tab:CreateSection("Others")

local Toggle = Tab:CreateToggle({
   Name = "WallCheck",
   CurrentValue = false,
   Flag = "WallCheck",
   Callback = function(v)
    WallCheckEnabled = v
   end,
})

local Slider = Tab:CreateSlider({
   Name = "Smooth",
   Range = {1, 20},
   Increment = 1,
   Suffix = "x",
   CurrentValue = 5,
   Flag = "Smooth",
   Callback = function(v)
    SmoothValue = v
   end,
})

local Dropdown = Tab:CreateDropdown({
   Name = "Aim Part",
   Options = {"Head", "UpperTorso"},
   CurrentOption = {"Head"},
   MultipleOptions = false,
   Flag = "AimPart",
   Callback = function(opt)
    AimPartName = opt[1]
   end,
})

local Section = Tab:CreateSection("Custom")

local Section = Tab:CreateSection("Color")

local ColorPicker = Tab:CreateColorPicker({
    Name = "FOV Color",
    Color = Color3.fromRGB(255,255,255),
    Flag = "FOVColor",
    Callback = function(v)
        AimCircle.Color = v
        AimCircleOutline.Color = v
    end
})