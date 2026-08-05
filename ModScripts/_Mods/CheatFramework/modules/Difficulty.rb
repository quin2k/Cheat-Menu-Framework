FrameworkModule = {
  name:       "Difficulty",
  key:        :difficulty,
  menu:       :DIFFICULTY
}

#--------------------------------------------------------------------------
# Menu Commands
#--------------------------------------------------------------------------
module MenuFramework
  module MENU
    register_command(
      type:  :scene,
      label: "modules/others:commands/difficulty",
      name:  "CheatMenuDifficulty",
      order: 7
    )
  end

  module SUBMENU
    register_command(
      type:   :edit_num,
      key:    "World Difficulty",
      label:  "modules/others:commands/world",
      state:  "$story_stats['WorldDifficulty'].to_i",
      min:    0,
      max:    100,
      action: ->(v) { $story_stats["WorldDifficulty"] = v },
      order:  10
    )
    # Same underlying cheat as Pregnancy.rb's "Pregnancy Difficulty" - shares its key/state/text so
    # both screens read and persist the exact same value, just registered again for this screen.
    register_command(
      type:   :edit_list,
      key:    "Pregnancy Difficulty",
      label:  "modules/pregnancy:commands/difficulty",
      state:  "$cheat_pregnancy_difficulty",
      gdef:   -1,
      help1:  "modules/pregnancy:command_help/difficulty",
      order:  60,
      list:   [
                { key: -1, label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
                { key:  0, label: "[#{$framework.txt("menu:cheat_toggle/hard")}]" },
                { key:  1, label: "[#{$framework.txt("menu:cheat_toggle/hell")}]" },
                { key:  2, label: "[#{$framework.txt("menu:cheat_toggle/doom")}]" }
              ]
    )
    register_command(
      type:   :action,
      key:    "Disable Doom Mode",
      label:  "modules/others:commands/diff",
      help1:  "modules/others:command_help/diff",
      hide:   -> { $story_stats["Setup_Hardcore"] != 2 },
      order:  70,
      action: -> { $story_stats["Setup_Hardcore"] = 0
                   $story_stats["record_giveup_hardcore"] = 0 }
    )

    # Off/Hard/Hell list, matching Pregnancy Difficulty's naming scheme.
    DIFFICULTY_TIER_LIST = [
      { key: -1, label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
      { key:  0, label: "[#{$framework.txt("menu:cheat_toggle/hard")}]" },
      { key:  1, label: "[#{$framework.txt("menu:cheat_toggle/hell")}]" },
    ]
    register_command(
      type:   :edit_list,
      key:    "Addiction Effects",
      label:  "modules/others:commands/addictioneffects",
      help1:  "modules/others:command_help/addictioneffects1",
      state:  "$cheat_addiction_effects",
      list:   DIFFICULTY_TIER_LIST,
      gdef:   0,
      order:  40
    )
    register_command(
      type:   :edit_list,
      key:    "Milk Overflow",
      label:  "modules/others:commands/milkoverflow",
      help1:  "modules/others:command_help/milkoverflow1",
      state:  "$cheat_milk_overflow",
      list:   DIFFICULTY_TIER_LIST,
      gdef:   0,
      order:  50
    )

    register_command(
      type:   :edit_list,
      key:    "Despawn Fix",
      label:  "modules/others:commands/despawnfix",
      help1:  "modules/others:command_help/despawnfix1",
      state:  "$cheat_item_despawn",
      list:   [
                { key:  0,  label: "[#{$framework.txt("menu:cheat_toggle/disable")}]" },
                { key:  1,  label: "[x1]" },
                { key:  2,  label: "[x2]" },
                { key:  4,  label: "[x4]" },
                { key:  5,  label: "[x8]" },
                { key: -1,  label: "[#{$framework.txt("menu:cheat_toggle/infinite")}]" },
              ],
      # 0 doubles as both "Off" and "not installed" (the patch's own gate is `!= 0`) - defaulting
      # here instead of x1 means a fresh install doesn't pay for the patch until actually used.
      gdef:   1,
      restart: -1,
      order:  20
    )
    register_command(
      type:   :edit_list,
      key:    "Increase Drop Rate",
      label:  "modules/others:commands/drops",
      help1:  "modules/others:command_help/dropsfix1",
      state:  "$cheat_item_drops",
      list:   [
                { key:  0,  label: "[#{$framework.txt("menu:cheat_toggle/disable")}]" },
                { key:  1,  label: "[x1]" },
                { key:  2,  label: "[x2]" },
                { key:  4,  label: "[x4]" },
              ],
      gdef:   1,
      restart: 0,
      order:  30
    )
  end
end

#--------------------------------------------------------------------------
# Addiction Effects
#--------------------------------------------------------------------------
# Ograsm/Semen/Drug addiction overevents normally only trigger at Hell+ difficulty - Off suppresses
# them regardless, Hell forces them regardless, Hard leaves the game's own check alone.
module GIM_OVC
  alias_method :cf_addiction_check_half_over_event, :check_half_over_event
  def check_half_over_event(parallel = false)
    cf_addiction_check_half_over_event(parallel)
    return unless $cheat_addiction_effects == 1 && $story_stats["Setup_Hardcore"] < 1
    checkOev_OgrasmAddiction(parallel)
    checkOev_SemenAddiction(parallel)
    checkOev_DrugAddiction(parallel)
  end

  alias_method :cf_addiction_off_ograsm, :checkOev_OgrasmAddiction
  def checkOev_OgrasmAddiction(parallel = false)
    return if $cheat_addiction_effects == -1
    cf_addiction_off_ograsm(parallel)
  end

  alias_method :cf_addiction_off_semen, :checkOev_SemenAddiction
  def checkOev_SemenAddiction(parallel = false)
    return if $cheat_addiction_effects == -1
    cf_addiction_off_semen(parallel)
  end

  alias_method :cf_addiction_off_drug, :checkOev_DrugAddiction
  def checkOev_DrugAddiction(parallel = false)
    return if $cheat_addiction_effects == -1
    cf_addiction_off_drug(parallel)
  end
end

#--------------------------------------------------------------------------
# Milk Overflow
#--------------------------------------------------------------------------
# checkOev_Milk gates itself on Hell+ difficulty internally - Off/Hell temporarily force that gate
# below/above for one call instead of duplicating its body; Hard leaves it alone.
module GIM_OVC
  alias_method :cf_milk_overflow_checkOev_Milk, :checkOev_Milk
  def checkOev_Milk(parallel = false)
    return if $cheat_milk_overflow == -1
    return cf_milk_overflow_checkOev_Milk(parallel) unless $cheat_milk_overflow == 1
    original = $story_stats["Setup_Hardcore"]
    $story_stats["Setup_Hardcore"] = 1
    cf_milk_overflow_checkOev_Milk(parallel)
    $story_stats["Setup_Hardcore"] = original
  end
end

#--------------------------------------------------------------------------
# Item Decay Control
#--------------------------------------------------------------------------
if $cheat_item_despawn != 0
  class Game_Map
    alias rq_orig_reserve_summon_event reserve_summon_event
    def reserve_summon_event(event_name, x=$game_player.x, y=$game_player.y, id=-1, data=nil)
      if event_name && event_name.start_with?("Item")
        event_template = event_lib[event_name][1]
        if event_template.pages
          event_template.pages.each do |page|
            next unless page.move_route && page.move_route.list.is_a?(Array)
            page.move_route.list.each do |cmd|
              next unless cmd.is_a?(RPG::MoveCommand) && [45, 42].include?(cmd.code)
              if $cheat_item_despawn >= 1 && cmd.parameters[0] =~ /@wait_count.*scoutcraft_trait/
                new_wait = [600 + 60 * $game_player.actor.scoutcraft_trait, 1800].min * $cheat_item_despawn
                cmd.parameters[0] = "@wait_count = #{new_wait}"
              elsif $cheat_item_despawn == -1
                if cmd.parameters[0] == 100
                  cmd.parameters[0] = 255
                elsif cmd.parameters[0] =~ /\bdelete\b/
                  cmd.code = 0
                  cmd.parameters = []
                end
              end
            end
          end
        end
      end
      @summoned_evs << [event_name, x, y, id, data]
    end
  end
end

#--------------------------------------------------------------------------
# Increase Drop Rate
#--------------------------------------------------------------------------
if $cheat_item_drops != 0
  class Game_NonPlayerCharacter
    alias orig_min_drop_amt min_drop_amt
    alias orig_max_drop_amt max_drop_amt

    # Falls back to the normal amount when the multiplier is 0 (Disabled).
    def min_drop_amt
      return orig_min_drop_amt unless $cheat_item_drops > 0
      (orig_min_drop_amt * $cheat_item_drops).to_i
    end

    def max_drop_amt
      return orig_max_drop_amt unless $cheat_item_drops > 0
      (orig_max_drop_amt * $cheat_item_drops).to_i
    end
  end
end
