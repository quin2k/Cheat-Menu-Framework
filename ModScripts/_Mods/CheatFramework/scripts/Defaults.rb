#===============================================================================
#  Menu Defaults
#------------------------------------------------------------------------------
#  Handles default commands structure and interface
#===============================================================================

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
        #$framework.txt(record[:label]), added alternative proc handling for testing:
        record[:label].is_a?(Proc) ? record[:label].call : $framework.txt(record[:label]),
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
      right = value ? "[#{$framework.txt("menu:cheat_toggle/on")}]" :
                      "[#{$framework.txt("menu:cheat_toggle/off")}]"
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
    display_name = enabled ? name : "#{name} (#{$framework.txt("menu:commands_status/locked")})"
    color = enabled ? color : text_color(8)

    if @editing && key == @editing_this
      color = text_color(16)
      right = @edit_value.to_s
    end

    # --- Draw ---
    change_color(color)
    draw_text(rect, display_name, 0)
    draw_text(rect, right, 2) if right && !right.to_s.empty?
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

  def override_help_window_text(text)
    SceneManager.scene.override_help_window_text(text) if SceneManager.scene.respond_to?(:override_help_window_text)
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
# Scene Defaults
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
    @action_window.set_handler(:cancel, method(:return_action_scene))
    @action_window.set_handler(:run_default_command, method(:default_command))
    restore_action_window_state
    refresh_help_window
  end

  def default_command
    @action_window.activate
    @action_window.dictionary = @dictionary
    save_action_window_state
    @action_window.run_default_command
    refresh_help_window
  end

  def return_action_scene
    save_action_window_state
    return_scene
  end

  def save_action_window_state
    menu = @menu_symbol
    $framework.menu_stack.push({ menu: menu, symbol: @action_window.current_ext, index: @action_window.index })
  end

  def save_action_window_state
    menu = @menu_symbol
    symbol = @action_window.current_ext rescue nil
    index  = @action_window.index rescue 0
    $framework.menu_stack.push({ menu: menu, symbol: @action_window.current_ext, index: @action_window.index })
  end

  def restore_action_window_state
    menu = @menu_symbol
    return unless menu && $framework.menu_stack && @action_window.active
    entry = $framework.menu_stack.reverse.find { |e| e[:menu] == menu }
    if entry
      list = @action_window.instance_variable_get(:@list)
      idx = list.index { |cmd| cmd[:symbol] == entry[:symbol] } || entry[:index] || 0
      idx = [[idx, 0].max, list.size - 1].min
      @action_window.select(idx)
    end
  end

  def menu_has_saved_state?(symbol)
    $framework.menu_stack.any? { |h| h[:symbol] == symbol }
  end

  def create_help_window
    wx = @command_window.width
    wy = Graphics.height - 120
    ww = Graphics.width - wx
    wh = 120
    @help_window = Window_Base.new(wx, wy, ww, wh)
  end

  def override_help_window_text(text)
    if @help_window && @help_window.contents
      @help_window.contents.clear
      @help_window.draw_text_ex(4, 0, text)
    end
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
      help1 = help1.call if help1.is_a?(Proc)
      help2 = (record[:help2] rescue nil) #command specific text
      help2 = help2.call if help2.is_a?(Proc)
      help3 = (record[:help3] rescue nil) #command specific text
      help3 = help3.call if help3.is_a?(Proc)
      help4 = (record[:help4] rescue nil) #command specific text
      help4 = help4.call if help4.is_a?(Proc)
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
      if help3.nil? && help4.nil?
        help3 = @help_window_text3 rescue nil #scene specific text
        help4 = @help_window_text4 rescue nil #scene specific text
        if help3.nil? && help4.nil?
          if @action_window && @action_window.instance_variable_get(:@editing_number)
            help3 = $framework.txt("menu:command_help/num_edit1")
            help4 = $framework.txt("menu:command_help/num_edit2")
          elsif @action_window && @action_window.instance_variable_get(:@editing)
            help3 = ""
            help4 = $framework.txt("menu:command_help/num_edit1")
          else
            help3 = ""
            case record && record[:type]
            when :action then help4 = $framework.txt("menu:command_help/execute")
            when :scene  then help4 = $framework.txt("menu:command_help/scene")
            when :toggle then help4 = $framework.txt("menu:command_help/toggle")
            when :edit_num, :edit_list then help4 = $framework.txt("menu:command_help/edit")
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
    main_dict = $framework.commands[:MAIN] || {}

    main_dict.each do |symbol, entry|
      @command_window.set_handler(:menu_command, method(:menu_command_update))
    end
    # Always restore using the first (root) menu symbol in the stack
    if $framework.menu_stack && !$framework.menu_stack.empty?
      first = $framework.menu_stack.first
      list = @command_window.instance_variable_get(:@list)
      index = list.index { |cmd| cmd[:ext] == first[:symbol] }
      @command_window.select(index || 0)
    else
      @command_window.select(0)
    end
  end

  def save_command_window_state
    menu   = :MAIN
    symbol = @command_window.current_ext rescue nil
    index  = @command_window.index rescue 0
    return unless symbol
    $framework.menu_stack.clear
    $framework.menu_stack.push({ menu: :MAIN, symbol: symbol, index: index })
  end

  def menu_command_update
    save_command_window_state
    key = @command_window.current_ext 
    record = $framework.commands[:MAIN][key]

    return unless record
    record[:action].call if record[:action] 
    SndLib.sys_ok
  end



  
end
