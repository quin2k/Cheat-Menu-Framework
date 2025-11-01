#===============================================================================
#  CheatsModManager
#------------------------------------------------------------------------------
#  Handles discovery, registration, and loading of modular cheat components
#===============================================================================

class CheatsModManager
  attr_reader :root_path
  attr_reader :modules 
  attr_reader :loaded 
  attr_reader :sys

  def initialize(root_path, sys = nil)
    @root_path = root_path
    @sys = sys || CheatsSystem.new(File.join(root_path, "_system"))
    @modules = {}   # { id => CheatModule }
    @loaded = []
  end

  #-------------------------------------------------------------------------
  # Discover and load bootstrap files
  #-------------------------------------------------------------------------
  def discover
    unless Dir.exist?(@root_path)
      puts "[CheatsModManager] No modules directory found at #{@root_path}"
      return
    end

    Dir.entries(@root_path).each do |entry|
      next if entry == "." || entry == ".." || entry.start_with?("_")
      full = File.join(@root_path, entry)
      id   = entry.sub(/\.rb$/, "")
      load_module_files(full, id)
    end

    puts "[CheatsModManager] Discovered #{@modules.size} registered modules"
  end

  #-------------------------------------------------------------------------
  # Called by modules to self-register
  #-------------------------------------------------------------------------
  def register(args = {})
    id           = args[:id]
    name         = args[:name]
    version      = args[:version] || "1.0"
    priority     = (args[:priority] || 100).to_i
    desc         = args[:desc] || ""
    dependencies = args[:dependencies] || []

    info = {
      id: id,
      name: name,
      version: version,
      desc: desc,
      priority: priority,
      dependencies: dependencies,
      enabled: @sys.nil? ? true : @sys.is_enabled?(id),
      loaded: false,
      commands: {},
      hotkeys: {},
      variables: {}
    }

    @modules[id] = info

    if @sys
      @sys.ensure_module_registered(id)
      @sys.set_module_load_order(id, priority)
      @sys.register_module_info(id, name: name, version: version, desc: desc)
    end

    CheatModule.new(self, info)
  end

  #-------------------------------------------------------------------------
  # Load all enabled modules with dependency & priority handling
  #-------------------------------------------------------------------------
  def load_all
    sorted = @modules.values.sort_by { |m| m[:priority] }

    sorted.each do |mod|
      next if mod[:loaded]
      next unless mod[:enabled]

      missing = mod[:dependencies].reject { |dep| @modules.key?(dep) && @modules[dep][:enabled] }
      unless missing.empty?
        puts "[CheatsModManager] Skipping #{mod[:id]} (missing deps: #{missing.join(', ')})"
        next
      end

      mod[:dependencies].each do |dep|
        load_module(dep) unless @modules[dep][:loaded] rescue nil
      end

      begin
        load_module(mod[:id])
      rescue => e
        puts "[CheatsModManager] Failed to load #{mod[:id]}: #{e.message}"
      end
    end

    puts "[CheatsModManager] Loaded #{@loaded.size} files (#{@modules.size} modules total)"
  end

  #-------------------------------------------------------------------------
  # Load all .rb files within a module folder or standalone file
  #-------------------------------------------------------------------------
  def load_module_files(path, id)
    if File.directory?(path)
      bootstrap = File.join(path, "bootstrap.rb")
      if File.exist?(bootstrap)
        safe_load(bootstrap)
        @loaded << "#{id}/bootstrap.rb"
      end

      Dir[File.join(path, "*.rb")].sort.each do |subfile|
        next if subfile == bootstrap
        safe_load(subfile)
        @loaded << "#{id}/#{File.basename(subfile)}"
      end
    elsif File.exist?(path)
      safe_load(path)
      @loaded << File.basename(path)
    end
  end

  #-------------------------------------------------------------------------
  # Load a specific module (by id)
  #-------------------------------------------------------------------------
  def load_module(id)
    mod = @modules[id]
    return unless mod && !mod[:loaded] && mod[:enabled]
    mod[:loaded] = true
  end

  #-------------------------------------------------------------------------
  # Safe loader with error handling
  #-------------------------------------------------------------------------
  def safe_load(file)
    load file if File.exist?(file)
  rescue => e
    puts "[CheatsModManager] Error loading #{file}: #{e.message}"
  end
end

#===============================================================================
#  CheatModule
#------------------------------------------------------------------------------
#  Represents a single module's interface to register commands, hotkeys, etc.
#===============================================================================

class CheatModule
  attr_reader :manager, :info

  def initialize(manager, info)
    @manager = manager
    @info = info
  end

  def add_command(symbol, args = {}, &block)
    label = args[:label]
    help  = args[:help]
    @info[:commands][symbol] = { label: label, help: help, action: block }
  end

  def add_hotkey(command_symbol, key)
    @info[:hotkeys][command_symbol] = key
    @manager.sys && @manager.sys.write_hotkey(@info[:id], command_symbol, key)
  end

  def add_variable(name, args = {})
    default = args[:default]
    persist = args[:persist] || :global
    @info[:variables][name] = { value: default, persist: persist }
    @manager.sys && @manager.sys.write_var(@info[:id], name, default, persist)
  end
end
