-- This file is a modification of the original file by Unknown Worlds Entertainment
-- Only changes not done by UWE (visible by looking through git commits; first commit is original file unmodified by me)
-- are subject to the license which covers the entire project (GPLv3).

Script.Load "lua/Weapons/Weapon.lua"
Script.Load "lua/PickupableWeaponMixin.lua"
Script.Load "lua/LiveMixin.lua"

class 'Welder' (Builder)

Welder.kMapName   = "welder"
Welder.kModelName = PrecacheAsset "models/marine/welder/welder.model"
Welder.kSound	  = PrecacheAsset "sound/NS2.fev/marine/welder/weld"

kWelderHUDSlot = 3

local kWelderTraceExtents = Vector(0.4, 0.4, 0.4)

local networkVars = {}
AddMixinNetworkVars(LiveMixin, networkVars)

local kWelderEffectRate = 0.45

Welder.kHealScoreAdded = 1
-- Every kAmountHealedForPoints points of damage healed, the player gets
-- kHealScoreAdded points to their score.
Welder.kAmountHealedForPoints		 = 150
Welder.kAmountHealedForPointsPlayers = 50

function Welder:OnCreate()
	Builder.OnCreate(self)

	InitMixin(self, PickupableWeaponMixin)
	InitMixin(self, LiveMixin)

	if Client then
		self.welder_not_attached = true
	end
end

if Client then
	function Welder:OnInitialized()
		Builder.OnInitialized(self)

		self:SetAnimationInput("needWelder", true)
		self:SetAnimationInput("welder", not self.welder_not_attached)

		self.last_muzzle = 0
	end
end

function Welder:GetBuildRate()
	return kWelderFireDelay
end

function Welder:EnableEffects()
	if not self:GetIsWelding() then
        self:TriggerEffects("welder_start")
	end

	Builder.EnableEffects(self)

	local time = Shared.GetTime()
	if time - self.last_muzzle > 0.45 then
		self:TriggerEffects("welder_muzzle")
		self.last_muzzle = time
	end
end

function Welder:DisableEffects()
	Builder.DisableEffects(self)

	self:TriggerEffects("welder_end")
end

function Welder:OnPrimaryAttack(player)
	PROFILE("Welder:OnPrimaryAttack")

	self:EnableEffects()
	local coords = player:GetViewCoords()
	local trace = Shared.TraceRay(
		coords.origin,
		coords.origin + coords.zAxis * kRange,
		CollisionRep.Default,
		PhysicsMask.Bullets,
		EntityFilterTwo(player, self)
	)
	local target = trace.entity
	if trace.fraction ~= 1 then
		if target == nil then
			self:TriggerEffects("welder_hit", { effecthostcoords = Coords.GetTranslation(trace.endPoint - coords.zAxis * .1) })
		else
			self:TriggerEffects("welder_hit", { classname = target:GetClassName(), effecthostcoords = Coords.GetTranslation(trace.endPoint - coords.zAxis * .1) })
		end
	end

	if player:GetCanConstructTarget(target) then
		self:OnConstruct(target)
	elseif GetAreEnemies(player, target) then
		self:DoDamage(kWelderDamagePerSecond * self:GetBuildRate(), target, trace.endPoint, coords.zAxis)
	else
		local prevHealth = target:GetHealth()
		local prevArmor = target:GetArmor()
		target:OnWeld(self, self:GetBuildRate(), player)
		player:AddContinuousScore(
			"WeldHealth",
			target:GetHealth() + target:GetArmor() - prevHealth - prevArmor,
			target:isa "Player" and Welder.kAmountHealedForPointsPlayers or Welder.kAmountHealedForPoints,
			Welder.kHealScoreAdded
		)
		player:SetArmor(player:GetArmor() + self:GetBuildRate() * kSelfWeldAmount)
	end
end

function Welder:GetIsValidRecipient(recipient)
	return self:GetParent() == nil and recipient and not GetIsVortexed(recipient) and recipient:isa "Marine"
end

function Welder:GetRepairRate(ent)
	return ent.GetReceivesStructuralDamage and ent:GetReceivesStructuralDamage() and kStructureWeldRate or kPlayerWeldRate
end

function Welder:GetShowDamageIndicator()
	return true
end

function Welder:GetReplacementWeaponMapName()
	return Builder.kMapName
end

function Welder:UpdateViewModelPoseParameters(viewModel)
	viewModel:SetPoseParam("welder", 1)
end

function Welder:OnUpdatePoseParameters(viewModel)
	self:SetPoseParam("welder", 1)
end

function Welder:ModifyDamageTaken(damageTable, attacker, doer, damageType)
	if damageType ~= kDamageType.Corrode then
		damageTable.damage = 0
	end
end

function Welder:GetCanTakeDamageOverride()
	return self:GetParent() == nil
end

if Server then
	function Welder:OnKill()
		DestroyEntity(self)
	end

	function Welder:GetSendDeathMessageOverride()
		return false
	end
end

function Welder:GetIsWelding()
	return self.playEffect
end

function Welder:OnTag(tagName)
	if tagName == "welderAdded" then
		self:SetAnimationInput("welder", true)
	end
end

--[[ Does welder_holster even exist?
function Welder:OnHolster(player)
	Builder.OnHolster(self, player)

    self:TriggerEffects("welder_holster")
end
--]]

Shared.LinkClassToMap("Welder", Welder.kMapName, networkVars)
