FrameworkModule = {
  name:       "Appearance", #Scene/Window names would be Window_CheatMenuEdit_Lona.
  key:        :appearance, #Menu key, also used to label source module.
  menu:       :APPEARANCE, #Dictionary / Group key.
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
      key:    :edit_appearance,
      label:  "modules/character:commands/appearance",
      menu1:  "menu:window_help/character1",
      name:   "CheatMenuAppearance",
      dict:   :APPEARANCE,
      order:  50
    )

    #------------------------------------------
    # Appearance 
    #------------------------------------------
    register_command(
      group:  :APPEARANCE,
      type:   :edit_list,
      key:    "Hair Color",
      label:  "modules/character:commands/appearance/hair_color",
      state:  "$game_player.actor.record_HairColor",
      list:   [
                { key: 0, label: "[#{$framework.txt("modules/character:commands/appearance/hair_color/0")}]" },
                { key: 1, label: "[#{$framework.txt("modules/character:commands/appearance/hair_color/1")}]" },
                { key: 2, label: "[#{$framework.txt("modules/character:commands/appearance/hair_color/2")}]" },
                { key: 3, label: "[#{$framework.txt("modules/character:commands/appearance/hair_color/3")}]" },
                { key: 4, label: "[#{$framework.txt("modules/character:commands/appearance/hair_color/4")}]" },
                { key: 5, label: "[#{$framework.txt("modules/character:commands/appearance/hair_color/5")}]" }
              ],
      action: ->(v) { $game_player.actor.record_HairColor = v; $game_player.refresh_chs },
      order:  30
    )
    register_command(
      group:  :PRIMARY,
      type:   :edit_num,
      key:    "Dirt",
      label:  "modules/character:commands/appearance/dirt",
      state:  "$game_player.actor.dirt.to_i",
      enable: -> { $game_player.actor.actStat.get_stat('dirt', 3) != 0 && !$cheat_autoclean },
      min:    0,
      max:    255,
      action: ->(v) { $game_player.actor.dirt = v },
      order:  10
    )
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Disable Dirt",
      label:  "modules/character:toggle/dirt",
      state:  "$game_player.actor.actStat.get_stat('dirt', 3) == 0",
      help1:  "modules/character:command_help/dirt",
      action: -> {
                  if $game_player.actor.actStat.get_stat('dirt', 3) == 0
                    $game_player.actor.actStat.set_stat('dirt', 255, 3)
                  else
                    $game_player.actor.actStat.set_stat('dirt', 0, 3)
                  end
                  $game_player.actor.refresh
    })
    register_command(
      group:  :APPEARANCE,
      type:   :edit_num,
      key:    "Freckles",
      label:  "modules/character:commands/appearance/freckles",
      state:  "$game_player.actor.stat['Freckle']",
      min:    0,
      max:    1,
      action: ->(v) { FrameworkUtils.custom_state_edit("Freckle", v) }
      )
    register_command(
      group:  :APPEARANCE,
      type:   :edit_num,
      key:    "PubicHairVag",
      label:  "modules/character:commands/appearance/vpubes",
      state:  "$game_player.actor.stat['PubicHairVag']",
      help1:  "modules/character:command_help/pubes1",
      min:    0,
      max:    4,
      action: ->(v) { FrameworkUtils.custom_state_edit("PubicHairVag", v) }
      )
    register_command(
      group:  :APPEARANCE,
      type:   :edit_num,
      key:    "PubicHairAnal",
      label:  "modules/character:commands/appearance/apubes",
      state:  "$game_player.actor.stat['PubicHairAnal']",
      help1:  "modules/character:command_help/pubes1",
      min:    0,
      max:    4,
      action: ->(v) { FrameworkUtils.custom_state_edit("PubicHairAnal", v) }
      )
    register_command(
      group:  :APPEARANCE,
      type:   :edit_num,
      key:    "PubicHairVagGrowth",
      label:  "modules/character:commands/appearance/vpubegrowth",
      state:  "$game_player.actor.pubicHair_Vag_GrowRate",
      hide:   -> { $game_player.actor.stat['PubicHairVag'] == 0 },
      help1:  "modules/character:command_help/pubegrowth1",
      help2:  "modules/character:command_help/pubegrowth2",
      min:    1,
      max:    365,
      action: ->(v) { $game_player.actor.pubicHair_Vag_GrowRate = v }
      )
    register_command(
      group:  :APPEARANCE,
      type:   :edit_num,
      key:    "PubicHairAnalGrowth",
      label:  "modules/character:commands/appearance/apubegrowth",
      state:  "$game_player.actor.pubicHair_Anal_GrowRate",
      hide:   -> { $game_player.actor.stat['PubicHairAnal'] == 0 },
      help1:  "modules/character:command_help/pubegrowth1",
      help2:  "modules/character:command_help/pubegrowth2",
      min:    1,
      max:    365,
      action: ->(v) { $game_player.actor.pubicHair_Anal_GrowRate = v }
      )
      register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Auto Bandage", #should be unique
      label:  "modules/character:toggle/autobandage",
      help1:  "modules/character:command_help/autobandage",
      state:  "$cheat_autobandage", #toggle variable
      hotkey: { key: "F4", sound: :sound_equip_armor},
      global: false
    )
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Auto Clean Outside", #should be unique
      label:  "modules/character:toggle/autocleanout",
      help1:  "modules/character:command_help/autocleanout",
      state:  "$cheat_autoclean_out", #toggle variable
      hotkey: { key: "F4", sound: :sound_WaterSpla},
      global: false
    )
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Auto Clean Inside", #should be unique
      label:  "modules/character:toggle/autocleanin",
      help1:  "modules/character:command_help/autocleanin",
      state:  "$cheat_autoclean_in", #toggle variable
      hotkey: { key: "F4", sound: :sound_WaterSpla},
      global: false
    )
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Auto Cure", #should be unique
      label:  "modules/character:toggle/autocure",
      help1:  "modules/character:command_help/autocure",
      state:  "$cheat_autocure", #toggle variable
      hotkey: { key: "F4", sound: :buff_life},
      global: false
    )
  end
end

# Uses a slower trigger (~3 seconds) as wounds, etc. aren't as dangerous/frequent
class CheatFramework
  alias_method :slow_trigger_MODULE_AUTOSTATE, :slow_trigger
  def slow_trigger
    slow_trigger_MODULE_AUTOSTATE
    FrameworkUtils.apply_auto_states if FrameworkUtils.ingame?
  end
end

module FrameworkUtils
  def self.apply_auto_states
    return unless self.ingame?
    actor = $game_player.actor
    return unless actor

    if $cheat_autobandage; autobandage end
    if $cheat_autoclean_out; autoclean_out end
    if $cheat_autoclean_in; autoclean_out end
    if $cheat_autocure; autocure end
  end

  def self.autobandage
    list = ["WoundHead", "WoundChest", "WoundCuff", "WoundSArm", "WoundMArm", "WoundCollar", "WoundBelly", "WoundGroin", "WoundSThigh", "WoundMThigh", "VaginalDamaged", "UrethralDamaged", "SphincterDamaged", "EffectBleedVag", "EffectBleedAnal"]
    mass_remove_state(list)
  end

  def self.autoclean_out
    list = ["CumsCreamPie", "CumsMoonPie", "CumsHead", "CumsTop", "CumsMid", "CumsBot", "CumsMouth", "SemenBursting", "EffectScat", "EffectBleedVag", "EffectBleedAnal"]
    mass_remove_state(list)
  end

  def self.autoclean_in
    actor = $game_player.actor
    actor.cumsMeters.each do |key, value|
      actor.healCums(key, value) if value > 0
    end
  end

  def self.autocure
    list = ["ParasitedMoonWorm", "ParasitedPotWorm", "AnalSeedBed", "BladderSeedBed", "ParasitedPolypWorm", "ParasitedHookWorm", "StomachSeedBed", "STD_Leukorrhea", "STD_WartAnal", "STD_WartVag", "STD_HerpesAnal", "STD_HerpesVag"]
    mass_remove_state(list)
  end

  def self.mass_remove_state(list)
    actor = $game_player.actor
    active_states = list.select { |id| actor.state_stack(id) >= 1 }
    active_states.each do |state|
      actor.remove_state(state)
    end
  end
end
