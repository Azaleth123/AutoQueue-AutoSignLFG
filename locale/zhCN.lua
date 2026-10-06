if GetLocale() ~= "zhCN" then return end

local _, ns = ...
local L = ns.L

-- 职责
L.ROLE_TANK        = "坦克"
L.ROLE_HEALER      = "治疗"
L.ROLE_HEAL_SHORT  = "治疗"
L.ROLE_DPS         = "输出"
L.ACTIVE_SPEC      = "(当前专精)"

-- 状态
L.ON               = "已启用"
L.OFF              = "已禁用"
L.ENABLED          = "已启用"
L.DISABLED         = "已禁用"

-- 报名消息(聊天)
L.SIGNED_UP_AS     = "已报名为:%s"

-- 小地图图标提示
L.TT_ACTIVE_ON     = "自动接受:已启用"
L.TT_ACTIVE_OFF    = "自动接受:已禁用"
L.TT_DISABLED_NOTE = "自动接受当前已禁用。"
L.HOLD_SHIFT_NOTE  = "按住 SHIFT 添加备注。"
L.DETECTED_ROLE    = "检测到的职责:%s"
L.QUEUE_ROLES      = "排队职责:%s"
L.LEFT_CLICK       = "左键点击:"
L.TOGGLE_ONOFF     = "启用 / 禁用"

-- /aq(状态 + 命令)
L.STATUS_HEADER    = "状态:"
L.STATUS_AUTOQUEUE = "AutoQueue:%s"
L.STATUS_DESC      = "当你的队长将你报名参加活动时自动接受。也会通过寻求组队(LFG)自动为你报名。(按住 SHIFT 手动报名)"
L.COMMANDS         = "命令:"
L.CMD_ONOFF        = "- 启用 / 禁用 AutoQueue"
L.CMD_MINIMAP      = "- 显示 / 隐藏小地图图标"
L.MINIMAP_HIDDEN   = "小地图图标已隐藏"
L.MINIMAP_SHOWN    = "小地图图标已显示"

-- 职责栏 (AutoQueueRoleBar.lua)
L.SUBTITLE_NONE    = "(未选择 = 当前专精的职责)"
L.SUBTITLE_NOTE    = "(按住 SHIFT 添加备注)"
L.NOT_AVAILABLE    = "此职业不可用"
L.TOGGLE_TT        = "显示 / 隐藏职责选择"
L.GOT_IT           = "知道了!"
L.TUTORIAL_INTRO   = "|cffb048f8AutoQueue|r:点击此处显示/隐藏职责选择,可让你以多个职责或其他专精报名。若不选择,则应用你当前专精的职责。"
L.TUTORIAL_SAVED   = "设置按角色保存。"
L.TUTORIAL_TIP     = "|cffffff00小提示:双击可更快报名。|r"
