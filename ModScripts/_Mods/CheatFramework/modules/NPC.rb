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
    register_command(
      type:   :edit_list,
      key:    "Beast Fix",
      label:  "modules/others:commands/beastfix",
      help1:  "modules/others:command_help/beastfix1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_beast_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: true,
      order:  47
    )
    register_command(
      type:   :edit_list,
      key:    "Companion Rape",
      label:  "modules/others:commands/companionrape",
      help1:  "modules/others:command_help/companionrape1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_companion_rape",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  48
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

  # Applies the health floor inside determine_death so it holds against hits landing between ticks.
  class Game_Actor
    alias_method :cf_prevent_death_determine_death, :determine_death
    def determine_death
      FrameworkUtils.apply_lona_death_lock if $game_player && self == $game_player.actor
      cf_prevent_death_determine_death
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

#--------------------------------------------------------------------------
# Beast Fix
#--------------------------------------------------------------------------
if $cheat_beast_fix >= 0
  # WildBoar/WildDog/WildHorse ship reachable; CompDoggy/CompHorseCarry ship hard-disabled
  # (sex==65535, never true) - companions get a higher weak threshold than wild animals.
  BEAST_FIX_WEAK_THRESHOLD = {
    "WildBoar"       => 40,
    "WildDog"        => 40,
    "WildHorse"      => 80,
    "CompDoggy"      => 150,
    "CompHorseCarry" => 150,
  }

  BEAST_FIX_FUCKER_SKILLS = ["NpcFuckerMh", "NpcFuckerSh", "NpcFuckerGrab"]

  # chcg4's "Others" pose entries ship ~80px too high on y; only nudges a value still at the
  # exact broken default, so an upstream fix becomes a silent no-op instead of double-applying.
  BEAST_ALIGN_FIX = {
    "chcg4_EventMouth_Others" => {from: 38,  to: 118},
    "chcg4_EventAnal_Others"  => {from: 287, to: 367},
    "chcg4_EventVag_Others"   => {from: 262, to: 342},
  }

  class << DataManager
    alias_method :cf_beastfix_load_mod_database, :load_mod_database
    def load_mod_database
      cf_beastfix_load_mod_database
      return unless $cheat_beast_fix == 1
      BEAST_FIX_WEAK_THRESHOLD.each do |name, weak|
        npc = $data_npcs[name]
        npc.fucker_condition = {"weak" => [weak, ">"], "sex" => [0, "="]} if npc
      end
      # Gives CompDoggy the grab/sex skills so it attempts the grab like other beasts.
      doggy = $data_npcs["CompDoggy"]
      doggy.skills_fucker = BEAST_FIX_FUCKER_SKILLS if doggy
      parts = $data_lona_portrait && $data_lona_portrait[1]["chcg4"]
      return unless parts
      parts.each do |part|
        fix = BEAST_ALIGN_FIX[part.part_name]
        part.posY = fix[:to] if fix && part.posY == fix[:from]
      end
    end
  end

  # WildHorse/WildDog/CompDoggy's template graphic uses a chartype with no real sex-pose data,
  # so grab() never reaches :sex - remap each to a working one, reusing existing matching art.
  class Game_Event
    alias_method :cf_beastfix_setup_charset_page_settings, :setup_charset_page_settings
    def setup_charset_page_settings
      if $cheat_beast_fix == 1 && @event && @page
        case @event.name
        when "WildHorse"
          if @page.graphic.character_name == "-char-Creatures80C01"
            @page.graphic.character_name = "-char-Creatures76MF01"
            @page.graphic.character_index = 1
            @page.graphic.pattern = 0
          end
        when "WildDog"
          if @page.graphic.character_name == "-char-Creatures48C01"
            @page.graphic.character_name = "-char-CreaturesDOG76M"
            @page.graphic.character_index = 0
            @page.graphic.pattern = 2
          end
        when "CompDoggy"
          if @page.graphic.character_name == "-char-Creatures48C01"
            @page.graphic.character_name = "-char-CreaturesDOG76M"
            @page.graphic.character_index = 1
            @page.graphic.pattern = 0
          end
        end
      end
      cf_beastfix_setup_charset_page_settings
    end
  end
end

#--------------------------------------------------------------------------
# Companion Rape
#--------------------------------------------------------------------------
if $cheat_companion_rape >= 0
  # Lets a companion :fucker-target its own team instead of being filtered out as friendly -
  # patches both independent checks. Needs Beast Fix (or similar) for the condition to be reachable.
  CF_SENSOR_IFF_BYPASS_NAMES = []

  class Game_NonPlayerCharacter
    # Escape hatch for granting the bypass to something that isn't a recruited companion
    # (@master == $game_player) yet, e.g. an NPC still under test.
    def cf_companion_rape_ignore_iff?
      @master == $game_player || CF_SENSOR_IFF_BYPASS_NAMES.include?(@npc_name)
    end

    alias_method :cf_companion_rape_process_target, :process_target
    def process_target(target, distance, signal, sensor_type)
      return cf_companion_rape_process_target(target, distance, signal, sensor_type) unless $cheat_companion_rape == 1
      return if @event.chk_skill_eff_reserved
      return if !target.actor
      return process_target_lost if target.deleted? || (!$game_map.events.value?(target) && target != $game_player)
      return process_target_lost if target && target.actor.action_state == :death
      is_friend = friendly?(target)
      return if is_friend && !fucker?(target, is_friend)
      process_ai_state(target, distance, signal, sensor_type)
      process_alert_level(target, distance, signal, sensor_type) if non_battle? && @ai_state != :none
      return unless @alert_level == 2
      @targetLock_HP = 10
      case @ai_state
      when :fucker; process_fucker(target, distance, signal, sensor_type)
      when :killer; process_killer(target, distance, signal, sensor_type)
      when :assaulter; process_assulter(target, distance, signal, sensor_type)
      when :flee; process_flee(target, distance, signal, sensor_type)
      else set_alert_level(0) if @fraction_mode == 1 || @fraction_mode == 4 || @fraction_mode == 2
      end
    end
  end

  class Sensors::Basic_Sensor
    class << self
      alias_method :cf_companion_rape_signal_IgnoreCheck, :signal_IgnoreCheck
      def signal_IgnoreCheck(character, target, track_mode = false)
        return cf_companion_rape_signal_IgnoreCheck(character, target, track_mode) unless $cheat_companion_rape == 1
        return true if !target.is_actor?
        return true if same_char?(target, character)
        return true if ignore_dead? && target.npc.action_state == :death
        return true if ignore_obj_chk(character, target)
        return true if use_iff? && !character.actor.cf_companion_rape_ignore_iff? && character.actor.friendly?(target)
        return true if friendly_only? && !character.actor.friendly?(target)
      end
    end
  end
end
