gModClassMap.Builder.networkVars = {}

Builder.OnDrawClient		= Weapon.OnDrawClient
Builder.ProcessMoveOnWeapon = Weapon.ProcessMoveOnWeapon
Builder.OnHolster			= Weapon.OnHolster

function Builder:GetHUDSlot()
	return 3
end

function Builder:GetIsDroppable()
	return true
end

if Client then
	function Builder:OnConstruct(target)
		self.playEffect = true
		target:Construct(kUseInterval, self:GetParent())
	end

	function Builder:OnConstructEnd()
		self.playEffect = false
	end
elseif Server then
	function Builder:OnConstruct(target)
		if not self.loopingFireSound:GetIsPlaying() then
			self.loopingFireSound:Start()
		end
		target:Construct(kUseInterval, self:GetParent())
	end

	function Builder:OnConstructEnd()
		self.loopingFireSound:Stop()
	end
elseif Predict then
	function Builder:OnConstruct(target)
		target:Construct(kUseInterval, self:GetParent())
	end

	function Builder:OnConstructEnd()
	end
end

function Builder:OnPrimaryAttack(player)
	local coords = player:GetViewCoords()
	local target = Shared.TraceRay(
		coords.origin,
		coords.origin + coords.zAxis * 100,
		CollisionRep.Default,
		PhysicsMask.Bullets
	).entity
	if player:GetCanConstruct(target) then
		self:OnConstruct(target)
	end
end

function Builder:OnPrimaryAttackEnd()
	self:OnConstructEnd()
end

if Server then
	function Builder:OnHolster(player)
		Weapon.OnHolster(self, player)

		self.loopingFireSound:Stop()
	end
end
