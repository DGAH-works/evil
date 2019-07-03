--[[
	太阳神三国杀武将扩展包·凶灵传奇（AI部分）
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
function SmartAI:useSkillCard(card, use)
	local name
	if card:isKindOf("LuaSkillCard") then
		name = "#" .. card:objectName()
	else
		name = card:getClassName()
	end
	if sgs.ai_skill_use_func[name] then
		sgs.ai_skill_use_func[name](card, use, self)
		if use.to then
			if not use.to:isEmpty() and sgs.dynamic_value.damage_card[name] then
				for _, target in sgs.qlist(use.to) do
					if self:damageIsEffective(target) then return end
				end
				use.card = nil
			end
		end
		return
	end
	if self["useCard"..name] then
		self["useCard"..name](self, card, use)
	end
end
--[[****************************************************************
	编号：EV - 001
	武将：凶灵司马懿
	称号：凶魂灵
	势力：魏
	性别：男
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：天灵
	描述：一张判定牌生效前，你可以亮出牌堆顶的五张牌，选择其中一张代替之，然后将剩下的四张牌以任意方式分配给场上角色或弃置。若你没有获得牌，收到牌的角色受到一点雷电伤害。每阶段限一次。
]]--
--room:askForUseCard(source, "@@evTianLing", "@evTianLing")
--player:askForSkillInvoke("evTianLing", data)
sgs.ai_skill_invoke["evTianLing"] = function(self, data)
	local judge = data:toJudge()
	return self:needRetrial(judge)
end
--room:askForAG(player, card_ids, false, "evTianLing")
sgs.ai_skill_askforag["evTianLing"] = function(self, card_ids)
	local data = self.player:getTag("evTianLingData")
	local judge = data:toJudge()
	local cards = {}
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
	end
	local id = self:getRetrialCardId(cards, judge, false)
	if id > 0 then
		return id
	end
	if self.player:getPhase() == sgs.Player_Play then
		self:sortByUseValue(cards, true)
	else
		self:sortByKeepValue(cards)
	end
	return cards[1]:getEffectiveId()
end
--room:askForUseCard(player, "@@evTianLing", "@evTianLing")
sgs.ai_skill_use["@@evTianLing"] = function(self, prompt, method)
	local cards = self.player:getCards("he")
	local to_arrange = {}
	for _,card in sgs.qlist(cards) do
		if card:hasFlag("evTianLingTurnedOver") then
			table.insert(to_arrange, card)
		end
	end
	if #to_arrange == 0 then
		return "."
	elseif #to_arrange == 1 then
		if self.player:getMark("evTianLingTarget") == 0 then
			if self.player:hasFlag("evTianLingToFriend") then
				local card_str = "#evTianLingCard:"..to_arrange[1]:getEffectiveId()..":->"..self.player:objectName()
				return card_str
			end
		end
	end
	if #self.friends_noself > 0 and not self.player:hasFlag("evTianLingToEnemy") then
		local to_use = {}
		local target = nil
		while #to_arrange > 0 do
			local card, friend = self:getCardNeedPlayer(to_arrange, true)
			if card and friend then
				if not target then
					target = friend
				end
				if target and target:objectName() == friend:objectName() then
					table.insert(to_use, card:getEffectiveId())
					table.removeOne(to_arrange, card)
				end
			else
				break
			end
		end
		if target and #to_use > 0 then
			self.room:setPlayerFlag(self.player, "evTianLingToFriend")
			local card_str = "#evTianLingCard:"..table.concat(to_use, "+")..":->"..target:objectName()
			return card_str
		end
		self:sort(self.friends_noself, "hp")
		self.friends_noself = sgs.reverse(self.friends_noself)
		self:sortByUseValue(to_arrange)
		for _,friend in ipairs(self.friends_noself) do
			if self:needToLoseHp(friend) and not hasManjuanEffect(friend) then
				local card_str = "#evTianLingCard:"..to_arrange[1]:getEffectiveId()..":->"..friend:objectName()
				return card_str
			end
		end
	end
	if #self.enemies > 0 and not self.player:hasFlag("evTianLingToFriend") then
		if self.player:getMark("evTianLingTarget") == 0 then
			self:sort(self.enemies, "hp")
			self:sortByUseValue(to_arrange, true)
			for _,enemy in ipairs(self.enemies) do
				if enemy:getMark("evTianLingTarget") > 0 then
				elseif self:needToLoseHp(enemy) then
				elseif self:getDamagedEffects(enemy) then
				else
					for _,card in ipairs(to_arrange) do
						if isCard("Peach", card, enemy) then
						elseif enemy:getHp() <= 1 and isCard("Analeptic", card, enemy) then
						else
							self.room:setPlayerFlag(self.player, "evTianLingToEnemy")
							local card_str = "#evTianLingTarget:"..card:getEffectiveId()..":->"..enemy:objectName()
							return card_str
						end
					end
				end
			end
		end
	end
	if self.player:hasFlag("evTianLingToEnemy") then
		if self.player:getMark("evTianLingTarget") == 0 then
			return "."
		end
	end
	local ids = {}
	for _,card in ipairs(to_arrange) do
		table.insert(ids, card:getEffectiveId())
	end
	return "#evTianLingCard:"..table.concat(ids, "+")..":->"..self.player:objectName()
end
--[[
	技能：狼残
	描述：你受到不少于两点的伤害后或出牌阶段限一次，你可以进行一次判定，若结果为黑桃，你可以对一名角色造成1点伤害并获得其一张牌。
]]--
--room:askForPlayerChosen(source, alives, "evLangCan", "@evLangCan-damage", true)
sgs.ai_skill_playerchosen["evLangCan"] = function(self, targets)
	local values = {}
	local JinXuanDi = self.room:findPlayerBySkillName("wuling")
	local fire = JinXuanDi and JinXuanDi:getMark("@fire") > 0 or false
	local function getValue(target)
		local v = 0
		local isFriend = self:isFriend(target)
		if self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then
			local damage = 1
			if target:isKongcheng() and target:hasSkill("chouhai") then
				damage = damage + 1
			end
			if fire then
				if target:hasArmorEffect("vine") or target:hasArmorEffect("gale_shell") then
					damage = damage + 1
				end
			end
			if damage > 1 and target:hasArmorEffect("silver_lion") then
				damage = 1
			end
			v = v + damage * 10
			if isFriend then
				v = - v
			end
			local dieFlag = false
			local hp = target:getHp()
			if hp <= damage then
				if hp + self:getAllPeachNum(target) <= damage then
					dieFlag = true
				end
			end
			if dieFlag then
				if self:cantbeHurt(target, self.player, damage) then
					v = v - 100
				else
					if isFriend then
						v = v - 100
					else
						v = v + 30
					end
				end
				if self.role == "renegade" then
					if target:isLord() and self.room:alivePlayerCount() > 2 then
						v = v - 100
					end
				elseif self.player:isLord() then
					if sgs.evaluatePlayerRole(target) == "loyalist" then
						v = v - 100
					end
				end
			else
				local v2 = 5 - hp
				if getBestHp(target) > target:getHp() then
					v2 = v2 - 3
				end
				if self:hasSkills(sgs.masochism_skill, target) then
					v2 = v2 - 12
				end
				if self:needToLoseHp(target, self.player, false) then
					v2 = v2 - 7
				end
				if isFriend then
					v = v - v2
				else
					v = v + v2
				end
			end
		end
		if isFriend then
			local armor = target:getArmor()
			if armor and self:needToThrowArmor(target) then
				if armor:isKindOf("SilverLion") then
					v = v + 20
				else
					v = v + 4
				end
			elseif target:hasEquip() and self:hasSkills(sgs.lose_equip_skill, target) then
				v = v + 15
			elseif target:getHandcardNum() == 1 and self:needKongcheng(target) then
				v = v + 8
			end
			if target:hasSkill("tuntian") then
				v = v + 10
			end
		else
			if target:hasSkill("tuntian") then
				v = v - 10
			end
			if target:isKongcheng() then
				if target:hasEquip() then
					if self:hasSkills(sgs.lose_equip_skill, target) then
						v = v - 15
					end
					local armor = target:getArmor()
					if armor and target:getEquips():length() == 1 then
						if self:needToThrowArmor(target) then
							if armor:isKindOf("SilverLion") then
								v = v - 20
							else
								v = v - 6
							end
						end
					end
				end
			else
				if not target:hasEquip() then
					if target:getHandcardNum() == 1 and self:needKongcheng(target) then
						v = v - 8
					end
				end
			end
		end
		return v
	end
	local players = sgs.QList2Table(targets)
	for _,p in ipairs(players) do
		values[p:objectName()] = getValue(p)
	end
	local compare_func = function(a, b)
		local valueA = values[a:objectName()] or 0
		local valueB = values[b:objectName()] or 0
		return valueA > valueB
	end
	table.sort(players, compare_func)
	local target = players[1]
	local value = values[target:objectName()] or 0
	if value > 0 then
		return target
	end
end
--room:askForCardChosen(source, target, "he", "evLangCan")
--LangCanCard:Play
local langcan_skill = {
	name = "evLangCan",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#evLangCanCard") then
			return nil
		end
		return sgs.Card_Parse("#evLangCanCard:.:")
	end,
}
table.insert(sgs.ai_skills, langcan_skill)
sgs.ai_skill_use_func["#evLangCanCard"] = function(card, use, self)
	use.card = card
end
--room:askForUseCard(player, "@@evLangCan", "@evLangCan")
sgs.ai_skill_use["@@evLangCan"] = function(self, prompt, method)
	return "#evLangCanCard:.:->."
end
--相关信息
sgs.ai_card_intention["evLangCanCard"] = 50
sgs.ai_use_value["evLangCanCard"] = 4.5
sgs.ai_use_priority["evLangCanCard"] = 4
--[[
	技能：凶魂（限定技）
	描述：出牌阶段，你可以弃四种花色的牌各一张，获得一名其他角色的所有手牌。回合结束时，该角色获得你的所有手牌，然后你摸四张牌。
]]--
--XiongHunCard:Play
local xionghun_skill = {
	name = "evXiongHun",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@evXiongHunMark") > 0 then
			if self.player:getCardCount(true) >= 4 then
				return sgs.Card_Parse("#evXiongHunCard:.:")
			end
		end
	end,
}
table.insert(sgs.ai_skills, xionghun_skill)
sgs.ai_skill_use_func["#evXiongHunCard"] = function(card, use, self)
	local target = nil
	local compare_func = function(a, b)
		local numA = a:getHandcardNum()
		local numB = b:getHandcardNum()
		local leastA = self:getLeastHandcardNum(a)
		local leastB = self:getLeastHandcardNum(b)
		local deltA = numA - leastA
		local deltB = numB - leastB
		if deltA == deltB then
			if numA == numB then
				return a:getHp() < b:getHp()
			else
				return numA > numB
			end
		else
			return deltA > deltB
		end
	end
	table.sort(self.enemies, compare_func)
	for _,enemy in ipairs(self.enemies) do
		local num = enemy:getHandcardNum()
		if num > 4 then
			target = enemy
			break
		elseif num > 2 and enemy:getHp() <= 2 then
			if self.player:canSlash(enemy) and self:getCardsNum("Slash") > 0 then
				target = enemy
				break
			end
		end
	end
	if not target then
		return 
	end
	local spade, heart, club, diamond = nil, nil, nil, nil
	local selected = false
	local handcards = self.player:getHandcards()
	if not handcards:isEmpty() then
		handcards = sgs.QList2Table(handcards)
		self:sortByUseValue(handcards, true)
		for _,c in ipairs(handcards) do
			local suit = c:getSuit()
			if suit == sgs.Card_Spade and not spade then
				spade = c
			elseif suit == sgs.Card_Heart and not heart then
				heart = c
			elseif suit == sgs.Card_Club and not club then
				club = c
			elseif suit == sgs.Card_Diamond and not diamond then
				diamond = c
			end
			if spade and heart and club and diamond then
				selected = true
				break
			end
		end
	end
	if not selected then
		local equips = self.player:getEquips()
		if not equips:isEmpty() then
			equips = sgs.QList2Table(equips)
			self:sortByKeepValue(equips)
			for _,equip in ipairs(equips) do
				local suit = equip:getSuit()
				if suit == sgs.Card_Spade and not spade then
					spade = equip
				elseif suit == sgs.Card_Heart and not heart then
					heart = equip
				elseif suit == sgs.Card_Club and not club then
					club = equip
				elseif suit == sgs.Card_Diamond and not diamond then
					diamond = equip
				end
				if spade and heart and club and diamond then
					selected = true
					break
				end
			end
		end
	end
	if selected then
		local card_str = string.format(
			"#evXiongHunCard:%d+%d+%d+%d:->%s", 
			spade:getEffectiveId(), 
			heart:getEffectiveId(), 
			club:getEffectiveId(), 
			diamond:getEffectiveId(), 
			target:objectName()
		)
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end
--相关信息
sgs.ai_use_value["evXiongHunCard"] = 10
sgs.ai_use_priority["evXiongHunCard"] = 6
--[[****************************************************************
	编号：EV - 002
	武将：凶灵魏文长
	称号：凶络灵
	势力：蜀
	性别：男
	体力上限：4
]]--****************************************************************
--[[
	技能：狂血
	描述：每当你造成一点伤害、或你的回合内一名角色扣减一点体力，你可以选择一项：1、回复一点体力；2、指定一名角色摸两张牌。
]]--
--room:askForChoice(player, "evKuangXue", choices)
sgs.ai_skill_choice["evKuangXue"] = function(self, choices, data)
	local withRecover = string.match(choices, "recover")
	local withDraw = string.match(choices, "draw")
	if withRecover then
		if self:isWeak() then
			return "recover"
		end
		if self.player:getPhase() == sgs.Player_Play then
			if self:getOverflow() > 0 then
				return "recover"
			end
		end
	end
	if withDraw then
		if self.player:getPhase() == sgs.Player_Play then
			if self:hasCrossbowEffect() then
				if #self.enemies > 0 then
					for _,enemy in ipairs(self.enemies) do
						if self.player:canSlash(enemy) then
							return "draw"
						end
					end
				end
			end
			if self.player:getMark("@evXiongLuoMark") > 0 then
				if self.player:hasSkill("evXiongLuo") then
					if self:getCardsNum("Slash") + self:getCardsNum("Duel") < 3 then
						return "draw"
					end
				end
			end
		end
	end
	if withRecover then
		if self.player:getPhase() == sgs.Player_NotActive then
			if getBestHp(self.player) < self.player:getHp() then
				return "recover"
			end
		end
	end
	if withDraw then
		local target = self:findPlayerToDraw(true, 2)
		if target then
			return "draw"
		end
	end
	if withRecover then
		return "recover"
	end
	if withDraw then
		return "draw"
	end
	return "cancel"
end
--room:askForPlayerChosen(player, alives, "evKuangXue", "@evKuangXue", true)
sgs.ai_skill_playerchosen["evKuangXue"] = function(self, targets)
	if self.player:getPhase() == sgs.Player_Play then
		if self.player:getMark("@evXiongLuoMark") > 0 then
			if self.player:hasSkill("evXiongLuo") then
				if self:getCardsNum("Slash") + self:getCardsNum("Duel") < 3 then
					return self.player
				end
			end
		end
	end
	return self:findPlayerToDraw(true, 2) or self.player
end
--相关信息
sgs.ai_playerchosen_intention["evKuangXue"] = -20
--[[
	技能：凶络（限定技）
	描述：出牌阶段，你可以弃三张【杀】或【决斗】，令一名其他角色失去所有体力（至少二点），然后你增加一点体力上限、回复所有体力并摸三张牌。
]]--
--XiongLuoCard:Play
local xiongluo_skill = {
	name = "evXiongLuo",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@evXiongLuoMark") > 0 then
			if self.player:getHandcardNum() >= 3 then
				return sgs.Card_Parse("#evXiongLuoCard:.:")
			end
		end
	end,
}
table.insert(sgs.ai_skills, xiongluo_skill)
sgs.ai_skill_use_func["#evXiongLuoCard"] = function(card, use, self)
	if #self.enemies == 0 then
		return 
	end
	local cards = self.player:getCards("he")
	local can_use = {}
	for _,c in sgs.qlist(cards) do
		if c:isKindOf("Slash") or c:isKindOf("Duel") then
			table.insert(can_use, c)
		end
	end
	if #can_use < 3 then
		return 
	end
	self:sort(self.enemies, "hp")
	self.enemies = sgs.reverse(self.enemies)
	local flag = ( self.role == "renegade" and self.room:alivePlayerCount() > 2 )
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if flag and enemy:isLord() then
		else
			target = enemy
			break
		end
	end
	if target then
		local to_use = {}
		self:sortByUseValue(can_use, true)
		for index, c in ipairs(can_use) do
			if index <= 3 then
				table.insert(to_use, c:getEffectiveId())
			else
				break
			end
		end
		local card_str = "#evXiongLuoCard:"..table.concat(to_use, "+")..":->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end
--相关信息
sgs.ai_use_value["evXiongLuoCard"] = 8
sgs.ai_use_priority["evXiongLuoCard"] = 2.1
sgs.ai_card_intention["evXiongLuoCard"] = 80
--[[****************************************************************
	编号：EV - 003
	武将：凶灵孙尚香
	称号：凶姿灵
	势力：吴
	性别：女
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：闺阵
	描述：一张装备牌进入或离开一名角色的装备区时，你可以选择一项：1、该角色摸一张牌；2、该角色弃一张牌；3、该角色回复一点体力；4、你摸一张牌；5、你回复一点体力。
]]--
--room:askForChoice(source, "evGuiZhen", choices, ai_data)
sgs.ai_skill_choice["evGuiZhen"] = function(self, choices, data)
	local target = data:toPlayer()
	local case = 0
	if target and target:isAlive() then
		if self:isFriend(target) then
			case = 1
		elseif self:isEnemy(target) then
			case = 2
		end
	end
	local withTargetDraw = string.match(choices, "TargetDraw")
	local withTargetDiscard = string.match(choices, "TargetDiscard")
	local withTargetRecover = string.match(choices, "TargetRecover")
	local withSourceDraw = string.match(choices, "SourceDraw")
	local withSourceRecover = string.match(choices, "SourceRecover")
	if case == 0 then
		if withSourceRecover then
			if self:isWeak() then
				return "SourceRecover"
			elseif self.player:isKongcheng() and self:needKongcheng() then
				return "SourceRecover"
			elseif hasManjuanEffect(self.player) then
				return "SourceRecover"
			end
		end
		if withSourceDraw then
			return "SourceDraw"
		end
	elseif case == 1 then
		if withTargetRecover then
			if self:isWeak(target) then
				return "TargetRecover"
			elseif getBestHp(target) < target:getHp() then
				return "TargetRecover"
			end
		end
		if withSourceRecover then
			if self:isWeak() then
				return "SourceRecover"
			elseif getBestHp(self.player) < self.player:getHp() then
				return "SourceRecover"
			end
		end
		if withTargetDraw then
			if hasManjuanEffect(target) then
				withTargetDraw = false
			end
		end
		if withSourceDraw then
			if hasManjuanEffect(self.player) then
				withSourceDraw = false
			end
		end
		if withTargetDraw then
			if self:hasSkills(sgs.card_need_skill, target) then
				return "TargetDraw"
			elseif self:getOverflow(target) < 0 then
				return "TargetDraw"
			end
		end
		if withSourceDraw then
			if self:hasSkills(sgs.card_need_skill) then
				return "SourceDraw"
			elseif self:getOverflow() < 0 then
				return "SourceDraw"
			end
		end
		if withTargetDiscard then
			if target:getArmor() and self:needToThrowArmor(target) then
				return "TargetDiscard"
			end
		end
		if withTargetDraw and withSourceDraw then
			if self:getOverflow() < self:getOverflow(target) then
				return "SourceDraw"
			else
				return "TargetDraw"
			end
		end
		if withSourceRecover then
			return "SourceRecover"
		end
		if withTargetRecover then
			return "TargetRecover"
		end
		if withSourceDraw then
			return "SourceDraw"
		end
		if withTargetDraw then
			return "TargetDraw"
		end
	elseif case == 2 then
		if withSourceRecover then
			if self:isWeak() then
				return "SourceRecover"
			end
		end
		if withTargetDiscard then
			if target:getArmor() and self:needToThrowArmor(target) then
				withTargetDiscard = false
			elseif self:hasSkills(sgs.lose_equip_skill, target) then
				for _,friend in ipairs(self.friends) do
					if self:isWeak(friend) then
						withTargetDiscard = false
						break
					end
				end
			end
		end
		if withTargetDiscard then
			return "TargetDiscard"
		end
		if withSourceRecover then
			if getBestHp(self.player) < self.player:getHp() then
				return "SourceRecover"
			end
		end
		if withSourceDraw then
			if hasManjuanEffect(self.player) then
			elseif self.player:isKongcheng() and self:needKongcheng() then
			else
				return "SourceDraw"
			end
		end
		if withSourceRecover then
			return "SourceRecover"
		end
		if withSourceDraw then
			return "SourceDraw"
		end
		if string.match(choices, "TargetDiscard") then
			return "TargetDiscard"
		end
	end
	return "cancel"
end
--room:askForDiscard(sp_target, "evGuiZhen", 1, 1, false, true)
--相关信息
sgs.ai_choicemade_filter["skillChoice"].evGuiZhen = function(self, player, promptlist)
	local target = self.room:getTag("evGuiZhenTarget"):toPlayer()
	if target and target:objectName() ~= player:objectName() then
		local choice = promptlist[#promptlist]
		local intention = 0
		if choice == "TargetDraw" then
			if hasManjuanEffect(target) then
			elseif target:isKongcheng() and self:needKongcheng(target) then
			else
				intention = -30
			end
		elseif choice == "TargetDiscard" then
			if target:getHandcardNum() == 1 and self:needKongcheng(target) then
			elseif target:getArmor() and self:needToThrowArmor(target) then
			elseif target:hasEquip() and self:hasSkills(sgs.lose_equip_skill, target) then
			else
				intention = 20
			end
		elseif choice == "TargetRecover" then
			if getBestHp(target) < target:getHp() then
				intention = -50
			end
		elseif choice == "SourceDraw" then
			intention = 0
		elseif choice == "SourceRecover" then
			intention = 0
		elseif choice == "cancel" then
			intention = 0
		end
		if intention ~= 0 then
			sgs.updateIntention(player, target, intention)
		end
	end
end
--[[
	技能：弓机（阶段技）
	描述：若你装备有武器牌，你可以指定一名有手牌的其他角色，该角色展示一张手牌，然后你可以将一张相同颜色的手牌或你装备区的武器牌当做【杀】对该角色使用（此【杀】无距离限制且无视其防具）。
]]--
--room:askForCardShow(target, source, "evGongJi")
--room:askForUseCard(source, "@@evGongJi", prompt)
sgs.ai_skill_use["@@evGongJi"] = function(self, prompt, method)
	local needRedSlash = self.player:hasFlag("evGongJiRedSlash")
	local needBlackSlash = self.player:hasFlag("evGongJiBlackSlash")
	local can_use = {}
	local to_use = nil
	local handcards = self.player:getHandcards()
	if needRedSlash then
		for _,c in sgs.qlist(handcards) do
			if c:isRed() then
				table.insert(can_use, c)
			end
		end
	elseif needBlackSlash then
		for _,c in sgs.qlist(handcards) do
			if c:isBlack() then
				table.insert(can_use, c)
			end
		end
	end
	if #can_use > 0 then
		self:sortByKeepValue(can_use)
		to_use = can_use[1]
	end
	to_use = to_use or self.player:getWeapon()
	if to_use then
		local alives = self.room:getAlivePlayers()
		local target = nil
		for _,p in sgs.qlist(alives) do
			if p:hasFlag("evGongJiTarget") then
				target = p
				break
			end
		end
		if target then
			local card_str = "#evGongJiSlashCard:"..to_use:getEffectiveId()..":->"..target:objectName()
			return card_str
		end
	end
	return "."
end
--GongJiCard:Play
local gongji_skill = {
	name = "evGongJi",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#evGongJiCard") then
			return nil
		elseif self.player:getWeapon() and #self.enemies > 0 then
			return sgs.Card_Parse("#evGongJiCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, gongji_skill)
sgs.ai_skill_use_func["#evGongJiCard"] = function(card, use, self)
	local enemies = {}
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for _,enemy in ipairs(self.enemies) do
		if enemy:isKongcheng() then
		elseif enemy:objectName() == self.player:objectName() then
		elseif self.player:canSlash(enemy, slash, false) then
			self.room:addPlayerMark(enemy, "Armor_Nullified")
			if not self:slashProhibit(slash, enemy, self.player) then
				table.insert(enemies, enemy)
			end
			self.room:removePlayerMark(enemy, "Armor_Nullified")
		end
	end
	if #enemies == 0 then
		return 
	end
	self:sort(enemies, "defenseSlash")
	use.card = card
	if use.to then
		use.to:append(enemies[1])
	end
end
--相关信息
sgs.ai_use_value["evGongJiCard"] = sgs.ai_use_value["FireSlash"]
sgs.ai_use_priority["evGongJiCard"] = 1.1
sgs.ai_card_intention["evGongJiCard"] = sgs.ai_card_intention["Slash"]
--[[
	技能：凶姿（限定技）
	描述：出牌阶段，你可以弃置武器牌、防具牌、防御马、进攻马各一张，令你攻击范围内的所有其他角色依次弃置所有装备牌并失去一点体力。
]]--
--XiongZiCard:Play
local xiongzi_skill = {
	name = "evXiongZi",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@evXiongZiMark") > 0 then
			if self.player:getCardCount(true) >= 4 then
				return sgs.Card_Parse("#evXiongZiCard:.:")
			end
		end
	end,
}
table.insert(sgs.ai_skills, xiongzi_skill)
sgs.ai_skill_use_func["#evXiongZiCard"] = function(card, use, self)
	local weapon, armor, dhorse, ohorse = nil, nil, nil, nil
	local selected = false
	local cards = self.player:getCards("he")
	for _,c in sgs.qlist(cards) do
		if c:isKindOf("Weapon") and not weapon then
			weapon = c
		elseif c:isKindOf("Armor") and not armor then
			armor = c
		elseif c:isKindOf("DefensiveHorse") and not dhorse then
			dhorse = c
		elseif c:isKindOf("OffensiveHorse") and not ohorse then
			ohorse = c
		end
		if weapon and armor and dhorse and ohorse then
			selected = true
			break
		end
	end
	if not selected then
		return 
	end
	
	local card_str = string.format(
		"#evXiongZiCard:%d+%d+%d+%d:", 
		weapon:getEffectiveId(), 
		armor:getEffectiveId(), 
		dhorse:getEffectiveId(), 
		ohorse:getEffectiveId()
	)
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
end
--相关信息
sgs.ai_use_priority["evXiongZiCard"] = 5
sgs.ai_use_value["evXiongZiCard"] = 7
--[[****************************************************************
	编号：EV - 004
	武将：凶灵天公将
	称号：凶魄灵
	势力：群
	性别：男
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：天道
	描述：一名角色的判定牌生效前，你可以摸四张牌，打出一张手牌替换之。然后你选择四张牌以任意方式分配给场上角色或置于牌堆顶。每阶段限一次。
]]--
--room:askForGuanxing(source, subcards, sgs.Room_GuanxingUpOnly)
--room:askForUseCard(source, "@@evTianDao", prompt)
--player:askForSkillInvoke("evTianDao", data)
sgs.ai_skill_invoke["evTianDao"] = true
--room:askForCard(player, ".", prompt, data, sgs.Card_MethodResponse, who, true, "evTianDao")
sgs.ai_skill_cardask["@evTianDao-retrial"] = function(self, data, pattern, target, target2, arg, arg2)
	local judge = data:toJudge()
	if self:needRetrial(judge) then
		local handcards = self.player:getHandcards()
		handcards = sgs.QList2Table(handcards)
		local id = self:getRetrialCardId(handcards, judge, true)
		if id > 0 then
			return "$"..id
		end
	end
	return "."
end
--room:askForUseCard(player, "@@evTianDao", prompt)
sgs.ai_skill_use["@@evTianDao"] = function(self, prompt, method)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local card, target = self:getCardNeedPlayer(cards, true)
	if card and target then
		if target:objectName() == self.player:objectName() then
			return "."
		end
		local card_str = "#evTianDaoCard:"..card:getEffectiveId()..":->"..target:objectName()
		return card_str
	end
	return "."
end
--[[
	技能：伏雷
	描述：出牌阶段对每名角色限一次，你可以将一张手牌扣置于一名其他角色的武将牌上，该角色第一次使用或打出相同花色或点数的卡牌时，弃置此牌并进行一次判定。若结果为黑桃，该角色受到两点雷电伤害。
]]--
--FuLeiCard:Play
local fulei_skill = {
	name = "evFuLei",
	getTurnUseCard = function(self, inclusive)
		if self.player:isKongcheng() then
			return nil
		end
		return sgs.Card_Parse("#evFuLeiCard:.:")
	end,
}
table.insert(sgs.ai_skills, fulei_skill)
sgs.ai_skill_use_func["#evFuLeiCard"] = function(card, use, self)
	local enemies = {}
	for _,enemy in ipairs(self.enemies) do
		local mark = string.format("evFuLei_to_%s", enemy:objectName())
		if self.player:getMark(mark) == 0 then
			table.insert(enemies, enemy)
		end
	end
	if #enemies == 0 then
		return 
	end
	local handcards = self.player:getHandcards()
	handcards = sgs.QList2Table(handcards)
	self:sortByUseValue(handcards, true)
	local target, to_use = nil, nil
	self:sort(enemies, "threat")
	for _,enemy in ipairs(enemies) do
		local pile = enemy:getPile("evFuLeiPile")
		local spade, heart, club, diamond = false, false, false, false
		for _,id in sgs.qlist(pile) do
			local c = sgs.Sanguosha:getCard(id)
			local suit = c:getSuit()
			if suit == sgs.Card_Spade then
				spade = true
			elseif suit == sgs.Card_Heart then
				heart = true
			elseif suit == sgs.Card_Club then
				club = true
			elseif stui == sgs.Card_Diamond then
				diamond = true
			end
		end
		for _,c in ipairs(handcards) do
			local suit = c:getSuit()
			if suit == sgs.Card_Spade and not spade then
				target, to_use = enemy, c
			elseif suit == sgs.Card_Heart and not heart then
				target, to_use = enemy, c
			elseif suit == sgs.Card_Club and not club then
				target, to_use = enemy, c
			elseif suit == sgs.Card_Diamond and not diamond then
				target, to_use = enemy, c
			end
			if target and to_use then
				break
			end
		end
		if target and to_use then
			break
		end
	end
	if not target then
		if self:getOverflow() > 0 then
			self:sortByKeepValue(handcards)
			target, to_use = enemies[1], handcards[1]
		end
	end
	if target and to_use then
		local card_str = "#evFuLeiCard:"..to_use:getEffectiveId()..":->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end
--相关信息
sgs.ai_use_value["evFuLeiCard"] = 6
sgs.ai_use_priority["evFuLeiCard"] = 8.2
--[[
	技能：凶魄（限定技）
	描述：出牌阶段，你可以弃三种不同类型的牌各一张，指定一名角色弃置所有手牌。其中每弃置一张黑桃牌，该角色受到一点雷电伤害；每弃置一张红心牌，该角色失去一点体力；每弃置一张草花牌，你摸一张牌；每弃置一张方块牌，你可以指定一名该角色攻击范围内的角色受到一点伤害。
]]--
--room:askForPlayerChosen(source, victims, "evXiongPo", prompt, true)
sgs.ai_skill_playerchosen["evXiongPo"] = sgs.ai_skill_playerchosen["damage"]
--XiongPoCard:Play
local xiongpo_skill = {
	name = "evXiongPo",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@evXiongPoMark") > 0 then
			if self.player:getCardCount(true) >= 3 then
				return sgs.Card_Parse("#evXiongPoCard:.:")
			end
		end
	end,
}
table.insert(sgs.ai_skills, xiongpo_skill)
sgs.ai_skill_use_func["#evXiongPoCard"] = function(card, use, self)
	local enemies = {}
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			table.insert(enemies, enemy)
		end
	end
	if #enemies == 0 then
		return 
	end
	self:sort(enemies, "handcard")
	enemies = sgs.reverse(enemies)
	local target = nil
	local flag = ( self.role == "renegade" and self.room:alivePlayerCount() > 2 )
	for _,enemy in ipairs(enemies) do
		if flag and enemy:isLord() then
		else
			target = enemy
			break
		end
	end
	if target then
		local basic, trick, equip = nil, nil, nil
		local selected = false
		local handcards = self.player:getHandcards()
		if not handcards:isEmpty() then
			handcards = sgs.QList2Table(handcards)
			self:sortByUseValue(handcards, true)
			for _,c in ipairs(handcards) do
				if c:isKindOf("BasicCard") and not basic then
					basic = c
				elseif c:isKindOf("TrickCard") and not trick then
					trick = c
				elseif c:isKindOf("EquipCard") and not equip then
					equip = c
				end
				if basic and trick and equip then
					selected = true
					break
				end
			end
		end
		if not selected then
			if not basic then
				return 
			elseif not trick then
				return 
			elseif not equip and self.player:hasEquip() then
				local equips = self.player:getEquips()
				equips = sgs.QList2Table(equips) 
				self:sortByKeepValue(equips)
				equip = equips[1]
				selected = true
			end
		end
		if selected then
			local card_str = string.format(
				"#evXiongPoCard:%d+%d+%d:->%s", 
				basic:getEffectiveId(), 
				trick:getEffectiveId(), 
				equip:getEffectiveId(), 
				target:objectName()
			)
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end
--相关信息
sgs.ai_card_intention["evXiongPoCard"] = 100
sgs.ai_use_value["evXiongPoCard"] = 8
sgs.ai_use_priority["evXiongPoCard"] = 5.5
--[[****************************************************************
	编号：EV - 005
	武将：凶灵古恶来
	称号：凶骨灵
	势力：魏
	性别：男
	体力上限：4
]]--****************************************************************
--[[
	技能：暴戟（阶段技）
	描述：你可以对一名角色造成一点伤害，然后该角色须交给你一张【闪】或防具牌，否则其失去一点体力。
]]--
--room:askForCard(
--	target, "Jink,Armor|.|.|hand,equipped", prompt, sgs.QVariant(), 
--	sgs.Card_MethodNone, source, false, "evBaoJi", true
--)
--BaoJiCard:Play
local baoji_skill = {
	name = "evBaoJi",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#evBaoJiCard") then
			return nil
		elseif #self.enemies == 0 then
			return nil
		end
		return sgs.Card_Parse("#evBaoJiCard:.:")
	end,
}
table.insert(sgs.ai_skills, baoji_skill)
sgs.ai_skill_use_func["#evBaoJiCard"] = function(card, use, self)
	local target = nil
	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 then
			if self:damageIsEffective(enemy) then
				if not self:cantbeHurt(enemy) then
					target = enemy
					break
				end
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if not self:damageIsEffective(enemy) then
				target = enemy
				break
			end
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end
--相关信息
sgs.ai_use_priority["evBaoJiCard"] = 3
sgs.ai_use_value["evBaoJiCard"] = 5.6
--[[
	技能：凶骨（限定技）
	描述：出牌阶段，你可以获得所有角色装备的武器牌。然后你可以弃置这些武器牌，对一名其他角色造成X点伤害（X为这些武器牌的数量且至少为1）。若该角色在你攻击范围之外，你失去X点体力。
]]--
--room:askForPlayerChosen(source, others, "evXiongGu", prompt, true)
sgs.ai_skill_playerchosen["evXiongGu"] = function(self, targets)
	local target = sgs.ai_xionggu_target
	if target then
		sgs.ai_xionggu_target = nil
		for _,p in sgs.qlist(targets) do
			if p:objectName() == target:objectName() then
				return p
			end
		end
	end
	local callback = sgs.ai_skill_playerchosen["damage"]
	return callback(self, targets)
end
--XiongGuCard:Play
local xionggu_skill = {
	name = "evXiongGu",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@evXiongGuMark") > 0 then
			if #self.enemies > 0 then
				return sgs.Card_Parse("#evXiongGuCard:.:")
			end
		end
	end,
}
table.insert(sgs.ai_skills, xionggu_skill)
sgs.ai_skill_use_func["#evXiongGuCard"] = function(card, use, self)
	local damage = 0
	local value = 0
	local function getThrowWeaponValue(player, weapon)
		local v = 3 * self:evaluateWeapon(weapon, player)
		if player:hasSkill("tuntian") and player:getPhase() == sgs.Player_NotActive then
			v = v - 4
		end
		if self:hasSkills(sgs.lose_equip_skill, player) then
			v = v - 15
		end
		if self:isFriend(player) then
			v = - v
		end
		return v
	end
	local alives = self.room:getAlivePlayers()
	for _,p in sgs.qlist(alives) do
		local weapon = p:getWeapon()
		if weapon then
			damage = damage + 1
			value = value + getThrowWeaponValue(p, weapon)
		end
	end
	damage = math.max(1, damage)
	local target = nil
	local targets = {}
	for _,enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy) then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then
		return 
	end
	local values = {}
	local flag = ( self.role == "renegade" and self.room:alivePlayerCount() > 2 )
	local function getDamageValue(player)
		local v = 0
		local count = damage
		if player:isKongcheng() and player:hasSkill("chouhai") then
			count = count + 1
		end
		if count > 1 and player:hasArmorEffect("silver_lion") then
			count = 1
		end
		v = v + count * 20
		if self:cantbeHurt(player, self.player, count) then
			v = v - 1000
		end
		local hp = player:getHp()
		local dieFlag = false
		if hp <= count then
			if hp + self:getAllPeachNum(player) <= count then
				dieFlag = true
			end
		end
		if dieFlag then
			if flag then
				v = v - 1000
			else
				v = v + 100
			end
		else
			if self:getDamagedEffects(player, self.player, false) then
				v = v - 8
			end
			if self:needToLoseHp(player, self.player, false) then
				v = v - 5
			end
			if getBestHp(player) >= hp + count then
				v = v - 3
			end
		end
		return v
	end
	for _,enemy in ipairs(targets) do
		values[enemy:objectName()] = getDamageValue(enemy)
	end
	local compare_func = function(a, b)
		local valueA = values[a:objectName()] or 0
		local valueB = values[b:objectName()] or 0
		return valueA > valueB
	end
	table.sort(targets, compare_func)
	local target = targets[1]
	local damageValue = values[target:objectName()] or 0
	if self.player:distanceTo(target) > 1 then
		local hp = self.player:getHp()
		local vs = 20
		if self.player:getMark("@nirvana") > 0 and self.player:hasSkill("niepan") then
			vs = 0
		elseif self.player:hasSkill("buqu") and self.player:getPile("buqu"):isEmpty() then
			vs = 10
		elseif self.player:hasSkill("nosbuqu") and self.player:getPile("nosbuqu"):isEmpty() then
			vs = 10
		elseif hp <= damage then
			vs = 25
			if hp + self:getAllPeachNum() <= damage then
				damageValue = damageValue - 50
				if self.room:alivePlayerCount() == 2 then
					vs = 10
				else
					local lord = getLord(self.player)
					if lord and lord:objectName() == self.player:objectName() then
						vs = 100
					end
				end
			end
		end
		damageValue = damageValue - damage * vs
	end
	if damageValue > 0 then
		value = value + damageValue
		if value > 50 then
			use.card = card
			if not use.isDummy then
				sgs.ai_xionggu_target = target
			end
		end
	end
end
--相关信息
sgs.ai_playerchosen_intention["evXiongGu"] = 200
sgs.ai_use_value["evXiongGu"] = 7
sgs.ai_use_priority["evXiongGu"] = 0.8
--[[****************************************************************
	编号：EV - 006
	武将：凶灵曹子桓
	称号：凶势灵
	势力：魏
	性别：男
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：阎罗
	描述：一名角色濒死时，你可以选择一项：1、令该角色失去一项技能；2、令该角色失去1点体力上限；3、获得该角色的所有手牌。若如此做，该角色回复所有体力，且该角色死亡时，你可以摸三张牌。每名角色限一次。
]]--
--room:askForChoice(source, "evYanLuo", choices, ai_data)
sgs.ai_skill_choice["evYanLuo"] = function(self, choices, data)
	local target = data:toPlayer()
	local withSkill = string.match(choices, "skill")
	local withMaxHp = string.match(choices, "maxhp")
	local withHandcard = string.match(choices, "handcard")
	if self:isFriend(target) then
		if withSkill then
			local skills = "benghuai|wumou|shiyong|yaowu|zaoyao|chanyuan|chouhai"
			if self:hasSkills(skills, target) then
				return "skill"
			end
		end
		if withHandcard then
			return "handcard"
		end
		if withMaxHp and target:getLostHp() > 2 then
			return "maxhp"
		end
		if withSkill then
			return "skill"
		end
		if withMaxHp and target:getMaxHp() > 1 then
			return "maxhp"
		end
	elseif self:isEnemy(target) then
		if target:getMaxHp() == 1 then
			if self.role == "renegade" and target:isLord() and self.room:alivePlayerCount() > 2 then
			else
				return "maxhp"
			end
		end
	end
	return "cancel"
end
--room:askForChoice(source, "evYanLuoDetachSkill", can_detach, ai_data)
sgs.ai_skill_choice["evYanLuoDetachSkill"] = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	end
	local skills = "benghuai|wumou|shiyong|yaowu|zaoyao|chanyuan|chouhai"
	if self:isFriend(target) then
		for _,item in ipairs(items) do
			if string.match(skills, item) then
				return item
			end
		end
	else
		for _,item in ipairs(items) do
			if not string.match(skills, item) then
				return item
			end
		end
	end
	return items[math.random(1, #items)]
end
--source:askForSkillInvoke("evYanLuoDraw", data)
sgs.ai_skill_invoke["evYanLuoDraw"] = true
--相关信息
sgs.ai_choicemade_filter["skillChoice"].evYanLuo = function(self, player, promptlist)
	local target = self.room:getTag("evYanLuoTarget"):toPlayer()
	if target and target:objectName() ~= player:objectName() then
		local choice = promptlist[#promptlist]
		local intention = 0
		if choice == "skill" then
			intention = -10
		elseif choice == "maxhp" then
			if target:getMaxHp() <= 1 then
				intention = 200
			else
				intention = -10
			end
		elseif choice == "handcard" then
			intention = -90
		elseif choice == "cancel" then
			intention = 0
		end
		if intention ~= 0 then
			sgs.updateIntention(player, target, intention)
		end
	end
end
--[[
	技能：狱罚
	描述：每当你受到一点伤害或出牌阶段限一次，你可以令一名角色弃一张红心手牌，否则该角色摸一张牌、将其武将牌横置并翻面。
]]--
--room:askForCard(target, ".|heart|.|hand", "@evYuFa-discard")
sgs.ai_skill_cardask["@evYuFa-discard"] = function(self, data, pattern, target, target2, arg, arg2)
	if not self:toTurnOver(self.player, 1, "evYuFa") then
		return "."
	end
end
--YuFaCard:Play
local yufa_skill = {
	name = "evYuFa",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#evYuFaCard") then
			return nil
		end
		return sgs.Card_Parse("#evYuFaCard:.:")
	end,
}
table.insert(sgs.ai_skills, yufa_skill)
sgs.ai_skill_use_func["#evYuFaCard"] = function(card, use, self)
	local target = nil
	self:sort(self.friends, "threat")
	for _,friend in ipairs(self.friends) do
		if not self:toTurnOver(friend, 1, "evYuFa") then
			target = friend
			break
		end
	end
	if not target then
		if #self.enemies > 0 then
			self:sort(self.enemies, "threat")
			for _,enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, 1, "evYuFa") then
					target = enemy
					break
				end
			end
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end
--room:askForUseCard(player, "@@evYuFa", "@evYuFa")
sgs.ai_skill_use["@@evYuFa"] = function(self, prompt, method)
	local target = nil
	self:sort(self.friends, "defense")
	for _,friend in ipairs(self.friends) do
		if not self:toTurnOver(friend, 1, "evYuFa") then
			target = friend
			break
		end
	end
	if not target then
		if #self.enemies > 0 then
			self:sort(self.enemies, "threat")
			for _,enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, 1, "evYuFa") then
					target = enemy
					break
				end
			end
		end
	end
	if target then
		local card_str = "#evYuFaCard:.:->"..target:objectName()
		return card_str
	end
	return "."
end
--相关信息
sgs.ai_use_value["evYuFaCard"] = 3.4
sgs.ai_use_priority["evYuFaCard"] = 2.7
sgs.ai_card_intention["evYuFaCard"] = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		local intention = 0
		if from:objectName() ~= to:objectName() then
			if self:toTurnOver(to, 1, "evYuFa") then
				intention = 50
			else
				intention = -50
			end
		end
		if intention ~= 0 then
			sgs.updateIntention(from, to, intention)
		end
	end
end
--[[
	技能：凶势（限定技）
	描述：出牌阶段，你可以弃三张点数均为X的牌，所有与你距离不超过X的其他角色须选择一项：交给你一张点数为X的手牌并流失一点体力上限，或者进行一次判定。若判定结果不为【桃】或【酒】，该角色失去X点体力并将武将牌翻面。
]]--
--room:askForCard(victim, pattern, prompt, sgs.QVariant(), sgs.Card_MethodNone, source, false, "evXiongShi")
--XiongShiCard:Play
local xiongshi_skill = {
	name = "evXiongShi",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@evXiongShiMark") > 0 then
			if self.player:getCardCount(true) >= 3 then
				return sgs.Card_Parse("#evXiongShiCard:.:")
			end
		end
	end,
}
table.insert(sgs.ai_skills, xiongshi_skill)
sgs.ai_skill_use_func["#evXiongShiCard"] = function(card, use, self)
	if #self.enemies == 0 then
		return 
	end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local compare_func = function(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(cards, compare_func)
	local to_use = {}
	local x = cards[1]:getNumber()
	for index, c in ipairs(cards) do
		local point = c:getNumber()
		if point == x then
			table.insert(to_use, c)
			if #to_use >= 3 then
				break
			end
		else
			to_use = {c}
			x = point
		end
	end
	if #to_use < 3 then
		return 
	end
	local ids = {}
	for index, c in ipairs(to_use) do
		if index <= 3 then
			table.insert(ids, c:getEffectiveId())
		else
			break
		end
	end
	local card_str = "#evXiongShiCard:"..table.concat(ids, "+")..":"
	local value = 0
	local others = self.room:getOtherPlayers(self.player)
	local victims = {}
	for _,p in sgs.qlist(others) do
		if self.player:distanceTo(p) <= x then
			table.insert(victims, p)
		end
	end
	if #victims == 0 then
		return 
	end
	local flag = ( self.role == "renegade" and self.room:alivePlayerCount() > 2 )
	local function getValue(target)
		local v = 0
		local handcards = target:getHandcards()
		local can_give = false
		local flag = string.format("visible_%s_%s", self.player:objectName(), target:objectName())
		for _,c in sgs.qlist(handcards) do
			if c:hasFlag("visible") or c:hasFlag(flag) then
				if c:getNumber() == x then
					can_give = true
					break
				end
			end
		end
		local dieFlag = false
		local isFriend = self:isFriend(target)
		local careLord = ( flag and target:isLord() and not isFriend )
		if can_give then
			v = v + 10
			if target:hasSkill("tuntian") then
				v = v - 3
			end
			if target:getHandcardNum() == 1 and self:needKongcheng(target) then
				v = v - 4
			end
			if target:getMaxHp() == 1 then
				dieFlag = true
			end
		else
			v = v + x * 20
			local hp = target:getHp()
			if hp <= x then
				if hp + self:getAllPeachNum(target) <= x then
					dieFlag = true
				end
			end
			local next_hp = hp - x
			if dieFlag then
				if target:getMark("@nirvana") > 0 and target:hasSkill("niepan") then
					dieFlag = false
					next_hp = math.min( 3, target:getMaxHp() )
				elseif isFriend or careLord then
					if target:getMark("@evYanLuoMark") == 0 then
						if self.player:hasSkill("evYanLuo") then
							dieFlag = false
							next_hp = target:getMaxHp()
						end
					end
				end
			end
			if not dieFlag then
				if target:hasSkill("zhaxiang") then
					v = v - x * 30
				end
				if getBestHp(target) > next_hp then
					v = v - 7
				end
				if self:toTurnOver(target, 0, "evXiongShi") then
					v = v + 25
				else
					v = v - 25
				end
			end
		end
		if isFriend then
			v = - v
		end
		if dieFlag then
			if isFriend then
				v = v - 50
				if target:isLord() then
					v = v - 950
				end
			elseif careLord then
				v = v - 1000
			else
				v = v + 80
				if target:isLord() then
					v = v + 1000
				end
			end
			if target:hasSkill("wuhun") then
				local lord = getLord(self.player)
				if lord then
					local revengeTargets = self:getWuhunRevengeTargets()
					for _,p in ipairs(revengeTargets) do
						if p:objectName() == lord:objectName() then
							v = v - 1000
						end
					end
				end
			end
		end
		return v
	end
	for _,victim in ipairs(victims) do
		local v = getValue(victim) or 0
		value = value + v
	end
	if value > 0 then
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
	end
end
--相关信息
sgs.ai_use_priority["evXiongShiCard"] = 10
sgs.ai_use_value["evXiongShiCard"] = 7
--[[****************************************************************
	编号：EV - 007
	武将：凶灵贾文和
	称号：凶容灵
	势力：群
	性别：男
	体力上限：3勾玉
]]--****************************************************************
--[[
	技能：绝计
	描述：一名角色因你或其自己对其造成的伤害而濒死时，你可以获得其一张牌并展示之。若此牌不为【桃】或该角色没有牌可令你获得，该角色立即死亡（你可以宣布对此事件负责）。
]]--
--room:askForSkillInvoke(source, "evJueJi", data)
sgs.ai_skill_invoke["evJueJi"] = function(self, data)
	local dying = data:toDying()
	local target = dying.who
	if self:isFriend(target) then
		return false
	end
	if self.role == "renegade" and target:isLord() then
		if self.room:alivePlayerCount() > 2 then
			return false
		end
	end
	if target:hasSkill("wuhun") then
		local lord = getLord(self.player)
		local victims = self:getWuhunRevengeTargets()
		for _,victim in ipairs(victims) do
			if victim:objectName() == self.player:objectName() then
				return false
			elseif lord and victim:objectName() == lord:objectName() then
				return false
			end
		end
	end
	return true
end
--room:askForCardChosen(source, victim, "he", "evJueJi")
--source:askForSkillInvoke("evJueJiKill", data)
sgs.ai_skill_invoke["evJueJiKill"] = function(self, data)
	local dying = data:toDying()
	local victim = dying.who
	--避免被断肠
	if victim:hasSkill("duanchang") then
		return false
	end
	--避免因毒士获得崩坏
	if victim:hasSkill("dushi") and not self.player:hasSkill("benghuai") then
		return false
	end
	--避免不能被追忆
	if victim:hasSkill("zhuiyi") and self:isFriend(victim) then
		return false
	end
	--作为主公防止误杀忠臣弃光手牌
	local role = sgs.evaluatePlayerRole(victim)
	if self.player:isLord() then
		if role == "loyalist" then
			return false
		end
	end
	--避免被挥泪
	if victim:hasSkill("huilei") then
		--只有当目标为反贼且自己不多于3张牌时，即保证有收益时才发动
		if self.player:getCardsCount(true) <= 3 and role == "rebel" then
		else
			return false
		end
	end
	--通常都是可发动的
	return true
end
--相关信息
sgs.ai_choicemade_filter["skillInvoke"].evJueJi = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	if choice == "yes" then
		local victims = self.room:getTag("CurrentDying"):toStringList()
		if #victims == 0 then
			return 
		end
		local target = nil
		local name = victims[#victims]
		local alives = self.room:getAlivePlayers()
		for _,p in sgs.qlist(alives) do
			if p:objectName() == name then
				target = p
				break
			end
		end
		if target and target:objectName() ~= player:objectName() then
			sgs.updateIntention(player, target, 400)
		end
	end
end
--[[
	技能：毒谋
	描述：当你被指定为一名角色使用的黑色锦囊牌的目标时，你可以选择一项：1、令使用者（若不是你）代替你成为此牌的目标；2、摸两张牌取消自己作为此牌的目标。
]]--
--room:askForChoice(target, "evDuMou", choices, data)
sgs.ai_skill_choice["evDuMou"] = function(self, choices, data)
	local use = data:toCardUse()
	local source = use.from
	local trick = use.card
	local targets = use.to
	if trick:isKindOf("GlobalEffect") or trick:isKindOf("ExNihilo") then
		return "cancel"
	end
	local withReplace = string.match(choices, "replace")
	local withDraw = string.match(choices, "draw")
	local isFriend = self:isFriend(source)
	if isFriend then
		if trick:isKindOf("Snatch") or trick:isKindOf("Dismantlement") then
			if self.player:containsTrick("indulgence") or self.player:containsTrick("supply_shortage") then
				if not self.player:containsTrick("YanxiaoCard") then
					return "cancel"
				end
			end
			if self.player:getArmor() and self:needToThrowArmor() then
				return "cancel"
			end
		end
	end
	if trick:isKindOf("IronChain") and self.player:isChained() then
		return "cancel"
	end
	if withDraw then
		if not isFriend then
			if self:hasSkills("danlao|huangen", source) then
				if targets:length() > 1 then
					return "draw"
				end
			end
		end
	end
	if withReplace then
		if isFriend then
			if trick:isKindOf("Snatch") or trick:isKindOf("Dismantlement") then
				if source:getArmor() and self:needToThrowArmor(source) then
					return "replace"
				end
			end
			if targets:length() > 1 then
				if self:hasSkills("danlao|huangen", source) then
					return "replace"
				end
			end
		else
			if self:hasTrickEffective(trick, source, source) then
				if trick:isKindOf("Dismantlement") then
					if source:getArmor() and self:needToThrowArmor(source) then
					elseif source:hasEquip() and self:hasSkills(sgs.lose_equip_skill, source) then
					else
						return "replace"
					end
				elseif trick:isKindOf("Duel") or trick:isKindOf("AOE") then
					return "replace"
				elseif trick:isKindOf("DelayedTrick") then
					return "replace"
				end
			end
		end
	end
	if withDraw then
		return "draw"
	end
	return "cancel"
end
--[[
	技能：凶容（限定技）
	描述：出牌阶段，你可以令所有其他角色依次选择对距离自己最近的一名角色使用一张【杀】或交给你一张红色基本牌，否则该角色对自己造成一点伤害且你摸一张牌。
]]--
--room:askForUseSlashTo(target, targets, prompt, false, false, false)
--room:askForCard(
--	target, "BasicCard|.|.|hand,equipped", prompt, sgs.QVariant(), 
--	sgs.Card_MethodNone, source, false, "evXiongRong"
--)
--XiongRongCard
local xiongrong_skill = {
	name = "evXiongRong",
	getTurnUseCard = function(self, inclusive)
		if self.player:getMark("@evXiongRongMark") > 0 then
			return sgs.Card_Parse("#evXiongRongCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, xiongrong_skill)
sgs.ai_skill_use_func["#evXiongRongCard"] = function(card, use, self)
	local has_weak_enemy = false
	for _,enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) then
			has_weak_enemy = true
			break
		end
	end
	if not has_weak_enemy then
		if not self:isWeak() then
			return 
		end
	end
	local value = 0
	local function getValue(target)
		local v = 0
		local slash, basic, draw = false, false, false
		local isFriend = self:isFriend(target)
		local flag = ( self.role == "renegade" and self.room:alivePlayerCount() > 2 )
		local careLord = ( flag and target:isLord() )
		local dieFlag = false
		if getCardsNum("Slash", target, self.player) > 0 then
			local targets = self.room:getOtherPlayers(target)
			for _,p in sgs.qlist(targets) do
				if target:canSlash(p) then
					slash = true
					break
				end
			end
		end
		if slash then
			v = v - 4
		else
			if getCardsNum("BasicCard", target, self.player) > 0 then
				basic = true
				v = v + 10
			end
			if not basic then
				draw = true
				if self:damageIsEffective(target, sgs.DamageStruct_Normal, target) then
					v = v + 20
					local hp = target:getHp() 
					if hp <= 1 then
						if hp + self:getAllPeachNum(target) <= 1 then
							dieFlag = true
						elseif self.player:hasSkill("evJueJi") then
							if isFriend or cardLord then
							else
								dieFlag = true
							end
						end
					end
				end
			end
		end
		if self:isWeak(target) then
			v = v * 1.1
		end
		if isFriend then
			v = - v
		end
		if dieFlag then
			if isFriend then
				v = v - 80
			elseif careLord then
				v = v - 200
			else
				v = v + 100
			end
		end
		if draw then
			v = v + 10
		end
		return v
	end
	local others = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(others) do
		local v = getValue(p) or 0
		value = value + v
	end
	if value > 30 then
		use.card = card
	end
end
--相关信息
sgs.ai_use_value["evXiongRongCard"] = 3
sgs.ai_use_priority["evXiongRongCard"] = 6.5
--[[****************************************************************
	编号：EV - 008
	武将：凶灵钟士季
	称号：凶运灵
	势力：魏
	性别：男
	体力上限：4勾玉
]]--****************************************************************
--[[
	技能：操控
	描述：一名其他角色的出牌阶段开始前，若你有手牌，你可以与其交换手牌、装备牌和座位，并代替其进行此出牌阶段。此阶段结束后将你们的手牌、装备牌和座位换回。此阶段中你造成伤害的伤害来源均视为该角色。若此阶段中该角色未造成伤害，你失去两点体力并弃置所有手牌。
]]--
--source:askForSkillInvoke("evCaoKong", ai_data)
sgs.ai_skill_invoke["evCaoKong"] = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		if target:getHandcardNum() > 9 then
			return true
		end
		local my_peach = 0
		local my_handcards = self.player:getHandcards()
		for _,c in sgs.qlist(my_handcards) do
			if c:isKindOf("Peach") then
				my_peach = my_peach + 1
			end
		end
		local handcards = target:getHandcards()
		local knowns = {}
		local flag = string.format("visible_%s_%s", self.player:objectName(), target:objectName())
		for _,c in sgs.qlist(handcards) do
			if c:hasFlag("visible") or c:hasFlag(flag) then
				table.insert(knowns, c)
			end
		end
		local damage, peach = 0, 0
		for _,c in ipairs(knowns) do
			if c:isKindOf("Slash") then
				for _,enemy in ipairs(self.enemies) do
					if target:canSlash(enemy) then
						damage = damage + 1
					end
				end
			elseif c:isKindOf("AOE") or c:isKindOf("Duel") then
				for _,enemy in ipairs(self.enemies) do
					if self:hasTrickEffective(c, enemy, self.player) then
						damage = damage + 1
					end
				end
			elseif c:isKindOf("Peach") then
				peach = peach + 1
			end
		end
		if self.role == "renegade" or self.player:isLord() then
			if self.room:alivePlayerCount() > 2 then
				if self.player:getHp() <= 2 then
					if self.player:getHp() + peach <= 3 then
						return false
					end
				end
			end
		end
		if damage > 0 then
			return true
		elseif peach > 0 then
			if peach > my_peach then
				return true
			end
		end
		if my_peach > peach then
			if target:getHandcardNum() <= self.player:getHandcardNum() then
				return false
			end
		end
		local overflow = self:getOverflow(target)
		if overflow > 0 then
			if target:getHandcardNum() >= self.player:getHandcardNum() then
				if getBestHp(self.player) > self.player:getHp() then
					return true
				end
			end
		end
		if overflow > 2 then
			if self.player:getHp() + self:getAllPeachNum() > 2 then
				return true
			end
		end
		if overflow > 3 then
			return true
		end
	end
	return false
end
--相关信息
sgs.ai_choicemade_filter["skillInvoke"].evCaoKong = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	if choice == "yes" then
		local current = self.room:getCurrent()
		if current and current:objectName() ~= player:objectName() then
			sgs.updateIntention(player, current, 40)
		end
	end
end
--[[
	技能：凶运（限定技）
	描述：若你处于操控的出牌阶段，你可以令被操控的角色摸三张牌，然后视为该角色对所有除你之外的角色依次使用了一张【决斗】。
]]--
--XiongYunCard:Play
local xiongyun_skill = {
	name = "evXiongYun",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasFlag("evXiongYunFail") then
			return nil
		elseif self.player:getMark("@evXiongYunMark") > 0 then
			if self.player:getMark("evCaoKongPhase") > 0 then
				return sgs.Card_Parse("#evXiongYunCard:.:")
			end
		end
	end,
}
--table.insert(sgs.ai_skills, xiongyun_skill)
sgs.ai_skill_use_func["#evXiongYunCard"] = function(card, use, self)
	local tag = self.player:getTag("evCaoKongTarget")
	local target = tag:toPlayer()
	if target and target:isAlive() and target:getMark("evCaoKongVictim") > 0 then
		local value = 0
		local others = self.room:getOtherPlayers(self.player)
		local victims = {}
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		for _,p in sgs.qlist(others) do
			if not target:isProhibited(p, duel) then
				table.insert(victims, p)
			end
		end
		if #victims == 0 then
			return 
		end
		local isFriendTarget = self:isFriend(target)
		local draw_num = 0
		if not hasManjuanEffect(target) then
			draw_num = 3
			if isFriendTarget then
				value = value + 30
			else
				value = value - 30
			end
		end
		local vt = 0
		if target:hasSkill("nosjizhi") then
			vt = vt - 10
		end
		if target:hasSkill("jizhi") then
			vt = vt - 9
		elseif target:hasSkill("jilve") and target:getMark("@bear") > 0 then
			vt = vt - 6
		end
		if target:hasSkill("jiang") then
			vt = vt - 10
		end
		if self:isWeak(target) then
			vt = vt + 12
		end
		if isFriendTarget then
			vt = - vt
		end
		value = value + vt
		local flag = ( self.role == "renegade" and self.room:alivePlayerCount() > 0 )
		local function getValue(victim)
			local v = 0
			local isFriend = self:isFriend(victim)
			local careLord = ( flag and victim:isLord() and not isFriend )
			local damage, dieFlag = false, false
			if victim:hasSkill("jiang") then
				v = v - 10
			end
			if self:hasTrickEffective(duel, victim, target) then
				v = v + 20
				damage = true
				local hp = victim:getHp()
				if hp <= 1 then
					if hp + self:getAllPeachNum(victim) <= 1 then
						dieFlag = true
					end
				end
				if getBestHp(victim) > hp then
					v = v - 3
				end
				if self:needToLoseHp(victim, target, false) then
					v = v - 4
				end
			end
			if isFriend then
				v = - v
			end
			if dieFlag then
				if careLord then
					v = v - 1000
				elseif isFriend then
					v = v - 50
					if victim:isLord() then
						v = v - 950
					end
				else
					v = v + 100
				end
			else
				if isFriendTarget and damage then
					if self:getDamagedEffects(victim, target, false) then
						v = v - 8
					end
				end
			end
			return v
		end
		for _,victim in ipairs(victims) do
			local v = getValue(victim) or 0
			value = value + v
		end
		if value > 10 then
			use.card = card
		end
	end
end
--相关信息
sgs.ai_use_value["evXiongYunCard"] = 2.5
sgs.ai_use_priority["evXiongYunCard"] = 1.7