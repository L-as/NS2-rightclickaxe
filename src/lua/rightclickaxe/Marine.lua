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
		if not self.prev_weapon_before_build then
			self.prev_weapon_before_build = self:GetActiveWeapon():GetMapName()
		end

		local slot = self.quickSwitchSlot
		self:SetHUDSlotActive(3)
		self.quickSwitchSlot = slot

		self:GetActiveWeapon():ConstructTarget(target)
	else
		self:OnUseEnd()
	end
end

function Marine:OnUseEnd()
	if self.prev_weapon_before_build then
		if self:GetActiveWeapon():isa "Builder" then
			self:GetActiveWeapon():ConstructTargetEnd(target)
		end
		self:SetActiveWeapon(self.prev_weapon_before_build, true)
		self.prev_weapon_before_build = nil
	end
end

if not Server then return end

function Marine:GiveItem(itemMapName, setActive, suppressError)
	if not itemMapName then return end

	if setActive == nil then
		setActive = true
	end

	if itemMapName == LayMines.kMapName then
		local mineWeapon = self:GetWeapon(LayMines.kMapName)

		if mineWeapon then
			mineWeapon:Refill(kNumMines)
			if setActive then
				self:SetActiveWeapon(LayMines.kMapName)
			end
			return mineWeapon
		end
	end

	return Player.GiveItem(self, itemMapName, setActive, suppressError)
end

-- Allow weapons to replace other weapons
function Marine:AddWeapon(weapon)
	local replacement = weapon.GetReplacementWeaponMapName and weapon:GetReplacementWeaponMapName()
	local obsoleteWep = replacement and self:GetWeapon(replacement)
	if obsoleteWep then
		self:RemoveWeapon(obsoleteWep)
		DestroyEntity(obsoleteWep)
	end
end

function Marine:SecondaryAttack()
	if not self.prev_weapon_before_axe then
		self.prev_weapon_before_axe = self:GetActiveWeapon():GetMapName()
	end

	self:SetActiveWeapon(Axe.kMapName, true)
	local axe = self:GetActiveWeapon()
	axe:OnPrimaryAttack(self)
end

function Marine:SecondaryAttackEnd()
	self:GetActiveWeapon():OnPrimaryAttackEnd()
	self:SetActiveWeapon(self.prev_weapon_before_axe, true)
	self.prev_weapon_before_axe = nil
end
