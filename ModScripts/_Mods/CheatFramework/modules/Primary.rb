FrameworkModule = {
  name:       "Primary Stats", #Scene/Window names would be Window_CheatMenuEdit_Lona.
  key:        :primary, #Menu key, also used to label source module.
  menu:       :PRIMARY, #Dictionary / Group key.
  order:      90,
  depends_on: []
}

module MenuFramework
  module SUBMENU
    #==========================================
    # Character Editing Menu
    #==========================================
    register_command(
      group:  :LONA,
      type:   :scene,
      key:    :edit_primary,
      label:  "modules/character:commands/primary",
      menu1:  "menu:window_help/character1",
      name:   "CheatMenuPrimary",
      dict:   :PRIMARY,
      order:  10
    )

    #------------------------------------------
    # Primary 
    #------------------------------------------
    register_command(
      group:  :PRIMARY,
      type:   :edit_num,
      key:    "Health",
      label:  "modules/character:commands/primary/health",
      state:  "$game_player.actor.health.to_i",
      enable: -> {!$cheat_infinite_health},
      min:    -100,
      max:    999,
      action: ->(v) { $game_player.actor.health = v },
      order:  10
      )
    register_command(
      group:  :PRIMARY,
      type:   :edit_num,
      key:    "Stamina",
      label:  "modules/character:commands/primary/stamina",
      enable: -> {!$cheat_infinite_stamina},
      state:  "$game_player.actor.sta.to_i",
      min:    -100,
      max:    200,
      action: ->(v) { $game_player.actor.sta = v },
      order:  20
    )
    register_command(
      group:  :PRIMARY,
      type:   :edit_num,
      key:    "Food",
      label:  "modules/character:commands/primary/food",
      enable: -> {!$cheat_infinite_food},
      state:  "$game_player.actor.sat",
      min:    0,
      max:    200,
      action: ->(v) { $game_player.actor.sat = v },
      order:  30
    )
      register_command(
      group:  :PRIMARY,
      type:   :edit_num,
      key:    "Mood",
      label:  "modules/character:commands/primary/mood",
      state:  "$game_player.actor.mood",
      min:    -100,
      max:    100,
      action: ->(v) { $game_player.actor.mood = v },
      order:  40
    )
    register_command(
      group:  :PRIMARY,
      type:   :edit_num,
      key:    "Arousal",
      label:  "modules/character:commands/primary/arousal",
      state:  "$game_player.actor.arousal",
      min:    0,
      max:    5000,
      action: ->(v) { $game_player.actor.arousal = v },
      order:  50
    )
    register_command(
      group:  :PRIMARY,
      type:   :edit_num,
      key:    "Morality",
      label:  "modules/character:commands/primary/morality",
      state:  "$game_player.actor.morality",
      help1:  "modules/character:command_help/moral",
      min:    -> {$game_player.actor.morality_plus - 200},
      max:    -> {100 + $game_player.actor.morality_plus - 200},
      action: ->(v) { 
        $game_player.actor.morality_lona = v - $game_player.actor.morality_plus + 200
        $game_player.actor.recalculate_stats
        },
      order:  60
    )
  end
end
