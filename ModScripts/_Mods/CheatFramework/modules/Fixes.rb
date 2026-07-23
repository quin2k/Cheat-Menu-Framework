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
      order: 4
    )
  end

  module SUBMENU
    #--------------------------------------------------------------------------
    # Toggles
    #--------------------------------------------------------------------------
    register_command(
      type:   :edit_list,
      key:    "Despawn Fix",
      label:  "modules/others:commands/despawnfix",
      help1:  "modules/others:command_help/despawnfix1",
      help2:  "modules/others:command_help/despawnfix2",
      state:  "$cheat_item_despawn",
      list:   [
                { key:  0,  label: "[#{$framework.txt("modules/others:command_item/off")}]" },
                { key:  1,  label: "[x1]" },
                { key:  2,  label: "[x2]" },
                { key:  4,  label: "[x4]" },
                { key:  5,  label: "[x8]" },
                { key: -1,  label: "[#{$framework.txt("modules/others:command_item/infinite")}]" },
              ],
      gdef:   1,
      restart: 0,
      order:  10
    )
    register_command(
      type:   :edit_list,
      key:    "Increase Drop Rate",
      label:  "modules/others:commands/drops",
      help1:  "modules/others:command_help/dropsfix1",
      help2:  "modules/others:command_help/despawnfix2",
      state:  "$cheat_item_drops",
      list:   [
                { key:  0,  label: "[#{$framework.txt("modules/others:command_item/off")}]" },
                { key:  1,  label: "[x1]" },
                { key:  2,  label: "[x2]" },
                { key:  4,  label: "[x4]" },
              ],
      gdef:   1,
      restart: 0,
      order:  20
    )
    register_command(
      group:  :NPC,
      type:   :edit_list,
      key:    "Siren Summon Max",
      label:  "modules/others:commands/siren",
      help1:  "modules/others:command_help/siren1",
      state:  "$cheat_max_sirens",
      list:   [
                { key:  2,   label: "[#{$framework.txt("menu:cheat_toggle/off")} (2)]" },
                { key:  4,   label: "[4]" },
                { key:  6,   label: "[6]" },
                { key:  8,   label: "[8]" },
                { key:  10,  label: "[10]" },
                { key:  12,  label: "[12]" },
              ],
      gdef:   2,
      order:  60
    )

    #--------------------------------------------------------------------------
    # Restart-Capable Fixes
    #--------------------------------------------------------------------------
    # Shared Disable / Off / On list for every fix below.
    FIX_TOGGLE_LIST = [
      { key: -1, label: "[#{$framework.txt("modules/others:command_item/off")}]" },
      { key:  0, label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
      { key:  1, label: "[#{$framework.txt("menu:cheat_toggle/on")}]" },
    ]
    register_command(
      group:  :NPC,
      type:   :edit_list,
      key:    "Friendly Fire",
      label:  "modules/others:commands/friendlyfire",
      help1:  "modules/others:command_help/friendlyfire1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_friendly_fire_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  30
    )
    register_command(
      type:   :edit_list,
      key:    "Equip Anything",
      label:  "modules/others:commands/equip",
      help1:  "modules/others:command_help/equip1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_classless_society",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  40
    )
    register_command(
      type:   :edit_list,
      key:    "Stealth Fix",
      label:  "modules/others:commands/stealth",
      help1:  "modules/others:command_help/stealth1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_stealth_confirm_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  60
    )
    register_command(
      type:   :edit_list,
      key:    "Abomination Skill Fix",
      label:  "modules/others:commands/abomskillfix",
      help1:  "modules/others:command_help/abomskillfix1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_abomination_skill_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  70
    )
    register_command(
      type:   :edit_list,
      key:    "Achievement Fix",
      label:  "modules/others:commands/achievementfix",
      help1:  "modules/others:command_help/achievementfix1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_difficulty_achievement_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  80
    )
    register_command(
      group:  :NPC,
      type:   :edit_list,
      key:    "Deepone Can Communicate",
      label:  "modules/others:commands/deeponecommunicate",
      help1:  "modules/others:command_help/deeponecommunicate1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_deepone_weak_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  50
    )
    register_command(
      type:   :edit_list,
      key:    "Fast Nap",
      label:  "modules/others:commands/fastnap",
      help1:  "modules/others:command_help/fastnap1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_fast_nap",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      hide:   -> { $framework.roleplay_mod? },
      order:  50
    )
    register_command(
      group:  :NPC,
      type:   :edit_list,
      key:    "Endless Contracts",
      label:  "modules/others:commands/endlesscontracts",
      help1:  "modules/others:command_help/endlesscontracts1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_infinite_companion",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  40
    )

    #--------------------------------------------------------------------------
    # Misc
    #--------------------------------------------------------------------------
    register_command(
      group:  :MISC,
      type:   :toggle,
      key:    "Night Vision",
      label:  "modules/others:commands/nightvision",
      help1:  "modules/others:command_help/nightvision1",
      state:  "$cheat_night_vision",
      gdef:   false,
      order:  50,
      action: -> {
        $cheat_night_vision = !$cheat_night_vision
        $framework.ini.write_global("Night Vision", $cheat_night_vision)
        $game_map.shadows.cf_reapply_opacity if FrameworkUtils.ingame? && $game_map && $game_map.shadows
      }
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
# Abomination Skill Fix
#--------------------------------------------------------------------------
if $cheat_abomination_skill_fix >= 0
  class Game_Actor
    alias_method :cf_abomination_skill_fix_check_Abom_heal_HealthSta, :check_Abom_heal_HealthSta

    # Restores sat, stamina, and health, and heals wounds.
    def check_Abom_heal_HealthSta(tmpCost = 10)
      return cf_abomination_skill_fix_check_Abom_heal_HealthSta(tmpCost) unless $cheat_abomination_skill_fix == 1
      self.heal_wound
      tmpSTA = self.sta
      tmpStaMax = self.battle_stat.get_stat("sta", 2)
      tmpStaVS = ((tmpSTA - tmpStaMax).abs).to_i
      tmpHp = self.health
      tmpHpMax = self.battle_stat.get_stat("health", 2)
      tmpHpVS = ((tmpHp - tmpHpMax).abs).to_i
      tmpSat = self.sat
      tmpSatMax = self.battle_stat.get_stat("sat", 2)
      tmpSatVS = ((tmpSat - tmpSatMax).abs).to_i

      if $story_stats["Setup_Hardcore"] >= 1
        satScore = (tmpCost * 0.5).round
      else
        satScore = (tmpCost * 0.8).round
      end

      if tmpSatVS != 0 && satScore > 0
        tmpSatInc = ([tmpSatVS, satScore].min).to_i
        satScore -= tmpSatInc
        self.sat += tmpSatInc
      end
      if tmpStaVS != 0 && satScore > 0
        tmpStaInc = ([tmpStaVS, satScore].min).to_i
        satScore -= tmpStaInc
        self.sta += tmpStaInc
      end
      if tmpHpVS != 0 && satScore > 0
        tmpHpInc = ([tmpHpVS, satScore].min).to_i
        satScore -= tmpHpInc
        self.health += tmpHpInc
      end

      true
    end
  end

  class Game_Event
    def abomEatDed
      user = @summon_data[:user]
      chkedNPC = $game_map.events_xy(user.x, user.y).select { |event|
        next if event == user
        next if event.deleted?
        next if !event.npc?
        next if event.actor.is_object
        next if event.actor.race == "Undead"
        next if !event.actor.dedAnimPlayed
        event
      }
      user.actor.add_state(160)
      if chkedNPC.empty?
        $game_map.popup(0, "QuickMsg:Lona/CannotWorks#{rand(2)}", 0, 0)
        SndLib.sys_buzzer
        return delete
      else
        @zoom_x = 1
        @zoom_y = 1
      end
      abomGrabSkillHoldEFX
      if !chkedNPC.empty?
        if user.actor.last_holding_count >= @summon_data[:skill].launch_max
          user.actor.remove_state_stack(49) #Sickly
          user.actor.remove_state_stack(30) #FeelsSick
          tmpTarHP = chkedNPC[0].actor.battle_stat.get_stat("health", 3) / 4
          tmpTarSAT = chkedNPC[0].actor.battle_stat.get_stat("sat", 3) / 5
          tmpTarSTA = chkedNPC[0].actor.battle_stat.get_stat("sta", 3) / 6
          bounsPointsToLona = tmpTarHP + tmpTarSTA + tmpTarSAT
          user.actor.check_Abom_heal_HealthSta(bounsPointsToLona)
          tmpHowManyBall = bounsPointsToLona / 50
          summonTimes = [tmpHowManyBall, 6].min
          summonTimes.times {
            EvLib.sum(["WasteJumpBloodToPlayer", "WasteJumpBloodToPlayer2"].sample, user.x, user.y)
          }
        else
          tmpTarHP = chkedNPC[0].actor.battle_stat.get_stat("health", 3)
          tmpTarSAT = chkedNPC[0].actor.battle_stat.get_stat("sat", 3)
          tmpTarSTA = chkedNPC[0].actor.battle_stat.get_stat("sta", 3)
          tmpTarATK = chkedNPC[0].actor.battle_stat.get_stat("def", 3)
          tmpTarDEF = chkedNPC[0].actor.battle_stat.get_stat("atk", 3)
          tmpTarSUR = chkedNPC[0].actor.battle_stat.get_stat("survival", 3)
          tmpData = {
            :user => user,
            :HP => tmpTarHP,
            :SAT => tmpTarSAT,
            :STA => tmpTarSTA,
            :ATK => tmpTarATK,
            :DEF => tmpTarDEF,
            :SUR => tmpTarSUR,
          }
          EvLib.sum("ProjAbomSumTentacle", user.x, user.y, tmpData)
          tmpBakDir = user.direction
          user.combat_jump_reverse
          user.direction = tmpBakDir
        end
        EvLib.sum("EffectOverKillReverse", chkedNPC[0].x, chkedNPC[0].y)
        chkedNPC[0].effects = ["ZoomOutDelete", 0, false, nil, nil, [true, false].sample]
        if $game_player.actor.stat["BloodLust"] == 1 || $game_player.actor.stat["Cannibal"] == 1
          $game_player.actor.mood += 50
        else
          $game_player.actor.mood -= 10
        end
      end
    end
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
# Deepone Summon Max
#--------------------------------------------------------------------------
# Rewrites the summon-limit check baked into this event's own script commands.
class Game_Event
  alias _booba_orig_refresh refresh
  def refresh
    _booba_orig_refresh

    return if @booba_checked
    @booba_checked = true

    return unless @summon_data
    event = @event
    return unless event
    return unless event.name == "SummonDeeponeProjectile"
    event.pages.each do |page|
      next unless page.list
      page.list.each do |cmd|
        next unless cmd.code == 355 || cmd.code == 655
        if cmd.parameters[0].include?("tmpQGcount >= 2")
          cmd.parameters[0] =
            "return self.delete if tmpQGcount >= #{$cheat_max_sirens}"
        end
      end
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

#--------------------------------------------------------------------------
# Equip Anything
#--------------------------------------------------------------------------
if $cheat_classless_society >= 0
  class Game_BattlerBase
    alias_method :cf_classless_society_equip_wtype_ok, :equip_wtype_ok?
    alias_method :cf_classless_society_equip_atype_ok, :equip_atype_ok?
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
    def usable_item_conditions_met?(item)
      return cf_classless_society_usable_item_conditions_met(item) unless $cheat_classless_society == 1
      # Allow weapon skills regardless of prerequisites
      return true if item.is_a?(RPG::Skill) && added_skills.include?(item.id)
      movable?
    end
  end
end

#--------------------------------------------------------------------------
# Deepone Can Communicate
#--------------------------------------------------------------------------
if $cheat_deepone_weak_fix >= 0
  # Lets True Deepone trigger NPC events normally instead of being hard-blocked.
  class Game_Player
    alias_method :cf_deepone_weak_fix_cannotTriggerBecauseTrueDeepone, :cannotTriggerBecauseTrueDeepone

    def cannotTriggerBecauseTrueDeepone(tmpEvent)
      return cf_deepone_weak_fix_cannotTriggerBecauseTrueDeepone(tmpEvent) unless $cheat_deepone_weak_fix == 1
      false
    end
  end

  # Strips the game's own True Deepone race-gate block out of these HCGframes files at load time.
  module DeeponeWeakFixPatch
    extend self
    GUARD = 'if $game_player.actor.stat["RaceRecord"] == "TrueDeepone"'
    BLOCK_OPENER = /\A(if|unless|case|while|until|def|class|module|begin)\b/

    TARGET_PATHS = %w[
      Data/HCGframes/encounter/BanditMobs.rb
      Data/HCGframes/encounter/CommonMobs.rb
      Data/HCGframes/encounter/FishPPL.rb
      Data/HCGframes/encounter/GangDebtCollet.rb
      Data/HCGframes/encounter/NobleGuards.rb
      Data/HCGframes/encounter/NoerGuards.rb
      Data/HCGframes/encounter/NoerHomeless.rb
      Data/HCGframes/encounter/NoerMissionary.rb
      Data/HCGframes/encounter/RoadHalp.rb
      Data/HCGframes/event/OvermapDoomArmory.rb
      Data/HCGframes/event/OvermapDoomFortress.rb
      Data/HCGframes/event/OvermapNoerGateEast.rb
      Data/HCGframes/event/OvermapNoerGateNoble.rb
      Data/HCGframes/event/OvermapNoerGateNorth.rb
      Data/HCGframes/event/OvermapPirateBane.rb
      Data/HCGframes/event/FishkindCaveCompExtUQConvoy.rb
      Data/HCGframes/event/OrkindCaveCompExtUQConvoy.rb
    ]
    NOER_OUTA_NEEDA_HELP = "Data/HCGframes/encounter/NoerOutaNeedaHelp.rb"

    # Tracks block depth since some files nest a case/end inside the guard.
    def strip_race_gate(text)
      lines = text.lines.to_a
      guard_i = lines.index { |l| l.strip == GUARD }
      return text unless guard_i
      depth = 1
      ((guard_i + 1)...lines.length).each do |i|
        stripped = lines[i].strip
        depth += 1 if stripped =~ BLOCK_OPENER
        depth -= 1 if stripped == "end"
        next unless depth == 0
        return (lines[0...guard_i] + lines[(i + 1)..-1]).join
      end
      text
    end
  end

  alias cf_deepone_weak_fix_load_script load_script
  def load_script(path)
    return cf_deepone_weak_fix_load_script(path) unless $cheat_deepone_weak_fix == 1
    unless DeeponeWeakFixPatch::TARGET_PATHS.include?(path) || path == DeeponeWeakFixPatch::NOER_OUTA_NEEDA_HELP
      return cf_deepone_weak_fix_load_script(path)
    end
    text = File.open(path, 'rb', &:read)
    text = path == DeeponeWeakFixPatch::NOER_OUTA_NEEDA_HELP ? text.gsub(/[ \t]*&&\s*!tmpTrueDeepone/, "") : DeeponeWeakFixPatch.strip_race_gate(text)
    self.instance_eval(text, path)
  rescue => ex
    msgbox ex.message + "\n" + ex.backtrace.join("\n")
  end

  # TrueDeepone.json's +1000 "weak" penalty is a state effect load_script doesn't
  # touch - tag the ItemEffect instance so #adjust can zero it out live.
  class << DataManager
    alias_method :cf_deepone_weak_fix_load_mod_database, :load_mod_database
    def load_mod_database
      cf_deepone_weak_fix_load_mod_database
      state = $data_StateName["TrueDeepone"] # same lookup Game_Actor#add_state uses
      lona_effect = state && state.instance_variable_get(:@lona_effect)
      weak_effect = lona_effect && lona_effect.find { |e| e.attr == "weak" }
      weak_effect.instance_variable_set(:@cf_deepone_weak_marker, true) if weak_effect
    end
  end

  module ItemConfigs
    class ItemEffect
      alias_method :cf_deepone_weak_fix_adjust, :adjust
      def adjust
        return 0 if @cf_deepone_weak_marker && $cheat_deepone_weak_fix == 1
        cf_deepone_weak_fix_adjust
      end
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
