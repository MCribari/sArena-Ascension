local DRData = LibStub("DRList-1.0")

local function defaultCategories()
    local categories = {}
    local indexList = {}
    for k, v in pairs(DRData:GetSpells()) do
        if type(v) == "table" then
            for _, category in ipairs(v) do
                tinsert(indexList, { spellID = k, category = category })
            end
        else
            tinsert(indexList, { spellID = k, category = v })
        end
    end
    table.sort(indexList, function(a, b)
        return a.spellID < b.spellID
    end)
    for _, v in pairs(indexList) do
        if not categories[v.category] then
            categories[v.category] = {
                enabled = true,
                forceIcon = false,
                icon = GetSpellTexture(v.spellID)
            }
        end
    end
    local categoriesL = {}
    local l = 1
    for i, v in pairs(categories) do
        categoriesL[l] = i;
        l = l + 1
    end
    return categoriesL
end
sArenaMixin.drCategories = {}
sArenaMixin.defaultSettings.profile.drCategories = {}

local categories = defaultCategories()

for _, category in ipairs(categories) do
    table.insert(sArenaMixin.drCategories, tostring(category))
    sArenaMixin.defaultSettings.profile.drCategories[category] = true
end

local drCategories = sArenaMixin.drCategories
local drTime = 20
local severityColor = {
    [1] = { 0, 1, 0, 1 },
    [2] = { 1, 1, 0, 1 },
    [3] = { 1, 0, 0, 1 },
}

local function getDiminishText(dr)
    if dr == 1 then
        return "½"
    elseif dr == 2 then
        return "¼"
    else
        return "ø"
    end
end

local GetTime = GetTime

function sArenaFrameMixin:FindDR(combatEvent, spellID)
    local category = DRData.spellList[spellID]
    if (not category) then
        return
    end
    if (not self.parent.db.profile.drCategories[category]) then
        return
    end

    local frame = self[category]
    local currTime = GetTime()

    if not frame then
        return
    end

    frame.cooldownData = frame.cooldownData or {}


    if (combatEvent == "SPELL_AURA_REMOVED" or combatEvent == "SPELL_AURA_BROKEN") then
        local startTime = frame.cooldownData.startTime or 0
        local startDuration = frame.cooldownData.duration or 0

        if startTime > 0 and startDuration > 0 then
            local newDuration = drTime / (1 - ((currTime - startTime) / startDuration))
            local newStartTime = drTime + currTime - newDuration

            frame:Show()
            frame.Cooldown:SetCooldown(newStartTime, newDuration)

            -- Update stored cooldown data
            frame.cooldownData.startTime = newStartTime
            frame.cooldownData.duration = newDuration
        else
            frame:Show()
            frame.Cooldown:SetCooldown(currTime, drTime)

            frame.cooldownData.startTime = currTime
            frame.cooldownData.duration = drTime
        end
        return
    elseif (combatEvent == "SPELL_AURA_APPLIED" or combatEvent == "SPELL_AURA_REFRESH") then
        local unit = self.unit

        for i = 1, 30 do
            local _, _, _, _, _, duration, _, _, _, _, _spellID = UnitAura(unit, i, "HARMFUL")

            if (not _spellID) then
                break
            end

            if (duration and spellID == _spellID) then
                frame:Show()
                frame.Cooldown:SetCooldown(currTime, duration + drTime)

                frame.cooldownData.startTime = currTime
                frame.cooldownData.duration = duration + drTime

                break
            end
        end
    elseif (combatEvent == "SPELL_AURA_APPLIED_DUMMY") then
        local unit = self.unit

        for i = 1, 30 do
            local duration, _spellID = 5, spellID

            if (not _spellID) then
                break
            end

            if (duration and spellID == _spellID) then
                frame:Show()
                frame.Cooldown:SetCooldown(currTime, duration + drTime)

                frame.cooldownData.startTime = currTime
                frame.cooldownData.duration = duration + drTime
                break
            end
        end
    end

    frame.Icon:SetTexture(select(3, GetSpellInfo(spellID)))
    frame.Border:SetVertexColor(unpack(severityColor[frame.severity]))
    if self.parent.db.profile.drText then
        if not frame.Text then
            frame.Text = frame.Cooldown:CreateFontString(nil, "OVERLAY")
            frame.Text:SetFont("Interface\\AddOns\\sArena\\ARIALN.ttf", 8, "OUTLINE")
            frame.Text:SetJustifyH("CENTER")
            frame.Text:SetPoint("CENTER", frame, "CENTER", 0, -8)
        end
        frame.Text:SetText(getDiminishText(frame.severity))
        frame.Text:SetTextColor(unpack(severityColor[frame.severity]))
    end

    frame.severity = frame.severity + 1
    if frame.severity > 3 then
        frame.severity = 3
    end
end

function sArenaFrameMixin:UpdateDRPositions()
    local layoutdb = self.parent.layoutdb
    local numActive = 0
    local frame, prevFrame
    local spacing = layoutdb.dr.spacing
    local growthDirection = layoutdb.dr.growthDirection

    for i = 1, #drCategories do
        frame = self[drCategories[i]]

        if (frame and frame:IsShown()) then
            frame:ClearAllPoints()
            if (numActive == 0) then
                frame:SetPoint("CENTER", self, "CENTER", layoutdb.dr.posX, layoutdb.dr.posY)
            else
                if (growthDirection == 4) then
                    frame:SetPoint("RIGHT", prevFrame, "LEFT", -spacing, 0)
                elseif (growthDirection == 3) then
                    frame:SetPoint("LEFT", prevFrame, "RIGHT", spacing, 0)
                elseif (growthDirection == 1) then
                    frame:SetPoint("TOP", prevFrame, "BOTTOM", 0, -spacing)
                elseif (growthDirection == 2) then
                    frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, spacing)
                end
            end
            numActive = numActive + 1
            prevFrame = frame
        end
    end
end

function sArenaFrameMixin:ResetDR()
    for i = 1, #drCategories do
        local category = drCategories[i]
        if self[category] and self[category].Cooldown then
            self[category].Cooldown:Clear()
            self[category]:Hide()
        end
    end
end
