FrameworkModule = {
  name:       "RolePlayS",
  key:        :roleplays,
  menu:       :ROLEPLAY,
  order:      120
}

if $framework.roleplay_mod?

  #--------------------------------------------------------------------------
  # Menu Commands
  #--------------------------------------------------------------------------
  MenuFramework::MENU.register_command(
    type:   :scene,
    dict:   :ROLEPLAY,
    key:    :roleplays,
    label:  "modules/others:commands/roleplays",
    name:   "RolePlayS",
    order:  100
  )

  MenuFramework::SUBMENU.register_command(
    group:  :ROLEPLAY,
    type:   :toggle,
    key:    "Infinite Mana",
    label:  "modules/others:commands/roleplays/mana",
    state:  "$cheat_infinite_mana",
    hotkey: {key: "F4"},
    gdef:   false,
    order:  10
  )
  MenuFramework::SUBMENU.register_command(
    group:  :ROLEPLAY,
    type:   :edit_num,
    key:    "Mana Rage Max",
    label:  "modules/others:commands/roleplays/mana_rage_max",
    state:  "$game_player.actor.mana_rage_max",
    min:    20,
    max:    5000,
   action: ->(v) { FrameworkUtils.apply_mana_rage_max(v) },
    order:  20
  )
  MenuFramework::SUBMENU.register_command(
    group:  :ROLEPLAY,
    type:   :edit_num,
    key:    "Mana Rage",
    label:  "modules/others:commands/roleplays/mana_rage",
    state:  "$game_player.actor.mana_rage",
    min:    -20,
    max:    -> { $game_player.actor.mana_rage_max },
    action: ->(v) { $game_player.actor.mana_rage = v },
    order:  30
  )
  MenuFramework::SUBMENU.register_command(
    group:  :ROLEPLAY,
    type:   :toggle,
    key:    "Infinite Saves",
    label:  "modules/others:commands/roleplays/saves",
    state:  "$cheat_infinite_saves",
    gdef:   false,
    order:  40
  )

  #--------------------------------------------------------------------------
  # Save System
  #--------------------------------------------------------------------------
  # Overrides the save system to prevent updating save counts.
  class Menu_System
    alias cheat_save_command_handler save_command_handler
    def save_command_handler
      if $cheat_infinite_saves
        return SndLib.sys_buzzer if $story_stats["MenuSysSavegameOff"] >= 1
        return SndLib.sys_buzzer if $story_stats["Setup_Hardcore"] >= 2
        SceneManager.goto(Scene_Save)
      else
        cheat_save_command_handler
      end
    end
  end

  # Upon game load, reset the save count if infinite saves is enabled.
  class Scene_Load < Scene_File
    alias cheat_on_load_success on_load_success
    def on_load_success
      cheat_on_load_success
      if $cheat_infinite_saves && $story_stats["YouCanSaveButOnlyOnce"] == 0
        $story_stats["YouCanSaveButOnlyOnce"] = 1
      end
    end
  end

  #--------------------------------------------------------------------------
  # Per-Tick Effects
  #--------------------------------------------------------------------------
  # Hooks the framework's hotkey tick to also apply RolePlayS's live effects.
  class CheatFramework
    alias_method :hotkey_trigger_ROLEPLAYS, :hotkey_trigger
    def hotkey_trigger
      hotkey_trigger_ROLEPLAYS
      FrameworkUtils.apply_roleplays_cheats
    end
  end

  module FrameworkUtils
    def self.apply_roleplays_cheats
      return unless self.ingame?
      actor = $game_player.actor
      return unless actor

      if $cheat_infinite_mana; mana_to_max end
    end

    def self.mana_to_max
      actor = $game_player.actor
      max_mp = actor.battle_stat.get_stat("mp", ActorStat::MAX_STAT)
      actor.mp = max_mp if actor.mp < max_mp
    end

    def self.apply_mana_rage_max(v)
      actor = $game_player.actor
      return unless actor && actor.actStat
      stat = actor.actStat

      stat.set_stat("mana_rage", v, ActorStat::MAX_TRUE)
      stat.set_stat("mana_rage", v, ActorStat::MAX_STAT)

      stat.check_current_stat("mana_rage")
    end

  end

end #if RolePlayS enabled
