# Cheat Framework: Main Menu

#---------------------------------------------------------------------------
# Hotkeys
#---------------------------------------------------------------------------
module FrameworkUtils
  def self.process_hotkeys
    return unless FrameworkUtils.ingame?

    process_menu_toggle_hotkey

    $framework.hotkeys.each do |key_const, actions|
      next unless Input.trigger?(key_const)

      actions.each do |data|
        record = $framework.commands.dig(data[:group], data[:key])
        cmd = record && record[:action]
        next unless cmd
        # Suppress hotkeys while a submenu is mid-capture, so the target key
        # doesn't also fire whatever it's currently bound to.
        next if $framework.hotkey_capture_active
        # Don't fire cheat hotkeys while browsing the cheat menu itself.
        next if FrameworkUtils.in_menu?
        # Letter/digit/punctuation hotkeys no-op if the game's own Key Binds
        # menu claims that key; F-keys skip this check (see HotkeySymbols).
        next if HotkeySymbols.symbols.include?(key_const) && FrameworkUtils.claimed_by_game_controls?(key_const)
        next unless modifiers_match?(data[:mods])
        cmd.call
        FrameworkUtils.mark_restart_needed(record)
        SndLib.send(data[:sound]) if defined?(SndLib) && data[:sound]
      end
    end
  end

  # Reads the Main Menu Toggle key from Input::SYM_KEYS[:CF_CHEAT_MENU] (see
  # hook_vanilla_keybind_menu), not a :MENU-group entry in $framework.hotkeys.
  def self.process_menu_toggle_hotkey
    return if $framework.hotkey_capture_active
    return unless Input.trigger?(:CF_CHEAT_MENU)

    record = $framework.commands.dig(:MENU, "Main Menu")
    cmd = record && record[:action]
    return unless cmd

    if FrameworkUtils.in_menu?
      # Loop since SceneManager.return only pops one level at a time.
      SceneManager.return while FrameworkUtils.in_menu?
    else
      cmd.call # not in menu → open it
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

#============================================================================
# Menu Initialization
#============================================================================
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
        order: opts[:order] || 999,
        default_order: opts[:order] || 999,
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
      key    = opts[:key]
      name   = opts[:name]   # scene/window name, when this command opens one
      type   = opts[:type]
      group  = opts[:group]
      state  = opts[:state]  # only :toggle/:edit_num/:edit_list/:info use this
      gdef   = opts[:gdef]
      hotkey = opts[:hotkey]
      scene  = opts[:scene]
      action = opts[:action]

      #Handle group lookup/creation
      group = group.upcase.to_sym
      $framework.commands[group] ||= {}

      if type == :toggle && !action && state
        action = -> {
          new_val = !eval(state); eval("#{state} = #{new_val}")
          $framework.ini.write_global(key, new_val)
        }
      end

      if !opts[:gdef].nil? && state
        var_name = state[1..-1] # remove $
        default  = gdef

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

      # Snapshot at boot: does the persisted value equal opts[:restart] (its
      # numeric "disabled" sentinel)? Lets restart_mismatch? compare this against whatever the value is now.
      restart_boot_disabled = (opts[:restart].is_a?(Numeric) && state) ? (eval(state) rescue nil) == opts[:restart] : nil

      $framework.commands[group][key] = {
        source: opts[:source],
        type:   opts[:type],
        key:    opts[:key],
        label:  opts[:label],
        action: action,
        state:  opts[:state] ? -> { eval(opts[:state]) } : nil,
        # Raw string form of state:, used by the Local/Global override system.
        state_str: opts[:state],
        help1:  opts[:help1].is_a?(Proc) ? opts[:help1] : (opts[:help1] ? $framework.txt(opts[:help1]) : nil),
        help2:  opts[:help2].is_a?(Proc) ? opts[:help2] : (opts[:help2] ? $framework.txt(opts[:help2]) : nil),
        help3:  opts[:help3].is_a?(Proc) ? opts[:help3] : (opts[:help3] ? $framework.txt(opts[:help3]) : nil),
        help4:  opts[:help4].is_a?(Proc) ? opts[:help4] : (opts[:help4] ? $framework.txt(opts[:help4]) : nil),
        list:   opts[:list],
        min:    opts[:min],
        max:    opts[:max],
        order:  opts[:order] || 999,
        default_order: opts[:order] || 999,
        enable: opts.has_key?(:enable) ? opts[:enable] : true,
        hide:   opts.has_key?(:hide)   ? opts[:hide]   : false,
        color:  opts.has_key?(:color)  ? opts[:color]  : false,
        restart: opts.has_key?(:restart) ? opts[:restart] : false,
        restart_boot_disabled: restart_boot_disabled,
        # Local/Global override eligibility (Config > Edit Globals). nil = not
        # eligible. false = natively Local. true = natively Global.
        global: opts.has_key?(:global) ? opts[:global] : nil
      }
    end
  end
end


#============================================================================
# Main Menu Window Initialization
#============================================================================
class Window_CheatMainMenu < Window_Command
  include MenuFramework::ScrollArrows

  #--------------------------------------------------------------------------
  # Initialize
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0)
    create_scroll_arrows
  end

  def scroll_arrow_tile_count
    1
  end

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
    FrameworkUtils.sorted_commands($framework.commands[:MAIN]).each do |key, record|
      add_command(
        record[:label].is_a?(Proc) ? record[:label].call : $framework.txt(record[:label]),
        :menu_command,
        true,
        record[:key]
      )
    end
  end

end # Window_CheatMainMenu


#---------------------------------------------------------------------------
# Main Menu Scene Initialization
#---------------------------------------------------------------------------
# Restart-needed warning draws into @help_window (otherwise unused here),
# overriding normal_color on that instance to animate its color.
class Scene_CheatMainMenu < Scene_MenuBase
  include Scene_Defaults
  def create_command_window
    super
    @command_window.set_handler(:cancel, method(:return_scene))
  end

  # Full red -> yellow -> red sweep every ~6 seconds at 60fps.
  RESTART_WARNING_STEP = 1.0 / 180

  def start
    super
    @restart_warning_phase = 0.0   # 0.0 = red, 1.0 = yellow
    @restart_warning_rising = true
    @help_window.instance_variable_set(:@restart_warning_color, nil)
    def @help_window.normal_color
      @restart_warning_color || super
    end
  end

  def update
    super
    refresh_restart_warning
  end

  def refresh_restart_warning
    unless $framework.restart_needed
      return unless @help_window.instance_variable_get(:@restart_warning_color)
      @help_window.instance_variable_set(:@restart_warning_color, nil)
      @help_window.contents.clear
      return
    end

    if @restart_warning_rising
      @restart_warning_phase += RESTART_WARNING_STEP
      @restart_warning_rising = false if @restart_warning_phase >= 1.0
    else
      @restart_warning_phase -= RESTART_WARNING_STEP
      @restart_warning_rising = true if @restart_warning_phase <= 0.0
    end
    @restart_warning_phase = [[@restart_warning_phase, 0.0].max, 1.0].min

    # Red (255,0,0) -> yellow (255,255,0): only green needs to move.
    green = (@restart_warning_phase * 255).round
    @help_window.instance_variable_set(:@restart_warning_color, Color.new(255, green, 0))

    @help_window.contents.clear
    MenuFramework.force_font(@help_window.contents)
    @help_window.draw_text_ex(4, 0, $framework.txt("menu:warnings/restart_required"))
  end
end
FrameworkUtils.menu_scenes << Scene_CheatMainMenu

#---------------------------------------------------------------------------
#  Cheat Menu button on the System page, next to Save Game
#---------------------------------------------------------------------------
class Menu_System
  CHEAT_MENU_BUTTON_TEXT = "Cheat Menu"

  alias_method :create_save_game_sprite_CheatFramework, :create_save_game_sprite

  def create_save_game_sprite
    real = create_save_game_sprite_CheatFramework

    spr = Sprite.new(@viewport)
    spr.bitmap = Bitmap.new(180, 30)
    spr.bitmap.font.color.set(*FONT_COLOR)
    spr.bitmap.font.size = 28
    spr.x = real[0].x + 160 + 20
    spr.y = real[0].y
    spr.z = 3
    spr.bitmap.font.outline = false
    spr.bitmap.draw_text(spr.bitmap.rect, CHEAT_MENU_BUTTON_TEXT)
    spr.visible = true
    spr.opacity = OPACITY_INACTIVE
    @all_sprites << spr

    if Mouse.usable?
      text_width  = spr.bitmap.text_size(CHEAT_MENU_BUTTON_TEXT).width
      text_height = spr.bitmap.text_size(CHEAT_MENU_BUTTON_TEXT).height
      # Multi-rect shape (matches every other multi-column row) so
      # mouse_update_input's +1 offset lines up with the column indices.
      @mouse_all_rects[0] = [
        @mouse_all_rects[0][0],
        [spr.x, spr.y, text_width, text_height]
      ]
    end

    [nil, real[0], spr]
  end

  # Lands the cursor on Save Game (column 1), not the nil placeholder at 0.
  alias_method :initialize_CheatFramework, :initialize

  def initialize
    initialize_CheatFramework
    @cursor_column_index = 1
  end

  alias_method :save_command_handler_CheatFramework, :save_command_handler

  def save_command_handler
    if @cursor_column_index == 2
      open_cheat_menu_from_system
    else
      save_command_handler_CheatFramework
    end
  end

  # Skips FrameworkUtils.ingame? on purpose - Scene_Menu is in outgame_scenes.
  def open_cheat_menu_from_system
    SndLib.sys_ok
    SceneManager.call(Scene_CheatMainMenu)
  end

  # Drives row 0's highlight off final cursor state, since it's a
  # multi-column row and the base game's own opacity helpers skip those.
  alias_method :set_cursor_position_CheatFramework, :set_cursor_position

  def set_cursor_position
    set_cursor_position_CheatFramework
    refresh_row0_highlight
  end

  def refresh_row0_highlight
    row = @commands[0][0]
    return unless row.length == 3
    row[1].opacity = OPACITY_INACTIVE
    row[2].opacity = OPACITY_INACTIVE
    row[@cursor_column_index].opacity = OPACITY_ACTIVE if @cursor_row_index == 0
  end
end

# Open Cheat Menu is a rebindable vanilla Key Binds entry. Its key
# (Input::SYM_KEYS[:CF_CHEAT_MENU]) is the single source of truth, also used by View Hotkeys (Controls.rb).
module FrameworkUtils
  def self.hook_vanilla_keybind_menu
    InputUtils.keyList << [
      :CF_CHEAT_MENU,
      "#{$framework.info.id}:menu:commands/cheat_menu_keybind",
      "Open Cheat Menu",
      [:F9]
    ]
  end

  # Resolves the live Main Menu Toggle key to a display string (e.g. "F9"
  # or "M"), for View Hotkeys' own row and HotkeyReserved's dynamic lookup.
  def self.current_menu_toggle_key
    code = Input::SYM_KEYS[:CF_CHEAT_MENU] && Input::SYM_KEYS[:CF_CHEAT_MENU].find { |c| c != 0 }
    return nil unless code
    symbol = InputUtils.reverse_key_map[code]
    return nil unless symbol
    HotkeySymbols.clean_name_for(symbol)
  end
end

# Catches rebinds made through the vanilla Key Binds menu (not just View
# Hotkeys), so the portable backup (config/hotkeys.ini) doesn't go stale.
class CheatFramework
  alias_method :slow_trigger_VanillaKeybind, :slow_trigger

  def slow_trigger
    slow_trigger_VanillaKeybind
    $framework.ini.sync_menu_toggle_key
  end
end

FrameworkUtils.hook_vanilla_keybind_menu

#============================================================================
# Default Category Initialization
#============================================================================
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
  order: 4
)
MenuFramework::MENU.register_command(
  type: :scene,
  key: :edit_npc,
  label: "menu:commands/npc",
  name: "CheatMenuNPCOptions",
  dict: :NPC,
  order: 6
)
MenuFramework::MENU.register_command(
  type: :scene,
  key: :config_menu,
  label: "menu:commands/config",
  name: "CheatMenuConfiguration",
  dict: :CONFIG,
  order: 1000
)
