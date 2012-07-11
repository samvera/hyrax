module Hydra
  module FileAccess
    require 'hydra/file_access/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
  autoload :Assets
end
