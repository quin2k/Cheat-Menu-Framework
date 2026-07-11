FrameworkModule = {
  name:       "Main Stats",
  key:         :main_stats,
  order:      90,
  depends_on: []
}

#--------------------------------------------------------------------------
# Menu Commands
#--------------------------------------------------------------------------
module MenuFramework
  module SUBMENU
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Infinite Health",
      label:  "modules/mainstatus:toggle/health",
      state:  "$cheat_infinite_health",
      hotkey: {key: "F4"},
      gdef:   false,
      order:  10
    )
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Infinite Stamina",
      label:  "modules/mainstatus:toggle/stamina",
      state:  "$cheat_infinite_stamina",
      hotkey: {key: "F4"},
      gdef:   false,
      order:  20
    )
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Infinite Food",
      label:  "modules/mainstatus:toggle/food",
      state:  "$cheat_infinite_food",
      hotkey: {key: "F4"},
      gdef:   false,
      order:  30
    )

    #--------------------------------------------------------------------------
    # Legacy Cheats
    #--------------------------------------------------------------------------
    register_command(
      group:  :MISC,
      type:   :action,
      key:    "Heal",
      label:  "modules/mainstatus:misc/heal",
      enable: -> { !($cheat_infinite_health && $cheat_infinite_stamina && $cheat_infinite_food) },
      action: -> {
        FrameworkUtils.health_to_max
        FrameworkUtils.stamina_to_max
        FrameworkUtils.food_to_max
      },
      order:  10
    )
    register_command(
      group:  :MISC,
      type:   :action,
      key:    "Heal Wound",
      label:  "modules/mainstatus:misc/heal_wound",
      enable: -> { !$cheat_autobandage },
      action: -> { $game_player.actor.heal_wound },
      help1:  "modules/mainstatus:command_help/heal_wound",
      order:  20
    )
    register_command(
      group:  :MISC,
      type:   :action,
      key:    "Faint",
      enable: -> { !$cheat_infinite_stamina },
      label:  "modules/mainstatus:misc/faint",
      action: -> { $game_player.actor.sta = -100 },
      order:  30
    )

    #--------------------------------------------------------------------------
    # Money Cheats
    #--------------------------------------------------------------------------
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Infinite Money",
      label:  "modules/mainstatus:toggle/money",
      state:  "$cheat_infinite_money",
      gdef:   false,
      order:  40
    )
    register_command(
      group:  :MISC,
      type:   :action,
      key:    "Money Now",
      label:  "modules/mainstatus:misc/money",
      enable: -> {!$cheat_infinite_money},
      action: -> { $game_party.set_gold_only(99999) },
      order:  40
    )
  end
end


#--------------------------------------------------------------------------
# Hotkey Hook
#--------------------------------------------------------------------------
class CheatFramework
  alias_method :hotkey_trigger_INFINITESTATS, :hotkey_trigger
  def hotkey_trigger
    hotkey_trigger_INFINITESTATS
    FrameworkUtils.apply_infinite_stats
  end
end


#--------------------------------------------------------------------------
# Per-Tick Application
#--------------------------------------------------------------------------
module FrameworkUtils
  def self.apply_infinite_stats
    return unless self.ingame?
    actor = $game_player.actor
    return unless actor

    if $cheat_infinite_health; health_to_max end
    if $cheat_infinite_stamina; stamina_to_max end
    if $cheat_infinite_food; food_to_max end
    if $cheat_infinite_money; money_to_max end
  end

  def self.health_to_max
    actor = $game_player.actor
    max_hp = actor.battle_stat.get_stat("health", ActorStat::MAX_STAT)
    actor.health = max_hp if actor.health < max_hp
  end

  def self.stamina_to_max
    actor = $game_player.actor
    max_stam = actor.battle_stat.get_stat("sta", ActorStat::MAX_STAT)
    actor.sta = max_stam if actor.sta < max_stam
  end

  def self.food_to_max
    actor = $game_player.actor
    max_sat = actor.battle_stat.get_stat("sat", ActorStat::MAX_STAT)
    actor.sat = max_sat if actor.sat < max_sat
  end

  def self.money_to_max
    actor = $game_player.actor
    $game_party.set_gold_only(99999) if $game_party.gold != 99999
  end

end

#Used by money cheats
class Game_Party
  def set_gold_only(amount)
    @gold = amount
  end
end

