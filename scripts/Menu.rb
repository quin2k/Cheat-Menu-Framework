# Cheat Menu Framework: Main Menu

##---------------------------------------------------------------------------
## Hotkeys
##---------------------------------------------------------------------------
class CheatsMod
  alias_method :cheat_triggers_CHEATMENUFRAMEWORK, :cheat_triggers
  def cheat_triggers
    cheat_triggers_CHEATMENUFRAMEWORK
    if Input.trigger?(@hotkey)
      unless SceneManager.scene_is?(Scene_CheatMainMenu)
        SceneManager.call(Scene_CheatMainMenu) if CheatUtils.ingame?
      end
    end
  end
end

##===========================================================================
## Menu Initialization
##===========================================================================
module CheatMenuFramework

  #==========================================================================
  # Framework-level helpers
  #==========================================================================
  def self.group_name_from_const(group)
    SUBMENU.constants.find { |c| SUBMENU.const_get(c) == group }
  end

  def self.ensure_scene_and_window(opts)
    name = opts[:name]
    dict_const = opts[:dict] || group_name_from_const(opts[:group])

    win_name   = "Window_#{name}"
    scene_name = "Scene_#{name}"

    unless Object.const_defined?(win_name)
      Object.const_set(win_name, Class.new(Window_Command) do
        include Action_Window_Defaults
        define_method(:make_command_list) do
          @dictionary = CheatMenuFramework::SUBMENU.const_get(dict_const)
          commands_from_group
        end
      end)
    end

    unless Object.const_defined?(scene_name)
      Object.const_set(scene_name, Class.new(Scene_MenuBase) do
        include Scene_Defaults
        define_method(:start) do
          super()
          @dictionary = CheatMenuFramework::SUBMENU.const_get(dict_const)
          @window = Object.const_get(win_name)
          @help_window_text1 = opts[:menu1] ? "#{$mod_cheats.txt(opts[:menu1])}" : nil
          @help_window_text2 = opts[:menu2] ? "#{$mod_cheats.txt(opts[:menu2])}" : nil
          @help_window_text3 = opts[:menu3] ? "#{$mod_cheats.txt(opts[:menu3])}" : nil
          @help_window_text4 = opts[:menu4] ? "#{$mod_cheats.txt(opts[:menu4])}" : nil
          override_action_window
        end
        if opts[:rebound]
          define_method(:run_default_command) do
            super
            return_scene
          end
        end
      end)
    end
  end

  #==========================================================================
  # Main Menu Registration
  #==========================================================================
  module MENU
    COMMANDS ||= []
    def self.register_command(opts = {})
      type    = opts[:type]   # :scene or :action
      key     = opts[:key]    # used to track cursor
      label   = opts[:label]  # localization text mapping
      action  = opts[:action] # function to execute
      name    = opts[:name]   # :scene only, scene/window name
      dict    = opts[:dict]   # :scene only, submenu constant name
      menu1   = opts[:menu1]  # menu-level help for :scene only, line 1
      menu2   = opts[:menu2]  # menu-level help for :scene only, line 2
      menu3   = opts[:menu3]  # menu-level help for :scene only, line 3
      menu4   = opts[:menu4]  # menu-level help for :scene only, line 4
      rebound = opts[:rebound] # :scene only, return to previous menu upon selection

      #Dynamically handles scene and window creation if needed.
      name = opts[:name]
      if type == :scene && name
        CheatMenuFramework.ensure_scene_and_window(opts)
        scene = Object.const_get("Scene_#{name}")
      end

      #Special handling to populate/standardize scene command.
      if type == :scene && scene
        action = -> {
          win = SceneManager.scene.instance_variable_get(:@command_window)
          if win
            idx = win.index rescue 0
            $mod_cheats.menu_stack.clear
            $mod_cheats.menu_stack.push({ menu: :main_menu, symbol: key, index: idx })
          end
          SceneManager.call(scene)
          SceneManager.scene.instance_variable_set(:@menu_symbol, key) if SceneManager.scene
        }
      end

      COMMANDS << [key, "#{$mod_cheats.txt(label)}", action]
    end
  end

  #==========================================================================
  # Submenu Registration
  #==========================================================================
  module SUBMENU
    # Define default submenu groups
    TOGGLES ||= {}
    ACTIONS ||= {}
    CONFIG  ||= {}  

    # Unified command registration method
    def self.register_command(opts)
      group  = opts[:group]  # sub menu name, usually in caps
      type   = opts[:type]   # :action, :toggle,:scene, :edit_list, :edit_num
      key    = opts[:key]    # config name for :toggle, menu map for :scene
      label  = opts[:label]  # localization text mapping
      action = opts[:action] # function to execute
      state  = opts[:state]  # :toggle, :edit_ only (text on right)
      help1  = opts[:help1]  # custom command text, line 1
      help2  = opts[:help2]  # custom command text, line 2
      help3  = opts[:help3]  # custom command text, line 3
      help4  = opts[:help4]  # custom command text, line 4
      menu1  = opts[:menu1]  # menu-level help for :scene only, line 1
      menu2  = opts[:menu2]  # menu-level help for :scene only, line 2
      menu3  = opts[:menu3]  # menu-level help for :scene only, line 3
      menu4  = opts[:menu4]  # menu-level help for :scene only, line 4
      scene  = opts[:scene]  # :scene only (navigation)
      list   = opts[:list]  # :edit_list only
      min    = opts[:min]    # :edit_num only
      max    = opts[:max]    # :edit_num only
      enable = opts.has_key?(:enable) ? opts[:enable] : true
      hide   = opts.has_key?(:hide)   ? opts[:hide]   : false
      color  = opts.has_key?(:color)  ? opts[:color]  : false

      #Handle group lookup/creation
      if group.is_a?(String) || group.is_a?(Symbol)
        const_name = group.to_s.upcase
        if CheatMenuFramework::SUBMENU.const_defined?(const_name)
          group = CheatMenuFramework::SUBMENU.const_get(const_name)
        else
          # Create it dynamically if missing, for new submenus
          group = CheatMenuFramework::SUBMENU.const_set(const_name, {})
        end
      end

      #Dynamically handles scene and window creation if needed.
      name = opts[:name]
      if type == :scene && name
        CheatMenuFramework.ensure_scene_and_window(opts)
        scene = Object.const_get("Scene_#{name}")
      end

      #Special handling to populate/standardize scene command.
      if type == :scene && scene
        action = -> {
          SceneManager.call(scene)
          SceneManager.scene.instance_variable_set(:@menu_symbol, key) if SceneManager.scene
        }
      end

      if type == :toggle && !action && state
        action = -> {
          new_val = !eval(state); eval("#{state} = #{new_val}")
          $mod_cheats.config.write("Cheats Mod - Modules", key, new_val)
        }
      end

      group[key] = {
        type: type,
        key: key,
        label: label,
        action: action,
        state: -> { eval(state) }, 
        help1: help1 ? "#{$mod_cheats.txt(help1)}" : nil,
        help2: help2 ? "#{$mod_cheats.txt(help2)}" : nil,
        help3: help3 ? "#{$mod_cheats.txt(help3)}" : nil,
        help4: help4 ? "#{$mod_cheats.txt(help4)}" : nil,        
        list: list,
        min: min,
        max: max,
        enable: enable,
        hide: hide,
        color: color
      }
    end
  end
end

#==============================================================================
# Action Window Module
#==============================================================================
module Action_Window_Defaults
  attr_accessor :dictionary
  #--------------------------------------------------------------------------
  # Initialize
  #-------------------------------------------------------------------------
  def initialize
    super(160, 0)
    @dictionary = nil
    clear_edit
  end

  def clear_edit
    @editing = false
    @editing_this = nil
    @editing_number = nil
    @edit_value = 0
    @edit_list = []
    @edit_index = 0
    @edit_min = 0
    @edit_max = 0
  end

  #--------------------------------------------------------------------------
  # Window Structure
  #--------------------------------------------------------------------------
  def window_width; return Graphics.width - 160; end
  def window_height; return Graphics.height - 120; end

  #--------------------------------------------------------------------------
  # Command Initialization
  #--------------------------------------------------------------------------
  def commands_from_group
    return unless @dictionary
    @dictionary.each do |key, record|
      next if record[:hide].is_a?(Proc) ? record[:hide].call : record[:hide]
      enable = record[:enable].is_a?(Proc) ? record[:enable].call : record[:enable]

      add_command(
        $mod_cheats.txt(record[:label]),
        :run_default_command,
        enable,
        record[:key]
      )
    end
  end

  #--------------------------------------------------------------------------
  # Command Definition
  #--------------------------------------------------------------------------
  def run_default_command
    key = current_ext
    record = @dictionary[key]
    return unless record

    case record[:type]
    when :edit_num, :edit_list
      if @editing
        save_editing(key)
      else
        start_editing(key)
      end
      refresh
    else
      record[:action].call if record[:action]
      SndLib.sys_ok
      refresh
    end
  end

  def start_editing(key)
    record = @dictionary[key]
    return unless record

    @editing = true
    @editing_this = key
    @editing_number = record[:type] == :edit_num
    @edit_value = record[:state].call rescue 0

    if @editing_number
      @edit_min = record[:min].is_a?(Proc) ? record[:min].call : record[:min] || 0
      @edit_max = record[:max].is_a?(Proc) ? record[:max].call : record[:max] || 999
    else
      @edit_list = record[:list] || []
      @edit_index = @edit_list.index { |i| i[:key] == record[:state].call rescue 0 } || 0
      @edit_value = @edit_list[@edit_index][:label]
    end
  end

  def save_editing(key)
    record = @dictionary[key]
    return unless record

    save_value =
      if record[:type] == :edit_list
        save_value = @edit_list[@edit_index][:key]
      else
        save_value = @edit_value
      end

    if record[:action].arity == 1
      #Handle Value (v) entry.
      record[:action].call(save_value)
    elsif record[:action].arity == 2
      #Handle Key/Value pair - mostly for saving to config.
      record[:action].call(record[:key],save_value)
    else
      #Run the command as-is if nothing required.
      instance_exec(&record[:action])
    end
    SndLib.sys_ok
    clear_edit
  end



  #--------------------------------------------------------------------------
  # Draw Setup
  #--------------------------------------------------------------------------
  def draw_item(index)
    rect = item_rect_for_text(index)
    contents.clear_rect(rect)

    key      = @list[index][:ext]
    name     = command_name(index)
    enabled  = command_enabled?(index)
    record   = @dictionary && key ? @dictionary[key] : nil
    value    = nil
    right    = ""

    # --- Determine base color ---
    color = if record && record[:color]
        c = record[:color]
        val = c.respond_to?(:call) ? c.call : c
        val.is_a?(Numeric) ? text_color(val) : val
      else
        normal_color
      end

    # --- Determine what to display on the right side ---
    case record && record[:type]
    when :info
      right = record[:state].call rescue ""
      color = text_color(8)
    when :toggle
      value = record[:state].call rescue false
      right = value ? "[#{$mod_cheats.txt("menu:cheat_toggle/on")}]" :
                      "[#{$mod_cheats.txt("menu:cheat_toggle/off")}]"
    when :edit_num
      value = record[:state].call rescue 0
      right = value.to_s
    when :edit_list
      list = record[:list] || []
      value = record[:state].call rescue 0
      item = list.find { |i| i[:key] == value }
      right = item ? item[:label] : value.to_s
    end


    # --- Adjust display name and color ---
    display_name = enabled ? name : "#{name} (#{$mod_cheats.txt("modules/variables:commands_item/locked")})"
    color = enabled ? color : text_color(8)

    if @editing && key == @editing_this
      color = text_color(16)
      right = @edit_value.to_s
    end

    # --- Draw ---
    change_color(color)
    draw_text(rect, display_name, 0)
    draw_text(rect, right, 2) if right && !right.empty?
  end

  #--------------------------------------------------------------------------
  # Control Overrides
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    if @editing
      SndLib.play_cursor
      number = @editing_number ? edit_key_multiply : 1
      modify_variable(-number)
    else
      cursor_pageup
    end
  end

  def cursor_right(wrap = false)
    if @editing
      SndLib.play_cursor
      number = @editing_number ? edit_key_multiply : 1
      modify_variable(number)
    else
      cursor_pagedown
    end
  end

  def cursor_up(wrap = false)
    super unless @editing
    refresh_help_window
  end

  def cursor_down(wrap = false)
    super unless @editing
    refresh_help_window
  end

  def refresh_help_window
    SceneManager.scene.refresh_help_window if SceneManager.scene.respond_to?(:refresh_help_window)
  end

  def process_cancel
    if @editing
      clear_edit
      refresh
    else
      super
    end
  end

  def edit_key_multiply
    multi = 1
    multi *= 10 if Input.press?(Input::KEYMAP[:SHIFT])
    multi *= 100 if Input.press?(Input::KEYMAP[:CONTROL])
    multi
  end

  def modify_variable(change)
    if @editing_number
      @edit_value += change
      @edit_value = [[@edit_value, @edit_min].max, @edit_max].min
    else    
      return unless @edit_list && @edit_list.is_a?(Array)
      @edit_index = (@edit_index + change) % @edit_list.size  # cycles properly
      @edit_value = @edit_list[@edit_index][:label]
    end
    refresh
  end


end

#==============================================================================
# Cheat Menu Module
#==============================================================================
module Scene_Defaults
  attr_accessor :menu_symbol
  def start
    super
    create_command_window
    create_help_window
    create_action_window
    @help_window_text1 = nil
    @help_window_text2 = nil
    @help_window_text3 = nil
    @help_window_text4 = nil
  end

  def update
    super
    return_scene if Input.trigger?($mod_cheats.hotkey)
  end

  def terminate
    super
  end

  def create_action_window
    wx = @command_window.width
    ww = Graphics.width - wx
    wh = Graphics.height - @help_window.height
    @action_window = Window_Base.new(wx, 0, ww, wh)
  end

  def override_action_window
    @command_window.deactivate
    @action_window = @window.new
    @action_window.dictionary = @dictionary
    @action_window.set_handler(:cancel, method(:return_scene))
    @action_window.set_handler(:run_default_command, method(:default_command))
    restore_action_window_state
    #refresh_help_window(:toggle_cheats, "#{$mod_cheats.txt("menu:command_help/cheats_0")}\n#{$mod_cheats.txt("menu:command_help/cheats_1")}\n\n")
    refresh_help_window
  end

  def default_command
    @action_window.activate
    @action_window.dictionary = @dictionary
    save_action_window_state
    @action_window.run_default_command
    refresh_help_window
  end

  def return_scene
    save_action_window_state
    super
  end

  def save_action_window_state
    menu = @menu_symbol
    #$mod_cheats.menu_stack.delete_if { |e| e[:menu] == menu_symbol }
    $mod_cheats.menu_stack.push({ menu: menu, symbol: @action_window.current_ext, index: @action_window.index })
  end

  def restore_action_window_state
    menu = @menu_symbol
    return unless menu && $mod_cheats.menu_stack && @action_window.active
    entry = $mod_cheats.menu_stack.reverse.find { |e| e[:menu] == menu }
    if entry
      list = @action_window.instance_variable_get(:@list)
      idx = list.index { |cmd| cmd[:symbol] == entry[:symbol] } || entry[:index] || 0
      idx = [[idx, 0].max, list.size - 1].min
      @action_window.select(idx)
    end
  end

  def menu_has_saved_state?(symbol)
    $mod_cheats.menu_stack.any? { |h| h[:symbol] == symbol }
  end

  def create_help_window
    wx = @command_window.width
    wy = Graphics.height - 120
    ww = Graphics.width - wx
    wh = 120
    @help_window = Window_Base.new(wx, wy, ww, wh)
  end

  def refresh_help_window
    text = ""
    unless @command_window.active 
      cmd = @action_window.current_ext
      dict = @action_window.instance_variable_get(:@dictionary) rescue nil
      record = dict ? dict[cmd] : nil

      # Build help text
      help_lines = []
      help1 = (record[:help1] rescue nil) #command specific text
      help2 = (record[:help2] rescue nil) #command specific text
      if help1.nil? && help2.nil?
        help1 = @help_window_text1 rescue nil #scene specific text
        help2 = @help_window_text2 rescue nil #scene specific text
        if help1.nil? && help2.nil?
          help1 = "" #if neither set, leave blank
          help2 = "" #if neither set, leave blank
        end
      end
      help_lines << help1
      help_lines << help2

      # Interface Instructions
      help3 = (record[:help3] rescue nil) #command specific text
      help4 = (record[:help4] rescue nil) #command specific text
      if help3.nil? && help4.nil?
        help3 = @help_window_text3 rescue nil #scene specific text
        help4 = @help_window_text4 rescue nil #scene specific text
        if help3.nil? && help4.nil?
          if @action_window && @action_window.instance_variable_get(:@editing_number)
            help3 = $mod_cheats.txt("menu:command_help/num_edit1")
            help4 = $mod_cheats.txt("menu:command_help/num_edit2")
          elsif @action_window && @action_window.instance_variable_get(:@editing)
            help3 = ""
            help4 = $mod_cheats.txt("menu:command_help/num_edit1")
          else
            help3 = ""
            case record && record[:type]
            when :action then help4 = $mod_cheats.txt("menu:command_help/execute")
            when :scene  then help4 = $mod_cheats.txt("menu:command_help/scene")
            when :toggle then help4 = $mod_cheats.txt("menu:command_help/toggle")
            when :edit_num, :edit_list then help4 = $mod_cheats.txt("menu:command_help/edit")
            else help4 = ""
            end
          end
        end
      end
      help_lines << help3
      help_lines << help4

      text = help_lines.join("\n")

      # Update Help Window
      if @help_window && @help_window.contents
        @help_window.contents.clear
        @help_window.draw_text_ex(4, 0, text)
      end
    end
  end

  def create_command_window
    @command_window = Window_CheatMainMenu.new

    CheatMenuFramework::MENU::COMMANDS.each do |symbol, label, action|
      @command_window.set_handler(symbol, action)
    end
    # Always restore using the first (root) menu symbol in the stack
    if $mod_cheats.menu_stack && !$mod_cheats.menu_stack.empty?
      first = $mod_cheats.menu_stack.first
      list = @command_window.instance_variable_get(:@list)
      index = list.index { |cmd| cmd[:symbol] == first[:symbol] }
      @command_window.select(index || 0)
    else
      @command_window.select(0)
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
  # Window Structure
  #--------------------------------------------------------------------------
  def window_width; return 160; end
  def window_height; return Graphics.height; end

  #--------------------------------------------------------------------------
  # Command List
  #--------------------------------------------------------------------------
  def make_command_list
    CheatMenuFramework::MENU::COMMANDS.each do |symbol, label|
      add_command(label, symbol)
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

##===========================================================================
## Default Category Initialization
##===========================================================================
CheatMenuFramework::MENU.register_command(
  type:  :scene,
  key:   :action_cheats,
  label: "menu:commands/toggle",
  name:  "CheatMenuActions",
  dict:  "ACTIONS",
  order: 1
)
CheatMenuFramework::MENU.register_command(
  type: :scene,
  key: :toggle_cheats,
  label: "menu:commands/actions",
  name: "CheatMenuToggles",
  dict: "TOGGLES",
  order: 2
)
CheatMenuFramework::MENU.register_command(
  type: :scene,
  key: :config_menu,
  label: "menu:commands/config",
  name: "CheatMenuConfiguration",
  dict: "CONFIG",
  order: 99
)
