FrameworkModule = {
  name:       "Clothing Utils",
  key:        :clothing_utils,
}

#--------------------------------------------------------------------------
# Menu Commands
#--------------------------------------------------------------------------
module MenuFramework
  module SUBMENU
    register_command(
      group:  :FIXES,
      type:   :edit_list,
      key:    "Prevent Discard",
      label:  "modules/others:commands/discard",
      help1:  "modules/others:command_help/discard1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_prevent_clothing_discard",
      # Inline 3-state list instead of reusing Fixes.rb's FIX_TOGGLE_LIST.
      list:   [
                { key: -1, label: "[#{$framework.txt("menu:cheat_toggle/disable")}]" },
                { key:  0, label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
                { key:  1, label: "[#{$framework.txt("menu:cheat_toggle/on")}]" },
              ],
      gdef:   0,
      restart: -1,
      order:  50
    )
    register_command(
      group:  :MISC,
      type:   :action,
      key:    "Remove Clothes",
      label:  "modules/others:commands/unequip",
      hotkey: {key: "F3"},
      action: -> { FrameworkUtils.unequipall(false) },
      order:  60
    )
    register_command(
      group:  :MISC,
      type:   :action,
      key:    "Force Remove Clothes",
      label:  "modules/others:commands/forceunequip",
      help1:  "modules/others:command_help/forceunequip1",
      hotkey: {key: "Shift+F3"},
      action: -> { FrameworkUtils.unequipall(true) },
      order:  70
    )
  end
end

module FrameworkUtils
  def self.unequipall(force)
    if self.ingame?
      actor = $game_player.actor
      actor.equip_slots.size.times do |i|
        item = actor.equips[i]
        next if item && item.type_tag == "Hair"
        bondage = item && item.type_tag == "Bondage"
        actor.change_equip(i, nil) if actor.equip_change_ok?(i) || (force && bondage)
        SndLib.sound_equip_armor
      end
    end
  end
end

#--------------------------------------------------------------------------
# Prevent Discard Patch
#--------------------------------------------------------------------------
# remove_equip_on_hit is the current (post B.0.10.8.05) choke point for combat clothing-strips -
# force summon off so the item returns to inventory instead of dropping as a pickup on the ground.
if $cheat_prevent_clothing_discard >= 0
  class Game_Actor
    alias_method :cf_prevent_discard_remove_equip_on_hit, :remove_equip_on_hit
    def remove_equip_on_hit(slot_key=self.remove_equip_slot_picker, summon=true, sound_play=true)
      summon = false if $cheat_prevent_clothing_discard == 1
      cf_prevent_discard_remove_equip_on_hit(slot_key, summon, sound_play)
    end
  end
end
