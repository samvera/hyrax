# Rails normally loads the locales of engines for us.
I18n.load_path << 'config/locales/hydra-access-controls.en.yml'

module Rails
  def self.env
    ENV['environment']
  end

  def self.version
    "0.0.0"
    #"hydra-access-controls mock rails"
  end
  def self.root
    'spec/support'
  end
end
