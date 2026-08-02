FrameworkModule = {
  name:       "Summons",
  key:        :summons,
  menu:       :NONE,
  depends_on: []
}

#--------------------------------------------------------------------------
# Menu Commands
#--------------------------------------------------------------------------
MenuFramework::MENU.register_command(
  type:   :scene,
  key:    :summon,
  label:  "modules/invedit:commands/summon",
  name:   "CheatMenuSummon",
  dict:   :SUMMON,
  order:  3
)

#--------------------------------------------------------------------------
# Arena Summons - labeled with system names, not translated.
#--------------------------------------------------------------------------
MenuFramework::SUBMENU.register_command(
  group:  :SUMMON,
  type:   :scene,
  key:    :arena,
  label:  -> { "Arena" },
  name:   "CheatMenuSummon_Arena",
  dict:   :SUMMON_ARENA,
  order:  200
)

# Arena fights read story points (cannon/bios/pillar) that only exist on the real arena map.
# stub_arena_storypoints (below) fakes them so these are summonable from anywhere.
ARENA_STORYPOINTS = %w[CannonCur DualBios CenterPillar]
ARENA_SUMMONS = %w[
  ArenaEastColossus ArenaDeepTerror ArenaSexBeast ArenaFemdom ArenaFailedAdv
  ArenaHoboDudes1 ArenaHoboDudes2 ArenaHoboDudes3
  ArenaOrkindBro1 ArenaOrkindBro2 ArenaOrkindBro3
  ArenaCecilyRBQ ArenaWildApeM1 ArenaWildDog1 ArenaWildDog2 ArenaWildDog3
  ArenaSwine1 ArenaTeamRBQ1 ArenaTeamRBQ2
]

ARENA_SUMMONS.sort.each_with_index do |event_key, j|
  MenuFramework::SUBMENU.register_command(
    group:  :SUMMON_ARENA,
    type:   :action,
    key:    event_key,
    label:  -> { event_key },
    order:  (j + 1) * 10,
    action: -> { FrameworkUtils.summon_and_close(event_key) }
  )
end

# NPC key -> [base template to spawn, graphic name, graphic index]. These have no event-lib
# template of their own, so a safe base template is spawned and reskinned into them instead.
REKSIN_SUMMONS = {
  "MobHumanRaperM"                => ["NeutralHumanCommonM", "-char-M-REGULAR02", 4],
  "NeutralHumanPrisonerRaperM"    => ["NeutralHumanCommonM", "-char-M-REGULAR04", 4],
  "NeutralHumanPrisonMinerRaperM" => ["NeutralHumanCommonM", "-char-M-REGULAR01", 5]
}

#--------------------------------------------------------------------------
# Companion Disband Dialogue Patch
#--------------------------------------------------------------------------
# Elise/Lisa's talk-scripts don't offer a Disband option like Cecily/GrayRat do. Patches in a
# menu entry and its case branch at load time instead of replacing the files.
module FrameworkUtils
  DISBANDABLE_COMPANION_SCRIPTS = ["Data/HCGframes/event/CompElise.rb", "Data/HCGframes/event/CompLisa.rb"]

  DISBAND_MENU_ANCHOR = /(tmpQuestList << \[\$game_text\["commonComp:Companion\/Wait"\][^\r\n]*\r?\n)/
  DISBAND_MENU_ENTRY  = "\ttmpQuestList << [$game_text[\"commonComp:Companion/Disband\"]\t\t\t,\"Disband\"] if get_character(0).instance_variable_get(:@cheat_summoned)\r\n"

  DISBAND_CASE_ANCHOR = /(get_character\(0\)\.follower\[1\]\s*=0\r?\n)(\s*end)/
  DISBAND_CASE_BLOCK = "\twhen \"Disband\"\r\n" \
    "\t\tcall_msg(\"common:Lona/Decide_optB\")\r\n" \
    "\t\tcam_center(0)\r\n" \
    "\t\tif $game_temp.choice == 1\r\n" \
    "\t\t\tportrait_hide\r\n" \
    "\t\t\tchcg_background_color(0,0,0,0,7)\r\n" \
    "\t\t\t\tportrait_off\r\n" \
    "\t\t\t\tget_character(0).set_this_companion_disband\r\n" \
    "\t\t\tchcg_background_color(0,0,0,255,-7)\r\n" \
    "\t\t\treturn portrait_hide\r\n" \
    "\t\tend\r\n"

  # Falls back to the untouched script if either anchor line has since changed upstream.
  def self.patch_companion_disband(script)
    return script unless script =~ DISBAND_MENU_ANCHOR && script =~ DISBAND_CASE_ANCHOR
    script = script.sub(DISBAND_MENU_ANCHOR) { "#{$1}#{DISBAND_MENU_ENTRY}" }
    script.sub(DISBAND_CASE_ANCHOR) { "#{$1}#{DISBAND_CASE_BLOCK}#{$2}" }
  end
end

class Object
  alias_method :load_script_cheat_summon_dialogue, :load_script
  def load_script(path)
    return load_script_cheat_summon_dialogue(path) unless FrameworkUtils::DISBANDABLE_COMPANION_SCRIPTS.include?(path)
    use_alternative = FileGetter::COMPRESSED && File.file?(path)
    real_path = $mod_load_script.fetch(path, path)
    script = use_alternative ? File.read(real_path) : File.open(real_path, 'rb', &:read)
    self.instance_eval(FrameworkUtils.patch_companion_disband(script), path)
  rescue => ex
    msgbox ex.message + "\n" + ex.backtrace.join("\n")
  end
end

#--------------------------------------------------------------------------
# Summon Placement
#--------------------------------------------------------------------------
module FrameworkUtils
  # Walks from the player until blocked, so summons land in front of them instead of on top.
  def self.summon_target_tile(max_distance = 8)
    actor = $game_player
    x, y = actor.x, actor.y
    d = actor.direction
    max_distance.times do
      break unless actor.passable?(x, y, d)
      x = $game_map.round_x_with_direction(x, d)
      y = $game_map.round_y_with_direction(y, d)
    end
    [x, y]
  end

  # Drops straight back to the map on success.
  def self.summon_and_close(npc_key)
    SndLib.sound_TeslaHit # plays immediately, before the summon itself finishes
    tx, ty = summon_target_tile
    stub = stub_arena_storypoints if ARENA_SUMMONS.include?(npc_key)
    base_key, graphic_name, graphic_index = REKSIN_SUMMONS[npc_key]
    event = $game_map.summon_event(base_key || npc_key, tx, ty)
    stub.delete if stub
    if event
      if base_key
        event.set_npc(npc_key)
        event.set_graphic(graphic_name, graphic_index)
      end
      event.instance_variable_set(:@cheat_summoned, true)
      event.give_light("cyanTesla")
      @glowing_npcs << { event: event, revert_at: Graphics.frame_count + GLOW_DURATION }
    end
    exit_cheat_menu
  rescue => e
    p "Summon error #{npc_key}: #{e.message}"
  end

  # Pre-seeds record_companion_name_front/_back so both companions' cross-checks pass before either exists.
  def self.summon_cecily_and_grayrat
    $game_player.record_companion_name_front = "UniqueGrayRat"
    $game_player.record_companion_name_back = "UniqueCecily"
    SndLib.sound_TeslaHit
    tx, ty = summon_target_tile
    ["UniqueGrayRat", "UniqueCecily"].each do |npc_key|
      event = $game_map.summon_event(npc_key, tx, ty)
      next unless event
      event.instance_variable_set(:@cheat_summoned, true)
      event.give_light("cyanTesla")
      @glowing_npcs << { event: event, revert_at: Graphics.frame_count + GLOW_DURATION }
    end
    exit_cheat_menu
  rescue => e
    p "Summon error UniqueCecily+GrayRat: #{e.message}"
  end

  # Spawns a throwaway event and points the arena story points at it (deleted right after), instead
  # of touching real story points. ARENA_MAP_VERDICT caches real-vs-fake once per map.
  ARENA_MAP_VERDICT = {}

  def self.stub_arena_storypoints
    map_id = $game_map.map_id
    points = $game_map.list_storypoints
    verdict = ARENA_MAP_VERDICT[map_id] ||= (ARENA_STORYPOINTS.all? { |name| points.key?(name) } ? :real : :fake)
    return nil if verdict == :real

    stub = $game_map.summon_event("NeutralHumanCommonM", $game_player.x, $game_player.y)
    return nil unless stub
    stub.instance_variable_set(:@summon_data, {PlayerMatch: true})
    ARENA_STORYPOINTS.each { |name| points[name] = [0, 0, stub.id] }
    stub
  end

  # Pops the scene stack back to Scene_Map when possible, instead of rebuilding it from scratch.
  def self.exit_cheat_menu
    10.times do
      return if SceneManager.scene_is?(Scene_Map)
      break if SceneManager.scene.nil?
      SceneManager.return
    end
    return if SceneManager.scene_is?(Scene_Map)
    SceneManager.clear
    SceneManager.goto(Scene_Map)
  end

  GLOW_DURATION = 30 # frames, ~0.5s
  @glowing_npcs = []

  def self.update_charge_effects
    return if @glowing_npcs.empty?
    now = Graphics.frame_count
    due, active = @glowing_npcs.partition { |e| now >= e[:revert_at] }
    due.each { |e| e[:event].drop_light }
    @glowing_npcs = active
  end
end

class CheatFramework
  alias_method :hotkey_trigger_summon_charge, :hotkey_trigger
  def hotkey_trigger
    hotkey_trigger_summon_charge
    FrameworkUtils.update_charge_effects
  end
end

# Skips the kill-tally hook for a cheat-summoned NPC, read via @summon_data[:user].
class Game_Event
  alias_method :trace_over_kill_cheat_summon, :traceOverKill
  def traceOverKill(user, temp_killer, mora=nil, tarState=nil)
    victim = @summon_data && @summon_data[:user]
    return if victim && victim.instance_variable_get(:@cheat_summoned)
    trace_over_kill_cheat_summon(user, temp_killer, mora, tarState)
  end
end

#--------------------------------------------------------------------------
# Dynamic Summon Menu
#--------------------------------------------------------------------------
module MenuFramework
  module Summons
    extend self

    # NPC key -> real event-lib template, for cases where they differ (e.g. followers).
    MANUAL_SUMMONS = {
      "UniqueElise" => "CompExtUniqueElise",
      "UniqueLisa"  => "CompExtUniqueLisa",
      # Alpha-design ogre boss cut from the game, distinct from UniqueOgreWarBoss. Placed in Orc for now.
      "OgreGayBoss" => "OgreGayBoss"
    }

    # Abom* traps and GoblinSlave* crash when summoned standalone (no fight target / no master NPC).
    # UniqueCecily/UniqueGrayRat/HumanBaby are handled elsewhere (combined entry / dropped with Baby).
    EXCLUDED_SUMMONS = %w[
      AbomManagerTrap AbomSpiderTrap AbomCreatureGroundSpore
      AbomCreatureTentacleHide AbomCreatureSpiderHideTrap AbomCreatureCocoon
      GoblinSlaveWarrior GoblinSlaveSpear GoblinSlaveClub GoblinSlaveBow
      UniqueCecily UniqueGrayRat HumanBaby
    ]

    # Folders left out of the menu entirely.
    SKIPPED_FOLDERS = %w[Baby]

    def build_dynamic_summons
      summonable_keys = []

      $data_npcs.each do |npc|
        next unless npc
        summonable_keys << npc[0]
      end

      entries = []
      $data_EventLib.each_key do |key|
        next if EXCLUDED_SUMMONS.include?(key)
        entries << [key, key] if summonable_keys.include?(key)
      end
      MANUAL_SUMMONS.each { |npc_key, event_key| entries << [npc_key, event_key] }
      REKSIN_SUMMONS.each_key { |npc_key| entries << [npc_key, npc_key] }
      entries << ["UniqueCecily+GrayRat", :cecily_and_grayrat]

      folder_map = Hash.new { |h, k| h[k] = [] }

      entries.each do |label, event_key|
        camel = label.split(/(?=[A-Z])/).reject(&:empty?)
        next if camel.empty?

        # Rename some folders for better grouping
        folder = {"Swine"=>"Wild","Player"=>"Baby","Deepone"=>"Fishkind","Gang"=>"Human","Ogre"=>"Orc"}.fetch(camel.first, camel.first)

        folder_map[folder] << [label, event_key]
      end

      SKIPPED_FOLDERS.each { |folder| folder_map.delete(folder) }

      folder_map.keys.sort.each_with_index do |folder, i|
        dict = :"SUMMON_#{folder.upcase}"

        MenuFramework::SUBMENU.register_command(
          group:  :SUMMON,
          type:   :scene,
          key:    folder,
          label:  -> {folder},
          name:   "CheatMenuSummon_#{folder}",
          dict:   dict,
          order:  (i + 1) * 10
        )

        # The :cecily_and_grayrat sentinel routes to summon_cecily_and_grayrat instead of a normal
        # summon, since Cecily and GrayRat each require the other already set as a companion.
        folder_map[folder].sort_by { |label, _| label }.each_with_index do |(label, event_key), j|
          MenuFramework::SUBMENU.register_command(
            group:  dict,
            type:   :action,
            key:    label,
            label:  -> {label},
            order:  (j + 1) * 10,
            action: -> {
              event_key == :cecily_and_grayrat ? FrameworkUtils.summon_cecily_and_grayrat : FrameworkUtils.summon_and_close(event_key)
            }
          )
        end
      end
    end
  end
end

class << DataManager
  alias_method :cf_summon_load_db, :load_database
  def load_database
    cf_summon_load_db
    MenuFramework::Summons.build_dynamic_summons
  end
end
