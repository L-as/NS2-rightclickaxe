
for _, v in ipairs {
	"Builder",
	"Axe",
	"Welder"
} do
	ModLoader.SetupFileHook("lua/Weapons/Marine/" .. v .. ".lua", "lua/rightclickaxe/" .. v .. ".lua", "post")
end
