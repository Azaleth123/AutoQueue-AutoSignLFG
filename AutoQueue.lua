local addonName = "AutoAcceptQueue"
local _, ns = ...
local L = ns.L -- défini dans Locale/enUS.lua (à charger avant ce fichier dans le .toc)

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
    if role == "TANK"   then return "|cff00aeef" .. L.ROLE_TANK   .. "|r" end
    if role == "HEALER" then return "|cff00ff7f" .. L.ROLE_HEALER .. "|r" end
    return "|cffff6060" .. L.ROLE_DPS .. "|r"
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
            if isTank   then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-tank",   14, 14) .. " |cff00aeff " .. L.ROLE_TANK   .. "|r")   end
            if isHealer then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-healer", 14, 14) .. " |cff00ff7f " .. L.ROLE_HEALER .. "|r") end
            if isDPS    then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-dps",    14, 14) .. " |cffff6060 " .. L.ROLE_DPS    .. "|r")    end
            print("|cffb048f8AutoQueue:|r " .. L.SIGNED_UP_AS:format(table.concat(roles, ",  ")))
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
local _applicationDialogHooked  = false

-- Auto-confirms the Group Finder sign-up dialog with the correct roles
local function SetupApplicationDialog()
    if _applicationDialogHooked then return end -- appelé à chaque PLAYER_ENTERING_WORLD : ne pas empiler les hooks
    if LFGListApplicationDialog then
        _applicationDialogHooked = true
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
                    if isTank   then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-tank",   14, 14) .. " |cff00aeff " .. L.ROLE_TANK   .. "|r")   end
                    if isHealer then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-healer", 14, 14) .. " |cff00ff7f " .. L.ROLE_HEALER .. "|r") end
                    if isDPS    then table.insert(roles, CreateAtlasMarkup("roleicon-tiny-dps",    14, 14) .. " |cffff6060 " .. L.ROLE_DPS    .. "|r")    end
                    print("|cffb048f8AutoQueue:|r " .. L.SIGNED_UP_AS:format(table.concat(roles, ",  ")))
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

    -- ATTENTION : c'est une écriture dans une table Blizzard depuis du code addon
    -- (laisse un "nil tainted" dans declines). On la garde pour la fonctionnalité,
    -- mais on n'appelle plus LFGListSearchPanel_UpdateResults() ici : Blizzard vient
    -- de rafraîchir la liste dans son propre handler, et un clic sur l'entrée
    -- redéclenche de toute façon un refresh sécurisé.
    LFGListFrame.declines[partyGUID] = nil
end

---------------------------------------------------------
-- ELLESMEREUI GROUP FINDER COMPATIBILITY
-- EllesmereUI's Group Finder module draws its own results list on top of
-- Blizzard's and fades Blizzard's rows out: those rows never receive clicks
-- anymore, so the OnDoubleClick set in InitializeButtons never fires.
-- We hook EllesmereUI's own rows instead (Buttons exposing .resultID).
-- If EllesmereUI's "quick sign-up" option is ON, EllesmereUI already opens the
-- sign-up dialog itself on (double-)click and our OnShow hook on
-- LFGListApplicationDialog confirms it: we stay out of the way then,
-- otherwise we would sign up twice.
---------------------------------------------------------

local EUI_DOUBLE_CLICK_DELAY = 0.4 -- same window as EllesmereUI's own click counter

local _euiHookedRows = setmetatable({}, { __mode = "k" })
local _euiLastClickID, _euiLastClickTime = nil, 0

-- Read-only copy of the checks done by Blizzard's / EllesmereUI's Sign Up button
local function CanSignUpTo(resultID)
    if not resultID or issecretvalue(resultID) then return false end
    if LFGListApplicationDialog and LFGListApplicationDialog:IsShown() then return false end
    if LFGListUtil_GetActiveQueueMessage and LFGListUtil_GetActiveQueueMessage(true) then return false end
    if LFGListUtil_IsAppEmpowered and not LFGListUtil_IsAppEmpowered() then return false end
    if IsInGroup(LE_PARTY_CATEGORY_HOME) and C_LFGList.IsCurrentlyApplying and C_LFGList.IsCurrentlyApplying() then
        return false
    end

    local _, numActive = C_LFGList.GetNumApplications()
    if type(numActive) == "number" and numActive >= (MAX_LFG_LIST_APPLICATIONS or 5) then return false end

    local tank, healer, dps = C_LFGList.GetAvailableRoles()
    if not (tank or healer or dps) then return false end

    local info = SafeGetSearchResultInfo(resultID)
    if not info or issecretvalue(info.isDelisted) or info.isDelisted then return false end

    local _, status, pending = C_LFGList.GetApplicationInfo(resultID)
    if issecretvalue(status) or issecretvalue(pending) then return false end
    if status == "declined_delisted" then status = "none" end -- delisted then relisted = fresh group
    return status == "none" and not pending
end

local function OnEUIRowClick(self, button)
    if button ~= "LeftButton" then return end
    local id = self.resultID
    if not id then return end
    if EllesmereUIDB and EllesmereUIDB.quickSignup then return end -- EllesmereUI handles the sign-up itself

    local now = GetTime()
    local isDouble = (_euiLastClickID == id) and ((now - _euiLastClickTime) < EUI_DOUBLE_CLICK_DELAY)
    _euiLastClickID, _euiLastClickTime = id, now
    if not isDouble then return end
    _euiLastClickID = nil

    if CanSignUpTo(id) then
        -- AutoQueue's OnShow hook on the dialog picks the roles and confirms
        -- (hold Shift to review the dialog yourself)
        LFGListApplicationDialog_Show(LFGListApplicationDialog, id)
    end
end

-- set further down (needs the declined-groups tables): per-row setup for the
-- red/orange coloring of groups that declined us
local OnEUIRowHooked

-- EllesmereUI creates its rows lazily: list frame (child of the search panel)
-- -> body -> rows. Rows are recognised by their fields, not by a name.
local function HookEUIRows()
    local sp = LFGListFrame and LFGListFrame.SearchPanel
    if not sp then return end
    for _, holder in ipairs({ sp:GetChildren() }) do
        for _, body in ipairs({ holder:GetChildren() }) do
            for _, row in ipairs({ body:GetChildren() }) do
                if not _euiHookedRows[row] and row:GetObjectType() == "Button" and row.rr and row.under then
                    _euiHookedRows[row] = true
                    row:HookScript("OnClick", OnEUIRowClick)
                    if OnEUIRowHooked and row.name then OnEUIRowHooked(row) end
                end
            end
        end
    end
end

local _euiScanPending = false
local function ScheduleEUIScan()
    if _euiScanPending then return end
    _euiScanPending = true
    C_Timer.After(0.2, function()
        _euiScanPending = false
        HookEUIRows()
    end)
end

local _euiPanelHooked = false
local function SetupEUICompat()
    if _euiPanelHooked then return end
    local sp = LFGListFrame and LFGListFrame.SearchPanel
    if not sp then return end
    _euiPanelHooked = true
    -- rows only exist once the panel has been shown with results
    sp:HookScript("OnShow", ScheduleEUIScan)
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

local _declinedColoringHooked = false
local function SetupDeclinedGroupColoring()
    if _declinedColoringHooked then return end
    if not LFGListSearchEntry_Update then
        return
    end
    hooksecurefunc("LFGListSearchEntry_Update", ColorDeclinedGroupName)
    _declinedColoringHooked = true
end

-- Same coloring on EllesmereUI's own list rows. EllesmereUI sets the name color
-- every time it fills a row (always as the last step, after SetText), so we
-- re-apply ours right after each of its SetTextColor calls.
local _coloringEUIRow = false

local function ColorEUIRowName(row)
    local id = row.resultID
    if not row.name or not id or issecretvalue(id) then return end
    local key = GetGroupKey(SafeGetSearchResultInfo(id))
    if not key then return end

    local color
    if IsGroupInTable(hardDeclinedGroups, key) then
        color = COLOR_DECLINED_HARD
    elseif IsGroupInTable(softDeclinedGroups, key) then
        color = COLOR_DECLINED_SOFT
    end
    if not color then return end

    _coloringEUIRow = true -- our own SetTextColor would re-trigger the hook below
    row.name:SetTextColor(color.R, color.G, color.B)
    _coloringEUIRow = false
end

OnEUIRowHooked = function(row)
    hooksecurefunc(row.name, "SetTextColor", function()
        if not _coloringEUIRow then ColorEUIRowName(row) end
    end)
    ColorEUIRowName(row) -- the row may already have been filled before we hooked it
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
-- Remplace LFGListApplicationDialog_Show (global Blizzard) par une copie
-- de la version actuelle SANS l'appel à C_LFGList.ClearApplicationTextFields(),
-- ce qui garde la note d'une inscription à l'autre. L'EditBox est verrouillée
-- (SetSecurityDisableSetText), donc c'est la seule façon de la conserver.
-- ATTENTION : cette fonction s'exécute en tainted (StaticPopupSpecial_Show
-- inclus). C'est le premier suspect si des erreurs de taint reviennent ;
-- à recomparer avec LFGList.lua de Blizzard à chaque patch.
---------------------------------------------------------

local _persistNoteHooked = false

local function SetupPersistNoteHooks()
    if _persistNoteHooked then return end
    if not LFGListApplicationDialog_Show then return end
    _persistNoteHooked = true

    LFGListApplicationDialog_Show = function(self, resultID)
        if not resultID then return end
        self.resultID = resultID
        LFGListApplicationDialog_UpdateRoles(self)
        StaticPopupSpecial_Show(self)
        -- C_LFGList.ClearApplicationTextFields() intentionally omitted
    end
end

---------------------------------------------------------
-- MINIMAP ICON - DataBroker + LibDBIcon
---------------------------------------------------------

local function GetRoleOverrideLabel()
    local db = AutoAcceptQueueCharDB.roleOverride
    local anyChecked = db.tank or db.healer or db.dps
    if not anyChecked then
        return "|cffaaaaaa" .. L.ACTIVE_SPEC .. "|r"
    end
    local parts = {}
    if db.tank   then table.insert(parts, "|cff00aeef" .. L.ROLE_TANK       .. "|r") end
    if db.healer then table.insert(parts, "|cff00ff7f" .. L.ROLE_HEAL_SHORT .. "|r") end
    if db.dps    then table.insert(parts, "|cffff6060" .. L.ROLE_DPS        .. "|r") end
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
            tt:AddLine("|cff00ff00" .. L.TT_ACTIVE_ON .. "|r")
        else
            tt:AddLine("|cffff0000" .. L.TT_ACTIVE_OFF .. "|r")
            tt:AddLine(L.TT_DISABLED_NOTE)
        end
        tt:AddLine(L.HOLD_SHIFT_NOTE)
        tt:AddLine(" ")
        tt:AddLine(L.DETECTED_ROLE:format(GetRoleLabel()))
        tt:AddLine(L.QUEUE_ROLES:format(GetRoleOverrideLabel()))
        tt:AddLine(" ")
        tt:AddLine("|cffb048f8" .. L.LEFT_CLICK .. "|r " .. L.TOGGLE_ONOFF)
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
            SetupEUICompat()
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
        SetupEUICompat()

    elseif event == "PLAYER_ENTERING_WORLD" then
        SetupApplicationDialog()

    elseif event == "LFG_ROLE_CHECK_SHOW" then
        HandleRoleCheck()

    elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
        lfgInitialized = false
        SetupDeclinedGroupColoring()
        SetupGroupAgeTooltip()
        SetupEUICompat()
        C_Timer.After(0.1, function()
            InitializeButtons() -- Blizzard's own rows (EllesmereUI list off, or results it can't read)
            HookEUIRows()       -- EllesmereUI's rows
        end)

    elseif event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
        OnLFGListApplicationStatusUpdated(arg1, arg2)
    end
end)

---------------------------------------------------------
-- SLASH COMMANDS
---------------------------------------------------------

local function PrintStatus()
    local aqStatus   = AutoAcceptQueueCharDB.active      and ("|cff00ff00" .. L.ON .. "|r") or ("|cffff0000" .. L.OFF .. "|r")
    print("------------------------")
    print("|cffb048f8AutoQueue:|r " .. L.STATUS_HEADER)
    print("  • " .. L.STATUS_AUTOQUEUE:format(aqStatus))
    print("  • " .. L.DETECTED_ROLE:format(GetRoleLabel()))
    print("  • " .. L.QUEUE_ROLES:format(GetRoleOverrideLabel()))
    print(" ")
    print("|cffb048f8AutoQueue|r = " .. L.STATUS_DESC)
    print(" ")
    print("|cffb048f8" .. L.COMMANDS .. "|r")
    print("|cffffffff/aq|r |cff00ff00on|r / |cffff0000off|r " .. L.CMD_ONOFF)
    print("|cffffffff/aq minimap|r " .. L.CMD_MINIMAP)
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
        print("|cffb048f8AutoQueue:|r " .. L.ON)
    elseif msg == "off" then
        AutoAcceptQueueCharDB.active = false
        UpdateIcon()
        print("|cffb048f8AutoQueue:|r " .. L.OFF)
    elseif msg == "minimap" then
        AutoAcceptQueueCharDB.minimap.hide = not AutoAcceptQueueCharDB.minimap.hide
        if AutoAcceptQueueCharDB.minimap.hide then
            DBIcon:Hide(addonName)
            print("|cffb048f8AutoQueue:|r " .. L.MINIMAP_HIDDEN)
        else
            DBIcon:Show(addonName)
            print("|cffb048f8AutoQueue:|r " .. L.MINIMAP_SHOWN)
        end
    else
        PrintStatus()
    end
end