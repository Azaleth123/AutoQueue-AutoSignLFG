-- AutoSignLFG Module - Double-clic pour inscription automatique au Group Finder
-- Intégré dans AutoQueue

local frame = CreateFrame("Frame")
local initialized = false

-- Fonction pour gérer le double-clic sur les entrées du Group Finder
local function OnDoubleClick(self, button)
    -- Vérifier si AutoSignLFG est activé
    if not AutoAcceptQueueDB.autoSignLFG then
        return
    end
    
    -- Vérifier que l'entrée existe toujours
    local resultExists = not LFGListFrame.SearchPanel.SignUpButton.tooltip
    
    if resultExists then
        LFGListSearchPanel_SignUp(self:GetParent():GetParent():GetParent())
    end
end

-- Fonction d'initialisation des boutons
local function InitializeButtons()
    if not LFGListFrame or not LFGListFrame.SearchPanel or not LFGListFrame.SearchPanel.ScrollBox then
        return
    end
    
    local scrollTarget = LFGListFrame.SearchPanel.ScrollBox:GetScrollTarget()
    if not scrollTarget then
        return
    end
    
    local buttons = {scrollTarget:GetChildren()}
    
    for _, child in ipairs(buttons) do
        -- Vérifier que c'est un Button et qu'il a la méthode SetScript
        if child and child:GetObjectType() == "Button" and not child.autoSignInitialized then
            child:SetScript("OnDoubleClick", OnDoubleClick)
            child:RegisterForClicks("AnyUp")
            child.autoSignInitialized = true
        end
    end
    
    initialized = true
end

-- Auto-accepter la vérification des rôles
-- CORRECTION: Cette fonction doit AUSSI vérifier AutoAcceptQueueDB.active !
local function SetupRoleCheckAutoAccept()
    if LFDRoleCheckPopupAcceptButton then
        LFDRoleCheckPopupAcceptButton:SetScript("OnShow", function()
            -- IMPORTANT: Vérifier AUSSI si AutoQueue est activé !
            if AutoAcceptQueueDB.autoSignLFG and AutoAcceptQueueDB.active then
                LFDRoleCheckPopupAcceptButton:Click()
            end
        end)
    end
end

-- Gérer le dialogue d'inscription (avec Shift pour inscription normale)
local function SetupApplicationDialog()
    if LFGListApplicationDialog then
        LFGListApplicationDialog:SetScript("OnShow", function()
            -- Si AutoSignLFG est désactivé, ne rien faire
            if not AutoAcceptQueueDB.autoSignLFG then
                return
            end
            
            -- Si Shift est maintenu, ne pas auto-cliquer (inscription normale)
            if not IsShiftKeyDown() then
                LFGListApplicationDialog.SignUpButton:Click()
            end
        end)
    end
end

-- Gestionnaire d'événements
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        -- Initialiser les scripts au chargement
        SetupRoleCheckAutoAccept()
        SetupApplicationDialog()
        
    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        -- Réinitialiser les boutons à chaque nouvelle recherche
        initialized = false
        C_Timer.After(0.1, InitializeButtons)
    end
end)