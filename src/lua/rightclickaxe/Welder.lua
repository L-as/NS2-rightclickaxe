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
local kRange            = 2.4

Welder.kHealScoreAdded = 1
-- Every kAmountHealedForPoints points of damage healed, the player gets
-- kHealScoreAdded points to their score.
Welder.kAmountHealedForPoints		 = 150
Welder.kAmountHealedForPointsPlayers = 50

function Welder:OnCreate()
	Builder.OnCreate(self)

	InitMixin(self, PickupableWeaponMixin)
	InitMixin(self, LiveMixin)

	self.last_muzzle = 0

	if Client then
		self.welder_not_attached = true
	end
end

if Client then
	function Welder:OnInitialized()
		Builder.OnInitialized(self)

		self.last_muzzle = 0
	end
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

function Welder:GetBuildRate()
	return kWelderFireDelay
end

function Welder:OnConstructTarget(target, endPoint)
	local zAxis = self:GetParent():GetViewCoords().zAxis

	local player = self:GetParent()

	if player:GetCanConstructTarget(target) then
		target:Construct(kWelderFireDelay, player)
	elseif GetAreEnemies(player, target) then
		self:DoDamage(kWelderDamagePerSecond * kWelderFireDelay, target, endPoint, zAxis)
	else
		local prevHealth = target:GetHealth()
		local prevArmor = target:GetArmor()
		target:OnWeld(self, kWelderFireDelay, player)
		player:AddContinuousScore(
			"WeldHealth",
			target:GetHealth() + target:GetArmor() - prevHealth - prevArmor,
			target:isa "Player" and Welder.kAmountHealedForPointsPlayers or Welder.kAmountHealedForPoints,
			Welder.kHealScoreAdded
		)
		player:SetArmor(player:GetArmor() + kWelderFireDelay * kSelfWeldAmount)
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

function Welder:OnUpdateAnimationInput()
	self:SetAnimationInput("activity", self.playEffect and "primary" or "none")
	self:SetAnimationInput("needWelder", true)
	--self:SetAnimationInput("welder", not self.welder_not_attached)
	self:SetAnimationInput("welder", false)
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
		self.welder_not_attached = false
	end
end

function Welder:OnUpdateRender()
	Weapon.OnUpdateRender(self)

	if self.ammoDisplayUI then
		local progress = PlayerUI_GetUnitStatusPercentage()
		self.ammoDisplayUI:SetGlobal("weldPercentage", progress)
	end

	local time = Shared.GetTime()
	if self.playEffect and time - self.lastBuilderEffect > 0.06 then
		self.lastBuilderEffect = time

		local player = self:GetParent()
		local coords = player:GetViewCoords()
		local trace  = Shared.TraceRay(
			coords.origin,
			coords.origin + coords.zAxis * 2.4,
			CollisionRep.Default,
			PhysicsMask.Bullets,
			EntityFilterTwo(player, self)
		)
		if trace.fraction == 1 then return end
		local target    = trace.entity
		local endPoint  = trace.endPoint
		local zAxis     = coords.zAxis
		local classname = target and target:GetClassName()
		self:TriggerEffects("welder_hit", {
			classname = classname,
			effecthostcoords = Coords.GetTranslation(endPoint - zAxis * .1)
		})
	end
end

function Welder:GetIsDroppable()
	return true
end

--[[ Does welder_holster even exist?
function Welder:OnHolster(player)
	Builder.OnHolster(self, player)

	self:TriggerEffects("welder_holster")
end
--]]

Shared.LinkClassToMap("Welder", Welder.kMapName, networkVars)
