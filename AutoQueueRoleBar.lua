local function EnsureDB()
    AutoAcceptQueueCharDB = AutoAcceptQueueCharDB or {}
    AutoAcceptQueueCharDB.roleOverride = AutoAcceptQueueCharDB.roleOverride or { tank = false, healer = false, dps = false }
    AutoAcceptQueueCharDB.roleBar      = AutoAcceptQueueCharDB.roleBar or { hidden = false }
end
EnsureDB()

---------------------------------------------------------
-- Rôles disponibles pour la classe actuelle
---------------------------------------------------------
local function GetAvailableRoles()
    local available = { tank = false, healer = false, dps = false }
    local numSpecs = GetNumSpecializations()
    for i = 1, numSpecs do
        local _, _, _, _, role = GetSpecializationInfo(i)
        if role == "TANK"    then available.tank   = true end
        if role == "HEALER"  then available.healer = true end
        if role == "DAMAGER" then available.dps    = true end
    end
    return available
end

local ROLE_LABELS = {
    tank   = "|cff00aeefTank|r",
    healer = "|cff00ff7fHeal|r",
    dps    = "|cffff6060DPS|r",
}

---------------------------------------------------------
-- Création de la barre (3 icônes de rôle + sous-titres)
---------------------------------------------------------
local BTN_SIZE = 50
local BTN_GAP  = 20
local ROW_WIDTH = 3 * BTN_SIZE + 2 * BTN_GAP
local BAR_WIDTH  = ROW_WIDTH + 50
local BAR_HEIGHT = 92 -- +14 par rapport à avant, pour la 2e ligne de texte

local bar = CreateFrame("Frame", "AutoQueueRoleBar", UIParent, "BackdropTemplate")
bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
bar:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile     = false,
    edgeSize = 1,
})
bar:SetBackdropColor(0.06, 0.06, 0.06, 0.9)
bar:SetBackdropBorderColor(0, 0, 0, 0.8)
bar:Hide()

-- Deux FontStrings séparés : un SetText() sur le même objet écrase le
-- précédent, donc il en faut un par ligne pour que les deux s'affichent.
local subtitle1 = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
subtitle1:SetPoint("BOTTOM", bar, "BOTTOM", 0, 22)
subtitle1:SetText("|cffaaaaaa(none checked = use active spec role)|r")

local subtitle2 = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
subtitle2:SetPoint("BOTTOM", bar, "BOTTOM", 0, 8)
subtitle2:SetText("|cffaaaaaa(Hold SHIFT to put a note)|r")

local roleButtons = {}
local roles = { "tank", "healer", "dps" }

local function UpdateRoleBar()
    EnsureDB()
    local db        = AutoAcceptQueueCharDB.roleOverride
    local available = GetAvailableRoles()

    for role, btn in pairs(roleButtons) do
        if not available[role] then
            db[role] = false
            btn.icon:SetDesaturated(true)
            btn.icon:SetAlpha(0.25)
            btn.check:Hide()
            btn:EnableMouse(true) -- garde la souris active pour le tooltip "Not available"
            if btn.hl then btn.hl:Hide() end -- mais pas de surbrillance au survol
            if btn.lockIcon then btn.lockIcon:Show() end
        elseif db[role] then
            btn.icon:SetDesaturated(false)
            btn.icon:SetAlpha(1.0)
            btn.check:Show()
            btn:EnableMouse(true)
            if btn.hl then btn.hl:Show() end
            if btn.lockIcon then btn.lockIcon:Hide() end
        else
            btn.icon:SetDesaturated(true)
            btn.icon:SetAlpha(0.5)
            btn.check:Hide()
            btn:EnableMouse(true)
            if btn.hl then btn.hl:Show() end
            if btn.lockIcon then btn.lockIcon:Hide() end
        end
    end
end

-- Rafraîchit l'infobulle du bouton de rôle survolé, si elle est ouverte.
local function RefreshRoleTooltip(btn, role)
    if not btn:IsMouseOver() then return end
    EnsureDB()
    local avail = GetAvailableRoles()
    GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
    GameTooltip:SetText(ROLE_LABELS[role])
    if not avail[role] then
        GameTooltip:AddLine("|cffaaaaaaNot available for this class|r")
    else
        GameTooltip:AddLine(AutoAcceptQueueCharDB.roleOverride[role] and "|cff00ff00Enabled|r" or "|cffff4444Disabled|r")
    end
    GameTooltip:Show()
end

for i, role in ipairs(roles) do
    local btn = CreateFrame("Frame", "AutoQueueRoleBar_" .. role, bar)
    btn:SetSize(BTN_SIZE, BTN_SIZE)
    local startX = -(ROW_WIDTH / 2) + BTN_SIZE / 2 + (i - 1) * (BTN_SIZE + BTN_GAP)
    btn:SetPoint("TOP", bar, "TOP", startX, -5)
    btn:EnableMouse(true)

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(BTN_SIZE - 4, BTN_SIZE - 4)
    local xOffset = (role == "tank") and -1 or -2
    local yOffset = (role == "healer") and -1 or 0
    icon:SetPoint("CENTER", btn, "CENTER", xOffset, yOffset)
    icon:SetTexture("Interface\\LFGFRAME\\UI-LFG-Icon-Roles")
    if role == "tank" then
        icon:SetTexCoord(0.00, 0.25, 0.25, 0.50)
    elseif role == "healer" then
        icon:SetTexCoord(0.25, 0.50, 0.00, 0.25)
    elseif role == "dps" then
        icon:SetTexCoord(0.25, 0.50, 0.25, 0.50)
    end
    btn.icon = icon

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(btn)
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    btn.hl = hl

    local checkBG = btn:CreateTexture(nil, "OVERLAY")
    checkBG:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
    checkBG:SetSize(18, 18)
    checkBG:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -5)

    local check = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    check:SetAllPoints(checkBG)
    btn.check = check

    -- Overlay verrou : grosse croix rouge quand le rôle n'existe pas pour la classe
    local lockTxt = btn:CreateTexture(nil, "OVERLAY")
    lockTxt:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
    lockTxt:SetSize(30, 30)
    lockTxt:SetPoint("CENTER", btn, "CENTER", 0, 0)
    lockTxt:Hide()
    btn.lockIcon = lockTxt

    btn:SetScript("OnMouseDown", function()
        EnsureDB()
        local avail = GetAvailableRoles()
        if not avail[role] then return end
        AutoAcceptQueueCharDB.roleOverride[role] = not AutoAcceptQueueCharDB.roleOverride[role]
        UpdateRoleBar()
        RefreshRoleTooltip(btn, role)
    end)

    btn:SetScript("OnEnter", function(self)
        RefreshRoleTooltip(self, role)
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    roleButtons[role] = btn
end

---------------------------------------------------------
-- Accroche de la barre au-dessus de PVEFrame
---------------------------------------------------------
local function AnchorBar()
    bar:ClearAllPoints()
    bar:SetPoint("BOTTOM", PVEFrame, "TOP", 100, -1)
end

-- Aligne la strata + le frame level de la barre sur ceux de PVEFrame une
-- fois qu'elle en est un vrai enfant (SetParent(PVEFrame), fait plus bas
-- dans le watcher). Un enfant réel suit le raise de son parent nativement
-- (c'est ce que fait RaiderIO, qui reste bien accroché à PVEFrame quand
-- on la déplace) — inutile de repoller en boucle comme avant.
local function SyncBarLayer()
    if not PVEFrame then return end
    local pveStrata = PVEFrame:GetFrameStrata()
    local pveLevel  = PVEFrame:GetFrameLevel()
    if bar:GetFrameStrata() ~= pveStrata then
        bar:SetFrameStrata(pveStrata)
    end
    if bar:GetFrameLevel() ~= pveLevel + 1 then
        bar:SetFrameLevel(pveLevel + 1)
    end
end

local function ShowBarIfNeeded()
    EnsureDB()
    if AutoAcceptQueueCharDB.roleBar.hidden then
        bar:Hide()
        return
    end
    AnchorBar()
    SyncBarLayer()
    UpdateRoleBar()
    bar:Show()
end

---------------------------------------------------------
-- Bouton afficher/cacher la barre
-- Accroché à l'intérieur de la fenêtre, juste à gauche du bouton
-- de fermeture (X), en haut à droite.
-- Pour le mettre à côté du bouton PGF à la place, remplace la ligne
-- toggleBtn:SetPoint(...) dans AnchorToggleButton() par un ancrage
-- sur ce bouton une fois son nom de frame identifié
-- (ex: PremadeGroupsFilterButton).
---------------------------------------------------------
local tutorialTip -- déclaré ici, rempli plus bas (utilisé par toggleBtn:OnClick avant sa création)

local toggleBtn = CreateFrame("Button", "AutoQueueRoleBarToggle", UIParent, "BackdropTemplate")
toggleBtn:SetSize(20, 20)
toggleBtn:SetFrameStrata("HIGH")
toggleBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
})
toggleBtn:SetBackdropColor(0.55, 0.08, 0.08, 1)

-- "+"/"-" dessiné avec deux barres (pas de police = pas d'asymétrie de glyphe)
local hBar = toggleBtn:CreateTexture(nil, "OVERLAY")
hBar:SetColorTexture(1, 0.82, 0, 1)
hBar:SetSize(12, 3)
hBar:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)

local vBar = toggleBtn:CreateTexture(nil, "OVERLAY")
vBar:SetColorTexture(1, 0.82, 0, 1)
vBar:SetSize(3, 12)
vBar:SetPoint("CENTER", toggleBtn, "CENTER", 0, 0)

toggleBtn.hBar = hBar
toggleBtn.vBar = vBar

local hl2 = toggleBtn:CreateTexture(nil, "HIGHLIGHT")
hl2:SetAllPoints(toggleBtn)
hl2:SetColorTexture(1, 1, 1, 0.25)

local function UpdateToggleTexture()
    EnsureDB()
    if AutoAcceptQueueCharDB.roleBar.hidden then
        toggleBtn.vBar:Show()  -- "+" (caché → cliquer pour afficher)
    else
        toggleBtn.vBar:Hide()  -- "-" (affiché → cliquer pour cacher)
    end
end

toggleBtn:SetScript("OnClick", function()
    EnsureDB()
    AutoAcceptQueueCharDB.roleBar.hidden = not AutoAcceptQueueCharDB.roleBar.hidden
    ShowBarIfNeeded()
    UpdateToggleTexture()
    if tutorialTip:IsShown() then
        tutorialTip:Hide()
        AutoAcceptQueueCharDB.roleBar.tutorialShown = true
    end
end)

toggleBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP", 50,0)
    GameTooltip:SetText("|cffb048f8AutoQueue|r")
    GameTooltip:AddLine("Show / Hide the role selection")
    GameTooltip:Show()
end)
toggleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function AnchorToggleButton()
    toggleBtn:ClearAllPoints()
    local closeBtn = (PVEFrame.CloseButton) or _G["PVEFrameCloseButton"]
    if closeBtn then
        toggleBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
    else
        -- Repli si le bouton de fermeture n'est pas trouvé sous ce nom :
        -- position approximative en haut à droite, à l'intérieur.
        toggleBtn:SetPoint("TOPRIGHT", PVEFrame, "TOPRIGHT", -32, -6)
    end
end

---------------------------------------------------------
-- Bulle de tutoriel (une seule fois, à la première ouverture)
---------------------------------------------------------
tutorialTip = CreateFrame("Frame", "AutoQueueRoleBarTutorial", UIParent, "BackdropTemplate")
tutorialTip:SetFrameStrata("TOOLTIP")
tutorialTip:SetSize(260, 10) -- hauteur recalculée dans ShowFirstTimeTutorial()
tutorialTip:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile     = false,
    edgeSize = 1,
})
tutorialTip:SetBackdropColor(0.06, 0.06, 0.06, 0.97)
tutorialTip:SetBackdropBorderColor(0.69, 0.28, 0.97, 1) -- violet AutoQueue
tutorialTip:Hide()

local tutorialText = tutorialTip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
tutorialText:SetPoint("TOPLEFT", tutorialTip, "TOPLEFT", 10, -10)
tutorialText:SetWidth(240)
tutorialText:SetJustifyH("LEFT")
tutorialText:SetText(
    "|cffb048f8AutoQueue|r: click here to show/hide the role selection, "
    .. "letting you queue for multiple roles or a different spec. "
    .. "If no selection is made, your current spec role applies.\n\n"
    .. "Settings are saved per character.\n\n"
    .. "|cffffff00Tip: you can double-click to queue faster.|r"
)

local tutorialClose = CreateFrame("Button", nil, tutorialTip, "UIPanelButtonTemplate")
tutorialClose:SetSize(80, 22)
tutorialClose:SetPoint("TOP", tutorialText, "BOTTOM", 0, -10)
tutorialClose:SetText("Got it!")

local function HideTutorial(markAsSeen)
    tutorialTip:Hide()
    if markAsSeen then
        EnsureDB()
        AutoAcceptQueueCharDB.roleBar.tutorialShown = true
    end
end
tutorialClose:SetScript("OnClick", function() HideTutorial(true) end)

local function ShowFirstTimeTutorial()
    EnsureDB()
    if AutoAcceptQueueCharDB.roleBar.tutorialShown then return end
    if not toggleBtn:IsShown() then return end

    tutorialTip:ClearAllPoints()
    tutorialTip:SetPoint("TOPRIGHT", toggleBtn, "BOTTOMRIGHT", 10, -8)
    tutorialTip:SetHeight(tutorialText:GetStringHeight() + tutorialClose:GetHeight() + 32)
    tutorialTip:Show()
end

---------------------------------------------------------
-- Attente que PVEFrame existe (frame chargée à la demande)
---------------------------------------------------------
local hooked = false
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:SetScript("OnEvent", function()
    EnsureDB()
    if hooked or not PVEFrame then return end
    hooked = true

    toggleBtn:SetParent(PVEFrame)
    toggleBtn:SetFrameStrata("DIALOG")
    toggleBtn:SetFrameLevel(PVEFrame:GetFrameLevel() + 50)
    AnchorToggleButton()
    UpdateToggleTexture()

    bar:SetParent(PVEFrame)
    SyncBarLayer()

    PVEFrame:HookScript("OnShow", ShowBarIfNeeded)
    PVEFrame:HookScript("OnShow", ShowFirstTimeTutorial)
    PVEFrame:HookScript("OnHide", function()
        bar:Hide()
        HideTutorial(false) -- se referme si on quitte, mais réapparaîtra à la prochaine ouverture
    end)

    if PVEFrame:IsShown() then
        ShowBarIfNeeded()
        ShowFirstTimeTutorial()
    end

    watcher:UnregisterEvent("ADDON_LOADED")
    watcher:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)