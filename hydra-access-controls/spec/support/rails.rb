# Rails normally loads the locales of engines for us.
I18n.load_path << 'config/locales/hydra-access-controls.en.yml'

module Rails
  class << self
    def env
      ENV['environment']
    end

    def version
      "0.0.0"
      #"hydra-access-controls mock rails"
    end

    def root
      'spec/support'
    end

    def logger
      @@logger ||= Logger.new(File.expand_path('../../test.log', __FILE__)).tap { |logger| logger.level = Logger::WARN }
    end
  end
end
