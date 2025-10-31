#===============================================================================
###	Main project file
### Mod: Cheat Menu Framework
###	Author: Kenny567
#===============================================================================

#Mod namespace
class CheatsMod
  attr_reader :info
  attr_reader :config
  attr_reader :config_dir
  attr_reader :load_order
  attr_accessor :modules
  attr_accessor :addons
  attr_accessor :hotkey

  def initialize
    @info = $mod_manager.mods["cheatmenu"]
    @config = nil
    @config_dir = nil
    @load_order = nil
    @modules = {}
    @hotkey = nil
  end

  def init_config_dir
    @config_dir = System_Settings::USER_DATA_PATH + "Cheat Menu"

    # Check if the directory exists
    unless Dir.exist?(@config_dir)
      # Create the directory if it doesn't exist
      Dir.mkdir(@config_dir)
      log("Directory created: #{@config_dir}")
    else
      log("Directory already exists: #{@config_dir}")
    end
  end

  def init_config(ini_file)
    @config = CheatsConfig.new(ini_file)
  end

  def init_modules
    modules_path = File.join(@info.path, "modules")

    unless Dir.exist?(modules_path)
      log("[CheatsMod] No modules folder found at #{modules_path}")
      return
    end

    log("[CheatsMod] Loading modules from: #{modules_path}")
    loaded = []

    Dir.entries(modules_path).each do |entry|
      next if entry == "." || entry == ".." || entry.start_with?("_")

      full = File.join(modules_path, entry)
      next if entry.start_with?("_")

      if File.directory?(full)
        bootstrap = File.join(full, "bootstrap.rb")

        # 1. Load bootstrap first (if exists)
        if File.exist?(bootstrap)
          load_script(bootstrap)
          loaded << "#{entry}/bootstrap.rb"
        end

        # 2. Then load all other Ruby files alphabetically
        Dir[File.join(full, "*.rb")].sort.each do |subfile|
          next if subfile == bootstrap
          load_script(subfile)
          loaded << "#{entry}/#{File.basename(subfile)}"
        end
      elsif entry.end_with?(".rb")
        load_script(full)
        loaded << entry
      end
    end

    log("[CheatsMod] Loaded #{loaded.size} module files")
  end

  def load_script(path)
    load path if File.exist?(path)
  rescue => e
    log("[CheatsMod] Failed to load #{path}: #{e.message}")
  end

  def init_load_order(file)
    unless File.exist?(file)
      default_load_order = [
        "DisplayPortrait"  , "UnlockTool"       , "UnequipItems"     ,
        "InvEdit"          , "Summons"          , "Race"             ,
        "Pregnancy"        , "StatsEdit"        , "HairColorEdit"    ,
        "MoralityEdit"     , "Legacy"           , "AbomSkills"       ,
        "DeepSkill"        , "Dirt"             , "InfiniteMainStats",
        "AutoBandage"      , "AutoClean"        , "InfiniteMoney"
      ]

      File.open(file, 'w') { 
        |lo_file| lo_file.write(JSON.encode(default_load_order)) 
      }
    end

    begin
      json_file = File.open(file)
      @load_order = JSON.decode(json_file.read)
    rescue => e
      puts "[CheatsMod] Failed to read load order (#{e.message}), using defaults."
      @load_order = default_load_order.dup
    ensure
      json_file.close if json_file
    end
  end

  def getText(text_flag)
    return $game_text["#{@info.id}:#{text_flag}"]
  end

  def log(msg)
    puts "[CheatsMod] #{msg}"
  end

  def get_resource(resource)
    return $mod_manager.get_resource(@info.id, resource)
  end

  #Include a single script
  def import(dir, file)
    FileGetter.load_from_list(FileGetter.getFileList(get_resource("#{dir}/#{file}.rb")))
  end

  #Include scripts from path
  def imports(dir)
    FileGetter.load_from_list(FileGetter.getFileList(get_resource("#{dir}/*.rb")))
  end

  #Expand cheat hotkeys
  #overridable function
  def cheat_triggers
    #empty so cheatmodules can override
  end
end

if $mod_cheats.nil?
  $mod_cheats = CheatsMod.new

  # Initialize Mod Config (Check config folder exists, create if not exist)
  $mod_cheats.init_config_dir

  #Import Load Order (creates default if no file)
  $mod_cheats.init_load_order("#{$mod_cheats.config_dir}/load_order.json")

  #Include Plugins class
  $mod_cheats.import("scripts", "Plugins")

  #Include Libraries
  $mod_cheats.imports("scripts/lib")
  
  #Include Other Mods
  $mod_cheats.imports("othermods")
  
  #Include project
  $mod_cheats.import("scripts", "Utils") # CheatUtils
  $mod_cheats.import("scripts", "System") # Cheat Config
  $mod_cheats.init_config("#{$mod_cheats.config_dir}/CheatSettings.ini")
  $mod_cheats.config.read_hotkey_menu
  $mod_cheats.import("scripts", "Menu") # Cheat Menu
  
  #Include Cheat Modules
  $mod_cheats.init_modules

  #Save Hotkey for future sessions
  #$mod_cheats.config.write_hotkey
end
