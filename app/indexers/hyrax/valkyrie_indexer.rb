# frozen_string_literal: true

module Hyrax
  ##
  # @deprecated use +Hyrax::Indexers::ResourceIndexer+ instead
  class ValkyrieIndexer < Hyrax::Indexers::ResourceIndexer
    def initialize(*args, **kwargs)
      Deprecation.warn "`Hyrax::ValkyrieIndexer` is deprecated. Use `Hyrax::Indexers::ResourceIndexer` instead."
      super
    end

    def self.for(*args, **kwargs)
      Deprecation.warn "`Hyrax::ValkyrieIndexer.for` is deprecated. Use `Hyrax::Indexers::ResourceIndexer.for` instead."
      Hyrax::Indexers::ResourceIndexer.for(*args, **kwargs)
    end
  end
end
