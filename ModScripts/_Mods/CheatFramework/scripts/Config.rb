#==============================================================================
#  CheatConfig
#------------------------------------------------------------------------------
#  Handles config loading, saving, and tracking of hotkeys, variables,
#  and per-module enable/disable states.
#==============================================================================

class FrameworkConfig
  attr_reader :mod_ini
  attr_reader :key_ini
  attr_reader :var_ini

  # ------------------------
  # Initialize and load INI files
  # ------------------------
  def initialize(config_dir)
    Dir.mkdir(config_dir) unless Dir.exist?(config_dir)
    @key_ini = load_or_create(File.join(config_dir, "hotkeys.ini"))
    @var_ini = load_or_create(File.join(config_dir, "globals.ini"))
    @mod_ini = load_or_create(File.join(config_dir, "modules.ini"))
  end

  def load_or_create(path)
    ini = IniFile.load(path)
    unless ini
      ini = IniFile.new(filename: path)
      ini.write
    end
    return ini
  end

  # ------------------------
  # Read / write helpers
  # ------------------------
  def read(section, key, default = "", ini)
    ini.read if ini.respond_to?(:read)
    if ini.has_section?(section) && ini[section].key?(key)
      ini[section][key]
    else
      default
    end
  end

  def write(section, key, value, ini)
    ini[section] ||= {}
    ini[section][key] = value
    ini.write
  end

  # ------------------------
  # Mod override handlers
  # ------------------------
  def get_enabled(key, default = true)
    val = read("Module Load Overrides", key, default, @mod_ini).to_s.downcase
    return true  if ["true", "1", "yes"].include?(val)
    return false if ["false", "0", "no"].include?(val)
    default
  end

  def get_load_order(key, default = 999)
    val = read("Load Order Overrides", key, default, @mod_ini)
    val.to_i.nonzero? || default
  end

  # ------------------------
  # Global variables handlers
  # ------------------------
  def read_global(key, default)
    value = read("Global Variables", key, default, @var_ini)
    Object.instance_eval("$#{sanitize_key(key)} = #{format_value(value)}")
    value
  end

  def write_global(key, value)
    write("Global Variables", key, value, @var_ini)
  end

  # ------------------------
  # Hotkey handling
  # ------------------------
  def init_hotkeys
    compare_hotkeys_to_ini
    clear_conflicting_hotkeys
    save_hotkeys_to_ini
    build_hotkey_map
  end

  # Self-clears any of our own hotkeys sitting on a key HotkeyReserved flags.
  # The menu toggle's own key never appears in hotkey_defs at all anymore
  # (see Input::SYM_KEYS[:CF_CHEAT_MENU], scripts/Menu.rb), so there's no
  # self-exclusion to worry about here.
  def clear_conflicting_hotkeys
    $framework.hotkey_defs.each do |full_key, data|
      next unless data[:key]
      next unless HotkeyReserved.info_for_combo(data[:key])
      data[:key] = "NONE"
    end
  end

  def compare_hotkeys_to_ini
    section = "Cheat Hotkeys"
    return unless @key_ini.has_section?(section)

    @key_ini[section].each do |full_key, value|
      next if value.nil?

      # IniFile auto-typecasts a bare digit ("6") into an Integer on read -
      # a real possibility now that digit keys are assignable hotkeys.
      value = value.to_s.strip
      next if value.empty?

      # Handle NONE → disable
      if value.upcase == "NONE"
        if $framework.hotkey_defs.key?(full_key)
          $framework.hotkey_defs[full_key][:key] = "NONE"
        else
          $framework.hotkey_defs[full_key] = { key: "NONE", sound: nil }
        end
        next
      end

      # Otherwise, override or add
      if $framework.hotkey_defs.key?(full_key)
        $framework.hotkey_defs[full_key][:key] = value
      else
        $framework.hotkey_defs[full_key] = { key: value, sound: nil }
      end
    end
  end

  def save_hotkeys_to_ini
    section = "Cheat Hotkeys"
    @key_ini[section] ||= {}

    $framework.hotkey_defs.each do |full_key, data|
      key_name = "#{full_key}"
      value = data[:key] || "NONE"
      @key_ini[section][key_name] = value
    end

    @key_ini.write
  end

  def build_hotkey_map
    $framework.hotkeys = Hash.new { |h, k| h[k] = [] }

    $framework.hotkey_defs.each do |full_key, data|
      next if data[:key].nil? || data[:key].upcase == "NONE"

      mods, base = parse_hotkey(data[:key])
      key_const = base

      group, key = full_key.split('.', 2)
      $framework.hotkeys[key_const] << {
        group: group.to_sym,
        key: key,
        mods: mods,
        sound: data[:sound]
      }
    end
  end

  # ------------------------
  # Main Menu Toggle key (portable backup)
  # ------------------------
  # Input::SYM_KEYS[:CF_CHEAT_MENU]/$LonaINI (the game's own Key Binds menu)
  def init_menu_toggle_key
    if menu_toggle_key_configured_in_game?
      Input::SYM_KEYS[:CF_CHEAT_MENU] = (0..2).map do |i|
        val = $LonaINI["Keyboard"]["CF_CHEAT_MENU_#{i}"]
        (val && val != 0 && val != "0") ? (Input::KEYMAP[val.to_sym] || 0) : 0
      end
      live = FrameworkUtils.current_menu_toggle_key
      save_menu_toggle_key(live) if live
    else
      saved_key = @key_ini["Main Menu Toggle"]["key"]
      saved_key = "F9" if saved_key.nil? || saved_key.to_s.strip.empty?
      apply_menu_toggle_key(saved_key)
    end
  end

  def menu_toggle_key_configured_in_game?
    (0..2).any? { |i| $LonaINI["Keyboard"].key?("CF_CHEAT_MENU_#{i}") }
  end

  def apply_menu_toggle_key(key_str)
    key_sym = HotkeySymbols.symbol_for(key_str) || key_str.to_sym
    Input::SYM_KEYS[:CF_CHEAT_MENU] = [Input::KEYMAP[key_sym] || Input::KEYMAP[:F9], 0, 0]
    InputUtils.save_keyboard_settings
    save_menu_toggle_key(key_str)
  end

  def save_menu_toggle_key(key_str)
    @key_ini["Main Menu Toggle"]["key"] = key_str
    @key_ini.write
  end

  # Catches rebinds made through the vanilla Key Binds menu.
  def sync_menu_toggle_key
    live = FrameworkUtils.current_menu_toggle_key
    return unless live
    return if live == @key_ini["Main Menu Toggle"]["key"]
    save_menu_toggle_key(live)
  end

  # ------------------------
  # Menu order handling
  # ------------------------
  def init_order
    compare_order_to_ini
    save_order_to_ini
  end

  def compare_order_to_ini
    section = "Menu Order Overrides"
    return unless @mod_ini.has_section?(section)

    @mod_ini[section].each do |full_key, value|
      next if value.nil? || value.to_s.strip.empty?

      group_key, cmd_key = full_key.split('.', 2)
      next unless group_key && cmd_key

      dict = $framework.commands[group_key.to_sym]
      next unless dict

      record = dict[cmd_key] || dict[cmd_key.to_sym]
      next unless record

      record[:order] = value.to_i
    end
  end

  def save_order_to_ini
    section = "Menu Order Overrides"
    @mod_ini[section] ||= {}

    $framework.commands.each do |group, dict|
      next unless dict.is_a?(Hash)

      dict.each do |key, record|
        next unless record.is_a?(Hash) && record.key?(:order)
        @mod_ini[section]["#{group}.#{key}"] = record[:order]
      end
    end

    @mod_ini.write
  end

  # Wipes all custom menu ordering back to each command's registered default.
  def reset_menu_order
    $framework.commands.each do |_group, dict|
      next unless dict.is_a?(Hash)
      dict.each do |_key, record|
        next unless record.is_a?(Hash) && record.key?(:default_order)
        record[:order] = record[:default_order]
      end
    end

    @mod_ini.delete_section("Menu Order Overrides")
    @mod_ini.write
  end

  # In-memory session for Edit Menu Order's Save/Discard confirm flow.
  def start_menu_order_session
    snapshot = {}
    $framework.commands.each do |group, dict|
      next unless dict.is_a?(Hash)
      dict.each do |key, record|
        next unless record.is_a?(Hash) && record.key?(:order)
        snapshot["#{group}.#{key}"] = record[:order]
      end
    end
    $framework.menu_order_snapshot = snapshot
    $framework.menu_order_dirty = false
  end

  def mark_menu_order_dirty
    $framework.menu_order_dirty = true
  end

  def menu_order_dirty?
    !!$framework.menu_order_dirty
  end

  def revert_menu_order_session
    return unless $framework.menu_order_snapshot
    $framework.menu_order_snapshot.each do |full_key, order|
      group_key, cmd_key = full_key.split('.', 2)
      dict = $framework.commands[group_key.to_sym]
      next unless dict
      record = dict[cmd_key] || dict[cmd_key.to_sym]
      next unless record
      record[:order] = order
    end
    clear_menu_order_session
  end

  def clear_menu_order_session
    $framework.menu_order_snapshot = nil
    $framework.menu_order_dirty = false
  end

  # ------------------------
  # Local/Global override handling (Config > Edit Globals)
  # ------------------------
  # Unlike menu order/hotkeys, these two actively prune stale entries instead
  # of leaving them unused.
  def init_force_modes
    compare_force_modes_to_ini
    save_force_modes_to_ini
  end

  def compare_force_modes_to_ini
    section = "Force Mode Overrides"
    return unless @mod_ini.has_section?(section)

    @mod_ini[section].each do |full_key, value|
      next if value.nil? || value.to_s.strip.empty?
      next unless global_override_eligible?(full_key)

      $framework.force_modes[full_key] = coerce_ini_value(value) == true
    end
  end

  def save_force_modes_to_ini
    section = "Force Mode Overrides"
    @mod_ini.delete_section(section)
    @mod_ini[section] = {}

    $framework.force_modes.each do |full_key, mode|
      @mod_ini[section][full_key] = mode
    end

    @mod_ini.write
  end

  def init_force_values
    compare_force_values_to_ini
    save_force_values_to_ini
  end

  def compare_force_values_to_ini
    section = "Force Value Overrides"
    return unless @mod_ini.has_section?(section)

    @mod_ini[section].each do |full_key, value|
      next if value.nil? || value.to_s.strip.empty?
      next unless global_override_eligible?(full_key)

      $framework.force_values[full_key] = coerce_ini_value(value)
    end
  end

  def save_force_values_to_ini
    section = "Force Value Overrides"
    @mod_ini.delete_section(section)
    @mod_ini[section] = {}

    $framework.force_values.each do |full_key, value|
      @mod_ini[section][full_key] = value
    end

    @mod_ini.write
  end

  # True if "GROUP.CommandKey" still resolves to a global:-flagged command.
  def global_override_eligible?(full_key)
    group_key, cmd_key = full_key.split('.', 2)
    return false unless group_key && cmd_key

    dict = $framework.commands[group_key.to_sym]
    return false unless dict

    record = dict[cmd_key] || dict[cmd_key.to_sym]
    !!(record && !record[:global].nil?)
  end

  # IniFile typecasts numbers on its own; this adds true/false.
  def coerce_ini_value(value)
    return value unless value.is_a?(String)
    return true  if value.downcase == "true"
    return false if value.downcase == "false"
    value
  end

  # ------------------------
  # Full reset (Config > Reset All Settings)
  # ------------------------
  def reset_all_settings
    @mod_ini.delete_section("Module Load Overrides")
    @mod_ini.delete_section("Load Order Overrides")
    @mod_ini.write

    @var_ini.delete_section("Global Variables")
    @var_ini.write
  end

  def reset_hotkeys_live
    $framework.hotkey_defs = $framework.hotkey_defaults.each_with_object({}) { |(k, v), h| h[k] = v.dup }
    clear_conflicting_hotkeys
    @key_ini.delete_section("Cheat Hotkeys")
    save_hotkeys_to_ini
    build_hotkey_map

    apply_menu_toggle_key("F9")
  end

  def reset_force_overrides
    $framework.force_modes.clear
    $framework.force_values.clear
    @mod_ini.delete_section("Force Mode Overrides")
    @mod_ini.delete_section("Force Value Overrides")
    @mod_ini.write
  end

  def parse_hotkey(hotkey_str)
    parts = hotkey_str.split('+').map(&:strip)
    mods = []
    base = nil

    parts.each do |p|
      case p.downcase
      when "shift"   then mods << :SHIFT
      when "ctrl", "control" then mods << :CTRL
      when "alt"     then mods << :ALT
      else
        base = HotkeySymbols.symbol_for(p) || p.upcase.to_sym
      end
    end

    [mods, base]
  end

  # ------------------------
  # Special handlers
  # ------------------------
  private

  def sanitize_key(key)
    key.to_s.strip.gsub(/\s+/, "_").downcase
  end

  def format_value(value)
    return "\"#{value}\"" if value.is_a?(String) && value !~ /^\d+$/
    value
  end
end
