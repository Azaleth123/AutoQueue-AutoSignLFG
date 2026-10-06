if GetLocale() ~= "esES" then return end

local _, ns = ...
local L = ns.L

-- Roles
L.ROLE_TANK        = "Tanque"
L.ROLE_HEALER      = "Sanador"
L.ROLE_HEAL_SHORT  = "Sanador"
L.ROLE_DPS         = "DPS"
L.ACTIVE_SPEC      = "(especialización activa)"

-- Estados
L.ON               = "Activado"
L.OFF              = "Desactivado"
L.ENABLED          = "Activado"
L.DISABLED         = "Desactivado"

-- Mensaje de registro (chat)
L.SIGNED_UP_AS     = "Inscrito como: %s"

-- Tooltip del icono del minimapa
L.TT_ACTIVE_ON     = "Aceptación automática: activada"
L.TT_ACTIVE_OFF    = "Aceptación automática: desactivada"
L.TT_DISABLED_NOTE = "La aceptación automática está actualmente desactivada."
L.HOLD_SHIFT_NOTE  = "Mantén MAYÚS para añadir una nota."
L.DETECTED_ROLE    = "Rol detectado: %s"
L.QUEUE_ROLES      = "funciones para la cola: %s"
L.LEFT_CLICK       = "Clic izquierdo:"
L.TOGGLE_ONOFF     = "Activar / Desactivar"

-- /aq (estado + comandos)
L.STATUS_HEADER    = "Estado:"
L.STATUS_AUTOQUEUE = "AutoQueue: %s"
L.STATUS_DESC      = "Acepta automáticamente cuando tu líder de grupo te inscribe en una actividad. También te inscribe automáticamente a través de la Búsqueda de grupo (LFG). (Mantén MAYÚS para inscribirte manualmente)"
L.COMMANDS         = "Comandos:"
L.CMD_ONOFF        = "- Activar / Desactivar AutoQueue"
L.CMD_MINIMAP      = "- Mostrar / Ocultar el icono del minimapa"
L.MINIMAP_HIDDEN   = "Icono del minimapa oculto"
L.MINIMAP_SHOWN    = "Icono del minimapa mostrado"

-- Barra de roles (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(ninguno marcado = rol de la especialización activa)"
L.SUBTITLE_NOTE    = "(Mantén MAYÚS para añadir una nota)"
L.NOT_AVAILABLE    = "No disponible para esta clase"
L.TOGGLE_TT        = "Mostrar / Ocultar la selección de roles"
L.GOT_IT           = "¡Entendido!"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r: haz clic aquí para mostrar/ocultar la selección de roles, que te permite inscribirte con varios roles o con otra especialización. Sin selección, se aplica el rol de tu especialización actual."
L.TUTORIAL_SAVED   = "Los ajustes se guardan por personaje."
L.TUTORIAL_TIP     = "|cffffff00Consejo: haz doble clic para inscribirte más rápido.|r"
