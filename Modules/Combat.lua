local function InCombat(unit)
    local _, _, class = UnitClass(unit)

    if UnitAffectingCombat(unit) then
        return true
    else
        if (IsActiveBattlefieldArena() and not (class == 1 or class == 2 or class == 4 or class == 11)) then
            for i = 1, 5, 1 do
                if UnitExists("arenapet" .. i .. "target") or UnitDetailedThreatSituation("player", "arenapet" .. i) or
                        UnitDetailedThreatSituation("party"..i, "arenapet" .. i) then
                    if UnitIsUnit(unit, "arena" .. i) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function sArenaFrameMixin:CreateCombatIndicatorForUnit()
    if not self.CombatIcon then
        local ciFrame = self:CreateTexture(nil, "OVERLAY")
        ciFrame:SetPoint("CENTER", self, "CENTER", self.parent.db.profile.CombatIndicator.posX, self.parent.db.profile.CombatIndicator.posY)
        ciFrame:SetSize(30, 30)
        ciFrame:SetTexture("Interface\\AddOns\\sArena\\Textures\\CombatSwords")
        ciFrame:Hide()

        self:RegisterEvent("UNIT_FLAGS")
        self:HookScript("OnEvent", function(self, event)
            if event == "UNIT_FLAGS" and self:IsShown() then
                local unit = SecureButton_GetUnit(self)
                self.CombatIcon:SetShown(InCombat(unit))
            end
        end)

        self.CombatIcon = ciFrame
    end
end
