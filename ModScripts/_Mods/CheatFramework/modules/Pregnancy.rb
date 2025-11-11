FrameworkModule = {
  name:       "Pregnancy",
  key:        :pregnancy,
  menu:       :PREGNANCY,
  depends_on: [],
  enabled:    true
}

module MenuFramework
  module MENU
    #Register Menu Command
  end

  module SUBMENU
    #Register Pregnancy Menu Commands
    #List-style Edit
    register_command(
      group:  :LONA,
      type:   :scene,
      key:    :pregnancy,
      label:  "modules/pregnancy:commands/preg", 
      name:   "CheatMenuPregnancy",
      dict:   :PREGNANCY,
      order:  60
    )
    register_command(
      group:  :PREGNANCY,
      type:   :edit_list,
      key:    "Pregnancy Difficulty", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/difficulty",
      state:  "$cheat_pregnancy_difficulty",
      global: -1, #default value
      help1:  "modules/pregnancy:command_help/difficulty",
      order:  10,
      list:   [
                { key: -1, label: "[#{$framework.txt("modules/pregnancy:commands/diff_off")}]" },
                { key:  0, label: "[#{$framework.txt("modules/pregnancy:commands/diff_hard")}]" },
                { key:  1, label: "[#{$framework.txt("modules/pregnancy:commands/diff_hell")}]" },
                { key:  2, label: "[#{$framework.txt("modules/pregnancy:commands/diff_doom")}]" }
              ]
    )
    #Number-style Edit
    register_command(
      group:  :PREGNANCY,
      type:   :edit_num,
      key:    "Seedbed", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/seedbed",
      state:  "$game_player.actor.stat['WombSeedBed']",
      help1:  "modules/pregnancy:command_help/seedbed",
      min:    0,
      max:    10,
      order:  20,
      action: ->(v) { FrameworkUtils.custom_state_edit("WombSeedBed", v) }
    )
    #Toggle variable
    register_command(
      group:  :PREGNANCY,
      type:   :toggle,
      key:    "Protect Pregnancy",
      label:  "modules/pregnancy:commands/protect",
      state:  "$cheat_protect_pregnancy", #toggle variable
      global: false,
      help1:  "modules/pregnancy:command_help/protect",
      order:  30
    )
    #Sub-sub Menu Link
    register_command(
      group:  :PREGNANCY,
      type:   :scene,
      key:    :impregnate,
      label:  "modules/pregnancy:commands/impreg",
      name:   "CheatMenuImpregnate",
      dict:   :IMPREGNATE,
      order:  40,
      menu1:  "modules/pregnancy:menu_help/impreg_menu1",
      menu4:  "modules/pregnancy:menu_help/impreg_menu4"
      )
    #Sub-sub Menu Items =====================================
    register_command(
      group:  :IMPREGNATE,
      type:   :action,
      key:    "Human", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/impreg/human",
      color:  -> { $game_player.actor.baby_race == "Human" ? 16 : 0 },
      action: -> { MenuFramework::Pregnancy.impregnate("Human") },
      order:  10
    )
    register_command(
      group:  :IMPREGNATE,
      type:   :action,
      key:    "Moot", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/impreg/moot",
      color:  -> { $game_player.actor.baby_race == "Moot" ? 16 : 0 },
      action: -> { MenuFramework::Pregnancy.impregnate("Moot") },
      order:  20
    )
    register_command(
      group:  :IMPREGNATE,
      type:   :action,
      key:    "Deepone", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/impreg/deepone",
      color:  -> { $game_player.actor.baby_race == "Deepone" ? 16 : 0 },
      action: -> { MenuFramework::Pregnancy.impregnate("Deepone") },
      order:  30
    )
    register_command(
      group:  :IMPREGNATE,
      type:   :action,
      key:    "Fishkind", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/impreg/fishkind",
      color:  -> { $game_player.actor.baby_race == "Fishkind" ? 16 : 0 },
      action: -> { MenuFramework::Pregnancy.impregnate("Fishkind") },
      order:  40
    )
    register_command(
      group:  :IMPREGNATE,
      type:   :action,
      key:    "Orkind", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/impreg/orkind",
      color:  -> { $game_player.actor.baby_race == "Orkind" ? 16 : 0 },
      action: -> { MenuFramework::Pregnancy.impregnate("Orkind") },
      order:  50
    )
    register_command(
      group:  :IMPREGNATE,
      type:   :action,
      key:    "Goblin", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/impreg/goblin",
      color:  -> { $game_player.actor.baby_race == "Goblin" ? 16 : 0 },
      action: -> { MenuFramework::Pregnancy.impregnate("Goblin") },
      order:  60
    )
    register_command(
      group:  :IMPREGNATE,
      type:   :action,
      key:    "Abomination", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/impreg/abomination",
      color:  -> { $game_player.actor.baby_race == "Abomination" ? 16 : 0 },
      action: -> { MenuFramework::Pregnancy.impregnate("Abomination") },
      order:  70
    )
    register_command(
      group:  :IMPREGNATE,
      type:   :action,
      key:    "Clear", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/clear",
      help1:  "modules/pregnancy:command_help/clear1",
      help2:  "modules/pregnancy:command_help/clear2",
      help4:  "menu:command_help/execute",
      color:  -> { $game_player.actor.preg_level == 0 ? 8 : 0 },
      action: -> { $game_player.actor.cleanup_after_birth },
      enable: -> { !$cheat_protect_pregnancy },
      order:  80

    )
    #========================================================
    #Conditional Commands (hidden if not pregnant)
    register_command(
      group:  :PREGNANCY,
      type:   :info,
      key:    "BabyRace", #should be unique to this dictionary
      label:  "modules/pregnancy:info/babyRace",
      state:  "$game_player.actor.baby_race",
      hide:   -> { $game_player.actor.preg_level == 0 },
      order:  50
    )
    register_command(
      group:  :PREGNANCY,
      type:   :edit_num,
      key:    "PregRemaining", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/days",
      state:  "$game_player.actor.preg_whenGiveBirth?",
      help1:  "modules/pregnancy:command_help/length1",
      help2:  "modules/pregnancy:command_help/length2",
      hide:   -> { $game_player.actor.preg_level == 0 },
      min:    0,
      max:    -> { $game_player.actor.preg_cycle.inject(0, :+) },
      order:  60,
      action: ->(v) { MenuFramework::Pregnancy.update_pregdays(v) }
    )
    register_command(
      group:  :PREGNANCY,
      type:   :edit_num,
      key:    "Baby Health", #should be unique to this dictionary
      label:  "modules/pregnancy:commands/health",
      state:  "$game_player.actor.baby_health",
      hide:   -> { $game_player.actor.preg_level == 0 },
      min:    0,
      max:    5000,
      order:  70,
      action: ->(v) { $game_player.actor.baby_health = v }
    )
  end

  #Custom functions if too complex for lambda.
  module Pregnancy
    def self.impregnate(baby_race)
      actor = $game_player.actor
      actor.cleanup_after_birth
      actor.force_pregnancy(baby_race)
    end

    def self.update_pregdays(days)
      actor = $game_player.actor
      current = actor.preg_whenGiveBirth?
      target  = days
      diff = current - target
      return if diff == 0

      #Editing date of conception, not length of pregnancy. 
      #Length is based on an array built at conception - increase pregnancy difficultyinstead.
      preg = Game_Date.new(*actor.preg_date)
      if diff > 0
        preg.decDays(diff)
      elsif diff < 0
        preg.addDays(-diff)
      end

      actor.preg_date = preg.date
      actor.update_pregnancy
    end
  end
end

#Functions in FrameworkUtils check per update.
module FrameworkUtils
  def self.protect_pregnancy
    return unless self.ingame?
    return if $game_player.actor.preg_level == 0

    $game_player.actor.baby_health += 999 if $cheat_protect_pregnant
  end
end

#Grounded in original location for variable/function access.
class Game_Actor
  #Based set_preg(race,day=0) in Reproduction.rb
  def force_pregnancy(baby_race, day = 0)
    return if empregnanted?
    $story_stats["dialog_preg_exped"] = 1
    @preg_date = $game_date.date
    @preg_race = baby_race
    # Directly force result
    @baby_race = baby_race  
    ####
    set_baby_health
    add_state("WombSeedBed") if System_Settings::RACE_PREG_GEN_SEEDBED_LEVEL[@preg_race]
    @preg_day = day
    @preg_cycle = create_preg_cycle
    set_preg_schedule
    update_preg_level
  end
end

#Overwrites create_preg_cycle in Reproduction.rb
module Reproduction
  def create_preg_cycle
		seedbed_level = self.stat["WombSeedBed"]
		seedbed_level_deduction=System_Settings::RACE_SEX_SETTING[@baby_race][1][seedbed_level]
    #Override difficulty if $cheat_pregnancy_difficulty set.
    difficulty = $cheat_pregnancy_difficulty >= 0 ? $cheat_pregnancy_difficulty : $story_stats["Setup_Hardcore"]
		cycle_template = System_Settings::RACE_SEX_SETTING[@baby_race][0][difficulty]
    ####
		preg_cycle=Array.new
		for i in 0...cycle_template.length-1
			daysNeeded = [cycle_template[i].to_a.sample-seedbed_level_deduction, 1].max # line changed
			preg_cycle.push(daysNeeded)
		end
		preg_cycle.push(cycle_template.last.to_a.sample)
		preg_cycle
  end
end
