#==============================================================================
#  CheatsSystem
#------------------------------------------------------------------------------
#  Handles config loading, saving, and tracking of hotkeys, variables,
#  and per-module enable/disable states.
#==============================================================================

class CheatsSystem
  attr_reader :mod_ini
  attr_reader :key_ini
  attr_reader :var_ini

  # ------------------------
  # Initialize and load INI
  # ------------------------
  def initialize(config_dir)
    #Dir.mkdir(config_dir) unless Dir.exist?(config_dir)

    @mod_ini = load_or_create(File.join(config_dir, "cheats_modules.ini"))
    @key_ini = load_or_create(File.join(config_dir, "cheats_hotkeys.ini"))
    @var_ini = load_or_create(File.join(config_dir, "cheats_variables.ini"))
  end

  def load_or_create(path)
    unless File.exist?(path)
      ini = IniFile.new(filename: path)
      ini.write
    end
    IniFile.load(path)
  end

  # ------------------------
  # Generic read/write
  # ------------------------
  def read(section, key, default = nil, type = :string)
    value = if @var_ini.has_section?(section) && @var_ini[section].has_key?(key)
              @var_ini[section][key]
            else
              default
            end
    cast_value(value, type)
  end

  def write(section, key, value)
    @var_ini[section] ||= {}
    @var_ini[section][key] = value.to_s
    @var_ini.save
  end

  def save
    @var_ini.save
  end

  def reset_module(module_id)
    @var_ini.delete_section(module_id)
    @var_ini.save
  end

  # ------------------------
  # Hotkey helpers
  # ------------------------
  def read_menu_hotkey
    key_str = read("Cheats Mod - Hotkeys", "CheatMenu", "F9")
    $mod_cheats.hotkey = key_str.to_sym
  end

  def read_hotkey(module_id, command_id, default = nil)
    section = module_id.to_s
    key = "Hotkey_#{command_id}"
    @key_ini[section] ||= {}
    cast_value(@key_ini[section][key] || default, :string)
  end

  def write_hotkey(module_id, command_id, keycode)
    section = module_id.to_s
    @key_ini[section] ||= {}
    @key_ini[section]["Hotkey_#{command_id}"] = keycode.to_s
    @key_ini.save
  end

  # ------------------------
  # Variable helpers
  # ------------------------
  def read_var(module_id, var_name, default = nil)
    section = module_id.to_s
    key = "Var_#{var_name}"
    return default unless @var_ini.has_section?(section) && @var_ini[section].has_key?(key)
    parse_value(@var_ini[section][key])
  end

  def write_var(module_id, var_name, value, persist = :global)
    section = module_id.to_s
    @var_ini[section] ||= {}
    @var_ini[section]["Var_#{var_name}"] = value.to_s
    @var_ini[section]["Var_#{var_name}_Persist"] = persist.to_s
    @var_ini.save
  end

  # ------------------------
  # Module enable/disable helpers
  # ------------------------
  def ensure_module_registered(module_id)
    @mod_ini["Modules"] ||= {}
    unless @mod_ini["Modules"].has_key?(module_id)
      @mod_ini["Modules"][module_id] = "true"
      @mod_ini.save
    end
  end

  def is_enabled?(module_id, default = true)
    ensure_module_registered(module_id)
    val = @mod_ini["Modules"][module_id]
    val.nil? ? default : cast_value(val, :boolean)
  end

  def set_enabled(module_id, enabled)
    @mod_ini["Modules"][module_id] = enabled ? "true" : "false"
    @mod_ini.save
  end

  def enabled_modules
    return {} unless @var_ini.has_section?("Modules")
    result = {}
    @var_ini["Modules"].each do |mod_id, val|
      result[mod_id] = cast_value(val, :boolean)
    end
    result
  end

  def module_load_order(module_id)
    read("Modules", "#{module_id}_Order", 0, :integer)
  end

  def set_module_load_order(module_id, order)
    @mod_ini["Modules"] ||= {}
    @mod_ini["Modules"]["#{module_id}_Order"] = order.to_s
    @mod_ini.save
    write("Modules", "#{module_id}_Order", order)
  end

  def register_module_info(module_id, args={})
    name = args[:name]
    version = args[:version]
    desc = args[:desc] || ""
    write("ModulesInfo", "#{module_id}_Name", name)
    write("ModulesInfo", "#{module_id}_Version", version)
    write("ModulesInfo", "#{module_id}_Desc", desc)
  end

  # ------------------------
  # Utility methods
  # ------------------------
  private

  def cast_value(val, type)
    return val if val.nil?
    case type
    when :boolean
      return true  if val.to_s.downcase == "true"
      return false if val.to_s.downcase == "false"
      !!val
    when :integer
      val.to_i
    when :float
      val.to_f
    else
      val.to_s
    end
  end

  def parse_value(val)
    case val.to_s
    when /^true$/i then true
    when /^false$/i then false
    when /^\d+$/ then val.to_i
    when /^\d+\.\d+$/ then val.to_f
    else
      val
    end
  end
end
