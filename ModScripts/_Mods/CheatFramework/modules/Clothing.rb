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
if $cheat_prevent_clothing_discard >= 0
  module GIM_CHCG
    alias_method :cf_prevent_discard_combat_remove_random_equip_exec, :combat_remove_random_equip_exec
    def combat_remove_random_equip_exec(tar_name,eqp_target=combat_hit_get_removable_slots,summon=true)
      unless $cheat_prevent_clothing_discard == 1
        return cf_prevent_discard_combat_remove_random_equip_exec(tar_name,eqp_target,summon)
      end
      eqp_target = $data_system.equip_type_name[eqp_target] if eqp_target.is_a?(String)
      $game_player.actor.change_equip(eqp_target, nil)
      weaponSlots = $data_system.weapon_slots
      tarType = weaponSlots.include?(eqp_target) ? "Weapon" : "Armor"
      #$game_party.drop_tgt_item_and_summon(tarType,tar_name,1,summon)
      if weaponSlots.include?(eqp_target) && summon
        SndLib.sound_combat_sword_hit_sword(vol=80,effect=65+rand(10))
      else
        SndLib.sound_DressTear(vol=80,effect=75+rand(10))
      end
      $game_player.actor.update_state_frames
      $game_player.update
    end
  end
end
