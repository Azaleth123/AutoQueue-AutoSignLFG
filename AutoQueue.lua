local addonName = "AutoAcceptQueue"

-- Saved variables - Default initialization
AutoAcceptQueueCharDB = AutoAcceptQueueCharDB or {
    minimap        = { hide = false },
    active         = true,
    autoSignLFG    = true,
    roleOverride   = { tank = false, healer = false, dps = false },
}

---------------------------------------------------------
-- ROLE DETECTION
---------------------------------------------------------

-- Returns "TANK", "HEALER" or "DAMAGER" based on active spec
local function GetCurrentRole()
    local specIndex = GetSpecialization()
    if not specIndex then return "DAMAGER" end
    return GetSpecializationRole(specIndex) or "DAMAGER"
end

-- Returns a colored label for display (tooltip, /aq status)
local function GetRoleLabel()
    local role = GetCurrentRole()
    if role == "TANK"   then return "|cff00aeefTank|r"   end
    if role == "HEALER" then return "|cff00ff7fHealer|r" end
    return "|cffff6060DPS|r"
end

-- Returns the effective roles to queue as (override or active spec)
local function GetEffectiveRoles()
    local db = AutoAcceptQueueCharDB.roleOverride
    local anyChecked = db.tank or db.healer or db.dps
    if anyChecked then
        return db.tank, db.healer, db.dps
    else
        local role = GetCurrentRole()
        return role == "TANK", role == "HEALER", role == "DAMAGER"
    end
end

-- Returns which roles are available for the current class (scans all specs)
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

---------------------------------------------------------
-- ROLE SELECTION POPUP (minimap right-click)
---------------------------------------------------------

local rolePopup = nil

local ROLE_LABELS = {
    tank   = "|cff00aeefTank|r",
    healer = "|cff00ff7fHeal|r",
    dps    = "|cffff6060DPS|r",
}

local roleButtons = {}

local function UpdateRoleButtons()
    local db        = AutoAcceptQueueCharDB.roleOverride
    local available = GetAvailableRoles()

    for role, btn in pairs(roleButtons) do
        if not available[role] then
            -- Rôle impossible pour cette classe : désactivé visuellement et non cliquable
            db[role] = false  -- force à false au cas où il était coché avant
            btn:EnableMouse(true)
            btn.icon:SetDesaturated(true)
            btn.icon:SetAlpha(0.25)
            btn.check:Hide()
            if btn.lockIcon then btn.lockIcon:Show() end
        elseif db[role] then
            btn:EnableMouse(true)
            btn.icon:SetDesaturated(false)
            btn.icon:SetAlpha(1.0)
            btn.check:Show()
            if btn.lockIcon then btn.lockIcon:Hide() end
        else
            btn:EnableMouse(true)
            btn.icon:SetDesaturated(true)
            btn.icon:SetAlpha(0.5)
            btn.check:Hide()
            if btn.lockIcon then btn.lockIcon:Hide() end
        end
    end
end

local function CreateRolePopup()
    if rolePopup then
        rolePopup:Show()
        return
    end

    local f = CreateFrame("Frame", "AutoQueueRolePopup", UIParent, "BackdropTemplate")
    f:SetSize(300, 185)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 11, right = 11, top = 11, bottom = 10 },
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -14)
    title:SetText("|cffb048f8AutoQueue|r - Preferred Roles")

    -- Subtitle
    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("|cffaaaaaa(none checked = use active spec role)|r")
    

    -- Role buttons
    local roles  = { "tank", "healer", "dps" }

    for i, role in ipairs(roles) do
        -- Outer frame: clickable, sized to show one icon
        local btn = CreateFrame("Frame", "AutoQueueRoleBtn_" .. role, f)
        btn:SetSize(64, 64)
        local totalWidth = 3 * 64 + 2 * 11
        local startX = -(totalWidth / 2) + 32 + (i - 1) * 75
        btn:SetPoint("TOP", f, "TOP", startX, -55)
        btn:EnableMouse(true)

        local icon = btn:CreateTexture(nil, "BACKGROUND")
        icon:SetSize(56, 56)
        -- Fine-tune centering per role (spritesheet padding is uneven)
        local xOffset = (role == "tank") and -1 or -4
        local yOffset = (role == "healer") and -3 or 0
        icon:SetPoint("CENTER", btn, "CENTER", xOffset, yOffset)

        -- Role spritesheet: 256x256, each icon is 64x64 (0.25 per tile)
        -- Row 1 (top=0, bottom=0.5): col1=tank, col2=healer (with ~8px top padding on heal)
        -- Row 2 (top=0.5): col1=leader, col2=dps
        icon:SetTexture("Interface\\LFGFRAME\\UI-LFG-Icon-Roles")
        if role == "tank" then
            icon:SetTexCoord(0.00, 0.25, 0.25, 0.50)
        elseif role == "healer" then
            icon:SetTexCoord(0.25, 0.50, 0.00, 0.25)
        elseif role == "dps" then
            icon:SetTexCoord(0.25, 0.50, 0.25, 0.50)
        end
        btn.icon = icon

        -- Hover highlight
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(btn)
        hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
        hl:SetBlendMode("ADD")

        -- Checkbox background (visible even when unchecked)
        local checkBG = btn:CreateTexture(nil, "ARTWORK")
        checkBG:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
        checkBG:SetSize(26, 26)
        checkBG:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 6, -6)

        -- Checkmark overlay (the green check)
        local check = btn:CreateTexture(nil, "OVERLAY")
        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        check:SetSize(26, 26)
        check:SetAllPoints(checkBG)
        btn.check = check



        -- Lock overlay: red cross texture (always loaded by Blizzard)
        local lockTxt = btn:CreateTexture(nil, "OVERLAY")
        lockTxt:SetTexture("Interface\\RAIDFRAME\\ReadyCheck-NotReady")
        lockTxt:SetSize(30, 30)
        lockTxt:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lockTxt:Hide()
        btn.lockIcon = lockTxt

        btn:SetScript("OnMouseDown", function()
            local avail = GetAvailableRoles()
            if not avail[role] then return end
            AutoAcceptQueueCharDB.roleOverride[role] = not AutoAcceptQueueCharDB.roleOverride[role]
            UpdateRoleButtons()
        end)

        btn:SetScript("OnEnter", function(self)
            local avail = GetAvailableRoles()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(ROLE_LABELS[role])
            if not avail[role] then
                GameTooltip:AddLine("|cffaaaaaaNot available for this class|r")
            else
                GameTooltip:AddLine(AutoAcceptQueueCharDB.roleOverride[role] and "|cff00ff00Enabled|r" or "|cffff4444Disabled|r")
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        roleButtons[role] = btn
    end

    -- Checkbox AutoSignLFG
    local chkFrame = CreateFrame("CheckButton", "AutoQueueChkAutoSign", f, "UICheckButtonTemplate")
    chkFrame:SetSize(24, 24)
    chkFrame:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 14, 14)
    chkFrame:SetChecked(AutoAcceptQueueCharDB.autoSignLFG ~= false)
    chkFrame:SetScript("OnClick", function(self)
        AutoAcceptQueueCharDB.autoSignLFG = self:GetChecked()
    end)

    local chkLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chkLabel:SetPoint("LEFT", chkFrame, "RIGHT", 2, 0)
    chkLabel:SetText("Double-click to sign up (LFG)")
    

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 1, 1)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    rolePopup = f

    -- Fermeture avec la touche Echap
    tinsert(UISpecialFrames, "AutoQueueRolePopup")

    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    UpdateRoleButtons()
end

local function ShowRolePopup()
    if rolePopup and rolePopup:IsShown() then
        rolePopup:Hide()
    else
        if not rolePopup then
            CreateRolePopup()
        else
            UpdateRoleButtons()
            if AutoQueueChkAutoSign then
                AutoQueueChkAutoSign:SetChecked(AutoAcceptQueueCharDB.autoSignLFG ~= false)
            end
            rolePopup:Show()
        end
    end
end

---------------------------------------------------------
-- AUTOQUEUE - Secure button for auto-accepting dungeon ready
---------------------------------------------------------

local proposalButton = CreateFrame("Button", "AutoQueueProposalButton", UIParent, "SecureActionButtonTemplate")
proposalButton:Hide()
proposalButton:SetAttribute("type", "click")

local function SetupSecureHooks()
    if LFGDungeonReadyDialog and LFGDungeonReadyDialogEnterDungeonButton then
        proposalButton:SetAttribute("clickbutton", LFGDungeonReadyDialogEnterDungeonButton)

        hooksecurefunc("LFGDungeonReadyPopup_Update", function()
            if AutoAcceptQueueCharDB.active and LFGDungeonReadyDialog:IsShown() then
                C_Timer.After(0.2, function()
                    if AutoAcceptQueueCharDB.active and not InCombatLockdown() then
                        proposalButton:Click()
                    end
                end)
            end
        end)
    end
end

---------------------------------------------------------
-- AUTOSIGNLFG - Role check + double-click Group Finder
---------------------------------------------------------

local lfgInitialized = false

-- Confirms the LFD role check with the correct role (override or active spec)
local function HandleRoleCheck()
    if not AutoAcceptQueueCharDB.autoSignLFG then return end
    if not AutoAcceptQueueCharDB.active then return end

    local isTank, isHealer, isDPS = GetEffectiveRoles()
    local isLeader = GetLFGRoles()
    SetLFGRoles(isLeader, isTank, isHealer, isDPS)
    CompleteLFGRoleCheck(true)
end

-- Auto-confirms the Group Finder sign-up dialog with the correct roles
local function SetupApplicationDialog()
    if LFGListApplicationDialog then
        LFGListApplicationDialog:SetScript("OnShow", function()
            if not AutoAcceptQueueCharDB.autoSignLFG then return end
            if not IsShiftKeyDown() then
                local isTank, isHealer, isDPS = GetEffectiveRoles()
                local isLeader = GetLFGRoles()
                SetLFGRoles(isLeader, isTank, isHealer, isDPS)
                LFGListApplicationDialog.SignUpButton:Click()
            end
        end)
    end
end

-- Double-click a Group Finder entry to sign up
local function OnDoubleClick(self)
    if not AutoAcceptQueueCharDB.autoSignLFG then return end
    local resultExists = not LFGListFrame.SearchPanel.SignUpButton.tooltip
    if resultExists then
        LFGListSearchPanel_SignUp(self:GetParent():GetParent():GetParent())
    end
end

-- Initializes double-click handlers on search result entries
local function InitializeButtons()
    if not LFGListFrame or not LFGListFrame.SearchPanel or not LFGListFrame.SearchPanel.ScrollBox then return end
    local scrollTarget = LFGListFrame.SearchPanel.ScrollBox:GetScrollTarget()
    if not scrollTarget then return end

    for _, child in ipairs({ scrollTarget:GetChildren() }) do
        if child and child:GetObjectType() == "Button" and not child.autoSignInitialized then
            child:SetScript("OnDoubleClick", OnDoubleClick)
            child:RegisterForClicks("AnyUp")
            child.autoSignInitialized = true
        end
    end

    lfgInitialized = true
end

---------------------------------------------------------
-- PERSIST SIGN-UP NOTE
---------------------------------------------------------

local _persistOriginalFunc = nil
local _persistPatchedFunc  = nil

local function SetupPersistNoteHooks()
    _persistOriginalFunc = LFGListApplicationDialog_Show

    _persistPatchedFunc = function(self, resultID)
        if resultID then
            local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
            self.resultID   = resultID
            self.activityID = searchResultInfo and searchResultInfo.activityID or 0
        end
        LFGListApplicationDialog_UpdateRoles(self)
        StaticPopupSpecial_Show(self)
        -- C_LFGList.ClearApplicationTextFields() intentionally omitted
    end

    LFGListApplicationDialog_Show = _persistPatchedFunc
end

---------------------------------------------------------
-- MINIMAP ICON - DataBroker + LibDBIcon
---------------------------------------------------------

local function GetRoleOverrideLabel()
    local db = AutoAcceptQueueCharDB.roleOverride
    local anyChecked = db.tank or db.healer or db.dps
    if not anyChecked then
        return "|cffaaaaaa(active spec)|r"
    end
    local parts = {}
    if db.tank   then table.insert(parts, "|cff00aeefTank|r")   end
    if db.healer then table.insert(parts, "|cff00ff7fHeal|r")   end
    if db.dps    then table.insert(parts, "|cffff6060DPS|r")    end
    return table.concat(parts, ", ")
end

local function UpdateIcon()
    local icon = AutoAcceptQueueCharDB.active
        and "Interface\\COMMON\\Indicator-Green"
        or  "Interface\\COMMON\\Indicator-Red"
    if AutoAcceptQueueLDB then
        AutoAcceptQueueLDB.icon = icon
    end
end

local function ToggleMode()
    AutoAcceptQueueCharDB.active = not AutoAcceptQueueCharDB.active
    UpdateIcon()
end

local LDB    = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

AutoAcceptQueueLDB = LDB:NewDataObject(addonName, {
    type  = "launcher",
    icon  = "Interface\\COMMON\\Indicator-Green",
    OnClick = function(_, button)
        if button == "LeftButton" then
            ToggleMode()
        elseif button == "RightButton" then
            ShowRolePopup()
        end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("|cffb048f8AutoQueue|r")
        tt:AddLine(" ")
        if AutoAcceptQueueCharDB.active then
            tt:AddLine("|cff00ff00Status: On|r")
            tt:AddLine("Lets you auto click the ''Accept'' when your")
            tt:AddLine("group leader tries to sign up for something.")
        else
            tt:AddLine("|cffff0000Status: Off|r")
            tt:AddLine("Auto-accept is currently disabled.")
        end
        tt:AddLine(" ")
        tt:AddLine("Detected role: " .. GetRoleLabel())
        tt:AddLine("Queue roles: "   .. GetRoleOverrideLabel())
        tt:AddLine(" ")
        tt:AddLine("|cffb048f8Left click:|r On / Off")
        tt:AddLine("|cffb048f8Right click:|r Role selection")
    end,
})

---------------------------------------------------------
-- EVENTS
---------------------------------------------------------

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("LFG_ROLE_CHECK_SHOW")
eventFrame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        AutoAcceptQueueCharDB.minimap      = AutoAcceptQueueCharDB.minimap or { hide = false }
        AutoAcceptQueueCharDB.autoSignLFG  = AutoAcceptQueueCharDB.autoSignLFG ~= false
        AutoAcceptQueueCharDB.roleOverride = AutoAcceptQueueCharDB.roleOverride or { tank = false, healer = false, dps = false }
        DBIcon:Register(addonName, AutoAcceptQueueLDB, AutoAcceptQueueCharDB.minimap)
        UpdateIcon()
        SetupPersistNoteHooks()

    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_LFGList" then
        SetupSecureHooks()

    elseif event == "PLAYER_ENTERING_WORLD" then
        SetupApplicationDialog()

    elseif event == "LFG_ROLE_CHECK_SHOW" then
        HandleRoleCheck()

    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        lfgInitialized = false
        C_Timer.After(0.1, InitializeButtons)
    end
end)

---------------------------------------------------------
-- SLASH COMMANDS
---------------------------------------------------------

local function PrintStatus()
    local aqStatus   = AutoAcceptQueueCharDB.active      and "|cff00ff00On|r" or "|cffff0000Off|r"
    local lfgStatus  = AutoAcceptQueueCharDB.autoSignLFG and "|cff00ff00On|r" or "|cffff0000Off|r"
    print("------------------------")
    print("|cffb048f8AutoQueue:|r Status:")
    print("  • AutoQueue: "        .. aqStatus)
    print("  • AutoSignLFG: "      .. lfgStatus)
    print("  • Detected role: "    .. GetRoleLabel())
    print("  • Queue roles: "      .. GetRoleOverrideLabel())
    print(" ")
    print("|cffb048f8AutoQueue|r = Auto-accept when your leader signs up for something.")
    print("|cffb048f8AutoSignLFG|r = Double-click to sign up in LFG. (Hold Shift to sign up manually)")    print(" ")
    print("|cffb048f8Commands:|r")
    print("|cffffffff/aq|r |cff00ff00on|r / |cffff0000off|r - Enable / Disable AutoQueue")
    print("|cffffffff/aq minimap|r - Show / Hide minimap icon")
    print("|cffffffff/aq roles|r - Open role selection popup")
    print("|cffffffff/lfg|r |cff00ff00on|r / |cffff0000off|r - Enable / Disable AutoSignLFG")
    print("------------------------")
end

-- /aq
SLASH_AUTOQUEUE1 = "/aq"
SLASH_AUTOQUEUE2 = "/autoqueue"

SlashCmdList["AUTOQUEUE"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "on" then
        AutoAcceptQueueCharDB.active = true
        UpdateIcon()
        print("|cffb048f8AutoQueue:|r On")
    elseif msg == "off" then
        AutoAcceptQueueCharDB.active = false
        UpdateIcon()
        print("|cffb048f8AutoQueue:|r Off")
    elseif msg == "minimap" then
        AutoAcceptQueueCharDB.minimap.hide = not AutoAcceptQueueCharDB.minimap.hide
        if AutoAcceptQueueCharDB.minimap.hide then
            DBIcon:Hide(addonName)
            print("|cffb048f8AutoQueue:|r Minimap icon hidden")
        else
            DBIcon:Show(addonName)
            print("|cffb048f8AutoQueue:|r Minimap icon visible")
        end
    elseif msg == "roles" then
        ShowRolePopup()
    else
        PrintStatus()
    end
end

-- /lfg
SLASH_AUTOSIGNLFG1 = "/lfg"
SLASH_AUTOSIGNLFG2 = "/autosign"

SlashCmdList["AUTOSIGNLFG"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "on" then
        AutoAcceptQueueCharDB.autoSignLFG = true
        print("|cffb048f8AutoSignLFG:|r On")
    elseif msg == "off" then
        AutoAcceptQueueCharDB.autoSignLFG = false
        print("|cffb048f8AutoSignLFG:|r Off")
    else
        PrintStatus()
    end
end