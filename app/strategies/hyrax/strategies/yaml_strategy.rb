module Hyrax::Strategies
  class YamlStrategy < Flipflop::Strategies::AbstractStrategy
    class << self
      def default_description
        "Features configured by a YAML configuration file."
      end
    end

    def initialize(**options)
      @config_file = options.delete(:config)
      yaml_file
      super(**options)
    end

    def switchable?
      false
    end

    def enabled?(feature)
      return unless key_exists?(feature)
      yaml_file[feature.to_s]["enabled"]
    end

    def switch!(_feature, _enabled); end

    def clear!(_feature); end

    private

      def key_exists?(feature)
        yaml_file[feature.to_s] && yaml_file[feature.to_s].key?("enabled")
      end

      def yaml_file
        @yaml_file ||=
          begin
            if File.exist?(@config_file)
              YAML.load_file(@config_file)
            else
              {}
            end
          end
      end
  end
end
