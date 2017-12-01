function Axe:GetHUDSlot()
	return 0 -- no slot
end

function Axe:OnUpdateAnimationInput()
	PROFILE("Axe:OnUpdateAnimationInput")

	local activity = "none"
	if self.primaryAttacking then
		activity = "primary"
	end
	self:SetAnimationInput("activity", self.primaryAttacking and "primary" or "none")
end

local old = Axe.OnInitialized
function Axe:OnInitialized()
	old(self)

	self:SetAnimationInput("idleName", "idle")
end

function Axe:GetIsDroppable()
	return false
end
