module Hyrax
  class Microdata
    include Singleton
    FILENAME = Hyrax::Engine.root + 'config/schema_org.yml'
    TOP_KEY = 'schema_org'.freeze

    def self.fetch(key, options = {})
      instance.fetch(key, options)
    end

    def fetch(key, options)
      data.fetch(key) { options[:default] }
    end

    # Allow clients to register paths providing config data sources.
    # Register a config files like this:
    #   Microdata.load_path << 'path/to/locale/en.yml'
    def self.load_path
      @load_path ||= [FILENAME]
    end

    # Sets the load path instance.
    class << self
      attr_writer :load_path
    end

    def self.reload!
      instance.reload!
    end

    def reload!
      @data = nil
    end

    private

      def data
        @data ||= begin
          flatten(yaml)
        end
      end

      def yaml
        yaml = {}
        self.class.load_path.each do |path|
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
