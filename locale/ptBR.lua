if GetLocale() ~= "ptBR" then return end

local _, ns = ...
local L = ns.L

-- Funções
L.ROLE_TANK        = "Tanque"
L.ROLE_HEALER      = "Curador"
L.ROLE_HEAL_SHORT  = "Curador"
L.ROLE_DPS         = "DPS"
L.ACTIVE_SPEC      = "(especialização ativa)"

-- Estados
L.ON               = "Ativado"
L.OFF              = "Desativado"
L.ENABLED          = "Ativado"
L.DISABLED         = "Desativado"

-- Mensagem de inscrição (chat)
L.SIGNED_UP_AS     = "Inscrito como: %s"

-- Tooltip do ícone do minimapa
L.TT_ACTIVE_ON     = "Aceitação automática: ativada"
L.TT_ACTIVE_OFF    = "Aceitação automática: desativada"
L.TT_DISABLED_NOTE = "A aceitação automática está atualmente desativada."
L.HOLD_SHIFT_NOTE  = "Segure SHIFT para adicionar uma nota."
L.DETECTED_ROLE    = "Função detectada: %s"
L.QUEUE_ROLES      = "Funções para a fila: %s"
L.LEFT_CLICK       = "Clique esquerdo:"
L.TOGGLE_ONOFF     = "Ativar / Desativar"

-- /aq (status + comandos)
L.STATUS_HEADER    = "Status:"
L.STATUS_AUTOQUEUE = "AutoQueue: %s"
L.STATUS_DESC      = "Aceita automaticamente quando o líder do grupo te inscreve em uma atividade. Também te inscreve automaticamente através da Busca de Grupo (LFG). (Segure SHIFT para se inscrever manualmente)"
L.COMMANDS         = "Comandos:"
L.CMD_ONOFF        = "- Ativar / Desativar AutoQueue"
L.CMD_MINIMAP      = "- Mostrar / Ocultar o ícone do minimapa"
L.MINIMAP_HIDDEN   = "Ícone do minimapa ocultado"
L.MINIMAP_SHOWN    = "Ícone do minimapa exibido"

-- Barra de funções (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(nenhuma marcada = função da especialização ativa)"
L.SUBTITLE_NOTE    = "(Segure SHIFT para adicionar uma nota)"
L.NOT_AVAILABLE    = "Indisponível para esta classe"
L.TOGGLE_TT        = "Mostrar / Ocultar a seleção de funções"
L.GOT_IT           = "Entendi!"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r: clique aqui para mostrar/ocultar a seleção de funções, que permite se inscrever com várias funções ou com outra especialização. Sem seleção, a função da sua especialização atual é usada."
L.TUTORIAL_SAVED   = "As configurações são salvas por personagem."
L.TUTORIAL_TIP     = "|cffffff00Dica: clique duas vezes para se inscrever mais rápido.|r"
