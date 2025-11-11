FrameworkModule = {
  name:       "Game Fixes", 
  key:        :game_fixes, 
  menu:       :TOGGLES #Group key.
}

module MenuFramework
  module SUBMENU
    #------------------------------------------
    # Toggles 
    #------------------------------------------
    register_command(
      type:   :toggle,
      key:    "Friendly Fire", #should be unique to this dictionary
      label:  "modules/others:commands/friendlyfire",
      help1:  "modules/others:command_help/friendlyfire1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_friendly_fire_fix",
      global: false
    )
    register_command(
      type:   :toggle,
      key:    "Stealth Fix", #should be unique to this dictionary
      label:  "modules/others:commands/stealth",
      help1:  "modules/others:command_help/stealth1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_stealth_confirm_fix",
      global: false
    )
    register_command(
      type:   :toggle,
      key:    "Abomination Skill Fix", #should be unique to this dictionary
      label:  "modules/others:commands/abomskillfix",
      help1:  "modules/others:command_help/abomskillfix1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_abomination_skill_fix",
      global: false
    )
    register_command(
      type:   :toggle,
      key:    "Achievement Fix", #should be unique to this dictionary
      label:  "modules/others:commands/achievementfix",
      help1:  "modules/others:command_help/achievementfix1",
      help2:  "modules/others:command_help/fixcommand2",
      state:  "$cheat_difficulty_achievement_fix",
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
        if user.event  && user.event.summon_data[:user] == $game_player
          attacker = "Lona"
        elsif user.event  && user.event.summon_data[:user].npc.master == $game_player
          attacker = "Ally"
        end
      else
        #Direct attacks such as melee
        if user == $game_player.actor
          attacker = "Lona"
        elsif user.master == $game_player
          attacker = "Ally"
        end
      end
      if target == $game_player
        targeted = "Lona"
      elsif target.actor.master == $game_player
        targeted = "Ally"
      end

      #Support magic/skill or target/attacker isn't an ally
      return false if skill.is_support || !attacker || !targeted
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
