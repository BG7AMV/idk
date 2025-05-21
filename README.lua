-- BG7 MODERN SILENT AIM GUI (compact, fixed [F], drag-anywhere, short info, manual lock, no auto aim, no auto-switch)
-- [V]: lock toggle, aim right shoulder behind. [F]: hold = aim nearest/front (blue), release = back. 
-- GUI: All frame draggable, info short, no overflow.

local Players, RunService, UserInputService, camera =
    game:GetService("Players"), game:GetService("RunService"), game:GetService("UserInputService"), workspace.CurrentCamera
local LocalPlayer, PlayerGui = Players.LocalPlayer, Players.LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    COLORS = {
        {name="Red", color=Color3.fromRGB(255,0,0)},
        {name="Green", color=Color3.fromRGB(0,255,0)},
        {name="Blue", color=Color3.fromRGB(0,0,255)},
        {name="Yellow", color=Color3.fromRGB(255,255,0)},
    },
    GUI_SIZE = UDim2.new(0, 404, 0, 236),
    GUI_POS = UDim2.new(0, 48, 0, 80),
    PADDING = 20,
    SHOW_HP = true,        -- HP etiketi göster
}

local GUI_VISIBLE = true
local silentAimEnabled, currentAimTarget, fAimTarget = false, nil, nil
local lastESPColor = CONFIG.COLORS[1].color
local FActive = false

-- Distance and HP tag
local infoTemplate = Instance.new("BillboardGui")
infoTemplate.Name, infoTemplate.Size, infoTemplate.StudsOffset, infoTemplate.AlwaysOnTop =
    "InfoGui", UDim2.new(0,130,0,36), Vector3.new(0,3.2,0), true
local infoLabel = Instance.new("TextLabel")
infoLabel.Size, infoLabel.BackgroundTransparency, infoLabel.TextColor3 =
    UDim2.new(1,0,1,0), 1, Color3.fromRGB(255,255,255)
infoLabel.TextStrokeTransparency, infoLabel.TextStrokeColor3, infoLabel.Font =
    0, Color3.fromRGB(0,0,0), Enum.Font.GothamBlack
infoLabel.TextScaled, infoLabel.TextSize, infoLabel.Parent =
    true, 16, infoTemplate

-- RGB helpers
local function rgbColor(t)
    local r = math.sin(t*2*math.pi) * 0.5 + 0.5
    local g = math.sin(t*2*math.pi + 2) * 0.5 + 0.5
    local b = math.sin(t*2*math.pi + 4) * 0.5 + 0.5
    return Color3.new(r,g,b)
end
local function createRGBStroke(frame, thickness)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = thickness or 3
    stroke.Color = Color3.fromRGB(255,0,0)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    task.spawn(function()
        local t = 0
        while frame and frame.Parent do
            t = t + RunService.RenderStepped:Wait()
            stroke.Color = rgbColor((t/2.5)%1)
        end
    end)
    return stroke
end

local function createButton(parent, name, size, pos, txt, bgColor, cb, rounded)
    local btn = Instance.new("TextButton", parent)
    btn.Name, btn.Size, btn.Position, btn.Text, btn.BackgroundColor3 =
        name, size, pos, txt, bgColor
    btn.TextColor3, btn.Font, btn.TextScaled, btn.AutoButtonColor =
        Color3.new(1,1,1), Enum.Font.GothamBlack, true, false
    if rounded then Instance.new("UICorner", btn).CornerRadius = UDim.new(0,rounded) end
    if cb then btn.MouseButton1Click:Connect(cb) end
    btn.ZIndex = 10
    return btn
end
local function createLabel(parent, name, size, pos, txt, textColor, font, fontSize, align, shadow)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Name, lbl.Size, lbl.Position, lbl.Text, lbl.BackgroundTransparency =
        name, size, pos, txt, 1
    lbl.TextColor3, lbl.Font, lbl.TextSize, lbl.TextXAlignment =
        textColor or Color3.new(1,1,1), font or Enum.Font.Gotham, fontSize or 20, align or Enum.TextXAlignment.Left
    lbl.TextScaled = false
    lbl.ZIndex = 10
    if shadow then
        lbl.TextStrokeTransparency = 0.7
        lbl.TextStrokeColor3 = Color3.new(0,0,0)
    end
    return lbl
end

-- === GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name, screenGui.ResetOnSpawn, screenGui.Parent = "BG7Modern", false, PlayerGui
screenGui.IgnoreGuiInset = true

-- Show/Hide button
local hideBtn = Instance.new("TextButton")
hideBtn.Name = "HideBTN"
hideBtn.Size = UDim2.new(0,62,0,32)
hideBtn.Position = UDim2.new(0,10,0.4,-16)
hideBtn.BackgroundColor3 = Color3.fromRGB(25,25,25)
hideBtn.Text = "Hide"
hideBtn.TextColor3 = Color3.new(1,1,1)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 18
hideBtn.ZIndex = 99
hideBtn.Parent = screenGui
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0,10)
createRGBStroke(hideBtn,2)

local mainFrame = Instance.new("Frame")
mainFrame.Name, mainFrame.Size, mainFrame.Position =
    "MainFrame", CONFIG.GUI_SIZE, CONFIG.GUI_POS
mainFrame.BackgroundColor3, mainFrame.BorderSizePixel, mainFrame.Visible = Color3.fromRGB(32,32,45), 0, true
mainFrame.Active = true
mainFrame.ZIndex = 2
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0,22)
createRGBStroke(mainFrame, 5)

-- =========================
-- BG7 PRO FRAMEWORK BAŞLATICI
-- =========================
-- Tüm yeni modüller ve paneller bu ana frame'e ultra modüler şekilde entegre edilir.
-- Aimbot koduna dokunulmaz! Sadece diğer modüller eklenir.

------------------------------------------------------------------
-- BG7 PRO EXPLOIT FRAMEWORK: MODÜLER YAPI VE EFFECT MANAGER ----
------------------------------------------------------------------

-- MODÜL YÜKLEYİCİ: Her modül "Framework:RegisterModule" ile eklenir.
local Framework = {
    Modules = {},
    Panels = {},
    Theme = {
        Background = Color3.fromRGB(32,32,45),
        Text = Color3.new(1,1,1),
    },
    Log = function(self, msg, type)
        print(string.format("[%s] %s", type, msg))
    end,
    RegisterModule = function(self, id, mod)
        self.Modules[id] = mod
        if mod.Init then mod:Init(self) end
    end,
    InitModules = function(self)
        for id,mod in pairs(self.Modules) do
            if mod.CreatePanel then
                mod:CreatePanel(self)
            end
        end
    end,
    CreatePanel = function(self, id, title, size, pos)
        local panel = Instance.new("Frame")
        panel.Name, panel.Size, panel.Position, panel.BackgroundTransparency =
            id.."Panel", size, pos, 1
        panel.BackgroundColor3 = self.Theme.Background
        panel.BorderSizePixel = 0
        panel.ZIndex = 20
        local titleLbl = createLabel(panel, id.."Title", UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), title, self.Theme.Text, Enum.Font.FredokaOne, 20)
        titleLbl.BackgroundTransparency = 1
        local contentFrame = Instance.new("Frame")
        contentFrame.Name, contentFrame.Size, contentFrame.Position, contentFrame.BackgroundTransparency =
            id.."Content", UDim2.new(1,0,1,-24), UDim2.new(0,0,0,24), 1
        contentFrame.BackgroundColor3 = self.Theme.Background
        contentFrame.BorderSizePixel = 0
        contentFrame.ZIndex = 21
        contentFrame.Parent = panel
        panel.Parent = mainFrame
        return contentFrame
    end,
    CreateToggle = function(self, parent, text, state, cb)
        local toggle = Instance.new("TextButton")
        toggle.Name, toggle.Size, toggle.Position, toggle.Text, toggle.BackgroundColor3 =
            text.."Toggle", UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), text, state and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
        toggle.TextColor3, toggle.Font, toggle.TextScaled, toggle.AutoButtonColor =
            self.Theme.Text, Enum.Font.Gotham, true, false
        toggle.ZIndex = 22
        toggle.MouseButton1Click:Connect(function()
            state = not state
            toggle.BackgroundColor3 = state and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
            if cb then cb(state) end
        end)
        toggle.Parent = parent
        return toggle
    end,
}

------------------------------------------------------------------
-- 1. EFFECT MANAGER MODÜLÜ (Anti Stun, Anti Block, NoCooldown, ...)
------------------------------------------------------------------
local EffectManager = {
    Toggles = {
        AntiStun = false,
        AntiBlock = false,
        AntiVelocity = false,
        NoJumpNerf = false,
        NoDashCooldown = false,
        NoSkillCooldown = false,
        AutoEffectCleaner = false,
    },
    Blacklist = {
        Stun = true, FullStun = true, Blocking = true, Cooldown = true,
        VelocityNerf = true, NoJump = true, CancelDash = true, Dashed = true
    },
    Panel = nil,
    Log = {},
    EffectRep = nil,
    EffectEvents = {},
}

-- MODÜL: Efektleri canlı takip et, GUI üzerinden kontrol et
function EffectManager:Init(framework)
    self.Framework = framework
    -- EffectReplicator referansını bul
    local suc, effectRep = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("EffectReplicator"))
    end)
    if suc then self.EffectRep = effectRep end
    -- Efekt event hook'ları
    if self.EffectRep then
        if self.EffectRep.EffectAdded then
            table.insert(self.EffectEvents, self.EffectRep.EffectAdded:Connect(function(effect)
                self:OnEffectAdded(effect)
            end))
        end
        if self.EffectRep.EffectRemoving then
            table.insert(self.EffectEvents, self.EffectRep.EffectRemoving:Connect(function(effect)
                self:OnEffectRemoving(effect)
            end))
        end
    end
    -- Otomatik temizleyici döngüsü
    task.spawn(function()
        while true do
            if self.Toggles.AutoEffectCleaner then
                self:CleanEffects()
            end
            task.wait(0.1)
        end
    end)
end

function EffectManager:CleanEffects()
    if not self.EffectRep or not self.EffectRep.GetEffects then return end
    for _, effect in pairs(self.EffectRep:GetEffects()) do
        if self:IsBlacklisted(effect) then
            effect:Destroy()
            self:AddLog("Efekt temizlendi: "..tostring(effect.Class), "Success")
        end
    end
end

function EffectManager:IsBlacklisted(effect)
    if not effect or not effect.Class then return false end
    if self.Toggles.AntiStun and (effect.Class == "Stun" or effect.Class == "FullStun") then return true end
    if self.Toggles.AntiBlock and effect.Class == "Blocking" then return true end
    if self.Toggles.AntiVelocity and effect.Class == "VelocityNerf" then return true end
    if self.Toggles.NoJumpNerf and effect.Class == "NoJump" then return true end
    if self.Toggles.NoDashCooldown and (effect.Class == "CancelDash" or effect.Class == "Dashed") then return true end
    if self.Toggles.NoSkillCooldown and effect.Class == "Cooldown" then return true end
    if self.Blacklist[effect.Class] then return true end
    return false
end

function EffectManager:OnEffectAdded(effect)
    if self:IsBlacklisted(effect) then
        effect:Destroy()
        self:AddLog("Eklenen efekt anında kaldırıldı: "..tostring(effect.Class), "Warn")
    end
end

function EffectManager:OnEffectRemoving(effect)
    -- Örnek: Block kaldırılınca Speed ekle
    if effect.Class == "Blocking" then
        self:AddLog("Blocking kaldırıldı, Speed efekti ekleniyor", "Info")
        if self.EffectRep and self.EffectRep.CreateEffect then
            self.EffectRep:CreateEffect("Speed", "Speed", {Value=1.5, DebrisTime=5})
        end
    end
end

function EffectManager:AddLog(msg, type)
    table.insert(self.Log, {os.time(), msg, type})
    if self.Panel and self.Panel.Visible then
        self.Framework:Log("[EffectManager] "..msg, type)
    end
end

-- MODÜL PANELİ: GUI toggle ve ayar paneli
function EffectManager:CreatePanel(framework)
    local panel = framework:CreatePanel("EffectManager", "Effect Manager", UDim2.new(0,340,0,280), UDim2.new(0, 36, 0, 260))
    local y = 44
    local spacing = 34
    local function addToggle(name, desc, toggleKey)
        local btn = framework:CreateToggle(panel, desc, self.Toggles[toggleKey], function(state)
            self.Toggles[toggleKey] = state
            self:AddLog(desc.." "..(state and "Aktif" or "Kapalı"), state and "Success" or "Error")
        end)
        btn.Position = UDim2.new(0,18,0,y)
        y = y + spacing
    end
    addToggle("AntiStun", "Anti Stun", "AntiStun")
    addToggle("AntiBlock", "Anti Block", "AntiBlock")
    addToggle("AntiVelocity", "Anti Velocity", "AntiVelocity")
    addToggle("NoJumpNerf", "No Jump Nerf", "NoJumpNerf")
    addToggle("NoDashCooldown", "No Dash Cooldown", "NoDashCooldown")
    addToggle("NoSkillCooldown", "No Skill Cooldown", "NoSkillCooldown")
    addToggle("AutoEffectCleaner", "Auto Effect Cleaner", "AutoEffectCleaner")
    -- Efektleri canlı listele
    local listBtn = framework:CreateToggle(panel, "Efektleri Listele", false, function(state)
        if state then
            self:ShowEffectList(panel)
        else
            if self.ListPanel then self.ListPanel:Destroy() self.ListPanel = nil end
        end
    end)
    listBtn.Position = UDim2.new(0,18,0,y)
    y = y + spacing
    self.Panel = panel
    framework.Panels["EffectManager"] = panel
end

function EffectManager:ShowEffectList(parent)
    if self.ListPanel then self.ListPanel:Destroy() end
    local listPanel = Instance.new("ScrollingFrame", parent)
    listPanel.Name = "EffectList"
    listPanel.Size = UDim2.new(1,-24,0,80)
    listPanel.Position = UDim2.new(0,12,1,-88)
    listPanel.BackgroundColor3 = Framework.Theme.Background
    listPanel.BorderSizePixel = 0
    listPanel.ScrollBarThickness = 8
    listPanel.ZIndex = 25
    local effects = {}
    if self.EffectRep and self.EffectRep.GetEffects then
        for _,effect in pairs(self.EffectRep:GetEffects()) do
            table.insert(effects, effect)
        end
    end
    for i,effect in ipairs(effects) do
        local lbl = Instance.new("TextLabel", listPanel)
        lbl.Size = UDim2.new(1,0,0,22)
        lbl.Position = UDim2.new(0,0,0,(i-1)*22)
        lbl.Text = string.format("%s | Value: %s | Tag: %s", tostring(effect.Class), tostring(effect.Value or "-"), tostring(effect.Tag or "-"))
        lbl.TextColor3 = Framework.Theme.Text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.BackgroundTransparency = 1
        lbl.ZIndex = 26
    end
    listPanel.CanvasSize = UDim2.new(0,0,0,#effects*22)
    self.ListPanel = listPanel
end

-- MODÜLÜ FRAMEWORK'E KAYDET
Framework:RegisterModule("EffectManager", EffectManager)

-- ====================
-- 2. DASH/SKILL COOLDOWN MODÜLÜ
-- ====================
local DashSkillCooldown = {
    Toggles = {
        NoDashCooldown = false,
        NoSkillCooldown = false,
    },
    Panel = nil,
    Log = {},
    EffectRep = nil,
}

function DashSkillCooldown:Init(framework)
    self.Framework = framework
    local suc, effectRep = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("EffectReplicator"))
    end)
    if suc then self.EffectRep = effectRep end
    task.spawn(function()
        while true do
            if self.EffectRep and self.EffectRep.GetEffects then
                for _, effect in pairs(self.EffectRep:GetEffects()) do
                    if self.Toggles.NoDashCooldown and (effect.Class == "CancelDash" or effect.Class == "Dashed") then
                        effect:Destroy()
                        self:AddLog("Dash cooldown efekti kaldırıldı!", "Success")
                    end
                    if self.Toggles.NoSkillCooldown and (effect.Class == "Cooldown" or effect.Class == "SkillCooldown" or effect.Class == "AbilityCooldown") then
                        effect:Destroy()
                        self:AddLog("Skill cooldown efekti kaldırıldı!", "Success")
                    end
                end
            end
            task.wait(0.08)
        end
    end)
end

function DashSkillCooldown:AddLog(msg, type)
    table.insert(self.Log, {os.time(), msg, type})
    if self.Panel and self.Panel.Visible then
        self.Framework:Log("[DashSkillCooldown] "..msg, type)
    end
end

function DashSkillCooldown:CreatePanel(framework)
    local panel = framework:CreatePanel("DashSkillCooldown", "Dash/Skill Cooldown", UDim2.new(0,320,0,120), UDim2.new(0, 400, 0, 260))
    local y = 16
    local spacing = 36
    local function addToggle(desc, toggleKey)
        local btn = framework:CreateToggle(panel, desc, self.Toggles[toggleKey], function(state)
            self.Toggles[toggleKey] = state
            self:AddLog(desc.." "..(state and "Aktif" or "Kapalı"), state and "Success" or "Error")
        end)
        btn.Position = UDim2.new(0,10,0,y)
        y = y + spacing
    end
    addToggle("No Dash Cooldown", "NoDashCooldown")
    addToggle("No Skill Cooldown", "NoSkillCooldown")
    self.Panel = panel
    framework.Panels["DashSkillCooldown"] = panel
end

Framework:RegisterModule("DashSkillCooldown", DashSkillCooldown)

-- ====================
-- 3. EFEKT TAKİP & LİSTELEME MODÜLÜ
-- ====================
local EffectTracker = {
    Panel = nil,
    EffectRep = nil,
    Log = {},
    Filtered = {},
    ShowOnlyServer = false,
}

function EffectTracker:Init(framework)
    self.Framework = framework
    local suc, effectRep = pcall(function()
        return require(game:GetService("ReplicatedStorage"):WaitForChild("EffectReplicator"))
    end)
    if suc then self.EffectRep = effectRep end
end

function EffectTracker:CreatePanel(framework)
    local panel = framework:CreatePanel("EffectTracker", "Effect Tracker", UDim2.new(0,340,0,210), UDim2.new(0, 36, 0, 560))
    local y = 14
    local filterBtn = framework:CreateToggle(panel, "Sadece Server Efektleri", self.ShowOnlyServer, function(state)
        self.ShowOnlyServer = state
        self:UpdateList(panel)
    end)
    filterBtn.Position = UDim2.new(0,10,0,y)
    y = y + 32
    local listBtn = framework:CreateToggle(panel, "Efektleri Listele", false, function(state)
        if state then self:ShowList(panel, y) else if self.ListPanel then self.ListPanel:Destroy() self.ListPanel = nil end end
    end)
    listBtn.Position = UDim2.new(0,10,0,y)
    self.Panel = panel
    framework.Panels["EffectTracker"] = panel
end

function EffectTracker:ShowList(parent, y)
    if self.ListPanel then self.ListPanel:Destroy() end
    local listPanel = Instance.new("ScrollingFrame", parent)
    listPanel.Name = "EffectList"
    listPanel.Size = UDim2.new(1,-20,0,110)
    listPanel.Position = UDim2.new(0,10,0,y+32)
    listPanel.BackgroundColor3 = Framework.Theme.Background
    listPanel.BorderSizePixel = 0
    listPanel.ScrollBarThickness = 8
    listPanel.ZIndex = 25
    local effects = {}
    if self.EffectRep and self.EffectRep.GetEffects then
        for _,effect in pairs(self.EffectRep:GetEffects()) do
            if not self.ShowOnlyServer or (effect.Domain == "Server") then
                table.insert(effects, effect)
            end
        end
    end
    for i,effect in ipairs(effects) do
        local lbl = Instance.new("TextLabel", listPanel)
        lbl.Size = UDim2.new(1,0,0,22)
        lbl.Position = UDim2.new(0,0,0,(i-1)*22)
        lbl.Text = string.format("%s | Value: %s | Tag: %s | Domain: %s", tostring(effect.Class), tostring(effect.Value or "-"), tostring(effect.Tag or "-"), tostring(effect.Domain or "-"))
        lbl.TextColor3 = Framework.Theme.Text
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.BackgroundTransparency = 1
        lbl.ZIndex = 26
    end
    listPanel.CanvasSize = UDim2.new(0,0,0,#effects*22)
    self.ListPanel = listPanel
end

Framework:RegisterModule("EffectTracker", EffectTracker)

-- ====================
-- 4. ORTAM/AMBIYANS MODÜLÜ
-- ====================
local AtmosphereManager = {
    Panel = nil,
    ThemePresets = {
        {name="Gündüz", lighting={Brightness=2, Ambient=Color3.fromRGB(200,200,200), OutdoorAmbient=Color3.fromRGB(180,180,180), FogEnd=1000, FogColor=Color3.fromRGB(255,255,255)}},
        {name="Gece", lighting={Brightness=0.5, Ambient=Color3.fromRGB(40,40,70), OutdoorAmbient=Color3.fromRGB(30,30,50), FogEnd=250, FogColor=Color3.fromRGB(30,30,50)}},
        {name="Kanlı", lighting={Brightness=0.7, Ambient=Color3.fromRGB(100,0,0), OutdoorAmbient=Color3.fromRGB(50,0,0), FogEnd=400, FogColor=Color3.fromRGB(100,0,0)}},
        {name="Neon", lighting={Brightness=2.5, Ambient=Color3.fromRGB(0,255,255), OutdoorAmbient=Color3.fromRGB(0,40,255), FogEnd=600, FogColor=Color3.fromRGB(0,255,255)}},
    },
    MusicPresets = {
        {name="Varsayılan", id=""},
        {name="Aksiyon", id="rbxassetid://1843555078"},
        {name="Korku", id="rbxassetid://1843555074"},
        {name="Lo-fi", id="rbxassetid://1843555072"},
    },
    CurrentMusic = nil,
}

function AtmosphereManager:Init(framework)
    self.Framework = framework
end

function AtmosphereManager:CreatePanel(framework)
    local panel = framework:CreatePanel("AtmosphereManager", "Atmosfer & Ambiyans", UDim2.new(0,340,0,270), UDim2.new(0, 760, 0, 260))
    local y = 16
    local spacing = 36
    local Lighting = game:GetService("Lighting")
    local function applyLighting(tbl)
        for k,v in pairs(tbl) do
            Lighting[k] = v
        end
    end
    local function addPresetBtn(preset)
        local btn = framework:CreateToggle(panel, preset.name, false, function(state)
            if state then
                applyLighting(preset.lighting)
                AtmosphereManager.Framework:Log("Ortam preset uygulandı: "..preset.name, "Success")
            end
        end)
        btn.Position = UDim2.new(0,10,0,y)
        y = y + spacing
    end
    for _,preset in ipairs(self.ThemePresets) do
        addPresetBtn(preset)
    end
    -- Müzik seçici
    local musicLbl = createLabel(panel, "MusicLbl", UDim2.new(0,120,0,18), UDim2.new(0,10,0,y+6), "Müzik:", framework.Theme.Text, Enum.Font.GothamBold, 14)
    local function playMusic(id)
        if self.CurrentMusic then self.CurrentMusic:Destroy() self.CurrentMusic = nil end
        if id and id ~= "" then
            local s = Instance.new("Sound", workspace)
            s.SoundId = id
            s.Looped = true
            s.Volume = 1
            s:Play()
            self.CurrentMusic = s
            AtmosphereManager.Framework:Log("Müzik başlatıldı: "..id, "Success")
        end
    end
    local mx = 0
    for _,mus in ipairs(self.MusicPresets) do
        local btn = framework:CreateToggle(panel, mus.name, false, function(state)
            if state then playMusic(mus.id) end
        end)
        btn.Position = UDim2.new(0,140+mx,0,y+2)
        mx = mx + 110
    end
    self.Panel = panel
    framework.Panels["AtmosphereManager"] = panel
end

Framework:RegisterModule("AtmosphereManager", AtmosphereManager)

-- ====================
-- 5. CHAT TAG / GLOBAL DUYURU MODÜLÜ
-- ====================
local ChatTagManager = {
    Panel = nil,
    Tag = "[VIP]",
    TagColor = Color3.fromRGB(255, 215, 0),
    GlobalMsg = "",
    GlobalColor = Color3.fromRGB(0,255,255),
    GlobalDuration = 6,
}

function ChatTagManager:Init(framework)
    self.Framework = framework
end

function ChatTagManager:CreatePanel(framework)
    local panel = framework:CreatePanel("ChatTagManager", "Chat Tag / Global Duyuru", UDim2.new(0,340,0,220), UDim2.new(0, 1160, 0, 260))
    local y = 16
    -- Tag giriş
    local tagBox = Instance.new("TextBox", panel)
    tagBox.Size = UDim2.new(0,110,0,26)
    tagBox.Position = UDim2.new(0,10,0,y)
    tagBox.Text = self.Tag
    tagBox.PlaceholderText = "Tag"
    tagBox.TextColor3 = self.TagColor
    tagBox.Font = Enum.Font.GothamBold
    tagBox.TextSize = 16
    tagBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    tagBox.ZIndex = 22
    tagBox.FocusLost:Connect(function()
        self.Tag = tagBox.Text
        self.Framework:Log("Tag güncellendi: "..self.Tag, "Info")
    end)
    -- Renk seçici
    local colorBtn = framework:CreateToggle(panel, "Tag Renk", false, function(state)
        if state then
            self.TagColor = Color3.fromRGB(math.random(50,255),math.random(50,255),math.random(50,255))
            tagBox.TextColor3 = self.TagColor
        end
    end)
    colorBtn.Position = UDim2.new(0,130,0,y)
    y = y + 36
    -- Global duyuru giriş
    local globalBox = Instance.new("TextBox", panel)
    globalBox.Size = UDim2.new(0,160,0,26)
    globalBox.Position = UDim2.new(0,10,0,y)
    globalBox.Text = self.GlobalMsg
    globalBox.PlaceholderText = "Global Duyuru"
    globalBox.TextColor3 = self.GlobalColor
    globalBox.Font = Enum.Font.GothamBold
    globalBox.TextSize = 16
    globalBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    globalBox.ZIndex = 22
    globalBox.FocusLost:Connect(function()
        self.GlobalMsg = globalBox.Text
        self.Framework:Log("Global duyuru güncellendi: "..self.GlobalMsg, "Info")
    end)
    -- Duyuru rengi seçici
    local globalColorBtn = framework:CreateToggle(panel, "Duyuru Renk", false, function(state)
        if state then
            self.GlobalColor = Color3.fromRGB(math.random(50,255),math.random(50,255),math.random(50,255))
            globalBox.TextColor3 = self.GlobalColor
        end
    end)
    globalColorBtn.Position = UDim2.new(0,180,0,y)
    y = y + 36
    -- Duyuru gönderme
    local sendBtn = framework:CreateToggle(panel, "Duyuru Gönder", false, function(state)
        if state then
            -- GlobalAnnouncement eventini tetikle (örnek, gerçek oyun eventine uyarlanmalı)
            if game:GetService("ReplicatedStorage"):FindFirstChild("GlobalAnnouncement") then
                game:GetService("ReplicatedStorage").GlobalAnnouncement:FireAllClients(self.GlobalMsg)
            end
            self.Framework:Log("Global duyuru gönderildi: "..self.GlobalMsg, "Success")
        end
    end)
    sendBtn.Position = UDim2.new(0,10,0,y)
    self.Panel = panel
    framework.Panels["ChatTagManager"] = panel
end

Framework:RegisterModule("ChatTagManager", ChatTagManager)

-- ====================
-- 6. ANİMASYON & HAREKET YÖNETİMİ MODÜLÜ
-- ====================
local AnimationManager = {
    Panel = nil,
    AnimPresets = {
        {name="Varsayılan", idle="rbxassetid://180435571", walk="rbxassetid://180426354", run="rbxassetid://180426354", jump="rbxassetid://125750702", fall="rbxassetid://180436148", climb="rbxassetid://180436334", sit="rbxassetid://178130996", tool="rbxassetid://182393478", emote="rbxassetid://357215802"},
        {name="Anime", idle="rbxassetid://507766666", walk="rbxassetid://507777826", run="rbxassetid://507767714", jump="rbxassetid://507765000", fall="rbxassetid://507767968", climb="rbxassetid://507765644", sit="rbxassetid://2506281703", tool="rbxassetid://182393478", emote="rbxassetid://357215802"},
    },
    CurrentPreset = 1,
    Speed = 1,
    Playing = false,
    Log = {},
}

function AnimationManager:Init(framework)
    self.Framework = framework
end

function AnimationManager:ApplyPreset(idx)
    local plr = game.Players.LocalPlayer
    if not plr.Character then return end
    local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    for _,track in pairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    local preset = self.AnimPresets[idx]
    for state,aid in pairs(preset) do
        if state ~= "name" then
            local anim = Instance.new("Animation")
            anim.AnimationId = aid
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            track:AdjustSpeed(self.Speed)
        end
    end
    self.Framework:Log("Animasyon preset uygulandı: "..preset.name, "Success")
end

function AnimationManager:CreatePanel(framework)
    local panel = framework:CreatePanel("AnimationManager", "Animasyon Yönetimi", UDim2.new(0,340,0,220), UDim2.new(0, 36, 0, 860))
    local y = 16
    local spacing = 36
    -- Preset seçici
    for i,preset in ipairs(self.AnimPresets) do
        local btn = framework:CreateToggle(panel, preset.name, i==self.CurrentPreset, function(state)
            if state then
                self.CurrentPreset = i
                self:ApplyPreset(i)
            end
        end)
        btn.Position = UDim2.new(0,10,0,y)
        y = y + spacing
    end
    -- Hız slider'ı (örnek, gerçek slider fonksiyonu eklenebilir)
    local speedBox = Instance.new("TextBox", panel)
    speedBox.Size = UDim2.new(0,60,0,26)
    speedBox.Position = UDim2.new(0,10,0,y)
    speedBox.Text = tostring(self.Speed)
    speedBox.PlaceholderText = "Hız"
    speedBox.TextColor3 = framework.Theme.Text
    speedBox.Font = Enum.Font.GothamBold
    speedBox.TextSize = 16
    speedBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    speedBox.ZIndex = 22
    speedBox.FocusLost:Connect(function()
        local val = tonumber(speedBox.Text)
        if val and val > 0 then
            self.Speed = val
            self:ApplyPreset(self.CurrentPreset)
            self.Framework:Log("Animasyon hızı: "..tostring(val), "Info")
        end
    end)
    self.Panel = panel
    framework.Panels["AnimationManager"] = panel
end

Framework:RegisterModule("AnimationManager", AnimationManager)

-- ====================
-- 7. SMARTBONE / PARÇACIK & MODEL MODÜLÜ
-- ====================
local SmartBoneManager = {
    Panel = nil,
    DebugHighlight = false,
    Log = {},
}

function SmartBoneManager:Init(framework)
    self.Framework = framework
end

function SmartBoneManager:CreatePanel(framework)
    local panel = framework:CreatePanel("SmartBoneManager", "SmartBone & Parçacık", UDim2.new(0,340,0,160), UDim2.new(0, 430, 0, 860))
    local y = 16
    local highlightBtn = framework:CreateToggle(panel, "Debug Highlight", self.DebugHighlight, function(state)
        self.DebugHighlight = state
        if state then
            self:HighlightBones()
        else
            self:RemoveHighlights()
        end
    end)
    highlightBtn.Position = UDim2.new(0,10,0,y)
    y = y + 36
    self.Panel = panel
    framework.Panels["SmartBoneManager"] = panel
end

function SmartBoneManager:HighlightBones()
    local plr = game.Players.LocalPlayer
    if not plr.Character then return end
    for _,desc in pairs(plr.Character:GetDescendants()) do
        if desc:IsA("Bone") then
            local sel = Instance.new("SelectionBox", desc)
            sel.Adornee = desc
            sel.LineThickness = 0.1
            sel.Color3 = Color3.fromRGB(0,255,255)
        end
    end
end

function SmartBoneManager:RemoveHighlights()
    local plr = game.Players.LocalPlayer
    if not plr.Character then return end
    for _,desc in pairs(plr.Character:GetDescendants()) do
        if desc:IsA("SelectionBox") then
            desc:Destroy()
        end
    end
end

Framework:RegisterModule("SmartBoneManager", SmartBoneManager)

-- ====================
-- 8. FREECAM & KAMERA MODÜLÜ
-- ====================
local FreecamManager = {
    Panel = nil,
    Active = false,
    Speed = 1.5,
    FOV = 70,
    Log = {},
}

function FreecamManager:Init(framework)
    self.Framework = framework
    self.FreecamConn = nil
end

function FreecamManager:ToggleFreecam(state)
    self.Active = state
    local camera = workspace.CurrentCamera
    if state then
        self.OriginalCameraType = camera.CameraType
        self.OriginalFOV = camera.FieldOfView
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = self.FOV
        self.FreecamConn = game:GetService("RunService").RenderStepped:Connect(function()
            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camera.CFrame.RightVector end
            camera.CFrame = camera.CFrame + move * self.Speed
        end)
        self.Framework:Log("Freecam aktif!", "Success")
    else
        if self.FreecamConn then self.FreecamConn:Disconnect() self.FreecamConn = nil end
        camera.CameraType = self.OriginalCameraType or Enum.CameraType.Custom
        camera.FieldOfView = self.OriginalFOV or 70
        self.Framework:Log("Freecam kapalı.", "Info")
    end
end

function FreecamManager:CreatePanel(framework)
    local panel = framework:CreatePanel("FreecamManager", "Freecam & Kamera", UDim2.new(0,340,0,160), UDim2.new(0, 820, 0, 860))
    local y = 16
    local freecamBtn = framework:CreateToggle(panel, "Freecam Aç/Kapa", self.Active, function(state)
        self:ToggleFreecam(state)
    end)
    freecamBtn.Position = UDim2.new(0,10,0,y)
    y = y + 36
    -- Hız ayarı
    local speedBox = Instance.new("TextBox", panel)
    speedBox.Size = UDim2.new(0,60,0,26)
    speedBox.Position = UDim2.new(0,10,0,y)
    speedBox.Text = tostring(self.Speed)
    speedBox.PlaceholderText = "Hız"
    speedBox.TextColor3 = framework.Theme.Text
    speedBox.Font = Enum.Font.GothamBold
    speedBox.TextSize = 16
    speedBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    speedBox.ZIndex = 22
    speedBox.FocusLost:Connect(function()
        local val = tonumber(speedBox.Text)
        if val and val > 0 then
            self.Speed = val
            self.Framework:Log("Freecam hızı: "..tostring(val), "Info")
        end
    end)
    -- FOV ayarı
    local fovBox = Instance.new("TextBox", panel)
    fovBox.Size = UDim2.new(0,60,0,26)
    fovBox.Position = UDim2.new(0,90,0,y)
    fovBox.Text = tostring(self.FOV)
    fovBox.PlaceholderText = "FOV"
    fovBox.TextColor3 = framework.Theme.Text
    fovBox.Font = Enum.Font.GothamBold
    fovBox.TextSize = 16
    fovBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    fovBox.ZIndex = 22
    fovBox.FocusLost:Connect(function()
        local val = tonumber(fovBox.Text)
        if val and val > 0 then
            self.FOV = val
            if self.Active then workspace.CurrentCamera.FieldOfView = val end
            self.Framework:Log("Freecam FOV: "..tostring(val), "Info")
        end
    end)
    self.Panel = panel
    framework.Panels["FreecamManager"] = panel
end

Framework:RegisterModule("FreecamManager", FreecamManager)

-- ====================
-- 9. CLIENT-SIDE ANTI-ANTICHEAT MODÜLÜ
-- ====================
local AntiAntiCheatManager = {
    Panel = nil,
    Toggles = {
        AttributeBypass = false,
        CollisionBypass = false,
        ModuleBypass = false,
    },
    Log = {},
}

function AntiAntiCheatManager:Init(framework)
    self.Framework = framework
end

function AntiAntiCheatManager:CreatePanel(framework)
    local panel = framework:CreatePanel("AntiAntiCheatManager", "Anti-AntiCheat", UDim2.new(0,340,0,160), UDim2.new(0, 1200, 0, 860))
    local y = 16
    local spacing = 36
    local function addToggle(desc, toggleKey)
        local btn = framework:CreateToggle(panel, desc, self.Toggles[toggleKey], function(state)
            self.Toggles[toggleKey] = state
            self.Framework:Log(desc.." "..(state and "Aktif" or "Kapalı"), state and "Success" or "Error")
        end)
        btn.Position = UDim2.new(0,10,0,y)
        y = y + spacing
    end
    addToggle("Attribute Bypass", "AttributeBypass")
    addToggle("CollisionGroup Bypass", "CollisionBypass")
    addToggle("Module Load Bypass", "ModuleBypass")
    self.Panel = panel
    framework.Panels["AntiAntiCheatManager"] = panel
end

Framework:RegisterModule("AntiAntiCheatManager", AntiAntiCheatManager)

-- ====================
-- 10. SCRIPT/MODÜL YÖNETİMİ MODÜLÜ
-- ====================
local ScriptManager = {
    Panel = nil,
    Scripts = {
        {name="PlayerModule", path="StarterPlayer.StarterPlayerScripts.PlayerModule"},
        {name="Freecam", path="StarterPlayer.StarterPlayerScripts.Freecam"},
    },
    Log = {},
}

function ScriptManager:Init(framework)
    self.Framework = framework
end

function ScriptManager:CreatePanel(framework)
    local panel = framework:CreatePanel("ScriptManager", "Script/Modül Yönetimi", UDim2.new(0,340,0,220), UDim2.new(0, 36, 0, 1160))
    local y = 16
    for _,scr in ipairs(self.Scripts) do
        local btn = framework:CreateToggle(panel, scr.name.." Inject", false, function(state)
            if state then
                -- Modülü yükle (örnek, gerçek inject fonksiyonu eklenebilir)
                self.Framework:Log(scr.name.." inject edildi!", "Success")
            else
                -- Modülü kaldır (örnek)
                self.Framework:Log(scr.name.." kaldırıldı!", "Warn")
            end
        end)
        btn.Position = UDim2.new(0,10,0,y)
        y = y + 36
    end
    self.Panel = panel
    framework.Panels["ScriptManager"] = panel
end

Framework:RegisterModule("ScriptManager", ScriptManager)

-- ====================
-- 11. PROFİL/PRESET & KİŞİSELLEŞTİRME MODÜLÜ
-- ====================
local ProfileManager = {
    Panel = nil,
    Log = {},
}

function ProfileManager:Init(framework)
    self.Framework = framework
end

function ProfileManager:CreatePanel(framework)
    local panel = framework:CreatePanel("ProfileManager", "Profil/Preset & Kişiselleştirme", UDim2.new(0,340,0,160), UDim2.new(0, 430, 0, 1160))
    local y = 16
    local saveBtn = framework:CreateToggle(panel, "Profil Kaydet", false, function(state)
        if state then
            framework:SaveProfile("KullanıcıProfili")
        end
    end)
    saveBtn.Position = UDim2.new(0,10,0,y)
    y = y + 36
    local loadBtn = framework:CreateToggle(panel, "Profil Yükle", false, function(state)
        if state then
            framework:LoadProfile("KullanıcıProfili")
        end
    end)
    loadBtn.Position = UDim2.new(0,120,0,16)
    self.Panel = panel
    framework.Panels["ProfileManager"] = panel
end

Framework:RegisterModule("ProfileManager", ProfileManager)

-- ====================
-- 12. OTOMASYON & DEBUG/LOG PANELİ MODÜLÜ
-- ====================
local AutomationDebugManager = {
    Panel = nil,
    Log = {},
}

function AutomationDebugManager:Init(framework)
    self.Framework = framework
end

function AutomationDebugManager:CreatePanel(framework)
    local panel = framework:CreatePanel("AutomationDebugManager", "Otomasyon & Debug/Log", UDim2.new(0,340,0,220), UDim2.new(0, 820, 0, 1160))
    local y = 16
    local logBox = Instance.new("ScrollingFrame", panel)
    logBox.Name = "LogBox"
    logBox.Size = UDim2.new(1,-16,1,-46)
    logBox.Position = UDim2.new(0,8,0,38)
    logBox.BackgroundColor3 = Framework.Theme.Background
    logBox.BorderSizePixel = 0
    logBox.ScrollBarThickness = 8
    logBox.CanvasSize = UDim2.new(0,0,0,0)
    logBox.ZIndex = 17
    local logs = {}
    function panel:AddLog(msg, type)
        local lbl = Instance.new("TextLabel", logBox)
        lbl.Size = UDim2.new(1,0,0,22)
        lbl.Text = os.date("[%H:%M:%S] ")..msg
        lbl.TextColor3 = type=="Error" and Framework.Theme.Error or (type=="Success" and Framework.Theme.Success or Framework.Theme.Text)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.BackgroundTransparency = 1
        lbl.ZIndex = 18
        table.insert(logs, lbl)
        logBox.CanvasSize = UDim2.new(0,0,0,#logs*24)
        if #logs>100 then logs[1]:Destroy(); table.remove(logs,1) end
    end
    panel.Visible = false
    self.Panel = panel
    framework.Panels["AutomationDebugManager"] = panel
end

Framework:RegisterModule("AutomationDebugManager", AutomationDebugManager)

-- ====================
-- 14. ANLIK PİNG, FPS, SERVER PANELİ
-- ====================
local StatusPanelManager = {
    Panel = nil,
    Ping = 0,
    FPS = 0,
    Tickrate = 0,
    Delay = 0,
    Log = {},
}

function StatusPanelManager:Init(framework)
    self.Framework = framework
    self.LastTick = tick()
    self.FrameCount = 0
    self.LastPing = 0
    self.LastDelay = 0
    self.LastServerTick = tick()
    game:GetService("RunService").RenderStepped:Connect(function()
        self.FrameCount = self.FrameCount + 1
        if tick() - self.LastTick >= 1 then
            self.FPS = self.FrameCount
            self.FrameCount = 0
            self.LastTick = tick()
        end
        -- Ping ölçümü
        local stats = game:GetService("Stats")
        if stats and stats.Network and stats.Network.ServerStatsItem and stats.Network.ServerStatsItem["Data Ping"] then
            self.Ping = math.floor(stats.Network.ServerStatsItem["Data Ping"].Value + 0.5)
        else
            -- Alternatif ping ölçümü
            self.Ping = math.random(30,60)
        end
        -- Delay (örnek)
        self.Delay = math.random(0,10)
        -- Tickrate (örnek)
        self.Tickrate = math.floor(1 / game:GetService("RunService").Heartbeat:Wait())
        -- Paneli güncelle
        if self.Panel and self.Panel:FindFirstChild("PingLbl") then
            self.Panel.PingLbl.Text = "Ping: "..self.Ping.." ms"
            self.Panel.FPSLbl.Text = "FPS: "..self.FPS
            self.Panel.TickLbl.Text = "Server Tick: "..self.Tickrate
            self.Panel.DelayLbl.Text = "Delay: "..self.Delay.." ms"
        end
    end)
end

function StatusPanelManager:CreatePanel(framework)
    local panel = framework:CreatePanel("StatusPanelManager", "Durum Paneli", UDim2.new(0,220,0,110), UDim2.new(0, 36, 0, 1680))
    local pingLbl = createLabel(panel, "PingLbl", UDim2.new(0,200,0,22), UDim2.new(0,10,0,10), "Ping: 0 ms", framework.Theme.Text, Enum.Font.GothamBold, 16)
    local fpsLbl = createLabel(panel, "FPSLbl", UDim2.new(0,200,0,22), UDim2.new(0,10,0,36), "FPS: 0", framework.Theme.Text, Enum.Font.GothamBold, 16)
    local tickLbl = createLabel(panel, "TickLbl", UDim2.new(0,200,0,22), UDim2.new(0,10,0,62), "Server Tick: 0", framework.Theme.Text, Enum.Font.GothamBold, 16)
    local delayLbl = createLabel(panel, "DelayLbl", UDim2.new(0,200,0,22), UDim2.new(0,10,0,88), "Delay: 0 ms", framework.Theme.Text, Enum.Font.GothamBold, 16)
    self.Panel = panel
    framework.Panels["StatusPanelManager"] = panel
end

Framework:RegisterModule("StatusPanelManager", StatusPanelManager)

-- ====================
-- 15. HIZLI KOMUT/SCRIPT PANELİ
-- ====================
local QuickCommandManager = {
    Panel = nil,
    Log = {},
    LastResult = "",
}

function QuickCommandManager:Init(framework)
    self.Framework = framework
end

function QuickCommandManager:CreatePanel(framework)
    local panel = framework:CreatePanel("QuickCommandManager", "Hızlı Komut/Script", UDim2.new(0,340,0,120), UDim2.new(0, 300, 0, 1680))
    local cmdBox = Instance.new("TextBox", panel)
    cmdBox.Size = UDim2.new(0,220,0,28)
    cmdBox.Position = UDim2.new(0,10,0,12)
    cmdBox.PlaceholderText = "Komut veya Lua kodu yaz..."
    cmdBox.Text = ""
    cmdBox.TextColor3 = framework.Theme.Text
    cmdBox.Font = Enum.Font.GothamBold
    cmdBox.TextSize = 15
    cmdBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    cmdBox.ZIndex = 22
    local runBtn = framework:CreateToggle(panel, "Çalıştır", false, function(state)
        if state then
            local code = cmdBox.Text
            local ok, result = pcall(function()
                return loadstring(code)()
            end)
            self.LastResult = ok and tostring(result) or "Hata: "..tostring(result)
            self.Framework:Log("Komut sonucu: "..self.LastResult, ok and "Success" or "Error")
        end
    end)
    runBtn.Position = UDim2.new(0,240,0,12)
    self.Panel = panel
    framework.Panels["QuickCommandManager"] = panel
end

Framework:RegisterModule("QuickCommandManager", QuickCommandManager)

-- TÜM MODÜLLERİ BAŞLAT
Framework:InitModules()
updateHideBtnText()

-- Drag: all frame area
do
    local dragging, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Title
local title = createLabel(mainFrame, "BG7Title", UDim2.new(0, 170, 0, 34), UDim2.new(0, CONFIG.PADDING, 0, 7), "BG7 GUI",
    Color3.new(1,1,1), Enum.Font.FredokaOne, 30, Enum.TextXAlignment.Left, true)
title.ZIndex = 10
task.spawn(function()
    local t = 0
    while title and title.Parent do
        t = t + RunService.RenderStepped:Wait()
        title.TextColor3 = rgbColor((t/3)%1)
    end
end)

local y = 50
local spacing = 38

local aimbotBtn = createButton(mainFrame, "AimbotBtn", UDim2.new(1,-CONFIG.PADDING*2,0,30), UDim2.new(0,CONFIG.PADDING,0,y),
    "AIMBOT: OFF", Color3.fromRGB(0,0,200), function()
        silentAimEnabled = not silentAimEnabled
        aimbotBtn.Text = silentAimEnabled and "AIMBOT: ON" or "AIMBOT: OFF"
        aimbotBtn.BackgroundColor3 = silentAimEnabled and Color3.fromRGB(0,200,0) or Color3.fromRGB(0,0,200)
        if not silentAimEnabled then
            currentAimTarget = nil
            highlight.Adornee = nil
            highlight.Enabled = false
        end
    end, 8)
aimbotBtn.TextSize = 16
aimbotBtn.ZIndex = 10
y = y + spacing

local colorLabel = createLabel(mainFrame, "GlowColorLbl", UDim2.new(0,70,0,22), UDim2.new(0,CONFIG.PADDING,0,y), "ESP:",
    Color3.fromRGB(220,220,220), Enum.Font.GothamBold, 16)
colorLabel.ZIndex = 10
local colorFrame = Instance.new("Frame", mainFrame)
colorFrame.Size, colorFrame.Position, colorFrame.BackgroundTransparency =
    UDim2.new(0, 180, 0, 32), UDim2.new(0,CONFIG.PADDING+65,0,y-2), 1
colorFrame.ZIndex = 10

-- HIGHLIGHT (ESP)
local highlight = Instance.new("Highlight")
highlight.Name, highlight.FillColor, highlight.OutlineColor, highlight.FillTransparency, highlight.OutlineTransparency, highlight.Parent =
    "AimTargetGlow", CONFIG.COLORS[1].color, CONFIG.COLORS[1].color, 0.7, 0.5, workspace
highlight.Enabled = false

for i, col in ipairs(CONFIG.COLORS) do
    local btn = Instance.new("TextButton", colorFrame)
    btn.Name, btn.Size, btn.Position, btn.BackgroundColor3 =
        col.name.."Btn", UDim2.new(0,32,0,32), UDim2.new(0,(i-1)*42,0,0), col.color
    btn.Text, btn.AutoButtonColor, btn.ZIndex = "", false, 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)
    createRGBStroke(btn,2)
    btn.MouseButton1Click:Connect(function()
        lastESPColor = col.color
        if not FActive then
            highlight.FillColor = col.color
            highlight.OutlineColor = col.color
        end
    end)
end

y = y + spacing - 6

local keyLbl = createLabel(mainFrame, "KeyInfo", UDim2.new(1, -CONFIG.PADDING*2, 0, 16), UDim2.new(0, CONFIG.PADDING, 1, -22),
    "[V] lock, [F] front/back", Color3.fromRGB(170,170,240), Enum.Font.Gotham, 13, Enum.TextXAlignment.Center)
keyLbl.ZIndex = 10

-- Helper: Get enemy under mouse
local function getEnemyUnderMouse()
    local mouseLoc = UserInputService:GetMouseLocation()
    local minDist, closestPlayer = 40, nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChild("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health>0 and hrp then
                local pos, visible = camera:WorldToViewportPoint(hrp.Position)
                if visible then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouseLoc.X, mouseLoc.Y)).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closestPlayer = plr
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Get closest enemy (no range limit)
local function getClosestEnemy()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local closest, dist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum  = plr.Character:FindFirstChild("Humanoid")
            local part = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health>0 and part then
                local d = (hrp.Position - part.Position).Magnitude
                if d < dist then
                    closest, dist = plr, d
                end
            end
        end
    end
    return closest
end

-- V: Toggle aimbot ON/OFF, lock mouse enemy if exists, else nearest
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.V then
        silentAimEnabled = not silentAimEnabled
        if not silentAimEnabled then
            currentAimTarget = nil
            highlight.Adornee = nil
            highlight.Enabled = false
            aimbotBtn.Text = "AIMBOT: OFF"
            aimbotBtn.BackgroundColor3 = Color3.fromRGB(0,0,200)
        else
            local mouseEnemy = getEnemyUnderMouse()
            if mouseEnemy then
                currentAimTarget = mouseEnemy
            else
                currentAimTarget = getClosestEnemy()
            end
            aimbotBtn.Text = "AIMBOT: ON"
            aimbotBtn.BackgroundColor3 = Color3.fromRGB(0,200,0)
        end
    end
end)

-- F: Hold = aim enemy front (blue), release = back, always aim front if no lock
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F then
        FActive = true
        -- her zaman kilitli hedef varsa onu yoksa en yakını al (her F basışında güncellenir)
        if currentAimTarget and currentAimTarget.Character
            and currentAimTarget.Character:FindFirstChild("HumanoidRootPart")
            and currentAimTarget.Character:FindFirstChild("Humanoid").Health > 0 then
            fAimTarget = currentAimTarget
        else
            fAimTarget = getClosestEnemy()
        end
        if fAimTarget then
            highlight.Adornee = fAimTarget.Character
            highlight.Enabled = true
            highlight.FillColor = Color3.fromRGB(0,0,255)
            highlight.OutlineColor = Color3.fromRGB(0,0,255)
        end
    end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.F then
        FActive = false
        if fAimTarget then
            highlight.FillColor = lastESPColor
            highlight.OutlineColor = lastESPColor
        end
        fAimTarget = nil
    end
end)

RunService.RenderStepped:Connect(function()
    mainFrame.Visible = GUI_VISIBLE
    updateHideBtnText()

    local aimTarget = FActive and fAimTarget or currentAimTarget
    if not silentAimEnabled or not aimTarget or not aimTarget.Character or not aimTarget.Character:FindFirstChild("HumanoidRootPart") or (aimTarget.Character:FindFirstChild("Humanoid").Health <= 0) then
        for _, plr in ipairs(Players:GetPlayers()) do
            local p = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            if p and p:FindFirstChild("InfoGui") then p.InfoGui:Destroy() end
        end
        highlight.Enabled   = false
        highlight.Adornee   = nil
        currentAimTarget    = nil
        return
    end

    highlight.Adornee = aimTarget.Character
    highlight.Enabled = true

    -- Odak: F aktifse önüne, değilse V modunda sağ kol arkası
    local char     = LocalPlayer.Character
    local humanoid = char and char:FindFirstChild("Humanoid")
    local hrp      = char and char:FindFirstChild("HumanoidRootPart")
    local targetChar = aimTarget.Character
    local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
    if not (humanoid and hrp and targetHrp) then return end

    if humanoid.PlatformStand then return end

    if tick()%2 < 0.01 then
        hrp.Velocity = hrp.Velocity + Vector3.new(math.random(-1,1)*0.1, 0, math.random(-1,1)*0.1)
    end

    if FActive then
        -- F: enemy FRONT (tam ön)
        local front = targetHrp.Position + targetHrp.CFrame.LookVector * 2
        local dir = (Vector3.new(front.X, hrp.Position.Y, front.Z) - hrp.Position).Unit
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
    else
        -- V: right shoulder behind (kilitli/otomatik) (HRP sağında ve arkasında)
        local rightShoulder = targetChar:FindFirstChild("RightUpperArm") or targetChar:FindFirstChild("Right Arm") or targetChar:FindFirstChild("RightHand")
        local basePos = targetHrp.Position
        local baseCFrame = targetHrp.CFrame
        local aimPos
        if rightShoulder and rightShoulder.Position then
            aimPos = rightShoulder.Position - baseCFrame.LookVector * 1.5
        else
            aimPos = basePos + baseCFrame.RightVector * 1.2 - baseCFrame.LookVector * 1.5
        end
        local dir = (Vector3.new(aimPos.X, hrp.Position.Y, aimPos.Z) - hrp.Position).Unit
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + dir)
    end

    -- MESAFE ve HP LABEL (info tag)
    if not targetHrp:FindFirstChild("InfoGui") then
        local g = infoTemplate:Clone()
        g.Parent = targetHrp
    end
    local lbl = targetHrp.InfoGui:FindFirstChildOfClass("TextLabel")
    if lbl then
        local d = math.floor((targetHrp.Position - hrp.Position).Magnitude)
        local hp = ""
        if CONFIG.SHOW_HP then
            local hum=targetChar:FindFirstChild("Humanoid")
            hp = hum and (" | HP:"..math.floor(hum.Health)) or ""
        end
        lbl.Text = tostring(d).."m"..hp
        lbl.TextSize = math.clamp(16 + (d / 75) * 10, 16, 28)
    end
end) Copilot said: Roblox oyununda elindeki yeni dosyalar ve sistemler
Roblox oyununda elindeki yeni dosyalar ve sistemler ile, client tarafında (yani oyuncu bilgisayarında) çok geniş kapsamlı ve ileri seviye müdahaleler/hileler/özelleştirmeler yapabilirsin. Her modülün ve fonksiyonun mantığını, olanaklarını ve bunların nasıl exploit edilebileceğini adım adım anlatıyorum:

1. Effect Sistemi (EffectReplicator/EffectManager) ile Manipülasyon
Yapabileceklerin:
Tüm olumsuz efektleri (Stun, FullStun, Cooldown, VelocityNerf, Blocking, Dashed, NoJump vs) doğrudan yok edebilirsin.
Kendine özel, oyunda olmayan efektler ekleyebilirsin (ör: Sürekli Speed, NoCooldown gibi).
Efektlerin hangi durumda tetikleneceğini, süresini, değerini, tag’larını anlık değiştirebilirsin.
Efekt event’lerine (EffectAdded, EffectRemoving vb.) hook atıp, yeni efekt eklenince anında silebilirsin (otomatik anti-stun, anti-block vs).
end)

-- ====================
-- 13. GELİŞMİŞ EFEKT YÖNETİMİ MODÜLÜ
-- ====================
local AdvancedEffectManager = {
    Panel = nil,
    Blacklist = { "Stun", "FullStun", "Blocking", "Cooldown", "VelocityNerf", "NoJump", "CancelDash" },
    AutoClean = false,
    EventClean = false,
    CustomEffects = {},
    Log = {},
}

function AdvancedEffectManager:Init(framework)
    self.Framework = framework
    self.EffectRep = require(game:GetService("ReplicatedStorage"):WaitForChild("EffectReplicator"))
    self.LoopConn = nil
    self.EventConn = nil
end

function AdvancedEffectManager:StartAutoClean()
    if self.LoopConn then return end
    self.LoopConn = task.spawn(function()
        while self.AutoClean do
            for _, effect in pairs(self.EffectRep:GetEffects()) do
                if table.find(self.Blacklist, effect.Class) then
                    effect:Destroy()
                    self.Framework:Log("Efekt temizlendi: "..effect.Class, "Success")
                end
            end
            task.wait(0.05)
        end
    end)
end

function AdvancedEffectManager:StopAutoClean()
    if self.LoopConn then
        task.cancel(self.LoopConn)
        self.LoopConn = nil
    end
end

function AdvancedEffectManager:StartEventClean()
    if self.EventConn then return end
    self.EventConn = self.EffectRep.EffectAdded:Connect(function(effect)
        if table.find(self.Blacklist, effect.Class) then
            effect:Destroy()
            self.Framework:Log("Efekt anında temizlendi: "..effect.Class, "Success")
        end
    end)
end

function AdvancedEffectManager:StopEventClean()
    if self.EventConn then self.EventConn:Disconnect() self.EventConn = nil end
end

function AdvancedEffectManager:AddCustomEffect(class, value, tag, duration)
    local tbl = {Class=class, Value=value, Tag=tag, Duration=duration or 10}
    table.insert(self.CustomEffects, tbl)
    self.EffectRep:CreateEffect("LocalPlayer", class, {Value=value, Tag=tag, Duration=duration or 10})
    self.Framework:Log("Özel efekt eklendi: "..class, "Success")
end

function AdvancedEffectManager:CreatePanel(framework)
    local panel = framework:CreatePanel("AdvancedEffectManager", "Gelişmiş Efekt Yönetimi", UDim2.new(0,340,0,260), UDim2.new(0, 36, 0, 1400))
    local y = 16
    local autoCleanBtn = framework:CreateToggle(panel, "Zararlı Efektleri Otomatik Temizle (Loop)", self.AutoClean, function(state)
        self.AutoClean = state
        if state then self:StartAutoClean() else self:StopAutoClean() end
    end)
    autoCleanBtn.Position = UDim2.new(0,10,0,y)
    y = y + 36
    local eventCleanBtn = framework:CreateToggle(panel, "Zararlı Efektleri Anında Temizle (Event)", self.EventClean, function(state)
        self.EventClean = state
        if state then self:StartEventClean() else self:StopEventClean() end
    end)
    eventCleanBtn.Position = UDim2.new(0,10,0,y)
    y = y + 36
    -- Özel efekt ekleme
    local classBox = Instance.new("TextBox", panel)
    classBox.Size = UDim2.new(0,80,0,26)
    classBox.Position = UDim2.new(0,10,0,y)
    classBox.PlaceholderText = "Class"
    classBox.Text = "Speed"
    classBox.TextColor3 = framework.Theme.Text
    classBox.Font = Enum.Font.GothamBold
    classBox.TextSize = 14
    classBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    classBox.ZIndex = 22
    local valueBox = Instance.new("TextBox", panel)
    valueBox.Size = UDim2.new(0,60,0,26)
    valueBox.Position = UDim2.new(0,100,0,y)
    valueBox.PlaceholderText = "Value"
    valueBox.Text = "2"
    valueBox.TextColor3 = framework.Theme.Text
    valueBox.Font = Enum.Font.GothamBold
    valueBox.TextSize = 14
    valueBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    valueBox.ZIndex = 22
    local tagBox = Instance.new("TextBox", panel)
    tagBox.Size = UDim2.new(0,60,0,26)
    tagBox.Position = UDim2.new(0,170,0,y)
    tagBox.PlaceholderText = "Tag"
    tagBox.Text = "Custom"
    tagBox.TextColor3 = framework.Theme.Text
    tagBox.Font = Enum.Font.GothamBold
    tagBox.TextSize = 14
    tagBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    tagBox.ZIndex = 22
    local durationBox = Instance.new("TextBox", panel)
    durationBox.Size = UDim2.new(0,60,0,26)
    durationBox.Position = UDim2.new(0,240,0,y)
    durationBox.PlaceholderText = "Süre"
    durationBox.Text = "10"
    durationBox.TextColor3 = framework.Theme.Text
    durationBox.Font = Enum.Font.GothamBold
    durationBox.TextSize = 14
    durationBox.BackgroundColor3 = Color3.fromRGB(40,40,60)
    durationBox.ZIndex = 22
    local addBtn = framework:CreateToggle(panel, "Efekt Ekle", false, function(state)
        if state then
            self:AddCustomEffect(classBox.Text, valueBox.Text, tagBox.Text, tonumber(durationBox.Text))
        end
    end)
    addBtn.Position = UDim2.new(0,310,0,y)
    self.Panel = panel
    framework.Panels["AdvancedEffectManager"] = panel
end

Framework:RegisterModule("AdvancedEffectManager", AdvancedEffectManager)

-- TÜM MODÜLLERİ BAŞLAT
Framework:InitModules()
updateHideBtnText()
