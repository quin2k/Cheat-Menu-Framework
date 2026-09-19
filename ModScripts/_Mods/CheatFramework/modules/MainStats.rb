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

    #--------------------------------------------------------------------------
    # Lona Vulnerable
    #--------------------------------------------------------------------------
    register_command(
      group:  :TOGGLES,
      type:   :toggle,
      key:    "Lona Vulnerable",
      label:  "modules/mainstatus:toggle/vulnerable",
      help1:  "modules/mainstatus:command_help/vulnerable1",
      state:  "FrameworkUtils.lona_vulnerable?",
      order:  90,
      action: -> { $story_stats['CF_lona_vulnerable'] = FrameworkUtils.lona_vulnerable? ? 0 : 1 }
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

# Refills Infinite Health before each death check; releases Lona Vulnerable the instant she collapses, so she isn't pinned back to 0 on waking.
class Game_Actor
  alias_method :determine_death_LONA_VULNERABLE, :determine_death
  def determine_death
    FrameworkUtils.health_to_max if $cheat_infinite_health && $game_player && self == $game_player.actor
    was_death = @action_state == :death
    determine_death_LONA_VULNERABLE
    $story_stats['CF_lona_vulnerable'] = 0 if !was_death && @action_state == :death && FrameworkUtils.lona_vulnerable?
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
    apply_stamina_lock if $cheat_infinite_stamina || lona_vulnerable?
    if $cheat_infinite_food; food_to_max end
    if $cheat_infinite_money; money_to_max end
  end

  def self.lona_vulnerable?
    $story_stats['CF_lona_vulnerable'] == 1
  end

  # Vulnerable alone only caps from above, so she can still faint for real; combined with
  # Infinite Stamina, a plain top-up would put her back at full, so this pins her at 0 instead.
  def self.apply_stamina_lock
    actor = $game_player.actor
    # Water's broken (base game's own "ready to birth" check) - let contractions/birth drain sta through, she's meant to faint here.
    return if actor.preg_level == 5 && $story_stats['dialog_ready_to_birth'] == 0
    if $cheat_infinite_stamina && lona_vulnerable?
      actor.sta = 0 if actor.sta != 0
    elsif $cheat_infinite_stamina
      stamina_to_max
    else
      actor.sta = 0 if actor.sta > 0
    end
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

