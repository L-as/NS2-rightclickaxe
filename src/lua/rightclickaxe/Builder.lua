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

local EnableEffects, DisableEffects
if Client then
	EnableEffects  = function(self)
		self.playEffect = true
	end
	DisableEffects = function(self)
		self.playEffect = false
	end
elseif Server then
	EnableEffects  = function(self)
		if not self.loopingFireSound:GetIsPlaying() then
			self.loopingFireSound:Start()
		end
	end
	DisableEffects = function(self)
		if self.loopingFireSound:GetIsPlaying() then
			self.loopingFireSound:Stop()
		end
	end
else
	EnableEffects  = function() end
	DisableEffects = function() end
end

function Builder:OnConstruct(target)
	EnableEffects(self)
	target:Construct(kUseInterval, self:GetParent())
end

function Builder:OnConstructEnd()
	DisableEffects(self)
end

function Builder:OnPrimaryAttack(player)
	EnableEffects(self)
	local coords = player:GetViewCoords()
	local target = Shared.TraceRay(
		coords.origin,
		coords.origin + coords.zAxis * 100,
		CollisionRep.Default,
		PhysicsMask.Bullets,
		EntityFilterTwo(player, self)
	).entity
	if player:GetCanConstructTarget(target) then
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
