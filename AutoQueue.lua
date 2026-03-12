-- AutoAcceptQueue.lua - Version sécurisée avec SecureHandlers
local addonName = "AutoAcceptQueue"

-- Variables sauvegardées - Initialisation par défaut
AutoAcceptQueueDB = AutoAcceptQueueDB or {
    minimap = { hide = false },
    active = true,
    autoSignLFG = true
}

-- État interne
_G.AQ = _G.AQ or {}

---------------------------------------------------------
-- Boutons sécurisés pour auto-accept (SOLUTION PROPRE)
---------------------------------------------------------
-- Créer un bouton sécurisé invisible pour le role check
local roleCheckButton = CreateFrame("Button", "AutoQueueRoleCheckButton", UIParent, "SecureActionButtonTemplate")
roleCheckButton:Hide()
roleCheckButton:SetAttribute("type", "click")

-- Créer un bouton sécurisé invisible pour accepter la proposition
local proposalButton = CreateFrame("Button", "AutoQueueProposalButton", UIParent, "SecureActionButtonTemplate")
proposalButton:Hide()
proposalButton:SetAttribute("type", "click")

---------------------------------------------------------
-- Hooks sécurisés sur les dialogues Blizzard
---------------------------------------------------------
local function SetupSecureHooks()
    -- Hook le dialogue de role check
    if LFDRoleCheckPopup and LFDRoleCheckPopupAcceptButton then
        roleCheckButton:SetAttribute("clickbutton", LFDRoleCheckPopupAcceptButton)
        
        hooksecurefunc("LFGDungeonReadyStatus_ResetReadyStates", function()
            if AutoAcceptQueueDB.active and LFDRoleCheckPopup:IsShown() then
                C_Timer.After(0.1, function()
                    if AutoAcceptQueueDB.active and not InCombatLockdown() then
                        roleCheckButton:Click()
                    end
                end)
            end
        end)
    end
    
    -- Hook le dialogue de queue ready
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
-- Toggle + icon update
---------------------------------------------------------
local function UpdateIcon()
    local icon = AutoAcceptQueueDB.active and "Interface\\COMMON\\Indicator-Green" or "Interface\\COMMON\\Indicator-Red"
    if AutoAcceptQueueLDB then
        AutoAcceptQueueLDB.icon = icon
    end
end

local function ToggleMode()
    AutoAcceptQueueDB.active = not AutoAcceptQueueDB.active
    UpdateIcon()
end

---------------------------------------------------------
-- DataBroker + LibDBIcon
---------------------------------------------------------
local LDB = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

AutoAcceptQueueLDB = LDB:NewDataObject(addonName, {
    type = "launcher",
    icon = "Interface\\COMMON\\Indicator-Green",
    OnClick = function(_, button)
        if button == "LeftButton" then
            ToggleMode()
        end
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
        tt:AddLine("|cffffd200Left click:|r On / Off")
    end,
})

---------------------------------------------------------
-- Events
---------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_LOGIN" then
        AutoAcceptQueueDB.minimap = AutoAcceptQueueDB.minimap or { hide = false }
        AutoAcceptQueueDB.autoSignLFG = AutoAcceptQueueDB.autoSignLFG ~= false
        DBIcon:Register(addonName, AutoAcceptQueueLDB, AutoAcceptQueueDB.minimap)
        UpdateIcon()
        
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_LFGList" then
        -- Initialiser les hooks sécurisés une fois que l'UI Blizzard est chargée
        SetupSecureHooks()
    end
end)

---------------------------------------------------------
-- Commandes /aq
---------------------------------------------------------
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
        -- Afficher le statut général
        local aqStatus = AutoAcceptQueueDB.active and "|cff00ff00On|r" or "|cffff0000Off|r"
        local lfgStatus = AutoAcceptQueueDB.autoSignLFG and "|cff00ff00On|r" or "|cffff0000Off|r"
        
        print("------------------------")
        print("|cffb048f8AutoQueue:|r Status:")
        print("  • AutoQueue: " .. aqStatus)
        print("  • AutoSignLFG: " .. lfgStatus)
        print(" ")
        print("|cffb048f8AutoQueue|r = Lets you auto click the ''Accept'' when your group leader tries to sign up for something.")
        print("|cffb048f8AutoSignLFG|r = Auto Signup in LFG with double-click.(Hold Shift to sign up the normal way.)")
        print(" ")
        print("|cffb048f8Available commands :|r")
        print("|cffffffff/aq on|r - Turn on AutoQueue")
        print("|cffffffff/aq off|r - Turn off AutoQueue")
        print("|cffffffff/aq minimap|r - Toggle minimap icon")
        print("|cffffffff/lfg on|r - Turn on AutoSignLFG")
        print("|cffffffff/lfg off|r - Turn off AutoSignLFG")
        print("------------------------")
    end
end

---------------------------------------------------------
-- Commandes /lfg pour AutoSignLFG
---------------------------------------------------------
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
        -- Afficher le statut général
        local aqStatus = AutoAcceptQueueDB.active and "|cff00ff00On|r" or "|cffff0000Off|r"
        local lfgStatus = AutoAcceptQueueDB.autoSignLFG and "|cff00ff00On|r" or "|cffff0000Off|r"
        
        print("------------------------")
        print("|cffb048f8AutoQueue:|r Status:")
        print("  • AutoQueue: " .. aqStatus)
        print("  • AutoSignLFG: " .. lfgStatus)
        print(" ")
        print("|cffb048f8AutoQueue|r = Lets you auto click the ''Accept'' when your group leader tries to sign up for something.")
        print("|cffb048f8AutoSignLFG|r = Auto Signup in LFG with double-click.(Hold Shift to sign up the normal way.)")
        print(" ")
        print("|cffb048f8Available commands :|r")
        print("|cffffffff/aq on|r - Turn on AutoQueue")
        print("|cffffffff/aq off|r - Turn off AutoQueue")
        print("|cffffffff/aq minimap|r - Toggle minimap icon")
        print("|cffffffff/lfg on|r - Turn on AutoSignLFG")
        print("|cffffffff/lfg off|r - Turn off AutoSignLFG")
        print("------------------------")
    end
end