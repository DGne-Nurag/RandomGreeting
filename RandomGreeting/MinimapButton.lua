-- ==========================================================
-- RandomGreeting – Minimap-Button & Aktionsfenster
-- MinimapButton.lua  (geladen nach Options.lua)
-- ==========================================================
-- Texture-Hinweis: Das Minimap-Icon erwartet die Datei
--   Interface\AddOns\RandomGreeting\Media\minimap.tga  (oder .blp / .png)
-- Bitte eine passende "winkende Hand"-Grafik dort ablegen.
-- ==========================================================

local ADDON_NAME     = "RandomGreeting"
local MINIMAP_RADIUS = 82     -- Pixel-Abstand vom Minimap-Mittelpunkt
local BTN_W          = 100    -- Breite normal; Kompakt = BTN_W / 2
local BTN_W_COMPACT  = 50     -- Breite im Kompaktmodus
local BTN_H          = 22     -- Höhe der Aktionsfenster-Buttons
local PAD            = 6      -- Innen-Abstand des Aktionsfensters

-- Kanal-Reihenfolge für den Zyklus-Button
local CHANNELS = { "SAY", "GUILD", "PARTY", "RAID" }
local CHANNEL_COLOR = {
    SAY   = "|cffffffff",
    GUILD = "|cff00ff00",
    PARTY = "|cff00aaff",
    RAID  = "|cffff7f00",
}

-- Einzel-Buchstaben im Kompaktmodus
local CHANNEL_SHORT = { SAY = "S", GUILD = "G", PARTY = "P", RAID = "R" }

-- Forward-Deklarationen
local AWF_Frame   = nil   -- Action-Window-Frame
local MM_Button   = nil   -- Minimap-Button
local AW_ChBtn    = nil   -- Kanal-Button im Aktionsfenster
local AW_ListBtns = {}    -- Liste der Aktions-Buttons

-- ==========================================================
-- Kanal-Hilfsfunktionen
-- ==========================================================

local function GetChannel()
    return (RandomGreetingDB and RandomGreetingDB.actionWindowChannel) or "GUILD"
end

local function SetChannel(ch)
    if RandomGreetingDB then RandomGreetingDB.actionWindowChannel = ch end
end

local function NextChannel()
    local cur = GetChannel()
    for i, ch in ipairs(CHANNELS) do
        if ch == cur then
            local nxt = CHANNELS[(i % #CHANNELS) + 1]
            SetChannel(nxt)
            return nxt
        end
    end
    SetChannel("GUILD")
    return "GUILD"
end

local function ChannelLabel(ch)
    if RandomGreetingDB and RandomGreetingDB.actionWindowCompact then
        return (CHANNEL_COLOR[ch] or "") .. (CHANNEL_SHORT[ch] or ch) .. "|r"
    end
    return (CHANNEL_COLOR[ch] or "") .. (ch or "?") .. "|r"
end

-- ==========================================================
-- Nachricht senden (gleiche Pool-Logik wie das Hauptmodul)
-- ==========================================================

local function SendListMsg(listKey)
    local db = RandomGreetingDB
    local msgs, pool
    if     listKey == "HI"      then msgs, pool = db.hiMessages,      db.hiPool
    elseif listKey == "BYE"     then msgs, pool = db.byeMessages,     db.byePool
    elseif listKey == "CUSTOM1" then msgs, pool = db.custom1Messages, db.custom1Pool
    elseif listKey == "CUSTOM2" then msgs, pool = db.custom2Messages, db.custom2Pool
    end

    if not msgs or #msgs == 0 then
        print("|cffff0000RandomGreeting:|r " .. (RG_L["ERR_EMPTY_LIST"] or "No entries in list!"))
        return
    end

    -- Pool auffüllen wenn leer
    if #pool == 0 then
        for i = 1, #msgs do pool[#pool + 1] = i end
        -- Fisher-Yates shuffle
        for i = #pool, 2, -1 do
            local j = math.random(i)
            pool[i], pool[j] = pool[j], pool[i]
        end
    end

    local idx = table.remove(pool, math.random(1, #pool))
    SendChatMessage(msgs[idx], GetChannel(), nil, nil)
end

-- ==========================================================
-- Aktionsfenster – Buttons dynamisch aufbauen
-- ==========================================================

local LIST_ORDER = { "HI", "BYE", "CUSTOM1", "CUSTOM2" }
local LIST_SLASH = { HI = "/rhi", BYE = "/rbye", CUSTOM1 = "/rcustom1", CUSTOM2 = "/rcustom2" }

local MAX_LABEL_CHARS = 12  -- passt bei BTN_W=100 ohne Überlauf

-- Kompaktmodus-Kurzbezeichnungen
local COMPACT_LABEL = { HI = "Hi", BYE = "Bye", CUSTOM1 = "C1", CUSTOM2 = "C2" }

local function IsCompact()
    return RandomGreetingDB and RandomGreetingDB.actionWindowCompact == true
end

local function TruncateLabel(str)
    if #str > MAX_LABEL_CHARS then
        return str:sub(1, MAX_LABEL_CHARS - 1) .. "…"
    end
    return str
end

local function GetListBtnLabel(key)
    if IsCompact() then return COMPACT_LABEL[key] or key end
    local db = RandomGreetingDB
    if     key == "HI"      then return TruncateLabel(RG_L["LABEL_HI"]    or "Greeting")
    elseif key == "BYE"     then return TruncateLabel(RG_L["LABEL_BYE"]   or "Farewell")
    elseif key == "CUSTOM1" then return TruncateLabel(db.custom1Label or RG_L["LABEL_CUSTOM1"] or "Custom1")
    elseif key == "CUSTOM2" then return TruncateLabel(db.custom2Label or RG_L["LABEL_CUSTOM2"] or "Custom2")
    end
    return TruncateLabel(key)
end

local function GetBtnW()
    return IsCompact() and BTN_W_COMPACT or BTN_W
end

local function RebuildAWFButtons()
    if not AWF_Frame then return end

    -- Alte Buttons ausblenden
    for _, b in ipairs(AW_ListBtns) do b:Hide() end
    wipe(AW_ListBtns)

    local db      = RandomGreetingDB
    local btnCfg  = db.actionWindowButtons or {}
    local btnW    = GetBtnW()
    local compact = IsCompact()
    local gap     = compact and 2  or 4   -- Pixel-Abstand zwischen Buttons
    local titleH  = compact and 22 or 24  -- Platz für Titelzeile + Trennstrich
    local sepY    = -20                   -- Trennstrich immer unter dem Text (Text endet bei ~-20)
    local yOff    = -titleH               -- erster Button direkt unter dem Trennstrich

    for _, key in ipairs(LIST_ORDER) do
        if btnCfg[key] then
            local btn = CreateFrame("Button", nil, AWF_Frame, "UIPanelButtonTemplate")
            btn:SetSize(btnW, BTN_H)
            btn:SetPoint("TOPLEFT", AWF_Frame, "TOPLEFT", PAD, yOff)
            local fullLabel = db.custom1Label and key == "CUSTOM1" and db.custom1Label
                           or db.custom2Label and key == "CUSTOM2" and db.custom2Label
                           or (RG_L["LABEL_"..key] or key)
            btn:SetText(GetListBtnLabel(key))
            local k = key  -- Upvalue closure
            btn:SetScript("OnClick", function() SendListMsg(k) end)
            -- Tooltip: im Normalmodus bei abgekürztem Label, im Kompaktmodus nur C1/C2
            btn:SetScript("OnEnter", function(self)
                local raw = k == "CUSTOM1" and (db.custom1Label or RG_L["LABEL_CUSTOM1"] or "Custom1")
                         or k == "CUSTOM2" and (db.custom2Label or RG_L["LABEL_CUSTOM2"] or "Custom2")
                         or (RG_L["LABEL_"..k] or k)
                local showTip = (IsCompact() and (k == "CUSTOM1" or k == "CUSTOM2"))
                             or (not IsCompact() and #raw > MAX_LABEL_CHARS)
                if showTip then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(raw, 1, 1, 1)
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
            btn:Show()
            AW_ListBtns[#AW_ListBtns + 1] = btn
            yOff = yOff - BTN_H - gap
        end
    end

    -- Titeltext anpassen
    if AWF_Frame and AWF_Frame.titleTxt then
        AWF_Frame.titleTxt:SetText(compact and "RG" or ADDON_NAME)
    end

    -- Kanal-Button aktualisieren
    if AW_ChBtn then
        AW_ChBtn:SetSize(GetBtnW(), BTN_H)
        AW_ChBtn:SetText(ChannelLabel(GetChannel()))
        -- Tooltip im Kompaktmodus: voller Kanalname
        AW_ChBtn:SetScript("OnEnter", function(self)
            if IsCompact() then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(GetChannel(), 1, 1, 1)
                GameTooltip:Show()
            end
        end)
        AW_ChBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- Fensterbreite + -höhe anpassen
    local frameW = GetBtnW() + PAD * 2
    AWF_Frame:SetWidth(frameW)
    if AWF_Frame.titleSep then
        AWF_Frame.titleSep:SetPoint("TOPLEFT",  AWF_Frame, "TOPLEFT",   9, sepY)
        AWF_Frame.titleSep:SetPoint("TOPRIGHT", AWF_Frame, "TOPRIGHT", -9, sepY)
    end
    local n = #AW_ListBtns
    local h = titleH                      -- Titelbereich
            + n * (BTN_H + gap)           -- Liste
            + (BTN_H + gap)               -- Kanal-Button
            + PAD
    if h < 60 then h = 60 end
    AWF_Frame:SetHeight(h)
end

-- Öffentlich zugänglich damit Options.lua das Fenster nach Checkbox-Änderungen neu aufbaut
RG_Internal.RebuildActionWindow = RebuildAWFButtons

-- ==========================================================
-- Aktionsfenster – Erstellen
-- ==========================================================

local function BuildActionWindow()
    if AWF_Frame then return end

    local f = CreateFrame("Frame", "RGActionWindow", UIParent, "BackdropTemplate")
    f:SetWidth(BTN_W + PAD * 2)
    f:SetHeight(100)   -- wird sofort durch RebuildAWFButtons überschrieben
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",  function(self)
        self:StopMovingOrSizing()
        -- GetLeft/GetTop liefern virtuelle Bildschirmkoordinaten (UIParent-Raum)
        local x = self:GetLeft()
        local y = self:GetTop() - UIParent:GetHeight()  -- negativer Offset von TOPLEFT
        RandomGreetingCharDB.actionWindowPos = { x = x, y = y }
    end)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    -- Titelzeile (einfache Beschriftung + Trennlinie, bleibt im Frame)
    local titleTxt = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    titleTxt:SetPoint("TOP", f, "TOP", 0, -10)
    titleTxt:SetText(IsCompact() and "RG" or ADDON_NAME)
    f.titleTxt = titleTxt

    local titleSep = f:CreateTexture(nil, "ARTWORK")
    titleSep:SetTexture("Interface\\Buttons\\WHITE8X8")
    titleSep:SetVertexColor(0.5, 0.5, 0.5, 0.6)
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  f, "TOPLEFT",  9, -20)
    titleSep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -9, -20)
    f.titleSep = titleSep

    -- Schließen-Button (X)
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        RandomGreetingDB.actionWindowShown = false
    end)

    -- Kanal-Zyklus-Button (ganz unten)
    local chBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    chBtn:SetSize(BTN_W, BTN_H)
    chBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, PAD)
    chBtn:SetScript("OnClick", function(self)
        local nxt = NextChannel()
        self:SetText(ChannelLabel(nxt))
        -- Tooltip aktualisieren, falls er gerade sichtbar ist (Maus noch auf Button)
        if IsCompact() and GameTooltip:IsOwned(self) then
            GameTooltip:SetText(nxt, 1, 1, 1)
        end
    end)
    AW_ChBtn = chBtn

    AWF_Frame = f
    RebuildAWFButtons()

    -- Position wiederherstellen (nach erstem Laden: CENTER-Default)
    local db  = RandomGreetingDB
    local pos = RandomGreetingCharDB.actionWindowPos
    f:ClearAllPoints()
    if pos and pos.x then
        f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", pos.x, pos.y)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
    end

    -- Sichtbarkeit wiederherstellen
    if db.actionWindowShown then f:Show() else f:Hide() end
end

local function ToggleActionWindow()
    if not AWF_Frame then
        BuildActionWindow()
        if AWF_Frame and not AWF_Frame:IsShown() then
            RebuildAWFButtons()
            AWF_Frame:Show()
            RandomGreetingDB.actionWindowShown = true
        end
        return
    end
    if AWF_Frame:IsShown() then
        AWF_Frame:Hide()
        RandomGreetingDB.actionWindowShown = false
    else
        RebuildAWFButtons()
        AWF_Frame:Show()
        RandomGreetingDB.actionWindowShown = true
    end
end

RG_Internal.ToggleActionWindow = ToggleActionWindow

-- ==========================================================
-- Minimap-Button
-- ==========================================================

local mm_isDragging = false

local function UpdateMMPos()
    if not MM_Button then return end
    local angle = (RandomGreetingDB and RandomGreetingDB.minimapAngle) or 225
    local rad   = math.rad(angle)
    MM_Button:ClearAllPoints()
    MM_Button:SetPoint("CENTER", Minimap, "CENTER",
        math.cos(rad) * MINIMAP_RADIUS,
        math.sin(rad) * MINIMAP_RADIUS)
end

local function BuildMinimapButton()
    if MM_Button then return end

    local btn = CreateFrame("Button", "RGMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameLevel(8)
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Icon: .png explizit angeben (WoW sucht sonst nur .blp/.tga)
    -- Für Classic Era < 1.15: minimap.tga stattdessen ablegen.
    local icon = btn:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\RandomGreeting\\Media\\minimap.png")
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER", 0, 0)
    btn.icon = icon

    -- Runde Minimap-Umrandung
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(56, 56)
    border:SetPoint("TOPLEFT", 0, 0)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(ADDON_NAME, 1, 1, 1)
        GameTooltip:AddLine(RG_L["MINIMAP_TT_LEFT"]  or "Left-click: Toggle action window", 0.8, 0.8, 0.8)
        GameTooltip:AddLine(RG_L["MINIMAP_TT_RIGHT"] or "Right-click: Open options",        0.8, 0.8, 0.8)
        GameTooltip:AddLine(RG_L["MINIMAP_TT_DRAG"]  or "Drag: Reposition button",          0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Klick- und Drag-Handling
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")

    btn:SetScript("OnDragStart", function(self)
        mm_isDragging  = true
        self.wasDragged = false
    end)
    btn:SetScript("OnDragStop", function()
        mm_isDragging = false
    end)

    btn:SetScript("OnUpdate", function(self)
        if mm_isDragging then
            self.wasDragged = true
            local mx, my = Minimap:GetCenter()
            local uis    = UIParent:GetEffectiveScale()
            local cx, cy = GetCursorPosition()
            cx = cx / uis
            cy = cy / uis
            local angle  = math.deg(math.atan2(cy - my, cx - mx))
            RandomGreetingDB.minimapAngle = angle
            self:ClearAllPoints()
            self:SetPoint("CENTER", Minimap, "CENTER",
                math.cos(math.rad(angle)) * MINIMAP_RADIUS,
                math.sin(math.rad(angle)) * MINIMAP_RADIUS)
        end
    end)

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if not self.wasDragged then
                ToggleActionWindow()
            end
            self.wasDragged = false
        elseif button == "RightButton" then
            if RG_Internal.OpenOptions then RG_Internal.OpenOptions(nil) end
        end
    end)

    MM_Button = btn
    UpdateMMPos()
end

-- ==========================================================
-- PLAYER_LOGIN – DB-Defaults initialisieren, UI aufbauen
-- ==========================================================

local mmInitFrame = CreateFrame("Frame")
mmInitFrame:RegisterEvent("PLAYER_LOGIN")
mmInitFrame:SetScript("OnEvent", function(self)
    local db = RandomGreetingDB

    -- Neue Felder mit Defaults befüllen (nur wenn noch nicht gesetzt)
    if db.minimapAngle        == nil then db.minimapAngle        = 225   end
    if db.actionWindowChannel == nil then db.actionWindowChannel = "GUILD" end
    if db.actionWindowShown   == nil then db.actionWindowShown   = false  end
    if RandomGreetingCharDB                    == nil then RandomGreetingCharDB                    = {}     end
    if RandomGreetingCharDB.actionWindowPos    == nil then RandomGreetingCharDB.actionWindowPos    = false  end
    if db.actionWindowButtons == nil then
        db.actionWindowButtons = { HI = true, BYE = true, CUSTOM1 = false, CUSTOM2 = false }
    end
    if db.actionWindowCompact  == nil then db.actionWindowCompact  = false end

    BuildMinimapButton()
    BuildActionWindow()

    self:UnregisterEvent("PLAYER_LOGIN")
end)
