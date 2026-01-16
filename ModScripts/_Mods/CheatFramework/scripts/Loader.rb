#===============================================================================
#  FrameworkLoader
#------------------------------------------------------------------------------
#  Handles discovery, registration, and loading of modular cheat components
#===============================================================================
class FrameworkLoader
  attr_reader :modules 
  attr_reader :loaded 

  def initialize(root_path, ini = nil)
    @path = root_path
    @ini = ini || FrameworkConfig.new(File.join($framework.config_dir, "_system"))
    @modules = []
    @modules_by_key = {}
    @loaded = []
  end

  #----------------------------------------------
  # Find all files in modules folder
  #----------------------------------------------
  def discover
    unless Dir.exist?(@path)
      return
    end

    @modules = []
    @modules_by_key = {}

    Dir.glob(File.join(@path, "**", "*.rb")).each do |file|
      meta = read_metadata(file)

      # If no metadata block was found, build a sane default from filename
      unless meta
        base = File.basename(file, ".rb")
        rel = file.sub(@path + File::SEPARATOR, '')

        meta = {
          name: base,
          key:  base.downcase.gsub(/[^a-z0-9]+/, '_').to_sym,
          path: rel,
          depends_on: [],
          enabled: true,
          order: 999
        }
      end

      # normalize key -> symbol, ensure path and depends_on exist
      key = (meta[:key] || meta[:id] || File.basename(file, ".rb")).to_sym
      meta[:key] = key
      meta[:path] ||= file
      meta[:depends_on] ||= []

      # apply INI overrides (your helper names)
      meta[:enabled] = @ini.get_enabled("#{key}.enabled", meta.fetch(:enabled, true))
      meta[:order]   = @ini.get_load_order("#{key}.order", meta.fetch(:order, 999))

      @modules << meta
      @modules_by_key[key] = meta
    end
  end

  #----------------------------------------------
  # Collects metadata from files without loading
  #----------------------------------------------
def read_metadata(file)
  content = File.read(file)
  if content =~ /FrameworkModule\s*=\s*(\{.*?\})/m
    begin
      # eval the hash literal only (it won't define a top-level constant)
      parsed = eval($1)
      # normalize keys to symbols if they are strings
      if parsed.is_a?(Hash)
        parsed = parsed.transform_keys { |k| k.is_a?(String) ? k.to_sym : k }
        parsed[:path] = file.sub(@path + File::SEPARATOR, '')
        parsed[:depends_on] ||= []
        return parsed
      end
    rescue => e
      return nil
    end
  end
  nil
end


  #----------------------------------------------
  # Load called by init after discovery
  #----------------------------------------------
  def load_all
    resolve_dependencies
    load_enabled_modules
  end

  #----------------------------------------------
  # Reorder modules based on dependencies
  #----------------------------------------------
  def resolve_dependencies
    # Simple topological sort
    sorted = []
    visited = {}

    visit = lambda do |mod|
      return if visited[mod[:key]]
      visited[mod[:key]] = true

      mod[:depends_on].each do |dep|
        dep_mod = @modules_by_key[dep]
        unless dep_mod
          next
        end
        visit.call(dep_mod)
      end
      sorted << mod
    end

    @modules.each { |m| visit.call(m) }
    @modules = sorted.sort_by { |m| m[:order] }
    #msgbox "Sorted Modules: #{@modules.inspect}"
  end

  #----------------------------------------------
  # Load modules, filtering disabled ones
  #----------------------------------------------
  def load_enabled_modules
    @modules.each do |mod|
      next unless mod[:enabled]
      #msgbox "Loading #{mod[:name]}"

      begin
        safe_load(mod[:path])
        @loaded << mod[:key]
      ensure
        Object.send(:remove_const, :FrameworkModule) if Object.const_defined?(:FrameworkModule)
      end
    end
  end

  #----------------------------------------------
  # Safe loader with error handling
  #----------------------------------------------
  def safe_load(file)
    load_script($mod_manager.get_resource("cheatframework", "modules/#{file}"))
  end
end