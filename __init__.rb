#===============================================================================
###	Main project file
### Mod: Cheat Menu Framework
###	Author: Kenny567
#===============================================================================

#Mod namespace
class CheatsMod
  attr_reader :info
  attr_reader :config_dir
  attr_reader :path
  attr_accessor :mods
  attr_accessor :sys
  attr_accessor :txt
  attr_accessor :hotkey
  attr_accessor :menu_stack

  def initialize
    @info = $mod_manager.mods["cheatmenu"]
    @path = $mod_manager.mods["cheatmenu"].path
    @sys = nil
    @config_dir = nil
    @hotkey = nil
    @mods = {}
    @menu_stack = []
  end


  def init_config_dir
    @config_dir = File.join(System_Settings::USER_DATA_PATH, "Cheat Menu")
    Dir.mkdir(@config_dir) unless Dir.exist?(@config_dir)
  end


  def init_modules
    modules_path = File.join(@info.path, "modules")
    @mods = CheatsModManager.new(modules_path, @sys)
    @mods.discover
    @mods.load_all
  end

  def load_script(file)
    path = File.join($mod_cheats.path, "scripts", file)
    load path if File.exist?(path)
  end

  def txt(text_flag)
    return $game_text["#{@info.id}:#{text_flag}"]
  end

  # Overridable function
  def cheat_triggers
    # Left blank for modules to override
  end
end


if $mod_cheats.nil?
  $mod_cheats = CheatsMod.new
  $mod_cheats.init_config_dir

  # Load critical base scripts
  $mod_cheats.load_script("Utils.rb")
  $mod_cheats.load_script("System.rb")
  $mod_cheats.load_script("Manager.rb")
  $mod_cheats.load_script("Menu.rb")

  # Initialize system
  $mod_cheats.sys = CheatsSystem.new($mod_cheats.config_dir)
  $mod_cheats.sys.read_menu_hotkey

  # Discover and load modules
  $mod_cheats.init_modules
end

