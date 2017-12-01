function Marine:GetCanConstructTarget(target)
	return target and HasMixin(target, "Construct")
		and ( target:GetCanConstruct(self) or (target.CanBeWeldedByBuilder and target:CanBeWeldedByBuilder()) )
		and not
			(  target:isa("PowerPoint") and -- is a powerpoint
			not target:GetIsBuilt() and target.buildFraction == 1 -- which is primed
			and not target:CanBeCompletedByScriptActor( self ) ) -- but can't be finished
end

function Marine:OnUseTarget(target)
	if self:GetCanConstructTarget(target) then
		if self.weaponBeforeUseId == Entity.invalidId  then
			self.weaponBeforeUseId = self:GetActiveWeapon():GetId()
		end

		local slot = self.quickSwitchSlot
		self:SetHUDSlotActive(3)
		self.quickSwitchSlot = slot
		self:GetActiveWeapon():OnConstruct(target)
	else
		self:OnUseEnd()
	end
end

function Marine:OnUseEnd()
	if self.weaponBeforeUseId ~= Entity.invalidId then
		self:GetActiveWeapon():OnConstructEnd(target)
		self:SetActiveWeapon(Shared.GetEntity(self.weaponBeforeUseId):GetMapName(), true)
	end

	self.weaponBeforeUseId = Entity.invalidId
end
