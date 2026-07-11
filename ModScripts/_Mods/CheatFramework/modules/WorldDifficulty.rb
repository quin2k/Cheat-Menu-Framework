MenuFramework::SUBMENU.register_command(
  group:  :NPC,
  type:   :edit_num,
  key:    "World Difficulty",
  label:  "modules/others:commands/world",
  state:  "$story_stats['WorldDifficulty'].to_i",
  min:    0,
  max:    100,
  action: ->(v) { $story_stats["WorldDifficulty"] = v },
  order:  20
)

MenuFramework::SUBMENU.register_command(
  group:  :NPC,
  type:   :action,
  key:    "Disable Doom Mode",
  label:  "modules/others:commands/diff",
  help1:  "modules/others:command_help/diff",
  hide:   -> { $story_stats["Setup_Hardcore"] != 2 },
  order:  90,
  action: -> { $story_stats["Setup_Hardcore"] = 0
               $story_stats["record_giveup_hardcore"] = 0 }
)
