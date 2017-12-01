
for _, v in ipairs {
	"Builder",
	"Welder",
} do
	ModLoader.SetupFileHook("lua/Weapons/Marine/" .. v .. ".lua", "lua/rightclickaxe/" .. v .. ".lua", "replace")
end
ModLoader.SetupFileHook("lua/Weapons/Marine/Axe.lua", "lua/rightclickaxe/Axe.lua", "post")

ModLoader.SetupFileHook("lua/Marine.lua",         "lua/rightclickaxe/Marine.lua",         "post")
ModLoader.SetupFileHook("lua/ConstructMixin.lua", "lua/rightclickaxe/ConstructMixin.lua", "post")
