FrameworkModule = {
  name:       "Sexual Stats", #Scene/Window names would be Window_CheatMenuEdit_Lona.
  key:        :sexual, #Menu key, also used to label source module.
  menu:       :SEXUAL, #Dictionary / Group key.
  depends_on: []
}
module MenuFramework
  module SUBMENU
    #==========================================
    # Character Editing Menu
    #==========================================
    register_command(
      group:  :LONA,
      type:   :scene,
      key:    :sexual,
      label:  "modules/character:commands/sexual",
      menu1:  "menu:window_help/character1",
      name:   "CheatMenuSexual",
      dict:   :SEXUAL,
    )
    #------------------------------------------
    # Damage 
    #------------------------------------------
    register_command(
      group:  :SEXUAL,
      type:   :edit_num,
      key:    "Vag Damage",
      label:  "modules/character:commands/sexual/dedit/v",
      state:  "$game_player.actor.vag_damage",
      enable: -> { $game_player.actor.actStat.get_stat('vag_damage', 3) != 0 },
      min:    0,
      max:    5000,
      action: ->(v) { $game_player.actor.vag_damage = v }
    )
    register_command(
      group:  :SEXUAL,
      type:   :edit_num,
      key:    "Urethra Damage",
      label:  "modules/character:commands/sexual/dedit/u",
      state:  "$game_player.actor.urinary_damage",
      enable: -> { $game_player.actor.actStat.get_stat('urinary_damage', 3) != 0 },
      min:    0,
      max:    5000,
      action: ->(v) { $game_player.actor.urinary_damage = v }
    )
    register_command(
      group:  :SEXUAL,
      type:   :edit_num,
      key:    "Anal Damage",
      label:  "modules/character:commands/sexual/dedit/a",
      state:  "$game_player.actor.anal_damage",
      enable: -> { $game_player.actor.actStat.get_stat('anal_damage', 3) != 0 },
      min:    0,
      max:    5000,
      action: ->(v) { $game_player.actor.anal_damage = v }
    )
    #------------------------------------------
    # Damage Toggles
    #------------------------------------------
    register_command(
      group:  :SEXUAL,
      type:   :toggle,
      key:    "Toggle Vag Damage",
      label:  "modules/character:commands/sexual/dtoggle/v",
      state:  "$game_player.actor.actStat.get_stat('vag_damage', 3) == 0",
      global: false, 
      action: -> {
                  if $game_player.actor.actStat.get_stat('vag_damage', 3) == 0
                    $game_player.actor.actStat.set_stat('vag_damage', 10000, 3)
                  else
                    $game_player.actor.actStat.set_stat('vag_damage', 0, 3)
                  end
                  $game_player.actor.refresh
    })
    register_command(
      group:  :SEXUAL,
      type:   :toggle,
      key:    "Toggle Urethra Damage",
      label:  "modules/character:commands/sexual/dtoggle/u",
      state:  "$game_player.actor.actStat.get_stat('urinary_damage', 3) == 0",
      global: false, 
      action: -> {
                  if $game_player.actor.actStat.get_stat('urinary_damage', 3) == 0
                    $game_player.actor.actStat.set_stat('urinary_damage', 10000, 3)
                  else
                    $game_player.actor.actStat.set_stat('urinary_damage', 0, 3)
                  end
                  $game_player.actor.refresh
    })
    register_command(
      group:  :SEXUAL,
      type:   :toggle,
      key:    "Toggle Anal Damage",
      label:  "modules/character:commands/sexual/dtoggle/a",
      state:  "$game_player.actor.actStat.get_stat('anal_damage', 3) == 0",
      global: false, 
      action: -> {
                  if $game_player.actor.actStat.get_stat('anal_damage', 3) == 0
                    $game_player.actor.actStat.set_stat('anal_damage', 10000, 3)
                  else
                    $game_player.actor.actStat.set_stat('anal_damage', 0, 3)
                  end
                  $game_player.actor.refresh
    })

    register_command(
      group:  :SEXUAL,
      type:   :action,
      key:    "Reset Sex Record",
      label:  "modules/character:commands/sexual/reset",
      help1:  "modules/character:command_help/sexual/reset",
      action: -> { FrameworkUtils.clear_sex_record }
    )

  end
end



module FrameworkUtils
  def self.clear_sex_record
    $story_stats["dialog_vag_virgin"] = 1
    $story_stats["dialog_anal_virgin"] = 1

    $story_stats["sex_record_first_mouth"]	= Array.new
    $story_stats["sex_record_first_vag"]	= Array.new
    $story_stats["sex_record_first_anal"]	= Array.new
    $story_stats["sex_record_last_mouth"]	= Array.new
    $story_stats["sex_record_last_vag"]	= Array.new
    $story_stats["sex_record_last_anal"]	= Array.new
    $story_stats["sex_record_partner_count"]= Hash.new(0)
    $story_stats["sex_record_race_count"]	= Hash.new(0)

    $story_stats["record_giveup_PeePoo"]	= 0
    $story_stats["record_Rebirth"]		= 0
    $story_stats["sex_record_cunnilingus_given_count"] = 0
    $story_stats["sex_record_whore_job"]	= 0
    $story_stats["sex_record_kissed"]	= 0
    $story_stats["sex_record_privates_seen"] = 0
    $story_stats["sex_record_groped"]	= 0
    $story_stats["sex_record_semen_swallowed"] = 0
    $story_stats["sex_record_frottage"]	= 0
    $story_stats["sex_record_biggest_gangbang"] = 0
    $story_stats["sex_record_seen_peeing"]	= 0
    $story_stats["sex_record_peed"]		= 0
    $story_stats["sex_record_shat"]		= 0
    $story_stats["sex_record_cumshotted"]	= 0
    $story_stats["sex_record_seen_shat"]	= 0
    $story_stats["sex_record_torture"]	= 0
    $story_stats["sex_record_eating_fecal"]	= 0
    $story_stats["sex_record_cunnilingus_taken"] = 0
    $story_stats["sex_record_coma_sex"]	= 0
    $story_stats["sex_record_mindbreak"]	= 0
    $story_stats["sex_record_defecate_incontinent"] = 0
    $story_stats["sex_record_urinary_incontinence"] = 0
    $story_stats["sex_record_anal_dilatation"] = 0
    $story_stats["sex_record_vag_dilatation"] = 0
    $story_stats["sex_record_urinary_dilatation"] = 0
    $story_stats["sex_record_BreastFeeding"] = 0
    $story_stats["sex_record_MilkSplash"]	= 0
    $story_stats["sex_record_MilkSplash_incontinence"] = 0
    $story_stats["sex_record_pregnancy"]	= 0
    $story_stats["sex_record_orgasm"]	= 0
    $story_stats["sex_record_orgasm_Mouth"]	= 0
    $story_stats["sex_record_orgasm_Torture"] = 0
    $story_stats["sex_record_orgasm_Vag"]	= 0
    $story_stats["sex_record_orgasm_Milking"] = 0
    $story_stats["sex_record_orgasm_Pee"]	= 0
    $story_stats["sex_record_orgasm_Poo"]	= 0
    $story_stats["sex_record_orgasm_Birth"]	= 0
    $story_stats["sex_record_orgasm_Anal"]	= 0
    $story_stats["sex_record_orgasm_Semen"]	= 0
    $story_stats["sex_record_orgasm_Breast"] = 0
    $story_stats["sex_record_orgasm_Shame"]	= 0
    $story_stats["sex_record_enemaed"]	= 0
    $story_stats["sex_record_analbeads"]	= 0
    $story_stats["sex_record_pussy_wash"]	= 0
    $story_stats["sex_record_anal_wash"]	= 0
    $story_stats["sex_record_golden_shower"] = 0
    $story_stats["sex_record_piss_drink"]	= 0

    $story_stats["record_CoconaVag"]	= 0
    $story_stats["record_CoconaOgrasm"]	= 0
    $story_stats["record_CoconaPeeWith"]	= 0

    $story_stats["sex_record_groin_harassment"] = 0
    $story_stats["sex_record_butt_harassment"] = 0
    $story_stats["sex_record_boob_harassment"] = 0

    $story_stats["sex_record_handjob_count"] = 0
    $story_stats["sex_record_anal_count"]	= 0
    $story_stats["sex_record_vaginal_count"] = 0
    $story_stats["sex_record_mouth_count"]	= 0
    $story_stats["sex_record_cumin_vaginal"] = 0
    $story_stats["sex_record_cumin_anal"]	= 0
    $story_stats["sex_record_cumin_mouth"]	= 0
    $story_stats["sex_record_masturbation_count"] = 0
    $story_stats["sex_record_FloorClearnPee"] = 0
    $story_stats["sex_record_FloorClearnScat"] = 0
    $story_stats["sex_record_FloorClearnCums"] = 0

    $story_stats["sex_record_miscarriage"]	= 0
    $story_stats["sex_record_baby_birth"]	= 0

    $story_stats["sex_record_birth_Abomination"] = 0
    $story_stats["sex_record_birth_Goblin"]	= 0
    $story_stats["sex_record_birth_Human"]	= 0
    $story_stats["sex_record_birth_Deepone"] = 0
    $story_stats["sex_record_birth_Moot"]	= 0
    $story_stats["sex_record_birth_Orkind"]	= 0
    $story_stats["sex_record_birth_Fishkind"] = 0

    $story_stats["sex_record_birth_PotWorm"] = 0
    $story_stats["sex_record_birth_MoonWorm"] = 0
    $story_stats["sex_record_birth_PolypWorm"] = 0
    $story_stats["sex_record_birth_HookWorm"] = 0
    $story_stats["sex_record_birth_BabyLost"] = 0
  end
end