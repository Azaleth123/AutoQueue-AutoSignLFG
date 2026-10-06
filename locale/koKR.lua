if GetLocale() ~= "koKR" then return end

local _, ns = ...
local L = ns.L

-- 역할
L.ROLE_TANK        = "탱커"
L.ROLE_HEALER      = "힐러"
L.ROLE_HEAL_SHORT  = "힐러"
L.ROLE_DPS         = "공격대원"
L.ACTIVE_SPEC      = "(활성 특성)"

-- 상태
L.ON               = "활성화됨"
L.OFF              = "비활성화됨"
L.ENABLED          = "활성화됨"
L.DISABLED         = "비활성화됨"

-- 등록 메시지 (채팅)
L.SIGNED_UP_AS     = "다음으로 등록됨: %s"

-- 미니맵 아이콘 툴팁
L.TT_ACTIVE_ON     = "자동 수락: 활성화됨"
L.TT_ACTIVE_OFF    = "자동 수락: 비활성화됨"
L.TT_DISABLED_NOTE = "자동 수락이 현재 비활성화되어 있습니다."
L.HOLD_SHIFT_NOTE  = "SHIFT 키를 눌러 메모를 추가하세요."
L.DETECTED_ROLE    = "감지된 역할: %s"
L.QUEUE_ROLES      = "대기열 역할: %s"
L.LEFT_CLICK       = "왼쪽 클릭:"
L.TOGGLE_ONOFF     = "켜기 / 끄기"

-- /aq (상태 + 명령어)
L.STATUS_HEADER    = "상태:"
L.STATUS_AUTOQUEUE = "AutoQueue: %s"
L.STATUS_DESC      = "파티장이 활동에 등록할 때 자동으로 수락합니다. 파티 찾기(LFG)를 통해서도 자동으로 등록됩니다. (Shift 키를 눌러 수동으로 등록)"
L.COMMANDS         = "명령어:"
L.CMD_ONOFF        = "- AutoQueue 켜기 / 끄기"
L.CMD_MINIMAP      = "- 미니맵 아이콘 표시 / 숨기기"
L.MINIMAP_HIDDEN   = "미니맵 아이콘이 숨겨짐"
L.MINIMAP_SHOWN    = "미니맵 아이콘이 표시됨"

-- 역할 표시줄 (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(선택 없음 = 활성 특성의 역할)"
L.SUBTITLE_NOTE    = "(Shift 키를 눌러 메모를 추가)"
L.NOT_AVAILABLE    = "이 클래스에는 사용할 수 없음"
L.TOGGLE_TT        = "역할 선택 표시 / 숨기기"
L.GOT_IT           = "확인했습니다!"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r: 여기를 클릭하면 역할 선택을 표시/숨길 수 있으며, 이를 통해 여러 역할이나 다른 특성으로 등록할 수 있습니다. 선택하지 않으면 현재 특성의 역할이 적용됩니다."
L.TUTORIAL_SAVED   = "설정은 캐릭터별로 저장됩니다."
L.TUTORIAL_TIP     = "|cffffff00팁: 더블 클릭하면 더 빠르게 등록할 수 있습니다.|r"
