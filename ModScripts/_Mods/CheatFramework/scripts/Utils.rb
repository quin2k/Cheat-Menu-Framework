#===============================================================================
#  Cheat Utilities
#------------------------------------------------------------------------------
#  Provides utility functions for the Cheat Framework.
#===============================================================================

#--------------------------------------------------------------------------
# Table of physical F-keys claimed outside CheatFramework
#--------------------------------------------------------------------------
module HotkeyReserved
  TABLE = {
    "F10" => { label: "Console",              active: -> { true } },
    "F5"  => { label: "RolePlay-S QuickSave", active: -> { $framework.roleplay_mod? } },
    "F6"  => { label: "RolePlay-S QuickLoad", active: -> { $framework.roleplay_mod? } },
    # Blocked at the OS level by 10_removeF1F12.rb, not assignable in Ruby.
    "F1"  => { label: "Disabled by the game itself (F1AltEnterF12.dll)", active: -> { true } },
    "F12" => { label: "Disabled by the game itself (F1AltEnterF12.dll)", active: -> { true } },
  }

  # Main Menu Toggle key is resolved dynamically via
  # FrameworkUtils.current_menu_toggle_key (scripts/Menu.rb) rather than a static TABLE entry.
  def self.info_for(key)
    key_str = key.to_s.upcase
    return { label: "Main Menu Toggle", active: true } if key_str == FrameworkUtils.current_menu_toggle_key
    entry = TABLE[key_str]
    return nil unless entry
    entry[:active].call ? entry : nil
  end

  # Strips any Shift+/Ctrl+/Alt+ prefix and checks just the base F-key.
  def self.info_for_combo(key_str)
    return nil unless key_str
    info_for(key_str.to_s.split('+').last)
  end
end

#--------------------------------------------------------------------------
# Hotkey Display Names
#--------------------------------------------------------------------------
# Punctuation entries are leftover X11 keysym names reused for Windows VK_OEM_*
# keys, not literal. LETTER_C is excluded - it's the hotkey-capture arm/disarm key.
module HotkeySymbols
  DISPLAY_NAMES = {
    LETTER_A: "A", LETTER_B: "B", LETTER_D: "D", LETTER_E: "E", LETTER_F: "F",
    LETTER_G: "G", LETTER_H: "H", LETTER_I: "I", LETTER_J: "J", LETTER_K: "K",
    LETTER_L: "L", LETTER_M: "M", LETTER_N: "N", LETTER_O: "O", LETTER_P: "P",
    LETTER_Q: "Q", LETTER_R: "R", LETTER_S: "S", LETTER_T: "T", LETTER_U: "U",
    LETTER_V: "V", LETTER_W: "W", LETTER_X: "X", LETTER_Y: "Y", LETTER_Z: "Z",
    KEY_1: "1", KEY_2: "2", KEY_3: "3", KEY_4: "4", KEY_5: "5",
    KEY_6: "6", KEY_7: "7", KEY_8: "8", KEY_9: "9", N0: "0",
    masculine: ";", guillemotright: "=", onequarter: ",", onehalf: "-",
    threequarters: ".", questiondown: "/", Ucircumflex: "[", Udiaeresis: "\\",
    Yacute: "]", THORN: "'"
  }
  SYMBOLS_BY_NAME = DISPLAY_NAMES.invert

  def self.symbols
    DISPLAY_NAMES.keys
  end

  def self.name_for(symbol)
    DISPLAY_NAMES[symbol]
  end

  def self.symbol_for(name)
    SYMBOLS_BY_NAME[name]
  end

  # Unlike name_for, always returns something displayable, including symbols
  # the table excludes (like :LETTER_C) by stripping the RGSS-internal prefix directly.
  def self.clean_name_for(symbol)
    return name_for(symbol) if DISPLAY_NAMES.key?(symbol)
    str = symbol.to_s
    return "0" if str == "N0"
    return str.sub("LETTER_", "") if str.start_with?("LETTER_")
    return str.sub("KEY_", "")    if str.start_with?("KEY_")
    str
  end
end

#--------------------------------------------------------------------------
# FrameworkUtils
#--------------------------------------------------------------------------
module FrameworkUtils
  class << self
    attr_accessor :menu_scenes
  end
  #List of Scenes classed as being out of game
  @outgame_scenes = [
    ModManagerScene,
    Scene_MapTitle,
    Scene_AdultContentWarning,
    Scene_FirstTimeSetup,
    Scene_Title,
    Scene_TitleOptions,
    Scene_TitleOptInputMenu,
    Scene_ACHlistMenu,
    Scene_Credits,
    Scene_Menu,
    Scene_File,
    Scene_Save,
    Scene_Load_OnGameMenu,
    Scene_Load
  ]
  @menu_scenes = []
  #Check if a game is loaded
  def self.ingame?
    return (!@outgame_scenes.any? {
      |outgame_scene|
      SceneManager.scene_is?(outgame_scene)
    } and $loading_screen.disposed?)
  end

  def self.in_menu?
    @menu_scenes.any? { |scene_class| SceneManager.scene_is?(scene_class) }
  end

  # True if this hotkey's physical key is already bound to one of the game's
  # own controls (Input::SYM_KEYS, live-updated by Key Binds). F-keys never go through this check.
  def self.claimed_by_game_controls?(key_const)
    vk_code = Input::KEYMAP[key_const]
    return false unless vk_code
    Input::SYM_KEYS.values.any? { |codes| codes.include?(vk_code) }
  end

  def self.custom_state_edit(state, new_value)
    actor = $game_player.actor
    state_id = state
    change = new_value - (actor.stat[state_id] || 0)
    if change == 0
      return
    elsif change < 0
      change.abs.times { actor.remove_state_stack(state_id) }
    elsif change > 0
      change.times { actor.add_state(state_id) }
    end
  end

  # Sorts a $framework.commands dict by :order, using registration order as a tiebreaker.
  def self.sorted_commands(dictionary)
    return [] unless dictionary
    dictionary.to_a.each_with_index
              .sort_by { |(_key, record), idx| [record[:order] || 999, idx] }
              .map { |pair, _idx| pair }
  end

  # For restart: <number> commands, true if the live value's on/off state now
  # disagrees with what was snapshotted at boot (restart_boot_disabled).
  def self.restart_mismatch?(record)
    return false unless record && record[:restart].is_a?(Numeric) && record[:state]
    boot_disabled = record[:restart_boot_disabled]
    return false if boot_disabled.nil?
    current_val = record[:state].call rescue nil
    return false if current_val.nil?
    (current_val == record[:restart]) != boot_disabled
  end

  # Flags that a restart is needed: on every change for restart: true, or only
  # when the change crosses the disabled/enabled boundary for restart: <number>.
  def self.mark_restart_needed(record)
    return unless record && record[:restart]
    if record[:restart].is_a?(Numeric)
      $framework.restart_needed = true if restart_mismatch?(record)
    else
      $framework.restart_needed = true
    end
  end

  # Hotkey address lookup for the current row (Action_Window_Defaults).
  def self.group_for_dictionary(dict)
    return nil unless dict
    entry = $framework.commands.find { |_group, d| d.equal?(dict) }
    entry ? entry[0] : nil
  end

  def self.hotkey_tag_for(dict, key)
    return nil unless key
    group = group_for_dictionary(dict)
    return nil unless group
    data = $framework.hotkey_defs["#{group}.#{key}"]
    return nil if data.nil? || data[:key].nil? || data[:key].to_s.upcase == "NONE"
    "[#{data[:key]}]"
  end

  # Resolves a command's display name, falling back to `fallback` if it has no label:.
  def self.display_name_for(record, fallback)
    return fallback.to_s unless record
    label = record[:label]
    if label.is_a?(Proc)
      label.call
    elsif label
      $framework.txt(label) rescue fallback.to_s
    else
      fallback.to_s
    end
  end

end

#--------------------------------------------------------------------------
# Overrides to remove debug massaging in SceneManager
#--------------------------------------------------------------------------
class Scene_Base
  def return_scene
    SceneManager.return
  end
end

module SceneManager
  def self.call(scene_class)
		@stack.push(@scene)
		@scene = scene_class.new
	end

  def self.return
    @scene = @stack.pop
  end
end

#--------------------------------------------------------------------------
# Window Base adjustment to reduce padding
#--------------------------------------------------------------------------
class Window_Base < Window
  def new_line_x
    standard_padding / 2
  end
end

#--------------------------------------------------------------------------
# Scene Base update override to include cheat triggers
#--------------------------------------------------------------------------
class Scene_Base
  alias_method :update_Framework, :update

  def update
    update_Framework
    $framework.hotkey_trigger if FrameworkUtils.ingame?
  end
end

#--------------------------------------------------------------------------
# Block the debug console (F10) while actively assigning a hotkey
#--------------------------------------------------------------------------
class Scene_Base
  alias_method :trigger_debug_window_entry_CheatFramework, :trigger_debug_window_entry

  def trigger_debug_window_entry
    return if $framework.hotkey_capture_active
    trigger_debug_window_entry_CheatFramework
  end
end

#--------------------------------------------------------------------------
# Calls $framework.on_save_ready after a new game or a loaded save
#--------------------------------------------------------------------------
# Three hooks for full coverage: a fresh game, Scene_Load (title-screen and
# in-game load), and Scene_CustomModeLoad (auto-saves, Doom-mode save, RolePlay-S quickload).
module DataManager
  class << self
    alias_method :setup_new_game_CheatFramework, :setup_new_game

    def setup_new_game(*args)
      setup_new_game_CheatFramework(*args)
      $framework.on_save_ready
    end
  end
end

class Scene_Load
  alias_method :on_load_success_CheatFramework, :on_load_success

  def on_load_success
    on_load_success_CheatFramework
    $framework.on_save_ready
  end
end

class Scene_CustomModeLoad
  alias_method :on_load_success_CheatFramework, :on_load_success

  def on_load_success
    on_load_success_CheatFramework
    $framework.on_save_ready
  end
end

# Applies every global: true/false command's configured override.
class CheatFramework
  alias_method :on_save_ready_FORCE_MODES, :on_save_ready

  def on_save_ready
    on_save_ready_FORCE_MODES
    FrameworkUtils.apply_force_modes
  end
end

# Sets the update rate for other triggers.
class CheatFramework
  alias_method :hotkey_trigger_TIMER, :hotkey_trigger

  def hotkey_trigger
    hotkey_trigger_TIMER
    frame = Graphics.frame_count
    @last_normal_check ||= 0
    @last_slow_check ||= 0

    # Every ~1 second
    if frame - @last_normal_check >= 40
      @last_normal_check = frame
      normal_trigger
    end

    # Every ~3 seconds
    if frame - @last_slow_check >= 120
      @last_slow_check = frame
      slow_trigger
    end
  end
end

#--------------------------------------------------------------------------
# Add extra triggerable keys to Input module
#--------------------------------------------------------------------------
module Input
  F1 = [KEYMAP[:F1]]
  F2 = [KEYMAP[:F2]]
  F3 = [KEYMAP[:F3]]
  F4 = [KEYMAP[:F4]]
  Agrave = [KEYMAP[:Agrave]]
end

