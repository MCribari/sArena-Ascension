local GetTime = GetTime

sArenaMixin.defaultSettings.profile.racialCategories = {
	["Human"] = true,
	["Scourge"] = true,
	["Gnome"] = true,
	["Dwarf"] = true,
	["Orc"] = true,
	["Tauren"] = true,
	["BloodElf"] = true,
	["Troll"] = true,
	["Draenei"] = false,
	["NightElf"] = false,
}

local racialSpells = {
	[20549] = 120,  -- War Stomp
	[7744] = 120,   -- Will of the Forsaken
	[20572] = 120,   -- Blood Fury
	[58984] = 10,   -- Shadowmeld
	[20589] = 105,   -- Escape Artist
	[20594] = 180,   -- Stoneform
	[59752] = 120, -- Will to survive
	[26297] = 180,   -- Berserking
	[28880] = 180,   -- Gift of the Naaru
	[59544] = 180,   -- Gift of the Naaru
	[59545] = 180,   -- Gift of the Naaru
	[59547] = 180,   -- Gift of the Naaru
	[59548] = 180,   -- Gift of the Naaru
	[59542] = 180,   -- Gift of the Naaru
	[59543] = 180,   -- Gift of the Naaru
	[33702] = 120,   -- Blood Fury - Caster
	[33697] = 120,   -- Blood Fury
	[25046] = 120,   -- Arcane Torrent - Rogue
	[28730] = 120,   -- Arcane Torrent - Mana
	[50613] = 120,   -- Arcane Torrent - DK
}

local racialData = {
	["Human"] = { texture = select(3, GetSpellInfo(59752)) },
	["Scourge"] = { texture = select(3, GetSpellInfo(7744)) },
	["Gnome"] = { texture = select(3, GetSpellInfo(20589))},
	["Dwarf"] = { texture = select(3, GetSpellInfo(20594))},
	["Orc"] = { texture = select(3, GetSpellInfo(20572))},
	["Tauren"] = { texture = select(3, GetSpellInfo(20549))},
	["BloodElf"] = { texture = select(3, GetSpellInfo(28730))},
	["Troll"] = { texture = select(3, GetSpellInfo(26297))},
	["Draenei"] = { texture = select(3, GetSpellInfo(28880))},
	["NightElf"] = { texture = select(3, GetSpellInfo(58984))},
}

-- Spells that trigger a shared cd with racials
local sharedSpells = {
	[42292] = {  -- PvP trinket
		races = {
			["Scourge"] = 45,
			["Human"] = 120
		}
	}
}

local spellStartTimes = {}
local function GetRemainingCD(spellID)
	if not spellStartTimes then
		spellStartTimes = {}
	end

	local currTime = GetTime()
	local duration = racialSpells[spellID]

	if not duration then
		return 0
	end

	local startTime = spellStartTimes[spellID] or 0
	local remainingCD = math.max(0, (startTime + duration) - currTime)

	return remainingCD
end

function sArenaFrameMixin:FindRacial(event, spellID, duration)
	if ( event ~= "SPELL_CAST_SUCCESS" ) then return end

	local _, race = UnitRace(self.unit)
	local currentCD = GetRemainingCD(spellID)
	if sharedSpells[spellID]
			and sharedSpells[spellID].races[race]
			and currentCD < sharedSpells[spellID].races[race]
	then
		duration = sharedSpells[spellID].races[race]
	end

	duration = duration or racialSpells[spellID]

	if ( duration ) then
		local currTime = GetTime()

		if ( self.Racial.Texture:GetTexture() ) then
			self.Racial.Cooldown:SetCooldown(currTime, duration)
		end

	end
end

function sArenaFrameMixin:UpdateRacial()
	if ( not self.race ) then
		local _, race = UnitRace(self.unit)
		self.race = race

		if ( self.parent.db.profile.racialCategories[self.race] ) then
			self.Racial.Texture:SetTexture(racialData[self.race].texture)
		end
	end
end

function sArenaFrameMixin:ResetRacial()
	self.race = nil
	self.Racial.Texture:SetTexture(nil)
	self.Racial.Cooldown:Clear()
	self:UpdateRacial()
	spellStartTimes = {}
end
