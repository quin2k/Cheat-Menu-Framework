FrameworkModule = {
  name:       "NPC Fixes",
  key:        :npc_fixes,
  menu:       :NPC
}

#--------------------------------------------------------------------------
# Menu Commands
#--------------------------------------------------------------------------
module MenuFramework
  module SUBMENU
    # Shared Disable / Off / On list, matching Fixes.rb's FIX_TOGGLE_LIST.
    FIX_TOGGLE_LIST = [
      { key: -1, label: "[#{$framework.txt("menu:cheat_toggle/disable")}]" },
      { key:  0, label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
      { key:  1, label: "[#{$framework.txt("menu:cheat_toggle/on")}]" },
    ]
    register_command(
      type:   :edit_list,
      key:    "Friendly Fire",
      label:  "modules/others:commands/friendlyfire",
      help1:  "modules/others:command_help/friendlyfire1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_friendly_fire_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  30
    )
    register_command(
      type:   :edit_list,
      key:    "Endless Contracts",
      label:  "modules/others:commands/endlesscontracts",
      help1:  "modules/others:command_help/endlesscontracts1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_infinite_companion",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  40
    )
    register_command(
      type:   :edit_list,
      key:    "Prevent Death",
      label:  "modules/others:commands/immortal",
      help1:  "modules/others:command_help/immortal1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_companion_immortal",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  45
    )
    register_command(
      type:   :edit_list,
      key:    "Irresistible",
      label:  "modules/others:commands/irresistible",
      help1:  "modules/others:command_help/irresistible1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_irresistible_companions",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  46
    )
  end
end

#--------------------------------------------------------------------------
# Friendly Fire Fix
#--------------------------------------------------------------------------
if $cheat_friendly_fire_fix >= 0
  module Battle_System
    alias_method :skill_result_check_ignore_tgt_nofriendlyfire, :skill_result_check_ignore_tgt

    def skill_result_check_ignore_tgt(character, skill)
      return skill_result_check_ignore_tgt_nofriendlyfire(character, skill) unless $cheat_friendly_fire_fix == 1
      return true if block_friendly_fire(self, character, skill)
      skill_result_check_ignore_tgt_nofriendlyfire(character, skill)
    end

    def block_friendly_fire(user, target, skill)
      attacker = nil
      targeted = nil

      #Indirect attacks such as magic, arrows
      if (user.class == Game_PorjectileCharacter || user.class == Game_DestroyableObject)
        if user.event && user.event.summon_data && user.event.summon_data[:user]
          source = user.event.summon_data[:user]

          if source && source == $game_player
            attacker = "Lona"
          elsif source.respond_to?(:npc) && source.npc && source.npc.master == $game_player
            attacker = "Ally"
          elsif source.respond_to?(:npc) && source.npc && source.npc.master &&
                source.npc.master.respond_to?(:npc) && source.npc.master.npc &&
                source.npc.master.npc.master == $game_player
            attacker = "AllySummon"
          end
        end

      else
        #Direct attacks such as melee
        if user == $game_player.actor
          attacker = "Lona"
        elsif user.respond_to?(:master) && user.master == $game_player
          attacker = "Ally"
        elsif user.respond_to?(:master) && user.master && user.master.respond_to?(:npc) &&
              user.master.npc && user.master.npc.master == $game_player
          attacker = "AllySummon"
        end
      end
      if target == $game_player
        targeted = "Lona"
      elsif target.respond_to?(:actor) && target.actor && target.actor.master == $game_player
        targeted = "Ally"
      elsif target.respond_to?(:actor) && target.actor && target.actor.master &&
            target.actor.master.respond_to?(:npc) && target.actor.master.npc &&
            target.actor.master.npc.master == $game_player
        targeted = "AllySummon"
      end

      #Support magic/skill or target/attacker isn't an ally
      return false if skill && skill.respond_to?(:is_support) && skill.is_support
      return false unless attacker && targeted
      true
    end
  end
end

#--------------------------------------------------------------------------
# Endless Contracts
#--------------------------------------------------------------------------
if $cheat_infinite_companion >= 0
  # Expiry checks only act when these dates aren't nil, so nil stops auto-leaving.
  class Game_Player
    alias_method :cf_infinite_companion_record_companion_front_date, :record_companion_front_date
    alias_method :cf_infinite_companion_record_companion_back_date,  :record_companion_back_date
    alias_method :cf_infinite_companion_record_companion_ext_date,   :record_companion_ext_date

    def record_companion_front_date
      return cf_infinite_companion_record_companion_front_date unless $cheat_infinite_companion == 1
      nil
    end
    def record_companion_back_date
      return cf_infinite_companion_record_companion_back_date unless $cheat_infinite_companion == 1
      nil
    end
    def record_companion_ext_date
      return cf_infinite_companion_record_companion_ext_date unless $cheat_infinite_companion == 1
      nil
    end
  end
end

#--------------------------------------------------------------------------
# Companion Incapacitation (shared helper used by both toggles below)
#--------------------------------------------------------------------------
class Game_NonPlayerCharacter
  # True while a companion is incapacitated. Restores its receiver_type once healed above 1 HP.
  def cf_incapacitated_companion_target?(target)
    victim = target.respond_to?(:actor) ? target.actor : nil
    return false unless victim.is_a?(Game_NonPlayerCharacter) && victim.instance_variable_get(:@cheat_incapacitated)
    if victim.stat.get_stat("health") > 1
      victim.instance_variable_set(:@cheat_incapacitated, false)
      original = victim.instance_variable_get(:@cheat_original_receiver_type)
      if original
        victim.receiver_type = original
        victim.instance_variable_set(:@cheat_original_receiver_type, nil)
      end
    end
    victim.instance_variable_get(:@cheat_incapacitated)
  end
end

#--------------------------------------------------------------------------
# Prevent Death
#--------------------------------------------------------------------------
if $cheat_companion_immortal >= 0
  # A companion (@master == $game_player) survives lethal damage at 1 HP with sta forced to 0,
  # triggering Fatigue/crawl mode instead of death, and can't be killer/assaulter-targeted while down.
  class Game_NonPlayerCharacter
    alias_method :cf_companion_immortal_process_death, :process_death
    def process_death
      return cf_companion_immortal_process_death unless $cheat_companion_immortal == 1
      return cf_companion_immortal_process_death unless @master == $game_player
      @cheat_incapacitated = true
      @stat.set_stat("health", 1) if @stat.get_stat("health") <= 0
      @stat.set_stat("sta", 0)
      @target = nil
      set_alert_level(0)
    end

    alias_method :cf_companion_immortal_process_ai_state, :process_ai_state
    def process_ai_state(target, distance, signal, sensor_type)
      cf_companion_immortal_process_ai_state(target, distance, signal, sensor_type)
      return unless $cheat_companion_immortal == 1
      return unless [:killer, :assaulter].include?(@ai_state)
      return unless cf_incapacitated_companion_target?(target)
      @ai_state = fucker?(target, friendly?(target)) ? :fucker : :none
      set_ai_state_balloon
    end
  end

  # Keeps Lona's health from reaching 0 (death) too - her stamina/overfatigue mechanic is untouched.
  module FrameworkUtils
    def self.apply_lona_death_lock
      return unless $cheat_companion_immortal == 1 && ingame?
      actor = $game_player.actor
      actor.health = 1 if actor.health <= 0
    end
  end

  class CheatFramework
    alias_method :hotkey_trigger_prevent_death_lona, :hotkey_trigger
    def hotkey_trigger
      hotkey_trigger_prevent_death_lona
      FrameworkUtils.apply_lona_death_lock
    end
  end
end

#--------------------------------------------------------------------------
# Irresistible
#--------------------------------------------------------------------------
if $cheat_irresistible_companions >= 0
  # Covers a companion Prevent Death has incapacitated, and Lona herself once her stamina hits 0.
  class Game_NonPlayerCharacter
    # Randomizes receiver_type from 3 (always struggles) to 1/2/4 (softer) while incapacitated.
    alias_method :cf_irresistible_process_death, :process_death
    def process_death
      cf_irresistible_process_death
      return unless $cheat_irresistible_companions == 1 && @master == $game_player && @cheat_incapacitated
      return unless @receiver_type == 3
      @cheat_original_receiver_type = @receiver_type
      @receiver_type = [1, 2, 4].sample
    end

    # Forces fucker to true for an incapacitated companion or a 0-stamina Lona, bypassing aggro/stat checks.
    alias_method :cf_irresistible_fucker?, :fucker?
    def fucker?(target, friendly)
      if $cheat_irresistible_companions == 1
        return true if cf_incapacitated_companion_target?(target)
        return true if target == $game_player && $game_player.actor.sta <= 0
      end
      cf_irresistible_fucker?(target, friendly)
    end

    # Re-derives killer/assaulter against a 0-stamina Lona as fucker-or-none.
    alias_method :cf_irresistible_process_ai_state, :process_ai_state
    def process_ai_state(target, distance, signal, sensor_type)
      cf_irresistible_process_ai_state(target, distance, signal, sensor_type)
      return unless $cheat_irresistible_companions == 1
      return unless [:killer, :assaulter].include?(@ai_state)
      return unless target == $game_player && $game_player.actor.sta <= 0
      @ai_state = fucker?(target, friendly?(target)) ? :fucker : :none
      set_ai_state_balloon
    end
  end
end
