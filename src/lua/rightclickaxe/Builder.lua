Script.Load "lua/Weapons/Weapon.lua"

class 'Builder' (Weapon)

Builder.kMapName   = "builder"
Builder.kModelName = PrecacheAsset "models/marine/welder/builder.model"
Builder.kSound     = PrecacheAsset "sound/NS2.fev/marine/welder/scan"

local kViewModels	  = GenerateMarineViewModelPaths("welder")
local kAnimationGraph = PrecacheAsset("models/marine/welder/welder_view.animation_graph")

local kRange			   = 2.4
local kBuildEffectInterval = 0.2

if Server then
	function Builder:OnCreate()
		Weapon.OnCreate(self)

		self.loopingFireSound = Server.CreateEntity(SoundEffect.kMapName)
		self.loopingFireSound:SetAsset(self.kSound)
		self.loopingFireSound:SetParent(self)
	end
end

function Builder:OnInitialized()
	Weapon.OnInitialized(self)

	self:SetModel(self.kModelName)

	self.last_build_time = 0
	self.play_effect = false

	if Client then
		self.lastBuilderEffect = 0
	end
end

function Builder:OverrideWeaponName()
	return "builder"
end

function Builder:GetViewModelName(sex, variant)
	return kViewModels[sex][variant]
end

function Builder:GetAnimationGraphName()
	return kAnimationGraph
end

function Builder:GetHUDSlot()
	return 3
end

function Builder:GetSprintAllowed()
	return true
end

function Builder:GetTryingToFire()
	return false
end

function Builder:GetDeathIconIndex()
	return kDeathMessageIcon.Welder
end

if Server then
	function Builder:EnableEffects()
		self.playEffect = true
		if not self.loopingFireSound:GetIsPlaying() then
			self.loopingFireSound:Start()
		end
	end
	function Builder:DisableEffects()
		self.playEffect = false
		if self.loopingFireSound:GetIsPlaying() then
			self.loopingFireSound:Stop()
		end
	end
else
	function Builder:EnableEffects()
		self.playEffect = true
	end
	function Builder:DisableEffects()
		self.playEffect = false
	end
end

function Builder:GetBuildRate()
	return kUseInterval
end

function Builder:ConstructTarget(target)
	PROFILE("Builder:ConstructTarget")

	self:EnableEffects()

	local now = Shared.GetTime()
	if now - self.last_build_time < self:GetBuildRate() then return end
	self.last_build_time = now

	local endPoint
	if not target then
		local player = self:GetParent()
		local coords = player:GetViewCoords()
		local trace  = Shared.TraceRay(
			coords.origin,
			coords.origin + coords.zAxis * kRange,
			CollisionRep.Default,
			PhysicsMask.Bullets,
			EntityFilterTwo(player, self)
		)
		target = trace.entity
		endPoint = trace.fraction ~= 1 and trace.endPoint or nil
	end

	if not target then return end
	self:OnConstructTarget(target, endPoint)
end

function Builder:ConstructTargetEnd()
	self:DisableEffects()
end

function Builder:OnConstructTarget(target, endPoint)
	local player = self:GetParent()
	if player:GetCanConstructTarget(target) then
		target:Construct(kUseInterval, self:GetParent())
	end
end

function Builder:OnPrimaryAttack(player)
	self:ConstructTarget()
end

function Builder:OnPrimaryAttackEnd()
	self:ConstructTargetEnd()
end

function Builder:OnDraw(player, previousWeaponMapName)
	Weapon.OnDraw(self, player, previousWeaponMapName)

	self:SetAttachPoint(Weapon.kHumanAttachPoint)
end

if Server then
	function Builder:OnHolster(player)
		Weapon.OnHolster(self, player)

		self:DisableEffects()
	end
elseif Client then
	function Builder:OnHolsterClient()
		Weapon.OnHolsterClient(self)

		self:DisableEffects()
	end
end

function Builder:UpdateViewModelPoseParameters(viewModel)
	viewModel:SetPoseParam("welder", 0)
end

function Builder:OnUpdateAnimationInput()
	PROFILE("Builder:OnUpdateAnimationInput")

	self:SetAnimationInput("activity", self.playEffect and "primary" or "none")
	self:SetAnimationInput("welder",	 false)
	self:SetAnimationInput("needWelder", false)
	self:SetPoseParam("welder", 0)
end

local kCinematicName	 = PrecacheAsset("cinematics/marine/builder/builder_scan.cinematic")
local kMuzzleAttachPoint = "fxnode_weldermuzzle"

function Builder:OnUpdateRender()
	Weapon.OnUpdateRender(self)

	if self.ammoDisplayUI then
		local progress = PlayerUI_GetUnitStatusPercentage()
		self.ammoDisplayUI:SetGlobal("weldPercentage", progress)
	end

	if self.playEffect and self.lastBuilderEffect + kBuildEffectInterval <= Shared.GetTime() then
		self.lastBuilderEffect = Shared.GetTime()
		CreateMuzzleCinematic(self, kCinematicName, kCinematicName, kMuzzleAttachPoint)
	end
end

if Client then
	function Builder:GetUIDisplaySettings()
		return { xSize = 512, ySize = 512, script = "lua/GUIWelderDisplay.lua", textureNameOverride = "welder" }
	end
end

function Builder:GetIsAffectedByWeaponUpgrades()
	return false
end

Shared.LinkClassToMap("Builder", Builder.kMapName, {})
