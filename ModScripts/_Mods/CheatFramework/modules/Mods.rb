FrameworkModule = {
  name:  "Other Mods",
  key:   :othermods,
  menu:  :OTHERMODS,
  order: 130
}

# Menu commands for optional companion mods: RolePlay-S, Lona Belly & Booba, Filter Visuals.
module MenuFramework
  module MENU
    # MAIN-menu rows don't support hide:, so the whole registration is gated instead.
    if $framework.roleplay_mod? || $framework.bellybooba_mod? || $framework.filter_visuals_mod?
      register_command(
        type:  :scene,
        label: "modules/mods:commands/othermods",
        name:  "CheatMenuOtherMods",
        order: 130
      )
    end
  end

  module SUBMENU
    #--------------------------------------------------------------------------
    # RolePlay-S
    #--------------------------------------------------------------------------
    if $framework.roleplay_mod?
      register_command(
        type:   :toggle,
        key:    "Infinite Mana",
        label:  "modules/mods:commands/roleplays/mana",
        state:  "$cheat_infinite_mana",
        hotkey: {key: "F4"},
        gdef:   false,
        order:  30
      )
      register_command(
        type:   :edit_num,
        key:    "Mana Rage Max",
        label:  "modules/mods:commands/roleplays/mana_rage_max",
        state:  "$game_player.actor.mana_rage_max",
        min:    40,
        max:    5000,
        action: ->(v) { FrameworkUtils.apply_mana_rage_max(v) },
        order:  40
      )
      register_command(
        type:   :edit_num,
        key:    "Mana Rage",
        label:  "modules/mods:commands/roleplays/mana_rage",
        state:  "$game_player.actor.mana_rage",
        min:    -20,
        max:    -> { $game_player.actor.mana_rage_max },
        action: ->(v) { $game_player.actor.mana_rage = v },
        order:  50
      )
      register_command(
        type:   :toggle,
        key:    "Infinite Saves",
        label:  "modules/mods:commands/roleplays/saves",
        state:  "$cheat_infinite_saves",
        gdef:   false,
        order:  60
      )
    end

    #--------------------------------------------------------------------------
    # Lona Belly & Booba
    #--------------------------------------------------------------------------
    register_command(
      type:   :toggle,
      key:    "Booba Cosmetic Mode",
      label:  "modules/mods:commands/othermods/booba_cosmetic",
      state:  "$lona_booba_cosmetic_mode",
      hide:   -> { !$framework.bellybooba_mod? },
      order:  70,
      action: -> {
        $lona_booba_cosmetic_mode = !$lona_booba_cosmetic_mode
        BoobaMod.write
        BoobaMod.refresh_portrait
      }
    )
    register_command(
      type:   :toggle,
      key:    "Booba Old Nipples",
      label:  "modules/mods:commands/othermods/booba_oldnipples",
      state:  "$lona_old_nipples_mode",
      hide:   -> { !$framework.bellybooba_mod? },
      order:  80,
      action: -> {
        $lona_old_nipples_mode = !$lona_old_nipples_mode
        BoobaMod.write
        BoobaMod.refresh_portrait
      }
    )

    #--------------------------------------------------------------------------
    # Filter Visuals
    #--------------------------------------------------------------------------
    # whitecum/events need a restart to take effect (patch installed once at boot).
    # The rest re-check $filter_visuals live on every bitmap load.
    FILTER_VISUAL_TOGGLES = [
      { key: :whitecum, order: 90,  restart: true },
      { key: :events,   order: 100,  restart: true },
      { key: :melanin,  order: 110 },
      { key: :pubes,    order: 120 },
      { key: :dirt,     order: 130 },
      { key: :wounds,   order: 140 },
      { key: :bleeding, order: 150 },
    ]

    FILTER_VISUAL_TOGGLES.each do |cfg|
      register_command(
        type:    :toggle,
        key:     "Filter Visuals #{cfg[:key]}",
        label:   "modules/mods:commands/othermods/filter_#{cfg[:key]}",
        state:   "$filter_visuals[:#{cfg[:key]}]",
        hide:    -> { !$framework.filter_visuals_mod? },
        restart: cfg[:restart],
        order:   cfg[:order],
        action:  -> {
          $filter_visuals[cfg[:key]] = !$filter_visuals[cfg[:key]]
          FilterVisuals.write
        }
      )
    end
  end
end

#--------------------------------------------------------------------------
# RolePlay-S: Save System
#--------------------------------------------------------------------------
if $framework.roleplay_mod?
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
  # RolePlay-S: Per-Tick Effects
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
end
