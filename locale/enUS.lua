local _, ns = ...

-- Une clé inconnue (faute de frappe dans le code) renvoie son propre
-- nom au lieu de planter sur un nil.
local L = setmetatable({}, { __index = function(_, key) return key end })
ns.L = L

-- Rôles
L.ROLE_TANK        = "Tank"
L.ROLE_HEALER      = "Heal"
L.ROLE_HEAL_SHORT  = "Heal"
L.ROLE_DPS         = "DPS"
L.ACTIVE_SPEC      = "(active spec)"

-- États
L.ON               = "On"
L.OFF              = "Off"
L.ENABLED          = "Enabled"
L.DISABLED         = "Disabled"

-- Message d'inscription (chat)
L.SIGNED_UP_AS     = "Signed up as: %s"

-- Infobulle de l'icône minimap
L.TT_ACTIVE_ON     = "Auto Accept Queue: On"
L.TT_ACTIVE_OFF    = "Auto Accept Queue: Off"
L.TT_DISABLED_NOTE = "Auto-accept is currently disabled."
L.HOLD_SHIFT_NOTE  = "Hold SHIFT to put a note."
L.DETECTED_ROLE    = "Detected role: %s"
L.QUEUE_ROLES      = "Queue roles: %s"
L.LEFT_CLICK       = "Left-click:"
L.TOGGLE_ONOFF     = "On / Off"

-- /aq (statut + commandes)
L.STATUS_HEADER    = "Status:"
L.STATUS_AUTOQUEUE = "AutoQueue: %s"
L.STATUS_DESC      = "Auto-accept when your leader signs up for something. Also signs you up automatically in LFG/Group Finder. (Hold Shift to sign up manually)"
L.COMMANDS         = "Commands:"
L.CMD_ONOFF        = "- Enable / Disable AutoQueue"
L.CMD_MINIMAP      = "- Show / Hide minimap icon"
L.MINIMAP_HIDDEN   = "Minimap icon hidden"
L.MINIMAP_SHOWN    = "Minimap icon visible"

-- Barre de rôles (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(none checked = use active spec role)"
L.SUBTITLE_NOTE    = "(Hold SHIFT to put a note)"
L.NOT_AVAILABLE    = "Not available for this class"
L.TOGGLE_TT        = "Show / Hide the role selection"
L.GOT_IT           = "Got it!"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r: click here to show/hide the role selection, letting you queue for multiple roles or a different spec. If no selection is made, your current spec role applies."
L.TUTORIAL_SAVED   = "Settings are saved per character."
L.TUTORIAL_TIP     = "|cffffff00Pro Tip: you can double-click to queue faster.|r"
