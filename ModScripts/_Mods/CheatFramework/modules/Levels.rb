FrameworkModule = {
  name:       "Levels",
  key:        :levels,
  menu:       :LEVELS,
  order:      10,
  depends_on: []
}

module MenuFramework
  module SUBMENU
    #--------------------------------------------------------------------------
    # Character Editing Menu
    #--------------------------------------------------------------------------
    register_command(
      group:  :LONA,
      type:   :scene,
      key:    :edit_level,
      label:  "modules/character:commands/levels",
      menu1:  "menu:window_help/character1",
      name:   "CheatMenuLevels",
      dict:   :LEVELS,
      order:  40
    )

    #--------------------------------------------------------------------------
    # Levels
    #--------------------------------------------------------------------------
    register_command(
      group:  :LEVELS,
      type:   :edit_num,
      key:    "Max Level",
      label:  "modules/character:commands/levels/max_level",
      state:  "$cheat_variables_max_level",
      hide:   -> { $framework.roleplay_mod? },
      gdef:   99,
      min:    50, # Allowed below the 99 default.
      max:    999,
      order:  10
    )
    register_command(
      group:  :LEVELS,
      type:   :edit_num,
      key:    "Level",
      label:  "modules/character:commands/levels/level",
      state:  "$game_player.actor.level",
      min:    1,
      max:    -> {$game_player.actor.max_level},
      help1:  "modules/character:command_help/lvl",
      action: ->(v) { 
                      $game_player.actor.change_level(v, true) 
                      $game_player.actor.trait_point = FrameworkUtils.calc_trait_points(false) if !$framework.roleplay_mod? 
                    },
      order:  20
    )
    register_command(
      group:  :LEVELS,
      type:   :edit_num,
      key:    "Traits Per Level",
      label:  "modules/character:commands/levels/traits_per_level",
      state:  "$cheat_variables_traits_per_level",
      hide:   -> { $framework.roleplay_mod? },
      gdef:   1,
      help1:  "modules/character:command_help/tpl1",
      help2:  "modules/character:command_help/lvl",
      min:    1,
      max:    20,
      action: ->(v) { $cheat_variables_traits_per_level = v
                      $framework.ini.write_global("Traits Per Level", v)
                      $game_player.actor.trait_point = FrameworkUtils.calc_trait_points(false)
                    },
      order:  30
    )
    register_command(
      group:  :LEVELS,
      type:   :edit_num,
      key:    "Max Traits",
      label:  "modules/character:commands/traits/max_traits",
      state:  "$cheat_variables_max_stat",
      gdef:   99,
      min:    99,
      max:    999,
      restart: true, # baked into LONA_STAT_DEFAULT at load time below - LonaActorStat.new only ever reads that snapshot
      order:  40
    )
    register_command(
      group:  :LEVELS,
      type:   :edit_num,
      key:    "Trait Points",
      label:  "modules/character:commands/traits/trait_points",
      state:  "$game_player.actor.trait_point",
      help1:  -> {         
        to = FrameworkUtils.calc_trait_points(false)
        text = "#{$framework.txt("modules/character:command_help/tp1")}: #{to}"
        },
      help2:  -> {
        ba,sk,tr,to = FrameworkUtils.calc_trait_points(true)
        text = "#{ba}(#{$framework.txt("modules/character:command_help/tp2")}) - #{sk}(#{$framework.txt("modules/character:command_help/tp3")}) - #{tr}(#{$framework.txt("modules/character:command_help/tp4")}"
        },
      min:    0,
      max:    9999,
      action: ->(v) { $game_player.actor.trait_point = v },
      order:  50
    )
    register_command(
      group:  :LEVELS,
      type:   :scene,
      key:    :edit_trait,
      label:  "modules/character:commands/traits",
      menu1:  "menu:window_help/character1",
      name:   "CheatMenuTraits",
      dict:   :TRAITS,
      order:  60
    )


    #--------------------------------------------------------------------------
    # Traits
    #--------------------------------------------------------------------------
    register_command(
      group:  :TRAITS,
      type:   :edit_num,
      key:    "Combat",
      label:  "modules/character:commands/traits/combat",
      state:  "$game_player.actor.combat_trait.to_i",
      min:    0,
      max:    -> {$cheat_variables_max_stat},
      action: ->(v) { FrameworkUtils.edit_trait("combat", v) },
      order:  70
    )
    register_command(
      group:  :TRAITS,
      type:   :edit_num,
      key:    "Scout",
      label:  "modules/character:commands/traits/scoutcraft",
      state:  "$game_player.actor.scoutcraft_trait.to_i",
      min:    0,
      max:    -> {$cheat_variables_max_stat},
      action: ->(v) { FrameworkUtils.edit_trait("scoutcraft", v) },
      order:  80
    )
    register_command(
      group:  :TRAITS,
      type:   :edit_num,
      key:    "Wisdom",
      label:  "modules/character:commands/traits/wisdom",
      state:  "$game_player.actor.wisdom_trait.to_i",
      min:    0,
      max:    -> {$cheat_variables_max_stat},
      action: ->(v) { FrameworkUtils.edit_trait("wisdom", v) },
      order:  90
    )
    register_command(
      group:  :TRAITS,
      type:   :edit_num,
      key:    "Survival",
      label:  "modules/character:commands/traits/survival",
      state:  "$game_player.actor.survival_trait.to_i",
      min:    0,
      max:    -> {$cheat_variables_max_stat},
      action: ->(v) { FrameworkUtils.edit_trait("survival", v) },
      order:  100
    )
    register_command(
      group:  :TRAITS,
      type:   :edit_num,
      key:    "Constitution",
      label:  "modules/character:commands/traits/constitution",
      state:  "$game_player.actor.constitution_trait.to_i",
      min:    0,
      max:    -> {$cheat_variables_max_stat},
      action: ->(v) { FrameworkUtils.edit_trait("constitution", v) },
      order:  110
    )
    register_command(
      group:  :TRAITS,
      type:   :action,
      key:    "Reset Traits",
      label:  "modules/character:commands/traits/reset",
      action: -> { FrameworkUtils.reset_all_traits },
      help1:  "modules/character:command_help/reset1",
      help2:  "modules/character:command_help/reset2",
      order:  120
    )
  end
end

  
module FrameworkUtils
  def self.update_variables
    $game_player.actor.recalculate_stats #Attempts to use existing function
  end

  def self.edit_trait(skill, new_value)
    actor = $game_player.actor
    current = actor.send("#{skill}_trait")
    change  = new_value.to_i - current.to_i
    actor.send("#{skill}_trait=", new_value.to_i)
    actor.trait_point += -change
    actor.recalculate_stats
  end

  def self.calc_trait_skills
    actor = $game_player.actor
    traits = System_Settings::TRAIT::LIST.flatten
    blank = System_Settings::TRAIT::BLANK_ID
    # Get all valid trait names (no tmp, no blanks)
    valid_traits = traits.reject { |t| t.nil? || t == blank || t == "tmp" }.uniq
    # Count how many the actor has
    match_count = valid_traits.count { |t| actor.stat[t] == 1 }
  end

  def self.calc_trait_points(math=false)
    actor = $game_player.actor
    base = actor.level * $cheat_variables_traits_per_level
    skills = calc_trait_skills
    traits = actor.combat_trait + actor.scoutcraft_trait + actor.wisdom_trait +
            actor.survival_trait + actor.constitution_trait
    total = base - skills - traits
    return base.to_i,skills.to_i,traits.to_i,total.to_i if math
    total
  end

  def self.reset_all_traits
    actor = $game_player.actor
    reset_trait_skills
    %w[combat scoutcraft wisdom survival constitution].each do |stat|
      actor.send("#{stat}_trait=", 0)
    end
    actor.recalculate_stats
    actor.trait_point = calc_trait_points
  end
  
  def self.reset_trait_skills
    actor = $game_player.actor
    traits = System_Settings::TRAIT::LIST.flatten
    blank  = System_Settings::TRAIT::BLANK_ID

    valid_traits = traits.reject { |t| t.nil? || t == blank || t == "tmp" }.uniq
      valid_traits.each do |t|
        FrameworkUtils.custom_state_edit(t,-1) if actor.stat[t] != 0
    end
  end
end

# Overrides UI to allow trait assignment
class Game_Actor < Game_Battler
  def basic_trait_addable?(tmpVal)
    tmpVal <= $cheat_variables_max_stat
  end
end

# Raises the caps LonaActorStat.new reads for max stats and traits.
class LonaActorStat < ActorStat
  def self.override_stat(max_val)
    [0, 0, max_val, max_val, 0, 0, 0]
  end

  # Define defaults for both core stats and traits
  %w[constitution survival wisdom combat scoutcraft
     constitution_trait survival_trait wisdom_trait combat_trait scoutcraft_trait].each do |stat|
    LONA_STAT_DEFAULT[stat] = [override_stat($cheat_variables_max_stat), 0]
  end
end

#--------------------------------------------------------------------------
# RolePlay-S Compatibility Overrides
#--------------------------------------------------------------------------
if $mod_manager.mods['RolePlayS'] && !$mod_manager.mods['RolePlayS'].enabled
  class Game_Actor < Game_Battler
    def max_level
        return $cheat_variables_max_level
    end

    # Sets experience to next level, level 99 is last on the table.
    def param_base(param_id)
      level_to_check = [[@level,99].min,0].max
      self.class.params[param_id, level_to_check]
    end
  end

  # Overrides how many traits are earned at level up.

  class Game_Actor < Game_Battler
    def level_up
      @level += 1
      @trait_point +=$cheat_variables_traits_per_level
      self.class.learnings.each do |learning|
        learn_skill(learning.skill_id) if learning.level == @level
      end
    end
  end
end