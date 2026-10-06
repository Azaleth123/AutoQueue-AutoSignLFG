if GetLocale() ~= "frFR" then return end

local _, ns = ...
local L = ns.L

-- Rôles
L.ROLE_TANK        = "Tank"
L.ROLE_HEALER      = "Heal"
L.ROLE_HEAL_SHORT  = "Heal"
L.ROLE_DPS         = "DPS"
L.ACTIVE_SPEC      = "(spé active)"

-- États
L.ON               = "Activé"
L.OFF              = "Désactivé"
L.ENABLED          = "Activé"
L.DISABLED         = "Désactivé"

-- Message d'inscription (chat)
L.SIGNED_UP_AS     = "Inscris en tant que : %s"

-- Infobulle de l'icône minimap
L.TT_ACTIVE_ON     = "Acceptation auto : activée"
L.TT_ACTIVE_OFF    = "Acceptation auto : désactivée"
L.TT_DISABLED_NOTE = "L'acceptation automatique est actuellement désactivée."
L.HOLD_SHIFT_NOTE  = "Maintenez MAJ pour ajouter une note."
L.DETECTED_ROLE    = "Rôle détecté : %s"
L.QUEUE_ROLES      = "Rôles pour la file : %s"
L.LEFT_CLICK       = "Clic gauche :"
L.TOGGLE_ONOFF     = "Activer / Désactiver"

-- /aq (statut + commandes)
L.STATUS_HEADER    = "Statut :"
L.STATUS_AUTOQUEUE = "AutoQueue : %s"
L.STATUS_DESC      = "Accepte automatiquement quand votre chef de groupe vous inscrit à une activité. Vous inscrit aussi automatiquement via la Recherche de groupe (LFG). (Maintenez MAJ pour vous inscrire manuellement)"
L.COMMANDS         = "Commandes :"
L.CMD_ONOFF        = "- Activer / Désactiver AutoQueue"
L.CMD_MINIMAP      = "- Afficher / Masquer l'icône de la minimap"
L.MINIMAP_HIDDEN   = "Icône de la minimap masquée"
L.MINIMAP_SHOWN    = "Icône de la minimap affichée"

-- Barre de rôles (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(aucun coché = rôle de la spé active)"
L.SUBTITLE_NOTE    = "(Maintenez MAJ pour ajouter une note)"
L.NOT_AVAILABLE    = "Indisponible pour cette classe"
L.TOGGLE_TT        = "Afficher / Masquer la sélection des rôles"
L.GOT_IT           = "Compris !"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r : cliquez ici pour afficher/masquer la sélection des rôles, qui vous permet de vous inscrire avec plusieurs rôles ou avec une autre spé. Sans sélection, le rôle de votre spé actuelle s'applique."
L.TUTORIAL_SAVED   = "Les réglages sont enregistrés par personnage."
L.TUTORIAL_TIP     = "|cffffff00Pro tip : double-cliquez pour vous inscrire plus vite.|r"
