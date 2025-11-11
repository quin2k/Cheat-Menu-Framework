FrameworkModule = {
  name:       "Race Changer", 
  key:         :edit_race, 
  menu:       :RACE #Group key.
}

module MenuFramework
  module SUBMENU
    #==========================================
    # Character Editing Menu
    #==========================================
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
    
    #------------------------------------------
    # Race Commands 
    #------------------------------------------
    register_command(
      type:   :action,
      key:    "Human", #should be unique to this dictionary
      label:  "modules/character:commands/race/human",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "Human" ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("Human") },
      order:  10
    )
    register_command(
      type:   :action,
      key:    "Moot", #should be unique to this dictionary
      label:  "modules/character:commands/race/moot",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "Moot" ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("Moot") },
      order:  20
    )
    register_command(
      type:   :action,
      key:    "Deepone", #should be unique to this dictionary
      label:  "modules/character:commands/race/deepone",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "PreDeepone" ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("Deepone") },
      order:  30
    )
    register_command(
      type:   :action,
      key:    "True Deepone", #should be unique to this dictionary
      label:  "modules/character:commands/race/truedeepone",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "TrueDeepone" ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("TrueDeepone") },
      order:  40
    )
    register_command(
      type:   :action,
      key:    "Human Abomination", #should be unique to this dictionary
      label:  "modules/character:commands/race/abom_human",
      color:  -> { ($game_player.actor.stat["RaceRecord"] == "Abomination" && $game_player.actor.stat["Race"] == "Human") ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("HumanAbomination") ; $game_party.lose_item("ItemBluePotion",3) },
      order:  50
    )
    register_command(
      type:   :action,
      key:    "Moot Abomination", #should be unique to this dictionary
      label:  "modules/character:commands/race/abom_moot",
      color:  -> { ($game_player.actor.stat["RaceRecord"] == "Abomination" && $game_player.actor.stat["Race"] == "Moot") ? 16 : 0 },
      action: -> { $game_player.actor.reBirthSetRace("MootAbomination") ; $game_party.lose_item("ItemBluePotion",3) },
      order:  60
    )

    #------------------------------------------
    # Race Skills 
    #------------------------------------------
    register_command(
      type:   :scene,
      key:    "Race Skills", #should be unique to this dictionary
      label:  "modules/character:commands/race/skills",
      color:  -> { ["Abomination", "TrueDeepone", "PreDeepone"].include?($game_player.actor.stat["RaceRecord"]) ? 0 : 8 },
      name:   "CheatMenuRaceSkills",
      dict:   :RACESKILL
    )
    register_command(
      group:  :RACESKILL,
      type:   :toggle,
      key:    "Sea Witch Awaken", #should be unique to this dictionary
      label:  "modules/character:commands/race/skills/deepone",
      state:  "$game_player.actor.skill_learn?($data_skills[65])",
      color:  -> { ["TrueDeepone", "PreDeepone"].include?($game_player.actor.stat["RaceRecord"]) ? 0 : 8 },
      action: -> { FrameworkUtils.skill_toggle(65) }, # BasicDeepOne
    )
    register_command(
      group:  :RACESKILL,
      type:   :toggle,
      key:    "Abom Desecrate Skill", #should be unique to this dictionary
      label:  "modules/character:commands/race/skills/abomeat",
      state:  "$game_player.actor.skill_learn?($data_skills[67])",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "Abomination" ? 0 : 8 },
      action: -> { FrameworkUtils.skill_toggle(67) } # BasicAbomEatDed
    )
    register_command(
      group:  :RACESKILL,
      type:   :toggle,
      key:    "Abom Tendril Whip", #should be unique to this dictionary
      label:  "modules/character:commands/race/skills/abomgrab",
      state:  "$game_player.actor.skill_learn?($data_skills[66])",
      color:  -> { $game_player.actor.stat["RaceRecord"] == "Abomination" ? 0 : 8 },
      action: -> { FrameworkUtils.skill_toggle(66) } # BasicAbomGrab
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
