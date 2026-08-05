FrameworkModule = {
  name:       "Race Changer",
  key:         :edit_race,
  menu:       :RACE
}

module MenuFramework
  module SUBMENU
    #--------------------------------------------------------------------------
    # Character Editing Menu
    #--------------------------------------------------------------------------
    register_command(
      group:  :LONA,
      type:   :scene,
      key:    :edit_race,
      label:  "modules/character:commands/race",
      menu1:  "modules/character:window_help/race1",
      name:   "CheatMenuRace",
      dict:   :RACE,
      order:  50
    )

    #--------------------------------------------------------------------------
    # Race Commands
    #--------------------------------------------------------------------------
    register_command(
      type:   :action,
      key:    "Human",
      label:  "modules/character:commands/race/human",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "Human" ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("Human") },
      order:  10
    )
    register_command(
      type:   :action,
      key:    "Moot",
      label:  "modules/character:commands/race/moot",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "Moot" ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("Moot") },
      order:  20
    )
    register_command(
      type:   :action,
      key:    "Deepone",
      label:  "modules/character:commands/race/deepone",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "PreDeepone" ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("Deepone") },
      order:  30
    )
    register_command(
      type:   :action,
      key:    "True Deepone",
      label:  "modules/character:commands/race/truedeepone",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "TrueDeepone" ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("TrueDeepone") },
      order:  40
    )
    register_command(
      type:   :action,
      key:    "Human Abomination",
      label:  "modules/character:commands/race/abom_human",
      color:  -> { ($game_player.actor.stat["RaceRecord"] == "Abomination" && $game_player.actor.stat["Race"] == "Human") ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("HumanAbomination") ; $game_party.lose_item("ItemBluePotion",3) },
      order:  50
    )
    register_command(
      type:   :action,
      key:    "Moot Abomination",
      label:  "modules/character:commands/race/abom_moot",
      color:  -> { ($game_player.actor.stat["RaceRecord"] == "Abomination" && $game_player.actor.stat["Race"] == "Moot") ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("MootAbomination") ; $game_party.lose_item("ItemBluePotion",3) },
      order:  60
    )

    #--------------------------------------------------------------------------
    # Race Cheats
    #--------------------------------------------------------------------------
    register_command(
      group:  :LONA,
      type:   :scene,
      key:    "Race Cheats",
      label:  "modules/character:commands/racecheats",
      name:   "CheatMenuRaceCheats",
      dict:   :RACECHEATS,
      order:  55
    )
    # Shared Disable / Off / On list, matching Fixes.rb's FIX_TOGGLE_LIST.
    FIX_TOGGLE_LIST = [
      { key: -1, label: "[#{$framework.txt("menu:cheat_toggle/disable")}]" },
      { key:  0, label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
      { key:  1, label: "[#{$framework.txt("menu:cheat_toggle/on")}]" },
    ]

    # --- Deepone ---
    register_command(
      group:  :RACECHEATS,
      type:   :info,
      key:    "Deepone Divider",
      label:  -> { "---#{$framework.txt("modules/character:commands/race/truedeepone")}---" },
      order:  10
    )
    register_command(
      group:  :RACECHEATS,
      type:   :toggle,
      key:    "Sea Witch Awaken",
      label:  "modules/character:commands/race/skills/deepone",
      state:  "$game_player.actor.skill_learn?($data_skills[65])",
      color:  -> { ["TrueDeepone", "PreDeepone"].include?($game_player.actor.stat["RaceRecord"]) ? 0 : 8 },
      action: -> { FrameworkUtils.skill_toggle(65) }, # BasicDeepOne
      order:  40
    )
    register_command(
      group:  :RACECHEATS,
      type:   :edit_list,
      key:    "Deepone Can Communicate",
      label:  "modules/character:commands/deeponecommunicate",
      help1:  "modules/character:command_help/deeponecommunicate1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_deepone_weak_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  20
    )
    register_command(
      group:  :RACECHEATS,
      type:   :edit_list,
      key:    "Siren Summon Max",
      label:  "modules/character:commands/siren",
      help1:  "modules/character:command_help/siren1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_max_sirens",
      list:   [
                { key: -1,  label: "[#{$framework.txt("menu:cheat_toggle/off")}]" },
                { key:  2,   label: "[2]" },
                { key:  4,   label: "[4]" },
                { key:  6,   label: "[6]" },
                { key:  8,   label: "[8]" },
                { key:  10,  label: "[10]" },
                { key:  12,  label: "[12]" },
              ],
      gdef:   2,
      restart: -1,
      order:  30
    )

    # --- Abomination ---
    register_command(
      group:  :RACECHEATS,
      type:   :info,
      key:    "Abomination Divider",
      label:  -> { "---#{$framework.txt("modules/pregnancy:commands/impreg/abomination")}---" },
      order:  50
    )
    register_command(
      group:  :RACECHEATS,
      type:   :toggle,
      key:    "Abom Desecrate Skill",
      label:  "modules/character:commands/race/skills/abomeat",
      state:  "$game_player.actor.skill_learn?($data_skills[67])",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "Abomination" ? 0 : 8 },
      action: -> { FrameworkUtils.skill_toggle(67) }, # BasicAbomEatDed
      order:  70
    )
    register_command(
      group:  :RACECHEATS,
      type:   :toggle,
      key:    "Abom Tendril Whip",
      label:  "modules/character:commands/race/skills/abomgrab",
      state:  "$game_player.actor.skill_learn?($data_skills[66])",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "Abomination" ? 0 : 8 },
      action: -> { FrameworkUtils.skill_toggle(66) }, # BasicAbomGrab
      order:  80
    )
    register_command(
      group:  :RACECHEATS,
      type:   :edit_list,
      key:    "Abomination Skill Fix",
      label:  "modules/character:commands/abomskillfix",
      help1:  "modules/character:command_help/abomskillfix1",
      help2:  "menu:command_help/fixcommand2",
      state:  "$cheat_abomination_skill_fix",
      list:   FIX_TOGGLE_LIST,
      gdef:   0,
      restart: -1,
      order:  60
    )
  end
end

module FrameworkUtils
  def self.skill_toggle(skillid)
    actor = $game_player.actor
    if actor.skill_learn?($data_skills[skillid])
      actor.forget_skill(skillid)
    else
      actor.learn_skill(skillid)
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
# Deepone Summon Max
#--------------------------------------------------------------------------
if $cheat_max_sirens >= 0
  # Rewrites the summon-limit check baked into this event's own script commands.
  class Game_Event
    alias_method :cf_max_sirens_refresh, :refresh
    def refresh
      cf_max_sirens_refresh

      return if @cheat_max_sirens_checked
      @cheat_max_sirens_checked = true

      return unless @summon_data
      event = @event
      return unless event
      return unless event.name == "SummonDeeponeProjectile"
      # Toggled to Disabled after this already installed this session - -1 would otherwise get
      # interpolated straight into the rewritten command below and delete sirens on sight.
      return if $cheat_max_sirens == -1
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
end
