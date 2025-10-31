class CheatsConfig
  attr_reader :ini, :ini_file

  # ------------------------
  # Initialize and load INI
  # ------------------------
  def initialize(ini_file)
    @ini_file = ini_file
    unless File.exist?(ini_file)
      @ini = IniFile.new
      @ini.filename = ini_file
      @ini.write
      #sleep 1 <- comment out to see if necessary
    end
    #sleep 0.1 <- comment out to see if necessary
    @ini = IniFile.load(ini_file)
    #sleep 0.9 <- comment out to see if necessary
  end

  # ------------------------
  # Generic read/write
  # ------------------------
  def read(module_id, key, default = nil, type = :string)
    value = if @ini.has_section?(module_id) && @ini[module_id].has_key?(key)
              @ini[module_id][key]
            else
              default
            end
    cast_value(value, type)
  end

  def write(module_id, key, value)
    @ini[module_id] ||= {}
    @ini[module_id][key] = value.to_s
    @ini.save
  end

  # ------------------------
  # Hotkey helpers
  # ------------------------
  # Returns a hash { :F3 => "module.command", :SHIFT_F3 => "module.command" }
  def read_hotkey_menu
    # defaults to F9
    key_str = read("Cheats Mod - Hotkeys", "CheatMenu", "F9")
    $mod_cheats.hotkey = key_str.to_sym
  end

  def read_hotkeys(module_id)
    result = {}
    return result unless @ini.has_section?(module_id)

    @ini[module_id].each do |key, value|
      next unless key.start_with?("Hotkey_")
      hotkey_name = key.sub("Hotkey_", "")
      result[hotkey_name.to_sym] = value
    end
    result
  end

  # ------------------------
  # Variable helpers
  # ------------------------
  # Returns a hash { var_name => { value:, persist: } }
  def read_vars(module_id)
    result = {}
    return result unless @ini.has_section?(module_id)

    @ini[module_id].each do |key, value|
      next unless key.start_with?("Var_")
      var_name = key.sub("Var_", "")
      persist_key = "Var_#{var_name}_Persist"
      persist = @ini[module_id].fetch(persist_key, "global").to_sym
      result[var_name.to_sym] = { value: parse_value(value), persist: persist }
    end
    result
  end

  # write variable and optionally persist scope
  def write_var(module_id, var_name, value, persist = :global)
    write(module_id, "Var_#{var_name}", value)
    write(module_id, "Var_#{var_name}_Persist", persist.to_s)
  end

  # ------------------------
  # Utility methods
  # ------------------------
  private

  # Convert string to proper type
  def cast_value(val, type)
    return val if val.nil?

    case type
    when :boolean
      return true if val.to_s.downcase == "true"
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

  # Attempt to parse value automatically
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
