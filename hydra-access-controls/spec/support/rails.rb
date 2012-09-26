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
