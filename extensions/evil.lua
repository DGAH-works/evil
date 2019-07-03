--[[
	太阳神三国杀武将扩展包·凶灵传奇
	适用版本：V2 - 愚人版（版本号：20150401）清明补丁（版本号：20150405）
	武将总数：8
	武将一览：
		1、凶灵司马懿（天灵、狼残、凶魂）
		2、凶灵魏文长（狂血、凶络）
		3、凶灵孙尚香（闺阵、弓机、凶姿）
		4、凶灵天公将（天道、伏雷、凶魄）
		5、凶灵古恶来（暴戟、凶骨）
		6、凶灵曹子桓（阎罗、狱罚、凶势）
		7、凶灵贾文和（绝计、毒谋、凶容）
		8、凶灵钟士季（操控、凶运）
	所需标记：
		1、@evXiongHunMark（“魂”标记，来自技能“凶魂”）
		2、@evXiongLuoMark（“络”标记，来自技能“凶络”）
		3、@evXiongZiMark（“姿”标记，来自技能“凶姿”）
		4、@evXiongPoMark（“魄”标记，来自技能“凶魄”）
		5、@evXiongGuMark（“骨”标记，来自技能“凶骨”）
		6、@evYanLuoMark（“命”标记，来自技能“阎罗”）
		7、@evXiongShiMark（“势”标记，来自技能“凶势”）
		8、@evXiongRongMark（“容”标记，来自技能“凶容”）
		9、@evXiongYunMark（“运”标记，来自技能“凶运”）
]]--
module("extensions.evil", package.seeall)
extension = sgs.Package("evil")
--AI适用开关
AIAccess = false
--翻译信息
sgs.LoadTranslationTable{
	["evil"] = "凶灵传奇",
}
--[[****************************************************************
	编号：EV - 001
	武将：凶灵司马懿
	称号：凶魂灵
	势力：魏
	性别：男
	体力上限：3勾玉
]]--****************************************************************
SiMaYi = sgs.General(extension, "evSiMaYi", "wei", 3, true, not AIAccess)
--翻译信息
sgs.LoadTranslationTable{
	["evSiMaYi"] = "凶灵司马懿",
	["&evSiMaYi"] = "司马懿",
	["#evSiMaYi"] = "凶魂灵",
	["designer:evSiMaYi"] = "DGAH",
	["cv:evSiMaYi"] = "官方",
	["illustrator:evSiMaYi"] = "KayaK",
	["~evSiMaYi"] = "凶灵司马懿 的阵亡台词",
}
--[[
	技能：天灵
	描述：一张判定牌生效前，你可以亮出牌堆顶的五张牌，选择其中一张代替之，然后将剩下的四张牌以任意方式分配给场上角色或弃置。若你没有获得牌，收到牌的角色受到一点雷电伤害。每阶段限一次。
]]--
TianLingCard = sgs.CreateSkillCard{
	name = "evTianLingCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		room:setPlayerMark(target, "evTianLingTarget", 1)
		local subcards = self:getSubcards()
		for _,id in sgs.qlist(subcards) do
			local card = sgs.Sanguosha:getCard(id)
			room:setCardFlag(card, "-evTianLingTurnedOver")
		end
		room:obtainCard(target, self, true)
		local handcards = source:getHandcards()
		local can_invoke = false
		for _,c in sgs.qlist(handcards) do
			if c:hasFlag("evTianLingTurnedOver") then
				can_invoke = true
				break
			end
		end
		if can_invoke then
			room:askForUseCard(source, "@@evTianLing", "@evTianLing")
		end
	end,
}
TianLingVS = sgs.CreateViewAsSkill{
	name = "evTianLing",
	n = 4,
	view_filter = function(self, selected, to_select)
		return to_select:hasFlag("evTianLingTurnedOver")
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = TianLingCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@evTianLing"
	end,
}
TianLing = sgs.CreateTriggerSkill{
	name = "evTianLing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForRetrial},
	view_as_skill = TianLingVS,
	on_trigger = function(self, event, player, data)
		if player:getMark("evTianLingInvoked") > 0 then
			return false
		elseif player:askForSkillInvoke("evTianLing", data) then
			local room = player:getRoom()
			room:setPlayerMark(player, "evTianLingInvoked", 1)
			local card_ids = room:getNCards(5)
			room:fillAG(card_ids)
			player:setTag("evTianLingData", data)
			local to_retrial = room:askForAG(player, card_ids, false, "evTianLing")
			player:removeTag("evTianLingData")
			room:clearAG()
			card_ids:removeOne(to_retrial)
			local move = sgs.CardsMoveStruct()
			move.card_ids = card_ids
			move.to = player
			move.to_place = sgs.Player_PlaceHand
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PREVIEWGIVE, player:objectName())
			room:moveCardsAtomic(move, true)
			for _,id in sgs.qlist(card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				room:setCardFlag(card, "evTianLingTurnedOver")
			end
			room:askForUseCard(player, "@@evTianLing", "@evTianLing")
			local to_throw = sgs.IntList()
			for _,id in sgs.qlist(card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:hasFlag("evTianLingTurnedOver") then
					to_throw:append(id)
				end
			end
			if not to_throw:isEmpty() then
				move = sgs.CardsMoveStruct()
				move.card_ids = to_throw
				move.to = nil
				move.to_place = sgs.Player_DiscardPile
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, player:objectName())
				room:moveCardsAtomic(move, true)
			end
			local flag = ( player:getMark("evTianLingTarget") == 0 )
			local alives = room:getAlivePlayers()
			local victims = {}
			for _,target in sgs.qlist(alives) do
				if target:getMark("evTianLingTarget") > 0 then
					room:setPlayerMark(target, "evTianLingTarget", 0)
					if flag then
						table.insert(victims, target)
					end
				end
			end
			if #victims > 0 then
				for _,victim in ipairs(victims) do
					local damage = sgs.DamageStruct()
					damage.from = nil
					damage.to = victim
					damage.damage = 1
					room:damage(damage)
				end
			end
			local card = sgs.Sanguosha:getCard(to_retrial)
			local judge = data:toJudge()
			room:broadcastSkillInvoke("evTianLing") --播放配音
			room:retrial(card, player, judge, "evTianLing", false)
		end
		return false
	end,
}
TianLingClear = sgs.CreateTriggerSkill{
	name = "#evTianLingClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			room:setPlayerMark(p, "evTianLingInvoked", 0)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
extension:insertRelatedSkills("evTianLing", "#evTianLingClear")
--添加技能
SiMaYi:addSkill(TianLing)
SiMaYi:addSkill(TianLingClear)
--翻译信息
sgs.LoadTranslationTable{
	["evTianLing"] = "天灵",
	[":evTianLing"] = "一张判定牌生效前，你可以亮出牌堆顶的五张牌，选择其中一张代替之，然后将剩下的四张牌以任意方式分配给场上角色或弃置。若你没有获得牌，收到牌的角色受到一点雷电伤害。每阶段限一次。",
	["$evTianLing"] = "天命？哈哈哈哈……",
	["@evTianLing"] = "您可以将其余亮出的牌任意分配给场上角色",
	["~evTianLing"] = "选择要分配的卡牌->选择一名目标角色->点击“确定”",
	["evtianling"] = "天灵",
}
--[[
	技能：狼残
	描述：你受到不少于两点的伤害后或出牌阶段限一次，你可以进行一次判定，若结果为黑桃，你可以对一名角色造成1点伤害并获得其一张牌。
]]--
LangCanCard = sgs.CreateSkillCard{
	name = "evLangCanCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evLangCan") --播放配音
		room:notifySkillInvoked(source, "evLangCan") --显示技能发动
		local judge = sgs.JudgeStruct()
		judge.who = source
		judge.reason = "evLangCan"
		judge.pattern = ".|spade"
		judge.good = true
		room:judge(judge)
		if judge:isGood() then
			local alives = room:getAlivePlayers()
			local target = room:askForPlayerChosen(source, alives, "evLangCan", "@evLangCan-damage", true)
			if target then
				local damage = sgs.DamageStruct()
				damage.from = source
				damage.to = target
				damage.damage = 1
				room:damage(damage)
				if source:isAlive() and target:isAlive() then
					if not target:isNude() then
						local id = room:askForCardChosen(source, target, "he", "evLangCan")
						if id > 0 then
							room:obtainCard(source, id, true)
						end
					end
				end
			end
		end
	end,
}
LangCanVS = sgs.CreateViewAsSkill{
	name = "evLangCan",
	n = 0,
	view_as = function(self, cards)
		return LangCanCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#evLangCanCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@evLangCan"
	end,
}
LangCan = sgs.CreateTriggerSkill{
	name = "evLangCan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	view_as_skill = LangCanVS,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local victim = damage.to
		if victim and victim:objectName() == player:objectName() then
			if damage.damage >= 2 then
				local room = player:getRoom()
				room:askForUseCard(player, "@@evLangCan", "@evLangCan")
			end
		end
		return false
	end,
}
--添加技能
SiMaYi:addSkill(LangCan)
--翻译信息
sgs.LoadTranslationTable{
	["evLangCan"] = "狼残",
	[":evLangCan"] = "你受到不少于两点的伤害后或<font color=\"green\"><b>出牌阶段限一次</b></font>，你可以进行一次判定，若结果为黑桃，你可以对一名角色造成1点伤害并获得其一张牌。",
	["$evLangCan"] = "出来混，早晚要还的！",
	["@evLangCan"] = "您想发动技能“狼残”吗？",
	["~evLangCan"] = "点击“确定”",
	["@evLangCan-damage"] = "狼残：您可以对一名角色造成1点伤害并获得其一张牌",
	["evlangcan"] = "狼残",
}
--[[
	技能：凶魂（限定技）
	描述：出牌阶段，你可以弃四种花色的牌各一张，获得一名其他角色的所有手牌。回合结束时，该角色获得你的所有手牌，然后你摸四张牌。
]]--
XiongHunCard = sgs.CreateSkillCard{
	name = "evXiongHunCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evXiongHun") --播放配音
		room:notifySkillInvoked(source, "evXiongHun") --显示技能发动
		source:loseMark("@evXiongHunMark", 1)
		local target = targets[1]
		room:setPlayerMark(source, "evXiongHunInvoked", 1)
		room:setPlayerMark(target, "evXiongHunTarget", 1)
		if not target:isKongcheng() then
			local move = sgs.CardsMoveStruct()
			move.card_ids = target:handCards()
			move.to = source
			move.to_place = sgs.Player_PlaceHand
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, source:objectName())
			room:moveCardsAtomic(move, false)
		end
	end,
}
XiongHunVS = sgs.CreateViewAsSkill{
	name = "evXiongHun",
	n = 4,
	view_filter = function(self, selected, to_select)
		local suit = to_select:getSuit()
		for _,card in ipairs(selected) do
			if card:getSuit() == suit then
				return false
			end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 4 then
			local card = XiongHunCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@evXiongHunMark") > 0 then
			return player:getCardCount(true) >= 4
		end
		return false
	end,
}
XiongHun = sgs.CreateTriggerSkill{
	name = "evXiongHun",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart},
	view_as_skill = XiongHunVS,
	limit_mark = "@evXiongHunMark",
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Finish then
			local room = player:getRoom()
			room:setPlayerMark(player, "evXiongHunInvoked", 0)
			local others = room:getOtherPlayers(player)
			local target = nil
			for _,p in sgs.qlist(others) do
				if p:getMark("evXiongHunTarget") > 0 then
					room:setPlayerMark(p, "evXiongHunTarget", 0)
					target = p
					break
				end
			end
			if target and not player:isKongcheng() then
				local move = sgs.CardsMoveStruct()
				move.card_ids = player:handCards()
				move.to = target
				move.to_place = sgs.Player_PlaceHand
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, target:objectName())
				room:moveCardsAtomic(move, false)
			end
			if player:isAlive() then
				room:drawCards(player, 4, "evXiongHun")
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:getMark("evXiongHunInvoked") > 0
	end,
}
--添加技能
SiMaYi:addSkill(XiongHun)
--翻译信息
sgs.LoadTranslationTable{
	["evXiongHun"] = "凶魂",
	[":evXiongHun"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可以弃四种花色的牌各一张，获得一名其他角色的所有手牌。回合结束时，该角色获得你的所有手牌，然后你摸四张牌。",
	["$evXiongHun"] = "才通天地，逆天改命！",
	["@evXiongHunMark"] = "魂",
	["evxionghun"] = "凶魂",
}
--[[****************************************************************
	编号：EV - 002
	武将：凶灵魏文长
	称号：凶络灵
	势力：蜀
	性别：男
	体力上限：4
]]--****************************************************************
WeiYan = sgs.General(extension, "evWeiYan", "shu", 4, true, not AIAccess)
--翻译信息
sgs.LoadTranslationTable{
	["evWeiYan"] = "凶灵魏文长",
	["&evWeiYan"] = "魏延",
	["#evWeiYan"] = "凶络灵",
	["designer:evWeiYan"] = "DGAH",
	["cv:evWeiYan"] = "官方",
	["illustrator:evWeiYan"] = "SoniaTang",
	["~evWeiYan"] = "凶灵魏文长 的阵亡台词",
}
--[[
	技能：狂血
	描述：每当你造成一点伤害、或你的回合内一名角色扣减一点体力，你可以选择一项：1、回复一点体力；2、指定一名角色摸两张牌。
]]--
function doKuangXue(room, player, count)
	for i=1, count, 1 do
		local choices = {}
		if player:getLostHp() > 0 then
			table.insert(choices, "recover")
		end
		table.insert(choices, "draw")
		table.insert(choices, "cancel")
		choices = table.concat(choices, "+")
		local choice = room:askForChoice(player, "evKuangXue", choices)
		if choice == "recover" then
			room:broadcastSkillInvoke("evKuangXue", 1) --播放配音
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 1
			room:recover(player, recover)
		elseif choice == "draw" then
			local alives = room:getAlivePlayers()
			local target = room:askForPlayerChosen(player, alives, "evKuangXue", "@evKuangXue", true)
			if target then
				room:broadcastSkillInvoke("evKuangXue", 2) --播放配音
				room:drawCards(target, 2, "evKuangXue")
			end
		elseif choice == "cancel" then
			return 
		end
	end
end
KuangXue = sgs.CreateTriggerSkill{
	name = "evKuangXue",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused, sgs.Damage, sgs.HpChanged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			local source = damage.from
			if source and source:objectName() == player:objectName() then
				if source:hasSkill("evKuangXue") and source:isAlive() then
					room:setPlayerFlag(source, "evKuangXueDamage")
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			local source = damage.from
			if source and source:objectName() == player:objectName() then
				if source:hasSkill("evKuangXue") and source:isAlive() then
					if source:hasFlag("evKuangXueDamage") then
						room:setPlayerFlag(source, "-evKuangXueDamage")
					end
					doKuangXue(room, player, damage.damage)
				end
			end
		elseif event == sgs.HpChanged then
			local record = player:getMark("evKuangXueRecord")
			local hp = player:getHp() 
			room:setPlayerMark(player, "evKuangXueRecord", hp)
			if hp < record then
				local current = room:getCurrent()
				if current and current:hasSkill("evKuangXue") then
					if current:hasFlag("evKuangXueDamage") then
						return false
					end
					doKuangXue(room, current, record - hp)
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target 
	end,
}
KuangXueRecord = sgs.CreateTriggerSkill{
	name = "#evKuangXueRecord",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart, sgs.DrawInitialCards},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			local hp = p:getHp()
			room:setPlayerMark(p, "evKuangXueRecord", hp)
		end
		return false
	end,
}
extension:insertRelatedSkills("evKuangXue", "#evKuangXueRecord")
--添加技能
WeiYan:addSkill(KuangXue)
WeiYan:addSkill(KuangXueRecord)
--翻译信息
sgs.LoadTranslationTable{
	["evKuangXue"] = "狂血",
	[":evKuangXue"] = "每当你造成一点伤害、或你的回合内一名角色扣减一点体力，你可以选择一项：1、回复一点体力；2、指定一名角色摸两张牌。",
	["$evKuangXue1"] = "真是美味呀！",
	["$evKuangXue2"] = "哈哈！",
	["evKuangXue:recover"] = "回复一点体力",
	["evKuangXue:draw"] = "令一名角色摸两张牌",
	["evKuangXue:cancel"] = "不发动“狂血”",
	["@evKuangXue"] = "狂血：请选择摸牌的角色",
}
--[[
	技能：凶络（限定技）
	描述：出牌阶段，你可以弃三张【杀】或【决斗】，令一名其他角色失去所有体力（至少二点），然后你增加一点体力上限、回复所有体力并摸三张牌。
]]--
XiongLuoCard = sgs.CreateSkillCard{
	name = "evXiongLuoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evXiongLuo") --播放配音
		room:notifySkillInvoked(source, "evXiongLuo") --显示技能发动
		source:loseMark("@evXiongLuoMark", 1) 
		local target = targets[1]
		local x = target:getHp()
		x = math.max(2, x)
		room:loseHp(target, x)
		local maxhp = source:getMaxHp()
		maxhp = maxhp + 1
		room:setPlayerProperty(source, "maxhp", sgs.QVariant(maxhp))
		local hp = source:getHp()
		local recover = sgs.RecoverStruct()
		recover.who = source
		recover.recover = maxhp - hp
		room:recover(source, recover)
		room:drawCards(source, 3, "evXiongLuo")
	end,
}
XiongLuoVS = sgs.CreateViewAsSkill{
	name = "evXiongLuo",
	n = 3,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("Slash") or to_select:isKindOf("Duel")
	end,
	view_as = function(self, cards)
		if #cards == 3 then
			local card = XiongLuoCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@evXiongLuoMark") > 0 then
			return player:getCardCount(true) >= 3
		end
		return false
	end,
}
XiongLuo = sgs.CreateTriggerSkill{
	name = "evXiongLuo",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = XiongLuoVS,
	limit_mark = "@evXiongLuoMark",
	on_trigger = function(self, event, player, data)
	end,
}
--添加技能
WeiYan:addSkill(XiongLuo)
--翻译信息
sgs.LoadTranslationTable{
	["evXiongLuo"] = "凶络",
	[":evXiongLuo"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可以弃三张【杀】或【决斗】，令一名其他角色失去所有体力（至少二点），然后你增加一点体力上限、回复所有体力并摸三张牌。",
	["$evXiongLuo"] = "我会怕你吗？",
	["@evXiongLuoMark"] = "络",
	["evxiongluo"] = "凶络",
}
--[[****************************************************************
	编号：EV - 003
	武将：凶灵孙尚香
	称号：凶姿灵
	势力：吴
	性别：女
	体力上限：3勾玉
]]--****************************************************************
SunShangXiang = sgs.General(extension, "evSunShangXiang", "wu", 3, false, not AIAccess)
--翻译信息
sgs.LoadTranslationTable{
	["evSunShangXiang"] = "凶灵孙尚香",
	["&evSunShangXiang"] = "孙尚香",
	["#evSunShangXiang"] = "凶姿灵",
	["designer:evSunShangXiang"] = "DGAH",
	["cv:evSunShangXiang"] = "官方",
	["illustrator:evSunShangXiang"] = "KayaK",
	["~evSunShangXiang"] = "凶灵孙尚香 的阵亡台词",
}
--[[
	技能：闺阵
	描述：一张装备牌进入或离开一名角色的装备区时，你可以选择一项：1、该角色摸一张牌；2、该角色弃一张牌；3、该角色回复一点体力；4、你摸一张牌；5、你回复一点体力。
]]--
function doGuizhen(room, target)
	if target then
		local sp_target = nil
		local allplayers = room:getAllPlayers(true)
		for _,p in sgs.qlist(allplayers) do
			if p:objectName() == target:objectName() then
				sp_target = p
				break
			end
		end
		local isLiuBei = false
		local name, name2 = target:getGeneralName(), target:getGeneral2Name()
		if type(name) == "string" and string.find(name, "liubei") then
			isLiuBei = true
		elseif type(name2) == "string" and string.find(name2, "liubei") then
			isLiuBei = true
		end
		local ai_data = sgs.QVariant()
		ai_data:setValue(sp_target)
		local alives = room:getAlivePlayers()
		for _,source in sgs.qlist(alives) do
			if source:hasSkill("evGuiZhen") then
				local choices = {}
				local hint = sp_target:getGeneralName()
				if sp_target:isAlive() then
					table.insert(choices, hint)
					table.insert(choices, "TargetDraw")
					if not sp_target:isNude() then
						if sp_target:canDiscard(sp_target, "he") then
							table.insert(choices, "TargetDiscard")
						end
					end
					if sp_target:getLostHp() > 0 then
						table.insert(choices, "TargetRecover")
					end
				end
				table.insert(choices, "SourceDraw")
				if source:getLostHp() > 0 then
					table.insert(choices, "SourceRecover")
				end
				table.insert(choices, "cancel")
				choices = table.concat(choices, "+")
				repeat
					room:setTag("evGuiZhenTarget", ai_data) --For AI
					local choice = room:askForChoice(source, "evGuiZhen", choices, ai_data)
					room:removeTag("evGuiZhenTarget") --For AI
					if choice == "TargetDraw" then
						room:broadcastSkillInvoke("evGuiZhen", 1) --播放配音
						room:drawCards(sp_target, 1, "evGuiZhen")
					elseif choice == "TargetDiscard" then
						room:broadcastSkillInvoke("evGuiZhen", 2) --播放配音	
						room:askForDiscard(sp_target, "evGuiZhen", 1, 1, false, true)
					elseif choice == "TargetRecover" then
						if isLiuBei then
							room:broadcastSkillInvoke("evGuiZhen", 3) --播放配音
						else
							room:broadcastSkillInvoke("evGuiZhen", 5) --播放配音
						end
						local recover = sgs.RecoverStruct()
						recover.who = source
						recover.recover = 1
						room:recover(sp_target, recover, true)
					elseif choice == "SourceDraw" then
						room:broadcastSkillInvoke("evGuiZhen", 4) --播放配音
						room:drawCards(source, 1, "evGuiZhen")
					elseif choice == "SourceRecover" then
						room:broadcastSkillInvoke("evGuiZhen", 5) --播放配音
						local recover = sgs.RecoverStruct()
						recover.who = source
						recover.recover = 1
						room:recover(source, recover)
					end
				until choice ~= hint
			end
		end
	end
end
GuiZhen = sgs.CreateTriggerSkill{
	name = "evGuiZhen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local move = data:toMoveOneTime()
		local room = player:getRoom()
		for index, id in sgs.qlist(move.card_ids) do
			local equip = sgs.Sanguosha:getCard(id)
			if equip:isKindOf("EquipCard") then
				local source, target = nil, nil
				if move.from_places:at(index) == sgs.Player_PlaceEquip then
					source = move.from
				end
				if move.to_place == sgs.Player_PlaceEquip then
					target = move.to
				end
				if source and target then
					if source:objectName() == target:objectName() then
						source = nil
						target = nil
					end
				end
				doGuizhen(room, source)
				doGuizhen(room, target)
			end
		end
	end,
}
--添加技能
SunShangXiang:addSkill(GuiZhen)
--翻译信息
sgs.LoadTranslationTable{
	["evGuiZhen"] = "闺阵",
	[":evGuiZhen"] = "一张装备牌进入或离开一名角色的装备区时，你可以选择一项：1、该角色摸一张牌；2、该角色弃一张牌；3、该角色回复一点体力；4、你摸一张牌；5、你回复一点体力。",
	["$evGuiZhen1"] = "小女子谢过将军~呵呵呵……",
	["$evGuiZhen2"] = "看我的厉害！",
	["$evGuiZhen3"] = "夫君，身体要紧~",
	["$evGuiZhen4"] = "这份大礼，我收下啦！",
	["$evGuiZhen5"] = "他好，我也好~",
	["evGuiZhen:TargetDraw"] = "目标角色摸一张牌",
	["evGuiZhen:TargetDiscard"] = "目标角色弃一张牌",
	["evGuiZhen:TargetRecover"] = "目标角色回复一点体力",
	["evGuiZhen:SourceDraw"] = "自己摸一张牌",
	["evGuiZhen:SourceRecover"] = "自己回复一点体力",
}
--[[
	技能：弓机（阶段技）
	描述：若你装备有武器牌，你可以指定一名有手牌的其他角色，该角色展示一张手牌，然后你可以将一张相同颜色的手牌或你装备区的武器牌当做【杀】对该角色使用（此【杀】无距离限制且无视其防具）。
]]--
GongJiSlashCard = sgs.CreateSkillCard{
	name = "evGongJiSlashCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return to_select:hasFlag("evGongJiTarget")
	end,
	on_validate = function(self, use)
		local source = use.from
		local room = source:getRoom()
		room:setPlayerFlag(source, "-evGongJiSlash")
		room:setPlayerFlag(source, "-evGongJiRedSlash")
		room:setPlayerFlag(source, "-evGongJiBlackSlash")
		local subcards = self:getSubcards()
		local id = subcards:first()
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuit()
		local point = card:getNumber()
		local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
		slash:addSubcard(id)
		slash:setSkillName("evGongJi")
		for _,target in sgs.qlist(use.to) do
			room:setPlayerFlag(target, "-evGongJiTarget")
			target:addQinggangTag(slash)
		end
		return slash
	end,
}
GongJiCard = sgs.CreateSkillCard{
	name = "evGongJiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:isKongcheng() then
				return false
			elseif to_select:objectName() == sgs.Self:objectName() then
				return false
			end
			return true
		end
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local to_show = room:askForCardShow(target, source, "evGongJi")
		room:showCard(target, to_show:getEffectiveId())
		local color = nil
		if to_show:isRed() then
			room:setPlayerFlag(source, "evGongJiRedSlash")
			color = "no_suit_red"
		elseif to_show:isBlack() then
			room:setPlayerFlag(source, "evGongJiBlackSlash")
			color = "no_suit_black"
		end
		if color then
			room:setPlayerFlag(target, "evGongJiTarget")
			room:setPlayerFlag(source, "evGongJiSlash")
			local prompt = string.format("@evGongJi:%s::%s", target:objectName(), color)
			local success = room:askForUseCard(source, "@@evGongJi", prompt)
			if not success then
				room:setPlayerFlag(source, "-evGongJiSlash")
				room:setPlayerFlag(target, "-evGongJiTarget")
				room:setPlayerFlag(source, "-evGongJiRedSlash")
				room:setPlayerFlag(source, "-evGongJiBlackSlash")
			end
		end
	end,
}
GongJi = sgs.CreateViewAsSkill{
	name = "evGongJi",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Self:hasFlag("evGongJiSlash") then
			if to_select:isEquipped() then
				if to_select:isKindOf("Weapon") then
					return true
				end
			elseif sgs.Self:hasFlag("evGongJiRedSlash") and to_select:isRed() then
				return true
			elseif sgs.Self:hasFlag("evGongJiBlackSlash") and to_select:isBlack() then
				return true
			end
			return false
		else
			return false
		end
	end,
	view_as = function(self, cards)
		if sgs.Self:hasFlag("evGongJiSlash") then
			if #cards == 1 then
				local card = GongJiSlashCard:clone()
				card:addSubcard(cards[1])
				return card
			end
		else
			return GongJiCard:clone()
		end
	end,
	enabled_at_play = function(self, player)
		if player:hasFlag("evGongJiSlash") then
			return false
		else
			if player:hasUsed("#evGongJiCard") then
				return false
			elseif player:getWeapon() then
				return true
			end
			return false
		end
	end,
	enabled_at_response = function(self, player, pattern)
		if player:hasFlag("evGongJiSlash") then
			return pattern == "@@evGongJi"
		else
			return false
		end
	end,
}
--添加技能
SunShangXiang:addSkill(GongJi)
--翻译信息
sgs.LoadTranslationTable{
	["evGongJi"] = "弓机",
	[":evGongJi"] = "<font color=\"green\"><b>阶段技</b></font>，若你装备有武器牌，你可以指定一名有手牌的其他角色，该角色展示一张手牌，然后你可以将一张相同颜色的手牌或你装备区的武器牌当做【杀】对该角色使用（此【杀】无距离限制且无视其防具）。",
	["$evGongJi"] = "哼！",
	["@evGongJi"] = "您可以将一张 %arg 手牌或你装备区的武器牌当做【杀】对 %src 使用",
	["~evGongJi"] = "选择一张要使用的牌->选择目标角色->点击“确定”",
	["evgongji"] = "弓机",
}
--[[
	技能：凶姿（限定技）
	描述：出牌阶段，你可以弃置武器牌、防具牌、防御马、进攻马各一张，令你攻击范围内的所有其他角色依次弃置所有装备牌并失去一点体力。
]]--
XiongZiCard = sgs.CreateSkillCard{
	name = "evXiongZiCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evXiongZi") --播放配音
		room:notifySkillInvoked(source, "evXiongZi") --显示技能发动
		source:loseMark("@evXiongZiMark", 1)
		local others = room:getOtherPlayers(source)
		local victims = {}
		for _,p in sgs.qlist(others) do
			if source:inMyAttackRange(p) then
				table.insert(victims, p)
			end
		end
		if #victims > 0 then
			for _,target in ipairs(victims) do
				target:throwAllEquips()
				room:loseHp(target, 1)
			end
		end
	end,
}
XiongZiVS = sgs.CreateViewAsSkill{
	name = "evXiongZi",
	n = 4,
	view_filter = function(self, selected, to_select)
		if to_select:isKindOf("Weapon") then
			for _,c in ipairs(selected) do
				if c:isKindOf("Weapon") then
					return false
				end
			end
			return true
		elseif to_select:isKindOf("Armor") then
			for _,c in ipairs(selected) do
				if c:isKindOf("Armor") then
					return false
				end
			end
			return true
		elseif to_select:isKindOf("DefensiveHorse") then
			for _,c in ipairs(selected) do
				if c:isKindOf("DefensiveHorse") then
					return false
				end
			end
			return true
		elseif to_select:isKindOf("OffensiveHorse") then
			for _,c in ipairs(selected) do
				if c:isKindOf("OffensiveHorse") then
					return false
				end
			end
			return true
		end
		return false
	end,
	view_as = function(self, cards)
		if #cards == 4 then
			local card = XiongZiCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@evXiongZiMark") > 0 then
			return player:getCardCount(true) >= 4
		end
		return false
	end,
}
XiongZi = sgs.CreateTriggerSkill{
	name = "evXiongZi",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = XiongZiVS,
	limit_mark = "@evXiongZiMark",
	on_trigger = function(self, event, player, data)
	end,
}
--添加技能
SunShangXiang:addSkill(XiongZi)
--翻译信息
sgs.LoadTranslationTable{
	["evXiongZi"] = "凶姿",
	[":evXiongZi"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可以弃置武器牌、防具牌、防御马、进攻马各一张，令你攻击范围内的所有其他角色依次弃置所有装备牌并失去一点体力。",
	["$evXiongZi"] = "你可要看好了！",
	["@evXiongZiMark"] = "姿",
	["evxiongzi"] = "凶姿",
}
--[[****************************************************************
	编号：EV - 004
	武将：凶灵天公将
	称号：凶魄灵
	势力：群
	性别：男
	体力上限：3勾玉
]]--****************************************************************
ZhangJiao = sgs.General(extension, "evZhangJiao", "qun", 3, true, not AIAccess)
--翻译信息
sgs.LoadTranslationTable{
	["evZhangJiao"] = "凶灵天公将",
	["&evZhangJiao"] = "张角",
	["#evZhangJiao"] = "凶魄灵",
	["designer:evZhangJiao"] = "DGAH",
	["cv:evZhangJiao"] = "官方",
	["illustrator:evZhangJiao"] = "LiuHeng",
	["~evZhangJiao"] = "凶灵天公将 的阵亡台词",
}
--[[
	技能：天道
	描述：一名角色的判定牌生效前，你可以摸四张牌，打出一张手牌替换之。然后你选择四张牌以任意方式分配给场上角色或置于牌堆顶。每阶段限一次。
]]--
TianDaoCard = sgs.CreateSkillCard{
	name = "evTianDaoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			return to_select:objectName() ~= sgs.Self:objectName()
		end
		return false
	end,
	feasible = function(self, targets)
		return true
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evTianDao", 2) --播放配音
		local count = source:getMark("evTianDaoCount")
		local num = self:subcardsLength()
		local new_count = count - num
		room:setPlayerMark(source, "evTianDaoCount", new_count)
		if #targets == 0 then
			local subcards = self:getSubcards()
			local move = sgs.CardsMoveStruct()
			move.to = nil
			move.to_place = sgs.Player_DrawPile
			move.card_ids = subcards
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName())
			room:moveCardsAtomic(move, false)
			if num > 1 then
				room:askForGuanxing(source, subcards, sgs.Room_GuanxingUpOnly)
			end
		else
			local target = targets[1]
			room:obtainCard(target, self, false)
		end
		if new_count > 0 then
			local prompt = string.format("@evTianDao:::%d:", new_count)
			local success = room:askForUseCard(source, "@@evTianDao", prompt)
			if not success then
				room:setPlayerMark(source, "evTianDaoCount", 0)
			end
		end
	end,
}
TianDaoVS = sgs.CreateViewAsSkill{
	name = "evTianDao",
	n = 4,
	view_filter = function(self, selected, to_select)
		return #selected < sgs.Self:getMark("evTianDaoCount")
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local card = TianDaoCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@evTianDao"
	end,
}
TianDao = sgs.CreateTriggerSkill{
	name = "evTianDao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.AskForRetrial},
	view_as_skill = TianDaoVS,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("evTianDaoInvoked") > 0 then
			return false
		end
		if player:askForSkillInvoke("evTianDao", data) then
			room:notifySkillInvoked(player, "evTianDao") --显示技能发动
			room:setPlayerMark(player, "evTianDaoInvoked", 1)
			room:drawCards(player, 4, "evTianDao")
			local judge = data:toJudge()
			local who = judge.who
			local reason = judge.reason
			local prompt = string.format("@evTianDao-retrial:%s::%s:", who:objectName(), reason)
			local to_retrial = room:askForCard(player, ".", prompt, data, sgs.Card_MethodResponse, who, true, "evTianDao")
			if to_retrial then
				room:broadcastSkillInvoke("evTianDao", 1) --播放配音
				room:retrial(to_retrial, player, judge, "evTianDao", true)
			end
			if not player:isNude() then
				local count = 4
				room:setPlayerMark(player, "evTianDaoCount", count)
				prompt = string.format("@evTianDao:::%d:", count)
				local success = room:askForUseCard(player, "@@evTianDao", prompt)
				if not success then
					room:setPlayerMark(player, "evTianDaoCount", 0)
				end
			end
		end
	end,
}
TianDaoClear = sgs.CreateTriggerSkill{
	name = "#evTianDaoClear",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			room:setPlayerMark(p, "evTianDaoInvoked", 0)
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
extension:insertRelatedSkills("evTianDao", "#evTianDaoClear")
--添加技能
ZhangJiao:addSkill(TianDao)
ZhangJiao:addSkill(TianDaoClear)
--翻译信息
sgs.LoadTranslationTable{
	["evTianDao"] = "天道",
	[":evTianDao"] = "一名角色的判定牌生效前，你可以摸四张牌，打出一张手牌替换之。然后你选择四张牌以任意方式分配给场上角色或置于牌堆顶。每阶段限一次。",
	["$evTianDao1"] = "天下大势，为我所控！",
	["$evTianDao2"] = "哼哼哼哼……",
	["@evTianDao-retrial"] = "您可以发动“天道”打出一张手牌，修改 %src 的 %arg 判定",
	["@evTianDao"] = "天道：您还可以将至多 %arg 张牌交给一名其他角色或以任意顺序置于牌堆顶",
	["~evTianDao"] = "选择一些卡牌（包括装备）->选择一名其他角色（不选则视为置于牌堆顶）->点击“确定”",
	["evtiandao"] = "天道",
}
--[[
	技能：伏雷
	描述：出牌阶段对每名角色限一次，你可以将一张手牌扣置于一名其他角色的武将牌上，该角色第一次使用或打出相同花色或点数的卡牌时，弃置此牌并进行一次判定。若结果为黑桃，该角色受到两点雷电伤害。
]]--
FuLeiCard = sgs.CreateSkillCard{
	name = "evFuLeiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:objectName() == sgs.Self:objectName() then
				return false
			end
			local mark = string.format("evFuLei_to_%s", to_select:objectName())
			if sgs.Self:getMark(mark) == 0 then
				return true
			end
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evFuLei", 1) --播放配音
		local target = targets[1]
		local mark = string.format("evFuLei_to_%s", target:objectName())
		room:setPlayerMark(source, mark, 1)
		target:addToPile("evFuLeiPile", self, false)
	end,
}
FuLeiVS = sgs.CreateViewAsSkill{
	name = "evFuLei",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = FuLeiCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:isKongcheng() then
			return false
		end
		local others = player:getSiblings()
		for _,p in sgs.qlist(others) do
			local mark = string.format("evFuLei_to_%s", p:objectName())
			if player:getMark(mark) == 0 then
				return true
			end
		end
		return false
	end,
}
FuLei = sgs.CreateTriggerSkill{
	name = "evFuLei",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	view_as_skill = FuLeiVS,
	on_trigger = function(self, event, player, data)
		if player:getPhase() == sgs.Player_Play then
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			for _,p in sgs.qlist(others) do
				local mark = string.format("evFuLei_to_%s", p:objectName())
				room:setPlayerMark(player, mark, 0)
			end
		end
		return false
	end,
}
FuLeiEffect = sgs.CreateTriggerSkill{
	name = "#evFuLeiEffect",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			card = use.card
		elseif event == sgs.CardResponded then
			local response = data:toCardResponse()
			card = response.m_card
		end
		if card and not card:isKindOf("SkillCard") then
			local suit = card:getSuit()
			local point = card:getNumber()
			local pile = player:getPile("evFuLeiPile")
			for _,id in sgs.qlist(pile) do
				local c = sgs.Sanguosha:getCard(id)
				local hit = false
				if c:getSuit() == suit then
					hit = true
					local msg = sgs.LogMessage()
					msg.type = "#evFuLeiMatchSuit"
					msg.from = player
					msg.arg = c:getSuitString()
					room:sendLog(msg) --发送提示信息
				elseif c:getNumber() == point then
					hit = true
					local msg = sgs.LogMessage()
					msg.type = "#evFuLeiMatchPoint"
					msg.from = player
					msg.arg = point
					room:sendLog(msg) --发送提示信息
				end
				if hit then
					room:broadcastSkillInvoke("evFuLei", 2) --播放配音
					room:throwCard(id, player)
					local judge = sgs.JudgeStruct()
					judge.who = player
					judge.reason = "evFuLei"
					judge.pattern = ".|spade"
					judge.good = false
					room:judge(judge)
					room:getThread():delay()
					if judge:isGood() then
						local msg = sgs.LogMessage()
						msg.type = "#evFuLeiLucky"
						msg.from = player
						room:sendLog(msg) --发送提示信息
					else
						local msg = sgs.LogMessage()
						msg.type = "#evFuLeiUnlucky"
						msg.from = player
						room:sendLog(msg) --发送提示信息
						local damage = sgs.DamageStruct()
						damage.from = nil
						damage.to = player
						damage.damage = 2
						damage.nature = sgs.DamageStruct_Thunder
						room:damage(damage)
					end
					return false
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		if target and target:isAlive() then
			return not target:getPile("evFuLeiPile"):isEmpty()
		end
		return false
	end,
}
extension:insertRelatedSkills("evFuLei", "#evFuLeiEffect")
--添加技能
ZhangJiao:addSkill(FuLei)
ZhangJiao:addSkill(FuLeiEffect)
--翻译信息
sgs.LoadTranslationTable{
	["evFuLei"] = "伏雷",
	[":evFuLei"] = "出牌阶段对每名角色限一次，你可以将一张手牌扣置于一名其他角色的武将牌上，该角色第一次使用或打出相同花色或点数的卡牌时，弃置此牌并进行一次判定。若结果为黑桃，该角色受到两点雷电伤害。",
	["$evFuLei1"] = "苍天已死，黄天当立！",
	["$evFuLei2"] = "雷公助我！",
	["evFuLeiPile"] = "伏雷",
	["#evFuLeiMatchSuit"] = "伏雷：糟糕！%from 使用或打出了一张 %arg 花色的牌，踩到雷了！",
	["#evFuLeiMatchPoint"] = "伏雷：糟糕！%from 使用或打出了一张 %arg 点数的牌，踩到雷了！",
	["#evFuLeiLucky"] = "伏雷：还好，%from 最终幸运地把雷排除了……",
	["#evFuLeiUnlucky"] = "伏雷：悲剧啊！%from 把雷引爆了！！！将受到 2 点雷电伤害……",
	["evfulei"] = "伏雷",
}
--[[
	技能：凶魄（限定技）
	描述：出牌阶段，你可以弃三种不同类型的牌各一张，指定一名角色弃置所有手牌。其中每弃置一张黑桃牌，该角色受到一点雷电伤害；每弃置一张红心牌，该角色失去一点体力；每弃置一张草花牌，你摸一张牌；每弃置一张方块牌，你可以指定一名该角色攻击范围内的角色受到一点伤害。
]]--
function doXiongPo(room, source, target, card)
	room:throwCard(card, target)
	local suit = card:getSuit()
	if suit == sgs.Card_Spade then
		local damage = sgs.DamageStruct()
		damage.from = nil
		damage.to = target
		damage.damage = 1
		damage.nature = sgs.DamageStruct_Thunder
		room:damage(damage)
	elseif suit == sgs.Card_Heart then
		room:loseHp(target, 1)
	elseif suit == sgs.Card_Club then
		room:drawCards(source, 1, "evXiongPo")
	elseif suit == sgs.Card_Diamond then
		local victims = sgs.SPlayerList()
		local alives = room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:objectName() == target:objectName() then
				victims:append(p)
			elseif target:inMyAttackRange(p) then
				victims:append(p)
			end
		end
		if not victims:isEmpty() then
			local prompt = string.format("@evXiongPo:%s:", target:objectName())
			local victim = room:askForPlayerChosen(source, victims, "evXiongPo", prompt, true)
			if victim then
				local damage = sgs.DamageStruct()
				damage.from = nil
				damage.to = victim
				damage.damage = 1
				room:damage(damage)
			end
		end
	end
end
XiongPoCard = sgs.CreateSkillCard{
	name = "evXiongPoCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		if #targets == 0 then
			if to_select:isKongcheng() then
				return false
			end
			return true
		end
		return false
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evXiongPo") --播放配音
		room:notifySkillInvoked(source, "evXiongPo") --显示技能发动
		source:loseMark("@evXiongPoMark", 1)
		local target = targets[1]
		local handcards = target:getHandcards()
		for _,card in sgs.qlist(handcards) do
			doXiongPo(room, source, target, card)
			if source:isDead() or target:isDead() then
				return
			end
		end
	end,
}
XiongPoVS = sgs.CreateViewAsSkill{
	name = "evXiongPo",
	n = 3,
	view_filter = function(self, selected, to_select)
		for _,card in ipairs(selected) do
			if to_select:getTypeId() == card:getTypeId() then
				return false
			end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 3 then
			local card = XiongPoCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@evXiongPoMark") > 0 then
			return player:getCardCount(true) >= 3
		end
		return false
	end,
}
XiongPo = sgs.CreateTriggerSkill{
	name = "evXiongPo",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = XiongPoVS,
	limit_mark = "@evXiongPoMark",
	on_trigger = function(self, event, player, data)
	end,
}
--添加技能
ZhangJiao:addSkill(XiongPo)
--翻译信息
sgs.LoadTranslationTable{
	["evXiongPo"] = "凶魄",
	[":evXiongPo"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可以弃三种不同类型的牌各一张，指定一名角色弃置所有手牌。其中每弃置一张<b>黑</b><b>桃</b>牌，该角色受到一点雷电伤害；每弃置一张<b>红</b><b>心</b>牌，该角色失去一点体力；每弃置一张<b>草</b><b>花</b>牌，你摸一张牌；每弃置一张<b>方</b><b>块</b>牌，你可以指定一名该角色攻击范围内的角色受到一点伤害。",
	["$evXiongPo"] = "成为黄天之士的祭品吧！",
	["@evXiongPoMark"] = "魄",
	["@evXiongPo"] = "凶魄：您可以令 %src 攻击范围内的一名角色受到1点伤害",
	["evxiongpo"] = "凶魄",
}
--[[****************************************************************
	编号：EV - 005
	武将：凶灵古恶来
	称号：凶骨灵
	势力：魏
	性别：男
	体力上限：4
]]--****************************************************************
DianWei = sgs.General(extension, "evDianWei", "wei", 4, true, not AIAccess)
--翻译信息
sgs.LoadTranslationTable{
	["evDianWei"] = "凶灵古恶来",
	["&evDianWei"] = "典韦",
	["#evDianWei"] = "凶骨灵",
	["designer:evDianWei"] = "DGAH",
	["cv:evDianWei"] = "三国杀OL典韦、三国杀OL张飞",
	["illustrator:evDianWei"] = "小冷",
	["~evDianWei"] = "凶灵古恶来 的阵亡台词",
}
--[[
	技能：暴戟（阶段技）
	描述：你可以对一名角色造成一点伤害，然后该角色须交给你一张【闪】或防具牌，否则其失去一点体力。
]]--
BaoJiCard = sgs.CreateSkillCard{
	name = "evBaoJiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evBaoJi") --播放配音
		room:notifySkillInvoked(source, "evBaoJi") --显示技能发动
		local target = targets[1]
		local damage = sgs.DamageStruct()
		damage.from = source
		damage.to = target
		damage.damage = 1
		room:damage(damage)
		if target:isAlive() then
			local prompt = string.format("@evBaoJi:%s:", source:objectName())
			local card = room:askForCard(
				target, "Jink,Armor|.|.|hand,equipped", prompt, sgs.QVariant(), 
				sgs.Card_MethodNone, source, false, "evBaoJi", true
			)
			if card then
				room:obtainCard(source, card, true)
			else
				room:loseHp(target, 1)
			end
		end
	end,
}
BaoJi = sgs.CreateViewAsSkill{
	name = "evBaoJi",
	n = 0,
	view_as = function(self, cards)
		return BaoJiCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#evBaoJiCard")
	end,
}
--添加技能
DianWei:addSkill(BaoJi)
--翻译信息
sgs.LoadTranslationTable{
	["evBaoJi"] = "暴戟",
	[":evBaoJi"] = "<font color=\"green\"><b>阶段技</b></font>，你可以对一名角色造成一点伤害，然后该角色须交给你一张【闪】或防具牌，否则其失去一点体力。",
	["$evBaoJi"] = "吃我一戟！",
	["evbaoji"] = "暴戟",
}
--[[
	技能：凶骨（限定技）
	描述：出牌阶段，你可以获得所有角色装备的武器牌。然后你可以弃置这些武器牌，对一名其他角色造成X点伤害（X为这些武器牌的数量且至少为1）。若该角色在你攻击范围之外，你失去X点体力。
]]--
XiongGuCard = sgs.CreateSkillCard{
	name = "evXiongGuCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evXiongGu") --播放配音
		room:notifySkillInvoked(source, "evXiongGu") --显示技能发动
		source:loseMark("@evXiongGuMark", 1)
		local alives = room:getAlivePlayers()
		local card_ids = sgs.IntList()
		for _,p in sgs.qlist(alives) do
			local weapon = p:getWeapon()
			if weapon then
				room:obtainCard(source, weapon, true)
				local id = weapon:getEffectiveId()
				card_ids:append(id)
			end
		end
		local x = math.max( 1, card_ids:length() )
		local prompt = string.format("@evXiongGu:::%d:", x)
		local others = room:getOtherPlayers(source)
		local target = room:askForPlayerChosen(source, others, "evXiongGu", prompt, true)
		if target then
			local notInMyAttackRange = true
			if source:inMyAttackRange(target) then
				notInMyAttackRange = false
			elseif source:objectName() == target:objectName() then
				notInMyAttackRange = false
			end
			if not card_ids:isEmpty() then
				local move = sgs.CardsMoveStruct()
				move.card_ids = card_ids
				move.to = nil
				move.to_place = sgs.Player_DiscardPile
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISCARD, source:objectName())
				room:moveCardsAtomic(move, true)
			end
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = target
			damage.damage = x
			room:damage(damage)
			if notInMyAttackRange then
				room:loseHp(source, x)
			end
		end
	end,
}
XiongGuVS = sgs.CreateViewAsSkill{
	name = "evXiongGu",
	n = 0,
	view_as = function(self, cards)
		return XiongGuCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@evXiongGuMark") > 0
	end,
}
XiongGu = sgs.CreateTriggerSkill{
	name = "evXiongGu",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = XiongGuVS,
	limit_mark = "@evXiongGuMark",
	on_trigger = function(self, event, player, data)
	end,
}
--添加技能
DianWei:addSkill(XiongGu)
--翻译信息
sgs.LoadTranslationTable{
	["evXiongGu"] = "凶骨",
	[":evXiongGu"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可以获得所有角色装备的武器牌。然后你可以弃置这些武器牌，对一名其他角色造成X点伤害（X为这些武器牌的数量且至少为1）。若该角色在你攻击范围之外，你失去X点体力。",
	["$evXiongGu"] = "啊！！！！",
	["@evXiongGu"] = "凶骨：您可以弃置这些武器牌，对一名角色造成 %arg 点伤害",
	["@evXiongGuMark"] = "骨",
	["evxionggu"] = "凶骨",
}
--[[****************************************************************
	编号：EV - 006
	武将：凶灵曹子桓
	称号：凶势灵
	势力：魏
	性别：男
	体力上限：3勾玉
]]--****************************************************************
CaoPi = sgs.General(extension, "evCaoPi", "wei", 3, true, not AIAccess)
--翻译信息
sgs.LoadTranslationTable{
	["evCaoPi"] = "凶灵曹子桓",
	["&evCaoPi"] = "曹丕",
	["#evCaoPi"] = "凶势灵",
	["designer:evCaoPi"] = "DGAH",
	["cv:evCaoPi"] = "V7、殆尘、烨子、三国杀OL曹丕",
	["illustrator:evCaoPi"] = "SoniaTang",
	["~evCaoPi"] = "凶灵曹子桓 的阵亡台词",
}
--[[
	技能：阎罗
	描述：一名角色濒死时，你可以选择一项：1、令该角色失去一项技能；2、令该角色失去1点体力上限；3、获得该角色的所有手牌。若如此做，该角色回复所有体力，且该角色死亡时，你可以摸三张牌。每名角色限一次。
]]--
function doYanLuo(room, source, target, names)
	local choices = {}
	table.insert(choices, target:getGeneralName())
	local skills = target:getVisibleSkillList()
	local can_detach = {}
	for _,skill in sgs.qlist(skills) do
		local skillname = skill:objectName()
		if skill:inherits("SPConvertSkill") then
		elseif skill:isAttachedLordSkill() then
		elseif skill:isLordSkill() then
			if target:hasLordSkill(skillname) then
				table.insert(can_detach, skillname)
			end
		else
			table.insert(can_detach, skillname)
		end
	end
	if #can_detach > 0 then
		table.insert(choices, "skill")
	end
	table.insert(choices, "maxhp")
	if not target:isKongcheng() then
		table.insert(choices, "handcard")
	end
	table.insert(choices, "cancel")
	choices = table.concat(choices, "+")
	local ai_data = sgs.QVariant()
	ai_data:setValue(target)
	local function doMark()
		room:broadcastSkillInvoke("evYanLuo", 1) --播放配音
		room:notifySkillInvoked(source, "evYanLuo") --显示技能发动
		table.insert(names, target:objectName())
		names = table.concat(names, "|")
		source:setTag("evYanLuoTargets", sgs.QVariant(names))
		target:gainMark("@evYanLuoMark", 1)
	end
	local function doRecover()
		if target:isAlive() then
			local maxhp = target:getMaxHp()
			local hp = target:getHp()
			local recover = sgs.RecoverStruct()
			recover.who = source
			recover.recover = maxhp - hp
			room:recover(target, recover)
		end
	end
	while true do
		room:setTag("evYanLuoTarget", ai_data)
		local choice = room:askForChoice(source, "evYanLuo", choices, ai_data)
		room:removeTag("evYanLuoTarget")
		if choice == "skill" then
			doMark()
			can_detach = table.concat(can_detach, "+")
			local to_detach = room:askForChoice(source, "evYanLuoDetachSkill", can_detach, ai_data)
			room:handleAcquireDetachSkills(target, "-"..to_detach)
			doRecover()
			return true
		elseif choice == "maxhp" then
			doMark()
			room:loseMaxHp(target, 1)
			doRecover()
			return true
		elseif choice == "handcard" then
			doMark()
			if source:objectName() ~= target:objectName() then
				local handcard = target:wholeHandCards()
				room:obtainCard(source, handcard, false)
			end
			doRecover()
			return true
		elseif choice == "cancel" then
			return false
		end
	end
end
YanLuo = sgs.CreateTriggerSkill{
	name = "evYanLuo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Dying},
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		local victim = dying.who
		if victim and victim:objectName() == player:objectName() then
			local room = player:getRoom()
			local alives = room:getAlivePlayers()
			for _,source in sgs.qlist(alives) do
				if source:hasSkill("evYanLuo") then
					local can_invoke = true
					local targets = source:getTag("evYanLuoTargets"):toString() or ""
					targets = targets:split("|")
					for _,name in ipairs(targets) do
						if victim:objectName() == name then
							can_invoke = false
							break
						end
					end
					if can_invoke then
						local success = doYanLuo(room, source, victim, targets)
						if success then
							break
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
YanLuoEffect = sgs.CreateTriggerSkill{
	name = "#evYanLuoEffect",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	on_trigger = function(self, event, player, data)
		local death = data:toDeath()
		local victim = death.who
		if victim and victim:objectName() == player:objectName() then
			if victim:getMark("@evYanLuoMark") > 0 then
				local room = player:getRoom()
				local alives = room:getAlivePlayers()
				local isCaoCao = false
				local name1, name2 = victim:getGeneralName(), victim:getGeneral2Name()
				if type(name1) == "string" and string.match(name1, "caocao") then
					isCaoCao = true
				elseif type(name2) == "string" and string.match(name2, "caocao") then
					isCaoCao = true
				end
				for _,source in sgs.qlist(alives) do
					if source:hasSkill("evYanLuo") then
						local names = source:getTag("evYanLuoTargets"):toString() or ""
						names = names:split("|")
						for _,name in ipairs(names) do
							if victim:objectName() == name then
								if source:askForSkillInvoke("evYanLuoDraw", data) then
									if isCaoCao then
										room:broadcastSkillInvoke("evYanLuo", 4) --播放配音
									elseif victim:isFemale() then
										room:broadcastSkillInvoke("evYanLuo", 3) --播放配音
									else
										room:broadcastSkillInvoke("evYanLuo", 2) --播放配音
									end
									room:notifySkillInvoked(source, "evYanLuo") --显示技能发动
									room:drawCards(source, 3, "evYanLuo")
								end
								break
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
extension:insertRelatedSkills("evYanLuo", "#evYanLuoEffect")
--添加技能
CaoPi:addSkill(YanLuo)
CaoPi:addSkill(YanLuoEffect)
--翻译信息
sgs.LoadTranslationTable{
	["evYanLuo"] = "阎罗",
	[":evYanLuo"] = "一名角色濒死时，你可以选择一项：1、令该角色失去一项技能；2、令该角色失去1点体力上限；3、获得该角色的所有手牌。若如此做，该角色回复所有体力，且该角色死亡时，你可以摸三张牌。每名角色限一次。",
	["$evYanLuo1"] = "罪不至死，赦死从流！",
	["$evYanLuo2"] = "汝妻子吾自养之，汝勿虑也~",
	["$evYanLuo3"] = "珠沉玉没，其香犹存……",
	["$evYanLuo4"] = "痛神曜之幽潛，哀鼎俎之虚置……",
	["evYanLuo:skill"] = "令其失去一项技能",
	["evYanLuo:maxhp"] = "令其失去1点体力上限",
	["evYanLuo:handcard"] = "获得其所有手牌",
	["evYanLuo:cancel"] = "不对其发动“阎罗”",
	["evYanLuoDetachSkill"] = "阎罗·失去技能",
	["@evYanLuoMark"] = "命",
	["evYanLuoDraw"] = "阎罗·摸牌",
}
--[[
	技能：狱罚
	描述：每当你受到一点伤害或出牌阶段限一次，你可以令一名角色弃一张红心手牌，否则该角色摸一张牌、将其武将牌横置并翻面。
	备注：若该角色武将牌已被横置，则只需执行摸牌和翻面的效果。
]]--
YuFaCard = sgs.CreateSkillCard{
	name = "evYuFaCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evYuFa") --播放配音
		room:notifySkillInvoked(source, "evYuFa") --显示技能发动
		local target = targets[1]
		local card = room:askForCard(target, ".|heart|.|hand", "@evYuFa-discard")
		if not card then
			room:drawCards(target, 1, "evYuFa")
			if not target:isChained() then
				target:setChained(true)
				room:setEmotion(target, "chained")
				room:broadcastProperty(target, "chained")
			end
			target:turnOver()
		end
	end,
}
YuFaVS = sgs.CreateViewAsSkill{
	name = "evYuFa",
	n = 0,
	view_as = function(self, cards)
		return YuFaCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#evYuFaCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@evYuFa"
	end,
}
YuFa = sgs.CreateTriggerSkill{
	name = "evYuFa",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	view_as_skill = YuFaVS,
	on_trigger = function(self, event, player, data)
		local damage = data:toDamage()
		local target = damage.to
		if target and target:objectName() == player:objectName() then
			local room = player:getRoom()
			for i=1, damage.damage, 1 do
				local use = room:askForUseCard(player, "@@evYuFa", "@evYuFa")
				if not use then
					return false
				end
			end
		end
		return false
	end,
}
--添加技能
CaoPi:addSkill(YuFa)
--翻译信息
sgs.LoadTranslationTable{
	["evYuFa"] = "狱罚",
	[":evYuFa"] = "每当你受到一点伤害或<font color=\"green\"><b>出牌阶段限一次</b></font>，你可以令一名角色弃一张红心手牌，否则该角色摸一张牌、将其武将牌横置并翻面。",
	["$evYuFa"] = "死罪可免，活罪难赦！",
	["@evYuFa"] = "您可以对一名角色发动技能“狱罚”",
	["~evYuFa"] = "选择一名角色（包括自己）->点击“确定”",
	["@evYuFa-discard"] = "狱罚：请弃置一张红心手牌，否则你将摸一张牌、将武将牌横置并翻面",
	["evyufa"] = "狱罚",
}
--[[
	技能：凶势（限定技）
	描述：出牌阶段，你可以弃三张点数均为X的牌，所有与你距离不超过X的其他角色须选择一项：交给你一张点数为X的手牌并流失一点体力上限，或者进行一次判定。若判定结果不为【桃】或【酒】，该角色失去X点体力并将武将牌翻面。
]]--
function doXiongShi(room, source, victim, pattern, prompt, x)
	local to_give = room:askForCard(
		victim, pattern, prompt, sgs.QVariant(), 
		sgs.Card_MethodNone, source, false, "evXiongShi"
	)
	if to_give then
		if source:isAlive() then
			room:obtainCard(source, to_give, true)
		end
		room:loseMaxHp(victim, 1)
	else
		local judge = sgs.JudgeStruct()
		judge.who = victim
		judge.reason = "evXiongShi"
		judge.pattern = "Peach,Analeptic"
		judge.good = true
		room:judge(judge)
		if not judge:isGood() then
			room:loseHp(victim, x)
			if victim:isAlive() then
				victim:turnOver()
			end
		end
	end
end
XiongShiCard = sgs.CreateSkillCard{
	name = "evXiongShiCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evXiongShi") --播放配音
		room:notifySkillInvoked(source, "evXiongShi") --显示技能发动
		source:loseMark("@evXiongShiMark", 1)
		local subcards = self:getSubcards()
		local id = subcards:first()
		local card = sgs.Sanguosha:getCard(id)
		local x = card:getNumber()
		local others = room:getOtherPlayers(source)
		local victims = {}
		for _,p in sgs.qlist(others) do
			if source:distanceTo(p) <= x then
				table.insert(victims, p)
			end
		end
		if #victims > 0 then
			local pattern = string.format(".|.|%d|hand", x)
			local prompt = string.format("@evXiongShi:%s::%d:", source:objectName(), x)
			for _,victim in ipairs(victims) do
				if victim:isAlive() then
					doXiongShi(room, source, victim, pattern, prompt, x)
				end
			end
		end
	end,
}
XiongShiVS = sgs.CreateViewAsSkill{
	name = "evXiongShi",
	n = 3,
	view_filter = function(self, selected, to_select)
		if #selected == 0 then
			return true
		else
			return to_select:getNumber() == selected[1]:getNumber()
		end
	end,
	view_as = function(self, cards)
		if #cards == 3 then
			local card = XiongShiCard:clone()
			for _,c in ipairs(cards) do
				card:addSubcard(c)
			end
			return card
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("@evXiongShiMark") > 0 then
			return player:getCardCount(true) >= 3
		end
		return false
	end,
}
XiongShi = sgs.CreateTriggerSkill{
	name = "evXiongShi",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = XiongShiVS,
	limit_mark = "@evXiongShiMark",
	on_trigger = function(self, event, player, data)
	end,
}
--添加技能
CaoPi:addSkill(XiongShi)
--翻译信息
sgs.LoadTranslationTable{
	["evXiongShi"] = "凶势",
	[":evXiongShi"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可以弃三张点数均为X的牌，所有与你距离不超过X的其他角色须选择一项：交给你一张点数为X的手牌并流失一点体力上限，或者进行一次判定。若判定结果不为【桃】或【酒】，该角色失去X点体力并将武将牌翻面。",
	["$evXiongShi"] = "来！管杀还管埋！",
	["@evXiongShiMark"] = "势",
	["evxiongshi"] = "凶势",
}
--[[****************************************************************
	编号：EV - 007
	武将：凶灵贾文和
	称号：凶容灵
	势力：群
	性别：男
	体力上限：3勾玉
]]--****************************************************************
JiaXu = sgs.General(extension, "evJiaXu", "qun", 3, true, not AIAccess)
--翻译信息
sgs.LoadTranslationTable{
	["evJiaXu"] = "凶灵贾文和",
	["&evJiaXu"] = "贾诩",
	["#evJiaXu"] = "凶容灵",
	["designer:evJiaXu"] = "DGAH",
	["cv:evJiaXu"] = "三国杀OL贾诩，极光，落凤一箭",
	["illustrator:evJiaXu"] = "KayaK",
	["~evJiaXu"] = "凶灵贾文和 的阵亡台词",
}
--[[
	技能：绝计
	描述：一名角色因你或其自己对其造成的伤害而濒死时，你可以获得其一张牌并展示之。若此牌不为【桃】或该角色没有牌可令你获得，该角色立即死亡（你可以宣布对此事件负责）。
]]--
function doJueJi(room, source, victim, data)
	if room:askForSkillInvoke(source, "evJueJi", data) then
		room:notifySkillInvoked(source, "evJueJi") --显示技能发动
		local peach = false
		if not victim:isNude() then
			local id = room:askForCardChosen(source, victim, "he", "evJueJi")
			if id > 0 then
				room:showCard(victim, id)
				local card = sgs.Sanguosha:getCard(id)
				if card:isKindOf("Peach") then
					peach = true
				end
				room:obtainCard(source, id, true)
			end
		end
		if peach then
			room:broadcastSkillInvoke("evJueJi", 3) --播放配音
		else
			local reason = sgs.DamageStruct()
			reason.to = victim
			if source:askForSkillInvoke("evJueJiKill", data) then
				room:broadcastSkillInvoke("evJueJi", 1) --播放配音
				reason.from = source
			else
				room:broadcastSkillInvoke("evJueJi", 2) --播放配音
				reason.from = nil
			end
			room:getThread():delay()
			room:killPlayer(victim, reason)
			return false
		end
	end
	return true
end
JueJi = sgs.CreateTriggerSkill{
	name = "evJueJi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EnterDying},
	on_trigger = function(self, event, player, data)
		local dying = data:toDying()
		local victim = dying.who
		if victim and victim:objectName() == player:objectName() then
			local reason = dying.damage
			if reason then
				local source = reason.from
				if source then
					local room = player:getRoom()
					if source:objectName() == victim:objectName() then
						local alives = room:getAlivePlayers()
						for _,p in sgs.qlist(alives) do
							if p:hasSkill("evJueJi") then
								local alive = doJueJi(room, p, victim, data)
								if not alive then
									return false
								end
							end
						end
					elseif source:hasSkill("evJueJi") then
						doJueJi(room, source, victim, data)
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
}
--添加技能
JiaXu:addSkill(JueJi)
--翻译信息
sgs.LoadTranslationTable{
	["evJueJi"] = "绝计",
	[":evJueJi"] = "一名角色因你或其自己对其造成的伤害而濒死时，你可以获得其一张牌并展示之。若此牌不为【桃】或该角色没有牌可令你获得，该角色立即死亡（你可以宣布对此事件负责）。",
	["$evJueJi1"] = "我要你三更死，谁敢留你到五更？！",
	["$evJueJi2"] = "神仙难救，神仙难救啊~",
	["$evJueJi3"] = "今日饶你，还不速速退去！",
	["evJueJiKill"] = "绝计·负责",
}
--[[
	技能：毒谋
	描述：当你被指定为一名角色使用的黑色锦囊牌的目标时，你可以选择一项：1、令使用者（若不是你）代替你成为此牌的目标；2、摸两张牌取消自己作为此牌的目标。
]]--
DuMou = sgs.CreateTriggerSkill{
	name = "evDuMou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local source = use.from
			if source and source:objectName() == player:objectName() then
				local trick = use.card
				if trick:isKindOf("TrickCard") and trick:isBlack() then
					local newTargets = sgs.SPlayerList()
					for index, target in sgs.qlist(use.to) do
						local append = true
						if target:hasSkill("evDuMou") then
							local choices = {}
							if source:objectName() == target:objectName() then
							elseif source:isProhibited(source, trick) then
							elseif trick:isKindOf("DelayedTrick") and source:containsTrick(trick:objectName()) then
							else
								table.insert(choices, "replace")
							end
							table.insert(choices, "draw")
							table.insert(choices, "cancel")
							choices = table.concat(choices, "+")
							local choice = room:askForChoice(target, "evDuMou", choices, data)
							if choice == "replace" then
								room:broadcastSkillInvoke("evDuMou", 1) --播放配音
								room:notifySkillInvoked(target, "evDuMou") --显示技能发动
								newTargets:append(source)
								append = false
								if trick:isKindOf("Collateral") then
									local tag = target:getTag("collateralVictim")
									target:removeTag("collateralVictim")
									source:setTag("collateralVictim", tag)
								end
								local msg = sgs.LogMessage()
								msg.type = "#evDuMouReplace"
								msg.from = target
								msg.to:append(source)
								msg.arg = "evDuMou"
								msg.arg2 = trick:objectName()
								room:sendLog(msg) --发送提示信息
								if trick:isKindOf("DelayedTrick") then
									room:moveCardTo(trick, source, sgs.Player_PlaceDelayedTrick, true)
								end
							elseif choice == "draw" then
								room:broadcastSkillInvoke("evDuMou", 2) --播放配音
								room:notifySkillInvoked(target, "evDuMou") --显示技能发动
								room:drawCards(target, 2, "evDuMou")
								append = false
								local msg = sgs.LogMessage()
								msg.type = "#evDuMouCancel"
								msg.from = target
								msg.arg = "evDuMou"
								msg.arg2 = trick:objectName()
								room:sendLog(msg) --发送提示信息
								if trick:isKindOf("DelayedTrick") then
									room:throwCard(trick, target)
								end
							end
						end
						if append then
							newTargets:append(target)
						end
					end
					use.to = newTargets
					data:setValue(use)
					return use.to:isEmpty()
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target 
	end,
}
--添加技能
JiaXu:addSkill(DuMou)
--翻译信息
sgs.LoadTranslationTable{
	["evDuMou"] = "毒谋",
	[":evDuMou"] = "当你被指定为一名角色使用的黑色锦囊牌的目标时，你可以选择一项：1、令使用者（若不是你）代替你成为此牌的目标；2、摸两张牌取消自己作为此牌的目标。",
	["$evDuMou1"] = "巧变制敌，谋定而动。",
	["$evDuMou2"] = "算无遗策，不动如山。",
	["evDuMou:replace"] = "令使用者代替你成为目标",
	["evDuMou:draw"] = "摸两张牌取消自己作为目标",
	["evDuMou:cancel"] = "不发动“毒谋”",
	["#evDuMouReplace"] = "%from 发动了“%arg”，令使用者 %to 代替自己成为了此【%arg2】的目标",
	["#evDuMouCancel"] = "%from 发动了“%arg”，取消自己作为此【%arg2】的目标",
}
--[[
	技能：凶容（限定技）
	描述：出牌阶段，你可以令所有其他角色依次选择对距离自己最近的一名角色使用一张【杀】或交给你一张红色基本牌，否则该角色对自己造成一点伤害且你摸一张牌。
]]--
function doXiongRong(room, source, target)
	local others = room:getOtherPlayers(target)
	local minDist = 999
	local targets = sgs.SPlayerList()
	for _,p in sgs.qlist(others) do
		local dist = target:distanceTo(p)
		if dist < minDist then
			minDist = dist
			targets = sgs.SPlayerList()
			targets:append(p)
		elseif dist == minDist then
			targets:append(p)
		end
	end
	if not targets:isEmpty() then
		local prompt = string.format("@evXiongRong-slash:%s:", source:objectName())
		local slash = room:askForUseSlashTo(target, targets, prompt, false, false, false)
		if slash then
			return 
		end
	end
	if target:isDead() or source:isDead() then
		return
	end
	if not target:isNude() then
		local prompt = string.format("@evXiongRong-basic:%s:", source:objectName())
		local basic = room:askForCard(
			target, "BasicCard|red|.|hand,equipped", prompt, sgs.QVariant(), 
			sgs.Card_MethodNone, source, false, "evXiongRong"
		)
		if basic then
			room:obtainCard(source, basic, true)
			return 
		end
	end
	if target:isAlive() then
		local damage = sgs.DamageStruct()
		damage.from = target
		damage.to = target
		damage.damage = 1
		room:damage(damage)
	end
	if source:isAlive() then
		room:drawCards(source, 1, "evXiongRong")
	end
end
XiongRongCard = sgs.CreateSkillCard{
	name = "evXiongRongCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evXiongRong") --播放配音
		room:notifySkillInvoked(source, "evXiongRong") --显示技能发动
		source:loseMark("@evXiongRongMark", 1)
		local others = room:getOtherPlayers(source)
		for _,target in sgs.qlist(others) do
			if source:isDead() then
				return
			elseif target:isAlive() then
				doXiongRong(room, source, target)
			end
		end
	end,
}
XiongRongVS = sgs.CreateViewAsSkill{
	name = "evXiongRong",
	n = 0,
	view_as = function(self, cards)
		return XiongRongCard:clone()
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@evXiongRongMark") > 0 
	end,
}
XiongRong = sgs.CreateTriggerSkill{
	name = "evXiongRong",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = XiongRongVS,
	limit_mark = "@evXiongRongMark",
	on_trigger = function(self, event, player, data)
	end,
}
--添加技能
JiaXu:addSkill(XiongRong)
--翻译信息
sgs.LoadTranslationTable{
	["evXiongRong"] = "凶容",
	[":evXiongRong"] = "<font color=\"red\"><b>限定技</b></font>，出牌阶段，你可以令所有其他角色依次选择对距离自己最近的一名角色使用一张【杀】或交给你一张红色基本牌，否则该角色对自己造成一点伤害且你摸一张牌。",
	["$evXiongRong"] = "智乱天下，武逆乾坤！哼哼哼……",
	["@evXiongRongMark"] = "容",
	["evxiongrong"] = "凶容",
}
--[[****************************************************************
	编号：EV - 008
	武将：凶灵钟士季
	称号：凶运灵
	势力：魏
	性别：男
	体力上限：4勾玉
]]--****************************************************************
ZhongHui = sgs.General(extension, "evZhongHui", "wei", 4, true, not AIAccess)
--翻译信息
sgs.LoadTranslationTable{
	["evZhongHui"] = "凶灵钟士季",
	["&evZhongHui"] = "钟会",
	["#evZhongHui"] = "凶运灵",
	["designer:evZhongHui"] = "DGAH",
	["cv:evZhongHui"] = "风叹息",
	["illustrator:evZhongHui"] = "雪君S",
	["~evZhongHui"] = "凶灵钟士季 的阵亡台词",
}
--[[
	技能：操控
	描述：一名其他角色的出牌阶段开始前，若你有手牌，你可以与其交换手牌、装备牌和座位，并代替其进行此出牌阶段。此阶段结束后将你们的手牌、装备牌和座位换回。此阶段中你造成伤害的伤害来源均视为该角色。若此阶段中该角色未造成伤害，你失去两点体力并弃置所有手牌。
]]--
local function swap(room, source, target)
	if source:isAlive() and target:isAlive() then
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName())
		local moveA = sgs.CardsMoveStruct()
		moveA.card_ids = source:handCards()
		moveA.from_place = sgs.Player_PlaceHand
		moveA.to_place = sgs.Player_PlaceHand
		moveA.from = source
		moveA.to = target
		moveA.reason = reason
		local moveB = sgs.CardsMoveStruct()
		moveB.card_ids = target:handCards()
		moveB.from_place = sgs.Player_PlaceHand
		moveB.to_place = sgs.Player_PlaceHand
		moveB.from = target
		moveB.to = source
		moveB.reason = reason
		local moves = sgs.CardsMoveList()
		if not moveA.card_ids:isEmpty() then
			moves:append(moveA)
		end
		if not moveB.card_ids:isEmpty() then
			moves:append(moveB)
		end
		if not moves:isEmpty() then
			room:moveCardsAtomic(moves, false)
		end
	end
	if source:isAlive() and target:isAlive() then
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName())
		local moveA = sgs.CardsMoveStruct()
		local equips = source:getEquips()
		for _,equip in sgs.qlist(equips) do
			local id = equip:getEffectiveId()
			moveA.card_ids:append(id)
		end
		moveA.from_place = sgs.Player_PlaceEquip
		moveA.to_place = sgs.Player_PlaceEquip
		moveA.from = source
		moveA.to = target
		moveA.reason = reason
		local moveB = sgs.CardsMoveStruct()
		equips = target:getEquips()
		for _,equip in sgs.qlist(equips) do
			local id = equip:getEffectiveId()
			moveB.card_ids:append(id)
		end
		moveB.from_place = sgs.Player_PlaceEquip
		moveB.to_place = sgs.Player_PlaceEquip
		moveB.from = target
		moveB.to = source
		moveB.reason = reason
		local moves = sgs.CardsMoveList()
		if not moveA.card_ids:isEmpty() then
			moves:append(moveA)
		end
		if not moveB.card_ids:isEmpty() then
			moves:append(moveB)
		end
		if not moves:isEmpty() then
			room:moveCardsAtomic(moves, false)
		end
	end
	if source:isAlive() and target:isAlive() then
		room:swapSeat(source, target)
	end
end
local function getNextPhase(player, this_phase)
	this_phase = this_phase or sgs.Player_Play
	local phases = player:getPhases()
	local this_index = -1
	for index, phase in sgs.qlist(phases) do
		if phase == this_phase then
			this_index = index
			break
		end
	end
	if this_index >= 0 then
		local next_index = this_index + 1
		if next_index < phases:length() then
			return phases:at(next_index)
		end
	end
	return sgs.Player_NotActive
end
function doCaoKong(room, source, target, data)
	swap(room, source, target)
	if source:isDead() then
		return nil
	end
	room:setPlayerMark(source, "evCaoKongPhase", 1)
	local next_phase = nil
	if target:isAlive() then
		source:setTag("evCaoKongTarget", data)
		next_phase = getNextPhase(target)
		room:setPlayerMark(target, "evCaoKongVictim", 1)
	end
	room:setCurrent(source)
	local msg = sgs.LogMessage()
	msg.type = "#evCaoKongStart"
	msg.from = source
	msg.to:append(target)
	msg.arg = "evCaoKong"
	room:sendLog(msg) --发送提示信息
	if target:isAlive() then
		target:setPhase(sgs.Player_NotActive)
		room:broadcastProperty(target, "phase")
	end
	source:setPhase(sgs.Player_Play)
	room:broadcastProperty(source, "phase")
	room:setPlayerMark(source, "evCaoKongDamageCaused", 0)
	local thread = room:getThread()
	if not thread:trigger(sgs.EventPhaseStart, room, source) then
		thread:trigger(sgs.EventPhaseProceeding, room, source)
	end
	thread:trigger(sgs.EventPhaseEnd, room, source)
	if target:isAlive() then
		room:setPlayerMark(target, "evCaoKongVictim", 0)
	end
	if source:isAlive() then
		source:removeTag("evCaoKongTarget")
		room:setPlayerMark(source, "evCaoKongPhase", 0)
	end
	if target:isAlive() then
		room:setCurrent(target)
		if source:isAlive() then
			swap(room, source, target)
		end
	end
	if source:isAlive() then
		if source:getMark("evCaoKongDamageCaused") == 0 then
			msg = sgs.LogMessage()
			msg.type = "#evCaoKongPunish"
			msg.from = source
			msg.to:append(target)
			msg.arg = "evCaoKong"
			room:sendLog(msg) --发送提示信息
			room:loseHp(source, 2)
			source:throwAllHandCards()
		else
			room:setPlayerMark(source, "evCaoKongDamageCaused", 0)
		end
	end
	return next_phase
end
CaoKong = sgs.CreateTriggerSkill{
	name = "evCaoKong",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()	
		local phase = change.to
		if phase == sgs.Player_Play then
			if player:isSkipped(phase) then
				return false
			end
			local room = player:getRoom()
			local others = room:getOtherPlayers(player)
			local ai_data = sgs.QVariant()
			ai_data:setValue(player)
			for _,source in sgs.qlist(others) do
				if source:hasSkill("evCaoKong") then
					if source:isKongcheng() then
					elseif source:askForSkillInvoke("evCaoKong", ai_data) then
						room:broadcastSkillInvoke("evCaoKong") --播放配音
						local next_phase = doCaoKong(room, source, player, ai_data)
						if next_phase then
							if player:isAlive() then
								change.to = next_phase
								data:setValue(change)
							else
								local next_alive = player:getNextAlive()
								room:setCurrent(next_alive)
								next_alive:setPhase(sgs.Player_RoundStart)
								room:broadcastProperty(next_player, "phase")
							end
							return true
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target and target:isAlive() and target:getMark("evCaoKongPhase") == 0
	end,
}
CaoKongEffect = sgs.CreateTriggerSkill{
	name = "#evCaoKongEffect",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage, sgs.Damage},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.ConfirmDamage then
			local source = damage.from
			if source and source:objectName() == player:objectName() then
				if source:getMark("evCaoKongPhase") > 0 then
					local others = room:getOtherPlayers(source)
					local victim = nil
					local tag = source:getTag("evCaoKongTarget")
					local target = tag:toPlayer()
					for _,p in sgs.qlist(others) do
						if p:getMark("evCaoKongVictim") > 0 then
							if target and target:objectName() == p:objectName() then
								victim = p
								break
							end
						end
					end
					if victim then
						damage.from = victim
						local msg = sgs.LogMessage()
						msg.type = "#evCaoKongChangeSource"
						msg.from = source
						msg.to:append(victim)
						msg.arg = "evCaoKong"
						room:sendLog(msg) --发送提示信息
					else
						damage.from = nil
						local msg = sgs.LogMessage()
						msg.type = "#evCaoKongNoSource"
						msg.from = source
						msg.arg = "evCaoKong"
						room:sendLog(msg) --发送提示信息
					end
					data:setValue(damage)
				end
			end
		elseif event == sgs.Damage then
			local source = damage.from
			if source and source:objectName() == player:objectName() then
				if source:getMark("evCaoKongVictim") > 0 then
					local others = room:getOtherPlayers(source)
					for _,p in sgs.qlist(others) do
						if p:getMark("evCaoKongPhase") > 0 then
							local tag = p:getTag("evCaoKongTarget")
							local victim = tag:toPlayer()
							if victim and victim:objectName() == player:objectName() then
								room:setPlayerMark(p, "evCaoKongDamageCaused", 1)
								break
							end
						end
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self, target)
		return target
	end,
}
extension:insertRelatedSkills("evCaoKong", "#evCaoKongEffect")
--添加技能
ZhongHui:addSkill(CaoKong)
ZhongHui:addSkill(CaoKongEffect)
--翻译信息
sgs.LoadTranslationTable{
	["evCaoKong"] = "操控",
	[":evCaoKong"] = "一名其他角色的出牌阶段开始前，若你有手牌，你可以与其交换手牌、装备牌和座位，并代替其进行此出牌阶段。此阶段结束后将你们的手牌、装备牌和座位换回。此阶段中你造成伤害的伤害来源均视为该角色。若此阶段中该角色未造成伤害，你失去两点体力并弃置所有手牌。",
	["$evCaoKong"] = "夺得军权，方能施展一番！",
	["#evCaoKongStart"] = "%from 发动了“%arg”，将代替 %to 进行本次出牌阶段",
	["#evCaoKongChangeSource"] = "%from 的技能“%arg”被触发，令本次造成伤害的来源视为 %to",
	["#evCaoKongNoSource"] = "%from 的技能“%arg”被触发，但由于操控对象不存在，本次伤害将视为无来源伤害",
	["#evCaoKongPunish"] = "由于操控对象 %to 本阶段未造成过伤害，%from 将为本次操控付出惨重的代价",
}
--[[
	技能：凶运（限定技）
	描述：若你处于操控的出牌阶段，你可以令被操控的角色摸三张牌，然后视为该角色对所有除你之外的角色依次使用了一张【决斗】。
]]--
XiongYunCard = sgs.CreateSkillCard{
	name = "evXiongYunCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("evXiongYun") --播放配音
		room:notifySkillInvoked(source, "evXiongYun") --显示技能发动
		local tag = source:getTag("evCaoKongTarget")
		local target = tag:toPlayer()
		if target and target:isAlive() and target:getMark("evCaoKongVictim") > 0 then
			source:loseMark("@evXiongYunMark", 1)
			room:drawCards(target, 3, "evXiongYun")
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:setSkillName("evXiongYun")
			local others = room:getOtherPlayers(source)
			for _,p in sgs.qlist(others) do
				if p:isAlive() and target:isAlive() then
					if not target:isProhibited(p, duel) then
						local use = sgs.CardUseStruct()
						use.from = target
						use.to:append(p)
						use.card = duel
						room:useCard(use, false)
					end
				end
			end
		else
			room:setPlayerFlag(source, "evXiongYunFail")
		end
	end,
}
XiongYunVS = sgs.CreateViewAsSkill{
	name = "evXiongYun",
	n = 0,
	view_as = function(self, cards)
		return XiongYunCard:clone()
	end,
	enabled_at_play = function(self, player)
		if player:hasFlag("evXiongYunFail") then
			return false
		elseif player:getMark("@evXiongYunMark") > 0 then
			if player:getMark("evCaoKongPhase") > 0 then
				return true
			end
		end
		return false
	end,
}
XiongYun = sgs.CreateTriggerSkill{
	name = "evXiongYun",
	frequency = sgs.Skill_Limited,
	events = {},
	view_as_skill = XiongYunVS,
	limit_mark = "@evXiongYunMark",
	on_trigger = function(self, event, player, data)
	end,
}
--添加技能
ZhongHui:addSkill(XiongYun)
--翻译信息
sgs.LoadTranslationTable{
	["evXiongYun"] = "凶运",
	[":evXiongYun"] = "<font color=\"red\"><b>限定技</b></font>，若你处于操控的出牌阶段，你可以令被操控的角色摸三张牌，然后视为该角色对所有除你之外的角色依次使用了一张【决斗】。",
	["$evXiongYun"] = "非我族者，其心可诛！",
	["@evXiongYunMark"] = "运",
	["evxiongyun"] = "凶运",
}