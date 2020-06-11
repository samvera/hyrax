# frozen_string_literal: true
module Hyrax
  module ResourceSync
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :CapabilityListWriter
      autoload :ChangeListWriter
      autoload :ResourceListWriter
      autoload :SourceDescriptionWriter
    end
  end
end
