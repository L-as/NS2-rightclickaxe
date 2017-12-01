
for _, v in ipairs {
	"Builder",
	"Axe",
	"Welder"
} do
	ModLoader.SetupFileHook("lua/Weapons/Marine/" .. v .. ".lua", "lua/rightclickaxe/" .. v .. ".lua", "post")
end

ModLoader.SetupFileHook("lua/Marine.lua",         "lua/rightclickaxe/Marine.lua",         "post")
ModLoader.SetupFileHook("lua/ConstructMixin.lua", "lua/rightclickaxe/ConstructMixin.lua", "post")
