Script.Load "lua/Weapons/Weapon.lua"

class 'Builder' (Weapon)

Builder.kMapName   = "builder"
Builder.kModelName = PrecacheAsset("models/marine/welder/builder.model")

local kViewModels	  = GenerateMarineViewModelPaths("welder")
local kAnimationGraph = PrecacheAsset("models/marine/welder/welder_view.animation_graph")

local kRange			   = 2.4
local kBuildEffectInterval = 0.2

local kFireLoopingSound = PrecacheAsset("sound/NS2.fev/marine/welder/scan")

if Server then
	function Builder:OnCreate()
		Weapon.OnCreate(self)

		self.loopingFireSound = Server.CreateEntity(SoundEffect.kMapName)
		self.loopingFireSound:SetAsset(kFireLoopingSound)
		self.loopingFireSound:SetParent(self)
		self.loopingSoundEntId = self.loopingFireSound:GetId()
	end
elseif Client then
	function Builder:OnCreate()
		Weapon.OnCreate(self)

		self.lastBuilderEffect = 0
	end
end

function Builder:OnInitialized()
	Weapon.OnInitialized(self)

	self:SetAnimationInput("activity",	 "primary")
	self:SetAnimationInput("welder",	 false)
	self:SetAnimationInput("needWelder", false)
	self:SetPoseParam("welder", 0)

	self:SetModel(self.kModelName)
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

function Builder:GetIsDroppable()
	return true
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
		coords.origin + coords.zAxis * kRange,
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

function Builder:OnDraw(player, previousWeaponMapName)
	Weapon.OnDraw(self, player, previousWeaponMapName)

	self:SetAttachPoint(Weapon.kHumanAttachPoint)
end

if Server then
	function Builder:OnHolster(player)
		Weapon.OnHolster(self, player)

		DisableEffects(self)
	end
elseif Client then
	function Builder:OnHolsterClient()
		Weapon.OnHolsterClient(self)

		DisableEffects(self)
	end
end

function Builder:UpdateViewModelPoseParameters(viewModel)
	viewModel:SetPoseParam("welder", 0)
end

local kCinematicName	 = PrecacheAsset("cinematics/marine/builder/builder_scan.cinematic")
local kMuzzleAttachPoint = "fxnode_weldermuzzle"

function Builder:OnUpdateRender()
	Weapon.OnUpdateRender(self)

	if self.ammoDisplayUI then
		local progress = PlayerUI_GetUnitStatusPercentage()
		self.ammoDisplayUI:SetGlobal("weldPercentage", progress)
	end

	if self.playEffect then
		if self.lastBuilderEffect + kBuildEffectInterval <= Shared.GetTime() then
			CreateMuzzleCinematic(self, kCinematicName, kCinematicName, kMuzzleAttachPoint)
			self.lastBuilderEffect = Shared.GetTime()
		end
	end
end

if Client then
	function Builder:GetUIDisplaySettings()
		return { xSize = 512, ySize = 512, script = "lua/GUIWelderDisplay.lua", textureNameOverride = "welder" }
	end
end

Shared.LinkClassToMap("Builder", Builder.kMapName, {})
