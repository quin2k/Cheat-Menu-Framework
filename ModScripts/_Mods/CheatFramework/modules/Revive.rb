FrameworkModule = {
  name:       "Revive Menu", 
  key:        :revive_menu, 
  menu:       :REVIVE #Group key.
}

module MenuFramework
  module SUBMENU
    # Menu Hook into "Game Tweaks"
    register_command(
      group:  :NPC,
      type:   :scene,
      key:    :revive_menu,
      label:  "modules/revive:commands/revive", 
      name:   "CheatMenuReviveNPC",
      dict:   :REVIVE,
      menu3:  "modules/revive:command/revive/menu3",
      menu4:  "modules/revive:command/revive/menu4"
    )


    # List of NPC Variables
    REVIVE_LIST = [
      "UniqueCharUniqueCecily",
      "UniqueCharUniqueGrayRat",
      "UniqueCharUniqueCocona",
      "UniqueCharUniqueLisa",
      "UniqueCharUniqueElise",
      "UniqueCharUniqueMaani",
      "UniqueCharUniqueDavidBorn",
      "UniqueCharUniquePigBobo",
      "UniqueCharUniqueAdam",
      "UniqueCharUniqueMilo",
      "UniqueCharUniqueSeaWitch",
      "UniqueCharUniqueTeller",
      "UniqueCharUniqueHappyMerchant",
      "UniqueCharUniqueTavernWaifu",
      "UniqueCharUniqueFerrum",
      "UniqueCharUniqueCaptainEdward",
      "UniqueCharUniqueFatdalf",
      "UniqueCharNoerSnowflake",

      #"UniqueChar_NorthFL_SGT",
      #"UniqueChar_NFL_MerCamp_Leader",
      #"UniqueCharNoerRelayOut_PoorBoy",
      #"UniqueChar_FishTownT_Shaman"
      #"UniqueCharUniqueKillerRabbit"
      #"UniqueCharUniqueOgreWarBoss"
      #"UniqueCharUniqueGangBoss"
      #"UniqueCharSMCloudVillage_Boss"
      #"UniqueCharSMCloudVillage_BossAtk"
      #"UniqueChar_OrcSlaveMaster"
    ]
    REVIVE_LIST.each do |char_key|
      register_command(
        group:  :REVIVE,
        type:   :action,
        key:    char_key,
        color:  -> { $story_stats[char_key] != -1 ? 8 : 0 },
        label:  "modules/revive:NPC/#{char_key}",
        action: -> {
          $story_stats[char_key] = 0
        }
      )
    end    
  end
end

