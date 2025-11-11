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
    path = File.join(config_dir, "framework.ini")
    write_default_ini(path) unless File.exist?(path)
    @ini = load_or_create(path)
  end

  def load_or_create(path)
    ini = IniFile.load(path)
    unless ini
      ini = IniFile.new(filename: path)
      ini.write
    end
    @ini = ini
  end

  # ------------------------
  # Read / write helpers
  # ------------------------
  def read(section, key, default = "")
    @ini.read if @ini.respond_to?(:read)
    if @ini.has_section?(section) && @ini[section].has_key?(key)
      @ini[section][key]
    else
      default
    end
  end

  def write(section, key, value)
    @ini[section] ||= {}
    @ini[section][key] = value
    @ini.write
  end

  # ------------------------
  # Mod override handlers
  # ------------------------
  def get_enabled(key, default = true)
    val = read("Module Load Overrides", key, default).to_s.downcase
    return true  if ["true", "1", "yes"].include?(val)
    return false if ["false", "0", "no"].include?(val)
    default
  end

  def get_load_order(key, default = 999)
    val = read("Load Order Overrides", key, default)
    val.to_i.nonzero? || default
  end

  # ------------------------
  # Global variables handlers
  # ------------------------
  def read_global(key, default)
    value = read("Global Variables", key, default)
    Object.instance_eval("$#{sanitize_key(key)} = #{format_value(value)}")
    value
  end

  def write_global(key, value)
    write("Global Variables", key, value)
  end

  # ------------------------
  # Hotkey handling
  # ------------------------
  def init_hotkeys
    compare_hotkeys_to_ini
    save_hotkeys_to_ini
    build_hotkey_map
  end

  def compare_hotkeys_to_ini
    section = "Cheat Hotkeys"
    return unless @ini.has_section?(section)

    @ini[section].each do |full_key, value|
      next if value.nil? || value.strip.empty?

      # Normalize
      value = value.strip
      full_key = full_key.gsub(/["']/, '') # strip quotes

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
    @ini[section] ||= {}

    $framework.hotkey_defs.each do |full_key, data|
      key_name = "\"#{full_key}\""
      value = data[:key] || "NONE"
      @ini[section][key_name] = value
    end

    @ini.write
  end

  def build_hotkey_map
    $framework.hotkeys = Hash.new { |h, k| h[k] = [] }

    $framework.hotkey_defs.each do |full_key, data|
      next if data[:key].nil? || data[:key].upcase == "NONE"

      mods, base = parse_hotkey(data[:key])
      key_const  = Input.const_get(base) rescue nil
      next unless key_const

      group, key = full_key.split('.', 2)
      $framework.hotkeys[key_const] << {
        group: group.to_sym,
        key: key, # e.g. :F9 or :F3
        mods: mods, # e.g. [:SHIFT, :CTRL]
        sound: data[:sound]
      }
    end
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
        base = p.upcase.to_sym
      end
    end

    [mods, base]
  end

  # ------------------------
  # Ensure config structure exists
  # ------------------------
  def write_default_ini(path)
    initial_text = [
      "[Cheat Hotkeys]","# To disable a default hotkey, enter NONE instead of the key.","",
      "[Global Variables]","# Edit with caution, malformed entries could cause load issues.","",
      "[Load Order Overrides]","# Should be unnecessary, as there are auto-resolve functions.","",
      "[Module Load Overrides]","# Disables modules they are causing issues - also let me know!!","",
      "[Main Menu Command Order]","# Override display order of main menu","",
      "[Character Command Order]","# Override display order of misc menu","",
      "[Toggles Command Order]","# Override display order of toggles menu","",
      "[Misc Command Order]","# Override display order of misc menu",""
    ]

    File.open(path, "w") { |f| initial_text.each { |line| f.puts(line) } }
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




