# Cheat Framework: Main Menu

##---------------------------------------------------------------------------
## Hotkeys
##---------------------------------------------------------------------------
module FrameworkUtils
  def self.process_hotkeys
    return unless FrameworkUtils.ingame?

    $framework.hotkeys.each do |key_const, actions|
      next unless Input.trigger?(key_const)

      actions.each do |data|
        cmd = $framework.commands.dig(data[:group], data[:key], :action)
        next unless cmd
        # Menu Toggle
        if data[:group] == :MENU
          if FrameworkUtils.in_menu?
            SceneManager.return # already in menu → close it
          else
            cmd.call # not in menu → open it
          end
          next
        end
        next unless modifiers_match?(data[:mods])
        cmd.call
        SndLib.send(data[:sound]) if defined?(SndLib) && data[:sound]
      end
    end
  end

  def self.modifiers_match?(mods)
    # Convert symbols to input names dynamically
    pressed = {
      SHIFT: Input.press?(:SHIFT),
      CTRL:  Input.press?(:CTRL),
      ALT:   Input.press?(:ALT)
    }

    mods.all? { |m| pressed[m] } &&
      (!pressed[:SHIFT] || mods.include?(:SHIFT)) &&
      (!pressed[:CTRL]  || mods.include?(:CTRL)) &&
      (!pressed[:ALT]   || mods.include?(:ALT))
  end
end

class CheatFramework
  alias_method :hotkey_trigger_Framework, :hotkey_trigger
  def hotkey_trigger
    hotkey_trigger_Framework
    FrameworkUtils.process_hotkeys if FrameworkUtils.ingame?
  end
end

##===========================================================================
## Menu Initialization
##===========================================================================
module MenuFramework
  #==========================================================================
  # Framework-level helpers
  #==========================================================================
  def self.ensure_scene_and_window(opts)
    name = opts[:name]
    dict = opts[:dict]

    win_name   = "Window_#{name}"
    scene_name = "Scene_#{name}"
    unless Object.const_defined?(win_name)
      Object.const_set(win_name, Class.new(Window_Command) do
        include Action_Window_Defaults
        define_method(:make_command_list) do
          @dictionary = $framework.commands[dict]
          commands_from_group
        end
      end)
    end

    unless Object.const_defined?(scene_name)
      new_scene = Class.new(Scene_MenuBase) do
        include Scene_Defaults
        define_method(:start) do
          super()
          @dictionary = $framework.commands[dict]
          @window = Object.const_get(win_name)
          @help_window_text1 = opts[:menu1].is_a?(Proc) ? opts[:menu1].call : (opts[:menu1] ? "#{$framework.txt(opts[:menu1])}" : nil)
          @help_window_text2 = opts[:menu2].is_a?(Proc) ? opts[:menu2].call : (opts[:menu2] ? "#{$framework.txt(opts[:menu2])}" : nil)
          @help_window_text3 = opts[:menu3].is_a?(Proc) ? opts[:menu3].call : (opts[:menu3] ? "#{$framework.txt(opts[:menu3])}" : nil)
          @help_window_text4 = opts[:menu4].is_a?(Proc) ? opts[:menu4].call : (opts[:menu4] ? "#{$framework.txt(opts[:menu4])}" : nil)
          override_action_window
        end
      end

      Object.const_set(scene_name, new_scene)
      # Track dynamically created scene for hotkey handling
      FrameworkUtils.menu_scenes << new_scene
    end
  end

  def self.force_font(contents)
    return unless contents
    return if Font.default_name == "Noto Sans CJK TC Black"
    return unless Font.exist?("Noto Sans CJK TC Black")

    contents.font.name = "Noto Sans CJK TC Black"
    contents.font.size = Font.default_size
  end

  #==========================================================================
  # Main Menu Registration
  #==========================================================================
  module MENU

    $framework.commands[:MAIN] ||= {}

    unless singleton_class.method_defined?(:orig_register_command)
      class << self
        alias_method :orig_register_command, :register_command if method_defined?(:register_command)

        def register_command(opts = {})
          # Automatically attach current module source if defined
          if defined?(FrameworkModule) && FrameworkModule.is_a?(Hash)
            alt_name = (FrameworkModule[:name] || (FrameworkModule[:key] || FrameworkModule[:id]).capitalize)
            opts[:name]   ||= "CheatMenu#{alt_name.gsub(/\s+/, '')}"
            opts[:source] ||= (FrameworkModule[:name] || FrameworkModule[:key] || FrameworkModule[:id])
            opts[:dict]   ||= FrameworkModule[:menu] || FrameworkModule[:key].to_s.upcase
            opts[:key]    ||= opts[:source]
          end
          orig_register_command(opts)
        end
      end
    end

    def self.orig_register_command(opts = {})
      # Prepare keys and menu references
      key  = opts[:key]    # menu key
      name = opts[:name]   # scene/window name
      dict = opts[:dict] || :NONE # submenu constant name

      # Initialize the group in $framework.commands
      $framework.commands[dict] ||= {}

      if name
        MenuFramework.ensure_scene_and_window(opts)
        scene = Object.const_get("Scene_#{name}")
      # Dynamically handle scene/window creation if needed
        action = -> {
          SceneManager.call(scene)
          SceneManager.scene.instance_variable_set(:@menu_symbol, key) if SceneManager.scene
        }
      else
        return
      end

      # Store in $framework.commands instead of COMMANDS
      $framework.commands[:MAIN][key] = {
        source: opts[:source],
        key: opts[:key],
        label: opts[:label],
        menu1: opts[:menu1],
        menu2: opts[:menu2],
        menu3: opts[:menu3],
        menu4: opts[:menu4],
        action: action
      }
    end
  end

  #==========================================================================
  # Submenu Registration
  #==========================================================================
  module SUBMENU
    # Define default submenu groups

    unless singleton_class.method_defined?(:orig_register_command)
      class << self
        alias_method :orig_register_command, :register_command if method_defined?(:register_command)

        def register_command(opts = {})
          if defined?(FrameworkModule) && FrameworkModule.is_a?(Hash)
            alt_name = (FrameworkModule[:name] || (FrameworkModule[:key] || FrameworkModule[:id]).capitalize)
            opts[:name]   ||= "CheatMenu#{alt_name.gsub(/\s+/, '')}"
            # Use module key or menu name for source/group defaults
            opts[:source] ||= (FrameworkModule[:name] || FrameworkModule[:key] || FrameworkModule[:id])
            opts[:group]  ||= (FrameworkModule[:menu] || FrameworkModule[:key].to_s.upcase)
          end
          orig_register_command(opts)
        end
      end
    end
    # Unified command registration method
    def self.orig_register_command(opts)
      key    = opts[:key]    # unique identifier for the command
      name   = opts[:name]   # sub menu name for scene/window creation
      type   = opts[:type]   # type of command :scene, :toggle : action :edit_num :edit_list
      group  = opts[:group]  # sub menu group, usually in caps
      state  = opts[:state]  # used to populate information :toggle, :edit_num, :edit_list only.
      global = opts[:global] # default value for a global variable
      hotkey = opts[:hotkey] # structured {key: "Shift+F4", sound: :sys_ok}
      scene  = opts[:scene]  # :scene only (navigation)
      action = opts[:action] # action performed by the command.

      #Handle group lookup/creation
      group = group.upcase.to_sym
      $framework.commands[group] ||= {}

      if type == :toggle && !action && state
        action = -> {
          new_val = !eval(state); eval("#{state} = #{new_val}")
          $framework.ini.write_global(key, new_val)
        }
      end

      if !opts[:global].nil? && state
        var_name = state[1..-1] # remove $
        default  = global

        # Read from INI or use default
        value = $framework.ini.read_global(key, default)
        eval("$#{var_name} = #{value.inspect}")

        # Auto-define an action if missing
        if action.nil?
          action = lambda do |val|
          next if val.nil?
            eval("$#{var_name} = val")
            $framework.ini.write_global(key, val)
          end
        end
      end

      if hotkey && hotkey[:key]
        sound = hotkey[:sound] || :sys_ok
        $framework.hotkey_defs["#{group}.#{key}"] = { key: hotkey[:key], sound: sound }
      end

      #Dynamically handles scene and window creation if needed.
      if type == :scene && name
        MenuFramework.ensure_scene_and_window(opts)
        scene = Object.const_get("Scene_#{name}")
      end

      #Special handling to populate/standardize scene command.
      if type == :scene && scene
        action = -> {
          SceneManager.call(scene)
          SceneManager.scene.instance_variable_set(:@menu_symbol, key) if SceneManager.scene
        }
      end

      if opts[:source]=="Edit Lona" && opts[:group]==:MISC
        #msgbox "#{opts.inspect}"
      end

      $framework.commands[group][key] = {
        source: opts[:source],
        type:   opts[:type],
        key:    opts[:key],
        label:  opts[:label],
        action: action,
        state:  opts[:state] ? -> { eval(opts[:state]) } : nil,
        help1:  opts[:help1].is_a?(Proc) ? opts[:help1] : (opts[:help1] ? $framework.txt(opts[:help1]) : nil),
        help2:  opts[:help2].is_a?(Proc) ? opts[:help2] : (opts[:help2] ? $framework.txt(opts[:help2]) : nil),
        help3:  opts[:help3].is_a?(Proc) ? opts[:help3] : (opts[:help3] ? $framework.txt(opts[:help3]) : nil),
        help4:  opts[:help4].is_a?(Proc) ? opts[:help4] : (opts[:help4] ? $framework.txt(opts[:help4]) : nil),
        list:   opts[:list],
        min:    opts[:min],
        max:    opts[:max],
        enable: opts.has_key?(:enable) ? opts[:enable] : true,
        hide:   opts.has_key?(:hide)   ? opts[:hide]   : false,
        color:  opts.has_key?(:color)  ? opts[:color]  : false        
      }
    end
  end
end


##===========================================================================
## Main Menu Window Initialization
##===========================================================================
class Window_CheatMainMenu < Window_Command

  #--------------------------------------------------------------------------
  # Initialize
  #--------------------------------------------------------------------------
  def initialize; super(0, 0); end

  #--------------------------------------------------------------------------
  # Draw Setup
  #--------------------------------------------------------------------------
  def draw_item(index)
    MenuFramework.force_font(contents) if contents
    super
  end

  #--------------------------------------------------------------------------
  # Window Structure
  #--------------------------------------------------------------------------
  def window_width; return 160; end
  def window_height; return Graphics.height; end

  #--------------------------------------------------------------------------
  # Command List
  #--------------------------------------------------------------------------
  def make_command_list
    return unless $framework.commands[:MAIN]
    dict =  $framework.commands[:MAIN]
    dict.each do |key, record|
      add_command(
        $framework.txt(record[:label]),
        :menu_command,
        true,
        record[:key]
      )
    end
  end

end # Window_CheatMainMenu


##---------------------------------------------------------------------------
## Main Menu Scene Initialization
##---------------------------------------------------------------------------
class Scene_CheatMainMenu < Scene_MenuBase
  include Scene_Defaults
  def create_command_window
    super
    @command_window.set_handler(:cancel, method(:return_scene))
  end
end
FrameworkUtils.menu_scenes << Scene_CheatMainMenu

##===========================================================================
## Default Category Initialization
##===========================================================================
MenuFramework::MENU.register_command(
  type: :scene,
  key: :misc_menu,
  label: "menu:commands/misc",
  name: "CheatMenuMiscellaneous",
  dict: :MISC,
  order: 1
)
MenuFramework::MENU.register_command(
  type: :scene,
  key: :toggle_menu,
  label: "menu:commands/toggles",
  name: "CheatMenuToggles",
  dict: :TOGGLES,
  order: 2
)
MenuFramework::MENU.register_command(
  type: :scene,
  key: :edit_lona,
  label: "menu:commands/character",
  menu1: "menu:window_help/character1",
  name: "CheatMenuEditLona",
  dict: :LONA,
  order: 3
)
MenuFramework::MENU.register_command(
  type: :scene,
  key: :edit_npc,
  label: "menu:commands/npc",
  name: "CheatMenuNPCOptions",
  dict: :NPC,
  order: 4
)
#MenuFramework::MENU.register_command(
#  type: :scene,
#  key: :config_menu,
#  label: "menu:commands/config",
#  name: "CheatMenuConfiguration",
#  dict: :CONFIG,
#  order: 1000
#)
