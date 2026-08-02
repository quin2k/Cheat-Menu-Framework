FrameworkModule = {
  name:       "Game Fixes",
  key:        :game_fixes,
  menu:       :FIXES #Group key.
}

#--------------------------------------------------------------------------
# Menu Commands
#--------------------------------------------------------------------------
module MenuFramework
  module MENU
    register_command(
      type: :scene,
      label: "modules/others:commands/fix",
      name: "CheatMenuGameFixes",
      order: 5
    )
  end

  module SUBMENU
    #--------------------------------------------------------------------------
    # Restart-Capable Fixes
    #--------------------------------------------------------------------------
    # Shared Disable / Off / On list for every fix below.
    FIX_TOGGLE_LIST = [
      { key: -1, label: "[#{$framework.txt("menu:cheat_toggle/disable")}]" },
      { key:  0, label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
      { key:  1, label: "[#{$framework.txt("menu:cheat_toggle/on")}]" },
    ]
    register_command(
      type:   :edit_list,
      key:    "Equip Anything",
      label:  "modules/others:commands/equip",
      help1:  "modules/others:command_help/equip1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_classless_society",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  30
    )
    register_command(
      type:   :edit_list,
      key:    "Stealth Fix",
      label:  "modules/others:commands/stealth",
      help1:  "modules/others:command_help/stealth1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_stealth_confirm_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   1,
      restart: -1,
      order:  60
    )
    register_command(
      type:   :edit_list,
      key:    "Fast Nap",
      label:  "modules/others:commands/fastnap",
      help1:  "modules/others:command_help/fastnap1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_fast_nap",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      hide:   -> { $framework.roleplay_mod? },
      order:  40
    )
    register_command(
      type:   :edit_list,
      key:    "Achievement Fix",
      label:  "modules/others:commands/achievementfix",
      help1:  "modules/others:command_help/achievementfix1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_difficulty_achievement_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   1,
      restart: -1,
      order:  70
    )

    #--------------------------------------------------------------------------
    # Misc
    #--------------------------------------------------------------------------
    register_command(
      type:   :toggle,
      key:    "Night Vision",
      label:  "modules/others:commands/nightvision",
      help1:  "modules/others:command_help/nightvision1",
      state:  "$cheat_night_vision",
      gdef:   false,
      order:  10,
      action: -> {
        $cheat_night_vision = !$cheat_night_vision
        $framework.ini.write_global("Night Vision", $cheat_night_vision)
        $game_map.shadows.cf_reapply_opacity if FrameworkUtils.ingame? && $game_map && $game_map.shadows
      }
    )
    register_command(
      type:   :toggle,
      key:    "Noclip",
      label:  "modules/others:commands/noclip",
      help1:  "modules/others:command_help/noclip1",
      state:  "$cheat_noclip",
      gdef:   false,
      order:  20
    )
    register_command(
      type:   :toggle,
      key:    "Forage Glow",
      label:  "modules/others:commands/forageglow",
      help1:  "modules/others:command_help/forageglow1",
      state:  "$cheat_forage_glow",
      gdef:   false,
      order:  25
    )
  end
end


#--------------------------------------------------------------------------
# Stealth Fix
#--------------------------------------------------------------------------
if $cheat_stealth_confirm_fix >= 0
  class Game_Player
    alias_method :cf_stealth_confirm_fix_update_nonmoving, :update_nonmoving

    def update_nonmoving(last_moving)
      return cf_stealth_confirm_fix_update_nonmoving(last_moving) unless $cheat_stealth_confirm_fix == 1
      return if $game_map.interpreter.running?
      if last_moving
        $game_party.on_player_walk
        return if check_touch_event
      end
      if inputToTriggerEvent? && movable? && !actor.lonaDeath?
        @pathfinding = false
        return if Input.skillKeyPressed?
        move_normal unless self.actor.stat["IntoShadow"] == 1
        return if check_action_event(chkItemsPick = true)
        SndLib.sys_trigger
      end
    end
  end
end


#--------------------------------------------------------------------------
# Equip Anything
#--------------------------------------------------------------------------
if $cheat_classless_society >= 0
  class Game_BattlerBase
    alias_method :cf_classless_society_equip_wtype_ok, :equip_wtype_ok?
    alias_method :cf_classless_society_equip_atype_ok, :equip_atype_ok?
    alias_method :cf_classless_society_wtype_sealed, :wtype_sealed?
    alias_method :cf_classless_society_atype_sealed, :atype_sealed?
    alias_method :cf_classless_society_usable_item_conditions_met, :usable_item_conditions_met?

    def equip_wtype_ok?(wtype_id)
      return cf_classless_society_equip_wtype_ok(wtype_id) unless $cheat_classless_society == 1
      # Allow equipping weapons no matter the type.
      true
    end
    def equip_atype_ok?(atype_id)
      return cf_classless_society_equip_atype_ok(atype_id) unless $cheat_classless_society == 1
      # Allow equipping armor no matter the type.
      true
    end
    def wtype_sealed?(wtype_id)
      return cf_classless_society_wtype_sealed(wtype_id) unless $cheat_classless_society == 1
      # equippable? checks this separately from equip_wtype_ok? - e.g. TrueDeepone's wtype_seal.
      false
    end
    def atype_sealed?(atype_id)
      return cf_classless_society_atype_sealed(atype_id) unless $cheat_classless_society == 1
      false
    end
    def usable_item_conditions_met?(item)
      return cf_classless_society_usable_item_conditions_met(item) unless $cheat_classless_society == 1
      # Allow weapon skills regardless of prerequisites
      return true if item.is_a?(RPG::Skill) && added_skills.include?(item.id)
      movable?
    end
  end

  class Game_Actor
    alias_method :cf_classless_society_equip_change_ok, :equip_change_ok?
    def equip_change_ok?(slot_id)
      return cf_classless_society_equip_change_ok(slot_id) unless $cheat_classless_society == 1
      resolved_slot = slot_id.is_a?(String) ? $data_system.equip_type_name[slot_id] : slot_id
      # Only bondage/cursed items - other fixed/sealed slots stay blocked.
      return true if equips[resolved_slot] && equips[resolved_slot].type_tag == "Bondage"
      cf_classless_society_equip_change_ok(slot_id)
    end
  end
end

#--------------------------------------------------------------------------
# Fast Nap
#--------------------------------------------------------------------------
if $cheat_fast_nap >= 0 && !$framework.roleplay_mod?
  # Ctrl+rest spends sat in 10-point chunks to heal 20-point chunks of stamina/health at once.
  # Skipped under RolePlay-S: it replaces this same method unaliased, so load order would decide the winner.
  class Game_Actor
    alias_method :cf_fast_nap_check_sat_heal_HealthSta, :check_sat_heal_HealthSta

    def check_sat_heal_HealthSta(tmpCost = 10)
      return cf_fast_nap_check_sat_heal_HealthSta(tmpCost) unless $cheat_fast_nap == 1 && Input.press?(:CTRL)

      staMax = battle_stat.get_stat("sta", 2)
      hpMax  = battle_stat.get_stat("health", 2)
      staVS  = (staMax - self.sta).abs
      hpVS   = $story_stats["Setup_Hardcore"] > 0 ? 0 : (hpMax - self.health).abs
      return cf_fast_nap_check_sat_heal_HealthSta(tmpCost) if self.sat < tmpCost || (staVS == 0 && hpVS == 0)

      staChunks = ((staMax - self.sta) / 20).to_i
      hpChunks  = ((hpMax - self.health) / 20).to_i
      satChunks = (self.sat / 10).to_i
      restoreSta = staChunks > 1
      restoreHp  = hpChunks > 1 && self.sta == staMax
      return cf_fast_nap_check_sat_heal_HealthSta(tmpCost) unless restoreSta || restoreHp

      fullSta = [staChunks, satChunks].min
      fullHp  = [hpChunks, satChunks].min
      self.sat -= restoreSta ? tmpCost * fullSta : tmpCost * fullHp

      satScore = tmpCost * 2
      if staVS != 0 && satScore > 0
        staInc = [staVS, satScore].min.to_i
        satScore -= staInc
        if restoreSta
          self.sta += staInc * fullSta
          SndLib.buff_life
        else
          self.sta += staInc
        end
      end
      if hpVS != 0 && satScore > 0
        hpInc = [hpVS, satScore].min.to_i
        if restoreHp
          self.health += hpInc * fullHp
          SndLib.buff_life
        else
          self.health += hpInc
        end
      end
      true
    end
  end
end

#--------------------------------------------------------------------------
# Night Vision
#--------------------------------------------------------------------------
# Shadow#set_opacity is the single choke point for all map darkness - halve
# whatever it's asked for while the toggle is on, restore it exactly on off.
class Shadow
  alias_method :cf_night_vision_set_opacity, :set_opacity

  def set_opacity(a, time = nil)
    @cf_true_opacity = a
    cf_night_vision_set_opacity($cheat_night_vision ? (a / 2) : a, time)
  end

  def cf_reapply_opacity
    true_opacity = @cf_true_opacity || @a
    cf_night_vision_set_opacity($cheat_night_vision ? (true_opacity / 2) : true_opacity, nil)
  end
end

#--------------------------------------------------------------------------
# Noclip
#--------------------------------------------------------------------------
# debug_through? already bypasses both terrain and NPC/event collision (see passable? in
# 33_Game_CharacterBase.rb) - normally only true in the RPG Maker editor's own test-play mode.
class Game_Player
  alias_method :cf_noclip_debug_through?, :debug_through?
  def debug_through?
    $cheat_noclip || cf_noclip_debug_through?
  end

  # handle_on_move_overmap is the single per-step choke point for overworld stamina drain, time
  # passage, and danger/encounter accumulation - skip it entirely while noclipping.
  alias_method :cf_noclip_handle_on_move_overmap, :handle_on_move_overmap
  def handle_on_move_overmap(use_ctrl = false)
    return if $cheat_noclip
    cf_noclip_handle_on_move_overmap(use_ctrl)
  end
end

#--------------------------------------------------------------------------
# Forage Glow
#--------------------------------------------------------------------------
# "Static*"-named events are the overworld forage nodes - tag them once (draw priority + blink),
# each starting on a random phase so a cluster doesn't blink in sync.
class Game_Event
  alias_method :cf_forage_glow_refresh, :refresh
  def refresh
    cf_forage_glow_refresh
    return if @cheat_forage_glow_checked
    @cheat_forage_glow_checked = true
    return unless $cheat_forage_glow
    return unless @event && @event.name.start_with?("Static")
    self.priority_type = 2
    @cheat_forage_glow_tagged = true
    @cheat_forage_glow_frame = rand(80)
  end

  alias_method :cf_forage_glow_update, :update
  def update
    cf_forage_glow_update
    return unless @cheat_forage_glow_tagged
    frame = (@cheat_forage_glow_frame += 1)
    lit = (frame % 80) < 20
    return if lit == @cheat_forage_glow_lit
    @cheat_forage_glow_lit = lit
    self.tone = lit ? Tone.new(120, 120, 60, 0) : Tone.new(0, 0, 0, 0)
  end
end

#--------------------------------------------------------------------------
# Achievement Fix
#--------------------------------------------------------------------------
if $cheat_difficulty_achievement_fix >= 0
  module GIM_ADDON
    alias_method :cf_achievement_fix_achCheckDate, :achCheckDate

    # Grants Hell and Doom achievement tiers independently for each date.
    def achCheckDate
      return cf_achievement_fix_achCheckDate unless $cheat_difficulty_achievement_fix == 1
      return if $story_stats["Setup_HardcoreAmt"] != [1772,3,1]
      case $game_date.date[0..2]
      when [1772,3,2]
        GabeSDK.getAchievement("HellModDateT1") if $story_stats["Setup_Hardcore"] >= 1
        GabeSDK.getAchievement("DoomModDateT1") if $story_stats["Setup_Hardcore"] >= 2
      when [1773,3,1]
        GabeSDK.getAchievement("HellModDateT2") if $story_stats["Setup_Hardcore"] >= 1
        GabeSDK.getAchievement("DoomModDateT2") if $story_stats["Setup_Hardcore"] >= 2
      when [1774,3,1]
        GabeSDK.getAchievement("HellModDateT3") if $story_stats["Setup_Hardcore"] >= 1
      when [1776,6,6]
        GabeSDK.getAchievement("DoomModDateT3") if $story_stats["Setup_Hardcore"] >= 2
      end
    end
  end
end
