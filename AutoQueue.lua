-- AutoQueue.lua
-- Fusion de AutoQueue + AutoSignLFG
local addonName = "AutoAcceptQueue"

-- Variables sauvegardées - Initialisation par défaut
AutoAcceptQueueDB = AutoAcceptQueueDB or {
    minimap     = { hide = false },
    active      = true,
    autoSignLFG = true,
}

---------------------------------------------------------
-- DÉTECTION DU RÔLE
---------------------------------------------------------

-- Retourne "TANK", "HEALER" ou "DAMAGER" selon la spé active
local function GetCurrentRole()
    local specIndex = GetSpecialization()
    if not specIndex then return "DAMAGER" end
    return GetSpecializationRole(specIndex) or "DAMAGER"
end

-- Retourne un label coloré pour l'affichage (tooltip, /aq status)
local function GetRoleLabel()
    local role = GetCurrentRole()
    if role == "TANK"   then return "|cff00aeefTank|r"   end
    if role == "HEALER" then return "|cff00ff7fHealer|r" end
    return "|cffff6060DPS|r"
end

---------------------------------------------------------
-- AUTOQUEUE - Bouton sécurisé pour auto-accept donjon prêt
---------------------------------------------------------

local proposalButton = CreateFrame("Button", "AutoQueueProposalButton", UIParent, "SecureActionButtonTemplate")
proposalButton:Hide()
proposalButton:SetAttribute("type", "click")

local function SetupSecureHooks()
    if LFGDungeonReadyDialog and LFGDungeonReadyDialogEnterDungeonButton then
        proposalButton:SetAttribute("clickbutton", LFGDungeonReadyDialogEnterDungeonButton)

        hooksecurefunc("LFGDungeonReadyPopup_Update", function()
            if AutoAcceptQueueDB.active and LFGDungeonReadyDialog:IsShown() then
                C_Timer.After(0.2, function()
                    if AutoAcceptQueueDB.active and not InCombatLockdown() then
                        proposalButton:Click()
                    end
                end)
            end
        end)
    end
end

---------------------------------------------------------
-- AUTOSIGNLFG - Role check + double-clic Group Finder
---------------------------------------------------------

local lfgInitialized = false

-- Confirme le role check LFD avec le bon rôle selon la spé
local function HandleRoleCheck()
    if not AutoAcceptQueueDB.autoSignLFG then return end
    if not AutoAcceptQueueDB.active then return end

    local role     = GetCurrentRole()
    local isLeader = GetLFGRoles()

    -- SetLFGRoles enregistre le rôle côté client, comme LFDRoleCheckPopupAccept_OnClick
    SetLFGRoles(isLeader, role == "TANK", role == "HEALER", role == "DAMAGER")
    CompleteLFGRoleCheck(true)
end

-- Auto-confirme la popup d'inscription Group Finder avec le bon rôle
local function SetupApplicationDialog()
    if LFGListApplicationDialog then
        LFGListApplicationDialog:SetScript("OnShow", function()
            if not AutoAcceptQueueDB.autoSignLFG then return end
            if not IsShiftKeyDown() then
                local role     = GetCurrentRole()
                local isLeader = GetLFGRoles()
                SetLFGRoles(isLeader, role == "TANK", role == "HEALER", role == "DAMAGER")
                LFGListApplicationDialog.SignUpButton:Click()
            end
        end)
    end
end

-- Double-clic sur une entrée du Group Finder pour s'inscrire
local function OnDoubleClick(self)
    if not AutoAcceptQueueDB.autoSignLFG then return end
    local resultExists = not LFGListFrame.SearchPanel.SignUpButton.tooltip
    if resultExists then
        LFGListSearchPanel_SignUp(self:GetParent():GetParent():GetParent())
    end
end

-- Initialise les boutons de double-clic sur les résultats de recherche
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
-- MINIMAP ICON - DataBroker + LibDBIcon
---------------------------------------------------------

local function UpdateIcon()
    local icon = AutoAcceptQueueDB.active
        and "Interface\\COMMON\\Indicator-Green"
        or  "Interface\\COMMON\\Indicator-Red"
    if AutoAcceptQueueLDB then
        AutoAcceptQueueLDB.icon = icon
    end
end

local function ToggleMode()
    AutoAcceptQueueDB.active = not AutoAcceptQueueDB.active
    UpdateIcon()
end

local LDB    = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

AutoAcceptQueueLDB = LDB:NewDataObject(addonName, {
    type  = "launcher",
    icon  = "Interface\\COMMON\\Indicator-Green",
    OnClick = function(_, button)
        if button == "LeftButton" then ToggleMode() end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("|cffb048f8AutoQueue|r")
        tt:AddLine(" ")
        if AutoAcceptQueueDB.active then
            tt:AddLine("|cff00ff00Status: On|r")
            tt:AddLine("Lets you auto click the ''Accept'' when your")
            tt:AddLine("group leader tries to sign up for something.")
        else
            tt:AddLine("|cffff0000Status: Off|r")
            tt:AddLine("Auto-accept is currently disabled.")
        end
        tt:AddLine(" ")
        tt:AddLine("Detected role: " .. GetRoleLabel())
        tt:AddLine(" ")
        tt:AddLine("|cffffd200Left click:|r On / Off")
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
        AutoAcceptQueueDB.minimap     = AutoAcceptQueueDB.minimap or { hide = false }
        AutoAcceptQueueDB.autoSignLFG = AutoAcceptQueueDB.autoSignLFG ~= false
        DBIcon:Register(addonName, AutoAcceptQueueLDB, AutoAcceptQueueDB.minimap)
        UpdateIcon()

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
-- COMMANDES SLASH
---------------------------------------------------------

local function PrintStatus()
    local aqStatus  = AutoAcceptQueueDB.active      and "|cff00ff00On|r" or "|cffff0000Off|r"
    local lfgStatus = AutoAcceptQueueDB.autoSignLFG and "|cff00ff00On|r" or "|cffff0000Off|r"
    print("------------------------")
    print("|cffb048f8AutoQueue:|r Status:")
    print("  • AutoQueue: "     .. aqStatus)
    print("  • AutoSignLFG: "   .. lfgStatus)
    print("  • Detected role: " .. GetRoleLabel())
    print(" ")
    print("|cffb048f8AutoQueue|r = Auto-accept when your leader signs up for something.")
    print("|cffb048f8AutoSignLFG|r = Double-click to sign up in LFG. (Hold Shift to sign up manually)")
    print(" ")
    print("|cffb048f8Commands:|r")
    print("|cffffffff/aq|r |cff00ff00On|r / |cffff0000Off|r - Enable / Disable AutoQueue")
    print("|cffffffff/aq minimap|r - Show / Hide minimap icon")
    print("|cffffffff/lfg|r |cff00ff00On|r / |cffff0000Off|r - Enable / Disable AutoSignLFG")
    print("------------------------")
end

-- /aq
SLASH_AUTOQUEUE1 = "/aq"
SLASH_AUTOQUEUE2 = "/autoqueue"

SlashCmdList["AUTOQUEUE"] = function(msg)
    msg = (msg or ""):lower()
    if msg == "on" then
        AutoAcceptQueueDB.active = true
        UpdateIcon()
        print("|cffb048f8AutoQueue:|r On")
    elseif msg == "off" then
        AutoAcceptQueueDB.active = false
        UpdateIcon()
        print("|cffb048f8AutoQueue:|r Off")
    elseif msg == "minimap" then
        AutoAcceptQueueDB.minimap.hide = not AutoAcceptQueueDB.minimap.hide
        if AutoAcceptQueueDB.minimap.hide then
            DBIcon:Hide(addonName)
            print("|cffb048f8AutoQueue:|r Minimap icon hidden")
        else
            DBIcon:Show(addonName)
            print("|cffb048f8AutoQueue:|r Minimap icon visible")
        end
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
        AutoAcceptQueueDB.autoSignLFG = true
        print("|cffb048f8AutoSignLFG:|r On")
    elseif msg == "off" then
        AutoAcceptQueueDB.autoSignLFG = false
        print("|cffb048f8AutoSignLFG:|r Off")
    else
        PrintStatus()
    end
end