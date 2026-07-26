local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- WINDOW ---------------------------
local Window = Library:CreateWindow({
	Title = "GHOST",
	Footer = "Ghost Store ┃ Test",
	Icon = "ghost",
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local DraggableLabel = Library:AddDraggableLabel("Obsidian demo")
DraggableLabel:SetVisible(true)

-- Example of dynamically-updating draggable label with common traits (fps and ping)
local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1;

    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter;
        FrameTimer = tick();
        FrameCounter = 0;
    end;

    DraggableLabel:SetText(('Obsidian demo | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()) -- Use LocalPlayer:GetNetworkPing() inside Studio
    ));
end);

-------------------------------- SCRIPTS --------------------------------
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-------------------------- ESP --------------------------

-- ─────────────────────────────────────────────────────────────
--  NATIVE CACHE
-- ─────────────────────────────────────────────────────────────
local V2new    = Vector2.new
local V3new    = Vector3.new
local C3new    = Color3.new
local C3rgb    = Color3.fromRGB
local mfloor   = math.floor
local mabs     = math.abs
local mclamp   = math.clamp
local mmin     = math.min
local mtan     = math.tan
local mrad     = math.rad
local huge     = math.huge
local tins     = table.insert
local tremove  = table.remove
local next     = next
local ipairs   = ipairs

-- ─────────────────────────────────────────────────────────────
--  CONFIGURATION
-- ─────────────────────────────────────────────────────────────
local Config = {
    Box         = false,
    Highlight   = false,
    Name        = false,
    Distance    = false,
    HealthBar   = false,
    Tracer      = false,
    Shadows     = false,         -- desligue p/ cortar ~metade dos drawings (GPU)

    BoxMode     = "Box",     -- "Box" | "Corner"
    BoxColor    = C3rgb(255, 255, 255),
    BoxThick    = 1.5,
    CornerRatio = 0.28,

    -- Box Fill (preenchimento dentro da box)
    BoxFill      = false,
    BoxFillMode  = "Solid",  -- "Solid" | "Gradient"
    -- Solid:
    BoxFillColor = C3rgb(255, 255, 255),
    BoxFillTrans = 0.70,        -- 0 = sólido, 1 = invisível
    -- Gradient (topo → base):
    BoxFillTopColor = C3rgb(255,  255, 255),
    BoxFillBotColor = C3rgb(255, 255, 255),
    BoxFillTopTrans = 0.92,     -- topo mais transparente
    BoxFillBotTrans = 0.42,     -- base mais forte

    HlFillColor    = C3rgb(255, 255, 255),
    HlOutlineColor = C3rgb(255, 255, 255),
    HlFillTrans    = 0.60,
    HlOutlineTrans = 0.3,

    TracerOrigin = "Bottom",    -- "Bottom" | "Top" | "Center"

    TextSize  = 13,
    TextFont  = 2,

    HpHigh = C3rgb(0,   220,  80),
    HpMid  = C3rgb(255, 190,   0),
    HpLow  = C3rgb(255,  50,  50),

    MaxDistance = 600,

    DistNear = 80,
    DistMid  = 250,
}

-- ─────────────────────────────────────────────────────────────
--  CONFIG CACHE
-- ─────────────────────────────────────────────────────────────
local CC = {}
local function BakeConfigCache()
    CC.Box          = Config.Box
    CC.Highlight    = Config.Highlight
    CC.Name         = Config.Name
    CC.Distance     = Config.Distance
    CC.HealthBar    = Config.HealthBar
    CC.Tracer       = Config.Tracer
    CC.Shadows      = Config.Shadows
    CC.BoxMode      = Config.BoxMode
    CC.BoxColor     = Config.BoxColor
    CC.CornerRatio  = Config.CornerRatio
    CC.BoxFill       = Config.BoxFill
    CC.BoxFillMode   = Config.BoxFillMode
    CC.BoxFillColor  = Config.BoxFillColor
    CC.BoxFillTrans  = Config.BoxFillTrans
    CC.TracerOrigin = Config.TracerOrigin
    CC.HpHigh       = Config.HpHigh
    CC.HpMid        = Config.HpMid
    CC.HpLow        = Config.HpLow
    CC.MaxDistance  = Config.MaxDistance
    CC.DistNear     = Config.DistNear
    CC.DistMid      = Config.DistMid
end
BakeConfigCache()

-- ─────────────────────────────────────────────────────────────
--  GRADIENT FILL LUT — cor/transparência por banda, computado
--  uma vez por rebake (igual p/ todos os players). Convenção do
--  Drawing: Transparency 1 = opaco, 0 = invisível.
-- ─────────────────────────────────────────────────────────────
local FILL_BANDS = 8
local BAND_COL = {}   -- [i] Color3
local BAND_TR  = {}   -- [i] transparency (Drawing)
local function BakeFillLut()
    local tc, bc = Config.BoxFillTopColor, Config.BoxFillBotColor
    local tt, bt = Config.BoxFillTopTrans, Config.BoxFillBotTrans
    for i = 1, FILL_BANDS do
        local t = (i - 0.5) / FILL_BANDS  -- 0=topo, 1=base
        BAND_COL[i] = C3new(
            tc.R + (bc.R - tc.R) * t,
            tc.G + (bc.G - tc.G) * t,
            tc.B + (bc.B - tc.B) * t
        )
        local trCfg = tt + (bt - tt) * t  -- 0..1 (invisível)
        BAND_TR[i]  = 1 - trCfg
    end
end
BakeFillLut()

-- ─────────────────────────────────────────────────────────────
--  VIEWPORT + PROJECTION CACHE (atualizado por evento)
--  projScale converte altura-de-mundo → pixels sem 2ª projeção.
--  pixelHeight = worldHeight * projScale / depth
-- ─────────────────────────────────────────────────────────────
local VP      = Camera.ViewportSize
local VP_X    = VP.X
local VP_Y    = VP.Y
local VP_HX   = VP.X * 0.5
local VP_HY   = VP.Y * 0.5
local projScale = 1

local function UpdateProj()
    VP    = Camera.ViewportSize
    VP_X  = VP.X
    VP_Y  = VP.Y
    VP_HX = VP.X * 0.5
    VP_HY = VP.Y * 0.5
    local fov = mrad(Camera.FieldOfView)
    projScale = VP_Y / (2 * mtan(fov * 0.5))
end
UpdateProj()

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateProj)
Camera:GetPropertyChangedSignal("FieldOfView"):Connect(UpdateProj)

local function GetTracerY()
    local o = CC.TracerOrigin
    return o == "Bottom" and VP_Y or o == "Top" and 0 or VP_HY
end

-- ─────────────────────────────────────────────────────────────
--  HEALTH COLOR LUT
-- ─────────────────────────────────────────────────────────────
local HP_LUT = {}
local function BakeHPLut()
    local hi, mi, lo = CC.HpHigh, CC.HpMid, CC.HpLow
    for i = 0, 100 do
        local t = i / 100
        if t > 0.5 then
            local f = (t - 0.5) * 2
            HP_LUT[i] = C3new(mi.R+(hi.R-mi.R)*f, mi.G+(hi.G-mi.G)*f, mi.B+(hi.B-mi.B)*f)
        else
            local f = t * 2
            HP_LUT[i] = C3new(lo.R+(mi.R-lo.R)*f, lo.G+(mi.G-lo.G)*f, lo.B+(mi.B-lo.B)*f)
        end
    end
end
BakeHPLut()

local function HpColor(hp01)
    return HP_LUT[mfloor(mclamp(hp01, 0, 1) * 100)]
end

-- ─────────────────────────────────────────────────────────────
--  DRAWING FACTORY
-- ─────────────────────────────────────────────────────────────
local SHD_COL   = C3new(0, 0, 0)
local SHD_ALPHA = 0.45

local function NewDraw(class, props)
    local d = Drawing.new(class)
    for k, v in next, props do d[k] = v end
    return d
end

local IGNORE = { HumanoidRootPart = true }

-- ─────────────────────────────────────────────────────────────
--  BOUNDING BOX — puramente aritmético, sem alocação.
--  Recebe lista de parts JÁ FILTRADA (nada de GetChildren/IsA aqui).
-- ─────────────────────────────────────────────────────────────
local _r00,_r01,_r02 = 0,0,0
local _r10,_r11,_r12 = 0,0,0
local _r20,_r21,_r22 = 0,0,0
local _bpx,_bpy,_bpz = 0,0,0
local _bbMinX,_bbMinY,_bbMinZ =  huge, huge, huge
local _bbMaxX,_bbMaxY,_bbMaxZ = -huge,-huge,-huge

local function _chk(lx, ly, lz)
    local wx = _r00*lx + _r01*ly + _r02*lz + _bpx
    local wy = _r10*lx + _r11*ly + _r12*lz + _bpy
    local wz = _r20*lx + _r21*ly + _r22*lz + _bpz
    if wx < _bbMinX then _bbMinX = wx end; if wx > _bbMaxX then _bbMaxX = wx end
    if wy < _bbMinY then _bbMinY = wy end; if wy > _bbMaxY then _bbMaxY = wy end
    if wz < _bbMinZ then _bbMinZ = wz end; if wz > _bbMaxZ then _bbMaxZ = wz end
end

local function GetBoundingBox(parts, count, hrpPos, outSize, outOffset)
    if count == 0 then return false end
    _bbMinX= huge; _bbMinY= huge; _bbMinZ= huge
    _bbMaxX=-huge; _bbMaxY=-huge; _bbMaxZ=-huge

    for i = 1, count do
        local part = parts[i]
        local size = part.Size
        local sx, sy, sz = size.X*.5, size.Y*.5, size.Z*.5
        _bpx,_bpy,_bpz,
        _r00,_r01,_r02,
        _r10,_r11,_r12,
        _r20,_r21,_r22 = part.CFrame:GetComponents()
        _chk( sx, sy, sz); _chk(-sx, sy, sz)
        _chk( sx,-sy, sz); _chk(-sx,-sy, sz)
        _chk( sx, sy,-sz); _chk(-sx, sy,-sz)
        _chk( sx,-sy,-sz); _chk(-sx,-sy,-sz)
    end

    local cx = (_bbMinX+_bbMaxX)*.5
    local cy = (_bbMinY+_bbMaxY)*.5
    local cz = (_bbMinZ+_bbMaxZ)*.5

    outSize[1] = _bbMaxX - _bbMinX
    outSize[2] = _bbMaxY - _bbMinY
    outSize[3] = _bbMaxZ - _bbMinZ
    outOffset[1] = cx - hrpPos.X
    outOffset[2] = cy - hrpPos.Y
    outOffset[3] = cz - hrpPos.Z
    return true
end

-- ─────────────────────────────────────────────────────────────
--  POOL
-- ─────────────────────────────────────────────────────────────
local Pool = {}

local function BuildEntry(player)
    local thick = Config.BoxThick
    local shdC  = SHD_COL
    local shdA  = SHD_ALPHA

    local e = {
        -- fill atrás de tudo (ZIndex baixo)
        BoxFill   = NewDraw("Square",{Thickness=1, Filled=true, Transparency=1-Config.BoxFillTrans, Color=Config.BoxFillColor, ZIndex=0, Visible=false}),
        FillBands = {}, -- gradiente (preenchido abaixo)

        BoxShadow = NewDraw("Square",{Thickness=thick+2, Filled=false, Transparency=shdA, Color=shdC, ZIndex=1, Visible=false}),
        Box       = NewDraw("Square",{Thickness=thick,   Filled=false, Transparency=1,    ZIndex=2, Visible=false}),

        CornerShadows = {},
        Corners       = {},

        TracerShadow = NewDraw("Line",{Thickness=2.5, Color=shdC, Transparency=shdA, Visible=false}),
        Tracer       = NewDraw("Line",{Thickness=1,   Transparency=0.85,             Visible=false}),

        Name = NewDraw("Text",{
            Size=Config.TextSize, Center=true, Outline=true, Font=Config.TextFont,
            Color=C3rgb(255,255,255), OutlineColor=SHD_COL, Transparency=1, Visible=false,
        }),
        Distance = NewDraw("Text",{
            Size=Config.TextSize-1, Center=true, Outline=true, Font=Config.TextFont,
            Color=C3rgb(185,185,185), OutlineColor=SHD_COL, Transparency=1, Visible=false,
        }),

        HpBg   = NewDraw("Line",{Thickness=4, Color=SHD_COL, Transparency=0.65, Visible=false}),
        HpFill = NewDraw("Line",{Thickness=2, Transparency=1, Visible=false}),

        Highlight = nil, -- criado lazy no heavy loop

        -- character cache
        char  = nil, hrp = nil, hum = nil, head = nil,
        charConn = nil, humConn = nil,
        descAddConn = nil, descRemConn = nil,

        -- parts cache (event-driven)
        parts = {}, partCount = 0, partsDirty = true,

        -- estado (0=invalid 1=dead 2=idle 3=far 4=mid 5=near)
        state = 0, onScreen = false, dist = 0, frameCount = 0,

        -- bbox buffers
        bbSize   = {4,6,2},
        bbOffset = {0,0,0},

        -- dirty flags
        dirtyHP = true, lastHP = -1, lastHPCol = nil,
        lastName = "", lastDistInt = -1,

        -- screen-pos dirty (evita reescrever drawings parados)
        pSx = -1, pSy = -1, pW = -1, pH = -1,

        player = player,
    }

    for i = 1, 8 do
        e.CornerShadows[i] = NewDraw("Line",{Thickness=thick+2.5, Transparency=shdA, Color=shdC, Visible=false})
        e.Corners[i]       = NewDraw("Line",{Thickness=thick+0.5, Transparency=1,               Visible=false})
    end

    for i = 1, FILL_BANDS do
        e.FillBands[i] = NewDraw("Square",{Thickness=1, Filled=true, Transparency=BAND_TR[i], Color=BAND_COL[i], ZIndex=0, Visible=false})
    end

    return e
end

-- ─────────────────────────────────────────────────────────────
--  HIDE ALL
-- ─────────────────────────────────────────────────────────────
local function HideAll(e)
    e.BoxFill.Visible   = false
    local FB = e.FillBands
    for i = 1, FILL_BANDS do FB[i].Visible = false end
    e.Box.Visible       = false
    e.BoxShadow.Visible = false
    e.Tracer.Visible    = false
    e.TracerShadow.Visible = false
    e.Name.Visible      = false
    e.Distance.Visible  = false
    e.HpBg.Visible      = false
    e.HpFill.Visible    = false
    local C, CS = e.Corners, e.CornerShadows
    for i = 1, 8 do C[i].Visible=false; CS[i].Visible=false end
    if e.Highlight then e.Highlight.Enabled = false end
    e.onScreen = false
end

local function SV(obj, val)
    if obj.Visible ~= val then obj.Visible = val end
end

-- ─────────────────────────────────────────────────────────────
--  PARTS CACHE — rebuild só quando o character muda de parts
-- ─────────────────────────────────────────────────────────────
local function RebuildParts(e)
    local char  = e.char
    local parts = e.parts
    local n = 0
    if char then
        local kids = char:GetChildren()
        for i = 1, #kids do
            local p = kids[i]
            if p:IsA("BasePart") and not IGNORE[p.Name] then
                n = n + 1
                parts[n] = p
            end
        end
    end
    for i = n+1, e.partCount do parts[i] = nil end
    e.partCount  = n
    e.partsDirty = false
end

-- ─────────────────────────────────────────────────────────────
--  CHARACTER CACHE
-- ─────────────────────────────────────────────────────────────
local function CacheCharacter(e, char)
    -- destrói highlight anterior (recriado lazy)
    if e.Highlight then
        e.Highlight.Parent = nil
        e.Highlight = nil
    end
    -- desconecta observadores de parts antigos
    if e.descAddConn then e.descAddConn:Disconnect(); e.descAddConn = nil end
    if e.descRemConn then e.descRemConn:Disconnect(); e.descRemConn = nil end

    if not char then
        e.char = nil; e.hrp = nil; e.hum = nil; e.head = nil
        e.partCount = 0; e.partsDirty = true
        e.state = 0
        HideAll(e)
        return
    end

    e.char  = char
    e.hrp   = char:FindFirstChild("HumanoidRootPart")   -- pode ser nil p/ char novo
    e.hum   = char:FindFirstChildOfClass("Humanoid")    -- pode ser nil p/ char novo
    e.head  = char:FindFirstChild("Head")
    e.state = 2  -- aguardando; heavy loop resolve hrp/hum e promove o state

    e.dirtyHP = true
    e.lastHP  = -1
    e.lastDistInt = -1
    e.partsDirty  = true
    e.pSx = -1; e.pSy = -1; e.pW = -1; e.pH = -1

    -- invalida parts quando o character ganha/perde BasePart
    e.descAddConn = char.DescendantAdded:Connect(function(inst)
        if inst:IsA("BasePart") then e.partsDirty = true end
    end)
    e.descRemConn = char.DescendantRemoving:Connect(function(inst)
        if inst:IsA("BasePart") then e.partsDirty = true end
    end)

    -- eventos do Humanoid são conectados de forma lazy no heavy loop
    -- (o Humanoid pode ainda não existir neste ponto p/ players novos)
    if e.humConn then e.humConn:Disconnect(); e.humConn = nil end
end

-- ─────────────────────────────────────────────────────────────
--  ADD / REMOVE
-- ─────────────────────────────────────────────────────────────
local ActiveList = {}

local function AddPlayer(player)
    if player == LocalPlayer then return end
    if Pool[player] then return end

    local e = BuildEntry(player)
    Pool[player] = e
    tins(ActiveList, e)

    if e.charConn then e.charConn:Disconnect() end
    e.charConn = player.CharacterAdded:Connect(function(char)
        CacheCharacter(e, char)
    end)
    CacheCharacter(e, player.Character)
end

local function RemovePlayer(player)
    local e = Pool[player]
    if not e then return end

    if e.charConn    then e.charConn:Disconnect()    end
    if e.humConn     then e.humConn:Disconnect()     end
    if e.descAddConn then e.descAddConn:Disconnect() end
    if e.descRemConn then e.descRemConn:Disconnect() end
    if e.Highlight   then e.Highlight.Parent = nil   end

    HideAll(e)
    for i = #ActiveList, 1, -1 do
        if ActiveList[i] == e then tremove(ActiveList, i); break end
    end
    Pool[player] = nil
end

Players.PlayerAdded:Connect(function(p)
    if p:IsA("Player") then AddPlayer(p) end
end)
Players.PlayerRemoving:Connect(function(p)
    if p:IsA("Player") then RemovePlayer(p) end
end)
for _, p in ipairs(Players:GetChildren()) do
    if p:IsA("Player") then AddPlayer(p) end
end

-- ─────────────────────────────────────────────────────────────
--  HEAVY LOOP — bbox + distância + LOD + highlight (20fps, batches)
-- ─────────────────────────────────────────────────────────────
local HEAVY_STEP = 1 / 20
local BATCH_SIZE = 6
local heavyAccum = 0
local heavyIdx   = 0

local function EnsureHighlight(e)
    if not e.Highlight and e.char then
        local hl = Instance.new("Highlight")
        hl.FillColor           = Config.HlFillColor
        hl.OutlineColor        = Config.HlOutlineColor
        hl.FillTransparency    = Config.HlFillTrans
        hl.OutlineTransparency = Config.HlOutlineTrans
        hl.DepthMode           = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee             = e.char
        hl.Parent              = e.char
        e.Highlight            = hl
    end
end

RunService.Heartbeat:Connect(function(dt)
    heavyAccum = heavyAccum + dt
    if heavyAccum < HEAVY_STEP then return end
    heavyAccum = heavyAccum % HEAVY_STEP

    local total = #ActiveList
    if total == 0 then return end

    local camPos = Camera.CFrame.Position
    local maxD   = CC.MaxDistance
    local wantHL = CC.Highlight

    local count = mmin(BATCH_SIZE, total)
    for _ = 1, count do
        heavyIdx = (heavyIdx % total) + 1
        local e  = ActiveList[heavyIdx]
        if not e then continue end

        local char = e.char
        if not char or not char:IsDescendantOf(workspace) then
            HideAll(e); e.state = 0
            continue
        end

        -- LAZY RESOLVE — char de player novo aparece antes do HRP/Humanoid.
        -- Enquanto faltarem, re-tenta buscar (state 2 = aguardando, NÃO morto).
        local hrp = e.hrp
        local hum = e.hum
        if not hrp then hrp = char:FindFirstChild("HumanoidRootPart"); e.hrp = hrp end
        if not hum then hum = char:FindFirstChildOfClass("Humanoid");  e.hum = hum end

        if not hrp or not hum then
            HideAll(e); e.state = 2  -- ainda carregando; tenta de novo no próximo tick
            continue
        end

        if hum.Health <= 0 then
            if e.state ~= 1 then HideAll(e); e.state = 1 end
            continue
        end

        -- (re)conecta eventos do Humanoid se ainda não conectado
        if not e.humConn then
            e.humConn = hum.Died:Connect(function()
                HideAll(e); e.state = 1
            end)
            hum:GetPropertyChangedSignal("Health"):Connect(function()
                e.dirtyHP = true
            end)
            e.dirtyHP = true
        end

        -- distância
        local hp = hrp.Position
        local dx = hp.X - camPos.X
        local dy = hp.Y - camPos.Y
        local dz = hp.Z - camPos.Z
        local dist = (dx*dx + dy*dy + dz*dz) ^ 0.5
        e.dist = dist

        if dist > maxD then
            if e.state ~= 6 then HideAll(e); e.state = 6 end
            if e.Highlight and e.Highlight.Enabled then e.Highlight.Enabled = false end
            continue
        end

        e.state = (dist < CC.DistNear) and 5
               or (dist < CC.DistMid)  and 4
               or                           3

        -- parts cache
        if e.partsDirty then RebuildParts(e) end

        -- bbox (tamanho + offset relativo ao HRP)
        local ok = GetBoundingBox(e.parts, e.partCount, hp, e.bbSize, e.bbOffset)
        if not ok then
            HideAll(e); e.state = 0
            continue
        end

        -- HP dirty
        if e.dirtyHP then
            e.lastHP  = mclamp(hum.Health / hum.MaxHealth, 0, 1)
            e.dirtyHP = false
        end

        -- Highlight gerido aqui (independente do culling 2D)
        if wantHL then
            EnsureHighlight(e)
            if e.Highlight and not e.Highlight.Enabled then e.Highlight.Enabled = true end
        elseif e.Highlight and e.Highlight.Enabled then
            e.Highlight.Enabled = false
        end
    end
end)

-- ─────────────────────────────────────────────────────────────
--  RENDER LOOP — RenderStepped (60fps+), só move drawings
-- ─────────────────────────────────────────────────────────────
local gSig    = -1
local gBoxCol = nil

RunService.RenderStepped:Connect(function()
    BakeConfigCache()

    local camCF   = Camera.CFrame
    local camPos  = camCF.Position
    local look    = camCF.LookVector
    local lookX, lookY, lookZ = look.X, look.Y, look.Z

    local tracerY  = GetTracerY()
    local tracerOx = VP_HX
    local boxCol   = CC.BoxColor
    local boxMode  = CC.BoxMode
    local cRatio   = CC.CornerRatio
    local doBox    = CC.Box
    local doName   = CC.Name
    local doDist   = CC.Distance
    local doHP     = CC.HealthBar
    local doTracer = CC.Tracer
    local doShadow = CC.Shadows
    local doFill   = CC.BoxFill
    local fillGrad = (CC.BoxFillMode == "Gradient")
    local fillCol  = CC.BoxFillColor
    local fillTr   = 1 - CC.BoxFillTrans
    local isBoxMode = (boxMode == "Box")

    -- assinatura global: se algum toggle/cor mudou, força redraw de todos
    local sig = 0
    if doBox    then sig = sig + 1  end
    if doName   then sig = sig + 2  end
    if doDist   then sig = sig + 4  end
    if doHP     then sig = sig + 8  end
    if doTracer then sig = sig + 16 end
    if doShadow then sig = sig + 32 end
    if isBoxMode then sig = sig + 64 end
    if doFill   then sig = sig + 128 end
    if fillGrad then sig = sig + 256 end
    local forceUpdate = false
    if sig ~= gSig or boxCol ~= gBoxCol then
        forceUpdate = true; gSig = sig; gBoxCol = boxCol
    end

    local vpX, vpY = VP_X, VP_Y

    for i = 1, #ActiveList do
        local e  = ActiveList[i]
        local st = e.state
        if st <= 2 then continue end -- invalid / dead / aguardando carregar

        local hrp = e.hrp
        if not hrp then continue end

        -- MAX DISTANCE GATE — validado todo frame, independente do state
        -- (o state do heavy loop pode ficar "preso" em 3 tanto para
        --  far-in-range quanto para out-of-range; aqui é a fonte da verdade)
        if e.dist > CC.MaxDistance then
            if e.onScreen then HideAll(e) end
            continue
        end

        -- LOD throttle: player longe atualiza a meia taxa
        e.frameCount = e.frameCount + 1
        if st == 3 and e.onScreen and (e.frameCount % 2 == 0) then
            continue
        end

        -- centro do box em tempo real (HRP + offset)
        local hrpPos = hrp.Position
        local off = e.bbOffset
        local bsz = e.bbSize
        local cxW = hrpPos.X + off[1]
        local cyW = hrpPos.Y + off[2]
        local czW = hrpPos.Z + off[3]

        -- DOT-REJECT: atrás da câmera? pula sem chamar W2VP (barato)
        local ex = cxW - camPos.X
        local ey = cyW - camPos.Y
        local ez = czW - camPos.Z
        local depth = ex*lookX + ey*lookY + ez*lookZ
        if depth <= 0.5 then
            if e.onScreen then HideAll(e) end
            continue
        end

        -- 1 ÚNICA projeção (centro). Altura vem do projScale analítico.
        local sVec = Camera:WorldToViewportPoint(V3new(cxW, cyW, czW))
        local d = sVec.Z
        if d <= 0.1 then
            if e.onScreen then HideAll(e) end
            continue
        end

        local bszY = bsz[2] > 0 and bsz[2] or 1
        local h = bszY * projScale / d
        if h < 1 then h = 1 end
        local w = h * (bsz[1] / bszY)

        local cx  = sVec.X
        local cyc = sVec.Y
        local sx  = cx - w * 0.5
        local sy  = cyc - h * 0.5

        -- margem de tela (deixa passar box parcialmente visível)
        if cx < -w or cx > vpX + w or cyc < -h or cyc > vpY + h then
            if e.onScreen then HideAll(e) end
            continue
        end

        -- SCREEN-POS DIRTY SKIP: parado + sem mudança de config → 0 writes
        if not forceUpdate and e.onScreen then
            local dsx = sx - e.pSx; if dsx < 0 then dsx = -dsx end
            local dsy = sy - e.pSy; if dsy < 0 then dsy = -dsy end
            local dw  = w  - e.pW;  if dw  < 0 then dw  = -dw  end
            local dh  = h  - e.pH;  if dh  < 0 then dh  = -dh  end
            if dsx < 0.4 and dsy < 0.4 and dw < 0.4 and dh < 0.4 then
                if doDist then
                    local di = mfloor(e.dist)
                    if e.lastDistInt ~= di then
                        e.Distance.Text = di .. "m"; e.lastDistInt = di
                    end
                end
                continue
            end
        end
        e.pSx = sx; e.pSy = sy; e.pW = w; e.pH = h

        -- ── BOX FILL (independente do modo de box) ───────────
        local FB = e.FillBands
        if doFill then
            if fillGrad then
                -- gradiente: N bandas horizontais empilhadas
                SV(e.BoxFill, false)
                local bandH = h / FILL_BANDS
                local bandSz = V2new(w, bandH + 1) -- +1 evita gaps entre bandas
                for j = 1, FILL_BANDS do
                    local fb = FB[j]
                    fb.Size     = bandSz
                    fb.Position = V2new(sx, sy + (j - 1) * bandH)
                    SV(fb, true)
                end
            else
                -- sólido: 1 quadrado
                for j = 1, FILL_BANDS do SV(FB[j], false) end
                local bf = e.BoxFill
                bf.Size     = V2new(w, h)
                bf.Position = V2new(sx, sy)
                if bf.Color ~= fillCol then bf.Color = fillCol end
                if bf.Transparency ~= fillTr then bf.Transparency = fillTr end
                SV(bf, true)
            end
        else
            SV(e.BoxFill, false)
            for j = 1, FILL_BANDS do SV(FB[j], false) end
        end

        -- ── BOX / CORNERS ────────────────────────────────────
        if doBox then
            if isBoxMode then
                local sz = V2new(w, h)
                local ps = V2new(sx, sy)
                if doShadow then
                    e.BoxShadow.Size=sz; e.BoxShadow.Position=ps; SV(e.BoxShadow, true)
                else
                    SV(e.BoxShadow, false)
                end
                e.Box.Size=sz; e.Box.Position=ps
                if e.Box.Color ~= boxCol then e.Box.Color = boxCol end
                SV(e.Box, true)
                local C, CS = e.Corners, e.CornerShadows
                for j = 1, 8 do SV(C[j], false); SV(CS[j], false) end
            else
                SV(e.Box, false); SV(e.BoxShadow, false)
                local c  = mclamp(mmin(w,h)*cRatio, 5, 20)
                local xw = sx + w
                local yh = sy + h
                local C, CS = e.Corners, e.CornerShadows
                local f1=V2new(sx,sy);  local t1=V2new(sx+c,sy)
                local f2=V2new(sx,sy);  local t2=V2new(sx,sy+c)
                local f3=V2new(xw,sy);  local t3=V2new(xw-c,sy)
                local f4=V2new(xw,sy);  local t4=V2new(xw,sy+c)
                local f5=V2new(sx,yh);  local t5=V2new(sx+c,yh)
                local f6=V2new(sx,yh);  local t6=V2new(sx,yh-c)
                local f7=V2new(xw,yh);  local t7=V2new(xw-c,yh)
                local f8=V2new(xw,yh);  local t8=V2new(xw,yh-c)
                local fArr={f1,f2,f3,f4,f5,f6,f7,f8}
                local tArr={t1,t2,t3,t4,t5,t6,t7,t8}
                for j = 1, 8 do
                    if doShadow then
                        CS[j].From=fArr[j]; CS[j].To=tArr[j]; SV(CS[j], true)
                    else
                        SV(CS[j], false)
                    end
                    C[j].From=fArr[j]; C[j].To=tArr[j]
                    if C[j].Color ~= boxCol then C[j].Color = boxCol end
                    SV(C[j], true)
                end
            end
        else
            SV(e.Box, false); SV(e.BoxShadow, false)
            local C, CS = e.Corners, e.CornerShadows
            for j = 1, 8 do SV(C[j], false); SV(CS[j], false) end
        end

        -- ── TRACER ───────────────────────────────────────────
        if doTracer then
            local origin = V2new(tracerOx, tracerY)
            local target = V2new(cx, cyc)
            if doShadow then
                e.TracerShadow.From=origin; e.TracerShadow.To=target; SV(e.TracerShadow, true)
            else
                SV(e.TracerShadow, false)
            end
            e.Tracer.From=origin; e.Tracer.To=target
            if e.Tracer.Color ~= boxCol then e.Tracer.Color = boxCol end
            SV(e.Tracer, true)
        else
            SV(e.Tracer, false); SV(e.TracerShadow, false)
        end

        -- ── NAME ─────────────────────────────────────────────
        if doName then
            local pname = e.player.DisplayName
            if e.lastName ~= pname then
                e.Name.Text = pname; e.lastName = pname
            end
            e.Name.Position = V2new(cx, sy - 16)
            SV(e.Name, true)
        else
            SV(e.Name, false)
        end

        -- ── DISTANCE ─────────────────────────────────────────
        if doDist then
            local di = mfloor(e.dist)
            if e.lastDistInt ~= di then
                e.Distance.Text = di .. "m"; e.lastDistInt = di
            end
            e.Distance.Position = V2new(cx, sy + h + 3)
            SV(e.Distance, true)
        else
            SV(e.Distance, false)
        end

        -- ── HEALTH BAR ───────────────────────────────────────
        if doHP then
            local bx = sx - 7
            e.HpBg.From = V2new(bx, sy)
            e.HpBg.To   = V2new(bx, sy + h)
            SV(e.HpBg, true)

            local hp01  = e.lastHP >= 0 and e.lastHP or 1
            local fillH = h * hp01
            e.HpFill.From = V2new(bx, sy + h)
            e.HpFill.To   = V2new(bx, sy + h - fillH)
            local hpCol = HpColor(hp01)
            if e.lastHPCol ~= hpCol then
                e.HpFill.Color = hpCol; e.lastHPCol = hpCol
            end
            SV(e.HpFill, true)
        else
            SV(e.HpBg, false); SV(e.HpFill, false)
        end

        e.onScreen = true
    end
end)

-------------------------------- TABS --------------------------------
local Tabs = {
	Main = Window:AddTab("Esp", "eye"),
}

-- Card1 do MAIN
local Card_Main1 = Tabs.Main:AddLeftGroupbox("General", "user-round")

Card_Main1:AddToggle("Highlight", {
	Text = "Highlight",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(v)
		Config.Highlight = v
	end,
})

Card_Main1:AddToggle("Box", {
	Text = "Box",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(v)
		Config.Box = v
	end,
})

Card_Main1:AddDropdown("BoxType", {
	Values = {"Box", "Corner"},
	Default = 1,
	Multi = false,

	Text = "Box Type",
	Searchable = false,

	Callback = function(opt)
		Config.BoxMode = opt
	end,

	Disabled = false,
	Visible = true,
})

Card_Main1:AddToggle("Tracer", {
	Text = "Tracer",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(v)
		Config.Tracer = v
	end,
})

Card_Main1:AddDropdown("TracerType", {
	Values = {"Bottom", "Center", "Top"},
	Default = 1,
	Multi = false,

	Text = "Tracer Type",
	Searchable = false,

	Callback = function(opt)
		Config.TracerOrigin = opt
	end,

	Disabled = false,
	Visible = true,
})

-- Card 2 do MAIN
local Card_Main2 = Tabs.Main:AddLeftGroupbox("Others", "layers")

Card_Main2:AddToggle("Name", {
	Text = "Name",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(v)
		Config.Name = v
	end,
})

Card_Main2:AddToggle("Distance", {
	Text = "Distance",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(v)
		Config.Distance = v
	end,
})

Card_Main2:AddToggle("HealthBar", {
	Text = "Health Bar",

	Default = false,
	Disabled = false,
	Visible = true,
	Risky = false,

	Callback = function(v)
		Config.HealthBar = v
	end,
})

-- Card 3 do MAIN
local Card_Main3 = Tabs.Main:AddRightGroupbox("Custom", "pencil")
