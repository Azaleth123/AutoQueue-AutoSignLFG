local addonName = "AutoAcceptQueue"

-- Saved variables - Default initialization
AutoAcceptQueueCharDB = AutoAcceptQueueCharDB or {
    minimap        = { hide = false },
    active         = true,
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
-- Role check + double-click Group Finder (toujours actif)
---------------------------------------------------------

local lfgInitialized = false

-- Confirms the LFD role check with the correct role (override or active spec)
local _roleCheckPrinted = false

local _lastRoleCheckAcceptTime = 0
local ROLE_CHECK_DEBOUNCE = 1.0

local function HandleRoleCheck()
    if not AutoAcceptQueueCharDB.active then return end
    local now = GetTime()
    if (now - _lastRoleCheckAcceptTime) < ROLE_CHECK_DEBOUNCE then return end
    _lastRoleCheckAcceptTime = now

    local isTank, isHealer, isDPS = GetEffectiveRoles()
    local isLeader = GetLFGRoles()
    SetLFGRoles(isLeader, isTank, isHealer, isDPS)

    if not _roleCheckPrinted then
        _roleCheckPrinted = true
        if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
            local roles = {}
            if isTank   then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-tank",   14, 14) .. " |cff00aeff Tank|r")   end
            if isHealer then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-healer", 14, 14) .. " |cff00ff7f Healer|r") end
            if isDPS    then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-dps",    14, 14) .. " |cffff6060 DPS|r")    end
            print("|cffb048f8AutoQueue:|r Signed up as: " .. table.concat(roles, ",  "))
        end
        C_Timer.After(2, function() _roleCheckPrinted = false end)
    end

    CompleteLFGRoleCheck(true)
end

-- Polling fallback: vérifie toutes les 0.4s si le popup LFD est visible.
-- Pur filet de sécurité si event+hook ont raté le tout premier show ; le
-- debounce dans HandleRoleCheck empêche ça de spammer l'API.
local function ThinkLFD()
    if LFDRoleCheckPopup and LFDRoleCheckPopup:IsVisible() then
        if AutoAcceptQueueCharDB.active then
            HandleRoleCheck()
        end
        C_Timer.After(0.2, ThinkLFD)
    else
        C_Timer.After(0.4, ThinkLFD)
    end
end

-- Hook sur l'affichage du popup : réagit dès qu'il apparaît, sans attendre
-- l'event LFG_ROLE_CHECK_SHOW ni le polling ci-dessous. Le debounce temporel
-- dans HandleRoleCheck se charge lui-même de filtrer le spam ET de laisser
-- passer un vrai nouveau role check ; plus besoin de réinitialiser quoi que
-- ce soit ici à OnShow/OnHide.
local _roleCheckHookSetup = false

local function SetupRoleCheckHook()
    if _roleCheckHookSetup then return end
    if LFDRoleCheckPopup then
        LFDRoleCheckPopup:HookScript("OnShow", function()
            if AutoAcceptQueueCharDB.active then
                HandleRoleCheck()
            end
        end)
        _roleCheckHookSetup = true
    end
end

local _applicationDialogHandled = false

-- Auto-confirms the Group Finder sign-up dialog with the correct roles
local function SetupApplicationDialog()
    if LFGListApplicationDialog then
        LFGListApplicationDialog:HookScript("OnShow", function()
            if _applicationDialogHandled then return end
            if not IsShiftKeyDown() then
                _applicationDialogHandled = true
                C_Timer.After(0.5, function() _applicationDialogHandled = false end)

                local isTank, isHealer, isDPS = GetEffectiveRoles()
                local isLeader = GetLFGRoles()
                SetLFGRoles(isLeader, isTank, isHealer, isDPS)

                if not IsInGroup(LE_PARTY_CATEGORY_HOME) then
                    local roles = {}
                    if isTank   then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-tank",   14, 14) .. " |cff00aeff Tank|r")   end
                    if isHealer then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-healer", 14, 14) .. " |cff00ff7f Healer|r") end
                    if isDPS    then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-dps",    14, 14) .. " |cffff6060 DPS|r")    end
                    print("|cffb048f8AutoQueue:|r Signed up as: " .. table.concat(roles, ",  "))
                end

                LFGListApplicationDialog.SignUpButton:Click()
            end
        end)
    end
end

-- Double-click a Group Finder entry to sign up
local function OnDoubleClick(self)
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
-- RE-APPLY TO DECLINED GROUPS
---------------------------------------------------------

local issecretvalue = issecretvalue or function() return false end
local canaccesstable = canaccesstable or function() return true end
local function IsAccessibleTable(value)
    return not issecretvalue(value) and canaccesstable(value)
end

local function SafeGetSearchResultInfo(resultID)
    local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
    if not searchResultInfo or not IsAccessibleTable(searchResultInfo) then
        return nil
    end
    return searchResultInfo
end

-- Stable identifier for a group across list refreshes AND relistings.
-- leaderName+activityID identifies the *player*, which is what we actually
-- want to remember ("this person declined me") — partyGUID identifies the
-- listing itself and changes every time the leader deletes and recreates
-- their post (even under a different title), so it's only used as a
-- fallback for brand new listings where leaderName isn't populated yet.
local function GetGroupKey(searchResultInfo)
    if not searchResultInfo then return nil end
    if searchResultInfo.leaderName and not issecretvalue(searchResultInfo.leaderName) then
        local activityIDs = searchResultInfo.activityIDs
        local activityID = searchResultInfo.activityID
            or (not issecretvalue(activityIDs) and activityIDs and activityIDs[1])
        return activityID and (activityID .. searchResultInfo.leaderName) or nil
    elseif not issecretvalue(searchResultInfo.partyGUID) and searchResultInfo.partyGUID then
        return searchResultInfo.partyGUID
    end
    return nil
end

-- Removes Blizzard's own decline-blacklist entry for this group so the
-- normal sign-up flow is allowed again on the next refresh. Blizzard keys
-- this table strictly by partyGUID (see LFGListFrame.declines[partyGUID]
-- in the default UI), so this must NOT use our own leaderName-based
-- GetGroupKey — that key is only for our persistent tracking/coloring.
local function ClearBlizzardDeclineBlock(resultID)
    if not LFGListFrame or not LFGListFrame.declines then return end
    local searchResultInfo = SafeGetSearchResultInfo(resultID)
    if not searchResultInfo then return end
    local partyGUID = searchResultInfo.partyGUID
    if not partyGUID or issecretvalue(partyGUID) then return end

    LFGListFrame.declines[partyGUID] = nil -- remove from Blizzard's list to allow re-applying to this group

    if LFGListFrame.SearchPanel then
        LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel) -- refresh without re-sorting
    end
end

---------------------------------------------------------
-- DECLINED / DELISTED GROUP COLORING
---------------------------------------------------------

local DECLINED_GROUPS_RESET = 60 * 15 -- forget a decline after 15 minutes

local COLOR_DECLINED_HARD = { R = 1.0, G = 0.1, B = 0.1 } -- red   - declined
local COLOR_DECLINED_SOFT = { R = 1.0, G = 0.4, B = 0.1 } -- orange - delisted/full/timed out

local hardDeclinedGroups = {} -- [groupKey] = time() -- appStatus == "declined"
local softDeclinedGroups = {} -- [groupKey] = time() -- declined_delisted / declined_full / timedout

local function IsGroupInTable(lookupTable, key)
    if not key then return false end
    local lastSeen = lookupTable[key] or 0
    return lastSeen > time() - DECLINED_GROUPS_RESET
end

-- Colors the group name red/orange if it previously declined/delisted us
local function ColorDeclinedGroupName(self)
    if not self.Name or not self.resultID then return end
    local searchResultInfo = SafeGetSearchResultInfo(self.resultID)
    local key = GetGroupKey(searchResultInfo)
    if not key then return end

    if IsGroupInTable(hardDeclinedGroups, key) then
        self.Name:SetTextColor(COLOR_DECLINED_HARD.R, COLOR_DECLINED_HARD.G, COLOR_DECLINED_HARD.B)
    elseif IsGroupInTable(softDeclinedGroups, key) then
        self.Name:SetTextColor(COLOR_DECLINED_SOFT.R, COLOR_DECLINED_SOFT.G, COLOR_DECLINED_SOFT.B)
    end
end

local function OnLFGListSearchPanelUpdateResultList(self)
    if self then
        LFGListSearchPanel_UpdateResults(self)
    end
end

local _declinedColoringHooked = false
local function SetupDeclinedGroupColoring()
    if _declinedColoringHooked then return end
    if not LFGListSearchEntry_Update or not LFGListSearchPanel_UpdateResultList then
        return
    end
    hooksecurefunc("LFGListSearchEntry_Update", ColorDeclinedGroupName)
    hooksecurefunc("LFGListSearchPanel_UpdateResultList", OnLFGListSearchPanelUpdateResultList)
    _declinedColoringHooked = true
end

-- possible newStatus values: declined, declined_full, declined_delisted, timedout
local function OnLFGListApplicationStatusUpdated(id, newStatus)
    local searchResultInfo = SafeGetSearchResultInfo(id)
    local key = GetGroupKey(searchResultInfo)

    if newStatus == "declined" then
        if key then hardDeclinedGroups[key] = time() end
        ClearBlizzardDeclineBlock(id)
    elseif newStatus == "declined_full" or newStatus == "declined_delisted" or newStatus == "timedout" then
        if key then softDeclinedGroups[key] = time() end
        ClearBlizzardDeclineBlock(id)
    end
end

---------------------------------------------------------
-- GROUP AGE IN TOOLTIP (restores line dropped by Blizzard in 10.2.7)
---------------------------------------------------------

local function IsPGFLoaded()
    return (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("PremadeGroupsFilter"))
        or (IsAddOnLoaded and IsAddOnLoaded("PremadeGroupsFilter"))
end

local function AddGroupAgeToTooltip(tooltip, resultID, autoAcceptOption)
    if IsPGFLoaded() then return end -- PGF already restores this line itself (its own age display)

    local searchResultInfo = SafeGetSearchResultInfo(resultID)
    if not searchResultInfo or not searchResultInfo.age or searchResultInfo.age <= 0 then return end
    if not tooltip or not tooltip:IsShown() then return end

    tooltip:AddLine(" ")
    tooltip:AddLine(string.format(LFG_LIST_TOOLTIP_AGE, SecondsToTime(searchResultInfo.age, false, false, 1, false)))
    tooltip:Show()
end

local _groupAgeTooltipHooked = false
local function SetupGroupAgeTooltip()
    if _groupAgeTooltipHooked then return end
    if not LFGListUtil_SetSearchEntryTooltip then return end
    hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", AddGroupAgeToTooltip)
    _groupAgeTooltipHooked = true
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

local _aqMinimapBtn = nil

local function RefreshTooltip()
    if _aqMinimapBtn and _aqMinimapBtn:IsMouseOver() then
        local onLeave = _aqMinimapBtn:GetScript("OnLeave")
        local onEnter = _aqMinimapBtn:GetScript("OnEnter")
        if onLeave then onLeave(_aqMinimapBtn) end
        if onEnter then onEnter(_aqMinimapBtn) end
    end
end

local function ToggleMode()
    AutoAcceptQueueCharDB.active = not AutoAcceptQueueCharDB.active
    UpdateIcon()
    RefreshTooltip()
end

local LDB    = LibStub("LibDataBroker-1.1")
local DBIcon = LibStub("LibDBIcon-1.0")

AutoAcceptQueueLDB = LDB:NewDataObject(addonName, {
    type  = "launcher",
    icon  = "Interface\\COMMON\\Indicator-Green",
    OnClick = function(_, button)
        if button == "LeftButton" then
            ToggleMode()
        end
    end,
    OnTooltipShow = function(tt)
        tt:AddLine("|cffb048f8AutoQueue|r")
        tt:AddLine(" ")
        if AutoAcceptQueueCharDB.active then
            tt:AddLine("|cff00ff00Auto Accept Queue: On|r")
        else
            tt:AddLine("|cffff0000Auto Accept Queue: Off|r")
            tt:AddLine("Auto-accept is currently disabled.")
        end
        tt:AddLine("Hold SHIFT to put a note.")
        tt:AddLine(" ")
        tt:AddLine("Detected role: " .. GetRoleLabel())
        tt:AddLine("Queue roles: "   .. GetRoleOverrideLabel())
        tt:AddLine(" ")
        tt:AddLine("|cffb048f8Left-click:|r On / Off")
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
eventFrame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "PLAYER_LOGIN" then
        AutoAcceptQueueCharDB.minimap      = AutoAcceptQueueCharDB.minimap or { hide = false }
        AutoAcceptQueueCharDB.roleOverride = AutoAcceptQueueCharDB.roleOverride or { tank = false, healer = false, dps = false }
        DBIcon:Register(addonName, AutoAcceptQueueLDB, AutoAcceptQueueCharDB.minimap)
        UpdateIcon()
        SetupPersistNoteHooks()
        SetupRoleCheckHook()
        ThinkLFD()

        local isLFGListLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("Blizzard_LFGList"))
            or (IsAddOnLoaded and IsAddOnLoaded("Blizzard_LFGList"))
        if isLFGListLoaded then
            SetupSecureHooks()
            SetupDeclinedGroupColoring()
            SetupGroupAgeTooltip()
        end

        _aqMinimapBtn = DBIcon:GetMinimapButton(addonName)
        if _aqMinimapBtn then
            local _origEnter = _aqMinimapBtn:GetScript("OnEnter")
            local _origLeave = _aqMinimapBtn:GetScript("OnLeave")
            _aqMinimapBtn:SetScript("OnEnter", function(self)
                if _origEnter then _origEnter(self) end
            end)
            _aqMinimapBtn:SetScript("OnLeave", function(self)
                if _origLeave then _origLeave(self) end
            end)
        end
    elseif event == "ADDON_LOADED" and arg1 == "Blizzard_LFGList" then
        SetupSecureHooks()
        SetupDeclinedGroupColoring()
        SetupGroupAgeTooltip()

    elseif event == "PLAYER_ENTERING_WORLD" then
        SetupApplicationDialog()

    elseif event == "LFG_ROLE_CHECK_SHOW" then
        HandleRoleCheck()

    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        lfgInitialized = false
        SetupDeclinedGroupColoring()
        SetupGroupAgeTooltip()
        C_Timer.After(0.1, InitializeButtons)

    elseif event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
        OnLFGListApplicationStatusUpdated(arg1, arg2)
    end
end)

---------------------------------------------------------
-- SLASH COMMANDS
---------------------------------------------------------

local function PrintStatus()
    local aqStatus   = AutoAcceptQueueCharDB.active      and "|cff00ff00On|r" or "|cffff0000Off|r"
    print("------------------------")
    print("|cffb048f8AutoQueue:|r Status:")
    print("  • AutoQueue: "        .. aqStatus)
    print("  • Detected role: "    .. GetRoleLabel())
    print("  • Queue roles: "      .. GetRoleOverrideLabel())
    print(" ")
    print("|cffb048f8AutoQueue|r = Auto-accept when your leader signs up for something. Also signs you up automatically in LFG/Group Finder. (Hold Shift to sign up manually)")
    print(" ")
    print("|cffb048f8Commands:|r")
    print("|cffffffff/aq|r |cff00ff00on|r / |cffff0000off|r - Enable / Disable AutoQueue")
    print("|cffffffff/aq minimap|r - Show / Hide minimap icon")
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
    else
        PrintStatus()
    end
end