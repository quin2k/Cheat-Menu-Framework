MenuFramework::SUBMENU.register_command(
  group:  :MISC,
  type:   :edit_num,
  key:    "World Difficulty",
  label:  "modules/others:command/world",
  state:  "$story_stats['WorldDifficulty'].to_i",
  min:    0,
  max:    100,
  action: ->(v) { $story_stats["WorldDifficulty"] = v },
)
