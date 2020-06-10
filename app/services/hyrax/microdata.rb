module Hyrax
  # Responsible for extracting information related to Schema.org microdata.
  #
  # You may load more than one source file. Source files that are later in the load process will overlay files that are earlier.
  #
  # @see Hyrax::Microdata.load_paths
  # @see Hyrax::Microdata.fetch
  #
  # @note This was extracted from internationalization because Schema.org keys are not internationalized
  class Microdata
    include Singleton
    FILENAME = Hyrax::Engine.root + 'config/schema_org.yml'
    TOP_KEY = 'schema_org'.freeze

    # @api private (See note regarding specific methods)
    #
    # @todo Should we make specific methods for fetching :property, :type, :value. This would mean privatizing the fetch method
    #
    # @param [String] key
    # @param [String] default - if we don't have a key match, use the given default value
    def self.fetch(key, default: nil)
      instance.fetch(key, default: default)
    end

    # @api private
    def fetch(key, default:)
      data.fetch(key) { default }
    end

    # @api public
    #
    # Allow clients to register paths providing config data sources.
    # Register a config files like this:
    #   Microdata.load_path << 'path/to/locale/en.yml'
    #
    # @note The load paths will be processed and loaded into in the natural array order. As each file is loaded, it overlays the already registered keys.
    # @return [Array<String>]
    def self.load_paths
      @load_paths ||= [FILENAME]
    end

    # @api public
    #
    # Sets the load_paths
    #
    # @param [String, Array<String>]
    def self.load_paths=(input)
      @load_paths = Array.wrap(input)
      reload! # If we are obliterating load paths, we really should clear data
    end

    # @api private
    def self.clear_load_paths!
      @load_paths = nil
      reload!
    end

    # @api public
    def self.reload!
      instance.reload!
    end

    # @api private
    def reload!
      @data = nil
    end

    private

    def data
      @data ||= flatten(yaml)
    end

    def yaml
      yaml = {}
      self.class.load_paths.each do |path|
        from_file = YAML.safe_load(File.open(path))[TOP_KEY]
        yaml.deep_merge!(from_file) if from_file
      end
      yaml
    end

    # Given a deeply nested hash, return a single hash
    def flatten(hash)
      hash.each_with_object({}) do |(key, value), h|
        if value.instance_of?(Hash)
          value.map do |k, v|
            # We could add recursion here if we ever had more than 2 levels
            h["#{key}.#{k}"] = v
          end
        else
          h[key] = value
        end
      end
    end
  end
end
