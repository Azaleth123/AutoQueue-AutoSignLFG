if GetLocale() ~= "itIT" then return end

local _, ns = ...
local L = ns.L

-- Ruoli
L.ROLE_TANK        = "Tank"
L.ROLE_HEALER      = "Heal"
L.ROLE_HEAL_SHORT  = "Heal"
L.ROLE_DPS         = "DPS"
L.ACTIVE_SPEC      = "(specializzazione attiva)"

-- Stati
L.ON               = "Attivato"
L.OFF              = "Disattivato"
L.ENABLED          = "Attivato"
L.DISABLED         = "Disattivato"

-- Messaggio di iscrizione (chat)
L.SIGNED_UP_AS     = "Iscritto come: %s"

-- Tooltip icona minimappa
L.TT_ACTIVE_ON     = "Accettazione automatica: attivata"
L.TT_ACTIVE_OFF    = "Accettazione automatica: disattivata"
L.TT_DISABLED_NOTE = "L'accettazione automatica è attualmente disattivata."
L.HOLD_SHIFT_NOTE  = "Tieni premuto MAIUSC per aggiungere una nota."
L.DETECTED_ROLE    = "Ruolo rilevato: %s"
L.QUEUE_ROLES      = "Ruoli per la coda: %s"
L.LEFT_CLICK       = "Clic sinistro:"
L.TOGGLE_ONOFF     = "Attiva / Disattiva"

-- /aq (stato + comandi)
L.STATUS_HEADER    = "Stato:"
L.STATUS_AUTOQUEUE = "AutoQueue: %s"
L.STATUS_DESC      = "Accetta automaticamente quando il capogruppo ti iscrive a un'attività. Ti iscrive anche automaticamente tramite la Ricerca gruppo (LFG). (Tieni premuto MAIUSC per iscriverti manualmente)"
L.COMMANDS         = "Comandi:"
L.CMD_ONOFF        = "- Attiva / Disattiva AutoQueue"
L.CMD_MINIMAP      = "- Mostra / Nascondi l'icona della minimappa"
L.MINIMAP_HIDDEN   = "Icona della minimappa nascosta"
L.MINIMAP_SHOWN    = "Icona della minimappa mostrata"

-- Barra dei ruoli (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(nessuno selezionato = ruolo della specializzazione attiva)"
L.SUBTITLE_NOTE    = "(Tieni premuto MAIUSC per aggiungere una nota)"
L.NOT_AVAILABLE    = "Non disponibile per questa classe"
L.TOGGLE_TT        = "Mostra / Nascondi la selezione dei ruoli"
L.GOT_IT           = "Capito!"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r: clicca qui per mostrare/nascondere la selezione dei ruoli, che ti permette di iscriverti con più ruoli o con un'altra specializzazione. Senza selezione, si applica il ruolo della tua specializzazione attuale."
L.TUTORIAL_SAVED   = "Le impostazioni vengono salvate per personaggio."
L.TUTORIAL_TIP     = "|cffffff00Consiglio: fai doppio clic per iscriverti più velocemente.|r"
