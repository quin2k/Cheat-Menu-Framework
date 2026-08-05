#===============================================================================
#  Menu Defaults
#------------------------------------------------------------------------------
#  Handles default commands structure and interface
#===============================================================================

module MenuFramework
  module ScrollArrows
    ARROW_SRC_DOWN  = Rect.new(0, 0, 19, 12)
    ARROW_WIDTH     = 12
    ARROW_HEIGHT    = 8
    ARROW_Z = 200
    JIGGLE_PERIOD = 60
    ARROW_UP_Y_OFFSET   = 4 # nudge down to re-center against the smaller glyphs
    ARROW_DOWN_Y_OFFSET = 0

    # Cap the cluster at 180px so it doesn't stretch to fill wide windows.
    def scroll_arrow_span
      [contents_width, 180].min
    end

    # Override to 1 for a single centered arrow instead of a 3-wide cluster.
    def scroll_arrow_tile_count
      3
    end

    def create_scroll_arrows
      source = Cache.system("Menu/08Items/item_arrow")
      down_glyph = Bitmap.new(ARROW_WIDTH, ARROW_HEIGHT)
      down_glyph.stretch_blt(down_glyph.rect, source, ARROW_SRC_DOWN)
      @scroll_arrow_down = build_scroll_arrow(down_glyph)
      @scroll_arrow_up   = build_scroll_arrow(flip_glyph(down_glyph))
      update_scroll_arrows
    end

    # Row-by-row reversal instead of a negative sprite zoom (zoom_y = -1
    # silently failed to render at all) - keeps up/down pixel-identical.
    def flip_glyph(glyph)
      flipped = Bitmap.new(glyph.width, glyph.height)
      glyph.height.times do |row|
        flipped.blt(0, glyph.height - 1 - row, glyph, Rect.new(0, row, glyph.width, 1))
      end
      flipped
    end

    def build_scroll_arrow(glyph)
      span = scroll_arrow_span
      sprite = Sprite.new
      sprite.z = ARROW_Z
      sprite.bitmap = Bitmap.new(span, ARROW_HEIGHT)
      scroll_arrow_tile_positions(span).each do |dest_x|
        sprite.bitmap.blt(dest_x, 0, glyph, glyph.rect)
      end
      sprite.x = self.x + padding + (contents_width - span) / 2
      sprite.visible = false
      sprite
    end

    def scroll_arrow_tile_positions(span)
      count = scroll_arrow_tile_count
      return [span / 2 - ARROW_WIDTH / 2] if count <= 1
      (0...count).map { |i| i * (span - ARROW_WIDTH) / (count - 1) }
    end

    def update_scroll_arrows
      return unless @scroll_arrow_up && @scroll_arrow_down
      more_rows = page_row_max > 0 && row_max > page_row_max
      @scroll_arrow_up.visible   = more_rows && top_row > 0
      @scroll_arrow_down.visible = more_rows && bottom_row < row_max - 1

      jiggle = Graphics.frame_count % JIGGLE_PERIOD / (JIGGLE_PERIOD / 3)
      @scroll_arrow_up.y   = self.y + ARROW_UP_Y_OFFSET - jiggle if @scroll_arrow_up.visible
      @scroll_arrow_down.y = self.y + height - padding_bottom + ARROW_DOWN_Y_OFFSET + jiggle if @scroll_arrow_down.visible
    end

    def dispose_scroll_arrows
      @scroll_arrow_up.dispose   if @scroll_arrow_up
      @scroll_arrow_down.dispose if @scroll_arrow_down
    end

    def update
      super
      update_scroll_arrows
    end

    def dispose
      dispose_scroll_arrows
      super
    end
  end
end

#==============================================================================
# Action Window Module
#==============================================================================
module Action_Window_Defaults
  include MenuFramework::ScrollArrows
  attr_accessor :dictionary
  #--------------------------------------------------------------------------
  # Initialize
  #-------------------------------------------------------------------------
  def initialize
    super(160, 0)
    @dictionary = nil
    @hotkey_capture_mode = false
    clear_edit
    create_scroll_arrows
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
    FrameworkUtils.sorted_commands(@dictionary).each do |key, record|
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
    return if @hotkey_capture_mode # assigning a hotkey, not activating the row

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
      FrameworkUtils.mark_restart_needed(record)
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
    FrameworkUtils.mark_restart_needed(record)
    SndLib.sys_ok
    clear_edit
  end



  #--------------------------------------------------------------------------
  # Draw Setup
  #--------------------------------------------------------------------------
  def draw_item(index)
    MenuFramework.force_font(contents) if contents
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
    when :scene
      right = ">>>"
    end

    # --- Adjust display name and color ---
    hotkey_tag = FrameworkUtils.hotkey_tag_for(@dictionary, key)
    # edit_list/edit_num rows cannot be assigned a hotkey, so no conflict with restart tag.
    restart_tag = hotkey_tag ? nil : (FrameworkUtils.restart_mismatch?(record) ? "[#{$framework.txt("menu:commands_status/restart_needed")}]" : nil)
    tag = hotkey_tag || restart_tag
    tagged_name = tag ? "#{name} #{tag}" : name
    display_name = enabled ? tagged_name : "#{tagged_name} (#{$framework.txt("menu:commands_status/locked")})"
    color = enabled ? color : text_color(8)

    if @editing && key == @editing_this
      color = text_color(16)
      right = @edit_value.to_s
    end

    if @hotkey_capture_mode && index == self.index
      color = text_color(16)
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
    if @hotkey_capture_mode
      exit_hotkey_capture
    elsif @editing
      clear_edit
      refresh
    else
      super
    end
  end

  #--------------------------------------------------------------------------
  # Hotkey Capture
  #--------------------------------------------------------------------------
  # LETTER_C arms the row, Shift/Ctrl/Alt+key assigns (F-key or letter/digit/
  # punctuation, see HotkeySymbols), Delete/Backspace clears, LETTER_C/Cancel
  # disarms. Any command can hold a hotkey via hotkey_defs.
  FKEY_SYMBOLS = (1..12).map { |n| :"F#{n}" }

  # :edit_num/:edit_list actions need a value argument, which a bare keypress can't supply.
  CAPTURABLE_TYPES = [:toggle, :action, :scene]

  def update
    super
    return unless active

    if @hotkey_capture_mode
      update_hotkey_capture
    elsif !@editing && current_ext && Input.trigger?(:LETTER_C)
      if capturable_row?
        enter_hotkey_capture
      else
        SndLib.sys_buzzer
      end
    end
  end

  def capturable_row?
    return false unless @dictionary && current_ext
    record = @dictionary[current_ext]
    record && CAPTURABLE_TYPES.include?(record[:type])
  end

  # Cursor movement is frozen on the armed row while capturing.
  def process_cursor_move
    return if @hotkey_capture_mode
    super
  end

  def enter_hotkey_capture
    @hotkey_capture_mode = true
    $framework.hotkey_capture_active = true
    SndLib.play_cursor
    refresh_help_window
    refresh
  end

  # Backs out without assigning anything - the only time "C to cancel" is
  # accurate, since assign/clear below leave on their own once committed.
  def exit_hotkey_capture
    SndLib.play_cursor
    leave_hotkey_capture
  end

  def leave_hotkey_capture
    @hotkey_capture_mode = false
    $framework.hotkey_capture_active = false
    refresh_help_window
    refresh
  end

  def update_hotkey_capture
    if Input.trigger?(:LETTER_C)
      exit_hotkey_capture
      return
    end

    if Input.trigger?(:BACK) || Input.trigger?(:DELETE)
      clear_current_hotkey
      return
    end

    (FKEY_SYMBOLS + HotkeySymbols.symbols).each do |key_sym|
      next unless Input.trigger?(key_sym)
      assign_current_hotkey(key_sym)
      return
    end
  end

  def current_hotkey_full_key
    key = current_ext
    return nil unless key
    group = FrameworkUtils.group_for_dictionary(@dictionary)
    return nil unless group
    "#{group}.#{key}"
  end

  def assign_current_hotkey(key_sym)
    full_key = current_hotkey_full_key
    return unless full_key

    if HotkeyReserved.info_for(key_sym.to_s)
      SndLib.sys_buzzer # reserved (Main Menu Key and F10 always, F5/F6 while RolePlay-S is active) - refuse, modifiers don't help
      return
    end

    mods = []
    mods << "Shift" if Input.press?(:SHIFT)
    mods << "Ctrl"  if Input.press?(:CTRL)
    mods << "Alt"   if Input.press?(:ALT)
    key_str = (mods + [HotkeySymbols.name_for(key_sym) || key_sym.to_s]).join("+")

    if $framework.hotkey_defs[full_key]
      $framework.hotkey_defs[full_key][:key] = key_str
    else
      $framework.hotkey_defs[full_key] = { key: key_str, sound: nil }
    end

    $framework.ini.save_hotkeys_to_ini
    $framework.ini.build_hotkey_map # live immediately - no restart needed
    SndLib.sys_ok
    leave_hotkey_capture
  end

  def clear_current_hotkey
    full_key = current_hotkey_full_key
    return unless full_key
    return unless $framework.hotkey_defs[full_key]

    $framework.hotkey_defs[full_key][:key] = "NONE"
    $framework.ini.save_hotkeys_to_ini
    $framework.ini.build_hotkey_map
    SndLib.sys_cancel
    leave_hotkey_capture
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
      c = @help_window.contents
      c.clear
      MenuFramework.force_font(c)
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
          if @action_window && @action_window.instance_variable_get(:@hotkey_capture_mode)
            help3 = $framework.txt("menu:command_help/hotkey_capture1")
            help4 = $framework.txt("menu:command_help/hotkey_capture2")
          elsif @action_window && @action_window.instance_variable_get(:@editing_number)
            help3 = $framework.txt("menu:command_help/num_edit1")
            help4 = $framework.txt("menu:command_help/num_edit2")
          elsif @action_window && @action_window.instance_variable_get(:@editing)
            help3 = ""
            help4 = $framework.txt("menu:command_help/num_edit1")
          else
            type = record && record[:type]
            case type
            when :action then help3 = $framework.txt("menu:command_help/execute")
            when :scene  then help3 = $framework.txt("menu:command_help/scene")
            when :toggle then help3 = $framework.txt("menu:command_help/toggle")
            when :edit_num, :edit_list then help3 = $framework.txt("menu:command_help/edit")
            else help3 = ""
            end
            # Only :action/:toggle/:scene rows can carry a hotkey (see
            # Action_Window_Defaults::CAPTURABLE_TYPES) - :edit_num/:edit_list
            # get no hint since pressing C there just buzzes.
            help4 = [:action, :scene, :toggle].include?(type) ? $framework.txt("menu:command_help/set_hotkey_hint") : ""
          end
        end
      end
      help_lines << help3
      help_lines << help4

      text = help_lines.join("\n")

      # Update Help Window
      if @help_window && @help_window.contents
        c = @help_window.contents
        c.clear
        MenuFramework.force_font(c)
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
  
  # Small fix to prevent crashes when opening the menu during animations.
  def hud
    self
  end

end

#==============================================================================
# Config List Defaults (Edit Menu Order / View Hotkeys / Edit Globals - the
# full-width single-window screens in scripts/Controls.rb)
#==============================================================================
module Window_ConfigList_Defaults
  include MenuFramework::ScrollArrows
  def window_width;  Graphics.width; end
  def window_height; Graphics.height - 120; end

  def initialize(*args)
    super
    create_scroll_arrows
  end

  def force_content_font
    MenuFramework.force_font(contents) if contents
  end
end

module Scene_ConfigList_Defaults
  # Breadcrumb save/restore/clamp, keyed by each scene's own menu_key.
  def save_selection
    $framework.menu_stack.push({
      menu:   menu_key,
      symbol: @command_window.current_ext,
      index:  @command_window.index
    })
  end

  def restore_selection
    entry = $framework.menu_stack.reverse.find { |e| e[:menu] == menu_key }
    return unless entry
    list = @command_window.instance_variable_get(:@list)
    idx = list.index { |cmd| cmd[:ext] == entry[:symbol] } || entry[:index] || 0
    idx = [[idx, 0].max, list.size - 1].min
    @command_window.select(idx)
  end

  def clamp_selection
    list = @command_window.instance_variable_get(:@list)
    return if list.empty?
    idx = [[@command_window.index, 0].max, list.size - 1].min
    @command_window.select(idx)
  end
end
