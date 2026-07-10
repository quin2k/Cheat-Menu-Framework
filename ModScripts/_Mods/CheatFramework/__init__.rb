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
  attr_accessor :hotkey_defaults
  attr_accessor :hotkeys
  attr_accessor :menu_stack
  attr_accessor :menu_order_snapshot
  attr_accessor :menu_order_dirty
  attr_accessor :hotkey_capture_active
  attr_accessor :restart_needed
  attr_accessor :force_modes
  attr_accessor :force_values

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
    # Main Menu Toggle's key lives in Input::SYM_KEYS[:CF_CHEAT_MENU] now.
    @hotkey_defs = {}
    @hotkeys = Hash.new { |h, k| h[k] = [] }
    @init_config_dir = nil
    @menu_stack = []
    @menu_order_snapshot = nil
    @menu_order_dirty = false
    @hotkey_capture_active = false
    # Process-wide only, not save-scoped - resets on a real restart.
    @restart_needed = false
    # "GROUP.CommandKey" => true/false (override active), for global:-flagged commands.
    @force_modes = {}
    # "GROUP.CommandKey" => the value to force when force_modes is active.
    @force_values = {}
  end


  def init_config_dir
    @config_dir = File.join(@path, "config")
    Dir.mkdir(@config_dir) unless Dir.exist?(@config_dir)
  end


  def init_modules
    modules_path = File.join(@info.path, "modules")
    @mods = FrameworkLoader.new(modules_path, @ini)
    @mods.discover
    @mods.load_all
  end

  def load_framework_script(file)
      load_script($mod_manager.get_resource("cheatframework", "scripts/#{file}"))
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

  # Fires once after a new game starts or a save finishes loading (scripts/Utils.rb).
  def on_save_ready
    # Left blank for modules to override
  end

  def roleplay_mod?
    $mod_manager.mods['RolePlayS'] && $mod_manager.mods['RolePlayS'].enabled
  end

end


if $framework.nil?
  $framework = CheatFramework.new
  $framework.init_config_dir

  # Load critical base scripts
  $framework.load_framework_script("Utils.rb")
  $framework.load_framework_script("Config.rb")
  $framework.load_framework_script("Loader.rb")
  $framework.load_framework_script("Defaults.rb")
  $framework.load_framework_script("Menu.rb")
  $framework.load_framework_script("Controls.rb")

  # Initialize system
  $framework.ini = FrameworkConfig.new($framework.config_dir)

  # Discover and load modules & hotkeys
  $framework.init_modules
  # Pristine, pre-ini state - lets Reset All Settings restore hotkeys live.
  $framework.hotkey_defaults = $framework.hotkey_defs.each_with_object({}) { |(k, v), h| h[k] = v.dup }
  $framework.ini.init_hotkeys
  $framework.ini.init_menu_toggle_key
  $framework.ini.init_order
  FrameworkUtils.build_global_overrides
  $framework.ini.init_force_modes
  $framework.ini.init_force_values
end

