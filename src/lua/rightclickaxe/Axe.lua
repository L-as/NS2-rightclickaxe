gModClassMap.Axe.networkVars.sprintAllowed = nil

function Axe:GetHUDSlot()
	return 0 -- no slot
end

function Axe:OnUpdateAnimationInput()
	self:SetAnimationInput("activity", self.primaryAttacking and "primary" or "none")
	self:SetAnimationInput("idleName", "idle")
end

function Axe:OnPrimaryAttack(player)
	self.primaryAttacking = true
end

function Axe:OnPrimaryAttackEnd(player)
	self.primaryAttacking = false
end

function Axe:OnTag(tagName)
	if tagName == "swipe_sound" then
		local player = self:GetParent()
		if player then
			player:TriggerEffects("axe_attack")
		end
	elseif tagName == "hit" then
		local player = self:GetParent()
		if player then
			AttackMeleeCapsule(self, player, kAxeDamage, self:GetRange())
		end
	end
end

Axe.GetSprintAllowed = Weapon.GetSprintAllowed
