#===============================================================================
###	Main project file
### Mod: Cheat Framework
###	Author: Kenny567
#===============================================================================

#Mod namespace
class CheatFramework
  attr_reader :info
  attr_reader :path
  attr_reader :config_dir
  attr_accessor :mods
  attr_accessor :ini
  attr_accessor :txt
  attr_accessor :commands
  attr_accessor :hotkey_defs
  attr_accessor :hotkeys
  attr_accessor :menu_stack

  def initialize
    @info = $mod_manager.mods["cheatframework"]
    @path = $mod_manager.mods["cheatframework"].path
    @mods = {}
    @config_dir = nil
    #Pre-define main menu command & hotkey for convenience.
    @commands ||= {}
    @commands[:MENU] ||= {}
    @commands[:MENU] = { "Main Menu" => {
      source: "Main Menu", 
      key: "Main Menu", 
      action: -> {
        unless SceneManager.scene_is?(Scene_CheatMainMenu)
        SceneManager.call(Scene_CheatMainMenu) if FrameworkUtils.ingame? end 
      }}}
    @hotkey_defs = { "MENU.Main Menu" => { key: "F9", sound: nil } }
    @hotkeys = Hash.new { |h, k| h[k] = [] }
    @init_config_dir = nil
    @menu_stack = []
  end


  def init_config_dir
    @config_dir = File.join(System_Settings::USER_DATA_PATH, "Cheat Framework")
    Dir.mkdir(@config_dir) unless Dir.exist?(@config_dir)
  end


  def init_modules
    modules_path = File.join(@info.path, "modules")
    @mods = FrameworkLoader.new(modules_path, @ini)
    @mods.discover
    @mods.load_all
  end

  def load_script(file)
    path = File.join($framework.path, "scripts", file)
    load path if File.exist?(path)
  end

  def txt(text_flag)
    return $game_text["#{@info.id}:#{text_flag}"]
  end

  # Overridable function
  def hotkey_trigger
    # Left blank for modules to override
  end

  def normal_trigger #every second
    # Left blank for modules to override
  end

  def slow_trigger #every 5 seconds
    # Left blank for modules to override
  end

end


if $framework.nil?
  $framework = CheatFramework.new
  $framework.init_config_dir

  # Load critical base scripts
  $framework.load_script("Utils.rb")
  $framework.load_script("Config.rb")
  $framework.load_script("Loader.rb")
  $framework.load_script("Defaults.rb")
  $framework.load_script("Menu.rb")

  # Initialize system
  $framework.ini = FrameworkConfig.new($framework.config_dir)

  # Discover and load modules & hotkeys
  $framework.init_modules
  $framework.ini.init_hotkeys
  #$framework.ini.init_order
end

