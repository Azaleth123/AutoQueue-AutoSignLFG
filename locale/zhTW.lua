if GetLocale() ~= "zhTW" then return end

local _, ns = ...
local L = ns.L

-- 職責
L.ROLE_TANK        = "坦克"
L.ROLE_HEALER      = "治療"
L.ROLE_HEAL_SHORT  = "治療"
L.ROLE_DPS         = "輸出"
L.ACTIVE_SPEC      = "(目前專精)"

-- 狀態
L.ON               = "已啟用"
L.OFF              = "已停用"
L.ENABLED          = "已啟用"
L.DISABLED         = "已停用"

-- 報名訊息(聊天)
L.SIGNED_UP_AS     = "已報名為:%s"

-- 小地圖圖示提示
L.TT_ACTIVE_ON     = "自動接受:已啟用"
L.TT_ACTIVE_OFF    = "自動接受:已停用"
L.TT_DISABLED_NOTE = "自動接受目前已停用。"
L.HOLD_SHIFT_NOTE  = "按住 SHIFT 以新增備註。"
L.DETECTED_ROLE    = "偵測到的職責:%s"
L.QUEUE_ROLES      = "排隊職責:%s"
L.LEFT_CLICK       = "左鍵點擊:"
L.TOGGLE_ONOFF     = "啟用 / 停用"

-- /aq(狀態 + 指令)
L.STATUS_HEADER    = "狀態:"
L.STATUS_AUTOQUEUE = "AutoQueue:%s"
L.STATUS_DESC      = "當你的隊長將你報名參加活動時自動接受。也會透過尋求團隊(LFG)自動為你報名。(按住 SHIFT 手動報名)"
L.COMMANDS         = "指令:"
L.CMD_ONOFF        = "- 啟用 / 停用 AutoQueue"
L.CMD_MINIMAP      = "- 顯示 / 隱藏小地圖圖示"
L.MINIMAP_HIDDEN   = "小地圖圖示已隱藏"
L.MINIMAP_SHOWN    = "小地圖圖示已顯示"

-- 職責列 (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(未選擇 = 目前專精的職責)"
L.SUBTITLE_NOTE    = "(按住 SHIFT 以新增備註)"
L.NOT_AVAILABLE    = "此職業不可用"
L.TOGGLE_TT        = "顯示 / 隱藏職責選擇"
L.GOT_IT           = "了解!"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r:點擊此處顯示/隱藏職責選擇,讓你可以用多個職責或其他專精報名。若不選擇,則套用你目前專精的職責。"
L.TUTORIAL_SAVED   = "設定會依角色儲存。"
L.TUTORIAL_TIP     = "|cffffff00小提示:雙擊可更快報名。|r"
