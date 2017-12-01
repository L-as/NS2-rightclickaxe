
for _, v in ipairs {
	"Builder",
	"Axe",
} do
	ModLoader.SetupFileHook("lua/Weapons/Marine/" .. v .. ".lua", "lua/rightclickaxe/" .. v .. ".lua", "post")
end
ModLoader.SetupFileHook("lua/Weapons/Marine/Welder.lua", "lua/rightclickaxe/Welder.lua", "replace")

ModLoader.SetupFileHook("lua/Marine.lua",         "lua/rightclickaxe/Marine.lua",         "post")
ModLoader.SetupFileHook("lua/ConstructMixin.lua", "lua/rightclickaxe/ConstructMixin.lua", "post")
