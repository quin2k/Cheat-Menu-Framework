FrameworkModule = {
  name:       "Game Fixes", 
  key:        :game_fixes, 
  menu:       :FIXES #Group key.
}

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
    #------------------------------------------
    # Toggles 
    #------------------------------------------
    register_command(
      type:   :edit_list,
      key:    "Despawn Fix", #should be unique to this dictionary
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
      gdef:   1, #default value = Normal
      order:  10
    )
    register_command(
      type:   :edit_list,
      key:    "Increase Drop Rate", #should be unique to this dictionary
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
      gdef:   1, #default value = Normal
      order:  20
    )
    register_command(
      group:  :NPC,
      type:   :edit_list,
      key:    "Siren Summon Max", #should be unique to this dictionary
      label:  "modules/others:commands/siren",
      help1:  "modules/others:command_help/siren1",
      state:  "$cheat_max_sirens",
      list:   [
                { key:  2,   label: "[#{$framework.txt("modules/others:command_item/off")}]" },
                { key:  4,   label: "[4]" },
                { key:  6,   label: "[6]" },
                { key:  8,   label: "[8]" },
                { key:  10,  label: "[10]" },
                { key:  12,  label: "[12]" },
              ],
      gdef:   2, #default value = Normal
      order:  90
    )
    register_command(
      group:  :NPC,
      type:   :toggle,
      key:    "Friendly Fire", #should be unique to this dictionary
      label:  "modules/others:commands/friendlyfire",
      help1:  "modules/others:command_help/friendlyfire1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_friendly_fire_fix",
      gdef:   false,
      restart: true, 
      order:  40
    )
    register_command(
      type:   :toggle,
      key:    "Equip Anything", #should be unique to this dictionary
      label:  "modules/others:commands/equip",
      help1:  "modules/others:command_help/equip1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_classless_society",
      gdef:   false,
      restart: true,
      order:  30
    )
    register_command(
      type:   :toggle,
      key:    "Stealth Fix", #should be unique to this dictionary
      label:  "modules/others:commands/stealth",
      help1:  "modules/others:command_help/stealth1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_stealth_confirm_fix",
      gdef:   false,
      restart: true, 
      order:  50
    )
    register_command(
      type:   :toggle,
      key:    "Abomination Skill Fix", #should be unique to this dictionary
      label:  "modules/others:commands/abomskillfix",
      help1:  "modules/others:command_help/abomskillfix1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_abomination_skill_fix",
      gdef:   false,
      restart: true, 
      order:  60
    )
    register_command(
      type:   :toggle,
      key:    "Achievement Fix", #should be unique to this dictionary
      label:  "modules/others:commands/achievementfix",
      help1:  "modules/others:command_help/achievementfix1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_difficulty_achievement_fix",
      gdef:   false,
      restart: true, 
      order:  70
    )
        register_command(
      type:   :toggle,
      key:    "Deepone Can Communicate", #should be unique to this dictionary
      label:  "modules/others:commands/deeponecommunicate",
      help1:  "modules/others:command_help/deeponecommunicate1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_deepone_weak_fix",
      global: false
    )
    register_command(
      group:  :NPC,
      type:   :toggle,
      key:    "Infinite Companion Duration", #should be unique to this dictionary
      label:  "modules/revive:commands/infinitecompanion",
      help1:  "modules/revive:command_help/infinitecompanion1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_infinite_companion",
      global: false
    )
  end
end


if $cheat_friendly_fire_fix
  module Battle_System
    alias_method :skill_result_check_ignore_tgt_nofriendlyfire, :skill_result_check_ignore_tgt

    def skill_result_check_ignore_tgt(character, skill)
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


if $cheat_stealth_confirm_fix
  class Game_Player
    def update_nonmoving(last_moving)
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


if $cheat_abomination_skill_fix
  class Game_Actor
    def check_Abom_heal_HealthSta(tmpCost = 10)
      tmpSuccess = false
      tmpSTA = self.sta
      tmpStaMax = self.battle_stat.get_stat("sta", 2)
      tmpStaVS = ((tmpSTA - tmpStaMax).abs).to_i
      tmpHp = self.health
      tmpHpMax = self.battle_stat.get_stat("health", 2)
      tmpHpVS = 0
      tmpHpVS = ((tmpHp - tmpHpMax).abs).to_i
      tmpSat = self.sat
      tmpSatMax = self.battle_stat.get_stat("sat", 2)
      tmpSatVS = ((tmpSat - tmpSatMax).abs).to_i

      #self.sat -= tmpCost
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

      tmpSuccess = true
      tmpSuccess
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

  class Game_Actor
    alias_method :check_Abom_heal_HealthSta_HEALWOUND, :check_Abom_heal_HealthSta

    def check_Abom_heal_HealthSta(tmpCost = 10)
      self.heal_wound
      check_Abom_heal_HealthSta_HEALWOUND(tmpCost)
    end
  end
end


if $cheat_difficulty_achievement_fix
  module GIM_ADDON
    def achCheckDate
      return if $story_stats["Setup_HardcoreAmt"] != [1772,3,1]
      #Doomsday Mode
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


if $cheat_item_drops != 0
  class Game_NonPlayerCharacter
    alias orig_min_drop_amt min_drop_amt
    alias orig_max_drop_amt max_drop_amt

    def min_drop_amt
      (orig_min_drop_amt * $cheat_item_drops).to_i
    end

    def max_drop_amt
      (orig_max_drop_amt * $cheat_item_drops).to_i
    end
  end
end

if $cheat_classless_society
  class Game_BattlerBase
    def equip_wtype_ok?(wtype_id)
      # Allow equipping weapons no matter the type.
      true
    end
    def equip_atype_ok?(atype_id)
      # Allow equipping armor no matter the type.
      true
    end
    def usable_item_conditions_met?(item)
      # Allow weapon skills regardless of prerequisites
      return true if item.is_a?(RPG::Skill) && added_skills.include?(item.id)
      movable?
    end
  end
end

if $cheat_deepone_weak_fix
  # Base game hard-blocks True Deepone from triggering any non-owned NPC event.
  class Game_Player
    def cannotTriggerBecauseTrueDeepone(tmpEvent)
      false
    end
  end

  # Base game also hardcodes True Deepone into forced sneak-or-fight encounters,
  # auto-hostile city gates, and blocked companion recruitment across a handful
  # of HCGframes scripts. Rather than shipping our own copies of that game
  # content (which would go stale the moment the base game updates those
  # files), patch load_script itself to strip the hardcoded check straight out
  # of whatever the currently-installed file says, every time it's loaded -
  # same idea as Game_Map#override_matching in modules/UnlockGallery.rb, just
  # applied to script text instead of parsed event commands.
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

    # Removes the game's own "if RaceRecord == TrueDeepone ... end" branch.
    # Tracks block-open/close depth (not just "first end after the guard")
    # since a couple of these files nest a case/end inside the guarded if/end.
    # If the guard or its matching end can't be found (base game reworded or
    # restructured it), returns the text unchanged rather than risk corrupting
    # it - the fix just silently stops applying to that one file until updated.
    def strip_race_gate(text)
      lines = text.lines
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
    unless DeeponeWeakFixPatch::TARGET_PATHS.include?(path) || path == DeeponeWeakFixPatch::NOER_OUTA_NEEDA_HELP
      return cf_deepone_weak_fix_load_script(path)
    end
    text = File.open(path, 'rb', &:read)
    text = path == DeeponeWeakFixPatch::NOER_OUTA_NEEDA_HELP ? text.gsub(" && !tmpTrueDeepone", "") : DeeponeWeakFixPatch.strip_race_gate(text)
    self.instance_eval(text, path)
  rescue => ex
    msgbox ex.message + "\n" + ex.backtrace.join("\n")
  end

  # TrueDeepone.json bakes in a +1000 max "weak" penalty. States aren't covered
  # by $mod_load_script, so patch the parsed effect directly after data loads.
  class << DataManager
    alias_method :cf_deepone_weak_fix_load_mod_database, :load_mod_database
    def load_mod_database
      cf_deepone_weak_fix_load_mod_database
      state = $data_StateName.values.find { |s| s && s.name == "TrueDeepone" }
      lona_effect = state && state.instance_variable_get(:@lona_effect)
      weak_effect = lona_effect && lona_effect.find { |e| e.attr == "weak" }
      weak_effect.instance_variable_set(:@adjust, 0) if weak_effect
    end
  end
end

if $cheat_infinite_companion
  # Every companion "expiry" check (summon_companion, check_companion_outdate?,
  # and the companion info overlay) only ever acts when these dates aren't nil -
  # forcing the readers to nil is enough to stop auto-leaving, without touching
  # either checking method or the recruitment code that writes these dates.
  class Game_Player
    def record_companion_front_date; nil; end
    def record_companion_back_date;  nil; end
    def record_companion_ext_date;   nil; end
  end
end

