module Sufia
  module ResourceSync
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :CapabilityListWriter
      autoload :ResourceListWriter
      autoload :SourceDescriptionWriter
    end
  end
end
