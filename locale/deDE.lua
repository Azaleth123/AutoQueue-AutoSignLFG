if GetLocale() ~= "deDE" then return end

local _, ns = ...
local L = ns.L

-- Rollen
L.ROLE_TANK        = "Tank"
L.ROLE_HEALER      = "Heiler"
L.ROLE_HEAL_SHORT  = "Heiler"
L.ROLE_DPS         = "DPS"
L.ACTIVE_SPEC      = "(aktive Spezialisierung)"

-- Status
L.ON               = "Aktiviert"
L.OFF              = "Deaktiviert"
L.ENABLED          = "Aktiviert"
L.DISABLED         = "Deaktiviert"

-- Anmeldenachricht (Chat)
L.SIGNED_UP_AS     = "Angemeldet als: %s"

-- Minimap-Symbol Tooltip
L.TT_ACTIVE_ON     = "Automatische Annahme: aktiviert"
L.TT_ACTIVE_OFF    = "Automatische Annahme: deaktiviert"
L.TT_DISABLED_NOTE = "Die automatische Annahme ist derzeit deaktiviert."
L.HOLD_SHIFT_NOTE  = "Halte UMSCHALT gedrückt, um eine Notiz hinzuzufügen."
L.DETECTED_ROLE    = "Erkannte Rolle: %s"
L.QUEUE_ROLES      = "Rollen für die Warteschlange: %s"
L.LEFT_CLICK       = "Linksklick:"
L.TOGGLE_ONOFF     = "Aktivieren / Deaktivieren"

-- /aq (Status + Befehle)
L.STATUS_HEADER    = "Status:"
L.STATUS_AUTOQUEUE = "AutoQueue: %s"
L.STATUS_DESC      = "Nimmt automatisch an, wenn dein Gruppenleiter dich für eine Aktivität anmeldet. Meldet dich außerdem automatisch über die Gruppensuche (LFG) an. (Halte UMSCHALT gedrückt, um dich manuell anzumelden)"
L.COMMANDS         = "Befehle:"
L.CMD_ONOFF        = "- AutoQueue aktivieren / deaktivieren"
L.CMD_MINIMAP      = "- Minimap-Symbol anzeigen / ausblenden"
L.MINIMAP_HIDDEN   = "Minimap-Symbol ausgeblendet"
L.MINIMAP_SHOWN    = "Minimap-Symbol angezeigt"

-- Rollenleiste (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(nichts ausgewählt = Rolle der aktiven Spezialisierung)"
L.SUBTITLE_NOTE    = "(Halte UMSCHALT gedrückt, um eine Notiz hinzuzufügen)"
L.NOT_AVAILABLE    = "Für diese Klasse nicht verfügbar"
L.TOGGLE_TT        = "Rollenauswahl anzeigen / ausblenden"
L.GOT_IT           = "Verstanden!"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r: Klicke hier, um die Rollenauswahl anzuzeigen/auszublenden, mit der du dich mit mehreren Rollen oder einer anderen Spezialisierung anmelden kannst. Ohne Auswahl gilt die Rolle deiner aktuellen Spezialisierung."
L.TUTORIAL_SAVED   = "Die Einstellungen werden pro Charakter gespeichert."
L.TUTORIAL_TIP     = "|cffffff00Profi-Tipp: Doppelklicke, um dich schneller anzumelden.|r"
