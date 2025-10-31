local GetTime = GetTime

local trinketSpells = {
	[42292] = 120, -- Trinket
  	[59752] = 120, -- Will to survive	
}

-- Spells that trigger a shared cd with pvp trinkets
local sharedSpells = {
	[7744] = 45 -- Will of the forsaken
}

local trinketData = {
	["Alliance"] = { texture = "Interface\\Icons\\Inv_jewelry_necklace_37"},
	["Horde"] = { texture = "Interface\\Icons\\Inv_jewelry_necklace_38"},
    ["Human"] = { texture = "Interface\\Icons\\Spell_shadow_charm"},
}

local spellStartTimes = {}
local function GetRemainingCD(spellID)
	if not spellStartTimes then
		spellStartTimes = {}
	end

	local currTime = GetTime()
	local duration = trinketSpells[spellID]

	if not duration then
		return 0
	end

	local startTime = spellStartTimes[spellID] or 0
	local remainingCD = math.max(0, (startTime + duration) - currTime)

	return remainingCD
end

function sArenaFrameMixin:FindTrinket(event, spellID, duration)
    if ( event ~= "SPELL_CAST_SUCCESS" ) then return end

	local currentCD = GetRemainingCD(spellID)
	if sharedSpells[spellID]
		and currentCD < sharedSpells[spellID] 
	then
		duration = sharedSpells[spellID]
	end

    duration = duration or trinketSpells[spellID]

    if ( duration ) then
        local currTime = GetTime()
		self.Trinket.spellID = spellID
		self.Trinket.Cooldown:SetCooldown(currTime, duration)
	end
end

function sArenaFrameMixin:UpdateTrinket()
	local _, _, raceId = UnitRace(self.unit)
	local faction = UnitFactionGroup(self.unit)
	if (raceId == 1) then
		self.Trinket.Texture:SetTexture(trinketData["Human"].texture)
	else 
		if (faction) then
			self.Trinket.Texture:SetTexture(trinketData[faction].texture)
		end
	end
end

function sArenaFrameMixin:ResetTrinket()
	self.Trinket.spellID = nil
    self.Trinket.Texture:SetTexture(nil)
    self.Trinket.Cooldown:Clear()
    self:UpdateTrinket()
end
